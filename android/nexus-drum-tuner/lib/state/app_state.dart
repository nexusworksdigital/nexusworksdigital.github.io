import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/audio_engine.dart';
import '../models/drum.dart';
import '../models/preset.dart';
import '../models/settings.dart';
import '../theme/nexus_theme.dart';

/// Estado do app: kit, presets, ajustes e afinação por parafuso.
class AppState extends ChangeNotifier {
  final AudioEngine audio;
  AppState(this.audio);

  List<Drum> kit = [];
  int selected = 0;
  List<Preset> presets = Preset.builtIns();
  String activePreset = 'rock';
  Settings settings = Settings();

  // Navegação
  int tab = 0;

  // Lugs
  int? armedLug;
  int currentLug = 0;
  bool headTop = true;

  // Analisador
  String spectrumView = 'spectrum'; // spectrum · cascade · heatmap
  String spectrumFilter = 'off'; // off · low · mid · high

  StreamSubscription<Reading>? _hitSub;
  SharedPreferences? _prefs;

  Drum get drum => kit[selected.clamp(0, kit.length - 1)];

  Preset get preset => presets.firstWhere((p) => p.id == activePreset,
      orElse: () => presets.first);

  String drumName(Drum d) =>
      settings.bilingual && d.type != DrumType.other && d.type != DrumType.tom
          ? '${d.name} (${d.type.english})'
          : d.name;

