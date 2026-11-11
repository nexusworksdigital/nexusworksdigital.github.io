import 'dart:typed_data';

class Peak {
  final double hz;
  final double db;
  final double prominence; // dB acima do ruído do espectro
  const Peak(this.hz, this.db, this.prominence);
}

class Harmonic {
  final int order;
  final double hz;
  final double relDb; // dB relativo à fundamental
  const Harmonic(this.order, this.hz, this.relDb);
}

/// Detecta a fundamental de um tambor.
/// Tambores têm parciais inarmônicos, e o mais forte nem sempre é o
/// fundamental. Regra: entre os picos até [window] dB abaixo do maior,
/// escolhe o de frequência mais baixa. Interpolação parabólica no pico.
Peak? findFundamental(Float64List db, int sampleRate, int fftSize,
    {double fmin = 40, double fmax = 1200, double window = 15}) {
  final binHz = sampleRate / fftSize;
  final lo = (fmin / binHz).floor().clamp(2, db.length - 3);
  final hi = (fmax / binHz).ceil().clamp(lo + 1, db.length - 2);

  final peaks = <int>[];
  var gmax = -1e9;
  for (var i = lo; i < hi; i++) {
    if (db[i] > db[i - 1] && db[i] >= db[i + 1]) {
      peaks.add(i);
      if (db[i] > gmax) gmax = db[i];
    }
  }
  if (peaks.isEmpty) return null;

  var k = peaks.firstWhere((i) => db[i] >= gmax - window);

  // ruído de referência: mediana do espectro na faixa
  final slice = db.sublist(lo, hi).toList()..sort();
  final floor = slice[slice.length ~/ 2];

  final a = db[k - 1], b = db[k], c = db[k + 1];
  final den = a - 2 * b + c;
  final p = den.abs() < 1e-12 ? 0.0 : 0.5 * (a - c) / den;
  final hz = (k + p.clamp(-0.5, 0.5)) * binHz;
  return Peak(hz, b, b - floor);
}

/// Mede os harmônicos 2..maxOrder procurando o pico em ±4% de n·f.
List<Harmonic> measureHarmonics(
    Float64List db, int sampleRate, int fftSize, Peak fund,
    {int maxOrder = 4}) {
  final binHz = sampleRate / fftSize;
  final out = <Harmonic>[];
  for (var n = 2; n <= maxOrder; n++) {
    final target = fund.hz * n;
    final lo = (target * 0.96 / binHz).floor();
    final hi = (target * 1.04 / binHz).ceil();
    if (hi >= db.length - 1) break;
    var best = lo;
    for (var i = lo; i <= hi; i++) {
      if (db[i] > db[best]) best = i;
    }
    out.add(Harmonic(n, best * binHz, db[best] - fund.db));
  }
  return out;
}
