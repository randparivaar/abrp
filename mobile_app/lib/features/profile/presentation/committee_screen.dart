import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';

class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  void _shareDetails(AppLanguage lang) {
    SharePlus.instance.share(
      ShareParams(
        text: AppTranslations.get('committee_share_text', lang),
        subject: AppTranslations.get('committee_share_subject', lang),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageStateProvider);
    final isHindi = lang == AppLanguage.hi;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppTranslations.get('committee_title', lang),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: AppTranslations.get('committee_share_tooltip', lang),
            onPressed: () => _shareDetails(lang),
          ),
          TextButton(
            onPressed: () {
              final newLang =
                  lang == AppLanguage.en ? AppLanguage.hi : AppLanguage.en;
              ref.read(languageStateProvider.notifier).setLanguage(newLang);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isHindi ? 'English' : 'हिंदी',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // ─── 1. Late Shri Chandmal Ji Rander (Manglana) Hero Tribute ───────
          _buildBhamashahHeroCard(context, lang),
          const SizedBox(height: 18),

          // ─── 2. Organization Vision & Mission ───────────────────
          _buildVisionSection(context, lang),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Patron & Inspiration Hero Card (Late Shri Chandmal Ji Rander)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBhamashahHeroCard(BuildContext context, AppLanguage lang) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF553D00), Color(0xFF8A6400), Color(0xFFA17700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF553D00).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.shade200,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              AppTranslations.get('patron_badge', lang),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: const Color(0xFF553D00),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Photo Frame in Center
          Container(
            width: 110,
            height: 135,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE082), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                'assets/images/chandmal_ji_rander.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.amber.shade100,
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF553D00),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Next Line: Name
          Text(
            AppTranslations.get('patron_name', lang),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),

          // Next Line: Address / Native Place
          Text(
            AppTranslations.get('patron_address', lang),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade100,
            ),
          ),
          const SizedBox(height: 6),

          // Next Line: Community / Lineage
          Text(
            AppTranslations.get('patron_community', lang),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),

          // Quote Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFFFFE082),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTranslations.get('patron_quote', lang),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Vision & Objectives
  // ─────────────────────────────────────────────────────────────
  Widget _buildVisionSection(BuildContext context, AppLanguage lang) {
    final colorScheme = Theme.of(context).colorScheme;

    final objectives = [
      {
        'icon': Icons.family_restroom_rounded,
        'title': AppTranslations.get('obj_family_unity_title', lang),
        'desc': AppTranslations.get('obj_family_unity_desc', lang),
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.school_rounded,
        'title': AppTranslations.get('obj_education_title', lang),
        'desc': AppTranslations.get('obj_education_desc', lang),
        'color': const Color(0xFF059669),
      },
      {
        'icon': Icons.account_balance_rounded,
        'title': AppTranslations.get('obj_infrastructure_title', lang),
        'desc': AppTranslations.get('obj_infrastructure_desc', lang),
        'color': const Color(0xFFD97706),
      },
      {
        'icon': Icons.health_and_safety_rounded,
        'title': AppTranslations.get('obj_healthcare_title', lang),
        'desc': AppTranslations.get('obj_healthcare_desc', lang),
        'color': const Color(0xFFDC2626),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppTranslations.get('committee_vision_title', lang),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: objectives.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final obj = objectives[index];
            final color = obj['color'] as Color;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(obj['icon'] as IconData, size: 22, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obj['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          obj['desc'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.35,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
