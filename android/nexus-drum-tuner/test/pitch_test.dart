import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_drum_tuner/audio/fft.dart';
import 'package:nexus_drum_tuner/audio/music.dart';
import 'package:nexus_drum_tuner/audio/pitch.dart';

/// Sinal sintético de tambor: parciais inarmônicos de membrana,
/// fundamental mais fraca que o 2º modo, ruído de ataque.
Float64List drum(double f, int n, {int sr = 44100}) {
  final rnd = math.Random(1);
  const modes = [
    [1.0, 0.35, 6.0],
    [1.594, 1.0, 10.0],
    [2.136, 0.6, 12.0],
    [2.296, 0.5, 14.0],
  ];
  final out = Float64List(n);
  const offset = 0.2; // janela começa 200 ms após a batida
  for (var i = 0; i < n; i++) {
    final t = offset + i / sr;
    var s = 0.0;
    for (final m in modes) {
      s += m[1] * math.sin(2 * math.pi * f * m[0] * t) * math.exp(-m[2] * t);
    }
    out[i] = s + 0.003 * (rnd.nextDouble() * 2 - 1);
  }
  return out;
}

void main() {
  const n = 8192, sr = 44100;
  final fft = FFT(n);

  for (final f in [55.0, 110.0, 147.0, 200.0, 320.0]) {
    test('detecta fundamental de $f Hz', () {
      final db = fft.magnitudeDb(drum(f, n));
      final p = findFundamental(db, sr, n, fmin: 30, fmax: 1200)!;
      expect(centsBetween(p.hz, f).abs(), lessThan(5));
    });
  }

  test('nota de 196 Hz é G3', () {
    expect(noteFromFreq(196).label, 'G3');
    expect(noteFromFreq(55).label, 'A1');
  });
}
