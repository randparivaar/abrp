import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/network/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchPendingMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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

  Future<void> _approveMember(int memberId, String fullName) async {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  Future<void> _rejectMember(int memberId, String fullName) async {
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

    if (confirm != true) return;

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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    }
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
                child: Text('${user['full_name']} (${user['role']})'),
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
              final item = _usersList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: item['avatar_url'] != null ? NetworkImage(item['avatar_url'] as String) : null,
                  child: item['avatar_url'] == null ? const Icon(Icons.person) : null,
                ),
                title: Text(item['full_name'] as String),
                subtitle: Text(item['email'] as String),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (item['role'] as String).toUpperCase(),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                  ),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.secondary,
                      ),
                    ),
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
                  ],
                ),
                const SizedBox(height: 8),
                Text('Gender: ${gender.toUpperCase()}'),
                Text('Family Code: $familyCode'),
                Text('Location: $address'),
                const Divider(height: 24),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageStateProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppTranslations.get('admin_dashboard', lang)),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: [
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Notifications'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Pending Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationsTab(lang),
            _buildApprovalsTab(),
          ],
        ),
      ),
    );
  }
}
