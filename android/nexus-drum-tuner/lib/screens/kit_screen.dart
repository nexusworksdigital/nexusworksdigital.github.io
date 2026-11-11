import 'package:flutter/material.dart';

import '../audio/music.dart';
import '../models/drum.dart';
import '../models/preset.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';

/// Página 04 · My Kit — gerenciador da bateria.
class KitScreen extends StatefulWidget {
  const KitScreen({super.key});

  @override
  State<KitScreen> createState() => _KitScreenState();
}

class _KitScreenState extends State<KitScreen> {
  String? styleView;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final st = app.settings;
        final style = styleView ?? app.preset.style;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const NexusHeader(),
            PageTitle(
              'Meu Kit',
              subtitle: 'Configuração, afinação e gerenciamento do seu set',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                OutlineBtn(
                  label: 'Novo',
                  icon: Icons.add,
                  height: 36,
                  onPressed: () => editDrum(context, null),
                ),
                PopupMenuButton<String>(
                  color: NX.cardHi,
                  icon: const Icon(Icons.more_vert, color: NX.white),
                  onSelected: (v) async {
                    if (v == 'order') reorderKit(context);
                    if (v == 'sizes') {
                      app.restoreSizes();
                      toast(context, 'Tamanhos do preset restaurados.');
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'order', child: Text('Ordem de exibição')),
                    PopupMenuItem(value: 'sizes', child: Text('Restaurar tamanhos padrão')),
                  ],
                ),
              ]),
            ),
            const _KitPicture(),
            const SizedBox(height: 12),
            // Seleção de estilo
            NxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionLabel(
                  'Seleção de Estilo (Presets)',
                  trailing: OutlineBtn(
                    label: 'Salvar como Preset',
                    icon: Icons.save_outlined,
                    height: 32,
                    onPressed: () async {
                      final n = await askText(context, 'Nome do preset', hint: 'Ex.: Meu Rock');
                      if (n != null && n.isNotEmpty) {
                        app.saveKitAsPreset(n);
                        if (context.mounted) toast(context, 'Preset "$n" salvo.');
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 92,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in app.presets.where((p) => p.builtIn))
                        _StyleChip(
                          preset: p,
                          selected: app.activePreset == p.id,
                          onTap: () async {
                            final ok = await confirm(context, 'Aplicar ${Preset.styleLabel(p.style)}?',
                                'O kit atual será trocado pela sugestão do estilo. Você poderá editar tudo depois.');
                            if (ok) {
                              app.applyPreset(p);
                              setState(() => styleView = p.style);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            NxCard(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
              child: Column(children: [
                const SectionLabel('Configuração de Tambores'),
                for (var i = 0; i < app.kit.length; i++)
                  _DrumRow(index: i),
              ]),
            ),
            const SizedBox(height: 12),
            NxCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('Personalizar por Estilo'),
                DropdownButtonFormField<String>(
                  value: Preset.styles.contains(style) ? style : 'rock',
                  dropdownColor: NX.cardHi,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.album_outlined, color: NX.accent),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NX.accent)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NX.accent)),
                  ),
                  items: [
                    for (final s in Preset.styles)
                      DropdownMenuItem(value: s, child: Text(Preset.styleLabel(s))),
                  ],
                  onChanged: (v) => setState(() => styleView = v),
                ),
                const SizedBox(height: 10),
                Text('Configuração do Estilo', style: NX.inter(13, w: FontWeight.w600, c: NX.white)),
                const SizedBox(height: 6),
                for (final rule in Preset.styleRules(Preset.styles.contains(style) ? style : 'rock'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.check, color: NX.ok, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(rule, style: NX.inter(12.5))),
                    ]),
                  ),
                const Divider(height: 20),
                Text('Variações Rápidas', style: NX.inter(13, w: FontWeight.w600, c: NX.white)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in [DrumType.snare, DrumType.tom, DrumType.floor, DrumType.kick])
                    PopupMenuButton<double>(
                      color: NX.cardHi,
                      onSelected: (d) => app.setTypeDiameter(t, d),
                      itemBuilder: (_) => [
                        for (final d in t.diameters)
                          PopupMenuItem(value: d, child: Text(st.size(d))),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: NX.border),
                          color: NX.card,
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const DrumIcon(size: 18),
                          const SizedBox(width: 6),
                          Text(t == DrumType.tom ? 'Tons' : t.label, style: NX.inter(13, c: NX.white)),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: NX.silver),
                        ]),
                      ),
                    ),
                ]),
              ]),
            ),
          ],
        );
      },
    );
  }
}

