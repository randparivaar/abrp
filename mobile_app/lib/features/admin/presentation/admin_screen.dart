import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/name_formatter.dart';
import '../../directory/presentation/family_member_detail_screen.dart';
import '../../directory/presentation/business_profile_detail_screen.dart';
import '../../directory/presentation/family_tree_screen.dart';
import '../../directory/presentation/app_drawer.dart';
import '../../auth/presentation/auth_controller.dart';
import 'family_approval_detail_screen.dart';
import '../../events/presentation/events_provider.dart';
import '../../events/presentation/event_form_dialog.dart';
import '../../events/presentation/event_detail_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  final int initialSection;
  const AdminScreen({super.key, this.initialSection = 0});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

String _formatHumanDate(DateTime? dt) {
  if (dt == null) return '';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedTabIndex = 0;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _userSearchController = TextEditingController();

  List<dynamic> _usersList = [];
  bool _isLoadingUsers = true;
  String? _usersError;
  int _userPage = 1;
  int _totalUserPages = 1;
  int _totalUsersCount = 0;
  String _userSearchQuery = '';

  String? _selectedUserId;
  bool _isSendingNotification = false;
  String? _statusMessage;

  List<dynamic> _pendingList = [];
  bool _isLoadingPending = true;
  String? _pendingError;

  List<dynamic> _pendingFamiliesList = [];
  bool _isLoadingPendingFamilies = true;
  String? _pendingFamiliesError;

  List<dynamic> _pendingBusinessesList = [];
  bool _isLoadingPendingBusinesses = true;
  String? _pendingBusinessesError;

  List<dynamic> _regionsList = [];
  bool _isLoadingRegions = false;

  List<dynamic> _adminAdsList = [];
  bool _isLoadingAdminAds = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialSection.clamp(0, 6);
    _fetchAdminAds();
    final authState = ref.read(authProvider);
    if (authState.user?.role == 'admin') {
      _fetchUsers();
    }
    _fetchRegions();
    _fetchPendingFamilies();
    _fetchPendingMembers();
    _fetchPendingBusinesses();
  }

  Future<void> _fetchAdminAds() async {
    setState(() => _isLoadingAdminAds = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/ads/admin/all');
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _adminAdsList = response.data['ads'] as List<dynamic>;
          });
        }
      }
    } catch (_) {
      // network / timeout — loader will be reset in finally
    } finally {
      if (mounted) setState(() => _isLoadingAdminAds = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/regions');
      if (mounted) {
        setState(() {
          _regionsList = (response.data['regions'] as List<dynamic>? ?? []);
        });
      }
    } catch (_) {
      // network / timeout — loader reset in finally
    } finally {
      if (mounted) setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _showChangeRoleModal(Map<String, dynamic> userItem) async {
    if (_regionsList.isEmpty && !_isLoadingRegions) {
      await _fetchRegions();
    }

    String roleVal = (userItem['role'] as String? ?? 'member').toLowerCase();
    if (!['member', 'moderator', 'admin'].contains(roleVal)) {
      roleVal = 'member';
    }
    String selectedRole = roleVal;

    final existingAssigned = (userItem['assignedRegions'] as List<dynamic>?) ?? [];
    final Set<int> selectedRegionIds = existingAssigned
        .map<int?>((r) {
          if (r is Map && r['id'] != null) {
            return r['id'] is int ? r['id'] as int : int.tryParse(r['id'].toString());
          }
          return null;
        })
        .whereType<int>()
        .toSet();

    final lang = ref.read(languageStateProvider);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final userName = (userItem['fullName'] as String? ?? 'User').toTitleCase();
            final userEmail = userItem['email'] as String? ?? userItem['mobile'] as String? ?? '';

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(userEmail, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Role Selector Header
                    const Text('Select User Role / रोल चुनें:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildRoleChip(AppTranslations.get('role_member', lang), 'member', selectedRole, (r) => setModalState(() => selectedRole = r)),
                        const SizedBox(width: 8),
                        _buildRoleChip(AppTranslations.get('role_coordinator', lang), 'moderator', selectedRole, (r) => setModalState(() => selectedRole = r)),
                        const SizedBox(width: 8),
                        _buildRoleChip(AppTranslations.get('role_admin', lang), 'admin', selectedRole, (r) => setModalState(() => selectedRole = r)),
                      ],
                    ),

                    // Zones / Regions Selector (if moderator selected)
                    if (selectedRole == 'moderator') ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Assign Regions / Zones to Moderate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('${selectedRegionIds.length} Selected', style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isLoadingRegions)
                        const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                      else if (_regionsList.isEmpty)
                        const Text('No regions available in system.', style: TextStyle(color: Colors.grey))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _regionsList.map((reg) {
                            final regId = reg['id'] is int ? reg['id'] as int : int.parse(reg['id'].toString());
                            final regName = reg['name'] as String? ?? 'Zone $regId';
                            final isSelected = selectedRegionIds.contains(regId);

                            return FilterChip(
                              label: Text(regName),
                              selected: isSelected,
                              selectedColor: Colors.indigo.shade100,
                              checkmarkColor: Colors.indigo.shade900,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.indigo.shade900 : theme.colorScheme.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                setModalState(() {
                                  if (val) {
                                    selectedRegionIds.add(regId);
                                  } else {
                                    selectedRegionIds.remove(regId);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _updateUserRole(
                            userItem['id'] as String,
                            selectedRole,
                            selectedRole == 'moderator' ? selectedRegionIds.toList() : null,
                          );
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Save User Role & Permissions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleChip(String label, String value, String currentSelected, ValueChanged<String> onSelect) {
    final isSelected = value == currentSelected;
    final color = value == 'admin' ? Colors.red : value == 'moderator' ? Colors.indigo : Colors.teal;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String userId, String newRole, List<int>? regionIds) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch('/users/change-role', data: {
        'userId': userId,
        'newRole': newRole,
        'regionIds': regionIds,
      });

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User role updated successfully!')),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $e')),
        );
      }
    }
  }

  Future<void> _fetchUsers({String? query, int? page}) async {
    final search = query ?? _userSearchQuery;
    final currentPage = page ?? _userPage;

    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/users', queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'page': currentPage,
        'limit': 10,
      });

      final data = response.data;
      if (mounted) {
        setState(() {
          _usersList = (data['users'] as List<dynamic>? ?? []);
          _totalUsersCount = data['totalCount'] as int? ?? _usersList.length;
          _totalUserPages = data['totalPages'] as int? ?? 1;
          _userPage = currentPage;
          _userSearchQuery = search;
          _usersError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _usersError = 'Failed to load users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _fetchPendingFamilies() async {
    setState(() {
      _isLoadingPendingFamilies = true;
      _pendingFamiliesError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending-families');
      if (mounted) {
        setState(() {
          _pendingFamiliesList = (response.data['pendingFamilies'] as List<dynamic>? ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingFamiliesError = 'Failed to load pending families: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPendingFamilies = false);
    }
  }

  Future<bool> _approveFamily(int familyId, String familyCode) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/family/$familyId/approve');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Family $familyCode approved successfully!')),
          );
        }
        _fetchPendingFamilies();
        _fetchPendingMembers();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family approval failed: $e')),
        );
      }
    }
    return false;
  }

  Future<bool> _rejectFamily(int familyId, String familyCode, String reason) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/family/$familyId/reject', data: {
        'reason': reason.isNotEmpty ? reason : null,
      });
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Family $familyCode rejected.')),
          );
        }
        _fetchPendingFamilies();
        _fetchPendingMembers();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Family rejection failed: $e')),
        );
      }
    }
    return false;
  }

  Future<void> _fetchPendingMembers() async {
    setState(() {
      _isLoadingPending = true;
      _pendingError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending');
      if (mounted) {
        setState(() {
          _pendingList = (response.data['pendingMembers'] as List<dynamic>? ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingError = 'Failed to load pending approvals: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<bool> _approveMember(int memberId, String fullName) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/member/$memberId/approve');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fullName has been approved.')),
          );
        }
        _fetchPendingMembers();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
    return false;
  }

  Future<bool> _rejectMember(int memberId, String fullName) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('Reject $fullName?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please specify a reason for rejecting this member entry (optional).'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  hintText: 'e.g. Duplicate entry',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('REJECT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/member/$memberId/reject', data: {
        'reason': reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
      });
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fullName has been rejected.')),
          );
        }
        _fetchPendingMembers();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    }
    return false;
  }

  Future<void> _fetchPendingBusinesses() async {
    setState(() {
      _isLoadingPendingBusinesses = true;
      _pendingBusinessesError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending-businesses');
      if (mounted) {
        setState(() {
          _pendingBusinessesList = (response.data['pendingBusinesses'] as List<dynamic>? ?? []);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pendingBusinessesError = 'Failed to load pending businesses: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPendingBusinesses = false);
    }
  }

  Future<bool> _approveBusiness(int businessId, String businessName) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/business/$businessId/approve');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$businessName has been approved.')),
          );
        }
        _fetchPendingBusinesses();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
    return false;
  }

  Future<bool> _rejectBusiness(int businessId, String businessName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final theme = Theme.of(dialogCtx);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text('Reject $businessName?'),
          content: const Text('Are you sure you want to reject and delete this business profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('REJECT', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return false;

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/directory/moderation/business/$businessId/reject');
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$businessName has been rejected.')),
          );
        }
        _fetchPendingBusinesses();
        return true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    }
    return false;
  }

  Future<void> _sendTestNotification() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipient user.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out Title and Message.')),
      );
      return;
    }

    setState(() {
      _isSendingNotification = true;
      _statusMessage = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/notifications/send-test', data: {
        'targetUserId': _selectedUserId,
        'title': title,
        'body': body,
      });

      setState(() {
        _isSendingNotification = false;
        _statusMessage = response.data['message'] ?? 'Notification dispatched.';
      });
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      setState(() {
        _isSendingNotification = false;
        _statusMessage = 'Failed to dispatch notification: $e';
      });
    }
  }

  Widget _buildUsersTab() {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Bar & Stats Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search by Name, Email, or Mobile...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _userSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _userSearchController.clear();
                        _fetchUsers(query: '', page: 1);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              _fetchUsers(query: val, page: 1);
            },
          ),
        ),

        // Summary Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Registered: $_totalUsersCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Page $_userPage of $_totalUserPages',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Users List Content
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _usersError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_usersError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetchUsers(page: _userPage),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _usersList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('No registered members found.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _usersList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _usersList[index] as Map<String, dynamic>;
                        final role = (item['role'] as String? ?? 'member').toLowerCase();
                        final assignedRegs = (item['assignedRegions'] as List<dynamic>?) ?? [];
                        final regNames = assignedRegs.map((r) => r['name'] as String).toList();

                        final roleColor = role == 'admin'
                            ? Colors.red
                            : role == 'moderator'
                                ? Colors.indigo
                                : theme.colorScheme.primary;

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundImage: item['avatarUrl'] != null ? NetworkImage(item['avatarUrl'] as String) : null,
                                      backgroundColor: roleColor.withValues(alpha: 0.1),
                                      child: item['avatarUrl'] == null
                                          ? Text(
                                              (item['fullName'] as String? ?? 'U')[0].toUpperCase(),
                                              style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (item['fullName'] as String? ?? '').toTitleCase(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['email'] as String? ?? item['mobile'] as String? ?? 'No contact info',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: roleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: roleColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (role == 'moderator') ...[
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 16, color: Colors.indigo.shade700),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: regNames.isNotEmpty
                                            ? Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: regNames
                                                    .map((name) => Chip(
                                                          label: Text(name, style: const TextStyle(fontSize: 11, color: Colors.indigo)),
                                                          backgroundColor: Colors.indigo.shade50,
                                                          visualDensity: VisualDensity.compact,
                                                          padding: EdgeInsets.zero,
                                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                        ))
                                                    .toList(),
                                              )
                                            : const Text(
                                                '⚠️ No Area/Zone Assigned',
                                                style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w600),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showChangeRoleModal(item),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Edit Role & Assigned Zones'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Pagination Controls
        if (_totalUserPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _userPage > 1 ? () => _fetchUsers(page: _userPage - 1) : null,
                  icon: const Icon(Icons.arrow_back_ios, size: 14),
                  label: const Text('Previous'),
                ),
                Text('Page $_userPage / $_totalUserPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _userPage < _totalUserPages ? () => _fetchUsers(page: _userPage + 1) : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 14),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationsTab(AppLanguage lang) {
    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            AppTranslations.get('send_test_push', lang),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Target User Dropdown
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Recipient Member',
            ),
            initialValue: _selectedUserId,
            items: _usersList.map<DropdownMenuItem<String>>((user) {
              return DropdownMenuItem<String>(
                value: user['id'] as String,
                child: Text(
                  '${user['fullName'] ?? ''} (${user['role']})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedUserId = val);
            },
          ),
          const SizedBox(height: 16),
          
          // Title Textbox
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Notification Title',
              hintText: 'e.g. Samaj Bulletin Update',
            ),
          ),
          const SizedBox(height: 16),
          
          // Body Textbox
          TextField(
            controller: _bodyController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message Body',
              hintText: 'Type your message text here...',
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Button
          _isSendingNotification
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Notification'),
                ),
          
          if (_statusMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _statusMessage!.startsWith('Failed') ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusMessage!.startsWith('Failed') ? Colors.red.shade200 : Colors.green.shade200),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Failed') ? Colors.red.shade800 : Colors.green.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildApprovalsTab() {
    final theme = Theme.of(context);
    if (_isLoadingPending) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pendingError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingMembers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no pending member approvals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _pendingList[index];
        final id = item['id'] as int;
        final name = item['fullName'] as String;
        final relation = item['relationshipToHead'] as String;
        final gender = item['gender'] as String;
        final familyCode = item['familyCode'] as String;
        final address = item['address'] as String;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final familyId = item['familyId'] as int;
              final member = MemberNode(
                id: id,
                familyId: familyId,
                fullName: name,
                gender: gender,
                relationshipToHead: relation,
                mobile: item['mobile'] as String?,
                gotra: item['gotra'] as String?,
                estimatedAgeOnCreation: item['estimatedAgeOnCreation'] as int?,
                birthDate: item['birthDate'] != null ? DateTime.tryParse(item['birthDate'].toString()) : null,
                education: item['education'] as String?,
                occupationType: item['occupationType'] as String?,
                occupationDetail: item['occupationDetail'] as String?,
                yearlyIncome: item['yearlyIncome'] as int?,
                fatherId: item['fatherId'] as int?,
                motherId: item['motherId'] as int?,
                spouseId: item['spouseId'] as int?,
                status: item['status'] as String? ?? 'pending',
                bloodGroup: item['bloodGroup'] as String?,
                maritalStatus: item['maritalStatus'] as String?,
                anniversaryDate: item['anniversaryDate'] != null ? DateTime.tryParse(item['anniversaryDate'].toString()) : null,
                currentAddress: item['currentAddress'] as String?,
                currentCity: item['currentCity'] as String?,
                currentState: item['currentState'] as String?,
                currentPincode: item['currentPincode'] as String?,
                avatarUrl: item['avatarUrl'] as String?,
                specialRemarks: item['specialRemarks'] as String?,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyMemberDetailScreen(
                    member: member,
                    familyMembers: [member],
                    familyId: familyId,
                    isPending: true,
                    onApprove: () => _approveMember(id, name),
                    onReject: () => _rejectMember(id, name),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name.toTitleCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              relation.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Gender: ${gender.toUpperCase()}'),
                  Text('Family Code: $familyCode'),
                  Text('Location: $address'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Tap card to view full details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectMember(id, name),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _approveMember(id, name),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
  }

  Widget _buildBusinessApprovalsTab() {
    final theme = Theme.of(context);
    if (_isLoadingPendingBusinesses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingBusinessesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pendingBusinessesError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingBusinesses,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingBusinessesList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no pending business approvals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingBusinessesList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _pendingBusinessesList[index];
        final id = item['id'] as int;
        final businessName = item['businessName'] as String;
        final industryCategory = item['industryCategory'] as String;
        final contactMobile = item['contactMobile'] as String;
        final email = item['email'] as String?;
        final websiteUrl = item['websiteUrl'] as String?;
        final address = item['locationAddress'] as String?;
        final city = item['locationCity'] as String?;
        final state = item['locationState'] as String?;
        final pincode = item['locationPincode'] as String?;
        final ownerName = item['ownerName'] as String?;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        String fullAddress = '';
        if (address != null && address.isNotEmpty) {
          fullAddress = address;
          if (city != null && city.isNotEmpty) fullAddress += ', $city';
          if (state != null && state.isNotEmpty) fullAddress += ', $state';
          if (pincode != null && pincode.isNotEmpty) fullAddress += ' - $pincode';
        }

        return Card(
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              final bp = BusinessProfile(
                id: id,
                businessName: businessName,
                industryCategory: industryCategory,
                contactMobile: contactMobile,
                email: email,
                websiteUrl: websiteUrl,
                description: item['description'] as String?,
                address: address ?? '',
                city: city ?? '',
                state: state,
                pincode: pincode,
              );
              MemberNode? ownerNode;
              if (ownerName != null && ownerName.isNotEmpty && item['ownerId'] != null) {
                ownerNode = MemberNode(
                  id: item['ownerId'] as int,
                  familyId: -1,
                  fullName: ownerName,
                  gender: '',
                  relationshipToHead: 'self',
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessProfileDetailScreen(
                    business: bp,
                    owner: ownerNode,
                    isPending: true,
                    onApprove: () => _approveBusiness(id, businessName),
                    onReject: () => _rejectBusiness(id, businessName),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          businessName.toTitleCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              industryCategory.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (ownerName != null && ownerName.isNotEmpty) ...[
                    Text('Owner: $ownerName'),
                    const SizedBox(height: 4),
                  ],
                  Text('Mobile: $contactMobile'),
                  if (email != null && email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Email: $email'),
                  ],
                  if (websiteUrl != null && websiteUrl.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Website: $websiteUrl'),
                  ],
                  if (fullAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Address: $fullAddress'),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Tap card to view full details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectBusiness(id, businessName),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Reject', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _approveBusiness(id, businessName),
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Approve', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
  }

  Widget _buildFamilyApprovalsTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = ref.watch(languageStateProvider);

    if (_isLoadingPendingFamilies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingFamiliesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_pendingFamiliesError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchPendingFamilies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pendingFamiliesList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no pending family approvals.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final isModerator = ref.watch(authProvider).user?.role == 'moderator';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingFamiliesList.length + (isModerator ? 1 : 0),
      itemBuilder: (context, index) {
        if (isModerator && index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Colors.indigo.shade700, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppTranslations.get('coordinator_view_banner', lang),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.indigo.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final realIndex = isModerator ? index - 1 : index;
        final family = _pendingFamiliesList[realIndex] as Map<String, dynamic>;
        final familyId = family['familyId'] as int;
        final familyCode = family['familyCode'] as String;
        final headName = (family['headName'] as String? ?? '').toTitleCase();
        final villageName = family['villageName'] as String? ?? '';
        final regionName = family['regionName'] as String? ?? '';
        final totalMembers = family['totalMembers'] as int? ?? 0;
        final pendingCount = family['pendingCount'] as int? ?? 0;
        final rejectedCount = family['rejectedCount'] as int? ?? 0;

        return Card(
          elevation: 2,
          color: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FamilyApprovalDetailScreen(
                    familyData: family,
                    onApprove: () => _approveFamily(familyId, familyCode),
                    onReject: (reason) => _rejectFamily(familyId, familyCode, reason),
                  ),
                ),
              ).then((_) {
                _fetchPendingFamilies();
                _fetchPendingMembers();
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          familyCode,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalMembers Members',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right, size: 20, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$villageName ($regionName)',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (pendingCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$pendingCount Pending',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (rejectedCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$rejectedCount Rejected',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'See full family details',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
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
  }

  Widget _buildAdvertisementsTab(AppLanguage lang) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ad Manager (${_adminAdsList.length})',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage active multi-placement community banners',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Ads',
                    onPressed: _fetchAdminAds,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingAdminAds)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_adminAdsList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined, size: 56, color: colorScheme.primary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text('No Active Campaigns', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the "+" button below to launch a new advertisement campaign.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ..._adminAdsList.map((adItem) {
                  final adId = adItem['id'] as int;
                  final title = adItem['title'] as String? ?? '';
                  final category = adItem['category'] as String? ?? 'General';
                  final isActive = adItem['isActive'] as bool? ?? true;
                  final priority = adItem['priority'] as int? ?? 0;
                  final placements = (adItem['placements'] as List<dynamic>?)?.cast<String>() ?? [];
                  final tagline = adItem['tagline'] as String?;
                  final imageUrl = adItem['imageUrl'] as String?;
                  final location = adItem['location'] as String?;
                  final contactMobile = adItem['contactMobile'] as String?;
                  final whatsappMobile = adItem['whatsappMobile'] as String?;
                  final targetUrl = adItem['targetUrl'] as String?;
                  final startDate = adItem['startDate'] != null ? DateTime.tryParse(adItem['startDate'].toString()) : null;
                  final endDate = adItem['endDate'] != null ? DateTime.tryParse(adItem['endDate'].toString()) : null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isActive ? Colors.green.shade400 : colorScheme.outlineVariant,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null && imageUrl.trim().isNotEmpty)
                            Container(
                              height: 140,
                              width: double.infinity,
                              color: Colors.grey.shade200,
                              child: Image.network(
                                imageUrl.trim(),
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_outlined, color: Colors.grey.shade500),
                                        const SizedBox(height: 4),
                                        Text('Image load error', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
                                            size: 14,
                                            color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isActive ? 'ACTIVE' : 'INACTIVE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isActive ? Colors.green.shade900 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Priority: $priority',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.indigo),
                                      tooltip: 'Edit Campaign',
                                      onPressed: () => _showAdFormModal(ad: adItem),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: 'Delete Campaign',
                                      onPressed: () => _deleteAd(adId, title),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Text(
                                  title,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 17, color: colorScheme.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                      ),
                                    ),
                                    if (location != null && location.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 2),
                                      Text(
                                        location,
                                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ],
                                ),

                                if (tagline != null && tagline.trim().isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_offer_outlined, size: 16, color: Colors.green.shade800),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            tagline,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if ((contactMobile != null && contactMobile.isNotEmpty) ||
                                    (whatsappMobile != null && whatsappMobile.isNotEmpty) ||
                                    (targetUrl != null && targetUrl.isNotEmpty) ||
                                    startDate != null || endDate != null) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      if (startDate != null || endDate != null)
                                        Chip(
                                          avatar: const Icon(Icons.date_range, size: 14, color: Colors.deepOrange),
                                          label: Text(
                                            'Period: ${startDate != null ? _formatHumanDate(startDate) : 'Immediate'} - ${endDate != null ? _formatHumanDate(endDate) : 'Indefinite'}',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (contactMobile != null && contactMobile.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.phone, size: 14, color: Colors.blue),
                                          label: Text(contactMobile, style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (whatsappMobile != null && whatsappMobile.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.chat, size: 14, color: Colors.green),
                                          label: Text(whatsappMobile, style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      if (targetUrl != null && targetUrl.isNotEmpty)
                                        Chip(
                                          avatar: const Icon(Icons.language, size: 14, color: Colors.purple),
                                          label: Text(targetUrl, style: const TextStyle(fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.layers_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Target Placements:',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: placements.map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.indigo.shade200),
                                      ),
                                      child: Text(
                                        p,
                                        style: TextStyle(fontSize: 11, color: Colors.indigo.shade900, fontWeight: FontWeight.w600),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),

        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            onPressed: () => _showAdFormModal(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Ad Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Future<void> _deleteAd(int adId, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Advertisement?'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dio = ref.read(apiClientProvider);
        await dio.delete('/ads/admin/$adId');
        _fetchAdminAds();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting ad: $e')));
        }
      }
    }
  }

  Future<void> _showAdFormModal({Map<String, dynamic>? ad}) async {
    final isEdit = ad != null;
    final titleCtrl = TextEditingController(text: ad?['title'] as String? ?? '');
    final taglineCtrl = TextEditingController(text: ad?['tagline'] as String? ?? '');
    final categoryCtrl = TextEditingController(text: ad?['category'] as String? ?? 'General');
    final targetUrlCtrl = TextEditingController(text: ad?['targetUrl'] as String? ?? '');
    final contactCtrl = TextEditingController(text: ad?['contactMobile'] as String? ?? '');
    final whatsappCtrl = TextEditingController(text: ad?['whatsappMobile'] as String? ?? '');
    final locationCtrl = TextEditingController(text: ad?['location'] as String? ?? '');
    final imageUrlCtrl = TextEditingController(text: ad?['imageUrl'] as String? ?? '');
    int priority = ad?['priority'] as int? ?? 0;
    bool isActive = ad?['isActive'] as bool? ?? true;
    DateTime? startDate = ad?['startDate'] != null ? DateTime.tryParse(ad!['startDate'].toString()) : null;
    DateTime? endDate = ad?['endDate'] != null ? DateTime.tryParse(ad!['endDate'].toString()) : null;

    final availablePlacements = [
      'home_carousel',
      'home_bottom_banner',
      'directory_header',
      'directory_feed',
      'business_native_catalog',
      'events_gallery',
      'community_feed',
    ];

    final Set<String> selectedPlacements = (ad?['placements'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toSet() ??
        {'home_carousel', 'directory_feed'};

    bool isUploading = false;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Material(
              color: Theme.of(modalCtx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit ? 'Edit Advertisement' : 'Create New Advertisement',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title / Business Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: taglineCtrl,
                      decoration: const InputDecoration(labelText: 'Tagline or Offer Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(labelText: 'Category (e.g. Textiles, Healthcare, Food) *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text('Image Banner:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (imageUrlCtrl.text.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Image.network(
                            imageUrlCtrl.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Center(child: Text('Invalid image URL')),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: imageUrlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Image Banner URL',
                              border: OutlineInputBorder(),
                              hintText: 'https://...',
                            ),
                            onChanged: (v) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : () async {
                            try {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                              if (image == null) return;

                              setModalState(() => isUploading = true);

                              final filename = 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              const contentType = 'image/jpeg';

                              final dio = ref.read(apiClientProvider);
                              final presignedResponse = await dio.post('/upload/presigned-url', data: {
                                'filename': filename,
                                'contentType': contentType,
                              });

                              final uploadUrl = presignedResponse.data['uploadUrl'] as String;
                              final publicUrl = presignedResponse.data['publicUrl'] as String;

                              final bytes = await image.readAsBytes();
                              final uploadDio = Dio();
                              await uploadDio.put(
                                uploadUrl,
                                data: Stream.fromIterable([bytes]),
                                options: Options(
                                  headers: {
                                    'Content-Type': contentType,
                                    'Content-Length': bytes.length,
                                  },
                                ),
                              );

                              setModalState(() {
                                imageUrlCtrl.text = publicUrl;
                                isUploading = false;
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Banner image uploaded successfully!')),
                                );
                              }
                            } catch (e) {
                              setModalState(() => isUploading = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Image upload failed: $e')),
                                );
                              }
                            }
                          },
                          icon: isUploading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.upload_file, size: 18),
                          label: Text(isUploading ? 'Uploading...' : 'Upload'),
                          style: ElevatedButton.styleFrom(
                            // Override theme's minimumSize (which may be Size(∞, 48)) to prevent
                            // infinite-width crash when button is inside a Row.
                            minimumSize: const Size(90, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text('Target Placements (Multi-Select):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: availablePlacements.map((placementKey) {
                        final isSelected = selectedPlacements.contains(placementKey);
                        return FilterChip(
                          label: Text(placementKey, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedPlacements.add(placementKey);
                              } else {
                                selectedPlacements.remove(placementKey);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: contactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Contact Mobile', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: whatsappCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'WhatsApp Mobile', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'City / Location', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetUrlCtrl,
                      decoration: const InputDecoration(labelText: 'Target Website URL', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),

                    const Text('Time Period / Active Duration (Optional):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              startDate != null
                                  ? 'Start: ${_formatHumanDate(startDate)}'
                                  : 'Start Date',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                          ),
                        ),
                        if (startDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setModalState(() => startDate = null),
                          ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event, size: 16),
                            label: Text(
                              endDate != null
                                  ? 'End: ${_formatHumanDate(endDate)}'
                                  : 'End Date',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: modalCtx,
                                initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                        if (endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () => setModalState(() => endDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text('Active Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Switch(
                          value: isActive,
                          onChanged: (val) => setModalState(() => isActive = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || selectedPlacements.isEmpty) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Please provide title and select at least one placement.')),
                            );
                            return;
                          }

                          final payload = {
                            'title': titleCtrl.text.trim(),
                            'tagline': taglineCtrl.text.trim(),
                            'category': categoryCtrl.text.trim(),
                            'imageUrl': imageUrlCtrl.text.trim(),
                            'placements': selectedPlacements.toList(),
                            'contactMobile': contactCtrl.text.trim(),
                            'whatsappMobile': whatsappCtrl.text.trim(),
                            'location': locationCtrl.text.trim(),
                            'targetUrl': targetUrlCtrl.text.trim(),
                            'isActive': isActive,
                            'priority': priority,
                            'startDate': startDate?.toIso8601String(),
                            'endDate': endDate?.toIso8601String(),
                          };

                          try {
                            final dio = ref.read(apiClientProvider);
                            if (isEdit) {
                              await dio.put('/ads/admin/${ad['id']}', data: payload);
                            } else {
                              await dio.post('/ads/admin/create', data: payload);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _fetchAdminAds();
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error saving ad: $e')));
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: Text(isEdit ? 'Update Campaign' : 'Publish Campaign', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  String _mon(int m) => _months[m.clamp(1, 12)];

  void _refreshAdminEvents() {
    ref.invalidate(adminEventsProvider);
    ref.invalidate(activeEventsProvider);
  }

  Widget _buildEventsManagementTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final adminEventsAsync = ref.watch(adminEventsProvider);
    final eventsService = ref.read(eventsServiceProvider);

    return RefreshIndicator(
      onRefresh: () async => _refreshAdminEvents(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Community Events',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      adminEventsAsync.when(
                        data: (list) => Text(
                          '${list.length} total · ${list.where((e) => e.isActive).length} active',
                          style: GoogleFonts.inter(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _refreshAdminEvents,
                ),
                FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => EventFormDialog(
                        onSuccess: () {
                          _refreshAdminEvents();
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Event'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── List ────────────────────────────────────────────────
            adminEventsAsync.when(
              data: (eventsList) {
                if (eventsList.isEmpty) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy_rounded, size: 56,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No events yet.',
                              style: GoogleFonts.inter(
                                  fontSize: 15, fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Text('Tap "Add Event" to create the first one.',
                              style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: eventsList.map((eventItem) {
                    final hasAlbum = eventItem.externalAlbumUrl?.isNotEmpty == true;
                    final galleryCount = eventItem.galleryUrls.length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: eventItem.isActive
                              ? Colors.green.withValues(alpha: 0.4)
                              : colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: thumbnail + info + menu
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: (eventItem.imageUrl?.isNotEmpty == true)
                                      ? Image.network(
                                          eventItem.imageUrl!,
                                          width: 60, height: 60, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _eventPlaceholder(colorScheme),
                                        )
                                      : _eventPlaceholder(colorScheme),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(eventItem.title,
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Builder(builder: (_) {
                                        final d = eventItem.eventDate;
                                        final e = eventItem.endDate;
                                        final isMulti = e != null &&
                                            !(e.year == d.year && e.month == d.month && e.day == d.day);
                                        final dateStr = isMulti
                                            ? '📅 ${d.day} ${_mon(d.month)} → ${e.day} ${_mon(e.month)} ${e.year}'
                                            : '📅 ${d.day} ${_mon(d.month)} ${d.year}';
                                        final days = isMulti ? e.difference(d).inDays + 1 : null;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dateStr +
                                                  (eventItem.venue?.isNotEmpty == true
                                                      ? '  ·  📍${eventItem.venue}'
                                                      : ''),
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: colorScheme.onSurfaceVariant),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (days != null) ...[ 
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primaryContainer,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$days-Day Event',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        );
                                      }),
                                      if (galleryCount > 0 || hasAlbum) ...[
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 4,
                                          children: [
                                            if (galleryCount > 0)
                                              _miniChip('$galleryCount photos', Icons.photo_library_outlined),
                                            if (hasAlbum)
                                              _miniChip('Album', Icons.link_rounded,
                                                  color: const Color(0xFF4285F4)),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => EventFormDialog(
                                          eventToEdit: eventItem,
                                          onSuccess: _refreshAdminEvents,
                                        ),
                                      );
                                    } else if (action == 'view') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EventDetailScreen(event: eventItem),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text('Delete "${eventItem.title}"?'),
                                          content: const Text(
                                              'This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel')),
                                            FilledButton(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor: colorScheme.error),
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (ok == true && mounted) {
                                        final deleted =
                                            await eventsService.deleteEvent(eventItem.id);
                                        if (!mounted) return;
                                        if (deleted) {
                                          _refreshAdminEvents();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text('Event deleted.')),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Delete failed. Try again.')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'view',
                                        child: Row(children: [
                                          Icon(Icons.visibility_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('View')
                                        ])),
                                    const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit')
                                        ])),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline,
                                              size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete',
                                              style: TextStyle(color: Colors.red))
                                        ])),
                                  ],
                                ),
                              ],
                            ),

                            const Divider(height: 16),

                            // Status toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: eventItem.isActive
                                            ? Colors.green
                                            : Colors.red.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      eventItem.isActive
                                          ? 'Active — Visible to members'
                                          : 'Inactive — Hidden from feed',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: eventItem.isActive
                                            ? Colors.green.shade700
                                            : Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch.adaptive(
                                  value: eventItem.isActive,
                                  activeTrackColor: Colors.green,
                                  onChanged: (newVal) async {
                                    final ok = await eventsService.toggleEventStatus(
                                        eventItem.id,
                                        isActive: newVal);
                                    if (!mounted) return;
                                    if (ok) {
                                      _refreshAdminEvents();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(newVal
                                              ? 'Event activated.'
                                              : 'Event deactivated.'),
                                          backgroundColor:
                                              newVal ? Colors.green : Colors.red.shade700,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Failed to update status.')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator())),
              error: (err, _) => SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load events',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _refreshAdminEvents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventPlaceholder(ColorScheme cs) => Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.campaign_rounded, color: cs.primary, size: 28),
      );

  Widget _miniChip(String label, IconData icon, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: (color ?? Colors.grey).withValues(alpha: 0.4), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: color ?? Colors.grey.shade700,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );


  // ─── Dashboard overview tab ──────────────────────────────────────────────
  Widget _buildDashboardTab(AppLanguage lang, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Admin';
    final userRole = authState.user?.role ?? 'admin';
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Family Approvals',
        'subtitle': 'Review submitted family records',
        'icon': Icons.groups_rounded,
        'badge': _pendingFamiliesList.length,
        'color': const Color(0xFF1976D2),
        'tab': 1,
      },
      {
        'title': 'Business Approvals',
        'subtitle': 'Approve community business profiles',
        'icon': Icons.business_center_rounded,
        'badge': _pendingBusinessesList.length,
        'color': const Color(0xFFE65100),
        'tab': 2,
      },
      if (isAdmin) ...[
        {
          'title': 'Events & Bulletins',
          'subtitle': 'Manage events, galleries & albums',
          'icon': Icons.event_available_rounded,
          'badge': 0,
          'color': const Color(0xFF2E7D32),
          'tab': 3,
        },
        {
          'title': 'Ad Campaigns',
          'subtitle': 'Create & manage promotions',
          'icon': Icons.campaign_rounded,
          'badge': _adminAdsList.length,
          'color': const Color(0xFF6A1B9A),
          'tab': 4,
        },
        {
          'title': 'User & Roles',
          'subtitle': 'Manage coordinators & permissions',
          'icon': Icons.manage_accounts_rounded,
          'badge': 0,
          'color': const Color(0xFF283593),
          'tab': 5,
        },
        {
          'title': 'Notifications',
          'subtitle': 'Broadcast messages to members',
          'icon': Icons.notifications_active_rounded,
          'badge': 0,
          'color': const Color(0xFF00695C),
          'tab': isAdmin ? 6 : 3,
        },
      ] else ...[
        {
          'title': 'Notifications',
          'subtitle': 'Broadcast messages to members',
          'icon': Icons.notifications_active_rounded,
          'badge': 0,
          'color': const Color(0xFF00695C),
          'tab': 3,
        },
      ],
    ];

    final totalPending = _pendingFamiliesList.length + _pendingBusinessesList.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome card ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [colorScheme.primary.withValues(alpha: 0.3), colorScheme.primaryContainer.withValues(alpha: 0.2)]
                    : [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                    style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8))),
                      Text(userName,
                          style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          userRole.toUpperCase(),
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Pending alerts row ──────────────────────────────────
          if (totalPending > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending_actions_rounded,
                      color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$totalPending pending approval${totalPending == 1 ? '' : 's'} require your attention.',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Stats row ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _dashStatCard(
                  label: 'Pending Families',
                  value: '${_pendingFamiliesList.length}',
                  icon: Icons.family_restroom_rounded,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dashStatCard(
                  label: 'Pending Businesses',
                  value: '${_pendingBusinessesList.length}',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFFE65100),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _dashStatCard(
                    label: 'Ad Campaigns',
                    value: '${_adminAdsList.length}',
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ── Module grid ────────────────────────────────────────
          Text('Admin Modules',
              style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (_, i) {
              final m = modules[i];
              final color = m['color'] as Color;
              final badge = m['badge'] as int;
              return _dashModuleCard(
                title: m['title'] as String,
                subtitle: m['subtitle'] as String,
                icon: m['icon'] as IconData,
                color: color,
                badge: badge,
                onTap: () => setState(() => _selectedTabIndex = m['tab'] as int),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _dashModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int badge,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                color.withValues(alpha: 0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.2,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Main build ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageStateProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == 'admin';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Build tab list lazily — only define metadata here, build body on demand
    final List<({IconData icon, String label, int badge})> tabs = [
      (icon: Icons.dashboard_rounded, label: 'Dashboard', badge: 0),
      (icon: Icons.groups_rounded, label: 'Families', badge: _pendingFamiliesList.length),
      (icon: Icons.business_center_rounded, label: 'Businesses', badge: _pendingBusinessesList.length),
      if (isAdmin) (icon: Icons.event_available_rounded, label: 'Events', badge: 0),
      if (isAdmin) (icon: Icons.campaign_rounded, label: 'Ads', badge: _adminAdsList.length),
      if (isAdmin) (icon: Icons.manage_accounts_rounded, label: 'Users', badge: _totalUsersCount),
      (icon: Icons.notifications_rounded, label: 'Notifications', badge: 0),
    ];

    // Clamp index if tabs count changed (role switch)
    if (_selectedTabIndex >= tabs.length) {
      _selectedTabIndex = 0;
    }

    // Tab titles
    final tabTitles = [
      'Dashboard',
      'Family Approvals',
      'Business Approvals',
      if (isAdmin) 'Events & Bulletins',
      if (isAdmin) 'Ad Campaigns',
      if (isAdmin) 'User & Coordinator Roles',
      'Dispatch Notifications',
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          tabTitles[_selectedTabIndex.clamp(0, tabTitles.length - 1)],
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                ((authState.user?.fullName ?? '').isNotEmpty
                        ? (authState.user?.fullName ?? 'A')[0]
                        : 'A')
                    .toUpperCase(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // ── NavigationRail ─────────────────────────────────────
          NavigationRail(
            selectedIndex: _selectedTabIndex,
            onDestinationSelected: (i) =>
                setState(() => _selectedTabIndex = i),
            labelType: NavigationRailLabelType.all,
            minWidth: 72,
            groupAlignment: -1.0,
            backgroundColor: isDark
                ? colorScheme.surface
                : colorScheme.surfaceContainerLowest,
            selectedIconTheme: IconThemeData(color: colorScheme.primary),
            unselectedIconTheme: IconThemeData(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            selectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary),
            unselectedLabelTextStyle: GoogleFonts.inter(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
            destinations: tabs.map((t) {
              final hasBadge = t.badge > 0;
              return NavigationRailDestination(
                icon: hasBadge
                    ? Badge(
                        label: Text('${t.badge}',
                            style: const TextStyle(fontSize: 8)),
                        child: Icon(t.icon),
                      )
                    : Icon(t.icon),
                selectedIcon: hasBadge
                    ? Badge(
                        label: Text('${t.badge}',
                            style: const TextStyle(fontSize: 8)),
                        child: Icon(t.icon),
                      )
                    : Icon(t.icon),
                label: Text(t.label),
              );
            }).toList(),
          ),

          // ── Vertical divider ───────────────────────────────────
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),

          // ── Tab body ───────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildDashboardTab(lang, isAdmin),
                _buildFamilyApprovalsTab(),
                _buildBusinessApprovalsTab(),
                if (isAdmin) _buildEventsManagementTab(),
                if (isAdmin) _buildAdvertisementsTab(lang),
                if (isAdmin) _buildUsersTab(),
                _buildNotificationsTab(lang),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
