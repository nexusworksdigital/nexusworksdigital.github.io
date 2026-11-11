import '../audio/music.dart';

/// Ajustes do app (editados em rascunho e salvos com "Salvar Ajustes").
class Settings {
  // Áudio e Microfone
  double sensitivity = 6; // dB (-12..+18): quanto maior, mais sensível
  bool noiseReduction = true;
  bool ambientFilter = true; // ignora < 45 Hz (zumbido/vento)
  int latencyMs = 40; // intervalo de análise

  // Afinação
  double a4 = 440;
  String display = 'all'; // all = Hz/Nota/Cents · hznote · hz
  double precision = 0.1; // 0.1 · 0.5 · 1.0 Hz
  bool autoNote = true;
  String curve = 'log'; // eixo de frequência: log · linear

  // Visual e Interface
  String theme = 'padrao'; // padrao · escuro (claro/auto em breve)
  int accent = 0;
  bool glow = true;
  bool animations = true;
  Notation notation = Notation.abc;

  // Sistema e Dados
  String unit = 'in'; // in · cm

  // Gerenciamento do Kit
  bool bilingual = true; // "Caixa (Snare)"

  // Geral
  String startWith = 'last'; // last · rock
  bool proMode = true;

  Settings();

  Settings copy() => Settings.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'sensitivity': sensitivity,
        'noiseReduction': noiseReduction,
        'ambientFilter': ambientFilter,
        'latencyMs': latencyMs,
        'a4': a4,
        'display': display,
        'precision': precision,
        'autoNote': autoNote,
        'curve': curve,
        'theme': theme,
        'accent': accent,
        'glow': glow,
        'animations': animations,
        'notation': notation.index,
        'unit': unit,
        'bilingual': bilingual,
        'startWith': startWith,
        'proMode': proMode,
      };

  factory Settings.fromJson(Map<String, dynamic> j) {
    final s = Settings();
    T v<T>(String k, T d) => j[k] is T ? j[k] as T : d;
    double dv(String k, double d) => (j[k] as num?)?.toDouble() ?? d;
    s.sensitivity = dv('sensitivity', s.sensitivity);
    s.noiseReduction = v('noiseReduction', s.noiseReduction);
    s.ambientFilter = v('ambientFilter', s.ambientFilter);
    s.latencyMs = (j['latencyMs'] as num?)?.toInt() ?? s.latencyMs;
    s.a4 = dv('a4', s.a4);
    s.display = v('display', s.display);
    s.precision = dv('precision', s.precision);
    s.autoNote = v('autoNote', s.autoNote);
    s.curve = v('curve', s.curve);
    s.theme = v('theme', s.theme);
    s.accent = (j['accent'] as num?)?.toInt() ?? s.accent;
    s.glow = v('glow', s.glow);
    s.animations = v('animations', s.animations);
    final n = (j['notation'] as num?)?.toInt() ?? 0;
    s.notation = Notation.values[n.clamp(0, Notation.values.length - 1)];
    s.unit = v('unit', s.unit);
    s.bilingual = v('bilingual', s.bilingual);
    s.startWith = v('startWith', s.startWith);
    s.proMode = v('proMode', s.proMode);
    return s;
  }

  /// Formata Hz conforme a precisão escolhida.
  String hz(double v) {
    if (precision >= 1) return v.toStringAsFixed(0);
    if (precision >= 0.5) return ((v * 2).round() / 2).toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }

  /// Formata tamanho (polegadas ou cm).
  String size(double inches) {
    if (unit == 'cm') return '${(inches * 2.54).toStringAsFixed(0)} cm';
    final s = inches == inches.roundToDouble()
        ? inches.toStringAsFixed(0)
        : inches.toString().replaceAll('.', ',');
    return '$s"';
  }
}
