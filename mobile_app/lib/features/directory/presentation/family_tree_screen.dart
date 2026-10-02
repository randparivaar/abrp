import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/utils/app_avatar.dart';
import 'package:mobile_app/features/directory/presentation/add_member_dialog.dart';
import 'package:mobile_app/features/directory/presentation/app_bottom_navigation.dart';
import 'package:mobile_app/features/directory/presentation/family_member_detail_screen.dart';
import 'package:mobile_app/features/directory/presentation/app_drawer.dart';
import 'package:mobile_app/features/directory/presentation/directory_models.dart';
export 'package:mobile_app/features/directory/presentation/directory_models.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _showCanvasTree = false;
  bool get _showPremiumUI => _showCanvasTree;
  String _seniorSearchQuery = '';
  int _seniorFilterGen = 0; // 0 = All, 1 = Elders/Parents, 2 = Self/Spouse, 3 = Children, 4 = Grandchildren
  final ScrollController _horizontalScrollController = ScrollController();
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _transformationController.dispose();
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

    // Show snackbar whenever the API fails (including 500 errors)
    ref.listen<AsyncValue<FamilyTreeData>>(familyTreeProvider(widget.familyId), (previous, next) {
      if (next is AsyncError && previous is! AsyncError) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 8),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                onPressed: () => ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree(),
              ),
            ),
          );
      }
    });

    return Scaffold(
        backgroundColor: _showPremiumUI ? null : theme.colorScheme.surface,
        drawer: const AppDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
            onPressed: () {
              if (_focusedRootMemberId != null) {
                // If viewing a sub-tree, go back to root tree
                setState(() {
                  _focusedRootMemberId = null;
                });
              } else {
                // context.canPop() is true when opened via context.push (from home card, directory FAB, etc.)
                // context.canPop() is false when opened via bottom nav (context.go replaces the stack)
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/'); // Bottom nav → back goes to Home
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

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    head.fullName,
                    style: GoogleFonts.outfit(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'FAMILY HERITAGE TREE',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFC59B27),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              );
            },
            loading: () => Text('Loading Tree...', style: TextStyle(color: theme.colorScheme.primary)),
            error: (_, _) => Text('Error Loading Tree', style: TextStyle(color: theme.colorScheme.primary)),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _showCanvasTree = !_showCanvasTree),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: _showCanvasTree
                        ? const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
                          )
                        : null,
                    color: _showCanvasTree ? null : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showCanvasTree
                          ? const Color(0xFFD4AF37)
                          : Colors.grey.shade400,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCanvasTree
                            ? Icons.auto_awesome
                            : Icons.view_agenda_outlined,
                        size: 13,
                        color: _showCanvasTree ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showCanvasTree ? 'V2 Tree' : 'Cards',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _showCanvasTree ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      body: treeAsync.when(
        data: (data) => _showCanvasTree
            ? _buildPremiumTreeContent(context, data, theme)
            : _buildSeniorTreeContent(context, data, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not load the family tree. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(familyTreeProvider(widget.familyId).notifier).fetchTree(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
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
    );
  }

  void _showMemberPhotoViewer(BuildContext context, MemberNode member) {
    final theme = Theme.of(context);
    final avatarUrl = member.avatarUrl;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  height: 250,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            member.fullName,
                            style: GoogleFonts.outfit(
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
                              color: Colors.grey.shade600,
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

  // ============================================================
  // PREMIUM V2 UI — Generation badges, status dots, AnimatedSize
  // ============================================================

  Widget _buildGenerationBadge(int gen) {
    const labels = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];
    final label = gen < labels.length ? 'GENERATION ${labels[gen]}' : 'GEN $gen';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFAA771C), Color(0xFFD4AF37)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumStatsBar(FamilyTreeData data, ThemeData theme) {
    final totalMembers = data.members.length;
    final approvedCount = data.members.where((m) => (m.status ?? '') == 'approved').length;
    final pendingCount = data.members.where((m) => (m.status ?? '') == 'pending').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.people_rounded, '$totalMembers', 'Members', const Color(0xFF6B1919)),
          Container(width: 1, height: 28, color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
          _statItem(Icons.verified_rounded, '$approvedCount', 'Verified', const Color(0xFF4CAF50)),
          if (pendingCount > 0) ...[
            Container(width: 1, height: 28, color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
            _statItem(Icons.pending_rounded, '$pendingCount', 'Pending', const Color(0xFFFFC107)),
          ],
          Container(width: 1, height: 28, color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
          _statItem(Icons.pinch_rounded, 'Pinch', 'to Zoom', theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildPremiumBreadcrumb(
    BuildContext context,
    MemberNode currentRoot,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sub-Tree: ${currentRoot.fullName}\'s Lineage',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: theme.colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _focusedRootMemberId = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home_rounded, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Main Tree',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildPremiumRejectionBanner(FamilyTreeData data) {
    final rejectedMember = data.members.firstWhere(
      (m) =>
          m.status == 'rejected' &&
          m.validationFeedback != null &&
          m.validationFeedback!.isNotEmpty,
    );
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade900],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Update Required / संशोधन आवश्यक',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Moderator Reason: ${rejectedMember.validationFeedback}',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please edit member details to fix the issue and resubmit.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumMemberPhotoColumn(
    BuildContext context,
    MemberNode m, {
    required String roleTag,
    bool isPrimary = true,
    int generation = 2,
  }) {
    final double avatarRadius = generation == 1 ? 56.0 : 46.0;
    final double nameWidth = generation == 1 ? 130.0 : 110.0;

    // Build birth year display
    String? birthInfo;
    if (m.birthDate != null) {
      birthInfo = 'b. ${m.birthDate!.year}';
    }

    // Status indicator dot color
    final String statusVal = m.status ?? '';
    final Color dotColor;
    if (statusVal == 'approved') {
      dotColor = const Color(0xFF4CAF50);
    } else if (statusVal == 'rejected') {
      dotColor = Colors.red.shade600;
    } else {
      dotColor = const Color(0xFFFFC107); // pending or unknown
    }

    return GestureDetector(
      onTap: () => _showMemberActionSheet(context, m),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _showMemberPhotoViewer(context, m),
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isPrimary
                        ? const LinearGradient(
                            colors: [Color(0xFFF4D068), Color(0xFFAA771C), Color(0xFFD4AF37)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            colors: [Colors.pink.shade300, Colors.pink.shade600],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPrimary ? const Color(0xFFD4AF37) : Colors.pink)
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AppAvatar(
                    name: m.fullName,
                    imageUrl: m.avatarUrl,
                    radius: avatarRadius,
                  ),
                ),
              ),
              // Status indicator dot
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.5),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: nameWidth,
            child: Text(
              m.fullName,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: generation == 1 ? 16 : 14,
                color: const Color(0xFF2C1D11),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (birthInfo != null) ...[
            const SizedBox(height: 2),
            Text(
              birthInfo,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF8C6615),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                    )
                  : null,
              color: isPrimary ? null : Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: isPrimary
                  ? null
                  : Border.all(color: Colors.pink.withValues(alpha: 0.3)),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              roleTag.toUpperCase(),
              style: GoogleFonts.inter(
                color: isPrimary ? Colors.white : Colors.pink.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 8,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSpousePlaceholderColumn(
    BuildContext context,
    MemberNode head,
    FamilyUnit family,
  ) {
    final String defaultSpouseRelation;
    final hRel = head.relationshipToHead.toLowerCase();
    if (hRel == 'father') {
      defaultSpouseRelation = 'mother';
    } else if (hRel == 'mother') {
      defaultSpouseRelation = 'father';
    } else if (hRel.contains('grandfather')) {
      defaultSpouseRelation = 'grandmother';
    } else if (hRel.contains('grandmother')) {
      defaultSpouseRelation = 'grandfather';
    } else {
      defaultSpouseRelation = 'spouse';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddMemberDialog(
            familyId: widget.familyId,
            defaultRelation: defaultSpouseRelation,
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
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 56,
              backgroundColor: const Color(0xFFF5F0E8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Color(0xFFAA771C),
                    size: 28,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFAA771C),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 110,
            child: Text(
              'Add Spouse',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: const Color(0xFF7A6855),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'TAP TO ADD',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  MemberNode _findAncestralRoot(List<MemberNode> members) {
    if (members.isEmpty) {
      return MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: '');
    }

    // 1. Look for Grandfather / Paternal Grandfather
    final grandfather = members.where((m) =>
      ['grandfather', 'paternal_grandfather'].contains(m.relationshipToHead.toLowerCase())
    ).firstOrNull;
    if (grandfather != null) return grandfather;

    final grandmother = members.where((m) =>
      ['grandmother', 'paternal_grandmother'].contains(m.relationshipToHead.toLowerCase())
    ).firstOrNull;
    if (grandmother != null) return grandmother;

    // 2. Look for Father
    final father = members.where((m) =>
      m.relationshipToHead.toLowerCase() == 'father'
    ).firstOrNull;
    if (father != null) return father;

    // 2b. Look for Mother
    final mother = members.where((m) =>
      m.relationshipToHead.toLowerCase() == 'mother'
    ).firstOrNull;
    if (mother != null) return mother;

    // 3. Look for Head of Family ('self')
    final head = members.where((m) =>
      m.relationshipToHead.toLowerCase() == 'self'
    ).firstOrNull;
    if (head != null) return head;

    return members.first;
  }

  String _getMemberDisplayRoleTag(MemberNode m) {
    switch (m.relationshipToHead.toLowerCase()) {
      case 'self':
        return 'HEAD OF FAMILY / मुखिया';
      case 'spouse':
        return 'SPOUSE / जीवनसाथी';
      case 'father':
        return 'FATHER / पिता';
      case 'mother':
        return 'MOTHER / माता';
      case 'grandfather':
      case 'paternal_grandfather':
        return 'GRANDFATHER / दादाजी';
      case 'grandmother':
      case 'paternal_grandmother':
        return 'GRANDMOTHER / दादीजी';
      case 'son':
        return 'SON / पुत्र';
      case 'daughter':
        return 'DAUGHTER / पुत्री';
      case 'brother':
        return 'BROTHER / भाई';
      case 'sister':
        return 'SISTER / बहन';
      case 'daughter_in_law':
        return 'DAUGHTER-IN-LAW / पुत्रवधू';
      case 'son_in_law':
        return 'SON-IN-LAW / दामाद';
      case 'grandson':
        return 'GRANDSON / पौत्र';
      case 'granddaughter':
        return 'GRANDDAUGHTER / पौत्री';
      default:
        return m.relationshipToHead.replaceAll('_', ' ').toUpperCase();
    }
  }

  MemberNode _findSpouseFor(MemberNode member, List<MemberNode> allMembers) {
    if (member.id == -1) {
      return MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: '');
    }
    // 1. Direct explicit spouseId match
    final explicitSpouse = allMembers.where((m) =>
      (member.spouseId != null && m.id == member.spouseId) ||
      (m.spouseId != null && m.spouseId == member.id)
    ).firstOrNull;
    if (explicitSpouse != null) return explicitSpouse;

    // 2. Relationship-based match when spouseId is not linked:
    final rel = member.relationshipToHead.toLowerCase();
    if (rel == 'self') {
      final s = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'spouse').firstOrNull;
      if (s != null) return s;
    } else if (rel == 'spouse') {
      final s = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'self').firstOrNull;
      if (s != null) return s;
    } else if (rel == 'father') {
      final s = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'mother').firstOrNull;
      if (s != null) return s;
    } else if (rel == 'mother') {
      final s = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'father').firstOrNull;
      if (s != null) return s;
    } else if (['grandfather', 'paternal_grandfather'].contains(rel)) {
      final s = allMembers.where((m) =>
        ['grandmother', 'paternal_grandmother'].contains(m.relationshipToHead.toLowerCase())
      ).firstOrNull;
      if (s != null) return s;
    } else if (['grandmother', 'paternal_grandmother'].contains(rel)) {
      final s = allMembers.where((m) =>
        ['grandfather', 'paternal_grandfather'].contains(m.relationshipToHead.toLowerCase())
      ).firstOrNull;
      if (s != null) return s;
    } else if (rel == 'son') {
      final dils = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'daughter_in_law').toList();
      final sons = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'son').toList();
      if (dils.length == 1 && sons.length == 1) {
        return dils.first;
      }
    } else if (rel == 'daughter_in_law') {
      final dils = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'daughter_in_law').toList();
      final sons = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'son').toList();
      if (dils.length == 1 && sons.length == 1) {
        return sons.first;
      }
    } else if (rel == 'brother') {
      final sils = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'sister_in_law').toList();
      final brothers = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'brother').toList();
      if (sils.length == 1 && brothers.length == 1) {
        return sils.first;
      }
    } else if (rel == 'sister_in_law') {
      final sils = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'sister_in_law').toList();
      final brothers = allMembers.where((m) => m.relationshipToHead.toLowerCase() == 'brother').toList();
      if (sils.length == 1 && brothers.length == 1) {
        return brothers.first;
      }
    }

    return MemberNode(
      id: -1,
      familyId: -1,
      fullName: '',
      gender: '',
      relationshipToHead: '',
    );
  }

  List<MemberNode> _getChildrenOf(
    MemberNode parent,
    MemberNode spouse,
    List<MemberNode> allMembers,
  ) {
    final parentSpouseIds = {parent.id, if (spouse.id != -1) spouse.id};
    final pRel = parent.relationshipToHead.toLowerCase();
    final sRel = spouse.id != -1 ? spouse.relationshipToHead.toLowerCase() : '';

    final isGrandparent = pRel.contains('grandfather') ||
        pRel.contains('grandmother') ||
        sRel.contains('grandfather') ||
        sRel.contains('grandmother');

    final isParentOfHead = pRel == 'father' ||
        pRel == 'mother' ||
        sRel == 'father' ||
        sRel == 'mother';

    final isHead = pRel == 'self' || sRel == 'self';

    final isSonDaughter = pRel == 'son' ||
        pRel == 'daughter' ||
        pRel == 'daughter_in_law' ||
        pRel == 'son_in_law' ||
        sRel == 'son' ||
        sRel == 'daughter' ||
        sRel == 'daughter_in_law' ||
        sRel == 'son_in_law';

    // 1. Direct explicit fatherId / motherId links
    final directLinked = allMembers.where((m) {
      if (parentSpouseIds.contains(m.id)) return false;
      return (m.fatherId != null && parentSpouseIds.contains(m.fatherId)) ||
          (m.motherId != null && parentSpouseIds.contains(m.motherId));
    }).toList();

    final result = <MemberNode>[...directLinked];
    final addedIds = result.map((m) => m.id).toSet();

    // 2. Semantic fallback for unlinked members:
    if (isGrandparent) {
      for (final m in allMembers) {
        if (parentSpouseIds.contains(m.id) || addedIds.contains(m.id)) continue;
        final rel = m.relationshipToHead.toLowerCase();
        if (['father', 'mother', 'uncle', 'aunt'].contains(rel) &&
            m.fatherId == null && m.motherId == null) {
          result.add(m);
          addedIds.add(m.id);
        }
      }
      if (result.isEmpty) {
        for (final m in allMembers) {
          if (parentSpouseIds.contains(m.id) || addedIds.contains(m.id)) continue;
          if (m.relationshipToHead.toLowerCase() == 'self' &&
              m.fatherId == null && m.motherId == null) {
            result.add(m);
            addedIds.add(m.id);
          }
        }
      }
    } else if (isParentOfHead) {
      for (final m in allMembers) {
        if (parentSpouseIds.contains(m.id) || addedIds.contains(m.id)) continue;
        final rel = m.relationshipToHead.toLowerCase();
        if (['self', 'brother', 'sister'].contains(rel) &&
            m.fatherId == null && m.motherId == null) {
          result.add(m);
          addedIds.add(m.id);
        }
      }
    } else if (isHead) {
      for (final m in allMembers) {
        if (parentSpouseIds.contains(m.id) || addedIds.contains(m.id)) continue;
        final rel = m.relationshipToHead.toLowerCase();
        if (['son', 'daughter'].contains(rel) &&
            m.fatherId == null && m.motherId == null) {
          result.add(m);
          addedIds.add(m.id);
        }
      }
    } else if (isSonDaughter) {
      final sonsAndDils = allMembers.where((m) =>
        ['son', 'daughter_in_law'].contains(m.relationshipToHead.toLowerCase())
      ).toList();
      if (sonsAndDils.length <= 2) {
        for (final m in allMembers) {
          if (parentSpouseIds.contains(m.id) || addedIds.contains(m.id)) continue;
          final rel = m.relationshipToHead.toLowerCase();
          if (['grandson', 'granddaughter'].contains(rel) &&
              m.fatherId == null && m.motherId == null) {
            result.add(m);
            addedIds.add(m.id);
          }
        }
      }
    }

    // Exclude spouses that will be rendered side-by-side with their partner
    final filtered = result.where((m) {
      final rel = m.relationshipToHead.toLowerCase();
      if (rel.contains('in_law') || rel == 'spouse' || rel == 'mother' || rel.contains('grandmother')) {
        for (final other in result) {
          if (other.id == m.id) continue;
          if (m.spouseId == other.id || other.spouseId == m.id) return false;
          if ((rel == 'daughter_in_law' && other.relationshipToHead.toLowerCase() == 'son') ||
              (rel == 'son_in_law' && other.relationshipToHead.toLowerCase() == 'daughter') ||
              (rel == 'mother' && other.relationshipToHead.toLowerCase() == 'father') ||
              (rel.contains('grandmother') && other.relationshipToHead.toLowerCase().contains('grandfather')) ||
              (rel == 'sister_in_law' && other.relationshipToHead.toLowerCase() == 'brother')) {
            return false;
          }
        }
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
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

    return filtered;
  }

  Widget _buildPremiumCoupleRow({
    required BuildContext context,
    required MemberNode head,
    required MemberNode spouse,
    required bool hasSpouse,
    required String city,
    required ThemeData theme,
    required FamilyUnit family,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF5), Color(0xFFFDF8E8), Color(0xFFF8F0D8)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPremiumMemberPhotoColumn(
            context,
            head,
            roleTag: '${_getMemberDisplayRoleTag(head)} • $city',
            isPrimary: true,
            generation: 1,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 1.5,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB3C1), Color(0xFFFF4D6D)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 1.5,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          hasSpouse
              ? _buildPremiumMemberPhotoColumn(
                  context,
                  spouse,
                  roleTag: _getMemberDisplayRoleTag(spouse),
                  isPrimary: false,
                  generation: 1,
                )
              : _buildPremiumSpousePlaceholderColumn(context, head, family),
        ],
      ),
    );
  }

  Widget _buildPremiumRecursiveMemberBranch(
    BuildContext context,
    MemberNode member,
    List<MemberNode> allMembers,
    ThemeData theme, {
    int generation = 2,
  }) {
    final colorScheme = theme.colorScheme;

    final spouseNode = _findSpouseFor(member, allMembers);
    final hasSpouse = spouseNode.id != -1;

    final directChildren = _getChildrenOf(member, spouseNode, allMembers);

    final double branchWidth = hasSpouse ? 290.0 : 160.0;

    // Premium card with gradient background + generation badge
    final premiumCard = Container(
      padding: EdgeInsets.symmetric(
        horizontal: hasSpouse ? 10 : 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDF5), Color(0xFFFAF5E6)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC59B27).withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildGenerationBadge(generation),
          const SizedBox(height: 8),
          if (hasSpouse)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPremiumMemberPhotoColumn(
                  context,
                  member,
                  roleTag: _getMemberDisplayRoleTag(member),
                  isPrimary: true,
                  generation: generation,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 1.5,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB3C1), Color(0xFFFF4D6D)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.35),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        width: 8,
                        height: 1.5,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                _buildPremiumMemberPhotoColumn(
                  context,
                  spouseNode,
                  roleTag: _getMemberDisplayRoleTag(spouseNode),
                  isPrimary: false,
                  generation: generation,
                ),
              ],
            )
          else
            _buildPremiumMemberPhotoColumn(
              context,
              member,
              roleTag: _getMemberDisplayRoleTag(member),
              isPrimary: true,
              generation: generation,
            ),
        ],
      ),
    );

    final isCollapsed = _collapsedMemberIds.contains(member.id);
    Widget? childrenSection;
    double subTotalWidth = 0.0;

    if (directChildren.isNotEmpty) {
      final List<double> subBranchWidths = directChildren.map((sc) {
        final hasSubSpouse = allMembers.any(
          (m) =>
              (sc.spouseId != null && m.id == sc.spouseId) ||
              m.spouseId == sc.id,
        );
        return hasSubSpouse ? 290.0 : 160.0;
      }).toList();
      subTotalWidth = subBranchWidths.fold(0.0, (a, b) => a + b);

      childrenSection = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold gradient collapse pill with animated rotating chevron
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${directChildren.length} '
                    '${directChildren.length == 1 ? 'Child' : 'Children'}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isCollapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Smooth animated expand/collapse
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: isCollapsed
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: 16,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFD4AF37), Color(0xFFAA771C)],
                          ),
                        ),
                      ),
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
                          return _buildPremiumRecursiveMemberBranch(
                            context,
                            subChild,
                            allMembers,
                            theme,
                            generation: generation + 1,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    final double effectiveWidth =
        (!isCollapsed && subTotalWidth > branchWidth) ? subTotalWidth : branchWidth;

    return SizedBox(
      width: effectiveWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          premiumCard,
          ?childrenSection,
        ],
      ),
    );
  }

  Widget _buildPremiumTreeContent(
    BuildContext context,
    FamilyTreeData data,
    ThemeData theme,
  ) {
    final ancestralRoot = _findAncestralRoot(data.members);

    final currentRoot = _focusedRootMemberId != null
        ? data.members.firstWhere(
            (m) => m.id == _focusedRootMemberId,
            orElse: () => ancestralRoot,
          )
        : ancestralRoot;

    final isFocused =
        _focusedRootMemberId != null && _focusedRootMemberId != ancestralRoot.id;

    final spouse = _findSpouseFor(currentRoot, data.members);
    final hasSpouse = spouse.id != -1;

    final children = _getChildrenOf(currentRoot, spouse, data.members);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDF9F0),
            Color(0xFFF5EDD8),
            Color(0xFFF0E5CC),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFocused) _buildPremiumBreadcrumb(context, currentRoot, theme),

            if (data.members.any((m) =>
                m.status == 'rejected' &&
                m.validationFeedback != null &&
                m.validationFeedback!.isNotEmpty))
              _buildPremiumRejectionBanner(data),

            const SizedBox(height: 12),
            _buildPremiumStatsBar(data, theme),
            const SizedBox(height: 8),

            Builder(builder: (context) {
              _centerHeadCard();
              return InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.3,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(80),
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 48.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildGenerationBadge(1),
                        const SizedBox(height: 10),
                        _buildPremiumCoupleRow(
                          context: context,
                          head: currentRoot,
                          spouse: spouse,
                          hasSpouse: hasSpouse,
                          city: data.family.city?.toUpperCase() ?? 'DELHI',
                          theme: theme,
                          family: data.family,
                        ),
                        if (children.isNotEmpty) ...[
                          Builder(builder: (context) {
                            final List<double> branchWidths =
                                children.map((child) {
                              final hasChildSpouse = data.members.any(
                                (m) =>
                                    (child.spouseId != null &&
                                        m.id == child.spouseId) ||
                                    m.spouseId == child.id,
                              );
                              return hasChildSpouse ? 290.0 : 160.0;
                            }).toList();
                            final totalWidth =
                                branchWidths.fold(0.0, (a, b) => a + b);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomPaint(
                                  size: Size(totalWidth, 48.0),
                                  painter: ConnectorPainter(
                                    childCount: children.length,
                                    branchWidths: branchWidths,
                                    color: theme.colorScheme.primaryContainer,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: children.map((child) {
                                    return _buildPremiumRecursiveMemberBranch(
                                      context,
                                      child,
                                      data.members,
                                      theme,
                                      generation: 2,
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SENIOR ACCESSIBLE UI — Large cards, bold text, direct action buttons
  // ============================================================

  Widget _buildSeniorTreeContent(BuildContext context, FamilyTreeData data, ThemeData theme) {
    // Filter members by search query
    final filteredMembers = data.members.where((m) {
      if (_seniorSearchQuery.trim().isEmpty) return true;
      final q = _seniorSearchQuery.trim().toLowerCase();
      final nameMatch = m.fullName.toLowerCase().contains(q);
      final relMatch = m.relationshipToHead.toLowerCase().contains(q);
      final gotraMatch = (m.gotra ?? '').toLowerCase().contains(q);
      final mobileMatch = (m.mobile ?? '').contains(q);
      return nameMatch || relMatch || gotraMatch || mobileMatch;
    }).toList();

    // 1. Elders & Parents (Sorted by Age Descending)
    final eldersAndParents = filteredMembers.where((m) {
      final rel = m.relationshipToHead.toLowerCase();
      return ['father', 'mother', 'grandfather', 'grandmother', 'paternal_grandfather', 'paternal_grandmother', 'maternal_grandfather', 'maternal_grandmother', 'uncle', 'aunt'].contains(rel);
    }).toList();
    eldersAndParents.sort((a, b) => b.age.compareTo(a.age));

    // 2. Self, Spouse & Siblings (Head + Spouse, then Siblings by Age + Spouse)
    final selfAndSpouseAndSiblings = <MemberNode>[];
    final processedSelfIds = <int>{};

    final headMember = filteredMembers.firstWhere(
      (m) => m.relationshipToHead.toLowerCase() == 'self',
      orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
    );

    if (headMember.id != -1) {
      selfAndSpouseAndSiblings.add(headMember);
      processedSelfIds.add(headMember.id);

      final spouseOfHead = filteredMembers.firstWhere(
        (m) => (headMember.spouseId != null && m.id == headMember.spouseId) ||
               (m.relationshipToHead.toLowerCase() == 'spouse'),
        orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
      );
      if (spouseOfHead.id != -1 && !processedSelfIds.contains(spouseOfHead.id)) {
        selfAndSpouseAndSiblings.add(spouseOfHead);
        processedSelfIds.add(spouseOfHead.id);
      }
    }

    final siblings = filteredMembers.where((m) {
      final rel = m.relationshipToHead.toLowerCase();
      return ['brother', 'sister'].contains(rel) && !processedSelfIds.contains(m.id);
    }).toList();
    siblings.sort((a, b) => b.age.compareTo(a.age));

    for (final sib in siblings) {
      if (!processedSelfIds.contains(sib.id)) {
        selfAndSpouseAndSiblings.add(sib);
        processedSelfIds.add(sib.id);

        final sibSpouse = filteredMembers.firstWhere(
          (m) => (sib.spouseId != null && m.id == sib.spouseId) ||
                 (m.spouseId != null && m.spouseId == sib.id),
          orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
        );
        if (sibSpouse.id != -1 && !processedSelfIds.contains(sibSpouse.id)) {
          selfAndSpouseAndSiblings.add(sibSpouse);
          processedSelfIds.add(sibSpouse.id);
        }
      }
    }

    for (final m in filteredMembers) {
      final rel = m.relationshipToHead.toLowerCase();
      if (['self', 'spouse', 'brother', 'sister', 'brother_in_law', 'sister_in_law'].contains(rel)) {
        if (!processedSelfIds.contains(m.id)) {
          selfAndSpouseAndSiblings.add(m);
          processedSelfIds.add(m.id);
        }
      }
    }

    // 3. Children & Spouses (Sorted Age-wise: Oldest Child first, followed immediately by their Spouse)
    final childrenAndInlaws = <MemberNode>[];
    final processedChildIds = <int>{};

    final primaryChildren = filteredMembers.where((m) =>
      ['son', 'daughter'].contains(m.relationshipToHead.toLowerCase())
    ).toList();
    primaryChildren.sort((a, b) => b.age.compareTo(a.age));

    for (final child in primaryChildren) {
      if (!processedChildIds.contains(child.id)) {
        childrenAndInlaws.add(child);
        processedChildIds.add(child.id);

        // Find spouse of this child
        final spouse = filteredMembers.firstWhere(
          (m) => (child.spouseId != null && m.id == child.spouseId) ||
                 (m.spouseId != null && m.spouseId == child.id),
          orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
        );
        if (spouse.id != -1 && !processedChildIds.contains(spouse.id)) {
          childrenAndInlaws.add(spouse);
          processedChildIds.add(spouse.id);
        }
      }
    }

    for (final m in filteredMembers) {
      final rel = m.relationshipToHead.toLowerCase();
      if (['son', 'daughter', 'son_in_law', 'daughter_in_law', 'nephew', 'niece'].contains(rel)) {
        if (!processedChildIds.contains(m.id)) {
          childrenAndInlaws.add(m);
          processedChildIds.add(m.id);
        }
      }
    }

    // 4. Grandchildren & Spouses (Sorted Age-wise: Oldest Grandchild first, followed immediately by their Spouse)
    final grandchildren = <MemberNode>[];
    final processedGcIds = <int>{};

    final primaryGrandchildren = filteredMembers.where((m) =>
      ['grandson', 'granddaughter'].contains(m.relationshipToHead.toLowerCase())
    ).toList();
    primaryGrandchildren.sort((a, b) => b.age.compareTo(a.age));

    for (final gc in primaryGrandchildren) {
      if (!processedGcIds.contains(gc.id)) {
        grandchildren.add(gc);
        processedGcIds.add(gc.id);

        final spouse = filteredMembers.firstWhere(
          (m) => (gc.spouseId != null && m.id == gc.spouseId) ||
                 (m.spouseId != null && m.spouseId == gc.id),
          orElse: () => MemberNode(id: -1, familyId: -1, fullName: '', gender: '', relationshipToHead: ''),
        );
        if (spouse.id != -1 && !processedGcIds.contains(spouse.id)) {
          grandchildren.add(spouse);
          processedGcIds.add(spouse.id);
        }
      }
    }

    for (final m in filteredMembers) {
      final rel = m.relationshipToHead.toLowerCase();
      if (['grandson', 'granddaughter'].contains(rel)) {
        if (!processedGcIds.contains(m.id)) {
          grandchildren.add(m);
          processedGcIds.add(m.id);
        }
      }
    }

    // 5. Others
    final allCategorizedIds = {
      ...eldersAndParents.map((e) => e.id),
      ...selfAndSpouseAndSiblings.map((e) => e.id),
      ...childrenAndInlaws.map((e) => e.id),
      ...grandchildren.map((e) => e.id),
    };
    final others = filteredMembers.where((m) => !allCategorizedIds.contains(m.id)).toList();

    return Container(
      color: theme.colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          // Senior Header & Search Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _seniorSearchQuery = val),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Search family member name or relation...',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 24, color: Color(0xFFC59B27)),
                      suffixIcon: _seniorSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _seniorSearchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFC59B27), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips Scrollable
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSeniorFilterChip('All (${filteredMembers.length})', 0),
                        const SizedBox(width: 8),
                        if (eldersAndParents.isNotEmpty)
                          _buildSeniorFilterChip('Elders & Parents (${eldersAndParents.length})', 1),
                        if (eldersAndParents.isNotEmpty) const SizedBox(width: 8),
                        if (selfAndSpouseAndSiblings.isNotEmpty)
                          _buildSeniorFilterChip('Self & Siblings (${selfAndSpouseAndSiblings.length})', 2),
                        if (selfAndSpouseAndSiblings.isNotEmpty) const SizedBox(width: 8),
                        if (childrenAndInlaws.isNotEmpty)
                          _buildSeniorFilterChip('Children (${childrenAndInlaws.length})', 3),
                        if (childrenAndInlaws.isNotEmpty) const SizedBox(width: 8),
                        if (grandchildren.isNotEmpty)
                          _buildSeniorFilterChip('Grandchildren (${grandchildren.length})', 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section 1: Elders & Parents
          if ((_seniorFilterGen == 0 || _seniorFilterGen == 1) && eldersAndParents.isNotEmpty) ...[
            _buildSeniorSectionHeader('1. Elders & Parents / बुज़ुर्ग और माता-पिता', Icons.elderly),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSeniorMemberCard(context, eldersAndParents[index], theme),
                childCount: eldersAndParents.length,
              ),
            ),
          ],

          // Section 2: Self, Spouse & Siblings
          if ((_seniorFilterGen == 0 || _seniorFilterGen == 2) && selfAndSpouseAndSiblings.isNotEmpty) ...[
            _buildSeniorSectionHeader('2. Self, Spouse & Siblings / स्वयं और भाई-बहन', Icons.people),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSeniorMemberCard(context, selfAndSpouseAndSiblings[index], theme),
                childCount: selfAndSpouseAndSiblings.length,
              ),
            ),
          ],

          // Section 3: Children & In-laws
          if ((_seniorFilterGen == 0 || _seniorFilterGen == 3) && childrenAndInlaws.isNotEmpty) ...[
            _buildSeniorSectionHeader('3. Children & Spouses / बच्चे और बहू-दामाद', Icons.child_care),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSeniorMemberCard(context, childrenAndInlaws[index], theme),
                childCount: childrenAndInlaws.length,
              ),
            ),
          ],

          // Section 4: Grandchildren
          if ((_seniorFilterGen == 0 || _seniorFilterGen == 4) && grandchildren.isNotEmpty) ...[
            _buildSeniorSectionHeader('4. Grandchildren / पोते-पोती व नाती-नातिन', Icons.face),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSeniorMemberCard(context, grandchildren[index], theme),
                childCount: grandchildren.length,
              ),
            ),
          ],

          // Section 5: Others
          if (_seniorFilterGen == 0 && others.isNotEmpty) ...[
            _buildSeniorSectionHeader('Other Relatives / अन्य रिश्तेदार', Icons.family_restroom),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSeniorMemberCard(context, others[index], theme),
                childCount: others.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildSeniorFilterChip(String label, int value) {
    final isSelected = _seniorFilterGen == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _seniorFilterGen = value);
        }
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSeniorSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC59B27), size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFC59B27),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFC59B27).withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeniorMemberCard(BuildContext context, MemberNode member, ThemeData theme) {
    final relTitle = member.relationshipToHead.replaceAll('_', ' ').toUpperCase();
    // ignore: unused_local_variable
    final hasMobile = member.mobile != null && member.mobile!.trim().isNotEmpty;

    // Color & Badge based on relationship
    Color badgeColor;
    IconData badgeIcon;
    switch (member.relationshipToHead.toLowerCase()) {
      case 'self':
        badgeColor = const Color(0xFFD4AF37);
        badgeIcon = Icons.stars_rounded;
        break;
      case 'father':
      case 'mother':
      case 'grandfather':
      case 'grandmother':
        badgeColor = const Color(0xFFC62828);
        badgeIcon = Icons.elderly_rounded;
        break;
      case 'spouse':
        badgeColor = const Color(0xFFAD1457);
        badgeIcon = Icons.favorite;
        break;
      case 'son':
      case 'daughter':
        badgeColor = const Color(0xFF1565C0);
        badgeIcon = Icons.child_care_rounded;
        break;
      default:
        badgeColor = const Color(0xFF2E7D32);
        badgeIcon = Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMemberActionSheet(context, member),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Member Avatar & Basic Info Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Photo / Avatar (ENLARGED to 84px for seniors)
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? Image.network(
                              member.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildSeniorAvatarFallback(member, badgeColor),
                            )
                          : _buildSeniorAvatarFallback(member, badgeColor),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name, Relation Badge, Age & Business Owner tag
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.fullName,
                                style: GoogleFonts.outfit(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (member.age > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${member.age} yrs',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Relationship Badge & Business Badge
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(badgeIcon, size: 14, color: badgeColor),
                                  const SizedBox(width: 5),
                                  Text(
                                    relTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (member.businessProfile != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_center_rounded, size: 13, color: Color(0xFFC59B27)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'BUSINESS',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFC59B27),
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
                ],
              ),
              const SizedBox(height: 12),
              
              // Rich Info Metadata Grid (Gotra, Blood Group, Education, Occupation, City)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (member.gotra != null && member.gotra!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFFC59B27)),
                          const SizedBox(width: 4),
                          Text(
                            'Gotra: ${member.gotra}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (member.bloodGroup != null && member.bloodGroup!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bloodtype, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Blood: ${member.bloodGroup}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    if (member.currentCity != null && member.currentCity!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            member.currentCity!,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (member.education != null && member.education!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_outlined, size: 14, color: Colors.purple),
                          const SizedBox(width: 4),
                          Text(
                            member.education!,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    if (member.occupationType != null && member.occupationType!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline, size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            member.occupationType!,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Compact Action Buttons Row (CALL, SMS, WHATSAPP) hidden for now
              /*
              Row(
                children: [
                  // Call Button (Compact)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasMobile ? () => _callMember(member.mobile!) : null,
                      icon: const Icon(Icons.phone_in_talk, size: 16),
                      label: Text(
                        'CALL',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        minimumSize: const Size(0, 36),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // SMS Button (Compact - Opens Native SMS app like detail screen)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasMobile ? () => _smsMember(member.mobile!) : null,
                      icon: const Icon(Icons.sms_outlined, size: 16),
                      label: Text(
                        'SMS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        minimumSize: const Size(0, 36),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // WhatsApp Button (Compact - Direct wa.me link with WhatsApp icon)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: hasMobile ? () => _whatsappMember(member.mobile!) : null,
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: Text(
                        'WHATSAPP',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        minimumSize: const Size(0, 36),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              */
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeniorAvatarFallback(MemberNode member, Color badgeColor) {
    return Container(
      color: badgeColor.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: badgeColor,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _callMember(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ignore: unused_element
  Future<void> _smsMember(String mobile) async {
    final uri = Uri(scheme: 'sms', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ignore: unused_element
  Future<void> _whatsappMember(String mobile) async {
    final cleanNum = mobile.replaceAll(RegExp(r'\D'), '');
    final numWithCountry = cleanNum.length == 10 ? '91$cleanNum' : cleanNum;
    final whatsappUri = Uri.parse('https://wa.me/$numWithCountry');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback scheme
      final fallbackUri = Uri.parse('whatsapp://send?phone=+$numWithCountry');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
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

    final double radius = 6.0;
    final double midX = size.width / 2;

    const double topDrop = 32.0;
    const double totalHeight = 48.0;

    // Compute the center X of each branch
    final List<double> centerXs = [];
    double offset = 0.0;
    for (int i = 0; i < childCount; i++) {
      final w = i < branchWidths.length ? branchWidths[i] : 160.0;
      centerXs.add(offset + w / 2);
      offset += w;
    }

    final path = Path()..moveTo(midX, 0)..lineTo(midX, topDrop);

    if (childCount == 1) {
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

    // Gold Filament Gradient Paint
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFAA771C), Color(0xFFF4D068)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw main connectors
    canvas.drawPath(path, goldPaint);

    // Draw glowing gold junction dots
    final dotPaint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.fill;
    final dotGlow = Paint()
      ..color = const Color(0xFFF4D068).withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Root drop junction dot
    canvas.drawCircle(Offset(midX, topDrop), 4.5, dotGlow);
    canvas.drawCircle(Offset(midX, topDrop), 3.0, dotPaint);

    // Branch drop junction dots
    for (final childX in centerXs) {
      canvas.drawCircle(Offset(childX, totalHeight), 4.0, dotGlow);
      canvas.drawCircle(Offset(childX, totalHeight), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return oldDelegate.childCount != childCount ||
        oldDelegate.color != color ||
        oldDelegate.branchWidths != branchWidths;
  }
}
