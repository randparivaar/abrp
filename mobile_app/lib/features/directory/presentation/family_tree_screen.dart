import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/directory/presentation/add_member_dialog.dart';
import 'package:mobile_app/features/directory/presentation/app_bottom_navigation.dart';
import 'package:mobile_app/features/directory/presentation/family_member_detail_screen.dart';

// Tree Node Model
class BusinessProfile {
  final int id;
  final String businessName;
  final String? logoUrl;
  final String industryCategory;
  final String contactMobile;
  final String? whatsappMobile;
  final String? email;
  final String? websiteUrl;
  final String? gstin;
  final String? description;
  final List<String>? tags;
  final Map<String, dynamic>? operatingHours;
  final Map<String, dynamic>? communityPerk;
  final List<dynamic>? catalog;
  final String address;
  final String city;
  final String? state;
  final String? pincode;
  final String? googleMapsLink;

  BusinessProfile({
    required this.id,
    required this.businessName,
    this.logoUrl,
    required this.industryCategory,
    required this.contactMobile,
    this.whatsappMobile,
    this.email,
    this.websiteUrl,
    this.gstin,
    this.description,
    this.tags,
    this.operatingHours,
    this.communityPerk,
    this.catalog,
    required this.address,
    required this.city,
    this.state,
    this.pincode,
    this.googleMapsLink,
  });

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] as int,
      businessName: json['businessName'] as String,
      logoUrl: json['logoUrl'] as String?,
      industryCategory: json['industryCategory'] as String,
      contactMobile: json['contactMobile'] as String,
      whatsappMobile: json['whatsappMobile'] as String?,
      email: json['email'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      gstin: json['gstin'] as String?,
      description: json['description'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      operatingHours: json['operatingHours'] as Map<String, dynamic>?,
      communityPerk: json['communityPerk'] as Map<String, dynamic>?,
      catalog: json['catalog'] as List<dynamic>?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      googleMapsLink: json['googleMapsLink'] as String?,
    );
  }
}

class MemberNode {
  final int id;
  final int familyId;
  final String fullName;
  final String gender;
  final String relationshipToHead;
  final String? mobile;
  final String? gotra;
  final int? estimatedAgeOnCreation;
  final DateTime? birthDate;
  final String? education;
  final String? occupationType;
  final String? occupationDetail;
  final int? yearlyIncome;
  final int? fatherId;
  final int? motherId;
  final int? spouseId;
  final String? status; // 'pending' | 'approved'
  final String? bloodGroup;
  final String? maritalStatus;
  final DateTime? anniversaryDate;
  final String? currentAddress;
  final String? currentCity;
  final String? currentState;
  final String? currentPincode;
  final BusinessProfile? businessProfile;
  final String? avatarUrl;
  final String? aadhaarNo;
  final String? specialRemarks;

  MemberNode({
    required this.id,
    required this.familyId,
    required this.fullName,
    required this.gender,
    required this.relationshipToHead,
    this.mobile,
    this.gotra,
    this.estimatedAgeOnCreation,
    this.birthDate,
    this.education,
    this.occupationType,
    this.occupationDetail,
    this.yearlyIncome,
    this.fatherId,
    this.motherId,
    this.spouseId,
    this.status,
    this.bloodGroup,
    this.maritalStatus,
    this.anniversaryDate,
    this.currentAddress,
    this.currentCity,
    this.currentState,
    this.currentPincode,
    this.businessProfile,
    this.avatarUrl,
    this.aadhaarNo,
    this.specialRemarks,
  });

  factory MemberNode.fromJson(Map<String, dynamic> json) {
    return MemberNode(
      id: json['id'] as int,
      familyId: json['familyId'] as int,
      fullName: json['fullName'] as String,
      gender: json['gender'] as String,
      relationshipToHead: json['relationshipToHead'] as String,
      mobile: json['mobile'] as String?,
      gotra: json['gotra'] as String?,
      estimatedAgeOnCreation: json['estimatedAgeOnCreation'] as int?,
      birthDate: json['birthDate'] != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      education: json['education'] as String?,
      occupationType: json['occupationType'] as String?,
      occupationDetail: json['occupationDetail'] as String?,
      yearlyIncome: json['yearlyIncome'] as int?,
      fatherId: json['fatherId'] as int?,
      motherId: json['motherId'] as int?,
      spouseId: json['spouseId'] as int?,
      status: json['status'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      maritalStatus: json['maritalStatus'] as String?,
      anniversaryDate: json['anniversaryDate'] != null ? DateTime.tryParse(json['anniversaryDate'] as String) : null,
      currentAddress: json['currentAddress'] as String?,
      currentCity: json['currentCity'] as String?,
      currentState: json['currentState'] as String?,
      currentPincode: json['currentPincode'] as String?,
      businessProfile: json['businessProfile'] != null 
          ? BusinessProfile.fromJson(json['businessProfile'] as Map<String, dynamic>)
          : null,
      avatarUrl: json['avatarUrl'] as String?,
      aadhaarNo: json['aadhaarNo'] as String?,
      specialRemarks: json['specialRemarks'] as String?,
    );
  }

  int get age {
    if (birthDate != null) {
      return DateTime.now().year - birthDate!.year;
    }
    return estimatedAgeOnCreation ?? 0;
  }
}

class FamilyUnit {
  final int id;
  final String familyCode;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final String villageName;
  final String regionName;

