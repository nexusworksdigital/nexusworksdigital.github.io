import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/music.dart';
import '../models/drum.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/lug_map.dart';
import '../widgets/meters.dart';

/// Página 02 · Lugs — afinação individual dos parafusos.
class LugsScreen extends StatelessWidget {
  const LugsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, audio]),
      builder: (context, _) {
        final st = app.settings;
        final d = app.drum;
        final values = app.lugValues;
        final measured = values.whereType<double>().toList();
        final avg = measured.isEmpty ? null : measured.reduce((a, b) => a + b) / measured.length;
        final i = app.currentLug.clamp(0, d.lugs - 1);
        final v = i < values.length ? values[i] : null;
        final armed = app.armedLug != null;
        final ref = avg;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const NexusHeader(),
            GestureDetector(
              onTap: () => pickDrum(context),
              child: PageTitle(
                'Mapa de Parafusos (Lugs)',
                subtitle: '${app.drumName(d)} – ${d.lugs} Parafusos  ⌄',
                trailing: OutlineBtn(
                  label: app.headTop ? 'Topo (Batedor)' : 'Fundo (Resposta)',
                  icon: Icons.swap_vert,
                  accent: true,
                  height: 36,
                  onPressed: () => app.setHead(!app.headTop),
                ),
              ),
            ),
            Builder(builder: (context) {
              final opts = {...d.type.lugOptions, d.lugs}.toList()..sort();
              return Row(children: [
                Text('Parafusos', style: NX.inter(13, c: NX.white)),
                const SizedBox(width: 10),
                Expanded(
                  child: Segmented<int>(
                    value: d.lugs,
                    height: 34,
                    onChanged: (n) async {
                      final hasData = app.drum.lugTop.any((v) => v != null) ||
                          app.drum.lugBottom.any((v) => v != null);
                      if (hasData &&
                          !await confirm(context, 'Mudar para $n parafusos?',
                              'As medições dos parafusos acima de $n serão descartadas.')) {
                        return;
                      }
                      app.setLugCount(n);
                    },
                    items: [for (final n in opts) (n, '$n', null)],
                  ),
                ),
              ]);
            }),
            const SizedBox(height: 6),
            LugMap(
              lugs: d.lugs,
              values: values,
              reference: ref,
              current: i,
              armed: armed,
              onTap: app.setCurrentLug,
            ),
            const SizedBox(height: 10),
            // parafuso atual
            Row(children: [
              _Arrow(icon: Icons.chevron_left, onTap: () => app.setCurrentLug(i - 1 + d.lugs)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: NX.cardDeco(radius: 14),
                  child: Row(children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lug ${(i + 1).toString().padLeft(2, '0')}',
                              style: NX.inter(13, c: NX.white)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(v == null ? '---.- Hz' : '${st.hz(v)} Hz',
                                style: NX.sora(24, w: FontWeight.w700, c: NX.accent)),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 38, color: NX.border),
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: Text(
                          v == null ? '--' : noteFromFreq(v, a4: st.a4, notation: st.notation).label,
                          style: NX.sora(20, w: FontWeight.w700),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 38, color: NX.border),
                    const SizedBox(width: 8),
                    _lugStatus(v, ref),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              _Arrow(icon: Icons.chevron_right, onTap: () => app.setCurrentLug(i + 1)),
            ]),
            const SizedBox(height: 12),
            PrimaryButton(
              label: armed
                  ? 'Bata perto do parafuso ${(app.armedLug ?? 0) + 1}…'
                  : 'Medir parafuso ${i + 1}',
              icon: armed ? Icons.graphic_eq : Icons.play_arrow,
              onPressed: armed ? app.disarm : app.armLug,
            ),
            const MicProblem(),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final table = _LugTable(values: values, current: i, avg: avg);
              final side = _BalanceCard(values: measured);
              if (c.maxWidth < 360) {
                return Column(children: [table, const SizedBox(height: 10), side]);
              }
              return IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 11, child: table),
                  const SizedBox(width: 10),
                  Expanded(flex: 8, child: side),
                ]),
              );
            }),
            const SizedBox(height: 12),
            _BeforeAfter(drum: d),
          ],
        );
      },
    );
  }

  Widget _lugStatus(double? v, double? ref) {
    if (v == null) {
      return const StatusChip('Medir', color: NX.metal, icon: Icons.touch_app);
    }
    final q = audio.reading?.stabilityLabel ?? 'Alta';
    if (ref != null && centsBetween(v, ref).abs() > 10) {
      return StatusChip(centsBetween(v, ref) < 0 ? 'Aperte' : 'Afrouxe',
          color: NX.warn, icon: Icons.tune);
    }
    return StatusChip(q == 'Baixa' ? 'Instável' : 'Estável',
        color: q == 'Baixa' ? NX.warn : NX.ok);
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Arrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 70,
          decoration: NX.cardDeco(radius: 12),
          child: Icon(icon, color: NX.white, size: 30),
        ),
      );
}

