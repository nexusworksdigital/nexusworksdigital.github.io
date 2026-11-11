import 'package:flutter/material.dart';

import '../state/services.dart';
import '../theme/nexus_theme.dart';
import '../widgets/nexus_logo.dart';
import 'home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    updates.init(); // verifica novidades em segundo plano
    await Future.wait([
      app.load(),
      Future.delayed(const Duration(milliseconds: 1900)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const HomeShell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: NX.bg,
      body: Stack(fit: StackFit.expand, children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0, 0.4],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: Image.asset('assets/img/snare.jpg', fit: BoxFit.fitWidth),
          ),
            ),
          ),
        ),
        SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(width: double.infinity),
            const Spacer(flex: 3),
            FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(fade),
                child: const NexusWordmark(scale: 1.1),
              ),
            ),
            const SizedBox(height: 18),
            FadeTransition(
              opacity: fade,
              child: Text('Afinador de Bateria Profissional', style: NX.inter(14, c: NX.silver)),
            ),
            const Spacer(flex: 5),
            SizedBox(
              width: 70,
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => LinearProgressIndicator(
                  value: _c.value,
                  minHeight: 2,
                  color: NX.accent,
                  backgroundColor: NX.border,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Carregando...', style: NX.inter(12, c: NX.silver)),
            const SizedBox(height: 30),
          ]),
        ),
      ]),
    );
  }
}
