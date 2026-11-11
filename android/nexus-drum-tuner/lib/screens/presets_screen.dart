import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/music.dart';
import '../models/drum.dart';
import '../models/preset.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';

/// Página 05 · Presets de Afinação — Preset Studio.
class PresetsScreen extends StatefulWidget {
  const PresetsScreen({super.key});

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.preset;
        final lib = app.presets
            .where((x) => search.isEmpty || x.name.toLowerCase().contains(search.toLowerCase()))
            .toList()
          ..sort((a, b) => (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const NexusHeader(),
            PageTitle(
              'Presets de Afinação',
              subtitle: 'Perfis prontos e personalizáveis para cada estilo',
              trailing: OutlineBtn(
                label: 'Novo Preset',
                icon: Icons.add,
                height: 36,
                onPressed: () => _newPreset(context),
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final x in app.presets) _PresetCard(preset: x, selected: x.id == p.id),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Configuração do preset
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 4, height: 22, color: NX.accent),
                  const SizedBox(width: 8),
                  Text('Configuração: ', style: NX.sora(15)),
                  Text(p.name, style: NX.sora(15, c: NX.accent)),
                ]),
                OutlineBtn(label: 'Duplicar', icon: Icons.copy, height: 32, onPressed: () => app.duplicatePreset(p)),
                OutlineBtn(
                  label: 'Renomear',
                  icon: Icons.edit_outlined,
                  height: 32,
                  onPressed: () async {
                    final n = await askText(context, 'Renomear preset', initial: p.name);
                    if (n != null && n.isNotEmpty) app.renamePreset(p, n);
                  },
                ),
                OutlineBtn(
                  label: p.builtIn ? 'Restaurar' : 'Excluir',
                  icon: p.builtIn ? Icons.restore : Icons.delete_outline,
                  height: 32,
                  onPressed: () async {
                    final ok = await confirm(context, p.builtIn ? 'Restaurar original?' : 'Excluir preset?',
                        p.builtIn ? 'Desfaz suas edições neste preset de fábrica.' : 'Esta ação não pode ser desfeita.');
                    if (ok) app.deletePreset(p);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            NxCard(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
              child: Column(children: [
                Row(children: [
                  const SizedBox(width: 34),
                  Expanded(flex: 4, child: Text('Tambor', style: NX.inter(11.5, c: NX.metal))),
                  Expanded(flex: 4, child: Text('Tamanho', style: NX.inter(11.5, c: NX.metal))),
                  Expanded(flex: 3, child: Text('Alvo', style: NX.inter(11.5, c: NX.metal))),
                  SizedBox(width: 34, child: Text('Nota', style: NX.inter(11.5, c: NX.metal))),
                  const SizedBox(width: 40),
                ]),
                const Divider(height: 12),
                for (final d in p.drums) _PresetDrumRow(preset: p, drum: d),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar tambor'),
                    onPressed: () {
                      p.drums.add(PresetDrum(DrumType.tom, 'Tom ${p.drums.where((x) => x.type == DrumType.tom).length + 1}', 13, 10, 131));
                      app.touch();
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            _SoundProfile(preset: p),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Aplicar "${p.name}" ao meu kit',
              icon: Icons.play_arrow,
              onPressed: () => _apply(context, p),
            ),
            const SizedBox(height: 16),
            // Biblioteca
            SectionLabel('Biblioteca de Presets',
                trailing: SizedBox(
                  width: 160,
                  height: 36,
                  child: TextField(
                    onChanged: (v) => setState(() => search = v),
                    style: NX.inter(13, c: NX.white),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar preset...',
                      hintStyle: NX.inter(12.5, c: NX.metal),
                      suffixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NX.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NX.border)),
                    ),
                  ),
                )),
            for (final x in lib) _LibraryRow(preset: x, onApply: () => _apply(context, x)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlineBtn(
                  label: 'Importar',
                  icon: Icons.download,
                  height: 44,
                  onPressed: () => _import(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlineBtn(
                  label: 'Exportar',
                  icon: Icons.upload,
                  height: 44,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: app.exportPreset(p)));
                    if (context.mounted) toast(context, 'Preset copiado. Cole no WhatsApp, e-mail ou bloco de notas.');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlineBtn(
                  label: 'Salvar',
                  icon: Icons.save_outlined,
                  accent: true,
                  height: 44,
                  onPressed: () {
                    app.touch();
                    toast(context, 'Alterações salvas.');
                  },
                ),
              ),
            ]),
          ],
        );
      },
    );
  }

  Future<void> _apply(BuildContext context, Preset p) async {
    final ok = await confirm(context, 'Aplicar "${p.name}"?',
        'O kit atual será substituído por este preset. Tudo continua editável.');
    if (ok) {
      app.applyPreset(p);
      if (context.mounted) toast(context, 'Kit atualizado: ${p.name}');
    }
  }

  Future<void> _newPreset(BuildContext context) async {
    final style = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NX.card,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(14), child: Text('Começar a partir de', style: NX.sora(15))),
          for (final s in Preset.styles)
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset('assets/img/preset_$s.jpg', width: 44, height: 36, fit: BoxFit.cover),
              ),
              title: Text(Preset.styleLabel(s), style: NX.inter(14, c: NX.white)),
              subtitle: Text(Preset.styleHint(s), style: NX.inter(12, c: NX.metal)),
              onTap: () => Navigator.pop(ctx, s),
            ),
        ]),
      ),
    );
    if (style == null || !context.mounted) return;
    final n = await askText(context, 'Nome do preset', initial: 'Meu ${Preset.styleLabel(style)}');
    if (n != null && n.isNotEmpty) app.newPreset(n, style);
  }

  Future<void> _import(BuildContext context) async {
    final clip = await Clipboard.getData('text/plain');
    if (!context.mounted) return;
    final t = await askText(context, 'Importar preset',
        initial: (clip?.text ?? '').contains('nexusPreset') ? clip!.text! : '',
        hint: 'Cole aqui o texto do preset');
    if (t == null || t.isEmpty) return;
    final name = app.importPreset(t);
    if (context.mounted) toast(context, name == null ? 'Texto de preset inválido.' : 'Preset "$name" importado.');
  }
}

