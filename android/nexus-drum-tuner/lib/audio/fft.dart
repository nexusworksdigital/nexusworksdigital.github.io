import 'dart:math' as math;
import 'dart:typed_data';

/// FFT radix-2 iterativa com janela Hann pré-calculada.
class FFT {
  final int n;
  late final Float64List _cos;
  late final Float64List _sin;
  late final Float64List window;
  late final Int32List _rev;
  late final Float64List _re;
  late final Float64List _im;

  FFT(this.n) {
    assert(n > 0 && (n & (n - 1)) == 0, 'n deve ser potência de 2');
    final bits = (math.log(n) / math.ln2).round();
    _cos = Float64List(n ~/ 2);
    _sin = Float64List(n ~/ 2);
    for (var i = 0; i < n ~/ 2; i++) {
      _cos[i] = math.cos(2 * math.pi * i / n);
      _sin[i] = -math.sin(2 * math.pi * i / n);
    }
    _rev = Int32List(n);
    for (var i = 0; i < n; i++) {
      var r = 0;
      var x = i;
      for (var b = 0; b < bits; b++) {
        r = (r << 1) | (x & 1);
        x >>= 1;
      }
      _rev[i] = r;
    }
    window = Float64List(n);
    for (var i = 0; i < n; i++) {
      window[i] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1));
    }
    _re = Float64List(n);
    _im = Float64List(n);
  }

  /// Magnitude em dB (0 dB ≈ senoide de amplitude 1) para os bins 0..n/2.
  Float64List magnitudeDb(Float64List input) {
    final re = _re, im = _im;
    for (var i = 0; i < n; i++) {
      re[_rev[i]] = input[i] * window[i];
      im[i] = 0;
    }
    for (var size = 2; size <= n; size <<= 1) {
      final half = size >> 1;
      final step = n ~/ size;
      for (var i = 0; i < n; i += size) {
        for (var j = 0; j < half; j++) {
          final k = j * step;
          final wr = _cos[k], wi = _sin[k];
          final a = i + j, b = a + half;
          final tr = re[b] * wr - im[b] * wi;
          final ti = re[b] * wi + im[b] * wr;
          re[b] = re[a] - tr;
          im[b] = im[a] - ti;
          re[a] += tr;
          im[a] += ti;
        }
      }
    }
    final out = Float64List(n ~/ 2 + 1);
    final norm = n / 4;
    for (var i = 0; i <= n ~/ 2; i++) {
      final m = math.sqrt(re[i] * re[i] + im[i] * im[i]) / norm;
      out[i] = 20 * math.log(m + 1e-9) / math.ln10;
    }
    return out;
  }
}
