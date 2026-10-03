import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/name_formatter.dart';
import '../../../auth/presentation/auth_controller.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTotalCountChanged;

  const AdminUsersTab({
    super.key,
    this.onTotalCountChanged,
  });

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final _userSearchController = TextEditingController();

  List<dynamic> _usersList = [];
  bool _isLoadingUsers = true;
  String? _usersError;
  int _userPage = 1;
  int _totalUserPages = 1;
  int _totalUsersCount = 0;
  String _userSearchQuery = '';

  List<dynamic> _regionsList = [];
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchRegions();
  }

  @override
  void dispose() {
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
    } finally {
      if (mounted) setState(() => _isLoadingRegions = false);
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
        widget.onTotalCountChanged?.call(_totalUsersCount);
      }
    } catch (e) {
      if (mounted) setState(() => _usersError = 'Failed to load users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
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

  Future<void> _updateStatusDirect(String userId, String newStatus) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch('/users/change-status', data: {
        'userId': userId,
        'status': newStatus,
      });

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to ${newStatus.toUpperCase()}.'),
            backgroundColor: newStatus == 'suspended'
                ? Colors.red
                : (newStatus == 'inactive' ? Colors.orange.shade800 : Colors.green),
          ),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _deleteUserByAdmin(String userId, String userName) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.delete('/users/$userId');
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account for "$userName" deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteUserByAdmin(Map<String, dynamic> userItem) async {
    final rawName = (userItem['fullName']?.toString() ?? '').trim();
    final name = rawName.isNotEmpty ? rawName.toTitleCase() : 'User';
    final email = userItem['email']?.toString() ?? userItem['mobile']?.toString() ?? '';
    final userId = userItem['id']?.toString() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Delete User Account?')),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the account for "$name" ($email)?\n\nTheir login credentials, FCM notification tokens, and mobile links will be purged. Their family tree directory entry will remain as an unlinked member profile.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted && userId.isNotEmpty) {
      await _deleteUserByAdmin(userId, name);
    }
  }

  bool _areSetsEqual(Set<int> a, Set<int> b) {
    return a.length == b.length && a.containsAll(b);
  }

  Widget _buildRoleChip(String label, String value, String selectedValue, ValueChanged<String> onSelected) {
    final isSelected = value == selectedValue;
    final color = value == 'admin' ? Colors.red : value == 'moderator' ? Colors.indigo : Colors.teal;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                value.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : color.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, String selectedValue, ValueChanged<String> onSelected) {
    final isSelected = value == selectedValue;
    final color = value == 'suspended'
        ? Colors.red
        : (value == 'inactive' ? Colors.orange.shade800 : Colors.green);

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                value.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : color.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeRoleModal(Map<String, dynamic> userItem) async {
    if (_regionsList.isEmpty && !_isLoadingRegions) {
      await _fetchRegions();
    }

    String roleVal = (userItem['role']?.toString() ?? 'member').toLowerCase();
    if (!['member', 'moderator', 'admin'].contains(roleVal)) {
      roleVal = 'member';
    }
    final initialRole = roleVal;
    String selectedRole = roleVal;

    final initialStatus = (userItem['status']?.toString() ?? 'active').toLowerCase();
    String selectedStatus = initialStatus;
    if (!['active', 'inactive', 'suspended'].contains(selectedStatus)) {
      selectedStatus = 'active';
    }

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
    final initialRegionIds = Set<int>.from(selectedRegionIds);

    final currentUserId = ref.read(authProvider).user?.id.toString();
    final targetUserId = userItem['id']?.toString() ?? '';
    final isSelf = targetUserId.isNotEmpty && targetUserId == currentUserId;
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
            final rawName = (userItem['fullName']?.toString() ?? '').trim();
            final userName = rawName.isNotEmpty ? rawName.toTitleCase() : 'User';
            final userEmail = userItem['email']?.toString() ?? userItem['mobile']?.toString() ?? '';

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

                    if (!isSelf) ...[
                      const SizedBox(height: 20),
                      const Text('Account Status / खाता स्थिति:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatusChip('Active', 'active', selectedStatus, (s) => setModalState(() => selectedStatus = s)),
                          const SizedBox(width: 8),
                          _buildStatusChip('Inactive', 'inactive', selectedStatus, (s) => setModalState(() => selectedStatus = s)),
                          const SizedBox(width: 8),
                          _buildStatusChip('Blocked', 'suspended', selectedStatus, (s) => setModalState(() => selectedStatus = s)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final roleChanged = selectedRole != initialRole;
                          final regionsChanged = (selectedRole == 'moderator') &&
                              (roleChanged || !_areSetsEqual(selectedRegionIds, initialRegionIds));
                          final statusChanged = !isSelf && selectedStatus != initialStatus;

                          if ((roleChanged || regionsChanged) && targetUserId.isNotEmpty) {
                            await _updateUserRole(
                              targetUserId,
                              selectedRole,
                              selectedRole == 'moderator' ? selectedRegionIds.toList() : null,
                            );
                          }

                          if (statusChanged && targetUserId.isNotEmpty) {
                            await _updateStatusDirect(targetUserId, selectedStatus);
                          }
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Save Role & Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(authProvider).user?.id.toString();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              TextField(
                controller: _userSearchController,
                decoration: InputDecoration(
                  hintText: 'Search members by name, email, or mobile...',
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
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (val) => _fetchUsers(query: val, page: 1),
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Registered: $_totalUsersCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_userSearchQuery.isNotEmpty)
                    Text(
                      'Filtered by "$_userSearchQuery"',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

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
                        final rawItem = _usersList[index];
                        final item = rawItem is Map<String, dynamic>
                            ? rawItem
                            : rawItem is Map
                                ? Map<String, dynamic>.from(rawItem)
                                : <String, dynamic>{};

                        final role = (item['role']?.toString() ?? 'member').toLowerCase();
                        final status = (item['status']?.toString() ?? 'active').toLowerCase();
                        final isSuspended = status == 'suspended';
                        final isInactive = status == 'inactive';
                        final assignedRegs = (item['assignedRegions'] as List<dynamic>?) ?? [];
                        final regNames = assignedRegs
                            .map((r) => (r is Map ? r['name']?.toString() : null) ?? '')
                            .where((name) => name.isNotEmpty)
                            .toList();

                        final roleColor = role == 'admin'
                            ? Colors.red
                            : role == 'moderator'
                                ? Colors.indigo
                                : theme.colorScheme.primary;

                        final rawName = (item['fullName']?.toString() ?? '').trim();
                        final displayName = rawName.isNotEmpty ? rawName.toTitleCase() : 'User';
                        final avatarLetter = rawName.isNotEmpty ? rawName[0].toUpperCase() : 'U';
                        final avatarUrl = item['avatarUrl']?.toString();
                        final hasValidAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty && avatarUrl.startsWith('http');
                        final contactInfo = item['email']?.toString() ?? item['mobile']?.toString() ?? 'No contact info';
                        final itemId = item['id']?.toString() ?? '';
                        final isCurrentUser = itemId.isNotEmpty && itemId == currentUserId;

                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSuspended
                                  ? Colors.red.shade300
                                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
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
                                      backgroundImage: hasValidAvatar ? NetworkImage(avatarUrl) : null,
                                      backgroundColor: roleColor.withValues(alpha: 0.1),
                                      child: !hasValidAvatar
                                          ? Text(
                                              avatarLetter,
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
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            contactInfo,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: roleColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSuspended
                                                ? Colors.red.shade50
                                                : (isInactive ? Colors.orange.shade50 : Colors.green.shade50),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isSuspended
                                                  ? Colors.red.shade300
                                                  : (isInactive ? Colors.orange.shade300 : Colors.green.shade300),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isSuspended
                                                    ? Icons.block
                                                    : (isInactive ? Icons.pause_circle_outline : Icons.check_circle_outline),
                                                size: 10,
                                                color: isSuspended
                                                    ? Colors.red.shade700
                                                    : (isInactive ? Colors.orange.shade800 : Colors.green.shade700),
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                isSuspended ? 'BLOCKED' : (isInactive ? 'INACTIVE' : 'ACTIVE'),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSuspended
                                                      ? Colors.red.shade700
                                                      : (isInactive ? Colors.orange.shade800 : Colors.green.shade700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showChangeRoleModal(item),
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Edit Role & Status', style: TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: theme.colorScheme.primary,
                                          side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (!isCurrentUser) ...[
                                      IconButton.outlined(
                                        onPressed: () => _confirmDeleteUserByAdmin(item),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        tooltip: 'Delete User Account',
                                        style: IconButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red.shade200),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'You (Current Admin)',
                                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

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
}
