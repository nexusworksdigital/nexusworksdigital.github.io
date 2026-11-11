import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/music.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/meters.dart';
import '../widgets/nexus_logo.dart';

/// Página 01 · Tuner — afinador principal.
class TunerScreen extends StatelessWidget {
  const TunerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, audio]),
      builder: (context, _) {
        final st = app.settings;
        final d = app.drum;
        final r = audio.reading;
        final hz = r?.hz;
        final span = math.max(20.0, d.targetHz * 0.12);
        final lo = d.targetHz - span, hi = d.targetHz + span;
        final note = hz == null ? null : noteFromFreq(hz, a4: st.a4, notation: st.notation);
        final cents = hz == null ? null : centsBetween(hz, d.targetHz);
        final deltaHz = hz == null ? null : hz - d.targetHz;
        final showNote = st.autoNote && st.display != 'hz';
        final showCents = st.display == 'all';

        return Stack(
          children: [
            // caixa integrada ao layout
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: ShaderMask(
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black, Colors.black],
                    stops: [0, 0.28, 1],
                  ).createShader(rect),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset('assets/img/snare.jpg', fit: BoxFit.fitWidth),
                ),
              ),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 150),
              children: [
                const NexusHeader(),
                const SizedBox(height: 4),
                const DrumSelector(),
                const SizedBox(height: 10),
                SegmentArc(
                  min: lo,
                  max: hi,
                  value: hz,
                  target: d.targetHz,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NexusMark(size: 34, color: NX.silver),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(hz == null ? '---.-' : st.hz(hz),
                              style: NX.sora(54, w: FontWeight.w700, ls: -1)),
                          const SizedBox(width: 4),
                          Text('Hz', style: NX.sora(24, w: FontWeight.w500)),
                        ],
                      ),
                      if (showNote)
                        Text(note?.label ?? '--',
                            style: NX.sora(40, w: FontWeight.w800, c: NX.accent)
                                .copyWith(height: 1.05)),
                      if (showCents)
                        Text(cents == null ? ' ' : '${fmtSigned(cents)} cents',
                            style: NX.inter(17, w: FontWeight.w500, c: NX.white)),
                      const SizedBox(height: 8),
                      _StatusPill(cents: cents, listening: audio.listening, hit: audio.hitActive),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  Expanded(
                    child: StatCard(
                      label: 'Alvo',
                      value: '${st.hz(d.targetHz)} Hz',
                      icon: Icons.gps_fixed,
                      onTap: () => editTarget(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Desvio',
                      value: deltaHz == null ? '--' : '${fmtSigned(deltaHz)} Hz',
                      icon: Icons.warning_amber_rounded,
                      valueColor: cents == null ? NX.white : NX.statusColor(cents.abs()),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: NX.cardDeco(radius: 16),
                  child: WaveBars(values: audio.wave, active: audio.listening),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    audio.listening
                        ? 'Sinal ${audio.levelDb.toStringAsFixed(0)} dB · ruído ${audio.noiseDb.toStringAsFixed(0)} dB'
                            '${audio.hitActive ? ' · batida!' : ''}'
                        : 'Toque no microfone para começar',
                    style: NX.inter(11, c: NX.dim),
                  ),
                ),
                const MicProblem(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RoundIcon(
                      icon: Icons.tune,
                      tooltip: 'Usar leitura como alvo',
                      onTap: hz == null
                          ? null
                          : () {
                              app.setTarget(hz);
                              HapticFeedback.lightImpact();
                              toast(context, 'Alvo definido: ${st.hz(hz)} Hz');
                            },
                    ),
                    GestureDetector(
                      onTap: audio.toggle,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: NX.accent, width: 3),
                          boxShadow: audio.listening ? NX.glowShadow(blur: 24, opacity: 0.7) : null,
                          color: NX.bg,
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: audio.listening
                                  ? const [Color(0xFFF4F4F6), Color(0xFFBFC2C8)]
                                  : const [Color(0xFF3A3C42), Color(0xFF1E2025)],
                            ),
                          ),
                          child: Icon(audio.listening ? Icons.mic_none : Icons.mic_off,
                              size: 40, color: audio.listening ? NX.graphite : NX.silver),
                        ),
                      ),
                    ),
                    _RoundIcon(
                      icon: audio.hold ? Icons.lock : Icons.lock_open,
                      tooltip: 'Travar leitura',
                      active: audio.hold,
                      onTap: audio.toggleHold,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

Future<void> editTarget(BuildContext context) async {
  final t = await askText(context, 'Frequência-alvo',
      initial: app.drum.targetHz.toStringAsFixed(1), number: true, suffix: 'Hz');
  final v = double.tryParse((t ?? '').replaceAll(',', '.'));
  if (v != null && v > 20 && v < 2000) app.setTarget(v);
}

class _StatusPill extends StatelessWidget {
  final double? cents;
  final bool listening;
  final bool hit;
  const _StatusPill({required this.cents, required this.listening, required this.hit});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    IconData icon;
    final c = cents;
    if (c == null) {
      text = listening ? (hit ? 'ANALISANDO…' : 'AGUARDANDO BATIDA') : 'MICROFONE DESLIGADO';
      color = NX.metal;
      icon = listening ? Icons.graphic_eq : Icons.mic_off;
    } else if (c.abs() <= 5) {
      text = 'AFINADO';
      color = NX.ok;
      icon = Icons.check;
    } else if (c.abs() <= 30) {
      text = 'PRÓXIMO DO ALVO';
      color = NX.ok;
      icon = Icons.check;
    } else {
      text = c < 0 ? 'BAIXO · APERTE' : 'ALTO · AFROUXE';
      color = c.abs() <= 60 ? NX.warn : NX.bad;
      icon = c < 0 ? Icons.arrow_upward : Icons.arrow_downward;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 1.4),
        color: color.withOpacity(0.12),
        boxShadow: NX.glow ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12)] : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(text, style: NX.inter(14, w: FontWeight.w700, c: color, ls: 0.4)),
      ]),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  const _RoundIcon({required this.icon, required this.tooltip, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF24262B), Color(0xFF111215)],
            ),
            border: Border.all(color: active ? NX.accent : NX.border),
          ),
          child: Icon(icon,
              size: 28, color: onTap == null ? NX.dim : (active ? NX.accent : NX.white)),
        ),
      ),
    );
  }
}
