import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../data/legal_repository.dart';

class FaqSupportScreen extends ConsumerStatefulWidget {
  const FaqSupportScreen({super.key});

  @override
  ConsumerState<FaqSupportScreen> createState() => _FaqSupportScreenState();
}

class _FaqSupportScreenState extends ConsumerState<FaqSupportScreen> {
  List<FaqModel> _faqs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() => _isLoading = true);
    final lang = ref.read(languageStateProvider);
    final repo = ref.read(legalRepositoryProvider);
    final items = await repo.getFaqs(lang);
    if (mounted) {
      setState(() {
        _faqs = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendSupportEmail() async {
    final mailUri = Uri(
      scheme: 'mailto',
      path: 'randerparivaar@gmail.com',
      queryParameters: {'subject': 'ABRP App Support Inquiry'},
    );
    if (await canLaunchUrl(mailUri)) {
      await launchUrl(mailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredFaqs = _searchQuery.isEmpty
        ? _faqs
        : _faqs.where((f) {
            final q = _searchQuery.toLowerCase();
            return f.question.toLowerCase().contains(q) ||
                f.answer.toLowerCase().contains(q) ||
                f.category.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppTranslations.get('help_support', lang),
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Switch Language / भाषा बदलें',
            onPressed: () {
              final newLang = lang == AppLanguage.en ? AppLanguage.hi : AppLanguage.en;
              ref.read(languageStateProvider.notifier).setLanguage(newLang);
              Future.microtask(_loadFaqs);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Support Contact Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          lang == AppLanguage.hi ? 'सहायता केंद्र' : 'Community Support Desk',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == AppLanguage.hi
                              ? 'किसी भी तकनीकी समस्या या समाज डायरेक्टरी सत्यापन में सहायता हेतु हमारी समिति से संपर्क करें।'
                              : 'Reach out to the ABRP Samaj administration team for any technical, onboarding, or verification assistance.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _sendSupportEmail,
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: Text(
                            'randerparivaar@gmail.com',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: lang == AppLanguage.hi ? 'प्रश्न खोजें...' : 'Search questions...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FAQs Header
                  Text(
                    AppTranslations.get('faqs', lang),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // FAQ Expansion Tiles
                  if (filteredFaqs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          lang == AppLanguage.hi ? 'कोई परिणाम नहीं मिला।' : 'No matching questions found.',
                          style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...filteredFaqs.map((faq) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                            ),
                          ),
                          elevation: 0,
                          child: Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.help_outline, color: colorScheme.primary, size: 20),
                              ),
                              title: Text(
                                faq.question,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  faq.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      faq.answer,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        height: 1.5,
                                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
