import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/audio_engine.dart';
import '../audio/music.dart';
import '../models/preset.dart';
import '../models/settings.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/nexus_logo.dart';
import 'kit_screen.dart';
import 'updates_screen.dart';

/// Página 06 · Ajustes — central de configurações.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings s = app.settings.copy();

  void _set(VoidCallback f) => setState(f);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _Section(icon: Icons.settings_outlined, title: 'Áudio e Microfone', children: [
        _Row(
          icon: Icons.mic_none,
          label: 'Fonte de Áudio',
          trailing: ListenableBuilder(
            listenable: audio,
            builder: (_, __) => _Pill(audio.state == MicState.listening ? 'Microfone do Sistema · ativo' : 'Microfone do Sistema'),
          ),
        ),
        _Row(
          icon: Icons.graphic_eq,
          label: 'Sensibilidade',
          trailing: _Pill('${s.sensitivity >= 0 ? '+' : ''}${s.sensitivity.toStringAsFixed(0)} dB'),
        ),
        Slider(
          min: -12,
          max: 18,
          divisions: 30,
          value: s.sensitivity,
          onChanged: (v) => _set(() => s.sensitivity = v),
        ),
        _Switch(Icons.blur_on, 'Redução de Ruído', s.noiseReduction, (v) => _set(() => s.noiseReduction = v)),
        _Switch(Icons.air, 'Filtro de Ambiência', s.ambientFilter, (v) => _set(() => s.ambientFilter = v)),
        _Row(
          icon: Icons.timer_outlined,
          label: 'Latência (ms)',
          trailing: _Drop<int>(
            value: s.latencyMs,
            items: const [(20, '20 ms'), (40, '40 ms'), (80, '80 ms')],
            onChanged: (v) => _set(() => s.latencyMs = v),
          ),
        ),
      ]),
      _Section(icon: Icons.gps_fixed, title: 'Afinação', children: [
        _Row(
          icon: Icons.tune,
          label: 'Referência',
          trailing: _Drop<double>(
            value: s.a4,
            items: [for (var f = 430.0; f <= 446; f += 1) (f, 'A4 = ${f.toStringAsFixed(0)} Hz')],
            onChanged: (v) => _set(() => s.a4 = v),
          ),
        ),
        _Row(
          icon: Icons.straighten,
          label: 'Unidade de Exibição',
          trailing: _Drop<String>(
            value: s.display,
            items: const [('all', 'Hz / Nota / Cents'), ('hznote', 'Hz / Nota'), ('hz', 'Somente Hz')],
            onChanged: (v) => _set(() => s.display = v),
          ),
        ),
        _Row(
          icon: Icons.center_focus_strong,
          label: 'Precisão de Leitura',
          trailing: _Drop<double>(
            value: s.precision,
            items: const [(0.1, 'Alta (±0,1 Hz)'), (0.5, 'Média (±0,5 Hz)'), (1.0, 'Básica (±1 Hz)')],
            onChanged: (v) => _set(() => s.precision = v),
          ),
        ),
        _Switch(Icons.music_note, 'Detecção Automática de Nota', s.autoNote, (v) => _set(() => s.autoNote = v)),
        _Row(
          icon: Icons.show_chart,
          label: 'Notas',
          trailing: _Drop<Notation>(
            value: s.notation,
            items: const [(Notation.abc, 'C, C#, D…'), (Notation.doremi, 'Dó, Ré, Mi…')],
            onChanged: (v) => _set(() => s.notation = v),
          ),
        ),
        _Row(
          icon: Icons.ssid_chart,
          label: 'Curva de Resposta',
          trailing: _Drop<String>(
            value: s.curve,
            items: const [('log', 'Logarítmica'), ('linear', 'Linear')],
            onChanged: (v) => _set(() => s.curve = v),
          ),
        ),
      ]),
      _Section(icon: Icons.desktop_windows_outlined, title: 'Visual e Interface', children: [
        Text('Tema', style: NX.inter(13, c: NX.white)),
        const SizedBox(height: 6),
        Row(children: [
          for (final t in const [('padrao', 'Padrão'), ('claro', 'Claro'), ('escuro', 'Escuro'), ('auto', 'Automático')])
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (t.$1 == 'claro' || t.$1 == 'auto') {
                    toast(context, 'Tema ${t.$2} chega em uma próxima versão.');
                    return;
                  }
                  _set(() => s.theme = t.$1);
                },
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: t.$1 == 'claro' ? const Color(0xFFD9DBDF) : NX.cardHi,
                    border: Border.all(color: s.theme == t.$1 ? NX.accents[s.accent] : NX.border, width: s.theme == t.$1 ? 2 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    NexusMark(size: 20, color: t.$1 == 'padrao' ? NX.accents[s.accent] : (t.$1 == 'claro' ? NX.graphite : NX.metal)),
                    Text(t.$2, style: NX.inter(10.5, c: t.$1 == 'claro' ? NX.graphite : NX.white)),
                  ]),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text('Cor de Destaque', style: NX.inter(13, c: NX.white)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < NX.accents.length; i++)
            GestureDetector(
              onTap: () => _set(() => s.accent = i),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NX.accents[i],
                  border: Border.all(color: s.accent == i ? NX.white : Colors.transparent, width: 2),
                ),
                child: s.accent == i ? const Icon(Icons.check, color: NX.white, size: 20) : null,
              ),
            ),
        ]),
        const SizedBox(height: 6),
        _Switch(Icons.auto_awesome, 'Efeitos Visuais (Glow)', s.glow, (v) => _set(() => s.glow = v)),
        _Switch(Icons.play_arrow_outlined, 'Animações da Interface', s.animations, (v) => _set(() => s.animations = v)),
      ]),
      _Section(icon: Icons.storage, title: 'Sistema e Dados', children: [
        _Row(
          icon: Icons.straighten,
          label: 'Unidade de Medida',
          trailing: _Drop<String>(
            value: s.unit,
            items: const [('in', 'Polegadas (")'), ('cm', 'Centímetros')],
            onChanged: (v) => _set(() => s.unit = v),
          ),
        ),
        _Soon(Icons.cloud_upload_outlined, 'Backup na Nuvem'),
        _Soon(Icons.devices, 'Sincronizar entre Dispositivos'),
        _Link(Icons.swap_horiz, 'Importar / Exportar Presets', () => app.goTab(4)),
        _Link(Icons.delete_outline, 'Limpar Histórico (${(app.storedBytes / 1024).toStringAsFixed(1)} KB)', () async {
          final ok = await confirm(context, 'Limpar histórico?', 'Apaga as medições salvas (Antes & Depois).');
          if (ok) {
            app.clearHistory();
            audio.spectrogram.clear();
            if (context.mounted) toast(context, 'Histórico limpo.');
            setState(() {});
          }
        }),
      ]),
      _Section(icon: Icons.album_outlined, title: 'Gerenciamento do Kit', children: [
        _Link(Icons.restart_alt, 'Tambores Padrão (Rock)', () async {
          final ok = await confirm(context, 'Restaurar kit padrão?', 'O kit volta para o preset Rock.');
          if (ok) app.applyPreset(Preset.builtIns().first);
        }),
        _Switch(Icons.label_outline, 'Nomes com inglês (Snare, Kick…)', s.bilingual, (v) => _set(() => s.bilingual = v)),
        _Link(Icons.format_list_numbered, 'Ordem de Exibição no Kit', () => reorderKit(context)),
        _Link(Icons.history, 'Restaurar Tamanhos Padrão', () {
          app.restoreSizes();
          toast(context, 'Tamanhos restaurados.');
        }),
      ]),
      _Section(icon: Icons.tune, title: 'Geral', children: [
        _Row(icon: Icons.language, label: 'Idioma', trailing: const _Pill('Português (BR)')),
        _Row(
          icon: Icons.power_settings_new,
          label: 'Inicializar com',
          trailing: _Drop<String>(
            value: s.startWith,
            items: const [('last', 'Último Kit'), ('rock', 'Kit Padrão')],
            onChanged: (v) => _set(() => s.startWith = v),
          ),
        ),
        _Switch(Icons.workspace_premium_outlined, 'Modo Profissional', s.proMode, (v) => _set(() => s.proMode = v)),
        _Link(Icons.system_update, updates.hasUpdate ? 'Atualizar para ${updates.latest!.versionName}' : 'Verificar Atualizações',
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdateScreen()))),
        _Link(Icons.info_outline, 'Sobre o Nexus Drum Tuner  ·  v${updates.currentName}', () {
          showAboutDialog(
            context: context,
            applicationName: 'Nexus Drum Tuner',
            applicationVersion: updates.currentName,
            applicationIcon: const NexusMark(size: 36),
            applicationLegalese: '© Nexus Works Digital',
          );
        }),
      ]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const NexusHeader(),
        const PageTitle('Ajustes', subtitle: 'Personalize o aplicativo do seu jeito'),
        LayoutBuilder(builder: (context, c) {
          if (c.maxWidth < 560) {
            return Column(children: [
              for (final w in sections) Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
            ]);
          }
          return Column(children: [
            for (var i = 0; i < sections.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: sections[i]),
                    const SizedBox(width: 12),
                    Expanded(child: i + 1 < sections.length ? sections[i + 1] : const SizedBox()),
                  ]),
                ),
              ),
          ]);
        }),
        Row(children: [
          Expanded(
            child: OutlineBtn(
              label: 'Restaurar',
              icon: Icons.restart_alt,
              height: 46,
              onPressed: () => _set(() => s = Settings()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlineBtn(
              label: 'Cancelar',
              icon: Icons.close,
              height: 46,
              onPressed: () => _set(() => s = app.settings.copy()),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlineBtn(
              label: 'Salvar',
              icon: Icons.check,
              accent: true,
              height: 46,
              onPressed: () {
                app.applySettings(s.copy());
                HapticFeedback.lightImpact();
                toast(context, 'Ajustes salvos.');
              },
            ),
          ),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1B20), Color(0xFF0E0F12)],
        ),
        border: Border.all(color: NX.border),
        boxShadow: NX.glow ? [BoxShadow(color: NX.accent.withOpacity(0.08), blurRadius: 18)] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: NX.accent, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: NX.sora(16, w: FontWeight.w600))),
        ]),
        const Divider(height: 18),
        ...children,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _Row({required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, color: NX.silver, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: NX.inter(13, c: NX.white))),
          const SizedBox(width: 6),
          Flexible(child: Align(alignment: Alignment.centerRight, child: trailing)),
        ]),
      );
}

