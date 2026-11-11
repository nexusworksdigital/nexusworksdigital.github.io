import 'drum.dart';

/// Configuração de um tambor dentro de um preset.
class PresetDrum {
  DrumType type;
  String name;
  double diameter;
  double depth;
  int lugs;
  double targetHz;

  PresetDrum(this.type, this.name, this.diameter, this.depth, this.targetHz,
      {int? lugs})
      : lugs = lugs ?? type.defaultLugs;

  String get sizeLabel => '${fmtInch(diameter)}" x ${fmtInch(depth)}"';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'diameter': diameter,
        'depth': depth,
        'lugs': lugs,
        'target': targetHz,
      };

  factory PresetDrum.fromJson(Map<String, dynamic> j) => PresetDrum(
        DrumType.values.firstWhere((t) => t.name == j['type'],
            orElse: () => DrumType.other),
        j['name'] as String,
        (j['diameter'] as num).toDouble(),
        (j['depth'] as num).toDouble(),
        (j['target'] as num).toDouble(),
        lugs: (j['lugs'] as num?)?.toInt(),
      );

  PresetDrum copy() => PresetDrum.fromJson(toJson());

  Drum toDrum(String id) => Drum(
        id: id,
        type: type,
        name: name,
        diameter: diameter,
        depth: depth,
        lugs: lugs,
        targetHz: targetHz,
      );

  factory PresetDrum.fromDrum(Drum d) =>
      PresetDrum(d.type, d.name, d.diameter, d.depth, d.targetHz, lugs: d.lugs);
}

/// Preset de afinação: sugestão de configuração, sempre editável.
class Preset {
  String id;
  String name;
  String style; // rock, metal, pop, forro, sertanejo
  String subtitle;
  bool builtIn;
  bool favorite;
  List<PresetDrum> drums;

  Preset({
    required this.id,
    required this.name,
    required this.style,
    required this.subtitle,
    required this.drums,
    this.builtIn = false,
    this.favorite = false,
  });

  static const styles = ['rock', 'metal', 'pop', 'forro', 'sertanejo'];

  static String styleLabel(String s) => switch (s) {
        'rock' => 'Rock',
        'metal' => 'Metal',
        'pop' => 'Pop',
        'forro' => 'Forró',
        'sertanejo' => 'Sertanejo',
        _ => 'Personalizado',
      };

  /// Sugestão característica de cada estilo (não é limitação).
  static String styleHint(String s) => switch (s) {
        'rock' => 'Surdo 14"',
        'metal' => 'Pesado',
        'pop' => 'Equilibrado',
        'forro' => 'Caixa aguda · Tom 8"',
        'sertanejo' => 'Caixa 14" x 8"',
        _ => 'Seu preset',
      };

  static List<String> styleRules(String s) => switch (s) {
        'rock' => [
            'Surdo: 14" (padrão do Rock)',
            'Caixa: livre (12" / 13" / 14" / 14"x8")',
            'Tons: livres (8" / 10" / 12" / 13")',
            'Bumbo: livre (20" / 22" / 24")',
          ],
        'metal' => [
            'Configuração totalmente personalizável',
            'Bumbo seco e grave, tons com ataque',
            'Caixa 14" com afinação média-alta',
          ],
        'pop' => [
            'Configuração equilibrada',
            'Tons em intervalos de terça',
            'Caixa média, bumbo controlado',
          ],
        'forro' => [
            'Caixa menor e afinação aguda',
            'Tom de 8"',
            'Surdo 14" e bumbo compacto',
          ],
        'sertanejo' => [
            'Caixa 14" x 8"',
            'Tons 10" e 12"',
            'Surdo 16"',
          ],
        _ => ['Preset criado por você'],
      };

  String get image =>
      'assets/img/preset_${styles.contains(style) ? style : 'rock'}.jpg';

