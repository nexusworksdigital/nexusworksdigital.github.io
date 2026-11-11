import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_drum_tuner/models/drum.dart';
import 'package:nexus_drum_tuner/models/preset.dart';
import 'package:nexus_drum_tuner/models/settings.dart';

void main() {
  test('presets de fábrica: 5 estilos com tambores', () {
    final p = Preset.builtIns();
    expect(p.length, 5);
    expect(p.every((x) => x.drums.isNotEmpty), true);
    final forro = p.firstWhere((x) => x.style == 'forro');
    expect(forro.drums.any((d) => d.type == DrumType.tom && d.diameter == 8), true);
  });

  test('tambor salva e carrega (com parafusos e histórico)', () {
    final d = Preset.builtIns().first.drums.first.toDrum('x');
    d.lugTop[0] = 196.2;
    d.sessions.add(Measurement(DateTime(2026), true, [196.0, null], 196.0));
    final back = Drum.fromJson(d.toJson());
    expect(back.targetHz, d.targetHz);
    expect(back.lugTop.length, back.lugs);
    expect(back.lugTop[0], 196.2);
    expect(back.sessions.length, 1);
  });

  test('ajustes salvam e formatam', () {
    final s = Settings()..precision = 1..unit = 'cm';
    final b = Settings.fromJson(s.toJson());
    expect(b.hz(196.4), '196');
    expect(b.size(14), '36 cm');
  });
}