  // ---------------- Persistência ----------------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    try {
      final s = p.getString('settings');
      if (s != null) settings = Settings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {}
    try {
      final raw = p.getString('presets');
      if (raw != null) {
        final custom = (jsonDecode(raw) as List)
            .map((e) => Preset.fromJson(e as Map<String, dynamic>))
            .toList();
        // built-ins editados substituem os originais
        final ids = custom.map((c) => c.id).toSet();
        presets = [
          ...Preset.builtIns().where((b) => !ids.contains(b.id)),
          ...custom,
        ];
        presets.sort((a, b) => _order(a).compareTo(_order(b)));
      }
    } catch (_) {}
    activePreset = p.getString('activePreset') ?? 'rock';
    try {
      final raw = p.getString('kit2');
      if (raw != null && settings.startWith == 'last') {
        kit = (jsonDecode(raw) as List)
            .map((e) => Drum.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    if (kit.isEmpty) _kitFromPreset(preset);
    selected = (p.getInt('selected') ?? 0).clamp(0, kit.length - 1);
    _applySettingsToEngine();
    _hitSub = audio.hits.listen(_onHit);
    notifyListeners();
  }

  int _order(Preset p) {
    final i = Preset.styles.indexOf(p.id);
    return i < 0 ? 100 : i;
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString('kit2', jsonEncode(kit.map((d) => d.toJson()).toList()));
    await p.setInt('selected', selected);
    await p.setString('settings', jsonEncode(settings.toJson()));
    await p.setString('activePreset', activePreset);
    // guarda todos (inclui edições e favoritos dos presets de fábrica)
    await p.setString('presets', jsonEncode(presets.map((x) => x.toJson()).toList()));
  }

  void touch() {
    _save();
    notifyListeners();
  }

  int get storedBytes => (_prefs?.getString('kit2')?.length ?? 0) +
      (_prefs?.getString('presets')?.length ?? 0);

  // ---------------- Ajustes ----------------
  void applySettings(Settings s) {
    settings = s;
    _applySettingsToEngine();
    touch();
  }

  void _applySettingsToEngine() {
    final s = settings;
    NX.accent = NX.accents[s.accent.clamp(0, NX.accents.length - 1)];
    NX.glow = s.glow;
    NX.animations = s.animations;
    audio.sensitivity = s.sensitivity;
    audio.noiseReduction = s.noiseReduction;
    audio.ambientFilter = s.ambientFilter;
    audio.hopSamples = (s.latencyMs * AudioEngine.sampleRate / 1000).round().clamp(512, 8192);
    audio.maxHarmonic = 5;
    _applyDrumToEngine();
    _applyFilter();
  }

  void _applyDrumToEngine() {
    if (kit.isEmpty) return;
    final (lo, hi) = drum.type.range;
    audio.setRange(lo, hi);
  }

  void setSpectrumView(String v) {
    spectrumView = v;
    notifyListeners();
  }

  void setSpectrumFilter(String f) {
    spectrumFilter = f;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    audio.band = switch (spectrumFilter) {
      'low' => (30.0, 160.0),
      'mid' => (150.0, 700.0),
      'high' => (600.0, 5000.0),
      _ => null,
    };
  }

  void goTab(int i) {
    tab = i;
    notifyListeners();
  }

  // ---------------- Kit ----------------
  void _kitFromPreset(Preset p) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    kit = [
      for (var i = 0; i < p.drums.length; i++) p.drums[i].toDrum('d${stamp}_$i'),
    ];
    selected = 0;
  }

  void selectDrum(int i) {
    selected = i.clamp(0, kit.length - 1);
    currentLug = 0;
    armedLug = null;
    audio.clearReading();
    _applyDrumToEngine();
    touch();
  }

  void updateDrum(Drum d) {
    _applyDrumToEngine();
    touch();
  }

  void addDrum(Drum d) {
    kit.add(d);
    selectDrum(kit.length - 1);
  }

  void removeDrum(int i) {
    if (kit.length <= 1) return;
    kit.removeAt(i);
    selectDrum(selected >= kit.length ? kit.length - 1 : selected);
  }

  void reorderKit(int oldIndex, int newIndex) {
    final cur = drum;
    if (newIndex > oldIndex) newIndex -= 1;
    final d = kit.removeAt(oldIndex);
    kit.insert(newIndex, d);
    selected = kit.indexOf(cur);
    touch();
  }

  void setTarget(double hz) {
    drum.targetHz = double.parse(hz.toStringAsFixed(1));
    touch();
  }

  /// Aplica um preset ao kit (sugestão inicial; tudo continua editável).
  void applyPreset(Preset p) {
    activePreset = p.id;
    _kitFromPreset(p);
    audio.clearReading();
    _applyDrumToEngine();
    touch();
  }

  /// Variação rápida: troca o diâmetro de todos os tambores de um tipo.
  void setTypeDiameter(DrumType t, double diameter, {int? tomIndex}) {
    var n = 0;
    for (final d in kit) {
      if (d.type != t) continue;
      if (tomIndex == null || n == tomIndex) d.diameter = diameter;
      n++;
    }
    touch();
  }

  /// Restaura os tamanhos do preset ativo, mantendo as afinações.
  void restoreSizes() {
    final p = preset;
    for (final d in kit) {
      final m = p.drums.where((x) => x.type == d.type && x.name == d.name);
      if (m.isNotEmpty) {
        d.diameter = m.first.diameter;
        d.depth = m.first.depth;
      }
    }
    touch();
  }

  // ---------------- Presets ----------------
  String _newId() => 'p${DateTime.now().millisecondsSinceEpoch}';

  Preset saveKitAsPreset(String name) {
    final p = Preset(
      id: _newId(),
      name: name,
      style: preset.style,
      subtitle: 'Meu kit',
      drums: kit.map(PresetDrum.fromDrum).toList(),
    );
    presets.add(p);
    activePreset = p.id;
    touch();
    return p;
  }

  Preset newPreset(String name, String style) {
    final base = Preset.builtIns().firstWhere((b) => b.style == style,
        orElse: () => Preset.builtIns().first);
    final p = base.copyAs(_newId(), name);
    presets.add(p);
    activePreset = p.id;
    touch();
    return p;
  }

  void duplicatePreset(Preset p) {
    final c = p.copyAs(_newId(), '${p.name} (cópia)');
    presets.add(c);
    activePreset = c.id;
    touch();
  }

  void renamePreset(Preset p, String name) {
    p.name = name;
    touch();
  }

  void deletePreset(Preset p) {
    if (p.builtIn) {
      // restaura o original em vez de apagar
      final orig = Preset.builtIns().firstWhere((b) => b.id == p.id);
      presets[presets.indexOf(p)] = orig;
    } else {
      presets.remove(p);
      if (activePreset == p.id) activePreset = presets.first.id;
    }
    touch();
  }

  void toggleFavorite(Preset p) {
    p.favorite = !p.favorite;
    touch();
  }

  void selectPreset(Preset p) {
    activePreset = p.id;
    notifyListeners();
  }

  String exportPreset(Preset p) =>
      const JsonEncoder.withIndent('  ').convert({'nexusPreset': 1, ...p.toJson()});

  /// Importa um preset em JSON. Retorna o nome ou null se inválido.
  String? importPreset(String text) {
    try {
      final j = jsonDecode(text.trim()) as Map<String, dynamic>;
      final p = Preset.fromJson(j)
        ..id = _newId()
        ..builtIn = false;
      if (p.drums.isEmpty) return null;
      presets.add(p);
      activePreset = p.id;
      touch();
      return p.name;
    } catch (_) {
      return null;
    }
  }

  // ---------------- Lugs ----------------
  List<double?> get lugValues => drum.lugsFor(headTop);

  void setHead(bool top) {
    headTop = top;
    currentLug = 0;
    armedLug = null;
    notifyListeners();
  }

  void setCurrentLug(int i) {
    currentLug = i % drum.lugs;
    if (armedLug != null) armedLug = currentLug;
    notifyListeners();
  }

  void armLug() {
    armedLug = currentLug;
    audio.hold = false;
    if (!audio.listening) audio.start();
    notifyListeners();
  }

  void disarm() {
    armedLug = null;
    notifyListeners();
  }

  /// Recalibrar: limpa a pele atual e começa pelo parafuso 1.
  void recalibrate() {
    final l = drum.lugsFor(headTop);
    for (var i = 0; i < l.length; i++) {
      l[i] = null;
    }
    currentLug = 0;
    armLug();
    touch();
  }

  /// Salva a medição atual (Antes & Depois).
  bool saveMeasurement() {
    final l = drum.lugsFor(headTop);
    if (l.every((v) => v == null) && drum.lastHz == null) return false;
    drum.sessions.add(Measurement(DateTime.now(), headTop, List.of(l), drum.lastHz));
    touch();
    return true;
  }

  void clearHistory() {
    for (final d in kit) {
      d.sessions.clear();
    }
    touch();
  }

  void _onHit(Reading r) {
    if (kit.isEmpty) return;
    drum.lastHz = double.parse(r.hz.toStringAsFixed(2));
    final lug = armedLug;
    final l = drum.lugsFor(headTop);
    if (lug != null && lug < l.length) {
      l[lug] = r.hz;
      final next = (lug + 1) % drum.lugs;
      currentLug = next;
      armedLug = l.every((v) => v != null) ? null : next;
    }
    touch();
  }

  @override
  void dispose() {
    _hitSub?.cancel();
    super.dispose();
  }
}