class _PresetCard extends StatelessWidget {
  final Preset preset;
  final bool selected;
  const _PresetCard({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => app.selectPreset(preset),
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(right: 10, top: 6, bottom: 6, left: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? NX.accent : NX.border, width: selected ? 2.4 : 1),
          boxShadow: selected ? NX.glowShadow(blur: 16, opacity: 0.6) : null,
          image: DecorationImage(image: AssetImage(preset.image), fit: BoxFit.cover),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0.35, 0.95],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(preset.builtIn ? Preset.styleLabel(preset.style) : preset.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NX.sora(19, w: FontWeight.w700)),
            Text(preset.builtIn ? Preset.styleHint(preset.style) : 'Personalizado',
                maxLines: 2,
                textAlign: TextAlign.center,
                style: NX.inter(11.5, c: NX.silver)),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: NX.accent),
                child: const Icon(Icons.check, size: 15, color: NX.white),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _PresetDrumRow extends StatelessWidget {
  final Preset preset;
  final PresetDrum drum;
  const _PresetDrumRow({required this.preset, required this.drum});

  @override
  Widget build(BuildContext context) {
    final st = app.settings;
    final d = drum;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 34, child: DrumIcon(size: 26, color: d.type == DrumType.kick ? NX.silver : NX.metal)),
        Expanded(
          flex: 4,
          child: Text(d.name, overflow: TextOverflow.ellipsis, style: NX.inter(13, c: NX.white)),
        ),
        Expanded(
          flex: 4,
          child: PopupMenuButton<(double, double)>(
            color: NX.cardHi,
            onSelected: (v) {
              d.diameter = v.$1;
              d.depth = v.$2;
              app.touch();
            },
            itemBuilder: (_) => [
              for (final dia in d.type.diameters)
                for (final dep in d.type.depths)
                  if (dep <= dia + 2)
                    PopupMenuItem(value: (dia, dep), child: Text('${st.size(dia)} x ${st.size(dep)}')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: NX.border),
              ),
              child: Row(children: [
                Expanded(
                  child: Text('${st.size(d.diameter)} x ${st.size(d.depth)}',
                      overflow: TextOverflow.ellipsis, style: NX.inter(11.5, c: NX.white)),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: NX.silver),
              ]),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => _editTarget(context),
            child: Text('${st.hz(d.targetHz)} Hz', style: NX.inter(12.5, w: FontWeight.w600, c: NX.white)),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(noteFromFreq(d.targetHz, a4: st.a4, notation: st.notation).label,
              style: NX.sora(13, w: FontWeight.w700, c: NX.accent)),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Container(
              width: 34,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: NX.accent),
              ),
              child: Icon(Icons.tune, size: 17, color: NX.accent),
            ),
            onPressed: () => _editDrum(context),
          ),
        ),
      ]),
    );
  }

  Future<void> _editTarget(BuildContext context) async {
    final t = await askText(context, 'Frequência-alvo · ${drum.name}',
        initial: drum.targetHz.toStringAsFixed(1), number: true, suffix: 'Hz');
    final v = double.tryParse((t ?? '').replaceAll(',', '.'));
    if (v != null && v > 20 && v < 2000) {
      drum.targetHz = v;
      app.touch();
    }
  }

  Future<void> _editDrum(BuildContext context) async {
    final name = TextEditingController(text: drum.name);
    final target = TextEditingController(text: drum.targetHz.toStringAsFixed(1));
    var lugs = drum.lugs;
    var type = drum.type;
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: NX.card,
          title: Text('Ajustar tambor', style: NX.sora(16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<DrumType>(
                value: type,
                dropdownColor: NX.cardHi,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [for (final t in DrumType.values) DropdownMenuItem(value: t, child: Text(t.label))],
                onChanged: (v) => setS(() => type = v ?? type),
              ),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(
                controller: target,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Frequência-alvo', suffixText: 'Hz'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('Parafusos', style: NX.inter(13)),
                const Spacer(),
                IconButton(onPressed: () => setS(() => lugs = (lugs - 1).clamp(3, 16)), icon: const Icon(Icons.remove)),
                Text('$lugs', style: NX.mono(20)),
                IconButton(onPressed: () => setS(() => lugs = (lugs + 1).clamp(3, 16)), icon: const Icon(Icons.add)),
              ]),
            ]),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: NX.bad),
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Remover'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: NX.accent, foregroundColor: NX.white),
              onPressed: () => Navigator.pop(ctx, 'save'),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (res == 'delete' && preset.drums.length > 1) {
      preset.drums.remove(drum);
      app.touch();
    } else if (res == 'save') {
      drum
        ..type = type
        ..name = name.text.trim().isEmpty ? type.label : name.text.trim()
        ..lugs = lugs
        ..targetHz = double.tryParse(target.text.replaceAll(',', '.')) ?? drum.targetHz;
      app.touch();
    }
  }
}

