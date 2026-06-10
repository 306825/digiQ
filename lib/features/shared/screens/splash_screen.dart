import 'package:digiQ/features/shared/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Logo: scale + fade
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Brand name: slide up + fade
  late final Animation<double> _textOffset;
  late final Animation<double> _textOpacity;

  // Tagline: fade
  late final Animation<double> _taglineOpacity;

  // Loading dots: fade
  late final Animation<double> _dotsOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    // ── Logo ────────────────────────────────────────────────
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // ── Brand name ──────────────────────────────────────────
    _textOffset = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOut),
      ),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.55, curve: Curves.easeIn),
      ),
    );

    // ── Tagline ─────────────────────────────────────────────
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.72, curve: Curves.easeIn),
      ),
    );

    // ── Loading dots ─────────────────────────────────────────
    _dotsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.90, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1E45), Color(0xFF0D47A1), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ── CENTRE CONTENT ──────────────────────────────────
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: const AppLogo(size: 96, dark: true),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Brand name
                        Opacity(
                          opacity: _textOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _textOffset.value),
                            child: Text(
                              'digiQ',
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Tagline
                        Opacity(
                          opacity: _taglineOpacity.value,
                          child: Text(
                            'Your trusted ride-share platform',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── LOADING DOTS (bottom) ───────────────────────────
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _dotsOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _dotsOpacity.value,
                    child: const _PulsingDots(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dots that pulse sequentially to indicate loading.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Stagger each dot by 0.2
            final offset = i * 0.2;
            final t = ((_ctrl.value - offset) % 1.0).clamp(0.0, 1.0);
            // Pulse: fade up then back down
            final opacity = t < 0.5 ? t * 2 : (1.0 - t) * 2;
            final scale = 0.6 + opacity * 0.4;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3 + opacity * 0.6),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
