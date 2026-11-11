import 'package:flutter/material.dart';

import '../audio/audio_engine.dart';
import '../audio/music.dart';
import '../models/drum.dart';
import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/common.dart';
import '../widgets/nexus_logo.dart';
import 'kit_screen.dart';
import 'lugs_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';
import 'spectrum_screen.dart';
import 'tuner_screen.dart';
import 'updates_screen.dart';

/// Estrutura com as 6 páginas: Tuner · Lugs · Espectro · Kit · Presets · Ajustes.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  bool _wasListening = false;
  bool _updateShown = false;

  static const _pages = [
    TunerScreen(),
    LugsScreen(),
    SpectrumScreen(),
    KitScreen(),
    PresetsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    audio.start();
    updates.addListener(_onUpdates);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onUpdates());
  }

  /// Avisa uma vez por sessão quando há versão nova.
  void _onUpdates() {
    if (_updateShown || !updates.hasUpdate || !mounted) return;
    _updateShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text('Nova versão ${updates.latest!.versionName} disponível!'),
      action: SnackBarAction(
        label: 'VER',
        textColor: NX.accent,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const UpdateScreen())),
      ),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updates.removeListener(_onUpdates);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    // (o diálogo de permissão não conta: só "paused" desliga)
    if (s == AppLifecycleState.paused) {
      _wasListening = audio.listening || audio.state == MicState.starting || _wasListening;
      audio.stop();
    } else if (s == AppLifecycleState.resumed) {
      if (_wasListening) {
        _wasListening = false;
        audio.start();
      }
      // ao voltar ao app, procura novidades (no máximo a cada 30 min)
      final last = updates.lastCheck;
      if (last == null || DateTime.now().difference(last).inMinutes > 30) updates.check();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final tab = app.tab.clamp(0, _pages.length - 1);
        return Scaffold(
          drawer: const _NexusDrawer(),
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.6),
                radius: 1.3,
                colors: [Color(0xFF1A1714), NX.bg],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(builder: (context, c) {
                final maxW = c.maxWidth > 760 ? 720.0 : c.maxWidth;
                return Center(
                  child: SizedBox(
                    width: maxW,
                    child: KeyedSubtree(key: ValueKey(tab), child: _pages[tab]),
                  ),
                );
              }),
            ),
          ),
          bottomNavigationBar: _NexusNavBar(index: tab, onTap: app.goTab),
        );
      },
    );
  }
}

class _NexusNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NexusNavBar({required this.index, required this.onTap});

  static const _items = [
    (Icons.speed, 'Tuner'),
    (Icons.blur_circular, 'Lugs'),
    (Icons.bar_chart, 'Espectro'),
    (Icons.album_outlined, 'Kit'),
    (Icons.tune, 'Presets'),
    (Icons.settings_outlined, 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E10),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: NX.accent.withOpacity(0.5), width: 1)),
        boxShadow: NX.glow ? [BoxShadow(color: NX.accent.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, -2))] : null,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_items[i].$1, size: 26, color: i == index ? NX.accent : NX.white),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(_items[i].$2,
                              style: NX.inter(11.5,
                                  w: i == index ? FontWeight.w700 : FontWeight.w500,
                                  c: i == index ? NX.accent : NX.white)),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: NX.animations ? 200 : 0),
                          height: 3,
                          width: i == index ? 34 : 0,
                          decoration: BoxDecoration(
                            color: NX.accent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: NX.glowShadow(blur: 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu lateral: ferramentas do laboratório.
class _NexusDrawer extends StatelessWidget {
  const _NexusDrawer();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t, String sub, VoidCallback onTap) => ListTile(
          leading: Icon(i, color: NX.accent),
          title: Text(t, style: NX.inter(14.5, w: FontWeight.w600, c: NX.white)),
          subtitle: Text(sub, style: NX.inter(12, c: NX.metal)),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );
    return Drawer(
      backgroundColor: NX.card,
      child: SafeArea(
        child: ListView(children: [
          const Padding(padding: EdgeInsets.all(20), child: NexusLogo()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('NEXUS DRUM LAB', style: NX.inter(11, w: FontWeight.w700, c: NX.metal, ls: 2)),
          ),
          item(Icons.speed, 'Tuning', 'Afinador e parafusos', () => app.goTab(0)),
          item(Icons.bar_chart, 'Analysis', 'Espectro e harmônicos', () => app.goTab(2)),
          item(Icons.album_outlined, 'Studio', 'Kit, presets e calibração', () => app.goTab(3)),
          const Divider(),
          item(Icons.balance, 'Drum Balance', 'Compare a afinação de todo o kit', () => _balance(context)),
          item(Icons.compare_arrows, 'Antes & Depois', 'Medições salvas por tambor', () => app.goTab(1)),
          item(Icons.library_music_outlined, 'Sound Library', 'Rock, Metal, Pop, Forró, Sertanejo', () => app.goTab(4)),
          item(Icons.system_update, 'Atualizações', 'Novidades e nova versão do app',
              () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UpdateScreen()))),
          const Divider(),
          item(Icons.info_outline, 'Sobre', 'Nexus Drum Tuner v${updates.currentName} · Nexus Works Digital', () {
            showAboutDialog(
              context: context,
              applicationName: 'Nexus Drum Tuner',
              applicationVersion: updates.currentName,
              applicationIcon: const NexusMark(size: 36),
              applicationLegalese: '© Nexus Works Digital',
            );
          }),
        ]),
      ),
    );
  }
}

/// Drum Balance: compara todos os tambores (alvo × última leitura e intervalos).
void _balance(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: NX.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      final st = app.settings;
      final kit = [...app.kit]..sort((a, b) => b.targetHz.compareTo(a.targetHz));
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionLabel('Drum Balance'),
            Text('Do mais agudo ao mais grave. Intervalo = distância musical para o próximo tambor.',
                style: NX.inter(12, c: NX.metal)),
            const SizedBox(height: 10),
            for (var i = 0; i < kit.length; i++) _balanceRow(kit, i, st.a4),
            const SizedBox(height: 8),
            Text('Dica: tons costumam ficar separados por terças ou quartas (3–5 semitons).',
                style: NX.inter(11.5, c: NX.dim)),
          ]),
        ),
      );
    },
  );
}

Widget _balanceRow(List<Drum> kit, int i, double a4) {
  final st = app.settings;
  final d = kit[i];
  final hz = d.lastHz ?? d.targetHz;
  String interval = '';
  if (i + 1 < kit.length) {
    final next = kit[i + 1].lastHz ?? kit[i + 1].targetHz;
    final semis = centsBetween(hz, next) / 100;
    interval = '↓ ${semis.toStringAsFixed(1)} st';
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      tuneStatusIcon(d, size: 26),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.drumName(d), style: NX.inter(13.5, w: FontWeight.w600, c: NX.white)),
          Text(
            'Alvo ${st.hz(d.targetHz)} Hz · ${d.lastHz == null ? 'sem leitura' : 'lido ${st.hz(d.lastHz!)} Hz (${fmtSigned(d.lastCents!, digits: 0)} c)'}',
            style: NX.inter(11.5, c: NX.metal),
          ),
        ]),
      ),
      Text(noteFromFreq(hz, a4: a4, notation: st.notation).label,
          style: NX.sora(14, w: FontWeight.w700, c: NX.accent)),
      const SizedBox(width: 10),
      SizedBox(width: 62, child: Text(interval, textAlign: TextAlign.right, style: NX.inter(11.5, c: NX.silver))),
    ]),
  );
}
