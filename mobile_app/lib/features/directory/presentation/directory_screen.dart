import 'dart:async';
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
  String? _activeLetter;
  Timer? _letterIndicatorTimer;
  final List<String> _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  static const List<Map<String, dynamic>> _dummyAds = [
    {
      'title': 'Shree Ganesh Textiles',
      'category': 'Textiles & Garments',
      'tagline': 'Special 15% discount for community members!',
      'imageUrl': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAT_FlZ8APgvqD4JePAdhJAyL4n2qjRXl5M496NUtWMjnGRmYQCHVmxv1JMCwDX-FRMz5c-MjOk87NJvmiW1dW7W-K3T0IZHl5rBwYfHWrTeM3MopGIPBkNufObl6sXJSKpcr8-k47XHWrsxg3bt5kP2Q8VAi8t6hbP1TgH8ybEEYTN8nKLtiVBgWqqOZIGBn2bvIZeus9MoaaS7OJmdMw3OII_gcRZIG0Fb-bHUWzV3Nbqo48_y1kMmJUb2o6QNJK99zLQtz1aJv0',
      'location': 'Surat, Gujarat',
    },
    {
      'title': 'Apex Healthcare & Clinic',
      'category': 'Healthcare & Medical',
      'tagline': 'Free Health Checkup & Consultation',
      'imageUrl': null,
      'location': 'Ahmedabad',
    },
    {
      'title': 'Vardhman Jewellers',
      'category': 'Gold & Diamond',
      'tagline': 'Zero Making Charges on Bridal Collection',
      'imageUrl': null,
      'location': 'Mumbai',
    },
    {
      'title': 'Rajdhani Caterers & Sweets',
      'category': 'Food & Hospitality',
      'tagline': 'Authentic Rajasthani & Gujarati Thali',
      'imageUrl': null,
      'location': 'Jaipur',
    },
  ];

  static const List<Map<String, dynamic>> _dummyMembers = [
    {
      'id': 101,
      'familyId': 1,
      'fullName': 'Rameshchandra J. Shah',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Kashyap',
      'occupationType': 'Business',
      'avatarUrl': null,
    },
    {
      'id': 102,
      'familyId': 1,
      'fullName': 'Savitaben R. Shah',
      'relationshipToHead': 'SPOUSE',
      'familyHeadName': 'Rameshchandra J. Shah',
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Kashyap',
      'occupationType': 'Homemaker',
      'avatarUrl': null,
    },
    {
      'id': 103,
      'familyId': 1,
      'fullName': 'Amitkumar R. Shah',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Rameshchandra J. Shah',
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Kashyap',
      'occupationType': 'IT Professional',
      'avatarUrl': null,
    },
    {
      'id': 104,
      'familyId': 1,
      'fullName': 'Neha A. Shah',
      'relationshipToHead': 'DAUGHTER_IN_LAW',
      'familyHeadName': 'Rameshchandra J. Shah',
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Vashishtha',
      'occupationType': 'Architect',
      'avatarUrl': null,
    },
    {
      'id': 105,
      'familyId': 2,
      'fullName': 'Bharatbhai M. Patel',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 2, 'name': 'Unjha'},
      'gotra': 'Garg',
      'occupationType': 'Agriculture & Trade',
      'avatarUrl': null,
    },
    {
      'id': 106,
      'familyId': 2,
      'fullName': 'Chirag B. Patel',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Bharatbhai M. Patel',
      'village': {'id': 2, 'name': 'Unjha'},
      'gotra': 'Garg',
      'occupationType': 'Chartered Accountant',
      'avatarUrl': null,
    },
    {
      'id': 107,
      'familyId': 3,
      'fullName': 'Dineshbhai K. Mehta',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 3, 'name': 'Siddhpur'},
      'gotra': 'Bharadwaj',
      'occupationType': 'Jewellery Business',
      'avatarUrl': null,
    },
    {
      'id': 108,
      'familyId': 3,
      'fullName': 'Deepak D. Mehta',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Dineshbhai K. Mehta',
      'village': {'id': 3, 'name': 'Siddhpur'},
      'gotra': 'Bharadwaj',
      'occupationType': 'Salaried Job',
      'avatarUrl': null,
    },
    {
      'id': 109,
      'familyId': 4,
      'fullName': 'Girishbhai S. Parikh',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 4, 'name': 'Visnagar'},
      'gotra': 'Vatsa',
      'occupationType': 'Textile Trading',
      'avatarUrl': null,
    },
    {
      'id': 110,
      'familyId': 4,
      'fullName': 'Hetal G. Parikh',
      'relationshipToHead': 'DAUGHTER',
      'familyHeadName': 'Girishbhai S. Parikh',
      'village': {'id': 4, 'name': 'Visnagar'},
      'gotra': 'Vatsa',
      'occupationType': 'Doctor',
      'avatarUrl': null,
    },
    {
      'id': 111,
      'familyId': 5,
      'fullName': 'Jitendrabhai V. Modi',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 5, 'name': 'Vadnagar'},
      'gotra': 'Shandilya',
      'occupationType': 'Retail Store',
      'avatarUrl': null,
    },
    {
      'id': 112,
      'familyId': 5,
      'fullName': 'Kiran J. Modi',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Jitendrabhai V. Modi',
      'village': {'id': 5, 'name': 'Vadnagar'},
      'gotra': 'Shandilya',
      'occupationType': 'Software Engineer',
      'avatarUrl': null,
    },
    {
      'id': 113,
      'familyId': 6,
      'fullName': 'Maheshbhai P. Shroff',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Parashar',
      'occupationType': 'Financial Advisor',
      'avatarUrl': null,
    },
    {
      'id': 114,
      'familyId': 6,
      'fullName': 'Nitin M. Shroff',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Maheshbhai P. Shroff',
      'village': {'id': 1, 'name': 'Patan'},
      'gotra': 'Parashar',
      'occupationType': 'Civil Engineer',
      'avatarUrl': null,
    },
    {
      'id': 115,
      'familyId': 7,
      'fullName': 'Pankajbhai L. Gandhi',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 6, 'name': 'Kadi'},
      'gotra': 'Agastya',
      'occupationType': 'Chemical Industry',
      'avatarUrl': null,
    },
    {
      'id': 116,
      'familyId': 7,
      'fullName': 'Pooja P. Gandhi',
      'relationshipToHead': 'DAUGHTER',
      'familyHeadName': 'Pankajbhai L. Gandhi',
      'village': {'id': 6, 'name': 'Kadi'},
      'gotra': 'Agastya',
      'occupationType': 'Professor',
      'avatarUrl': null,
    },
    {
      'id': 117,
      'familyId': 8,
      'fullName': 'Rajeshbhai T. Choksi',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 2, 'name': 'Unjha'},
      'gotra': 'Kashyap',
      'occupationType': 'Real Estate',
      'avatarUrl': null,
    },
    {
      'id': 118,
      'familyId': 8,
      'fullName': 'Sanjay R. Choksi',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Rajeshbhai T. Choksi',
      'village': {'id': 2, 'name': 'Unjha'},
      'gotra': 'Kashyap',
      'occupationType': 'Business',
      'avatarUrl': null,
    },
    {
      'id': 119,
      'familyId': 9,
      'fullName': 'Tusharbhai H. Vora',
      'relationshipToHead': 'HEAD',
      'isHead': true,
      'village': {'id': 3, 'name': 'Siddhpur'},
      'gotra': 'Garg',
      'occupationType': 'Pharmaceuticals',
      'avatarUrl': null,
    },
    {
      'id': 120,
      'familyId': 9,
      'fullName': 'Vipul T. Vora',
      'relationshipToHead': 'SON',
      'familyHeadName': 'Tusharbhai H. Vora',
      'village': {'id': 3, 'name': 'Siddhpur'},
      'gotra': 'Garg',
      'occupationType': 'Consultant',
      'avatarUrl': null,
    },
  ];

  List<dynamic> _filterDummyMembers() {
    return _dummyMembers.where((m) {
      if (_searchQuery.isNotEmpty) {
        final name = (m['fullName'] as String? ?? '').toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      if (_selectedVillageId != null) {
        final vId = m['village']?['id'] as int?;
        if (vId != _selectedVillageId) return false;
      }
      return true;
    }).toList();
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

    // Find index of first member starting with letter
    final targetIndex = _members.indexWhere((m) {
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
        final membersList = List<dynamic>.from(responses[0].data['members'] as List<dynamic>);
        membersList.sort((a, b) {
          final nameA = (a['fullName'] as String? ?? '').toLowerCase();
          final nameB = (b['fullName'] as String? ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        setState(() {
          _members = membersList.isNotEmpty ? membersList : _filterDummyMembers();
          _villages = responses[1].data['villages'] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members = _filterDummyMembers();
          _isLoading = false;
        });
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
      final membersList = List<dynamic>.from(response.data['members'] as List<dynamic>);
      membersList.sort((a, b) {
        final nameA = (a['fullName'] as String? ?? '').toLowerCase();
        final nameB = (b['fullName'] as String? ?? '').toLowerCase();
        return nameA.compareTo(nameB);
      });

      if (mounted) {
        setState(() {
          _members = membersList.isNotEmpty ? membersList : _filterDummyMembers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _members = _filterDummyMembers();
        });
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

              // Promoted Ad Slot (Reduced by 30%: height 126 instead of 180)
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening sponsored business profile...')),
                  );
                },
                child: Container(
                  height: 126,
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
                            child: Icon(Icons.storefront, color: primaryColor, size: 36),
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
                                Colors.black.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),
                        // Ad content
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
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
                              const SizedBox(height: 4),
                              Text(
                                'Promoted Business: Shree Ganesh Textiles - Visit Us!',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                Builder(
                  builder: (context) {
                    final int totalAdCount = _members.length ~/ 8;
                    final int totalItemCount = _members.length + totalAdCount;

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: totalItemCount,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        // Insert Ad after every 8 members (at positions index 8, 17, 26...)
                        if ((index + 1) % 9 == 0) {
                          final adIndex = ((index + 1) ~/ 9 - 1) % _dummyAds.length;
                          final ad = _dummyAds[adIndex];
                          return _buildAdMemberCard(context, ad, primaryColor, secondaryColor, colorScheme);
                        }

                        final memberIndex = index - (index ~/ 9);
                        final member = _members[memberIndex];
                        final String rawName = (member['fullName'] as String? ?? '').toTitleCase();
                        final village = member['village']?['name'] as String?;
                        final titleText = village != null
                            ? '$rawName ($village)'
                            : rawName;
                        final avatarUrl = member['avatarUrl'] as String?;
                        final relationToHead = (member['relationshipToHead'] as String? ?? member['relationToHead'] as String? ?? '').toUpperCase();
                        final bool isHead = relationToHead == 'HEAD' || relationToHead == 'SELF' || member['isHead'] == true;
                        final familyHeadName = (member['familyHeadName'] as String? ?? '').toTitleCase();
                        final gotra = member['gotra'] as String?;
                        final occupation = member['occupationType'] as String?;

                        return Card(
                          margin: EdgeInsets.zero,
                          color: isHead ? const Color(0xFFFFFDF5) : Colors.white,
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
                                  // Avatar with Hero Animation for smooth page transitions
                                  Hero(
                                    tag: 'avatar_${member['id']}',
                                    child: AppAvatar(
                                      name: rawName,
                                      imageUrl: avatarUrl,
                                      radius: 28,
                                      border: Border.all(
                                        color: isHead ? const Color(0xFFD4AF37) : primaryColor, 
                                        width: 2,
                                      ),
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
                                            if (isHead) ...[
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
                                                      'Family Head',
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
                                        const SizedBox(height: 4),

                                        // Family Head Name Row (if not self head)
                                        if (!isHead && familyHeadName.isNotEmpty) ...[
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.family_restroom_rounded,
                                                size: 13,
                                                color: secondaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Head: $familyHeadName',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: secondaryColor,
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
        if (!_isLoading && _members.isNotEmpty)
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
                      final bool isAvailable = _members.any((m) {
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

  Widget _buildAdMemberCard(
    BuildContext context,
    Map<String, dynamic> ad,
    Color primaryColor,
    Color secondaryColor,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFFBEF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${ad['title']}...')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar format (same 56x56 circle as AppAvatar radius 28)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                  border: Border.all(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: ad['imageUrl'] != null && (ad['imageUrl'] as String).isNotEmpty
                      ? Image.network(
                          ad['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.storefront_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        )
                      : Icon(
                          Icons.storefront_rounded,
                          color: primaryColor,
                          size: 26,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ad['title'] ?? 'Sponsored Business',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AD',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ad['tagline'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                                Icons.campaign_outlined,
                                size: 11,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                ad['category'] ?? 'Sponsored',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (ad['location'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ad['location']!,
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
                Icons.open_in_new_rounded,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