/// Ilustração da bateria com etiquetas tocáveis.
class _KitPicture extends StatelessWidget {
  const _KitPicture();

  // posição (x, y) relativa das etiquetas na ilustração
  static const _spots = {
    'tom0': (0.358, 0.086),
    'tom1': (0.502, 0.086),
    'tom2': (0.651, 0.086),
    'snare': (0.145, 0.49),
    'floor': (0.888, 0.49),
    'kick': (0.5, 0.855),
  };

  @override
  Widget build(BuildContext context) {
    // liga cada tambor do kit a uma posição da ilustração
    final placed = <String, int>{};
    var tom = 0;
    for (var i = 0; i < app.kit.length; i++) {
      final d = app.kit[i];
      String? key;
      switch (d.type) {
        case DrumType.snare:
          key = 'snare';
        case DrumType.floor:
          key = 'floor';
        case DrumType.kick:
          key = 'kick';
        case DrumType.tom:
          if (tom < 3) key = 'tom${tom++}';
        case DrumType.other:
          key = null;
      }
      if (key != null && !placed.containsKey(key)) placed[key] = i;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 941 / 488,
        child: LayoutBuilder(builder: (context, c) {
          return Stack(children: [
            Positioned.fill(child: Image.asset('assets/img/kit.jpg', fit: BoxFit.cover)),
            for (final e in placed.entries)
              Builder(builder: (context) {
                final pos = _spots[e.key]!;
                final d = app.kit[e.value];
                final sel = e.value == app.selected;
                final w = c.maxWidth * 0.2;
                return Positioned(
                  left: c.maxWidth * pos.$1 - w / 2,
                  top: c.maxHeight * pos.$2 - 18,
                  width: w,
                  child: GestureDetector(
                    onTap: () => drumDetails(context, e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.78),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NX.accent, width: sel ? 2 : 1.2),
                        boxShadow: NX.glowShadow(blur: sel ? 14 : 8, opacity: sel ? 0.6 : 0.35),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(d.name, style: NX.inter(12, w: FontWeight.w600, c: NX.white)),
                          Text('${app.settings.size(d.diameter)} x ${app.settings.size(d.depth)}',
                              style: NX.inter(11, c: NX.white)),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
          ]);
        }),
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  final Preset preset;
  final bool selected;
  final VoidCallback onTap;
  const _StyleChip({required this.preset, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 112,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? NX.accent : NX.border, width: selected ? 2 : 1),
          boxShadow: selected ? NX.glowShadow(blur: 12) : null,
          image: DecorationImage(image: AssetImage(preset.image), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.3, 1],
            ),
          ),
          padding: const EdgeInsets.all(6),
          alignment: Alignment.bottomCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(Preset.styleLabel(preset.style), style: NX.sora(15, w: FontWeight.w700)),
            Text(Preset.styleHint(preset.style),
                maxLines: 1, overflow: TextOverflow.ellipsis, style: NX.inter(10.5, c: NX.silver)),
          ]),
        ),
      ),
    );
  }
}

