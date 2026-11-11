import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nexus_theme.dart';

/// Medidor em arco segmentado (laranja até o valor; alvo no topo).
class SegmentArc extends StatelessWidget {
  final double min, max;
  final double? value;
  final double target;
  final Widget child;
  const SegmentArc({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.target,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: CustomPaint(
        painter: _ArcPainter(min, max, value, target, NX.accent, NX.glow),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: child,
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double min, max, target;
  final double? value;
  final Color accent;
  final bool glow;
  _ArcPainter(this.min, this.max, this.value, this.target, this.accent, this.glow);

  static const sweep = 250.0;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * 0.56);
    final r = math.min(s.width / 2, s.height * 0.56) - 4;
    final start = (90 + (360 - sweep) / 2) * math.pi / 180;
    final sw = sweep * math.pi / 180;

    // aro metálico
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start - 0.03,
      sw + 0.06,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..shader = SweepGradient(
          colors: [NX.dim, NX.silver, NX.metal, NX.silver, NX.dim],
          transform: GradientRotation(start),
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    const segs = 64;
    final frac = value == null ? -1.0 : ((value! - min) / (max - min)).clamp(0.0, 1.0);
    final tFrac = ((target - min) / (max - min)).clamp(0.0, 1.0);
    final lit = frac < 0 ? -1 : (frac * (segs - 1)).round();
    final segAngle = sw / segs;
    final outer = r - 10, inner = r - 34;

    for (var i = 0; i < segs; i++) {
      final a = start + i * segAngle + segAngle * 0.18;
      final a2 = a + segAngle * 0.64;
      final on = i <= lit;
      final t = i / segs;
      final col = on
          ? Color.lerp(accent.withOpacity(0.55), Color.lerp(accent, const Color(0xFFFFC27A), 0.35)!, t)!
          : const Color(0xFF2A2B30);
      final path = Path()
        ..moveTo(c.dx + math.cos(a) * inner, c.dy + math.sin(a) * inner)
        ..lineTo(c.dx + math.cos(a) * outer, c.dy + math.sin(a) * outer)
        ..lineTo(c.dx + math.cos(a2) * outer, c.dy + math.sin(a2) * outer)
        ..lineTo(c.dx + math.cos(a2) * inner, c.dy + math.sin(a2) * inner)
        ..close();
      if (on && glow) {
        canvas.drawPath(
            path,
            Paint()
              ..color = accent.withOpacity(0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
      canvas.drawPath(path, Paint()..color = col);
    }

    // marcador do alvo
    final ta = start + tFrac * sw;
    canvas.drawLine(
      Offset(c.dx + math.cos(ta) * (inner - 6), c.dy + math.sin(ta) * (inner - 6)),
      Offset(c.dx + math.cos(ta) * (r + 2), c.dy + math.sin(ta) * (r + 2)),
      Paint()
        ..color = NX.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // ponta do valor
    if (frac >= 0) {
      final va = start + frac * sw;
      final o = Offset(c.dx + math.cos(va) * (inner - 10), c.dy + math.sin(va) * (inner - 10));
      canvas.drawCircle(o, 4.5, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter o) =>
      o.value != value || o.target != target || o.min != min || o.max != max ||
      o.accent != accent || o.glow != glow;
}

/// Forma de onda em barras com o centro em laranja.
class WaveBars extends StatelessWidget {
  final List<double> values;
  final bool active;
  const WaveBars({super.key, required this.values, this.active = true});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _WavePainter(List.of(values), active, NX.accent), size: Size.infinite);
}

class _WavePainter extends CustomPainter {
  final List<double> v;
  final bool active;
  final Color accent;
  _WavePainter(this.v, this.active, this.accent);

  @override
  void paint(Canvas canvas, Size s) {
    if (v.isEmpty) return;
    final w = s.width / v.length;
    final mid = s.height / 2;
    final p = Paint()
      ..strokeWidth = math.max(1.4, w * 0.42)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < v.length; i++) {
      final h = math.max(2.0, v[i] * s.height * 0.95) / 2;
      final distC = ((i - v.length / 2).abs() / (v.length / 2));
      final base = !active
          ? NX.dim
          : distC < 0.22
              ? accent
              : Color.lerp(NX.silver, NX.metal, distC)!;
      p.color = base.withOpacity(active ? 0.95 - distC * 0.4 : 0.6);
      final x = i * w + w / 2;
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), p);
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) => true;
}

/// Barras de nível de sinal.
class SignalIndicator extends StatelessWidget {
  final double levelDb;
  final bool on;
  const SignalIndicator({super.key, required this.levelDb, required this.on});

  @override
  Widget build(BuildContext context) {
    final lvl = on ? ((levelDb + 70) / 55).clamp(0.0, 1.0) : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final lit = lvl > i / 4;
        return Container(
          width: 3.5,
          height: 6.0 + i * 3.5,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: lit ? (i == 3 ? NX.accent : NX.ok) : NX.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

/// Anel segmentado de porcentagem (Equilíbrio da Pele, Perfil Sonoro).
class RingGauge extends StatelessWidget {
  final double value; // 0..1
  final Widget child;
  final double size;
  const RingGauge({super.key, required this.value, required this.child, this.size = 130});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0.0, 1.0), NX.accent, NX.glow),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color accent;
  final bool glow;
  _RingPainter(this.v, this.accent, this.glow);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 4;
    const n = 48;
    final lit = (v * n).round();
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / n;
      final o1 = c + Offset(math.cos(a), math.sin(a)) * r;
      final o2 = c + Offset(math.cos(a), math.sin(a)) * (r - 16);
      final p = Paint()
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.butt
        ..color = i < lit ? Color.lerp(accent, const Color(0xFFFFC27A), i / n * 0.5)! : const Color(0xFF2A2B30);
      if (i < lit && glow) {
        canvas.drawLine(o1, o2, Paint()
          ..strokeWidth = 6
          ..color = accent.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      }
      canvas.drawLine(o1, o2, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.accent != accent;
}
