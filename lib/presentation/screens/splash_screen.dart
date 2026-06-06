import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent  = AppTheme.goldPremium;

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _dotController;
  late AnimationController _bgController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _dotOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _dotOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeIn),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _textController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _dotController.forward();

    final authState = ref.read(authProvider);
    if (!authState.isInitialized) {
      int retries = 0;
      while (!ref.read(authProvider).isInitialized && retries < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.token != null && auth.user != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14), // Deep midnight black
      body: Stack(
        children: [
          // Ambient Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.0 + (_bgController.value * 0.4),
                      colors: [
                        AppTheme.navyDeep.withOpacity(0.6),
                        const Color(0xFF060B14),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Logo Animation with Breathing Ring
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Breathing Glow Ring
                            AnimatedBuilder(
                              animation: _bgController,
                              builder: (context, child) {
                                return Container(
                                  width: 140 + (_bgController.value * 40),
                                  height: 140 + (_bgController.value * 40),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.goldPremium.withOpacity(0.05 + (_bgController.value * 0.1)),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: AppTheme.goldPremium.withOpacity(_bgController.value * 0.05), blurRadius: 40, spreadRadius: 10),
                                    ]
                                  ),
                                );
                              }
                            ),
                            // Logo Container
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
                                // Glassmorphism backdrop effect could go here, but colors work fine
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 80, height: 80,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.gavel_rounded, size: 60, color: AppTheme.goldPremium),
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .scaleXY(end: 1.03, duration: 2.seconds, curve: Curves.easeInOut)
                             .shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.3)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 56),

                // Premium App Name with Gold Gradient
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFD4AF37), AppTheme.goldPremium], // Shimmering Gold
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'QANOON BUDDY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Elite Tagline Badge
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineOpacity.value,
                      child: SlideTransition(
                        position: _taglineSlide,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.goldPremium.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppTheme.goldPremium.withOpacity(0.2)),
                          ),
                          child: const Text(
                            'AI LEGAL INTELLIGENCE',
                            style: TextStyle(
                              color: AppTheme.goldPremium,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer (Loader & Branding)
          Positioned(
            bottom: 50,
            left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, child) {
                return Opacity(
                  opacity: _dotOpacity.value,
                  child: Column(
                    children: [
                      _ProtocolLoader(),
                      const SizedBox(height: 40),
                      const Text(
                        'POWERED BY',
                        style: TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'MAIRAJ ELITE SYSTEMS',
                        style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtocolLoader extends StatefulWidget {
  @override
  State<_ProtocolLoader> createState() => _ProtocolLoaderState();
}

class _ProtocolLoaderState extends State<_ProtocolLoader> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 2,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset((_controller.value * 2) - 1.0, 0),
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldPremium.withOpacity(0.0),
                      AppTheme.goldPremium,
                      AppTheme.goldPremium.withOpacity(0.0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(color: AppTheme.goldPremium.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}