class _DrumRow extends StatelessWidget {
  final int index;
  const _DrumRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final st = app.settings;
    final d = app.kit[index];
    final sel = index == app.selected;
    return InkWell(
      onTap: () => drumDetails(context, index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: sel ? NX.accent.withOpacity(0.07) : NX.cardHi.withOpacity(0.5),
        ),
        child: Row(children: [
          Container(width: 3, height: 36, color: NX.accent),
          const SizedBox(width: 10),
          DrumIcon(size: 30, color: sel ? NX.accent : NX.silver),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.drumName(d), style: NX.inter(13.5, w: FontWeight.w600, c: NX.white)),
              Text('${st.size(d.diameter)} x ${st.size(d.depth)}', style: NX.inter(11.5, c: NX.metal)),
            ]),
          ),
          Text('${st.hz(d.targetHz)} Hz', style: NX.inter(13.5, c: NX.white)),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(noteFromFreq(d.targetHz, a4: st.a4, notation: st.notation).label,
                style: NX.sora(13.5, w: FontWeight.w700, c: NX.accent)),
          ),
          tuneStatusIcon(d, size: 28),
          const Icon(Icons.chevron_right, color: NX.silver),
        ]),
      ),
    );
  }
}

/// Detalhes de afinação de uma peça (Drum Profile).
void drumDetails(BuildContext context, int index) {
  final d = app.kit[index];
  final st = app.settings;
  showModalBottomSheet(
    context: context,
    backgroundColor: NX.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            DrumIcon(size: 34, color: NX.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.drumName(d), style: NX.sora(18)),
                Text('${st.size(d.diameter)} x ${st.size(d.depth)} · ${d.lugs} parafusos',
                    style: NX.inter(12.5, c: NX.metal)),
              ]),
            ),
            tuneStatusIcon(d, size: 34),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: StatCard(label: 'Alvo', value: '${st.hz(d.targetHz)} Hz', center: true)),
            const SizedBox(width: 8),
            Expanded(
                child: StatCard(
                    label: 'Nota',
                    value: noteFromFreq(d.targetHz, a4: st.a4, notation: st.notation).label,
                    valueColor: NX.accent,
                    center: true)),
            const SizedBox(width: 8),
            Expanded(
              child: StatCard(
                label: 'Última leitura',
                value: d.lastHz == null ? '--' : '${st.hz(d.lastHz!)} Hz',
                valueColor: d.lastCents == null ? NX.white : NX.statusColor(d.lastCents!.abs()),
                center: true,
              ),
            ),
          ]),
          if (d.brand.isNotEmpty || d.headModel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              [if (d.brand.isNotEmpty) 'Marca: ${d.brand}', if (d.headModel.isNotEmpty) 'Pele: ${d.headModel}']
                  .join('   ·   '),
              style: NX.inter(12.5),
            ),
          ],
          if (d.sessions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('${d.sessions.length} medição(ões) salva(s) — veja Antes & Depois em Lugs.',
                style: NX.inter(12, c: NX.metal)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: PrimaryButton(
                label: 'Afinar',
                icon: Icons.speed,
                onPressed: () {
                  app.selectDrum(index);
                  app.goTab(0);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlineBtn(
                label: 'Parafusos',
                icon: Icons.blur_circular,
                height: 46,
                onPressed: () {
                  app.selectDrum(index);
                  app.goTab(1);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlineBtn(
              label: 'Editar',
              icon: Icons.edit_outlined,
              accent: true,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
                editDrum(context, index);
              },
            ),
          ]),
        ]),
      ),
    ),
  );
}

