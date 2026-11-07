import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_avatar.dart';
import '../../../core/utils/name_formatter.dart';
import 'app_bottom_navigation.dart';
import 'family_member_detail_screen.dart';
import 'family_tree_screen.dart';
import 'my_family_provider.dart';
import 'business_directory_screen.dart';
import 'app_drawer.dart';
import 'ads_provider.dart';
import 'ad_banner_card.dart';
import '../../../core/widgets/admob_banner_widget.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  List<dynamic> _members = [];
  List<dynamic> _villages = [];
  int? _selectedVillageId;
  String? _selectedVillageName;
  String _searchQuery = '';
  Timer? _debounce;
  CancelToken? _cancelToken;
  bool _isFabVisible = true;
  String? _activeLetter;
  Timer? _letterIndicatorTimer;
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  int _totalFamiliesCount = 0;
  int _totalMembersCount = 0;
  Map<int, int> _familyMemberCounts = {};

  List<dynamic> get _displayedMembers {
    if (_searchQuery.trim().isNotEmpty) {
      // Searching: show ALL matching members (heads and non-heads)
      return _members;
    }
    // Default: show ONLY Family Heads
    return _members.where((m) {
      final relationToHead = (m['relationshipToHead'] as String? ?? m['relationToHead'] as String? ?? '').toLowerCase();
      return m['isHead'] == true || relationToHead == 'head' || relationToHead == 'self';
    }).toList();
  }

  String _formatRelationLabel(String relation) {
    switch (relation.toLowerCase()) {
      case 'self':
        return 'Head / मुखिया';
      case 'spouse':
        return 'Spouse / जीवनसाथी';
      case 'father':
        return 'Father / पिता';
      case 'mother':
        return 'Mother / माता';
      case 'grandfather':
      case 'paternal_grandfather':
        return 'Grandfather / दादाजी';
      case 'grandmother':
      case 'paternal_grandmother':
        return 'Grandmother / दादीजी';
      case 'son':
        return 'Son / पुत्र';
      case 'daughter':
        return 'Daughter / पुत्री';
      case 'brother':
        return 'Brother / भाई';
      case 'sister':
        return 'Sister / बहन';
      case 'daughter_in_law':
        return 'Daughter-in-law / पुत्रवधू';
      case 'son_in_law':
        return 'Son-in-law / दामाद';
      case 'grandson':
        return 'Grandson / पौत्र';
      case 'granddaughter':
        return 'Granddaughter / पौत्री';
      default:
        return relation.replaceAll('_', ' ').toTitleCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollToLetter(String letter) {
    setState(() {
      _activeLetter = letter;
    });

    _letterIndicatorTimer?.cancel();
    _letterIndicatorTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _activeLetter = null);
      }
    });

    // Find index of first member starting with letter in currently displayed list
    final targetIndex = _displayedMembers.indexWhere((m) {
      final name = (m['fullName'] as String? ?? '').trim().toUpperCase();
      return name.startsWith(letter);
    });

    if (targetIndex != -1) {
      // Estimated height calculation: Reduced Top Ad slot ~ 126 + headers ~ 200 + item ~ 110
      final displayIndex = targetIndex + (targetIndex ~/ 8);
      final double targetOffset = 325.0 + (displayIndex * 115.0);
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _cancelToken?.cancel('Disposed');
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    ref.invalidate(adsByPlacementProvider('directory_feed'));
    ref.invalidate(myFamilyProvider);
    try {
      final dio = ref.read(apiClientProvider);
      
      // Fetch members and villages in parallel
      final responses = await Future.wait([
        dio.get('/directory/members', queryParameters: {
          if (_searchQuery.isNotEmpty) 'q': _searchQuery,
          if (_selectedVillageId != null) 'villageId': _selectedVillageId,
        }),
        dio.get('/directory/villages'),
      ]);

      if (mounted) {
        final membersList = List<dynamic>.from(responses[0].data['members'] as List<dynamic>);
        final statsData = responses[0].data['stats'] as Map<String, dynamic>?;
        int totalFamilies = statsData?['totalFamilies'] as int? ?? 0;
        int totalMembers = statsData?['totalMembers'] as int? ?? 0;

        if (totalFamilies == 0) {
          totalFamilies = membersList.where((m) {
            final rel = (m['relationshipToHead'] as String? ?? m['relationToHead'] as String? ?? '').toLowerCase();
            return m['isHead'] == true || rel == 'head' || rel == 'self';
          }).length;
          if (totalFamilies == 0) {
            totalFamilies = membersList.map((m) => m['familyId']).toSet().length;
          }
        }
        if (totalMembers == 0) {
          totalMembers = membersList.length;
        }

        final counts = <int, int>{};
        for (final m in membersList) {
          final fId = (m['familyId'] as num?)?.toInt();
          if (fId != null) {
            counts[fId] = (counts[fId] ?? 0) + 1;
          }
        }

        membersList.sort((a, b) {
          final nameA = (a['fullName'] as String? ?? '').toLowerCase();
          final nameB = (b['fullName'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        setState(() {
          _members = membersList;
          _familyMemberCounts = counts;
          _totalFamiliesCount = totalFamilies;
          _totalMembersCount = totalMembers;
          _villages = responses[1].data['villages'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMembersOnly() async {
    _cancelToken?.cancel('New search query');
    _cancelToken = CancelToken();

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get(
        '/directory/members',
        queryParameters: {
          if (_searchQuery.isNotEmpty) 'q': _searchQuery,
          if (_selectedVillageId != null) 'villageId': _selectedVillageId,
        },
        cancelToken: _cancelToken,
      );
      final membersList = List<dynamic>.from(response.data['members'] as List<dynamic>);
      final statsData = response.data['stats'] as Map<String, dynamic>?;
      final totalFamilies = statsData?['totalFamilies'] as int?;
      final totalMembers = statsData?['totalMembers'] as int?;

      final counts = <int, int>{};
      for (final m in membersList) {
        final fId = (m['familyId'] as num?)?.toInt();
        if (fId != null) {
          counts[fId] = (counts[fId] ?? 0) + 1;
        }
      }

      membersList.sort((a, b) {
        final nameA = (a['fullName'] as String? ?? '').toLowerCase();
        final nameB = (b['fullName'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _members = membersList;
          if (_familyMemberCounts.isEmpty || _searchQuery.isEmpty) {
            _familyMemberCounts = counts;
          }
          if (totalFamilies != null && totalFamilies > 0) {
            _totalFamiliesCount = totalFamilies;
          }
          if (totalMembers != null && totalMembers > 0) {
            _totalMembersCount = totalMembers;
          }
        });
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        // Request cancelled by newer search input or reset, safely ignore
        return;
      }
      if (mounted) {
        setState(() {
          _members = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members = [];
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    if (trimmed == _searchQuery) return;

    _debounce?.cancel();

    // If query was cleared, reset immediately without waiting
    if (trimmed.isEmpty) {
      _cancelToken?.cancel('Search cleared');
      setState(() => _searchQuery = '');
      _fetchMembersOnly();
      return;
    }

    // Debounce for 600ms before making API request
    _debounce = Timer(const Duration(milliseconds: 600), () {
      setState(() => _searchQuery = trimmed);
      _fetchMembersOnly();
    });
  }

  void _showVillageFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _VillageFilterDialog(
          villages: _villages,
          selectedVillageId: _selectedVillageId,
          onSelect: (villageId, villageName) {
            setState(() {
              _selectedVillageId = villageId;
              _selectedVillageName = villageName;
            });
            _fetchMembersOnly();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final surfaceColor = colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    final myFamilyAsync = ref.watch(myFamilyProvider);
    final myFamilyData = myFamilyAsync.value;
    final hasFamily = myFamilyData != null && myFamilyData['family'] != null;
    final myFamilyId = hasFamily ? myFamilyData['family']['id'] : null;

    return Scaffold(
      backgroundColor: surfaceColor,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: Icon(Icons.menu, color: primaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
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
            icon: Icon(Icons.notifications_outlined, color: colorScheme.onSurfaceVariant),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: primaryColor),
            onSelected: (value) {
              if (value == 'business_directory') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BusinessDirectoryScreen()),
                );
              } else if (value == 'my_family') {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                ref.read(myFamilyProvider.future).then((myFamilyData) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (myFamilyData != null && myFamilyData['family'] != null) {
                      final familyId = myFamilyData['family']['id'];
                      context.push('/family/$familyId/tree');
                    } else {
                      context.push('/onboard-family');
                    }
                  }
                }).catchError((_) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    context.push('/onboard-family');
                  }
                });
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'business_directory',
                child: Row(
                  children: [
                    Icon(Icons.storefront, color: primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Business Directory / व्यापार निर्देशिका',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'my_family',
                child: Row(
                  children: [
                    Icon(Icons.family_restroom, color: secondaryColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'My Family / मेरा परिवार',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
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
        onRefresh: _loadData,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 28, 20),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner Ad
              const AdmobBannerWidget(margin: EdgeInsets.only(bottom: 12)),

              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
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
                          hintText: 'Search directory...',
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
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: _selectedVillageId != null
                        ? primaryColor
                        : colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _showVillageFilterDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        height: 48,
                        width: 48,
                        child: Icon(
                          Icons.filter_list,
                          color: _selectedVillageId != null
                              ? Colors.white
                              : colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Directory Header Image Banner (Prioritizes directory_header, falls back to directory_feed)
              Consumer(
                builder: (context, ref, _) {
                  final headerAds = ref.watch(adsByPlacementProvider('directory_header')).value ?? [];
                  final feedAds = ref.watch(adsByPlacementProvider('directory_feed')).value ?? [];
                  final adList = headerAds.isNotEmpty ? headerAds : feedAds;
                  if (adList.isEmpty) return const SizedBox.shrink();
                  return AdBannerCarousel(
                    ads: adList,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 16),
                  );
                },
              ),

              // Active filter badge if selected
              if (_selectedVillageId != null) ...[
                Row(
                  children: [
                    InputChip(
                      label: Text(
                        _selectedVillageName ?? 'Village',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedVillageId = null;
                          _selectedVillageName = null;
                        });
                        _fetchMembersOnly();
                      },
                      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.1),
                      deleteIconColor: secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: secondaryColor.withValues(alpha: 0.2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Community Stats Card (Total Families & Total Members)
              _buildCommunityStatsCard(colorScheme, primaryColor, secondaryColor, isDark),

              // Directory Header
              Builder(
                builder: (context) {
                  final displayedList = _displayedMembers;
                  final isSearching = _searchQuery.trim().isNotEmpty;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSearching ? 'Search Results' : 'Family Heads',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                          Text(
                            isSearching ? 'खोज परिणाम' : 'परिवार के मुखिया',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isSearching
                              ? '${displayedList.length} Found'
                              : '${displayedList.length} Families',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Members List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_displayedMembers.isEmpty)
                _buildEmptyState(context, colorScheme, primaryColor, secondaryColor, isDark)
              else
                Builder(
                  builder: (context) {
                    final displayedList = _displayedMembers;
                    final isSearching = _searchQuery.trim().isNotEmpty;
                    final dynamicAds = ref.watch(adsByPlacementProvider('directory_feed')).value ?? [];
                    final bool hasDynamicAds = dynamicAds.isNotEmpty;

                    // Waterfall ad logic: Samaj ads every 4 items; if none, backfill Google AdMob every 7 items
                    final int adFrequency = hasDynamicAds ? 4 : 7;
                    final int totalAdCount = displayedList.length >= adFrequency ? (displayedList.length ~/ adFrequency) : 0;
                    final int totalItemCount = displayedList.length + totalAdCount;
                    final int modulus = adFrequency + 1;

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalItemCount,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Insert ad slot if item index lands on an ad interval
                        if (totalAdCount > 0 && (index + 1) % modulus == 0) {
                          if (hasDynamicAds) {
                            final adIndex = ((index + 1) ~/ modulus - 1) % dynamicAds.length;
                            final ad = dynamicAds[adIndex];
                            return _buildDynamicAdCard(context, ad, primaryColor, secondaryColor, colorScheme);
                          } else {
                            // Backfill with Google AdMob Banner
                            return const AdmobBannerWidget();
                          }
                        }

                        // Member index: calculated cleanly so no item repeats and last item is never hidden
                        final memberIndex = totalAdCount > 0 ? (index - (index ~/ modulus)) : index;
                        final member = displayedList[memberIndex];
                        final String rawName = (member['fullName'] as String? ?? '').toTitleCase();
                        final titleText = rawName;
                        final avatarUrl = member['avatarUrl'] as String?;
                        final relationToHead = (member['relationshipToHead'] as String? ?? member['relationToHead'] as String? ?? '').toUpperCase();
                        final bool isHead = relationToHead == 'HEAD' || relationToHead == 'SELF' || member['isHead'] == true;
                        final familyHeadName = (member['familyHeadName'] as String? ?? '').toTitleCase();
                        final gotra = member['gotra'] as String?;
                        final occupation = member['occupationType'] as String?;
                        final int fId = (member['familyId'] as num?)?.toInt() ?? -1;
                        final int memberCount = (member['familyMemberCount'] as num?)?.toInt() ?? _familyMemberCounts[fId] ?? 1;

                        return Card(
                          margin: EdgeInsets.zero,
                          color: isHead 
                              ? (isDark ? colorScheme.surfaceContainerHigh : const Color(0xFFFFFDF5)) 
                              : (isDark ? colorScheme.surfaceContainer : Colors.white),
                          elevation: isHead ? 1 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isHead 
                                  ? const Color(0xFFD4AF37) 
                                  : secondaryColor.withValues(alpha: 0.08),
                              width: isHead ? 1.5 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _onMemberTap(member),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // Avatar
                                  AppAvatar(
                                    name: rawName,
                                    imageUrl: avatarUrl,
                                    radius: 28,
                                    border: Border.all(
                                      color: isHead ? const Color(0xFFD4AF37) : primaryColor, 
                                      width: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                titleText,
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isHead && isSearching) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFB8860B).withValues(alpha: 0.3),
                                                      blurRadius: 3,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.workspace_premium,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Family Head / मुखिया',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        // Family Head Member Count Badge Row
                                        if (isHead) ...[
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? colorScheme.surfaceContainerHighest
                                                      : const Color(0xFFFFF6E5),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.groups_rounded,
                                                      size: 13,
                                                      color: Color(0xFFB8860B),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '$memberCount सदस्य',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: isDark ? colorScheme.onSurface : const Color(0xFF8B5A00),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                        ] else ...[
                                          const SizedBox(height: 4),
                                        ],

                                        // Family Head Name Row (if not self head)
                                        if (!isHead && familyHeadName.isNotEmpty) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.family_restroom_rounded,
                                                size: 13,
                                                color: isDark ? colorScheme.primary : secondaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Head: $familyHeadName • ${_formatRelationLabel(relationToHead)}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? colorScheme.primary : secondaryColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                        ],

                                        // Occupation & Gotra / Details Row
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            // Prominent Occupation Tag
                                            if (occupation != null && occupation.isNotEmpty && occupation != 'N/A')
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: primaryColor.withValues(alpha: 0.2),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.work_outline_rounded,
                                                      size: 11,
                                                      color: primaryColor,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      occupation,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: primaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Gotra Chip
                                            if (gotra != null && gotra.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Gotra: $gotra',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.outlineVariant,
                                    size: 22,
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

        // ── Right Side A-Z Fast Scroll Sidebar ─────────────────
        if (!_isLoading && _displayedMembers.isNotEmpty)
          Positioned(
            right: 2,
            top: 20,
            bottom: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(-1, 1),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _alphabet.map((letter) {
                      final bool isAvailable = _displayedMembers.any((m) {
                        final name = (m['fullName'] as String? ?? '').trim().toUpperCase();
                        return name.startsWith(letter);
                      });

                      return InkWell(
                        onTap: isAvailable ? () => _scrollToLetter(letter) : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5, horizontal: 3),
                          child: Text(
                            letter,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: _activeLetter == letter ? FontWeight.bold : FontWeight.w600,
                              color: isAvailable
                                  ? (_activeLetter == letter ? secondaryColor : primaryColor)
                                  : Colors.black26,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),

        // ── Floating Letter Indicator Bubble ────────────────────
        if (_activeLetter != null)
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _activeLetter!,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  ),
  floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () {
              if (hasFamily && myFamilyId != null) {
                context.push('/family/$myFamilyId/tree');
              } else {
                context.push('/onboard-family');
              }
            },
            backgroundColor: primaryColor,
            icon: Icon(hasFamily ? Icons.account_tree : Icons.add, color: Colors.white),
            label: Text(
              hasFamily ? 'View My Family' : 'Add New Family',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildCommunityStatsCard(ColorScheme colorScheme, Color primaryColor, Color secondaryColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFDF5), Color(0xFFFBF4E4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Families
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_totalFamiliesCount',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2C1D11),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'कुल परिवार',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.primary : secondaryColor,
                        ),
                      ),
                      Text(
                        'Registered Families',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          ),

          // Total Members
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB8860B), Color(0xFFDAA520)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8860B).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_totalMembersCount',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2C1D11),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'कुल सदस्य',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? colorScheme.primary : secondaryColor,
                        ),
                      ),
                      Text(
                        'Total Population',
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicAdCard(BuildContext context, AdvertisementModel ad, Color primaryColor, Color secondaryColor, ColorScheme colorScheme) {
    return AdBannerCard(
      ad: ad,
      height: 120,
      margin: EdgeInsets.zero,
    );
  }

  Future<void> _onMemberTap(Map<String, dynamic> member) async {
    final familyId = member['familyId'] as int;
    final memberId = member['id'] as int;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tree = await ref.read(familyTreeProvider(familyId).future);
      if (!mounted) return;
      Navigator.pop(context); // close loader

      final targetMemberNode = tree.members.firstWhere((m) => m.id == memberId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyMemberDetailScreen(
            member: targetMemberNode,
            familyMembers: tree.members,
            familyId: familyId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    Color primaryColor,
    Color secondaryColor,
    bool isDark,
  ) {
    final bool hasFilter = _searchQuery.isNotEmpty || _selectedVillageId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                hasFilter ? Icons.person_search_rounded : Icons.group_off_rounded,
                size: 56,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter ? 'No Members Found / कोई सदस्य नहीं मिला' : 'Directory is Empty / निर्देशिका खाली है',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'We couldn\'t find any members matching your search or village filter. Try searching for a different name or clearing filters.\nआपके सर्च या गांव फ़िल्टर से कोई सदस्य नहीं मिला।'
                  : 'No registered members found in the directory yet. Check back soon or pull down to refresh!\nनिर्देशिका में अभी तक कोई पंजीकृत सदस्य नहीं है।',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilter)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedVillageId = null;
                    _selectedVillageName = null;
                  });
                  _fetchMembersOnly();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(
                  'Clear Filters / फ़िल्टर हटाएं',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Refresh / रिफ्रेश करें',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VillageFilterDialog extends StatefulWidget {
  final List<dynamic> villages;
  final int? selectedVillageId;
  final Function(int?, String?) onSelect;

  const _VillageFilterDialog({
    required this.villages,
    required this.selectedVillageId,
    required this.onSelect,
  });

  @override
  State<_VillageFilterDialog> createState() => _VillageFilterDialogState();
}

class _VillageFilterDialogState extends State<_VillageFilterDialog> {
  final TextEditingController _dialogSearchController = TextEditingController();
  String _villageSearchQuery = '';

  @override
  void dispose() {
    _dialogSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredVillages = widget.villages.where((v) {
      final name = (v['name'] as String).toLowerCase();
      return name.contains(_villageSearchQuery.toLowerCase());
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Select Native Village',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dialogSearchController,
                onChanged: (val) => setState(() => _villageSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search village...',
                  hintStyle: GoogleFonts.inter(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredVillages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        title: Text(
                          'All Villages',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        selected: widget.selectedVillageId == null,
                        onTap: () {
                          widget.onSelect(null, null);
                          Navigator.pop(context);
                        },
                      );
                    }
                    final village = filteredVillages[index - 1];
                    final villageId = village['id'] as int;
                    final villageName = village['name'] as String;

                    return ListTile(
                      title: Text(
                        villageName,
                        style: GoogleFonts.inter(),
                      ),
                      selected: widget.selectedVillageId == villageId,
                      onTap: () {
                        widget.onSelect(villageId, villageName);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
