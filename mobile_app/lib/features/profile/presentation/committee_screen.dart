import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';

class CommitteeScreen extends ConsumerWidget {
  const CommitteeScreen({super.key});

  void _shareDetails(bool isHindi) {
    final shareText = isHindi
        ? '''🙏 श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार 🙏
मुख्य प्रेरणास्रोत एवं भामाशाह:
स्व. श्री चांदमल जी रांदड़ (मंगलाना)

"समाज सेवा, शिक्षा संवर्धन एवं बंधुत्व ही हमारा संकल्प है।"'''
        : '''🙏 Shri Akhil Bhartiya (Maheshwari) Rander Pariwar 🙏
Chief Patron & Inspiration:
Late Shri Chandmal Ji Rander (Manglana)

"Dedicated to community welfare, youth education, and social unity."''';

    SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: isHindi
            ? 'अखिल भारतीय रांदड़ परिवार समिति'
            : 'ABRP Committee & Patrons',
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
          isHindi ? 'कार्यकारिणी एवं प्रेरणास्रोत' : 'Committee & Patrons',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: isHindi ? 'साझा करें' : 'Share',
            onPressed: () => _shareDetails(isHindi),
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
          _buildBhamashahHeroCard(context, isHindi),
          const SizedBox(height: 18),

          // ─── 2. Organization Vision & Mission ───────────────────
          _buildVisionSection(context, isHindi),
          const SizedBox(height: 18),

          // ─── 3. Executive Committee Structure ───────────────────
          _buildCommitteeStructureSection(context, isHindi),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. Patron & Inspiration Hero Card (Late Shri Chandmal Ji Rander)
  // ─────────────────────────────────────────────────────────────
  Widget _buildBhamashahHeroCard(BuildContext context, bool isHindi) {
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
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Frame
              Container(
                width: 95,
                height: 118,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11.5),
                  child: Image.asset(
                    'assets/images/chandmal_ji_rander.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.amber.shade100,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF553D00),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Title & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isHindi
                            ? 'मुख्य प्रेरणास्रोत एवं भामाशाह'
                            : 'CHIEF PATRON & INSPIRATION',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: const Color(0xFF553D00),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isHindi
                          ? 'स्व. श्री चांदमल जी रांदड़'
                          : 'Late Shri Chandmal Ji Rander',
                      style: GoogleFonts.outfit(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHindi ? 'मंगलाना (राजस्थान)' : 'Manglana (Rajasthan)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade100,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi
                          ? 'श्री अखिल भारतीय (माहेश्वरी) रांदड़ परिवार'
                          : 'Shri Akhil Bhartiya (Maheshwari) Rander Pariwar',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                    isHindi
                        ? 'समाज की सेवा, शिक्षा का संवर्धन एवं जरूरतमंदों का उत्थान ही सबसे बड़ा धर्म है।'
                        : 'Dedication to community upliftment, education of youth, and supporting families in need.',
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
  Widget _buildVisionSection(BuildContext context, bool isHindi) {
    final colorScheme = Theme.of(context).colorScheme;

    final objectives = [
      {
        'icon': Icons.family_restroom_rounded,
        'title': isHindi ? 'पारिवारिक समन्वय एवं एकता' : 'Family Unity & Lineage',
        'desc': isHindi
            ? 'देशभर में बसे समस्त रांदड़ परिवारों को एक सूत्र में जोड़ना एवं परिचय सम्मेलन आयोजित करना।'
            : 'Connecting all Rander families across India and fostering matrimonial and social harmony.',
        'color': const Color(0xFF2563EB),
      },
      {
        'icon': Icons.school_rounded,
        'title': isHindi ? 'शिक्षा संवर्धन एवं छात्रवृत्ति' : 'Education & Scholarships',
        'desc': isHindi
            ? 'मेधावी एवं जरूरतमंद छात्र-छात्राओं को उच्च शिक्षा, कोचिंग एवं छात्रवृत्ति सहायता।'
            : 'Providing scholarships, career counseling, and academic support to deserving youth.',
        'color': const Color(0xFF059669),
      },
      {
        'icon': Icons.account_balance_rounded,
        'title': isHindi ? 'समाज भवन एवं छात्रावास' : 'Community Infrastructure',
        'desc': isHindi
            ? 'तीर्थ क्षेत्रों एवं प्रमुख नगरों में समाज भवन, धर्मशाला एवं विद्यार्थियों हेतु छात्रावास निर्माण।'
            : 'Developing community halls, dharamshalas, and student hostels in pilgrimage centers.',
        'color': const Color(0xFFD97706),
      },
      {
        'icon': Icons.health_and_safety_rounded,
        'title': isHindi ? 'चिकित्सा एवं सामाजिक सहयोग' : 'Healthcare & Social Care',
        'desc': isHindi
            ? 'आकस्मिक स्वास्थ्य संकट में सहायता एवं वरिष्ठ नागरिकों का सम्मान व सहयोग।'
            : 'Emergency healthcare aid, senior citizen welfare, and community mutual aid programs.',
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
              isHindi ? 'समिति के मुख्य उद्देश्य एवं संकल्प' : 'Objectives & Core Vision',
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

  // ─────────────────────────────────────────────────────────────
  // 3. Central Executive Committee Structure
  // ─────────────────────────────────────────────────────────────
  Widget _buildCommitteeStructureSection(BuildContext context, bool isHindi) {
    final colorScheme = Theme.of(context).colorScheme;

    final roles = [
      {'role': isHindi ? 'संरक्षक मंडल' : 'Board of Patrons', 'icon': Icons.military_tech_rounded},
      {'role': isHindi ? 'राष्ट्रीय अध्यक्ष' : 'National President', 'icon': Icons.stars_rounded},
      {'role': isHindi ? 'वरिष्ठ उपाध्यक्ष' : 'Senior Vice President', 'icon': Icons.workspace_premium_rounded},
      {'role': isHindi ? 'राष्ट्रीय महामंत्री' : 'General Secretary', 'icon': Icons.assignment_ind_rounded},
      {'role': isHindi ? 'कोषाध्यक्ष' : 'Treasurer', 'icon': Icons.account_balance_wallet_rounded},
      {'role': isHindi ? 'संगठन मंत्री' : 'Organization Secretary', 'icon': Icons.hub_rounded},
      {'role': isHindi ? 'युवा एवं महिला प्रकोष्ठ' : 'Youth & Women Wings', 'icon': Icons.diversity_3_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'केंद्रीय कार्यकारिणी संरचना' : 'Executive Committee Structure',
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isHindi
                ? 'अखिल भारतीय स्तर पर समाज के सुचारु संचालन एवं विकास हेतु गठित।'
                : 'Formed for the harmonious governance and advancement of the Samaj nationwide.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roles.map((r) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r['icon'] as IconData, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      r['role'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
