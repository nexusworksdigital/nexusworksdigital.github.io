import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/nexus_theme.dart';
import 'nexus_logo.dart';

/// Mapa dos parafusos em volta da pele (aro cromado, ponto ativo em laranja).
class LugMap extends StatelessWidget {
  final int lugs;
  final List<double?> values;
  final double? reference;
  final int current;
  final bool armed;
  final ValueChanged<int> onTap;

  const LugMap({
    super.key,
    required this.lugs,
    required this.values,
    required this.reference,
    required this.current,
    required this.armed,
    required this.onTap,
  });

  Color? _status(int i) {
    final v = i < values.length ? values[i] : null;
    final ref = reference;
    if (v == null || ref == null) return null;
    final cents = (1200 * math.log(v / ref) / math.ln2).abs();
    return NX.statusColor(cents);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: LayoutBuilder(builder: (context, c) {
        final size = math.min(c.maxWidth, c.maxHeight);
        final cx = c.maxWidth / 2, cy = c.maxHeight / 2;
        final rLug = size * 0.43;
        final dot = size * 0.135;
        return Stack(
          children: [
            Positioned(
              left: cx - size * 0.42,
              top: cy - size * 0.42,
              width: size * 0.84,
              height: size * 0.84,
              child: CustomPaint(painter: _HeadPainter(NX.accent, current, lugs, NX.glow)),
            ),
            Positioned(
              left: cx - size * 0.09,
              top: cy - size * 0.09,
              child: Opacity(
                opacity: 0.55,
                child: NexusMark(size: size * 0.18, color: const Color(0xFF3B3D44)),
              ),
            ),
            for (var i = 0; i < lugs; i++)
              Builder(builder: (context) {
                final a = -math.pi / 2 + 2 * math.pi * i / lugs;
                final sel = i == current;
                final st = _status(i);
                return Positioned(
                  left: cx + math.cos(a) * rLug - dot / 2,
                  top: cy + math.sin(a) * rLug - dot / 2,
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: NX.animations ? 200 : 0),
                      width: dot,
                      height: dot,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          center: Alignment(-0.3, -0.4),
                          colors: [Color(0xFF3A3C42), Color(0xFF0B0B0D)],
                        ),
                        border: Border.all(
                          color: sel ? NX.accent : (st ?? NX.silver),
                          width: sel ? 3 : 2,
                        ),
                        boxShadow: sel
                            ? NX.glowShadow(blur: armed ? 22 : 14, opacity: armed ? 0.8 : 0.55)
                            : const [BoxShadow(color: Colors.black, blurRadius: 6)],
                      ),
                      child: Text('${i + 1}',
                          style: NX.sora(dot * 0.42, w: FontWeight.w700, c: NX.white)),
                    ),
                  ),
                );
              }),
          ],
        );
      }),
    );
  }
}

class _HeadPainter extends CustomPainter {
  final Color accent;
  final int current, lugs;
  final bool glow;
  _HeadPainter(this.accent, this.current, this.lugs, this.glow);

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    // sombra
    canvas.drawCircle(c + const Offset(0, 8), r, Paint()
      ..color = Colors.black
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    // aro cromado
    canvas.drawCircle(c, r, Paint()
      ..shader = const SweepGradient(colors: [
        Color(0xFFF2F3F5), Color(0xFF5E626A), Color(0xFFD6D8DC), Color(0xFF3A3D43),
        Color(0xFFEDEEF0), Color(0xFF6B6F77), Color(0xFFF2F3F5),
      ]).createShader(Rect.fromCircle(center: c, radius: r)));
    // pele
    canvas.drawCircle(c, r * 0.9, Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.3),
        radius: 1.0,
        colors: [Color(0xFFE2E4E8), Color(0xFFAEB2B9), Color(0xFF6E737B)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.9)));
    canvas.drawCircle(c, r * 0.9, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.black54);
    // brilho do parafuso ativo
    if (glow) {
      final a = -math.pi / 2 + 2 * math.pi * current / lugs;
      final o = c + Offset(math.cos(a), math.sin(a)) * r * 0.86;
      canvas.drawCircle(o, r * 0.28, Paint()
        ..shader = RadialGradient(colors: [accent.withOpacity(0.55), accent.withOpacity(0)])
            .createShader(Rect.fromCircle(center: o, radius: r * 0.28)));
    }
  }

  @override
  bool shouldRepaint(_HeadPainter o) => o.current != current || o.accent != accent || o.lugs != lugs;
}