class _LugTable extends StatelessWidget {
  final List<double?> values;
  final int current;
  final double? avg;
  const _LugTable({required this.values, required this.current, required this.avg});

  @override
  Widget build(BuildContext context) {
    final st = app.settings;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: NX.cardDeco(radius: 14),
      child: Column(
        children: [
          for (var k = 0; k < values.length; k++)
            GestureDetector(
              onTap: () => app.setCurrentLug(k),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: k == current ? NX.accent : Colors.transparent, width: 1.4),
                  color: k == current ? NX.accent.withOpacity(0.06) : null,
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: NX.cardHi, borderRadius: BorderRadius.circular(6)),
                    child: Text('Lug ${(k + 1).toString().padLeft(2, '0')}',
                        style: NX.inter(11.5, c: NX.silver)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(values[k] == null ? '—' : '${st.hz(values[k]!)} Hz',
                        style: NX.inter(13, w: FontWeight.w600, c: NX.white)),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                        values[k] == null
                            ? ''
                            : noteFromFreq(values[k]!, a4: st.a4, notation: st.notation).label,
                        style: NX.inter(11.5, c: NX.silver)),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      values[k] == null || avg == null || k == current
                          ? ''
                          : fmtSigned(values[k]! - avg!),
                      textAlign: TextAlign.right,
                      style: NX.inter(11.5,
                          c: values[k] == null || avg == null
                              ? NX.silver
                              : NX.statusColor(centsBetween(values[k]!, avg!).abs())),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final List<double> values;
  const _BalanceCard({required this.values});

  @override
  Widget build(BuildContext context) {
    double? pct;
    if (values.length >= 2) {
      final m = values.reduce((a, b) => a + b) / values.length;
      var acc = 0.0;
      for (final v in values) {
        final c = centsBetween(v, m);
        acc += c * c;
      }
      final std = math.sqrt(acc / values.length);
      pct = (100 - std * 4).clamp(0.0, 100.0);
    }
    final label = pct == null
        ? 'Meça 2+'
        : pct >= 90
            ? 'Uniforme'
            : pct >= 70
                ? 'Quase'
                : 'Desigual';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: NX.cardDeco(radius: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.graphic_eq, color: NX.accent, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text('Equilíbrio da Pele', style: NX.inter(13, w: FontWeight.w600, c: NX.white))),
          ]),
          const SizedBox(height: 8),
          RingGauge(
            value: (pct ?? 0) / 100,
            size: 118,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(pct == null ? '--' : '${pct.round()}%', style: NX.sora(26, w: FontWeight.w700)),
              Text(label, style: NX.inter(12, w: FontWeight.w600, c: NX.accent)),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Recalibrar',
              icon: Icons.gps_fixed,
              height: 40,
              onPressed: app.recalibrate,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlineBtn(
              label: 'Salvar Medição',
              icon: Icons.save_outlined,
              onPressed: () {
                final ok = app.saveMeasurement();
                toast(context, ok ? 'Medição salva (Antes & Depois).' : 'Meça pelo menos um parafuso.');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Before & After: compara a última medição salva com a atual.
class _BeforeAfter extends StatelessWidget {
  final Drum drum;
  const _BeforeAfter({required this.drum});

  @override
  Widget build(BuildContext context) {
    final st = app.settings;
    final saved = drum.sessions.where((s) => s.top == app.headTop).toList();
    if (saved.isEmpty) return const SizedBox.shrink();
    final before = saved.last;
    final now = app.lugValues;
    String fmt(double? v) => v == null ? '—' : st.hz(v);
    return NxCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionLabel('Antes & Depois',
            trailing: Text(
                '${before.at.day.toString().padLeft(2, '0')}/${before.at.month.toString().padLeft(2, '0')} '
                '${before.at.hour.toString().padLeft(2, '0')}:${before.at.minute.toString().padLeft(2, '0')}',
                style: NX.inter(11, c: NX.metal))),
        Row(children: [
          const SizedBox(width: 56),
          Expanded(child: Text('Antes', style: NX.inter(11.5, c: NX.metal))),
          Expanded(child: Text('Agora', style: NX.inter(11.5, c: NX.metal))),
          SizedBox(width: 50, child: Text('Dif.', textAlign: TextAlign.right, style: NX.inter(11.5, c: NX.metal))),
        ]),
        const Divider(height: 10),
        for (var k = 0; k < math.min(before.lugs.length, now.length); k++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              SizedBox(width: 56, child: Text('Lug ${k + 1}', style: NX.inter(12, c: NX.silver))),
              Expanded(child: Text(fmt(before.lugs[k]), style: NX.mono(15, c: NX.metal))),
              Expanded(child: Text(fmt(now[k]), style: NX.mono(15))),
              SizedBox(
                width: 50,
                child: Text(
                  before.lugs[k] == null || now[k] == null ? '' : fmtSigned(now[k]! - before.lugs[k]!),
                  textAlign: TextAlign.right,
                  style: NX.mono(14, c: NX.accent),
                ),
              ),
            ]),
          ),
      ]),
    );
  }
}
