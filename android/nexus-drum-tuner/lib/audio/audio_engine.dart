import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'fft.dart';
import 'pitch.dart';

/// Resultado estável de uma batida.
class Reading {
  final double hz;
  final double quality; // 0..1
  final double stabilityCents; // dispersão das leituras da batida
  final List<Harmonic> harmonics; // H1 (fundamental) .. H5
  final DateTime at;
  const Reading(this.hz, this.quality, this.stabilityCents, this.harmonics, this.at);

  String get stabilityLabel => stabilityCents <= 3
      ? 'Alta'
      : stabilityCents <= 10
          ? 'Média'
          : 'Baixa';
}

enum MicState { off, starting, listening, denied, error }

/// Motor de áudio: microfone → FFT → fundamental → leitura estabilizada.
/// Todo o processamento é local, sem internet.
class AudioEngine extends ChangeNotifier {
  static const sampleRate = 44100;
  static const fftSize = 8192; // ~186 ms, 5,4 Hz por bin (+ interpolação)

  final AudioRecorder _rec = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final FFT _fft = FFT(fftSize);
  final Float64List _ring = Float64List(fftSize);
  final Float64List _ordered = Float64List(fftSize);
  int _write = 0;
  int _filled = 0;

  MicState state = MicState.off;
  String? error;

  // Ao vivo
  double levelDb = -100;
  final List<double> wave = List<double>.filled(72, 0.0, growable: true);
  Float64List? spectrumDb;
  bool hitActive = false;

  // Leitura estabilizada (mantida após a batida)
  Reading? reading;
  bool hold = false;
  int maxHarmonic = 5;

  // Ajustes de áudio
  double sensitivity = 6; // dB
  bool noiseReduction = true;
  bool ambientFilter = true;
  int hopSamples = 2048;

  /// Filtro de banda do analisador (null = sem filtro)
  (double, double)? band;

  /// Espectrograma: linhas recentes em 96 faixas log (40 Hz–10 kHz).
  static const specBins = 96;
  static const specRows = 64;
  final List<Float32List> spectrogram = [];

  // Faixa de busca (definida pelo tipo de tambor)
  double fmin = 40, fmax = 1200;

  // Interno
  double _noiseDb = -65;
  double get noiseDb => _noiseDb;
  // histórico curto de nível (dB, nº de amostras) para detectar o ataque
  final List<(double, int)> _levelHist = [];
  double _prevLevel = -100;
  double _hitPeakDb = -100;
  int _samplesSinceHit = 0;
  int _samplesSinceAnalysis = 0;
  final List<double> _hitHz = [];
  final List<double> _hitProm = [];
  Peak? _lastPeak;
  Float64List? _lastPeakSpectrum;

  final StreamController<Reading> _hits = StreamController.broadcast();

  /// Emite uma leitura ao fim de cada batida válida.
  Stream<Reading> get hits => _hits.stream;

  bool get listening => state == MicState.listening;

  int _op = 0; // invalida operações antigas de start/stop
  DateTime _lastData = DateTime.now();
  Timer? _watchdog;