class _Switch extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch(this.icon, this.label, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) => _Row(
        icon: icon,
        label: label,
        trailing: Switch(value: value, onChanged: onChanged, activeTrackColor: NX.accent),
      );
}

class _Link extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Link(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: _Row(icon: icon, label: label, trailing: const Icon(Icons.chevron_right, color: NX.silver)),
      );
}

class _Soon extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Soon(this.icon, this.label);

  @override
  Widget build(BuildContext context) => _Row(icon: icon, label: label, trailing: const _Pill('Em breve'));
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NX.border),
          color: NX.card,
        ),
        child: Text(text, overflow: TextOverflow.ellipsis, style: NX.inter(12, c: NX.white)),
      );
}

class _Drop<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  const _Drop({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cur = items.where((e) => e.$1 == value);
    return PopupMenuButton<T>(
      color: NX.cardHi,
      onSelected: onChanged,
      itemBuilder: (_) => [for (final e in items) PopupMenuItem(value: e.$1, child: Text(e.$2))],
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NX.border),
          color: NX.card,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(
            child: Text(cur.isEmpty ? '$value' : cur.first.$2,
                overflow: TextOverflow.ellipsis, style: NX.inter(12, c: NX.white)),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: NX.silver),
        ]),
      ),
    );
  }
}
