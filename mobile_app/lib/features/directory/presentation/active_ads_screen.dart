import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import 'ads_provider.dart';
import 'directory_models.dart';
import 'app_bottom_navigation.dart';

class ActiveAdsScreen extends ConsumerStatefulWidget {
  const ActiveAdsScreen({super.key});

  @override
  ConsumerState<ActiveAdsScreen> createState() => _ActiveAdsScreenState();
}

class _ActiveAdsScreenState extends ConsumerState<ActiveAdsScreen> {
  String _selectedCategory = 'All';

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsapp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = ref.watch(languageStateProvider);
    final adsAsync = ref.watch(allActiveAdsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        title: Text(
          AppTranslations.get('active_ads_title', lang),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load ads', style: GoogleFonts.inter(color: Colors.red)),
              ElevatedButton(
                onPressed: () => ref.refresh(allActiveAdsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (ads) {
          if (ads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No active business promotions',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.secondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.get('active_ads_subtitle', lang),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          // Extract unique categories
          final categories = ['All', ...ads.map((a) => a.category).toSet()];

          final filteredAds = _selectedCategory == 'All'
              ? ads
              : ads.where((a) => a.category == _selectedCategory).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(allActiveAdsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF795900), const Color(0xFFB22B1D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF795900).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.white, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppTranslations.get('active_ads_title', lang),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppTranslations.get('active_ads_subtitle', lang),
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: const Color(0xFF795900),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Ad Cards List
                ...filteredAds.map((ad) => _buildAdCard(context, ad, lang, theme)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildAdCard(BuildContext context, AdvertisementModel ad, AppLanguage lang, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final primaryColor = const Color(0xFF795900);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image if available
          if (ad.imageUrl != null && ad.imageUrl!.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl!.trim(),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (ctx, url) => Container(
                  height: 160,
                  color: Colors.grey.shade100,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (ctx, url, err) => const SizedBox.shrink(),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        AppTranslations.get('sponsored', lang).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ad.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Text(
                  ad.title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (ad.tagline != null && ad.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ad.tagline!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (ad.location != null && ad.location!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        ad.location!,
                        style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // CTA Buttons Row
                Row(
                  children: [
                    if (ad.contactMobile != null && ad.contactMobile!.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => _launchPhone(ad.contactMobile!),
                        icon: const Icon(Icons.phone, size: 14, color: Colors.green),
                        label: Text(AppTranslations.get('call_now', lang), style: const TextStyle(color: Colors.green, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (ad.whatsappMobile != null && ad.whatsappMobile!.isNotEmpty) ...[
                      OutlinedButton.icon(
                        onPressed: () => _launchWhatsapp(ad.whatsappMobile!),
                        icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF25D366)),
                        label: Text(AppTranslations.get('whatsapp', lang), style: const TextStyle(color: Color(0xFF25D366), fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (ad.targetUrl != null && ad.targetUrl!.isNotEmpty) ...[
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(ad.targetUrl!),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Visit', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
