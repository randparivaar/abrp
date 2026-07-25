import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingItem {
  final String title;
  final String subtitle;
  final String hindiSubtitle;
  final List<Color> gradientColors;
  final Widget illustration;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.hindiSubtitle,
    required this.gradientColors,
    required this.illustration,
  });
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final _storage = const FlutterSecureStorage();

  Future<void> _completeOnboarding() async {
    try {
      await _storage.write(key: 'has_completed_onboarding', value: 'true');
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
    }
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goldAccent = Color(0xFFF6BE3B);
    const goldPrimary = Color(0xFFDAA520);

    final List<OnboardingItem> pages = [
      // Slide 1: Global Community
      OnboardingItem(
        title: 'We Are a Connected Community',
        subtitle: 'Connecting thousands of families across 600+ cities and regions seamlessly.',
        hindiSubtitle: '६००+ शहरों में फैले परिवारों का अद्भुत संगम और अटूट बंधन।',
        gradientColors: [
          const Color(0xFF2C0B35),
          const Color(0xFF4A1058),
          const Color(0xFF190520),
        ],
        illustration: _buildCommunityIllustration(goldAccent, goldPrimary),
      ),
      // Slide 2: Values & Heritage
      OnboardingItem(
        title: 'We Believe in Uplifting Every Member',
        subtitle: 'Rooted in traditional values while empowering every family to grow together.',
        hindiSubtitle: 'परंपरागत संस्कारों और समाज सेवा के साथ हर परिवार की उन्नति।',
        gradientColors: [
          const Color(0xFF1E0A3C),
          const Color(0xFF3B1066),
          const Color(0xFF120429),
        ],
        illustration: _buildValuesIllustration(goldAccent, goldPrimary),
      ),
      // Slide 3: Family Lineage & Growth
      OnboardingItem(
        title: 'Preserve Your Family Tree & Lineage',
        subtitle: 'Document your multi-generational family tree, business directory, and unite generations.',
        hindiSubtitle: 'अपनी पीढ़ियों के इतिहास और वंश वृक्ष को डिजिटल रूप से सुरक्षित रखें।',
        gradientColors: [
          const Color(0xFF3B0C0E),
          const Color(0xFF5E1316),
          const Color(0xFF210507),
        ],
        illustration: _buildLineageIllustration(goldAccent, goldPrimary),
      ),
    ];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2),
            radius: 1.25,
            colors: pages[_currentIndex].gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar: Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentIndex < pages.length - 1)
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 40),
                  ],
                ),
              ),

              // PageView Slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final item = pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Title
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Subtitle English
                          Text(
                            item.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle Hindi
                          Text(
                            item.hindiSubtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: goldAccent.withValues(alpha: 0.9),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Center Graphic Illustration
                          item.illustration,
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Navigation Section (Dots + Next Arrow Button)
              Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 28.0, top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot Page Indicators
                    Row(
                      children: List.generate(
                        pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          width: _currentIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? goldAccent
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Floating Action Arrow Button (Next / Get Started)
                    GestureDetector(
                      onTap: () {
                        if (_currentIndex < pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: goldAccent.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _currentIndex == pages.length - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          color: const Color(0xFF2C0B35),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Illustration 1: Community Connection ---
  static Widget _buildCommunityIllustration(Color goldAccent, Color goldPrimary) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            goldAccent.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Decorative Ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          // Inner Circle Icon Badge
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF381045),
              border: Border.all(
                color: goldAccent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldAccent.withValues(alpha: 0.3),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_rounded,
                  size: 54,
                  color: goldAccent,
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.public_rounded,
                  size: 26,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Illustration 2: Values & Culture Mandala ---
  static Widget _buildValuesIllustration(Color goldAccent, Color goldPrimary) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            goldAccent.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mandala Star/Petal Rings
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldAccent.withValues(alpha: 0.25),
                width: 2.0,
              ),
            ),
            child: Icon(
              Icons.brightness_7_rounded,
              size: 200,
              color: goldAccent.withValues(alpha: 0.15),
            ),
          ),
          // Center Cultural Motif Badge
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2C0A4B),
              border: Border.all(
                color: goldAccent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldAccent.withValues(alpha: 0.4),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 54,
                  color: goldAccent,
                ),
                const SizedBox(height: 6),
                Text(
                  'सेवा व संस्कार',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Illustration 3: Lineage & Growth Lotus/Tree ---
  static Widget _buildLineageIllustration(Color goldAccent, Color goldPrimary) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            goldAccent.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative Petal Outer Ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: goldAccent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          // Center Tree of Lineage Badge
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF450D10),
              border: Border.all(
                color: goldAccent,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: goldAccent.withValues(alpha: 0.4),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.park_rounded,
                  size: 56,
                  color: goldAccent,
                ),
                const SizedBox(height: 4),
                Text(
                  'कुल वृक्ष',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