/// Cria (index == null) ou edita um tambor — cadastro completo.
Future<void> editDrum(BuildContext context, int? index) async {
  final existing = index == null ? null : app.kit[index];
  final st = app.settings;
  var type = existing?.type ?? DrumType.tom;
  final name = TextEditingController(text: existing?.name ?? 'Tom');
  final brand = TextEditingController(text: existing?.brand ?? '');
  final head = TextEditingController(text: existing?.headModel ?? '');
  final target = TextEditingController(text: (existing?.targetHz ?? 147).toStringAsFixed(1));
  var diameter = existing?.diameter ?? 12.0;
  var depth = existing?.depth ?? 9.0;
  var lugs = existing?.lugs ?? 6;

  List<double> withValue(List<double> base, double v) =>
      base.contains(v) ? base : ([...base, v]..sort());

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NX.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Novo tambor' : 'Drum Profile', style: NX.sora(17)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 6, children: [
                for (final t in DrumType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: type == t,
                    selectedColor: NX.accent.withOpacity(0.3),
                    onSelected: (_) => setS(() {
                      type = t;
                      if (existing == null) {
                        name.text = t.label;
                        diameter = t.diameters[t.diameters.length ~/ 2];
                        depth = t.depths[t.depths.length ~/ 2];
                        lugs = t.defaultLugs;
                      }
                    }),
                  ),
              ]),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: diameter,
                    dropdownColor: NX.cardHi,
                    decoration: const InputDecoration(labelText: 'Diâmetro'),
                    items: [
                      for (final v in withValue(type.diameters, diameter))
                        DropdownMenuItem(value: v, child: Text(st.size(v))),
                    ],
                    onChanged: (v) => setS(() => diameter = v ?? diameter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: depth,
                    dropdownColor: NX.cardHi,
                    decoration: const InputDecoration(labelText: 'Profundidade'),
                    items: [
                      for (final v in withValue(type.depths, depth))
                        DropdownMenuItem(value: v, child: Text(st.size(v))),
                    ],
                    onChanged: (v) => setS(() => depth = v ?? depth),
                  ),
                ),
              ]),
              Row(children: [
                Expanded(child: TextField(controller: brand, decoration: const InputDecoration(labelText: 'Marca'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: head, decoration: const InputDecoration(labelText: 'Pele'))),
              ]),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Afinação desejada', suffixText: 'Hz'),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Text('Parafusos', style: NX.inter(13.5)),
                const Spacer(),
                IconButton(
                    onPressed: lugs > 3 ? () => setS(() => lugs--) : null,
                    icon: const Icon(Icons.remove_circle_outline)),
                Text('$lugs', style: NX.mono(22)),
                IconButton(
                    onPressed: lugs < 16 ? () => setS(() => lugs++) : null,
                    icon: const Icon(Icons.add_circle_outline)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                if (existing != null && app.kit.length > 1)
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: NX.bad),
                    onPressed: () {
                      app.removeDrum(index!);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                const Spacer(),
                PrimaryButton(
                  label: 'Salvar',
                  icon: Icons.check,
                  onPressed: () {
                    final hz = double.tryParse(target.text.replaceAll(',', '.')) ?? 147;
                    final nm = name.text.trim().isEmpty ? type.label : name.text.trim();
                    if (existing == null) {
                      app.addDrum(Drum(
                        id: 'd${DateTime.now().millisecondsSinceEpoch}',
                        type: type,
                        name: nm,
                        diameter: diameter,
                        depth: depth,
                        lugs: lugs,
                        targetHz: hz,
                        brand: brand.text.trim(),
                        headModel: head.text.trim(),
                      ));
                    } else {
                      existing
                        ..type = type
                        ..name = nm
                        ..diameter = diameter
                        ..depth = depth
                        ..targetHz = hz
                        ..brand = brand.text.trim()
                        ..headModel = head.text.trim();
                      if (existing.lugs != lugs) existing.setLugCount(lugs);
                      app.updateDrum(existing);
                    }
                    Navigator.pop(ctx);
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ordem de exibição dos tambores.
void reorderKit(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: NX.card,
    builder: (ctx) => ListenableBuilder(
      listenable: app,
      builder: (ctx, _) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text('Arraste para reordenar', style: NX.sora(15)),
          ),
          Flexible(
            child: ReorderableListView(
              shrinkWrap: true,
              onReorder: app.reorderKit,
              children: [
                for (final d in app.kit)
                  ListTile(
                    key: ValueKey(d.id),
                    leading: const DrumIcon(),
                    title: Text(app.drumName(d), style: NX.inter(14, c: NX.white)),
                    subtitle: Text(d.sizeLabel, style: NX.inter(12, c: NX.metal)),
                    trailing: const Icon(Icons.drag_handle),
                  ),
              ],
            ),
          ),
        ]),
      ),
    ),
  );
}
