import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:mobile_app/core/utils/name_formatter.dart';
import 'package:go_router/go_router.dart';
import 'business_profile_detail_screen.dart';
import 'directory_models.dart';
import 'directory_constants.dart';
import 'app_bottom_navigation.dart';
import 'business_favorites_provider.dart';
import 'ads_provider.dart';
import '../../../core/widgets/admob_banner_widget.dart';

class BusinessDirectoryScreen extends ConsumerStatefulWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  ConsumerState<BusinessDirectoryScreen> createState() => _BusinessDirectoryScreenState();
}

class _BusinessDirectoryScreenState extends ConsumerState<BusinessDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  List<dynamic> _businesses = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  Timer? _debounce;

  List<Map<String, String>> get _categories {
    final favoritesCount = ref.watch(businessFavoritesProvider).length;
    return [
      {'value': 'all', 'label': 'All'},
      {'value': 'favorites', 'label': '❤️ Favorites${favoritesCount > 0 ? " ($favoritesCount)" : ""}'},
      ...DirectoryConstants.industryCategories.map((item) {
        // Extract the English label (before the slash) to keep it compact on chip
        final fullLabel = item['label'] ?? '';
        final displayLabel = fullLabel.split('/').first.trim();
        return {
          'value': item['value'] ?? '',
          'label': displayLabel,
        };
      }),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadBusinesses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    ref.invalidate(adsByPlacementProvider('directory_feed'));
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/businesses', queryParameters: {
        if (_searchQuery.isNotEmpty) 'q': _searchQuery,
        if (_selectedCategory != 'all' && _selectedCategory != 'favorites') 'category': _selectedCategory,
      });

      if (mounted) {
        setState(() {
          _businesses = response.data['businesses'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load business directory: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _loadBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final surfaceColor = colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    final favorites = ref.watch(businessFavoritesProvider);
    final displayedBusinesses = _selectedCategory == 'favorites'
        ? _businesses.where((biz) => favorites.contains(biz['id'])).toList()
        : _businesses;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/directory');
            }
          },
        ),
        title: Text(
          'Business Directory / व्यापार निर्देशिका',
          style: GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadBusinesses,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: secondaryColor.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBusinesses,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner Ad
              const AdmobBannerWidget(margin: EdgeInsets.only(bottom: 12)),

              // Search Input
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surfaceContainer : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search business name, category, city...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal Category Chips Filter
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final catValue = cat['value'] ?? 'all';
                    final catLabel = cat['label'] ?? '';
                    final isSelected = _selectedCategory == catValue;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(
                          catLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                        selectedColor: primaryColor,
                        backgroundColor: isDark ? colorScheme.surfaceContainer : Colors.white,
                        checkmarkColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? primaryColor : colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = catValue;
                          });
                          _loadBusinesses();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Header & Counter
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Business Profiles',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colorScheme.onSurface : secondaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${displayedBusinesses.length} Listings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Business Cards Listing
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (displayedBusinesses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Icon(
                          _selectedCategory == 'favorites' ? Icons.favorite_border_rounded : Icons.storefront_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedCategory == 'favorites'
                              ? 'No favorite businesses yet\nपसंदीदा व्यापार अभी तक नहीं जोड़ा गया'
                              : 'No business profiles found',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    const int adFrequency = 7;
                    final int totalAdCount = displayedBusinesses.length >= adFrequency
                        ? (displayedBusinesses.length ~/ adFrequency)
                        : 0;
                    final int totalItemCount = displayedBusinesses.length + totalAdCount;
                    const int modulus = adFrequency + 1;

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalItemCount,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (totalAdCount > 0 && (index + 1) % modulus == 0) {
                          return const AdmobBannerWidget();
                        }

                        final bizIndex = totalAdCount > 0 ? (index - (index ~/ modulus)) : index;
                        final biz = displayedBusinesses[bizIndex];
                        final isFavorited = favorites.contains(biz['id']);
                        final String name = (biz['businessName'] as String? ?? 'Business').toTitleCase();
                        final String category = biz['industryCategory'] ?? 'Other';
                        final String city = biz['city'] ?? '';
                        final String? logoUrl = biz['logoUrl'];
                        final String mobile = biz['contactMobile'] ?? '';
                        final List<dynamic> owners = biz['owners'] ?? [];

                    return Card(
                      margin: EdgeInsets.zero,
                      color: isDark ? colorScheme.surfaceContainer : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: secondaryColor.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          final bp = BusinessProfile.fromJson(biz);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusinessProfileDetailScreen(business: bp),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Business Logo Avatar
                              AppAvatar(
                                name: name,
                                imageUrl: logoUrl,
                                radius: 30,
                                fontSize: 24,
                                border: Border.all(color: primaryColor, width: 1.5),
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            category.toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ),
                                        if (city.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '• $city',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                     if (owners.isNotEmpty) ...[
                                       const SizedBox(height: 4),
                                       Text(
                                         'Owner: ${owners.map((o) => o['fullName']).join(', ')}',
                                         style: GoogleFonts.inter(
                                           fontSize: 11,
                                           color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                         ),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ],
                                     if (mobile.isNotEmpty) ...[
                                       const SizedBox(height: 2),
                                       Text(
                                         'Contact: $mobile',
                                         style: GoogleFonts.inter(
                                           fontSize: 11,
                                           color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                         ),
                                         maxLines: 1,
                                         overflow: TextOverflow.ellipsis,
                                       ),
                                     ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      color: isFavorited ? Colors.red : colorScheme.outlineVariant,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      ref.read(businessFavoritesProvider.notifier).toggleFavorite(biz['id']);
                                    },
                                    tooltip: isFavorited ? 'Remove favorite' : 'Add favorite',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(height: 10),
                                  Icon(
                                    Icons.chevron_right,
                                    color: colorScheme.outlineVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }
}
