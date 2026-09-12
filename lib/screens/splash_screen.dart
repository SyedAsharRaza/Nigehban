import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';
import 'home_screen.dart';

/// Branded splash: logo scales in, wordmark and tagline fade, then a smooth fade to Home.
/// The native launch screen (same green + logo) shows before this, so there is no white flash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoScale = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)).drive(Tween(begin: 0.6, end: 1.0));
    _logoFade = CurvedAnimation(parent: _c, curve: const Interval(0.0, 0.4, curve: Curves.easeOut));
    _textFade = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.85, curve: Curves.easeOut));
    _textSlide = CurvedAnimation(parent: _c, curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic)).drive(Tween(begin: const Offset(0, 0.25), end: Offset.zero));
    _c.forward();
    Future<void>.delayed(const Duration(milliseconds: 2100), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    final me = ModalRoute.of(context);
    final home = PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, a, secondary) => const HomeScreen(),
      transitionsBuilder: (context, a, secondary, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: child),
    );
    if (me != null && !me.isCurrent) {
      // A shared item already pushed the checking screen on top of us: swap the splash out underneath.
      Navigator.of(context).replace(oldRoute: me, newRoute: home);
    } else {
      Navigator.of(context).pushReplacement(home);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: N.brand,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [N.brand, N.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset('assets/brand/logo_1024.png', width: 150, height: 150),
                ),
              ),
              const SizedBox(height: 26),
              SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textFade,
                  child: Column(children: [
                    const Text('Nigehban', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('نگہبان', style: TextStyle(color: Color(0xFFF2B233), fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text(S.t('tagline'), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, letterSpacing: 0.3)),
                  ]),
                ),
              ),
              const Spacer(flex: 6),
              FadeTransition(
                opacity: _textFade,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text(S.t('privacy'), style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