/// Perfil sonoro estimado a partir das frequências do preset.
class _SoundProfile extends StatelessWidget {
  final Preset preset;
  const _SoundProfile({required this.preset});

  double _avg(Iterable<double> v, double d) => v.isEmpty ? d : v.reduce((a, b) => a + b) / v.length;

  @override
  Widget build(BuildContext context) {
    final ds = preset.drums;
    final kick = _avg(ds.where((d) => d.type == DrumType.kick).map((d) => d.targetHz), 55);
    final floor = _avg(ds.where((d) => d.type == DrumType.floor).map((d) => d.targetHz), 110);
    final snare = _avg(ds.where((d) => d.type == DrumType.snare).map((d) => d.targetHz), 200);
    final toms = _avg(ds.where((d) => d.type == DrumType.tom).map((d) => d.targetHz), 150);
    final diam = _avg(ds.map((d) => d.diameter), 14);
    final values = [
      ('Grave', (1.6 - (kick + floor) / 2 / 100).clamp(0.15, 1.0)),
      ('Médio', (0.3 + (toms - 100) / 150).clamp(0.15, 1.0)),
      ('Agudo', ((snare - 100) / 250).clamp(0.15, 1.0)),
      ('Sustentação', (diam / 18).clamp(0.15, 1.0)),
    ];
    return NxCard(
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(preset.image, width: 96, height: 96, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Perfil Sonoro'),
            for (final v in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  SizedBox(width: 82, child: Text(v.$1, style: NX.inter(12, c: NX.white))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: v.$2,
                        minHeight: 7,
                        color: NX.accent,
                        backgroundColor: NX.border,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${(v.$2 * 100).round()}%',
                        textAlign: TextAlign.right, style: NX.inter(12, c: NX.white)),
                  ),
                ]),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  final Preset preset;
  final VoidCallback onApply;
  const _LibraryRow({required this.preset, required this.onApply});

  @override
  Widget build(BuildContext context) {
    final active = app.activePreset == preset.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(2, 4, 0, 4),
      decoration: NX.cardDeco(radius: 12, borderColor: active ? NX.accent : null),
      child: Row(children: [
        IconButton(
          icon: Icon(preset.favorite ? Icons.star : Icons.star_border,
              color: preset.favorite ? NX.accent : NX.silver),
          onPressed: () => app.toggleFavorite(preset),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(preset.image, width: 64, height: 40, fit: BoxFit.cover),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => app.selectPreset(preset),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(preset.name, overflow: TextOverflow.ellipsis, style: NX.inter(13.5, w: FontWeight.w600, c: NX.white)),
              Text(preset.summary, overflow: TextOverflow.ellipsis, style: NX.inter(11.5, c: NX.metal)),
            ]),
          ),
        ),
        if (preset.id == 'rock')
          Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NX.accent),
            ),
            child: Text('Padrão', style: NX.inter(11, c: NX.accent)),
          ),
        IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: NX.silver)),
            child: const Icon(Icons.play_arrow, size: 20, color: NX.white),
          ),
          onPressed: onApply,
        ),
        PopupMenuButton<String>(
          color: NX.cardHi,
          icon: const Icon(Icons.more_vert, color: NX.white),
          onSelected: (v) async {
            if (v == 'dup') app.duplicatePreset(preset);
            if (v == 'ren') {
              final n = await askText(context, 'Renomear preset', initial: preset.name);
              if (n != null && n.isNotEmpty) app.renamePreset(preset, n);
            }
            if (v == 'exp') {
              await Clipboard.setData(ClipboardData(text: app.exportPreset(preset)));
              if (context.mounted) toast(context, 'Preset copiado.');
            }
            if (v == 'del') app.deletePreset(preset);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'dup', child: Text('Duplicar')),
            const PopupMenuItem(value: 'ren', child: Text('Renomear')),
            const PopupMenuItem(value: 'exp', child: Text('Exportar')),
            PopupMenuItem(value: 'del', child: Text(preset.builtIn ? 'Restaurar original' : 'Excluir')),
          ],
        ),
      ]),
    );
  }
}
