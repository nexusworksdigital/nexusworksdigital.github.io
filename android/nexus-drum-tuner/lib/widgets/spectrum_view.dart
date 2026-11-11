import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../audio/pitch.dart';
import '../theme/nexus_theme.dart';

const _fmin = 40.0, _fmax = 10000.0;

double _xOf(double hz, double left, double width, bool log) {
  final t = log
      ? math.log(hz / _fmin) / math.log(_fmax / _fmin)
      : (hz - _fmin) / (_fmax - _fmin);
  return left + t.clamp(0.0, 1.0) * width;
}

/// Analisador de espectro com marcação da fundamental e harmônicos.
class SpectrumView extends StatelessWidget {
  final Float64List? db;
  final int sampleRate, fftSize;
  final List<Harmonic> harmonics;
  final bool logAxis;
  final (double, double)? band;
  const SpectrumView({
    super.key,
    required this.db,
    required this.sampleRate,
    required this.fftSize,
    this.harmonics = const [],
    this.logAxis = true,
    this.band,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _SpecPainter(db, sampleRate, fftSize, harmonics, logAxis, band, NX.accent, NX.glow),
        size: Size.infinite,
      );
}

class _SpecPainter extends CustomPainter {
  final Float64List? db;
  final int sr, n;
  final List<Harmonic> harmonics;
  final bool logAxis;
  final (double, double)? band;
  final Color accent;
  final bool glow;
  _SpecPainter(this.db, this.sr, this.n, this.harmonics, this.logAxis, this.band, this.accent, this.glow);

  static const left = 40.0, bottom = 22.0, top = 34.0, right = 6.0;

  double _y(double d, double h) =>
      top + ((0 - d) / 60).clamp(0.0, 1.0) * (h - top - bottom);

  void _label(Canvas c, String t, Offset o, {bool right = false, Color? col, double size = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: NX.inter(size, c: col ?? NX.silver)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, right ? o - Offset(tp.width, tp.height / 2) : o);
  }

