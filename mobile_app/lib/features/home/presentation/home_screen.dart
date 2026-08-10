import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../directory/presentation/app_drawer.dart';
import '../../directory/presentation/app_bottom_navigation.dart';
import '../../directory/presentation/ads_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final lang = ref.watch(languageStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
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
          'ABRP',
          style: GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
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
                image: user?.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user!.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user?.avatarUrl == null
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
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting Section
            Text(
              'Jai Shree Krishna,',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${user?.fullName ?? 'Basant Rander'}!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),


            // Carousel Section (Events + Ads together)
            Consumer(
              builder: (context, ref, _) {
                final carouselAds = ref.watch(adsByPlacementProvider('home_carousel')).value ?? [];
                return SizedBox(
                  height: 270,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Carousel Card 1: Upcoming Event
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Image.network(
                                    'https://lh3.googleusercontent.com/gps-cs-s/AHRPTWkmefiChBJ0IIWUeFtuJJ-dvjed_XzRjOCYr0RauyP0pL-556MAyDLh5a4rZAMXnhNyOjSaAcM6w-GMr7kt8G62KykrX4zAxgKW0k5px8T2S4MYd5DhWWtngvWO-8Raw4FaaIjfOjhqf9yI=s1360-w1360-h1020-rw',
                                    height: 130,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 130,
                                      color: theme.colorScheme.primaryContainer,
                                      child: Icon(Icons.temple_hindu_outlined, color: primaryColor, size: 48),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'LATEST',
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '6th Sammelan, 2026 at Ayodhya',
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'June 19 - 21, 2026',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2.0),
                                          child: Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Asharfi Bhawan Chauraha Rd, Tulsi Nagar, Ayodhya, Uttar Pradesh 224123',
                                            style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Carousel Card 2: Community News
                      Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.secondary.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.campaign_outlined, color: secondaryColor, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'COMMUNITY NEWS',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'New Mahila Mandal Committee Announced for 2026',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'The Rander Parivar Samaj is proud to introduce the newly elected members of the Mahila Mandal...',
                                  style: GoogleFonts.inter(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('News details will be available soon.')),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Read More', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.arrow_forward, size: 14, color: primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Dynamic Ad Cards from home_carousel placement
                      ...carouselAds.map((ad) => Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Full image background
                              if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: ad.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: theme.colorScheme.primaryContainer),
                                  errorWidget: (_, __, ___) => Container(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Icon(Icons.storefront_rounded, color: primaryColor, size: 48),
                                  ),
                                )
                              else
                                Container(
                                  color: theme.colorScheme.primaryContainer,
                                  child: Icon(Icons.storefront_rounded, color: primaryColor, size: 48),
                                ),
                              // Gradient overlay from bottom
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.black.withValues(alpha: 0.1),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                              // SPONSORED badge top-left
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SPONSORED',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                              ),
                              // Title + tagline bottom
                              Positioned(
                                bottom: 16,
                                left: 14,
                                right: 14,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ad.title,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (ad.tagline != null && ad.tagline!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        ad.tagline!,
                                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (ad.location != null && ad.location!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 13, color: Colors.white70),
                                          const SizedBox(width: 3),
                                          Text(ad.location!, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Links Section
            Text(
              'Quick Links',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildQuickLinkItem(
                  context: context,
                  icon: Icons.event_note_rounded,
                  label: 'Events',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Events will be available soon.'),
                      ),
                    );
                  },
                  theme: theme,
                ),
                _buildQuickLinkItem(
                  context: context,
                  icon: Icons.storefront_rounded,
                  label: 'Businesses',
                  onTap: () {
                    context.push('/business-directory');
                  },
                  theme: theme,
                ),
                _buildQuickLinkItem(
                  context: context,
                  icon: Icons.groups_rounded,
                  label: 'Committee',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Committee details will be available soon.',
                        ),
                      ),
                    );
                  },
                  theme: theme,
                ),
                _buildQuickLinkItem(
                  context: context,
                  icon: Icons.article_rounded,
                  label: 'News Board',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('News Board will be available soon.'),
                      ),
                    );
                  },
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── My Family Card ───────────────────────────────────────────
            _MyFamilyCard(lang: lang),
            const SizedBox(height: 24),

            // Admin/Moderator Panel Quick Link
            if (user?.role == 'admin' || user?.role == 'moderator') ...[
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user?.role == 'admin'
                                ? AppTranslations.get('admin_features', lang)
                                : AppTranslations.get('zone_coordinator_panel', lang),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.role == 'admin'
                            ? AppTranslations.get('admin_desc', lang)
                            : AppTranslations.get('zone_coordinator_desc', lang),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/admin'),
                        child: Text(
                          user?.role == 'admin'
                              ? AppTranslations.get('admin_dashboard', lang)
                              : AppTranslations.get('zone_coordinator_panel', lang),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Dynamic Home Bottom Ad Banner — with image
            Consumer(
              builder: (context, ref, _) {
                final bottomAds = ref.watch(adsByPlacementProvider('home_bottom_banner')).value ?? [];
                if (bottomAds.isEmpty) return const SizedBox.shrink();
                final ad = bottomAds.first;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Full image
                        if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: ad.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: theme.colorScheme.primaryContainer),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFFFFFDF5),
                              child: const Icon(Icons.campaign, color: Color(0xFF795900), size: 36),
                            ),
                          )
                        else
                          Container(
                            color: const Color(0xFFFFFDF5),
                            child: const Icon(Icons.campaign, color: Color(0xFF795900), size: 36),
                          ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.72),
                                Colors.black.withValues(alpha: 0.08),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // SPONSORED badge + text
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SPONSORED · ${ad.category}',
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ad.title,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ad.tagline != null && ad.tagline!.isNotEmpty)
                                Text(
                                  ad.tagline!,
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildQuickLinkItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── MY FAMILY CARD ───────────────────────────────────────────────────────────

class _MyFamilyCard extends ConsumerStatefulWidget {
  final AppLanguage lang;
  const _MyFamilyCard({required this.lang});

  @override
  ConsumerState<_MyFamilyCard> createState() => _MyFamilyCardState();
}

class _MyFamilyCardState extends ConsumerState<_MyFamilyCard> {
  bool _loading = true;
  Map<String, dynamic>? _familyData;
  int _memberCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/my-family');
      if (!mounted) return;

      final familyMap = response.data['family'] as Map<String, dynamic>?;
      int memberCount = 0;
      if (familyMap != null) {
        final familyId = familyMap['id'] as int;
        final treeResponse = await dio.get('/directory/family/$familyId/tree');
        final membersList = treeResponse.data['members'] as List<dynamic>?;
        memberCount = membersList?.length ?? 0;
      }

      setState(() {
        _familyData = familyMap;
        _memberCount = memberCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'error'; // triggers error UI
        _loading = false;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Expanded(
                  child: Text('Something went wrong. Please try again.'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Dismiss',
                ),
                const SizedBox(width: 8),
              ],
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadFamily,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = widget.lang == AppLanguage.hi;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Loading state
    if (_loading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.05),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Could not load family info.',
                style: GoogleFonts.inter(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(onPressed: _loadFamily, child: const Text('Retry')),
          ],
        ),
      );
    }

    // ── No family registered yet ─────────────────────────────────────────
    if (_familyData == null) {
      return Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.error.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    color: colorScheme.error,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'मेरा परिवार' : 'My Family',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.secondary,
                        ),
                      ),
                      Text(
                        isHindi ? 'अभी तक पंजीकृत नहीं' : 'Not registered yet',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isHindi
                  ? 'समाज में अपनी पारिवारिक जानकारी दर्ज करें और परिवार के सदस्यों को जोड़ें।'
                  : 'Register your family in the directory and start adding your family members to build your tree.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/onboard-family');
                  _loadFamily();
                },
                icon: const Icon(Icons.add_home_work_outlined),
                label: Text(
                  isHindi ? 'परिवार पंजीकृत करें' : 'Register Your Family',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Family is registered ─────────────────────────────────────────────
    final familyId = _familyData!['id'] as int;
    final familyCode = _familyData!['familyCode'] as String? ?? '';
    final villageName = (_familyData!['village']?['name'] ?? '') as String;

    return InkWell(
      onTap: () => context.push('/family/$familyId/tree'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Parivar Profile',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$familyCode • $villageName',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.account_tree_outlined, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FAMILY MEMBERS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_memberCount',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTRIBUTIONS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '4',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
