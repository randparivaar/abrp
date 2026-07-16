import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import 'app_bottom_navigation.dart';
import 'family_member_detail_screen.dart';
import 'family_tree_screen.dart';

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
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
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
        setState(() {
          _members = responses[0].data['members'] as List<dynamic>;
          _villages = responses[1].data['villages'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load directory: $e')),
        );
      }
    }
  }

  Future<void> _fetchMembersOnly() async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/members', queryParameters: {
        if (_searchQuery.isNotEmpty) 'q': _searchQuery,
        if (_selectedVillageId != null) 'villageId': _selectedVillageId,
      });
      if (mounted) {
        setState(() {
          _members = response.data['members'] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to filter: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
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
    final primaryColor = const Color(0xFF795900);
    final secondaryColor = const Color(0xFFB22B1D);
    final surfaceColor = const Color(0xFFFBF9F8);

    return Scaffold(
      backgroundColor: surfaceColor,
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
          'Rander Parivar Samaj',
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
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
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

              // Promoted Ad Slot
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening sponsored business profile...')),
                  );
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background Image
                        Image.network(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuAT_FlZ8APgvqD4JePAdhJAyL4n2qjRXl5M496NUtWMjnGRmYQCHVmxv1JMCwDX-FRMz5c-MjOk87NJvmiW1dW7W-K3T0IZHl5rBwYfHWrTeM3MopGIPBkNufObl6sXJSKpcr8-k47XHWrsxg3bt5kP2Q8VAi8t6hbP1TgH8ybEEYTN8nKLtiVBgWqqOZIGBn2bvIZeus9MoaaS7OJmdMw3OII_gcRZIG0Fb-bHUWzV3Nbqo48_y1kMmJUb2o6QNJK99zLQtz1aJv0',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => Container(
                            color: primaryColor.withValues(alpha: 0.2),
                            child: Icon(Icons.storefront, color: primaryColor, size: 48),
                          ),
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        // Ad content
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SPONSORED',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Promoted Business: Shree Ganesh Textiles - Visit Us!',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Directory Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Members',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_members.length} Members',
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

              // Members List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_members.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No members found',
                      style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final village = member['village']?['name'] as String?;
                    final titleText = village != null
                        ? '${member['fullName']} ($village)'
                        : member['fullName'];
                    final avatarUrl = member['avatarUrl'] as String?;
                    final familyCode = member['familyCode'] as String;
                    
                    return Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: secondaryColor.withValues(alpha: 0.05),
                          width: 1,
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
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor,
                                    width: 2,
                                  ),
                                  image: avatarUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(avatarUrl),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: avatarUrl == null
                                    ? Icon(
                                        Icons.person,
                                        color: primaryColor,
                                        size: 28,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Occupation: ${member['occupationType'] ?? 'N/A'} | Family ID: $familyCode',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right,
                                color: colorScheme.outlineVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
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
              context.push('/onboard-family');
            },
            backgroundColor: primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add New Family',
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
