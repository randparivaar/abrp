import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/name_formatter.dart';

class RecipientSelectorModal extends ConsumerStatefulWidget {
  final Map<String, String> initialSelected;
  final ValueChanged<Map<String, String>> onConfirmed;

  const RecipientSelectorModal({
    super.key,
    required this.initialSelected,
    required this.onConfirmed,
  });

  @override
  ConsumerState<RecipientSelectorModal> createState() => _RecipientSelectorModalState();
}

class _RecipientSelectorModalState extends ConsumerState<RecipientSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, String> _selected;
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _selected = Map.from(widget.initialSelected);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchUsers(query: query, page: 1);
    });
  }

  Future<void> _fetchUsers({String? query, int page = 1}) async {
    final search = query ?? _searchController.text.trim();
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/users', queryParameters: {
        if (search.isNotEmpty) 'search': search,
        'page': page,
        'limit': 20,
      });

      final data = response.data;
      final fetchedUsers = (data['users'] as List<dynamic>? ?? []);
      final totalP = data['totalPages'] as int? ?? 1;
      final totalC = data['totalCount'] as int? ?? fetchedUsers.length;

      if (mounted) {
        setState(() {
          if (page == 1) {
            _users = fetchedUsers;
          } else {
            _users.addAll(fetchedUsers);
          }
          _page = page;
          _totalPages = totalP;
          _totalCount = totalC;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load members: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleUser(Map<String, dynamic> user) {
    final id = user['id'] as String;
    final name = (user['fullName'] as String? ?? 'Member').toTitleCase();
    final role = (user['role'] as String? ?? 'member').toUpperCase();
    final label = '$name ($role)';

    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Push Recipients',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_selected.length} selected of $_totalCount members',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selected.isNotEmpty ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                          fontWeight: _selected.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members by name, mobile, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchUsers(query: '', page: 1);
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Quick Select Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _users.isEmpty
                      ? null
                      : () {
                          setState(() {
                            for (final u in _users) {
                              final id = u['id'] as String;
                              final name = (u['fullName'] as String? ?? 'Member').toTitleCase();
                              final role = (u['role'] as String? ?? 'member').toUpperCase();
                              _selected[id] = '$name ($role)';
                            }
                          });
                        },
                  icon: const Icon(Icons.select_all, size: 16),
                  label: const Text('Select Visible', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                const SizedBox(width: 8),
                if (_selected.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _selected.clear()),
                    icon: const Icon(Icons.deselect, size: 16, color: Colors.red),
                    label: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // User List
          Expanded(
            child: _isLoading && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _fetchUsers(page: 1),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? const Center(
                            child: Text('No matching members found.', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _users.length + (_page < _totalPages ? 1 : 0),
                            separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 64),
                            itemBuilder: (ctx, i) {
                              if (i == _users.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: OutlinedButton(
                                      onPressed: () => _fetchUsers(page: _page + 1),
                                      child: const Text('Load More Members'),
                                    ),
                                  ),
                                );
                              }

                              final user = _users[i] as Map<String, dynamic>;
                              final id = user['id'] as String;
                              final name = (user['fullName'] as String? ?? 'Member').toTitleCase();
                              final role = (user['role'] as String? ?? 'member').toUpperCase();
                              final contact = user['mobile'] as String? ?? user['email'] as String? ?? '';
                              final isChecked = _selected.containsKey(id);

                              return CheckboxListTile(
                                value: isChecked,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (_) => _toggleUser(user),
                                secondary: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: user['avatarUrl'] != null
                                      ? NetworkImage(user['avatarUrl'] as String)
                                      : null,
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  child: user['avatarUrl'] == null
                                      ? Text(
                                          name.isNotEmpty ? name[0] : 'U',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                subtitle: Text(
                                  '$role • $contact',
                                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
          ),

          // Bottom Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + mediaQuery.padding.bottom),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  widget.onConfirmed(_selected);
                  Navigator.pop(context);
                },
                child: Text(
                  _selected.isEmpty
                      ? 'Done (No member selected)'
                      : 'Confirm Selection (${_selected.length})',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
