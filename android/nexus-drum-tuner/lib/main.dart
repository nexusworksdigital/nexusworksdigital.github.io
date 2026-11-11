import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/splash_screen.dart';
import 'state/services.dart';
import 'theme/nexus_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D0E10),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const NexusDrumTunerApp());
}

class NexusDrumTunerApp extends StatelessWidget {
  const NexusDrumTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // reconstrói o tema quando a cor de destaque muda
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: 'Nexus Drum Tuner',
        debugShowCheckedModeBanner: false,
        theme: NX.theme(),
        home: const SplashScreen(),
      ),
    );
  }
}
