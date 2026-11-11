import 'dart:math' as math;

enum Notation { abc, doremi }

const _sharp = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const _solfege = [
  'Dó', 'Dó#', 'Ré', 'Ré#', 'Mi', 'Fá', 'Fá#', 'Sol', 'Sol#', 'Lá', 'Lá#', 'Si'
];

class NoteInfo {
  final String name;
  final int octave;
  final double cents; // desvio da nota mais próxima
  final double refHz; // frequência exata da nota mais próxima
  const NoteInfo(this.name, this.octave, this.cents, this.refHz);
  String get label => '$name$octave';
}

NoteInfo noteFromFreq(double f,
    {double a4 = 440, Notation notation = Notation.abc}) {
  final midi = 69 + 12 * math.log(f / a4) / math.ln2;
  final r = midi.round();
  final idx = ((r % 12) + 12) % 12;
  final names = notation == Notation.abc ? _sharp : _solfege;
  final octave = (r / 12).floor() - 1;
  final ref = a4 * math.pow(2, (r - 69) / 12).toDouble();
  return NoteInfo(names[idx], octave, (midi - r) * 100, ref);
}

double centsBetween(double f, double ref) =>
    1200 * math.log(f / ref) / math.ln2;

String fmtHz(double hz) => hz.toStringAsFixed(1);

String fmtSigned(double v, {int digits = 1}) =>
    '${v >= 0 ? '+' : ''}${v.toStringAsFixed(digits)}';
