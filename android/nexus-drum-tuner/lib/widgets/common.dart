import 'package:flutter/material.dart';

import '../audio/audio_engine.dart';
import '../models/drum.dart';
import '../screens/updates_screen.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import 'meters.dart';
import 'nexus_logo.dart';

/// Cabeçalho: menu · logo · nuvem · ajustes.
class NexusHeader extends StatelessWidget {
  const NexusHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: NX.white, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const Expanded(child: Center(child: NexusLogo(scale: 0.82))),
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: NX.white, size: 24),
            onPressed: () => app.goTab(5),
          ),
        ],
      ),
    );
  }
}

/// Título de página com barra laranja.
class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: subtitle == null ? 26 : 42,
            decoration: BoxDecoration(
              color: NX.accent,
              borderRadius: BorderRadius.circular(2),
              boxShadow: NX.glowShadow(blur: 8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(title, style: NX.sora(22, w: FontWeight.w700)),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NX.inter(12.5, c: NX.silver)),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

/// Título de seção dentro de cards.
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 3, height: 16, color: NX.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: NX.sora(14.5, w: FontWeight.w600))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Card grafite padrão.
class NxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool active;
  const NxCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.active = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: NX.cardDeco(active: active),
        child: child,
      );
}

/// Seletor de tambor: "Tambor | [ícone] Caixa (Snare) ⌄".
class DrumSelector extends StatelessWidget {
  final bool showLugs;
  const DrumSelector({super.key, this.showLugs = false});

  @override
  Widget build(BuildContext context) {
    final d = app.drum;
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () => pickDrum(context),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: NX.card,
          border: Border.all(color: NX.border),
        ),
        child: Row(children: [
          Text('Tambor', style: NX.inter(14, c: NX.white)),
          Container(width: 1, height: 26, margin: const EdgeInsets.symmetric(horizontal: 14), color: NX.border),
          DrumIcon(size: 26, color: NX.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              showLugs ? '${app.drumName(d)} – ${d.lugs} Parafusos' : app.drumName(d),
              overflow: TextOverflow.ellipsis,
              style: NX.inter(15, w: FontWeight.w500, c: NX.white),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: NX.white),
        ]),
      ),
    );
  }
}

void pickDrum(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: NX.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Escolha o tambor', style: NX.sora(15)),
            const SizedBox(height: 8),
            for (var i = 0; i < app.kit.length; i++)
              ListTile(
                leading: DrumIcon(color: i == app.selected ? NX.accent : NX.silver),
                title: Text(app.drumName(app.kit[i]), style: NX.inter(14, c: NX.white)),
                subtitle: Text(
                    '${app.settings.size(app.kit[i].diameter)} · alvo ${app.settings.hz(app.kit[i].targetHz)} Hz · ${app.kit[i].lugs} parafusos',
                    style: NX.inter(12, c: NX.metal)),
                trailing: i == app.selected ? Icon(Icons.check, color: NX.accent) : null,
                onTap: () {
                  app.selectDrum(i);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Ícone linear de tambor.
class DrumIcon extends StatelessWidget {
  final double size;
  final Color color;
  const DrumIcon({super.key, this.size = 22, this.color = NX.silver});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _DrumIconPainter(color));
}

class _DrumIconPainter extends CustomPainter {
  final Color color;
  _DrumIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.075
      ..strokeCap = StrokeCap.round;
    final w = s.width, h = s.height;
    canvas.drawOval(Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.26), p);
    canvas.drawLine(Offset(w * 0.06, h * 0.31), Offset(w * 0.06, h * 0.7), p);
    canvas.drawLine(Offset(w * 0.94, h * 0.31), Offset(w * 0.94, h * 0.7), p);
    canvas.drawArc(Rect.fromLTWH(w * 0.06, h * 0.57, w * 0.88, h * 0.26), 0, 3.14159, false, p);
    for (final x in [0.28, 0.5, 0.72]) {
      canvas.drawLine(Offset(w * x, h * 0.46), Offset(w * x, h * 0.8), p);
    }
  }

  @override
  bool shouldRepaint(_DrumIconPainter o) => o.color != color;
}

/// Card de valor (Alvo, Desvio, Nota...).
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color valueColor;
  final bool active;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool center;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor = NX.white,
    this.active = false,
    this.footer,
    this.onTap,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    final col = Column(
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: NX.inter(12, c: NX.silver)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: NX.sora(21, w: FontWeight.w700, c: valueColor)),
        ),
        if (footer != null) ...[const SizedBox(height: 4), footer!],
      ],
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: NX.cardDeco(active: active),
        child: icon == null
            ? (center ? Center(child: col) : col)
            : Row(children: [
                Icon(icon, color: NX.white, size: 26),
                const SizedBox(width: 12),
                Expanded(child: col),
              ]),
      ),
    );
  }
}

