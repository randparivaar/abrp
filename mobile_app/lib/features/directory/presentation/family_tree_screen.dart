import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:mobile_app/features/directory/presentation/add_member_dialog.dart';
import 'package:mobile_app/features/directory/presentation/app_bottom_navigation.dart';
import 'package:mobile_app/features/directory/presentation/family_member_detail_screen.dart';
import 'package:mobile_app/features/directory/presentation/app_drawer.dart';
import 'package:mobile_app/features/directory/presentation/directory_models.dart';
export 'package:mobile_app/features/directory/presentation/directory_models.dart';

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
    final canEdit = data['canEdit'] as bool? ?? true;

    return FamilyTreeData(family: family, members: members, canEdit: canEdit);
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
  int? _focusedRootMemberId;
  final Set<int> _collapsedMemberIds = {};
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _centerHeadCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_horizontalScrollController.hasClients) {
        final maxScroll = _horizontalScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _horizontalScrollController.jumpTo(maxScroll / 2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(familyTreeProvider(widget.familyId));
    final family = treeAsync.value?.family;
    final theme = Theme.of(context);

    return PopScope(
      canPop: _focusedRootMemberId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _focusedRootMemberId != null) {
          setState(() {
            _focusedRootMemberId = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
            onPressed: () {
              if (_focusedRootMemberId != null) {
                setState(() {
                  _focusedRootMemberId = null;
                });
              } else {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        title: treeAsync.when(
          data: (data) {
            final head = data.members.firstWhere(
              (m) => m.relationshipToHead == 'self',
              orElse: () => data.members.first,
            );

            return Text(
              head.fullName,
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
      floatingActionButton: (treeAsync.value?.canEdit ?? true)
          ? FloatingActionButton(
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
            )
          : null,
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 2),
    ),
  );
}

  Widget _buildTreeContent(BuildContext context, FamilyTreeData data, ThemeData theme) {
    // Determine the root member (either Main Head or Focused Sub-Tree Root)
    final head = data.members.firstWhere(
      (m) => m.relationshipToHead == 'self',
      orElse: () => data.members.first,
    );

    final currentRoot = _focusedRootMemberId != null
        ? data.members.firstWhere(
            (m) => m.id == _focusedRootMemberId,
            orElse: () => head,
          )
        : head;

    final isFocused = _focusedRootMemberId != null && _focusedRootMemberId != head.id;

    // Find Root's spouse if exists
    final spouse = data.members.firstWhere(
      (m) => m.spouseId == currentRoot.id || (currentRoot.spouseId != null && m.id == currentRoot.spouseId),
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    final hasSpouse = spouse.id != -1;

    // Helper function to sort members by age (oldest first, youngest last)
    List<MemberNode> sortByAge(Iterable<MemberNode> list) {
      final sorted = list.toList();
      sorted.sort((a, b) {
        // 1. Sort by birthDate if available (earlier birthDate = older person)
        if (a.birthDate != null && b.birthDate != null) {
          return a.birthDate!.compareTo(b.birthDate!);
        }
        if (a.birthDate != null) return -1; // a has birthdate, b doesn't -> a first
        if (b.birthDate != null) return 1;  // b has birthdate, a doesn't -> b first

        // 2. Sort by estimatedAgeOnCreation (higher age = older person)
        if (a.estimatedAgeOnCreation != null && b.estimatedAgeOnCreation != null) {
          return b.estimatedAgeOnCreation!.compareTo(a.estimatedAgeOnCreation!);
        }
        if (a.estimatedAgeOnCreation != null) return -1;
        if (b.estimatedAgeOnCreation != null) return 1;

        // 3. Fallback to ID for stable sorting
        return a.id.compareTo(b.id);
      });
      return sorted;
    }

    // Find Root's direct children (sorted oldest to youngest)
    final rootAndSpouseIds = {currentRoot.id, if (hasSpouse) spouse.id};
    final children = sortByAge(data.members.where((m) {
      final linkedToRoot = (m.fatherId != null && rootAndSpouseIds.contains(m.fatherId)) ||
          (m.motherId != null && rootAndSpouseIds.contains(m.motherId));
      return linkedToRoot && m.id != currentRoot.id && m.id != spouse.id;
    }));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Breadcrumb Navigation Bar for Sub-Tree Focus Mode
          if (isFocused) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sub-Tree View: ${currentRoot.fullName}\'s Lineage',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedRootMemberId = null;
                      });
                    },
                    icon: const Icon(Icons.home_outlined, size: 14),
                    label: const Text('Main Tree', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
          // Rejection Notice Banner (if any member was rejected with feedback)
          if (data.members.any((m) => m.status == 'rejected' && m.validationFeedback != null && m.validationFeedback!.isNotEmpty)) ...[
            Builder(builder: (_) {
              final rejectedMember = data.members.firstWhere((m) => m.status == 'rejected' && m.validationFeedback != null && m.validationFeedback!.isNotEmpty);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Family Update Required / संशोधन आवश्यक',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Moderator Reason: ${rejectedMember.validationFeedback}',
                            style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please edit member details to fix the issue and resubmit.',
                            style: GoogleFonts.inter(color: Colors.red.shade700, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 8),

          // Scrollable Tree Area (Head + Spouse + Children all aligned together)
          Builder(builder: (context) {
            _centerHeadCard();
            return SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Root Couple Row
                  _buildCoupleRow(
                    context: context,
                    head: currentRoot,
                    spouse: spouse,
                    hasSpouse: hasSpouse,
                    city: data.family.city?.toUpperCase() ?? 'DELHI',
                    theme: theme,
                    family: data.family,
                  ),

                  // Children Generation Layer
                  if (children.isNotEmpty) ...[
                    Builder(builder: (context) {
                      final List<double> branchWidths = children.map((child) {
                        final hasChildSpouse = data.members.any(
                          (m) => (child.spouseId != null && m.id == child.spouseId) || m.spouseId == child.id,
                        );
                        return hasChildSpouse ? 290.0 : 160.0;
                      }).toList();
                      final totalWidth = branchWidths.fold(0.0, (a, b) => a + b);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Connector painter for child nodes
                          CustomPaint(
                            size: Size(totalWidth, 48.0),
                            painter: ConnectorPainter(
                              childCount: children.length,
                              branchWidths: branchWidths,
                              color: theme.colorScheme.primaryContainer,
                            ),
                          ),
                          // Row of children couple-branch cards
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: children.map((child) {
                              return _buildRecursiveMemberBranch(context, child, data.members, theme);
                            }).toList(),
                          ),
                        ],
                      );
                    }),
                  ] else ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'No children added yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Builds the top Head + Spouse main couple card
  Widget _buildCoupleRow({
    required BuildContext context,
    required MemberNode head,
    required MemberNode spouse,
    required bool hasSpouse,
    required String city,
    required ThemeData theme,
    required FamilyUnit family,
  }) {
    final colorScheme = theme.colorScheme;

    Widget buildMemberColumn(MemberNode member, {bool isHead = false}) {
      return GestureDetector(
        onTap: () => _showMemberActionSheet(context, member),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showMemberPhotoViewer(context, member),
              child: AppAvatar(
                name: member.fullName,
                imageUrl: member.avatarUrl,
                radius: 60, // 120px Huge Avatar
                border: Border.all(
                  color: member.gender == 'female'
                      ? Colors.pink.shade400
                      : (isHead ? colorScheme.primary : colorScheme.secondary.withValues(alpha: 0.6)),
                  width: 3.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              child: Text(
                member.fullName,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isHead
                    ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isHead ? 'HEAD • $city' : 'SPOUSE',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isHead ? colorScheme.primary : colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Placeholder spouse card column (tap to add)
    Widget buildSpousePlaceholderColumn() {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMemberDialog(
              familyId: widget.familyId,
              defaultRelation: 'spouse',
              defaultGender: head.gender == 'male' ? 'female' : 'male',
              spouseId: head.id,
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colorScheme.surfaceContainerHigh,
              child: Icon(
                Icons.person_add_alt_1_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 110,
              child: Text(
                'Add Spouse',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'TAP TO ADD',
                style: GoogleFonts.inter(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Head
          buildMemberColumn(head, isHead: true),

          // Heart connector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 1.5,
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 1.5,
                  color: colorScheme.secondary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // Spouse or placeholder
          hasSpouse ? buildMemberColumn(spouse, isHead: false) : buildSpousePlaceholderColumn(),
        ],
      ),
    );
  }

  Widget _buildRecursiveMemberBranch(
    BuildContext context,
    MemberNode member,
    List<MemberNode> allMembers,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    // Find spouse for this node if registered
    final spouseNode = allMembers.firstWhere(
      (m) => (member.spouseId != null && m.id == member.spouseId) || m.spouseId == member.id,
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );
    final hasSpouse = spouseNode.id != -1;

    // Find direct children of this member (sorted oldest to youngest)
    final memberAndSpouseIds = {member.id, if (hasSpouse) spouseNode.id};
    final directChildren = allMembers.where((m) {
      if (memberAndSpouseIds.contains(m.id)) return false;
      final linkedToMember = (m.fatherId != null && memberAndSpouseIds.contains(m.fatherId)) ||
          (m.motherId != null && memberAndSpouseIds.contains(m.motherId));
      return linkedToMember;
    }).toList();

    directChildren.sort((a, b) {
      if (a.birthDate != null && b.birthDate != null) {
        return a.birthDate!.compareTo(b.birthDate!);
      }
      if (a.birthDate != null) return -1;
      if (b.birthDate != null) return 1;

      if (a.estimatedAgeOnCreation != null && b.estimatedAgeOnCreation != null) {
        return b.estimatedAgeOnCreation!.compareTo(a.estimatedAgeOnCreation!);
      }
      if (a.estimatedAgeOnCreation != null) return -1;
      if (b.estimatedAgeOnCreation != null) return 1;

      return a.id.compareTo(b.id);
    });

    // Branch width: 290 for couple card pair, 160 for single child
    final double branchWidth = hasSpouse ? 290.0 : 160.0;

    // ----------- Member photo column (used inside unified card) ----------
    Widget memberPhotoColumn(MemberNode m, {required String roleTag, bool isPrimary = true}) {
      return GestureDetector(
        onTap: () => _showMemberActionSheet(context, m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showMemberPhotoViewer(context, m),
              child: AppAvatar(
                name: m.fullName,
                imageUrl: m.avatarUrl,
                radius: 54, // 108px Huge Avatar for children/spouses
                border: Border.all(
                  color: m.gender == 'female'
                      ? Colors.pink.shade400
                      : (isPrimary ? colorScheme.primary : colorScheme.secondary.withValues(alpha: 0.6)),
                  width: 3.0,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 120,
              child: Text(
                m.fullName,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              roleTag.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isPrimary ? colorScheme.primary : colorScheme.secondary,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // ----------- Unified Couple / Member Card ----------
    Widget coupleHeader;
    if (hasSpouse) {
      coupleHeader = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            memberPhotoColumn(member, roleTag: member.relationshipToHead, isPrimary: true),
            // Heart connector icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 1.5, color: colorScheme.secondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 3),
                  Icon(Icons.favorite_rounded, size: 12, color: colorScheme.secondary),
                  const SizedBox(height: 3),
                  Container(width: 8, height: 1.5, color: colorScheme.secondary.withValues(alpha: 0.4)),
                ],
              ),
            ),
            memberPhotoColumn(spouseNode, roleTag: 'SPOUSE', isPrimary: false),
          ],
        ),
      );
    } else {
      coupleHeader = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: memberPhotoColumn(member, roleTag: member.relationshipToHead, isPrimary: true),
      );
    }

    // ----------- Sub-branch children connector + recursive row ----------
    Widget? childrenSection;
    final isCollapsed = _collapsedMemberIds.contains(member.id);
    double subTotalWidth = 0.0;

    if (directChildren.isNotEmpty) {
      final List<double> subBranchWidths = directChildren.map((sc) {
        final hasSubSpouse = allMembers.any(
          (m) => (sc.spouseId != null && m.id == sc.spouseId) || m.spouseId == sc.id,
        );
        return hasSubSpouse ? 290.0 : 160.0;
      }).toList();
      subTotalWidth = subBranchWidths.fold(0.0, (a, b) => a + b);

      childrenSection = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expand / Collapse Toggle Pill
          GestureDetector(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedMemberIds.remove(member.id);
                } else {
                  _collapsedMemberIds.add(member.id);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primaryContainer),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCollapsed ? Icons.unfold_more : Icons.unfold_less,
                    size: 12,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${directChildren.length} ${directChildren.length == 1 ? 'Child' : 'Children'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (!isCollapsed) ...[
            Container(width: 2, height: 16, color: colorScheme.primaryContainer),
            CustomPaint(
              size: Size(subTotalWidth, 44.0),
              painter: ConnectorPainter(
                childCount: directChildren.length,
                branchWidths: subBranchWidths,
                color: colorScheme.primaryContainer,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: directChildren.map((subChild) {
                return _buildRecursiveMemberBranch(context, subChild, allMembers, theme);
              }).toList(),
            ),
          ],
        ],
      );
    }

    // Dynamic width: allow branch container to expand if level 3 sub-tree children span wider than parent card
    final double effectiveWidth = (!isCollapsed && subTotalWidth > branchWidth) ? subTotalWidth : branchWidth;

    return SizedBox(
      width: effectiveWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          coupleHeader,
          ?childrenSection,
        ],
      ),
    );
  }

  void _showMemberPhotoViewer(BuildContext context, MemberNode member) {
    final theme = Theme.of(context);
    final avatarUrl = member.avatarUrl;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                height: 320,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _buildPlaceholderPhoto(theme, member.fullName),
                              )
                            : _buildPlaceholderPhoto(theme, member.fullName),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          member.fullName,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${member.relationshipToHead.toUpperCase()} • ${member.gender.toUpperCase()}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (member.gotra != null && member.gotra!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Gotra: ${member.gotra}',
                            style: GoogleFonts.inter(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto(ThemeData theme, String name) {
    return Container(
      height: 240,
      width: double.infinity,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 12),
          const Text('No Photo Available', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }

  void _showMemberActionSheet(BuildContext context, MemberNode member) {
    final treeData = ref.read(familyTreeProvider(widget.familyId)).value;
    final canEdit = treeData?.canEdit ?? false;

    // If user does not have edit rights for this family tree, directly open Full Detail Screen
    if (!canEdit) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FamilyMemberDetailScreen(
            member: member,
            familyMembers: treeData?.members ?? [],
            familyId: widget.familyId,
          ),
        ),
      );
      return;
    }

    final theme = Theme.of(context);
    final family = treeData?.family;

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
                  leading: Icon(Icons.center_focus_strong_outlined, color: theme.colorScheme.primary),
                  title: Text(
                    'View Full Photo / फोटो देखें',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showMemberPhotoViewer(context, member);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.account_tree_outlined, color: theme.colorScheme.primary),
                  title: Text(
                    'Focus Sub-Tree / वंश वृक्ष देखें',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _focusedRootMemberId = member.id;
                    });
                  },
                ),
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
  final List<double> branchWidths; // Width of each branch (120 single, 200 couple)
  final Color color;

  ConnectorPainter({
    required this.childCount,
    required this.branchWidths,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (childCount <= 0 || branchWidths.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double radius = 4.0;
    final double midX = size.width / 2;

    // Top drop and total painter height
    const double topDrop = 32.0;
    const double totalHeight = 48.0;

    // Compute the center X of each branch
    final List<double> centerXs = [];
    double offset = 0.0;
    for (int i = 0; i < childCount; i++) {
      final w = i < branchWidths.length ? branchWidths[i] : 120.0;
      centerXs.add(offset + w / 2);
      offset += w;
    }

    // Vertical line from top-center down to y = topDrop
    final path = Path()
      ..moveTo(midX, 0)
      ..lineTo(midX, topDrop);

    if (childCount == 1) {
      // Only 1 child, draw straight down
      path.lineTo(midX, totalHeight);
    } else {
      final double startX = centerXs.first;
      final double endX = centerXs.last;

      // Left elbow
      path.moveTo(midX, topDrop);
      path.lineTo(startX + radius, topDrop);
      path.arcToPoint(
        Offset(startX, topDrop + radius),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(startX, totalHeight);

      // Right elbow
      path.moveTo(midX, topDrop);
      path.lineTo(endX - radius, topDrop);
      path.arcToPoint(
        Offset(endX, topDrop + radius),
        radius: Radius.circular(radius),
        clockwise: true,
      );
      path.lineTo(endX, totalHeight);

      // Intermediate drops
      for (int i = 1; i < childCount - 1; i++) {
        final double childX = centerXs[i];
        path.moveTo(childX, topDrop);
        path.lineTo(childX, totalHeight);
      }

      // Horizontal bar connecting all branches
      path.moveTo(startX + radius, topDrop);
      path.lineTo(endX - radius, topDrop);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return oldDelegate.childCount != childCount ||
        oldDelegate.color != color ||
        oldDelegate.branchWidths != branchWidths;
  }
}
