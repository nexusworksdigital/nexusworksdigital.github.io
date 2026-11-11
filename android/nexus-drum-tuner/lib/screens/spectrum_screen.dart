import 'package:flutter/material.dart';

import '../audio/audio_engine.dart';
import '../audio/music.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/spectrum_view.dart';

/// Página 03 · Spectrum Analyzer — laboratório acústico.
class SpectrumScreen extends StatelessWidget {
  const SpectrumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, audio]),
      builder: (context, _) {
        final st = app.settings;
        final r = audio.reading;
        final note = r == null ? null : noteFromFreq(r.hz, a4: st.a4, notation: st.notation);
        final view = app.spectrumView;

        Widget graph;
        if (view == 'cascade') {
          graph = CascadeView(rows: audio.spectrogram);
        } else if (view == 'heatmap') {
          graph = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: HeatmapView(rows: audio.spectrogram),
          );
        } else {
          graph = SpectrumView(
            db: audio.spectrumDb,
            sampleRate: AudioEngine.sampleRate,
            fftSize: AudioEngine.fftSize,
            harmonics: r?.harmonics.take(4).toList() ?? const [],
            logAxis: st.curve != 'linear',
            band: audio.band,
          );
        }

        final quality = r?.quality;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const NexusHeader(),
            PageTitle(
              'Analisador de Espectro',
              subtitle: '${app.drumName(app.drum)} – ${app.headTop ? 'Topo (Batedor)' : 'Fundo (Resposta)'}',
              trailing: OutlineBtn(
                label: audio.hold ? 'Congelado' : 'Tempo Real',
                icon: audio.hold ? Icons.pause : Icons.play_arrow,
                accent: audio.hold,
                height: 36,
                onPressed: audio.toggleHold,
              ),
            ),
            SizedBox(height: 250, child: graph),
            const MicProblem(),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                flex: 5,
                child: StatCard(
                  label: 'Fundamental',
                  value: r == null ? '--' : '${st.hz(r.hz)} Hz',
                  valueColor: NX.accent,
                  center: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(flex: 3, child: StatCard(label: 'Nota', value: note?.label ?? '--', center: true)),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: StatCard(
                  label: 'Qualidade',
                  value: quality == null ? '--' : '${(quality * 100).round()}%',
                  center: true,
                  footer: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: quality ?? 0,
                      minHeight: 5,
                      color: NX.ok,
                      backgroundColor: NX.border,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: StatCard(
                  label: 'Estabilidade',
                  value: r?.stabilityLabel ?? '--',
                  valueColor: r == null
                      ? NX.white
                      : r.stabilityLabel == 'Alta'
                          ? NX.ok
                          : r.stabilityLabel == 'Média'
                              ? NX.warn
                              : NX.bad,
                  center: true,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final table = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('Harmônicos Detectados'),
                if (r == null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Bata no tambor para analisar.', style: NX.inter(12.5, c: NX.metal)),
                  )
                else
                  for (final h in r.harmonics)
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: NX.card,
                        border: Border.all(
                            color: h.order == 1 ? NX.accent : NX.border, width: h.order == 1 ? 1.4 : 1),
                      ),
                      child: Row(children: [
                        Container(
                          width: 34,
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: h.order == 1 ? NX.accent.withOpacity(0.25) : NX.cardHi,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('H${h.order}',
                              style: NX.inter(12, w: FontWeight.w700, c: h.order == 1 ? NX.accent : NX.white)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${st.hz(h.hz)} Hz', style: NX.inter(13, c: NX.white))),
                        Text('(${noteFromFreq(h.hz, a4: st.a4, notation: st.notation).label})',
                            style: NX.inter(12, c: NX.silver)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 46,
                          child: Text('${h.relDb.toStringAsFixed(0)} dB',
                              textAlign: TextAlign.right, style: NX.inter(12, c: NX.silver)),
                        ),
                      ]),
                    ),
              ]);
              final heat = Container(
                height: 230,
                decoration: NX.cardDeco(radius: 12),
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: HeatmapView(rows: audio.spectrogram, vertical: true),
                ),
              );
              if (c.maxWidth < 380) {
                return Column(children: [table, const SizedBox(height: 10), heat]);
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 11, child: table),
                const SizedBox(width: 10),
                Expanded(flex: 9, child: Padding(padding: const EdgeInsets.only(top: 26), child: heat)),
              ]);
            }),
            const SizedBox(height: 14),
            NxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Visualização', style: NX.inter(12.5, c: NX.white)),
                const SizedBox(height: 6),
                Segmented<String>(
                  value: view,
                  onChanged: app.setSpectrumView,
                  height: 44,
                  items: const [
                    ('spectrum', 'Espectro', Icons.equalizer),
                    ('cascade', 'Cascata', Icons.landscape_outlined),
                    ('heatmap', 'Heatmap', Icons.grid_view),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Filtro', style: NX.inter(12.5, c: NX.white)),
                const SizedBox(height: 6),
                Segmented<String>(
                  value: app.spectrumFilter,
                  onChanged: app.setSpectrumFilter,
                  items: const [
                    ('off', 'Off', null),
                    ('low', 'Low', null),
                    ('mid', 'Mid', null),
                    ('high', 'High', null),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  switch (app.spectrumFilter) {
                    'low' => 'Low: 30–160 Hz (bumbo e surdo)',
                    'mid' => 'Mid: 150–700 Hz (caixa e tons)',
                    'high' => 'High: 600 Hz–5 kHz (ataque e esteira)',
                    _ => 'Sem filtro: faixa do tambor selecionado',
                  },
                  style: NX.inter(11.5, c: NX.metal),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }
}
