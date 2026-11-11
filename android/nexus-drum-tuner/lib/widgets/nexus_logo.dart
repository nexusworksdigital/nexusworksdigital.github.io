import 'package:flutter/material.dart';

import '../theme/nexus_theme.dart';

/// Símbolo de onda da Nexus.
class NexusMark extends StatelessWidget {
  final double size;
  final Color? color;
  const NexusMark({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size(size, size), painter: _MarkPainter(color ?? NX.accent));
}

class _MarkPainter extends CustomPainter {
  final Color color;
  _MarkPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round;
    const h = [0.26, 0.5, 0.95, 0.7, 0.42, 0.22];
    const slant = 0.22;
    for (var i = 0; i < h.length; i++) {
      final x = s.width * (0.12 + i * 0.152);
      final half = s.height * h[i] / 2;
      final cy = s.height / 2;
      canvas.drawLine(Offset(x - half * slant, cy + half),
          Offset(x + half * slant, cy - half), p);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

/// Marca horizontal: símbolo + NEXUS / DRUM TUNER.
class NexusLogo extends StatelessWidget {
  final double scale;
  const NexusLogo({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexusMark(size: 34 * scale),
        SizedBox(width: 8 * scale),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NEXUS',
                  style: NX.sora(24 * scale, w: FontWeight.w800, ls: 1.5 * scale)
                      .copyWith(height: 1.0)),
              Text('®', style: NX.inter(7 * scale, c: NX.silver)),
            ]),
            Text('DRUM  TUNER',
                style: NX.inter(8 * scale, w: FontWeight.w600, c: NX.silver, ls: 3.6 * scale)),
          ],
        ),
      ],
    );
  }
}

/// Marca vertical (splash).
class NexusWordmark extends StatelessWidget {
  final double scale;
  const NexusWordmark({super.key, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexusMark(size: 64 * scale),
        SizedBox(height: 14 * scale),
        Text('NEXUS', style: NX.sora(40 * scale, w: FontWeight.w800, ls: 3 * scale)),
        SizedBox(height: 2 * scale),
        Text('DRUM  TUNER',
            style: NX.inter(11 * scale, w: FontWeight.w600, c: NX.silver, ls: 6 * scale)),
      ],
    );
  }
}
