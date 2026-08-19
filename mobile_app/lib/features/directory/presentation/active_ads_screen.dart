import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../auth/presentation/auth_controller.dart';
import 'ads_provider.dart';
import 'ad_banner_card.dart';
import 'app_drawer.dart';
import 'app_bottom_navigation.dart';

class ActiveAdsScreen extends ConsumerStatefulWidget {
  const ActiveAdsScreen({super.key});

  @override
  ConsumerState<ActiveAdsScreen> createState() => _ActiveAdsScreenState();
}

class _ActiveAdsScreenState extends ConsumerState<ActiveAdsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final lang = ref.watch(languageStateProvider);
    final adsAsync = ref.watch(allActiveAdsProvider);
    final user = ref.watch(authProvider).user;
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, color: primaryColor),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          AppTranslations.get('active_ads_title', lang),
          style: GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications will be available soon.'),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
                image: hasAvatar
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasAvatar
                  ? Icon(
                      Icons.person,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.secondary.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: adsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load advertisements', style: GoogleFonts.inter(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(allActiveAdsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (ads) {
          Future<void> onRefresh() async {
            ref.invalidate(allActiveAdsProvider);
            ref.invalidate(adsByPlacementProvider('directory_feed'));
            ref.invalidate(adsByPlacementProvider('directory_header'));
            ref.invalidate(adsByPlacementProvider('home_carousel'));
            ref.invalidate(adsByPlacementProvider('home_bottom_banner'));
            await ref.read(allActiveAdsProvider.future);
          }

          if (ads.isEmpty) {
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Active Business Promotions',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Active promotions and advertisements running across the community will be listed here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(16.0),
              itemCount: ads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return AdBannerCard(
                  ad: ad,
                  height: 140,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 3),
    );
  }
}
