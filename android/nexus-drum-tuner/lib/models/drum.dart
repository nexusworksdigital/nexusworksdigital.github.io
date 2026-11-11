import 'dart:math' as math;

enum DrumType { snare, tom, floor, kick, other }

extension DrumTypeInfo on DrumType {
  String get label => switch (this) {
        DrumType.snare => 'Caixa',
        DrumType.tom => 'Tom',
        DrumType.floor => 'Surdo',
        DrumType.kick => 'Bumbo',
        DrumType.other => 'Outro',
      };

  String get english => switch (this) {
        DrumType.snare => 'Snare',
        DrumType.tom => 'Tom',
        DrumType.floor => 'Floor',
        DrumType.kick => 'Kick',
        DrumType.other => 'Other',
      };

  /// Faixa de busca da fundamental (Hz) — reduz leituras erradas.
  (double, double) get range => switch (this) {
        DrumType.snare => (110.0, 700.0),
        DrumType.tom => (60.0, 450.0),
        DrumType.floor => (45.0, 250.0),
        DrumType.kick => (30.0, 160.0),
        DrumType.other => (30.0, 1200.0),
      };

  /// Diâmetros comuns (polegadas) para os seletores.
  List<double> get diameters => switch (this) {
        DrumType.snare => [10, 12, 13, 14],
        DrumType.tom => [8, 10, 12, 13, 14],
        DrumType.floor => [14, 16, 18],
        DrumType.kick => [18, 20, 22, 24],
        DrumType.other => [6, 8, 10, 12, 14, 16],
      };

  List<double> get depths => switch (this) {
        DrumType.snare => [3.5, 5, 5.5, 6, 6.5, 7, 8],
        DrumType.tom => [6, 7, 8, 9, 10, 11],
        DrumType.floor => [12, 14, 16],
        DrumType.kick => [14, 16, 18, 20],
        DrumType.other => [4, 6, 8, 10, 12],
      };

  int get defaultLugs => switch (this) {
        DrumType.snare => 8,
        DrumType.tom => 6,
        DrumType.floor => 8,
        DrumType.kick => 10,
        DrumType.other => 6,
      };
}

String fmtInch(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString().replaceAll('.', ',');

/// Uma medição salva (para Antes & Depois).
class Measurement {
  final DateTime at;
  final bool top;
  final List<double?> lugs;
  final double? hz;
  const Measurement(this.at, this.top, this.lugs, this.hz);

  double? get average {
    final v = lugs.whereType<double>().toList();
    if (v.isEmpty) return hz;
    return v.reduce((a, b) => a + b) / v.length;
  }

  Map<String, dynamic> toJson() =>
      {'at': at.toIso8601String(), 'top': top, 'lugs': lugs, 'hz': hz};

  factory Measurement.fromJson(Map<String, dynamic> j) => Measurement(
        DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        j['top'] as bool? ?? true,
        ((j['lugs'] as List?) ?? const [])
            .map((e) => e == null ? null : (e as num).toDouble())
            .toList(),
        (j['hz'] as num?)?.toDouble(),
      );
}

/// Drum Profile: cadastro completo de cada peça.
class Drum {
  String id;
  DrumType type;
  String name;
  double diameter;
  double depth;
  int lugs;
  double targetHz;
  String brand;
  String headModel;
  List<double?> lugTop;
  List<double?> lugBottom;
  double? lastHz;
  List<Measurement> sessions;

  Drum({
    required this.id,
    required this.type,
    required this.name,
    required this.diameter,
    required this.depth,
    required this.lugs,
    required this.targetHz,
    this.brand = '',
    this.headModel = '',
    List<double?>? lugTop,
    List<double?>? lugBottom,
    this.lastHz,
    List<Measurement>? sessions,
  })  : lugTop = lugTop ?? List<double?>.filled(lugs, null, growable: true),
        lugBottom = lugBottom ?? List<double?>.filled(lugs, null, growable: true),
        sessions = sessions ?? <Measurement>[];

  String get sizeLabel => '${fmtInch(diameter)}" x ${fmtInch(depth)}"';

  List<double?> lugsFor(bool top) => top ? lugTop : lugBottom;

  void setLugCount(int n) {
    List<double?> resize(List<double?> l) =>
        List<double?>.generate(n, (i) => i < l.length ? l[i] : null);
    lugs = n;
    lugTop = resize(lugTop);
    lugBottom = resize(lugBottom);
  }

  /// Desvio da última leitura em relação ao alvo (cents).
  double? get lastCents =>
      lastHz == null ? null : 1200 * math.log(lastHz! / targetHz) / math.ln2;

  Drum copy() => Drum.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'diameter': diameter,
        'depth': depth,
        'lugs': lugs,
        'target': targetHz,
        'brand': brand,
        'head': headModel,
        'lugTop': lugTop,
        'lugBottom': lugBottom,
        'lastHz': lastHz,
        'sessions': sessions.length > 30
            ? sessions.sublist(sessions.length - 30).map((s) => s.toJson()).toList()
            : sessions.map((s) => s.toJson()).toList(),
      };

  static List<double?> _lugList(Object? raw, int n) {
    final l = (raw as List?) ?? const [];
    return List<double?>.generate(
        n, (i) => i < l.length && l[i] != null ? (l[i] as num).toDouble() : null);
  }

  factory Drum.fromJson(Map<String, dynamic> j) {
    final lugs = (j['lugs'] as num).toInt();
    return Drum(
      id: j['id'] as String,
      type: DrumType.values.firstWhere((t) => t.name == j['type'],
          orElse: () => DrumType.other),
      name: j['name'] as String,
      diameter: ((j['diameter'] ?? j['size']) as num).toDouble(),
      depth: ((j['depth'] ?? 6) as num).toDouble(),
      lugs: lugs,
      targetHz: (j['target'] as num).toDouble(),
      brand: j['brand'] as String? ?? '',
      headModel: j['head'] as String? ?? '',
      lugTop: _lugList(j['lugTop'] ?? j['lugHz'], lugs),
      lugBottom: _lugList(j['lugBottom'], lugs),
      lastHz: (j['lastHz'] as num?)?.toDouble(),
      sessions: ((j['sessions'] as List?) ?? const [])
          .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