  Future<void> start() async {
    if (state == MicState.listening || state == MicState.starting) return;
    final id = ++_op;
    state = MicState.starting;
    error = null;
    notifyListeners();
    try {
      final ok = await _rec.hasPermission();
      if (id != _op) return; // foi cancelado enquanto pedia permissão
      if (!ok) {
        state = MicState.denied;
        notifyListeners();
        return;
      }
      await _sub?.cancel();
      try {
        await _rec.stop();
      } catch (_) {}
      final stream = await _rec.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ));
      if (id != _op) {
        try {
          await _rec.stop();
        } catch (_) {}
        return;
      }
      _lastData = DateTime.now();
      _sub = stream.listen(
        _onData,
        onError: (Object e) {
          error = '$e';
          state = MicState.error;
          notifyListeners();
        },
        onDone: () {
          if (id == _op && state == MicState.listening) _restart();
        },
      );
      state = MicState.listening;
      _startWatchdog();
      notifyListeners();
    } catch (e) {
      if (id != _op) return;
      error = '$e';
      state = MicState.error;
      notifyListeners();
    }
  }

  /// Se o microfone parar de mandar áudio, religa sozinho.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state == MicState.listening &&
          DateTime.now().difference(_lastData).inMilliseconds > 2000) {
        _restart();
      }
    });
  }

  Future<void> _restart() async {
    await stop();
    await start();
  }

  Future<void> stop() async {
    ++_op;
    _watchdog?.cancel();
    _watchdog = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _rec.stop();
    } catch (_) {}
    state = MicState.off;
    levelDb = -100;
    hitActive = false;
    for (var i = 0; i < wave.length; i++) {
      wave[i] = 0;
    }
    notifyListeners();
  }

  Future<void> toggle() => listening ? stop() : start();

  void setRange(double min, double max) {
    fmin = min;
    fmax = max;
  }

  void toggleHold() {
    hold = !hold;
    notifyListeners();
  }

  void clearReading() {
    reading = null;
    notifyListeners();
  }

  void _onData(Uint8List bytes) {
    _lastData = DateTime.now();
    final count = bytes.length ~/ 2;
    if (count == 0) return;
    final bd = ByteData.sublistView(bytes);
    var sum = 0.0, peak = 0.0;
    for (var i = 0; i < count; i++) {
      final s = bd.getInt16(i * 2, Endian.little) / 32768.0;
      _ring[_write] = s;
      _write = (_write + 1) % fftSize;
      sum += s * s;
      final a = s.abs();
      if (a > peak) peak = a;
    }
    _filled = math.min(fftSize, _filled + count);
    levelDb = 20 * math.log(math.sqrt(sum / count) + 1e-9) / math.ln10;

    wave.removeAt(0);
    wave.add(math.min(1.0, peak * 1.6));

    _process(count);
    _levelHist.add((levelDb, count));
    var total = 0;
    for (final e in _levelHist) {
      total += e.$2;
    }
    while (_levelHist.length > 1 && total - _levelHist.first.$2 >= sampleRate * 0.2) {
      total -= _levelHist.removeAt(0).$2;
    }
    _prevLevel = levelDb;
    notifyListeners();
  }

  Float64List _snapshot() {
    for (var i = 0; i < fftSize; i++) {
      _ordered[i] = _ring[(_write + i) % fftSize];
    }
    return _ordered;
  }

  void _process(int count) {
    _samplesSinceAnalysis += count;
    final gate = math.max(
        _noiseDb + 14 - (sensitivity - 6) + (noiseReduction ? 4 : 0), -66.0);
    final ready = _filled == fftSize && _samplesSinceAnalysis >= hopSamples;

    if (!hitActive) {
      // Filtro de ruído: piso adaptativo enquanto não há batida
      // (sobe devagar se o ambiente for barulhento, desce rápido)
      final k = levelDb < gate ? 0.03 : 0.004;
      _noiseDb = (_noiseDb * (1 - k) + levelDb * k).clamp(-90.0, -30.0);
      // ataque: nível acima do portão e subida rápida em relação ao
      // mínimo dos últimos ~200 ms (independe do tamanho do bloco)
      var recentMin = levelDb;
      for (final e in _levelHist) {
        if (e.$1 < recentMin) recentMin = e.$1;
      }
      final onset = levelDb > gate && levelDb - recentMin > 9;
      if (onset) {
        hitActive = true;
        _samplesSinceHit = 0;
        _hitPeakDb = levelDb;
        _hitHz.clear();
        _hitProm.clear();
      } else if (ready) {
        _samplesSinceAnalysis = 0;
        _setSpectrum(_fft.magnitudeDb(_snapshot()));
      }
      return;
    }

    _samplesSinceHit += count;
    if (levelDb > _hitPeakDb) _hitPeakDb = levelDb;
    final ms = _samplesSinceHit * 1000 / sampleRate;

    // Ignora o ataque da baqueta; analisa a parte que soa
    if (ms >= 60 && ready) {
      _samplesSinceAnalysis = 0;
      final db = _fft.magnitudeDb(_snapshot());
      _setSpectrum(db);
      final (lo, hi) = _searchRange();
      final p = findFundamental(db, sampleRate, fftSize, fmin: lo, fmax: hi);
      if (p != null && p.prominence > 12) {
        _hitHz.add(p.hz);
        _hitProm.add(p.prominence);
        _lastPeak = p;
        _lastPeakSpectrum = db;
        _updateReading(isFinal: false);
      }
    }

    final ended = (ms > 80 && levelDb < gate - 3) ||
        levelDb < _hitPeakDb - 38 ||
        ms > 2500;
    if (ended) {
      hitActive = false;
      // batida curta (pele abafada): faz pelo menos uma análise
      if (_hitHz.isEmpty && _filled == fftSize) {
        final db = _fft.magnitudeDb(_snapshot());
        _setSpectrum(db);
        final (lo, hi) = _searchRange();
        final p = findFundamental(db, sampleRate, fftSize, fmin: lo, fmax: hi);
        if (p != null && p.prominence > 8) {
          _hitHz.add(p.hz);
          _hitProm.add(p.prominence);
          _lastPeak = p;
          _lastPeakSpectrum = db;
        }
      }
      _updateReading(isFinal: true);
    }
  }

  (double, double) _searchRange() {
    var lo = math.max(fmin, ambientFilter ? 45.0 : 30.0);
    var hi = fmax;
    final b = band;
    if (b != null) {
      lo = math.max(lo, b.$1);
      hi = math.min(hi, b.$2);
      if (hi <= lo + 10) {
        lo = b.$1;
        hi = b.$2;
      }
    }
    return (lo, hi);
  }

  void _setSpectrum(Float64List db) {
    spectrumDb = db;
    final row = Float32List(specBins);
    const f0 = 40.0, f1 = 10000.0;
    const binHz = sampleRate / fftSize;
    for (var i = 0; i < specBins; i++) {
      final a = f0 * math.pow(f1 / f0, i / specBins);
      final b = f0 * math.pow(f1 / f0, (i + 1) / specBins);
      var k0 = (a / binHz).floor();
      final k1 = math.max(k0, (b / binHz).floor());
      var m = -120.0;
      for (; k0 <= k1 && k0 < db.length; k0++) {
        if (db[k0] > m) m = db[k0];
      }
      row[i] = m;
    }
    spectrogram.add(row);
    if (spectrogram.length > specRows) spectrogram.removeAt(0);
  }

  void _updateReading({required bool isFinal}) {
    if (_hitHz.isEmpty) return;
    if (hold && reading != null) return;
    final sorted = [..._hitHz]..sort();
    final med = sorted[sorted.length ~/ 2];

    // Estabilidade: dispersão em cents em torno da mediana
    var dev = 0.0;
    for (final h in _hitHz) {
      final c = 1200 * math.log(h / med) / math.ln2;
      dev += c * c;
    }
    final stdCents = math.sqrt(dev / _hitHz.length);
    final prom = _hitProm.reduce((a, b) => a + b) / _hitProm.length;
    final q = (0.5 * ((prom - 12) / 30).clamp(0.0, 1.0) +
            0.35 * (1 - stdCents / 30).clamp(0.0, 1.0) +
            0.15 * (_hitHz.length / 4).clamp(0.0, 1.0))
        .clamp(0.0, 1.0);

    final harmonics = (_lastPeak != null && _lastPeakSpectrum != null)
        ? measureHarmonics(_lastPeakSpectrum!, sampleRate, fftSize,
            Peak(med, _lastPeak!.db, _lastPeak!.prominence),
            maxOrder: maxHarmonic)
        : <Harmonic>[];

    final h1 = Harmonic(1, med, 0);
    reading = Reading(med, q, stdCents, [h1, ...harmonics], DateTime.now());
    if (isFinal) _hits.add(reading!);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    _sub?.cancel();
    _rec.dispose();
    _hits.close();
    super.dispose();
  }
}