/// Botão principal branco (texto escuro).
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;
  const PrimaryButton({super.key, required this.label, this.icon, this.onPressed, this.height = 46});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: NX.silver,
          foregroundColor: NX.graphite,
          disabledBackgroundColor: NX.cardHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(height / 2)),
        ),
        onPressed: onPressed,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: NX.inter(14, w: FontWeight.w600, c: NX.graphite)),
          ),
        ]),
      ),
    );
  }
}

/// Botão contornado (laranja quando [accent]).
class OutlineBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool accent;
  final double height;
  const OutlineBtn({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.accent = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final c = accent ? NX.accent : NX.white;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: accent ? NX.accent.withOpacity(0.08) : NX.card,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: accent ? NX.accent : NX.border, width: accent ? 1.5 : 1),
          boxShadow: accent ? NX.glowShadow(blur: 10, opacity: 0.3) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          if (icon != null) ...[Icon(icon, size: 18, color: c), const SizedBox(width: 6)],
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: NX.inter(13, w: FontWeight.w600, c: accent ? NX.accent : NX.white)),
          ),
        ]),
      ),
    );
  }
}

/// Grupo de opções (laranja no selecionado).
class Segmented<T> extends StatelessWidget {
  final List<(T, String, IconData?)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  const Segmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: NX.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NX.border),
      ),
      child: Row(children: [
        for (final it in items)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(it.$1),
              child: AnimatedContainer(
                duration: Duration(milliseconds: NX.animations ? 180 : 0),
                height: height,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: it.$1 == value ? NX.accent.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: it.$1 == value ? NX.accent : Colors.transparent, width: 1.4),
                  boxShadow: it.$1 == value ? NX.glowShadow(blur: 10, opacity: 0.3) : null,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (it.$3 != null) ...[
                    Icon(it.$3, size: 16, color: it.$1 == value ? NX.accent : NX.silver),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(it.$2,
                        overflow: TextOverflow.ellipsis,
                        style: NX.inter(12.5,
                            w: FontWeight.w600,
                            c: it.$1 == value ? NX.accent : NX.silver)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Selo de status (ex.: "Estável").
class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const StatusChip(this.text, {super.key, required this.color, this.icon = Icons.check});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
          color: color.withOpacity(0.1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(text, style: NX.inter(12, w: FontWeight.w600, c: color)),
        ]),
      );
}

/// Bolinha do microfone.
class MicDot extends StatelessWidget {
  const MicDot({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: audio,
        builder: (context, _) {
          final on = audio.listening;
          return Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? NX.ok : NX.dim,
              boxShadow: on ? [BoxShadow(color: NX.ok.withOpacity(0.6), blurRadius: 6)] : null,
            ),
          );
        },
      );
}

/// Indicador de sinal ligado ao motor.
class LiveSignal extends StatelessWidget {
  const LiveSignal({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: audio,
        builder: (_, __) => SignalIndicator(levelDb: audio.levelDb, on: audio.listening),
      );
}

/// Aviso de microfone negado / com erro.
class MicProblem extends StatelessWidget {
  const MicProblem({super.key});

  @override
  Widget build(BuildContext context) {
    if (audio.state != MicState.denied && audio.state != MicState.error) {
      return const SizedBox.shrink();
    }
    final msg = audio.state == MicState.denied
        ? 'Permita o acesso ao microfone nas configurações do aparelho.'
        : 'Não foi possível abrir o microfone. ${audio.error ?? ''}';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: NX.cardDeco(borderColor: NX.bad.withOpacity(0.6)),
      child: Row(children: [
        const Icon(Icons.mic_off, color: NX.bad, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: NX.inter(12))),
      ]),
    );
  }
}

/// Status de afinação de um tambor (check verde, alerta, sem leitura).
Widget tuneStatusIcon(Drum d, {double size = 30}) {
  final c = d.lastCents;
  final (color, icon) = c == null
      ? (NX.dim, Icons.remove)
      : c.abs() <= 10
          ? (NX.ok, Icons.check)
          : (NX.warn, Icons.warning_amber_rounded);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.12),
      border: Border.all(color: color.withOpacity(0.7)),
    ),
    child: Icon(icon, size: size * 0.6, color: color),
  );
}

Future<String?> askText(BuildContext context, String title,
    {String initial = '', String? hint, bool number = false, String? suffix}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NX.card,
      title: Text(title, style: NX.sora(16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: number ? NX.mono(26) : NX.inter(15, c: NX.white),
        decoration: InputDecoration(hintText: hint, suffixText: suffix),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: NX.accent, foregroundColor: NX.white),
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<bool> confirm(BuildContext context, String title, String msg) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NX.card,
      title: Text(title, style: NX.sora(16)),
      content: Text(msg, style: NX.inter(13.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: NX.accent, foregroundColor: NX.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