  FamilyUnit({
    required this.id,
    required this.familyCode,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.villageName,
    required this.regionName,
  });

  factory FamilyUnit.fromJson(Map<String, dynamic> json) {
    return FamilyUnit(
      id: json['id'] as int,
      familyCode: json['familyCode'] as String,
      address: json['address'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      villageName: (json['village']?['name'] ?? '') as String,
      regionName: (json['village']?['region']?['name'] ?? '') as String,
    );
  }
}

class FamilyTreeData {
  final FamilyUnit family;
  final List<MemberNode> members;

  FamilyTreeData({required this.family, required this.members});
}

class FamilyTreeNotifier extends AsyncNotifier<FamilyTreeData> {
  final int familyId;

  FamilyTreeNotifier(this.familyId);

  @override
  Future<FamilyTreeData> build() async {
    return _fetchTree();
  }

  Future<FamilyTreeData> _fetchTree() async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/directory/family/$familyId/tree');
    final data = response.data;

    final family = FamilyUnit.fromJson(data['family']);
    final list = data['members'] as List<dynamic>;
    final members = list.map((json) => MemberNode.fromJson(json)).toList();

    return FamilyTreeData(family: family, members: members);
  }

  Future<void> fetchTree() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTree());
  }
}

final familyTreeProvider =
    AsyncNotifierProvider.family<FamilyTreeNotifier, FamilyTreeData, int>(
  (familyId) => FamilyTreeNotifier(familyId),
);

