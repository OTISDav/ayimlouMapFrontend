import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  static const Color _white  = Color(0xFFFFFFFF);
  static const Color _bg     = Color(0xFFF7F3EE);
  static const Color _orange = Color(0xFFFF5C2A);
  static const Color _green  = Color(0xFF00B87C);
  static const Color _yellow = Color(0xFFFFCC00);
  static const Color _dark   = Color(0xFF1A1A1A);
  static const Color _grey   = Color(0xFF9A9A9A);

  late final AnimationController _blobCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _dotCtrl;

  late final Animation<double> _blobAnim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotate;
  late final Animation<Offset>  _cardSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset>  _titleSlide;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _blobCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _blobAnim = CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));
    _logoRotate = Tween<double>(begin: -0.3, end: 0.0).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _cardSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.0, 0.5)));
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)));
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _cardCtrl, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));

    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();

    _runSequence();
  }

  bool _readyToGo = false;

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _cardCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _readyToGo = true); // affiche le bouton
  }

  void _goToMap() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => MapScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _logoCtrl.dispose();
    _cardCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_blobCtrl, _logoCtrl, _cardCtrl, _dotCtrl]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _buildBlobs(size),
              _buildFloatingDots(size),
              Positioned(top: size.height * 0.15, left: 0, right: 0, child: _buildLogo()),
              Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomCard(size)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBlobs(Size size) {
    final t = _blobAnim.value;
    return Stack(children: [
      Positioned(top: -60 + t * 20, right: -40 + t * 15, child: _blob(size: 280 + t * 30, color: _orange.withOpacity(0.18))),
      Positioned(top: 40 - t * 15, left: -70 + t * 10, child: _blob(size: 220 + t * 20, color: _green.withOpacity(0.15))),
      Positioned(top: size.height * 0.28 + t * 10, left: size.width * 0.3, child: _blob(size: 160 + t * 15, color: _yellow.withOpacity(0.2))),
    ]);
  }

  Widget _blob({required double size, required Color color}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildFloatingDots(Size size) {
    final configs = [
      [30.0, 120.0, _orange, 8.0],
      [size.width - 50, 180.0, _green, 6.0],
      [60.0, size.height * 0.4, _yellow, 10.0],
      [size.width - 35, size.height * 0.35, _orange, 5.0],
      [size.width * 0.5, 80.0, _green, 7.0],
    ];
    return Stack(
      children: configs.map((d) {
        final left = d[0] as double;
        final top = d[1] as double;
        final color = d[2] as Color;
        final sz = d[3] as double;
        final bounce = math.sin((_blobAnim.value + left / 100) * math.pi) * 6;
        return Positioned(
          left: left, top: top + bounce,
          child: Container(width: sz, height: sz,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.5))),
        );
      }).toList(),
    );
  }

  Widget _buildLogo() {
    return Transform.scale(
      scale: _logoScale.value,
      child: Transform.rotate(
        angle: _logoRotate.value,
        child: Opacity(
          opacity: _logoOpacity.value,
          child: Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _orange.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)])),
              Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_orange, Color(0xFFFF3D00)]),
                      boxShadow: [BoxShadow(color: _orange.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))]),
                  child: const Center(child: Text('🍚', style: TextStyle(fontSize: 46)))),
              Positioned(bottom: 6, right: 6,
                  child: Container(width: 28, height: 28,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _green, border: Border.all(color: _bg, width: 2)),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard(Size size) {
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardOpacity,
        child: Container(
          height: size.height * 0.42,
          decoration: const BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 40, offset: Offset(0, -8))],
          ),
          padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 28),
              FadeTransition(
                opacity: _titleOpacity,
                child: SlideTransition(
                  position: _titleSlide,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Ayimolou', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: _dark, letterSpacing: -1, height: 1)),
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(6)),
                        child: const Text('MAP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(width: 60, height: 3, decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Container(width: 20, height: 3, decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 4),
                      Container(width: 10, height: 3, decoration: BoxDecoration(color: _yellow, borderRadius: BorderRadius.circular(2))),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _taglineOpacity,
                child: Text("Trouve l'ayimolou le plus proche\nde toi en quelques secondes.",
                    style: const TextStyle(fontSize: 15, color: _grey, height: 1.55)),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _taglineOpacity,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Row(children: [
                    _buildProgressDots(),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _readyToGo ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: GestureDetector(
                        onTap: _readyToGo ? _goToMap : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: _orange.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Commencer',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(3, (i) {
        final phase = (_dotCtrl.value - i * 0.25) % 1.0;
        final isActive = phase < 0.4;
        final colors = [_orange, _green, _yellow];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 22 : 8, height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? colors[i] : colors[i].withOpacity(0.2),
          ),
        );
      }),
    );
  }
}