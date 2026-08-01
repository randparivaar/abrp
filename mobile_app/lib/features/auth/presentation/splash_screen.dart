import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;
  late AnimationController _particleController;

  late Animation<double> _fadeIn;
  late Animation<double> _titleSlideUp;
  late Animation<double> _titleFade;
  late Animation<double> _image1SlideIn;
  late Animation<double> _image2SlideIn;
  late Animation<double> _decorFade;
  late Animation<double> _dividerScale;
  late Animation<double> _shimmer;
  late Animation<double> _particleRotate;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _image1SlideIn = Tween<double>(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _image2SlideIn = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _titleSlideUp = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );

    _decorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    _dividerScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _shimmer = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _particleRotate = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _mainController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    try {
      await Future.delayed(const Duration(milliseconds: 4000)); // 10 sec
      if (!mounted) return;

      int waitCount = 0;
      while (ref.read(authProvider).isLoading && waitCount < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
        waitCount++;
      }

      if (!mounted) return;

      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      if (isAuthenticated) {
        context.go('/');
        return;
      }

      String? hasCompleted;
      try {
        const storage = FlutterSecureStorage();
        hasCompleted = await storage.read(key: 'has_completed_onboarding');
      } catch (e) {
        debugPrint('SecureStorage error on splash: $e');
      }

      if (!mounted) return;

      if (hasCompleted == 'true') {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Error in splash navigation: $e');
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const Color bgDark = Color(0xFF050000); // near-pure black with red tint
    const Color saffron = Color(0xFFFF7722); // deeper saffron
    const Color gold = Color(0xFFD4A017); // rich antique gold
    const Color goldLight = Color(0xFFF7C948); // bright warm gold
    const Color goldPale = Color(0xFFFFF3B0); // pale gold shimmer
    const Color maroon = Color(0xFF8B0000);
    const Color teal = Color(0xFF00897B);
    const Color deityPink = Color(0xFFE91E8C);

    return Scaffold(
      backgroundColor: const Color(0xFF050000),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _shimmerController,
          _particleController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: _fadeIn.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.25),
                        radius: 1.4,
                        colors: [
                          Color(
                            0xFF6B0000,
                          ), // bright crimson core — like a lit diya
                          Color(0xFF3A0000), // deep blood red
                          Color(0xFF180000), // very dark maroon
                          Color(0xFF050000), // near-black edges
                        ],
                        stops: [0.0, 0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Subtle warm vignette overlay for depth
              Positioned.fill(
                child: Opacity(
                  opacity: _fadeIn.value * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.bottomCenter,
                        radius: 1.2,
                        colors: [
                          const Color(0xFFFF5500).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Decorative rotating mandala particles (top)
              Positioned(
                top: size.height * 0.05,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _decorFade.value * 0.35,
                  child: Transform.rotate(
                    angle: _particleRotate.value * 0.3,
                    child: CustomPaint(
                      size: Size(size.width, 120),
                      painter: _MandalaPainter(goldLight),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // Top blessing strip
                    Opacity(
                      opacity: _decorFade.value,
                      child: _buildTopDecorStrip(goldLight, saffron),
                    ),

                    const SizedBox(height: 14),

                    // Akhil Bhartiya Rander Parivar header
                    Transform.translate(
                      offset: Offset(0, _titleSlideUp.value * 0.5),
                      child: Opacity(
                        opacity: _titleFade.value,
                        child: _buildOrgHeader(
                          gold,
                          goldLight,
                          goldPale,
                          saffron,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Two deity images side-by-side ────────────────────
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Left: pink Mata
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(_image1SlideIn.value, 0),
                                child: Opacity(
                                  opacity: _fadeIn.value,
                                  child: _buildDeityCard(
                                    imagePath: 'assets/images/deity1.jpg',
                                    borderColor: deityPink,
                                    glowColor: deityPink.withValues(alpha: 0.4),
                                    shimmerProgress: (_shimmer.value + 2) / 4,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Right: teal Krishna
                            Expanded(
                              child: Transform.translate(
                                offset: Offset(_image2SlideIn.value, 0),
                                child: Opacity(
                                  opacity: _fadeIn.value,
                                  child: _buildDeityCard(
                                    imagePath: 'assets/images/deity2.jpg',
                                    borderColor: teal,
                                    glowColor: teal.withValues(alpha: 0.4),
                                    shimmerProgress:
                                        1 - (_shimmer.value + 2) / 4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Gold star divider
                    Transform.scale(
                      scaleX: _dividerScale.value,
                      child: Opacity(
                        opacity: _decorFade.value,
                        child: _buildGoldDivider(gold, goldLight),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ABRP main title
                    Transform.translate(
                      offset: Offset(0, _titleSlideUp.value),
                      child: Opacity(
                        opacity: _titleFade.value,
                        child: _buildMainTitle(gold, goldLight, maroon),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Taglines
                    Opacity(
                      opacity: _decorFade.value,
                      child: _buildTagline(goldLight),
                    ),

                    const SizedBox(height: 18),

                    // Loading spinner
                    Opacity(
                      opacity: _decorFade.value,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            goldLight.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopDecorStrip(Color goldLight, Color saffron) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _decorLine(goldLight),
        const SizedBox(width: 8),
        const Text('🙏', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          'जय श्री कृष्ण',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: saffron,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 6),
        const Text('🙏', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        _decorLine(goldLight),
      ],
    );
  }

  Widget _decorLine(Color color) {
    return Container(
      width: 48,
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, color, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildOrgHeader(
    Color gold,
    Color goldLight,
    Color goldPale,
    Color saffron,
  ) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [goldLight, gold, saffron, gold, goldLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            '॥ ॐ ॥',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [goldLight, goldPale, goldLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'अखिल भारतीय',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1.3,
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [goldLight, goldPale, goldLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'रेन्डर परिवार',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AKHIL BHARTIYA RANDER PARIVAR',
          style: GoogleFonts.outfit(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: gold.withValues(alpha: 0.75),
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDeityCard({
    required String imagePath,
    required Color borderColor,
    required Color glowColor,
    required double shimmerProgress,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: glowColor, blurRadius: 24, spreadRadius: 2),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: borderColor.withValues(alpha: 0.7), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Deity image
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1A0505),
                child: const Center(
                  child: Icon(Icons.image, color: Colors.white24, size: 48),
                ),
              ),
            ),
            // Shimmer sweep
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1 + shimmerProgress * 3, -0.5),
                end: Alignment(-0.5 + shimmerProgress * 3, 0.5),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ).createShader(bounds),
              blendMode: BlendMode.srcOver,
              child: Container(color: Colors.transparent),
            ),
            // Bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Top coloured arc
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      borderColor.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoldDivider(Color gold, Color goldLight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, gold]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [gold, goldLight, gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '✦',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [gold, Colors.transparent]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTitle(Color gold, Color goldLight, Color maroon) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [gold, goldLight, Colors.white, goldLight, gold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'ABRP',
            style: GoogleFonts.outfit(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
              shadows: [
                Shadow(color: gold.withValues(alpha: 0.6), blurRadius: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: goldLight.withValues(alpha: 0.4),
              width: 1,
            ),
            color: gold.withValues(alpha: 0.1),
          ),
          child: Text(
            'COMMUNITY PORTAL',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: goldLight,
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline(Color goldLight) {
    return Column(
      children: [
        Text(
          'Connecting Families • Preserving Lineage',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'परिवारों का जुड़ाव • परंपरा का मान',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: goldLight.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// Decorative mandala painter
class _MandalaPainter extends CustomPainter {
  final Color color;
  _MandalaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(Offset(cx, cy), i * 18.0, paint);
    }

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      canvas.drawLine(
        Offset(cx + math.cos(angle) * 18, cy + math.sin(angle) * 18),
        Offset(cx + math.cos(angle) * 72, cy + math.sin(angle) * 72),
        paint,
      );
    }

    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      canvas.drawCircle(
        Offset(cx + math.cos(angle) * 72, cy + math.sin(angle) * 72),
        2.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MandalaPainter old) => old.color != color;
}