  void _bubble(Canvas canvas, Offset at, String text, {bool big = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: NX.inter(big ? 12 : 10.5, w: FontWeight.w700, c: NX.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 14, h = tp.height + 6;
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: at - Offset(0, h / 2 + 8), width: w, height: h),
        const Radius.circular(7));
    canvas.drawRRect(r, Paint()..color = NX.graphite);
    canvas.drawRRect(r, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);
    tp.paint(canvas, Offset(r.left + 7, r.top + 3));
    canvas.drawCircle(at, 4, Paint()..color = NX.white);
    canvas.drawCircle(at, 4, Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final pw = w - left - right;
    final grid = Paint()
      ..color = NX.border.withOpacity(0.6)
      ..strokeWidth = 1;

    // faixa do filtro
    final b = band;
    if (b != null) {
      final x0 = _xOf(b.$1, left, pw, logAxis), x1 = _xOf(b.$2, left, pw, logAxis);
      canvas.drawRect(Rect.fromLTRB(x0, top, x1, h - bottom),
          Paint()..color = accent.withOpacity(0.07));
    }

    for (var d = 0; d >= -60; d -= 12) {
      final y = _y(d.toDouble(), h);
      canvas.drawLine(Offset(left, y), Offset(w - right, y), grid);
      _label(canvas, d == 0 ? '0 dB' : '$d', Offset(left - 6, y), right: true);
    }
    final ticks = logAxis
        ? [50, 100, 200, 500, 1000, 2000, 5000, 10000]
        : [1000, 2500, 5000, 7500, 10000];
    for (final f in ticks) {
      final x = _xOf(f.toDouble(), left, pw, logAxis);
      canvas.drawLine(Offset(x, top), Offset(x, h - bottom), grid);
      _label(canvas, f >= 1000 ? '${f ~/ 1000}k' : '$f', Offset(x - 8, h - bottom + 5));
    }

    final data = db;
    if (data == null) return;
    final binHz = sr / n;
    final path = Path();
    final cols = pw.floor();
    for (var px = 0; px <= cols; px++) {
      final t0 = px / cols, t1 = (px + 1) / cols;
      final f0 = logAxis ? _fmin * math.pow(_fmax / _fmin, t0) : _fmin + (_fmax - _fmin) * t0;
      final f1 = logAxis ? _fmin * math.pow(_fmax / _fmin, t1) : _fmin + (_fmax - _fmin) * t1;
      final b0 = (f0 / binHz).floor().clamp(0, data.length - 1);
      final b1 = math.max(b0, (f1 / binHz).floor()).clamp(0, data.length - 1);
      var m = -200.0;
      for (var k = b0; k <= b1; k++) {
        if (data[k] > m) m = data[k];
      }
      final pt = Offset(left + px.toDouble(), _y(m, h));
      if (px == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    final fill = Path.from(path)
      ..lineTo(w - right, h - bottom)
      ..lineTo(left, h - bottom)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [accent.withOpacity(0.75), accent.withOpacity(0.05)],
          ).createShader(Rect.fromLTWH(0, top, w, h - top - bottom)));
    if (glow) {
      canvas.drawPath(path, Paint()
        ..color = accent.withOpacity(0.5)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    canvas.drawPath(path, Paint()
      ..color = Color.lerp(accent, NX.white, 0.35)!
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke);

    // fundamental + harmônicos
    for (final hm in harmonics) {
      if (hm.hz < _fmin || hm.hz > _fmax) continue;
      final x = _xOf(hm.hz, left, pw, logAxis);
      final k = (hm.hz / binHz).round().clamp(0, data.length - 1);
      final y = _y(data[k], h);
      if (hm.order == 1) {
        canvas.drawLine(Offset(x, y), Offset(x, h - bottom), Paint()
          ..color = accent
          ..strokeWidth = 1.5);
        _bubble(canvas, Offset(x, math.max(y, top + 8)), '${hm.hz.toStringAsFixed(1)} Hz', big: true);
      } else {
        _bubble(canvas, Offset(x, math.max(y, top + 8)), 'H${hm.order}');
      }
    }
  }

  @override
  bool shouldRepaint(_SpecPainter o) => true;
}

/// Visão em cascata (últimas leituras sobrepostas em perspectiva).
class CascadeView extends StatelessWidget {
  final List<Float32List> rows;
  const CascadeView({super.key, required this.rows});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _CascadePainter(List.of(rows), NX.accent), size: Size.infinite);
}

class _CascadePainter extends CustomPainter {
  final List<Float32List> rows;
  final Color accent;
  _CascadePainter(this.rows, this.accent);

  @override
  void paint(Canvas canvas, Size s) {
    if (rows.isEmpty) return;
    final take = math.min(18, rows.length);
    final list = rows.sublist(rows.length - take);
    for (var r = 0; r < take; r++) {
      final row = list[r];
      final depth = (take - 1 - r) / math.max(1, take - 1); // 0 = mais recente
      final ox = 30 * depth, oy = -s.height * 0.5 * depth;
      final w = s.width - 40;
      final base = s.height - 10 + oy;
      final path = Path()..moveTo(ox + 10, base);
      for (var i = 0; i < row.length; i++) {
        final v = ((row[i] + 60) / 60).clamp(0.0, 1.0);
        path.lineTo(ox + 10 + w * i / (row.length - 1), base - v * s.height * 0.45);
      }
      path.lineTo(ox + 10 + w, base);
      final col = Color.lerp(accent, NX.dim, depth)!;
      canvas.drawPath(path, Paint()..color = NX.bg.withOpacity(0.85));
      canvas.drawPath(path, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = r == take - 1 ? 1.8 : 1);
    }
  }

  @override
  bool shouldRepaint(_CascadePainter o) => true;
}

/// Espectrograma (heatmap): tempo na vertical, frequência na horizontal.
class HeatmapView extends StatelessWidget {
  final List<Float32List> rows;
  final bool vertical;
  const HeatmapView({super.key, required this.rows, this.vertical = false});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HeatPainter(List.of(rows), vertical), size: Size.infinite);
}

class _HeatPainter extends CustomPainter {
  final List<Float32List> rows;
  final bool vertical;
  _HeatPainter(this.rows, this.vertical);

  static const _stops = [
    Color(0xFF07040F),
    Color(0xFF3A0D5C),
    Color(0xFF9B1D6A),
    Color(0xFFFF5A1F),
    Color(0xFFFFC94A),
    Color(0xFFFFFFE0),
  ];

  Color _map(double v) {
    final t = v.clamp(0.0, 0.999) * (_stops.length - 1);
    final i = t.floor();
    return Color.lerp(_stops[i], _stops[i + 1], t - i)!;
  }

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = _stops[0]);
    if (rows.isEmpty) return;
    final nRows = rows.length;
    final nBins = rows.first.length;
    final p = Paint();
    for (var r = 0; r < nRows; r++) {
      final row = rows[r];
      for (var b = 0; b < nBins; b++) {
        final v = ((row[b] + 70) / 65);
        if (v <= 0.02) continue;
        p.color = _map(v);
        if (vertical) {
          // frequência na horizontal, tempo descendo
          final cw = s.width / nBins, ch = s.height / nRows;
          canvas.drawRect(Rect.fromLTWH(b * cw, (nRows - 1 - r) * ch, cw + 0.6, ch + 0.6), p);
        } else {
          final cw = s.width / nRows, ch = s.height / nBins;
          canvas.drawRect(Rect.fromLTWH(r * cw, s.height - (b + 1) * ch, cw + 0.6, ch + 0.6), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter o) => true;
}
