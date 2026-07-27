import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/name_formatter.dart';
import '../../directory/presentation/family_member_detail_screen.dart';
import '../../directory/presentation/business_profile_detail_screen.dart';
import '../../directory/presentation/family_tree_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  List<dynamic> _usersList = [];
  bool _isLoadingUsers = true;
  String? _selectedUserId;
  bool _isSendingNotification = false;
  String? _statusMessage;

  List<dynamic> _pendingList = [];
  bool _isLoadingPending = true;
  String? _pendingError;

  List<dynamic> _pendingBusinessesList = [];
  bool _isLoadingPendingBusinesses = true;
  String? _pendingBusinessesError;

  List<dynamic> _regionsList = [];
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchRegions();
    _fetchPendingMembers();
    _fetchPendingBusinesses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/regions');
      setState(() {
        _regionsList = response.data['regions'] as List<dynamic>;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _showChangeRoleDialog(Map<String, dynamic> userItem) async {
    String selectedRole = userItem['role'] as String? ?? 'member';
    final existingAssigned = (userItem['assignedRegions'] as List<dynamic>?) ?? [];
    final Set<int> selectedRegionIds = existingAssigned.map<int>((r) => r['id'] as int).toSet();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text('Change Role: ${userItem['fullName']}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select User Role:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'member', child: Text('Member')),
                        DropdownMenuItem(value: 'moderator', child: Text('Moderator (Area Coordinator)')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    if (selectedRole == 'moderator') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Assign Regions / Zones to Moderate:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingRegions)
                        const Center(child: CircularProgressIndicator())
                      else if (_regionsList.isEmpty)
                        const Text('No regions available in system.', style: TextStyle(color: Colors.grey, fontSize: 12))
                      else
                        Container(
                          maxHeight: 180,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _regionsList.length,
                            itemBuilder: (context, idx) {
                              final reg = _regionsList[idx];
                              final regId = reg['id'] as int;
                              final regName = reg['name'] as String;
                              final isChecked = selectedRegionIds.contains(regId);

                              return CheckboxListTile(
                                dense: true,
                                title: Text(regName, style: const TextStyle(fontSize: 13)),
                                value: isChecked,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      selectedRegionIds.add(regId);
                                    } else {
                                      selectedRegionIds.remove(regId);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _updateUserRole(
                      userItem['id'] as String,
                      selectedRole,
                      selectedRole == 'moderator' ? selectedRegionIds.toList() : null,
                    );
                  },
                  child: const Text('SAVE ROLE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateUserRole(String userId, String newRole, List<int>? regionIds) async {
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch('/users/change-role', data: {
        'userId': userId,
        'newRole': newRole,
        if (regionIds != null) 'regionIds': regionIds,
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

  Future<void> _fetchUsers() async {

    setState(() => _isLoadingUsers = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/users');
      setState(() {
        _usersList = response.data['users'] as List<dynamic>;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to load users: $e';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _fetchPendingMembers() async {
    setState(() {
      _isLoadingPending = true;
      _pendingError = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/moderation/pending');
      setState(() {
        _pendingList = response.data['pendingMembers'] as List<dynamic>;
        _isLoadingPending = false;
      });
    } catch (e) {
      setState(() {
        _pendingError = 'Failed to load pending approvals: $e';
        _isLoadingPending = false;
      });
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
      setState(() {
        _pendingBusinessesList = response.data['pendingBusinesses'] as List<dynamic>;
        _isLoadingPendingBusinesses = false;
      });
    } catch (e) {
      setState(() {
        _pendingBusinessesError = 'Failed to load pending businesses: $e';
        _isLoadingPendingBusinesses = false;
      });
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

  Widget _buildNotificationsTab(AppLanguage lang) {
    final theme = Theme.of(context);
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
            decoration: const InputDecoration(
              labelText: 'Select Recipient Member',
            ),
            initialValue: _selectedUserId,
            items: _usersList.map<DropdownMenuItem<String>>((user) {
              return DropdownMenuItem<String>(
                value: user['id'] as String,
                child: Text('${user['fullName'] ?? ''} (${user['role']})'),
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
          const SizedBox(height: 40),
          
          // Users List section
          const Text(
            'Registered Members List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _usersList.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = _usersList[index] as Map<String, dynamic>;
              final role = (item['role'] as String? ?? 'member').toLowerCase();
              final assignedRegs = (item['assignedRegions'] as List<dynamic>?) ?? [];
              final regNames = assignedRegs.map((r) => r['name'] as String).join(', ');

              return ListTile(
                onTap: () => _showChangeRoleDialog(item),
                leading: CircleAvatar(
                  backgroundImage: item['avatarUrl'] != null ? NetworkImage(item['avatarUrl'] as String) : null,
                  child: item['avatarUrl'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(item['fullName'] as String? ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['email'] as String? ?? item['mobile'] as String? ?? ''),
                    if (role == 'moderator')
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        style: TextStyle(
                          fontSize: 12,
                          color: regNames.isNotEmpty ? Colors.indigo : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        child: Text(
                          regNames.isNotEmpty ? 'Zones: $regNames' : '⚠️ No Area Assigned',
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: role == 'admin' 
                            ? Colors.red.withValues(alpha: 0.1) 
                            : role == 'moderator' 
                                ? Colors.indigo.withValues(alpha: 0.1) 
                                : theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11, 
                          color: role == 'admin' ? Colors.red : role == 'moderator' ? Colors.indigo : theme.colorScheme.secondary, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              );
            },

          ),
        ],
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageStateProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppTranslations.get('admin_dashboard', lang)),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: [
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Notifications'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Member Approvals'),
              Tab(icon: Icon(Icons.business_center_outlined), text: 'Business Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationsTab(lang),
            _buildApprovalsTab(),
            _buildBusinessApprovalsTab(),
          ],
        ),
      ),
    );
  }
}