class FamilyTreeScreen extends ConsumerStatefulWidget {
  final int familyId;
  const FamilyTreeScreen({super.key, required this.familyId});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(familyTreeProvider(widget.familyId));
    final family = treeAsync.value?.family;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: treeAsync.when(
          data: (data) {
            final head = data.members.firstWhere(
              (m) => m.relationshipToHead == 'self',
              orElse: () => data.members.first,
            );
            final nameParts = head.fullName.trim().split(' ');
            final lineageName = nameParts.length > 1 ? nameParts.last : 'Family';
            return Text(
              'Our Family Tree ($lineageName Lineage)',
              style: GoogleFonts.inter(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            );
          },
          loading: () => Text('Loading...', style: TextStyle(color: theme.colorScheme.primary)),
          error: (_, _) => Text('Error', style: TextStyle(color: theme.colorScheme.primary)),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.primary, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 16),
            ),
          )
        ],
      ),
      body: treeAsync.when(
        data: (data) => _buildTreeContent(context, data, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Failed to load tree: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMemberDialog(
                familyId: widget.familyId,
                defaultRelation: 'son',
                defaultAddress: family?.address,
                defaultCity: family?.city,
                defaultState: family?.state,
                defaultPincode: family?.pincode,
                onMemberAdded: () {
                  ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                },
              ),
              fullscreenDialog: true,
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildTreeContent(BuildContext context, FamilyTreeData data, ThemeData theme) {
    // Find the Family Head (relationshipToHead == 'self')
    final head = data.members.firstWhere(
      (m) => m.relationshipToHead == 'self',
      orElse: () => data.members.first,
    );

    // Find Head's spouse if exists
    final spouse = data.members.firstWhere(
      (m) => m.spouseId == head.id || (head.spouseId != null && m.id == head.spouseId),
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    final hasSpouse = spouse.id != -1;

    // Find Head's children
    final children = data.members.where(
      (m) => m.fatherId == head.id || (hasSpouse && m.motherId == spouse.id) || m.relationshipToHead == 'son' || m.relationshipToHead == 'daughter',
    ).toList();

    // Filter children based on search query
    final filteredChildren = children.where((child) {
      if (_searchQuery.isEmpty) return true;
      return child.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search family members...',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Head Node Card
          _buildHeadNodeCard(
            context: context,
            member: head,
            roleLabel: 'FAMILY HEAD • ${data.family.city?.toUpperCase() ?? 'DELHI'}',
            theme: theme,
          ),

          _buildVerticalLine(theme),

          // Spouse Node Card or Placeholder
          _buildSpouseNodeCard(
            context: context,
            member: spouse,
            isPlaceholder: !hasSpouse,
            defaultSpouseId: head.id,
            theme: theme,
            family: data.family,
          ),

          // Children Generation Layer
          if (filteredChildren.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom paint connector for child nodes with 80px vertical spacing (48px top-drop, 32px bottom-drop) and 4px elbow joints
                        CustomPaint(
                          size: Size(filteredChildren.length * 100.0, 80.0),
                          painter: ConnectorPainter(
                            childCount: filteredChildren.length,
                            color: theme.colorScheme.primaryContainer,
                          ),
                        ),
                        // Row of children avatar nodes (width 100 per child for proper spacing)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filteredChildren.map((child) {
                            return SizedBox(
                              width: 100,
                              child: _buildChildAvatarNode(context, child, theme),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ] else if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'No family members match your search.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                'No children added yet.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildVerticalLine(ThemeData theme) {
    return Center(
      child: Container(
        width: 2,
        height: 32, // Matches tree-connector-vertical (32px)
        color: theme.colorScheme.primaryContainer, // Primary container (gold) for connectors
      ),
    );
  }

  Widget _buildHeadNodeCard({
    required BuildContext context,
    required MemberNode member,
    required String roleLabel,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: GestureDetector(
        onTap: () => _showMemberActionSheet(context, member),
        child: Container(
          width: 256,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest, // bg-surface-container-lowest
            borderRadius: BorderRadius.circular(12), // rounded-xl
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
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4.0,
                    color: colorScheme.primary, // border-l-4 border-primary
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.primary, width: 2.0),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: member.gender == 'male' ? Colors.blue.shade50 : Colors.pink.shade50,
                              backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                                  ? NetworkImage(member.avatarUrl!)
                                  : null,
                              child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                                  ? null
                                  : Icon(
                                      member.gender == 'male' ? Icons.face : Icons.face_3,
                                      color: member.gender == 'male' ? Colors.blue.shade400 : Colors.pink.shade400,
                                      size: 28,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              member.fullName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16, // title-md
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              roleLabel,
                              style: GoogleFonts.inter(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 11, // label-sm
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
    );
  }

  Widget _buildSpouseNodeCard({
    required BuildContext context,
    required MemberNode member,
    required bool isPlaceholder,
    int? defaultSpouseId,
    required ThemeData theme,
    required FamilyUnit family,
  }) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: GestureDetector(
        onTap: () {
          if (isPlaceholder) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMemberDialog(
                  familyId: widget.familyId,
                  defaultRelation: 'spouse',
                  defaultGender: 'female',
                  spouseId: defaultSpouseId,
                  defaultAddress: family.address,
                  defaultCity: family.city,
                  defaultState: family.state,
                  defaultPincode: family.pincode,
                  onMemberAdded: () {
                    ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                  },
                ),
                fullscreenDialog: true,
              ),
            );
          } else {
            _showMemberActionSheet(context, member);
          }
        },
        child: Container(
          width: 192, // w-48
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest, // bg-white
            borderRadius: BorderRadius.circular(8), // rounded-lg
            border: Border.all(
              color: colorScheme.secondary.withValues(alpha: 0.3), // border-secondary/30
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(1.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.secondary.withValues(alpha: 0.4), // border-secondary/40
                        width: 1.0,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20, // w-10
                      backgroundColor: isPlaceholder
                          ? colorScheme.surfaceContainerLow
                          : (member.gender == 'male' ? Colors.blue.shade50 : Colors.pink.shade50),
                      backgroundImage: !isPlaceholder && member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? NetworkImage(member.avatarUrl!)
                          : null,
                      child: !isPlaceholder && member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? null
                          : Icon(
                              isPlaceholder
                                  ? Icons.person_add_alt_1_outlined
                                  : (member.gender == 'male' ? Icons.face : Icons.face_3),
                              color: isPlaceholder
                                  ? colorScheme.onSurfaceVariant
                                  : (member.gender == 'male' ? Colors.blue.shade400 : Colors.pink.shade400),
                              size: 20,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.0),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPlaceholder ? 'Spouse' : member.fullName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPlaceholder ? 'Self/Spouse' : 'SPOUSE',
                      style: GoogleFonts.inter(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                        fontSize: 11, // label-sm
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChildAvatarNode(
    BuildContext context, 
    MemberNode member, 
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final isMale = member.gender == 'male';

    return GestureDetector(
      onTap: () => _showMemberActionSheet(context, member),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primaryContainer, // border-primary-container
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30, // w-16
                  backgroundColor: isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                  backgroundImage: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                      ? null
                      : Icon(
                          isMale ? Icons.face : Icons.face_3,
                          color: isMale ? Colors.blue.shade400 : Colors.pink.shade400,
                          size: 32,
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24, // w-6
                  height: 24, // h-6
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: colorScheme.onPrimaryContainer,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            member.fullName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14, // text-body-md
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMemberActionSheet(BuildContext context, MemberNode member) {
    final theme = Theme.of(context);
    final family = ref.read(familyTreeProvider(widget.familyId)).value?.family;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  member.fullName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Relationship: ${member.relationshipToHead.toUpperCase()}',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: Text(
                    'View Member Details / विवरण देखें',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMemberDetailsDialog(context, member);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.add_circle_outline, color: theme.colorScheme.primary),
                  title: Text(
                    'Add Child / बच्चा जोड़ें',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMemberDialog(
                          familyId: widget.familyId,
                          defaultRelation: 'son',
                          fatherId: member.gender == 'male' ? member.id : null,
                          motherId: member.gender == 'female' ? member.id : null,
                          defaultAddress: family?.address,
                          defaultCity: family?.city,
                          defaultState: family?.state,
                          defaultPincode: family?.pincode,
                          onMemberAdded: () {
                            ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                          },
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
                if (member.spouseId == null && member.relationshipToHead != 'spouse')
                  ListTile(
                    leading: Icon(Icons.favorite_border, color: theme.colorScheme.primary),
                    title: Text(
                      'Add Spouse / जीवनसाथी जोड़ें',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMemberDialog(
                            familyId: widget.familyId,
                            defaultRelation: 'spouse',
                            defaultGender: member.gender == 'male' ? 'female' : 'male',
                            spouseId: member.id,
                            defaultAddress: family?.address,
                            defaultCity: family?.city,
                            defaultState: family?.state,
                            defaultPincode: family?.pincode,
                            onMemberAdded: () {
                              ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                            },
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  title: Text(
                    'Edit Member / विवरण संपादित करें',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMemberDialog(
                          familyId: widget.familyId,
                          memberToEdit: member,
                          defaultAddress: family?.address,
                          defaultCity: family?.city,
                          defaultState: family?.state,
                          defaultPincode: family?.pincode,
                          onMemberAdded: () {
                            ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                          },
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Delete Member / सदस्य हटाएं',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteMember(context, member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteMember(BuildContext context, MemberNode member) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Delete Member?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${member.fullName} from the family tree? This will also disconnect their relationships.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'CANCEL',
                style: GoogleFonts.inter(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                try {
                  final dio = ref.read(apiClientProvider);
                  final response = await dio.delete('/directory/member/${member.id}');
                  if (response.statusCode == 200) {
                    ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${member.fullName} removed successfully.',
                            style: GoogleFonts.inter(),
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString()}',
                          style: GoogleFonts.inter(),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'DELETE',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMemberDetailsDialog(BuildContext context, MemberNode member) {
    final allMembers = ref.read(familyTreeProvider(widget.familyId)).value?.members ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyMemberDetailScreen(
          member: member,
          familyMembers: allMembers,
          familyId: widget.familyId,
        ),
      ),
    );
  }
}

class ConnectorPainter extends CustomPainter {
  final int childCount;
  final Color color;

  ConnectorPainter({required this.childCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (childCount <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double radius = 4.0;
    final double midX = size.width / 2;

    // Top drop height is 48.0 px, and total height of the painter is 80.0 px
    const double topDrop = 48.0;
    const double totalHeight = 80.0;
    const double childWidth = 100.0;
    const double halfChildWidth = childWidth / 2;

    // Vertical line from top-center down to y = topDrop
    final path = Path()
      ..moveTo(midX, 0)
      ..lineTo(midX, topDrop);

    if (childCount == 1) {
      // Only 1 child, draw straight down to y = totalHeight
      path.lineTo(midX, totalHeight);
    } else {
      final double startX = halfChildWidth; // Center of first child node (width 100)
      final double endX = size.width - halfChildWidth; // Center of last child node

      // Left side of horizontal bar (from midX to startX + radius)
      path.moveTo(midX, topDrop);
      path.lineTo(startX + radius, topDrop);
      // Elbow curve to (startX, topDrop + radius)
      path.arcToPoint(
        Offset(startX, topDrop + radius),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      // Vertical line down to y = totalHeight
      path.lineTo(startX, totalHeight);

      // Right side of horizontal bar (from midX to endX - radius)
      path.moveTo(midX, topDrop);
      path.lineTo(endX - radius, topDrop);
      // Elbow curve to (endX, topDrop + radius)
      path.arcToPoint(
        Offset(endX, topDrop + radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      // Vertical line down to y = totalHeight
      path.lineTo(endX, totalHeight);

      // Intermediate drops
      for (int i = 1; i < childCount - 1; i++) {
        final double childX = i * childWidth + halfChildWidth;
        path.moveTo(childX, topDrop);
        path.lineTo(childX, totalHeight);
      }

      // Fill in horizontal line gap
      path.moveTo(startX + radius, topDrop);
      path.lineTo(endX - radius, topDrop);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return oldDelegate.childCount != childCount || oldDelegate.color != color;
  }
}
