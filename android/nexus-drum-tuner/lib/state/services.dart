import '../audio/audio_engine.dart';
import '../services/updates.dart';
import 'app_state.dart';

/// Instâncias únicas do app.
final AudioEngine audio = AudioEngine();
final AppState app = AppState(audio);
final UpdateService updates = UpdateService();
