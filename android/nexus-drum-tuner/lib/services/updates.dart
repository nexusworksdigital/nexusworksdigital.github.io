import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Endereço do feed (site da Nexus Works Digital).
const feedUrl = 'https://nexusworksdigital.github.io/nexus-drum-tuner/feed.json';

/// Item do sino de notificações.
class NxNotification {
  final String id;
  final String type; // update · news · notice
  final String title;
  final String body;
  final DateTime date;
  final String? link;
  const NxNotification(this.id, this.type, this.title, this.body, this.date, this.link);

  factory NxNotification.fromJson(Map<String, dynamic> j) => NxNotification(
        j['id'] as String,
        j['type'] as String? ?? 'news',
        j['title'] as String? ?? '',
        j['body'] as String? ?? '',
        DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        j['link'] as String?,
      );
}

/// Versão publicada no site.
class Release {
  final int versionCode;
  final String versionName;
  final DateTime date;
  final List<String> notes;
  final String apkArm64;
  final String apkArmv7;
  final String? sha256Arm64;
  final String? sha256Armv7;
  const Release({
    required this.versionCode,
    required this.versionName,
    required this.date,
    required this.notes,
    required this.apkArm64,
    required this.apkArmv7,
    this.sha256Arm64,
    this.sha256Armv7,
  });

  factory Release.fromJson(Map<String, dynamic> j) => Release(
        versionCode: (j['versionCode'] as num).toInt(),
        versionName: j['versionName'] as String,
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        notes: ((j['notes'] as List?) ?? const []).map((e) => '$e').toList(),
        apkArm64: j['apk_arm64'] as String,
        apkArmv7: (j['apk_armv7'] as String?) ?? j['apk_arm64'] as String,
        sha256Arm64: j['sha256_arm64'] as String?,
        sha256Armv7: j['sha256_armv7'] as String?,
      );
}

enum UpdatePhase { idle, checking, downloading, installing, error }

/// Atualização automática + central de notificações.
class UpdateService extends ChangeNotifier {
  int currentCode = 0;
  String currentName = '';
  Release? latest;
  List<NxNotification> news = [];
  Set<String> _read = {};
  DateTime? lastCheck;
  bool offline = false;

  UpdatePhase phase = UpdatePhase.idle;
  double progress = 0; // 0..1
  String? error;
  StreamSubscription<OtaEvent>? _ota;
  SharedPreferences? _prefs;

  bool get hasUpdate => latest != null && latest!.versionCode > currentCode;

  /// Notificações (a atualização disponível vem primeiro).
  List<NxNotification> get notifications {
    final l = <NxNotification>[];
    final r = latest;
    if (r != null && hasUpdate) {
      l.add(NxNotification(
        'update-${r.versionCode}',
        'update',
        'Nova versão ${r.versionName} disponível',
        r.notes.isEmpty ? 'Toque para ver as novidades e atualizar.' : r.notes.first,
        r.date,
        null,
      ));
    }
    l.addAll(news);
    return l;
  }

  int get unread => notifications.where((n) => !_read.contains(n.id)).length;

  bool isRead(NxNotification n) => _read.contains(n.id);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _read = (_prefs!.getStringList('readNotifs') ?? const []).toSet();
    try {
      final info = await PackageInfo.fromPlatform();
      currentCode = int.tryParse(info.buildNumber) ?? 0;
      currentName = info.version;
    } catch (_) {}
    // mostra o último feed salvo enquanto busca o novo
    final cached = _prefs!.getString('feedCache');
    if (cached != null) _parse(cached);
    notifyListeners();
    await check();
  }

  Future<void> check() async {
    if (phase == UpdatePhase.downloading) return;
    phase = UpdatePhase.checking;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('$feedUrl?t=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes);
        _parse(body);
        await _prefs?.setString('feedCache', body);
        offline = false;
      }
    } catch (_) {
      offline = true;
    }
    lastCheck = DateTime.now();
    phase = UpdatePhase.idle;
    notifyListeners();
  }

  void _parse(String body) {
    try {
      final j = jsonDecode(body) as Map<String, dynamic>;
      final l = j['latest'];
      latest = l is Map<String, dynamic> ? Release.fromJson(l) : null;
      news = ((j['news'] as List?) ?? const [])
          .map((e) => NxNotification.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {}
  }

  void markRead(NxNotification n) {
    _read.add(n.id);
    _prefs?.setStringList('readNotifs', _read.toList());
    notifyListeners();
  }

  void markAllRead() {
    _read.addAll(notifications.map((n) => n.id));
    _prefs?.setStringList('readNotifs', _read.toList());
    notifyListeners();
  }

  Future<String> _abi() async {
    try {
      final abi = await OtaUpdate().getAbi();
      return '$abi';
    } catch (_) {
      return 'arm64-v8a';
    }
  }

  /// Baixa a nova versão e abre o instalador do Android.
  Future<void> startUpdate() async {
    final r = latest;
    if (r == null || phase == UpdatePhase.downloading) return;
    final abi = await _abi();
    final v7 = abi.contains('armeabi');
    final url = v7 ? r.apkArmv7 : r.apkArm64;
    final sha = v7 ? r.sha256Armv7 : r.sha256Arm64;
    phase = UpdatePhase.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      await _ota?.cancel();
      _ota = OtaUpdate()
          .execute(url, destinationFilename: 'NexusDrumTuner-${r.versionName}.apk', sha256checksum: sha)
          .listen((e) {
        final s = e.status.toString().toUpperCase();
        if (s.contains('DOWNLOADING')) {
          phase = UpdatePhase.downloading;
          progress = (double.tryParse(e.value ?? '') ?? 0) / 100;
        } else if (s.contains('INSTALL') && !s.contains('ERROR')) {
          phase = UpdatePhase.installing;
          progress = 1;
        } else if (s.contains('ERROR') || s.contains('CANCEL')) {
          phase = UpdatePhase.error;
          error = s.contains('PERMISSION')
              ? 'Permita "instalar apps desconhecidos" para o Nexus Drum Tuner e tente de novo.'
              : s.contains('CHECKSUM')
                  ? 'O arquivo baixado veio corrompido. Tente de novo.'
                  : 'Não foi possível baixar a atualização (${e.value ?? s}).';
        }
        notifyListeners();
      }, onError: (Object e) {
        phase = UpdatePhase.error;
        error = 'Falha no download: $e';
        notifyListeners();
      });
    } catch (e) {
      phase = UpdatePhase.error;
      error = 'Falha ao iniciar a atualização: $e';
      notifyListeners();
    }
  }

  /// Alternativa: baixar pelo navegador.
  Future<void> openInBrowser() async {
    final r = latest;
    final url = r?.apkArm64 ?? 'https://nexusworksdigital.github.io/nexus-drum-tuner/#baixar';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> openLink(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