  String get summary => drums
      .where((d) => d.type != DrumType.kick)
      .take(3)
      .map((d) => '${d.type.label} ${fmtInch(d.diameter)}"')
      .join(' | ');

  Preset copyAs(String newId, String newName) => Preset(
        id: newId,
        name: newName,
        style: style,
        subtitle: subtitle,
        drums: drums.map((d) => d.copy()).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'style': style,
        'subtitle': subtitle,
        'builtIn': builtIn,
        'favorite': favorite,
        'drums': drums.map((d) => d.toJson()).toList(),
      };

  factory Preset.fromJson(Map<String, dynamic> j) => Preset(
        id: j['id'] as String,
        name: j['name'] as String,
        style: j['style'] as String? ?? 'rock',
        subtitle: j['subtitle'] as String? ?? '',
        builtIn: j['builtIn'] as bool? ?? false,
        favorite: j['favorite'] as bool? ?? false,
        drums: ((j['drums'] as List?) ?? const [])
            .map((e) => PresetDrum.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static List<Preset> builtIns() => [
        Preset(id: 'rock', name: 'Rock - Padrão', style: 'rock', subtitle: 'Surdo 14"', builtIn: true, drums: [
          PresetDrum(DrumType.snare, 'Caixa', 14, 6.5, 196),
          PresetDrum(DrumType.tom, 'Tom 1', 10, 8, 165),
          PresetDrum(DrumType.tom, 'Tom 2', 12, 9, 147),
          PresetDrum(DrumType.floor, 'Surdo', 14, 14, 110),
          PresetDrum(DrumType.kick, 'Bumbo', 22, 18, 55),
        ]),
        Preset(id: 'metal', name: 'Metal - Agressivo', style: 'metal', subtitle: 'Pesado', builtIn: true, drums: [
          PresetDrum(DrumType.snare, 'Caixa', 14, 6.5, 220),
          PresetDrum(DrumType.tom, 'Tom 1', 12, 9, 150),
          PresetDrum(DrumType.tom, 'Tom 2', 13, 10, 131),
          PresetDrum(DrumType.floor, 'Surdo', 16, 16, 98),
          PresetDrum(DrumType.kick, 'Bumbo', 22, 18, 50),
        ]),
        Preset(id: 'pop', name: 'Pop - Equilibrado', style: 'pop', subtitle: 'Equilibrado', builtIn: true, drums: [
          PresetDrum(DrumType.snare, 'Caixa', 14, 5.5, 233),
          PresetDrum(DrumType.tom, 'Tom 1', 10, 8, 175),
          PresetDrum(DrumType.tom, 'Tom 2', 12, 9, 147),
          PresetDrum(DrumType.floor, 'Surdo', 16, 16, 110),
          PresetDrum(DrumType.kick, 'Bumbo', 22, 18, 58),
        ]),
        Preset(id: 'forro', name: 'Forró - Compacto', style: 'forro', subtitle: 'Caixa aguda · Tom 8"', builtIn: true, drums: [
          PresetDrum(DrumType.snare, 'Caixa', 12, 5, 330),
          PresetDrum(DrumType.tom, 'Tom 1', 8, 7, 262),
          PresetDrum(DrumType.floor, 'Surdo', 14, 14, 147),
          PresetDrum(DrumType.kick, 'Bumbo', 20, 16, 65),
        ]),
        Preset(id: 'sertanejo', name: 'Sertanejo - Brilhante', style: 'sertanejo', subtitle: 'Caixa 14" x 8"', builtIn: true, drums: [
          PresetDrum(DrumType.snare, 'Caixa', 14, 8, 185),
          PresetDrum(DrumType.tom, 'Tom 1', 10, 8, 165),
          PresetDrum(DrumType.tom, 'Tom 2', 12, 9, 147),
          PresetDrum(DrumType.floor, 'Surdo', 16, 16, 104),
          PresetDrum(DrumType.kick, 'Bumbo', 22, 18, 55),
        ]),
      ];
}
