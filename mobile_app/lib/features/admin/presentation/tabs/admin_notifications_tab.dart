import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/recipient_selector_modal.dart';

class AdminNotificationsTab extends ConsumerStatefulWidget {
  final AppLanguage? lang;
  const AdminNotificationsTab({super.key, this.lang});

  @override
  ConsumerState<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends ConsumerState<AdminNotificationsTab> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  final Map<String, String> _selectedRecipients = {};
  bool _sendNotificationToAll = true;
  bool _isSendingNotification = false;
  String? _statusMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _openRecipientSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecipientSelectorModal(
        initialSelected: Map<String, String>.from(_selectedRecipients),
        onConfirmed: (selectedMap) {
          setState(() {
            _selectedRecipients.clear();
            _selectedRecipients.addAll(selectedMap);
          });
        },
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (!_sendNotificationToAll && _selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient member.')),
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
        if (_sendNotificationToAll) ...{
          'targetUserId': 'all',
        } else ...{
          'targetUserIds': _selectedRecipients.keys.toList(),
        },
        'title': title,
        'body': body,
      });

      setState(() {
        _isSendingNotification = false;
        _statusMessage = response.data['message'] ?? 'Notification dispatched successfully.';
      });
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      String errorMessage = 'Failed to dispatch notification';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMessage = 'Failed: ${data['message']}';
        } else if (data is Map && data['error'] != null) {
          errorMessage = 'Failed: ${data['error']}';
        } else {
          errorMessage = 'Failed (${e.response?.statusCode ?? 'network'}): ${e.message}';
        }
      } else {
        errorMessage = 'Failed: $e';
      }
      setState(() {
        _isSendingNotification = false;
        _statusMessage = errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final AppLanguage lang =
        widget.lang ?? ref.watch(languageStateProvider) ?? AppLanguage.en;
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
          
          // Target Choice: All or Single
          const Text(
            'Target Audience / प्राप्तकर्ता',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('📢 All Members / सभी सदस्य'),
                selected: _sendNotificationToAll,
                onSelected: (val) {
                  setState(() => _sendNotificationToAll = true);
                },
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('👤 Specific Members / चयनित सदस्य'),
                selected: !_sendNotificationToAll,
                onSelected: (val) {
                  setState(() => _sendNotificationToAll = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_sendNotificationToAll) ...[
            InkWell(
              onTap: _openRecipientSelectorSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedRecipients.isEmpty
                        ? theme.colorScheme.outlineVariant
                        : theme.colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surfaceContainerLow,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_search_rounded,
                      color: _selectedRecipients.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedRecipients.isEmpty
                                ? 'Search & Select Recipients'
                                : '${_selectedRecipients.length} Recipient(s) Selected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _selectedRecipients.isEmpty
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedRecipients.isEmpty
                                ? 'Tap to search and pick specific members'
                                : 'Tap to add or modify selected members',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (_selectedRecipients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Members (${_selectedRecipients.length}):',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedRecipients.clear()),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _selectedRecipients.entries.map((entry) {
                  return Chip(
                    label: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => _selectedRecipients.remove(entry.key));
                    },
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Broadcast Mode: Notification will be delivered to ALL active member devices.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Title Textbox
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppTranslations.get('notification_title', lang),
              hintText: 'e.g. Community Gathering this Sunday',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          
          // Body Textbox
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AppTranslations.get('notification_body', lang),
              hintText: 'Enter full notification content...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSendingNotification ? null : _sendTestNotification,
              icon: _isSendingNotification 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSendingNotification 
                    ? 'Dispatching...' 
                    : AppTranslations.get('dispatch_notification', lang),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusMessage!.startsWith('Failed') 
                    ? Colors.red.shade50 
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage!.startsWith('Failed') 
                      ? Colors.red.shade200 
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage!.startsWith('Failed') 
                        ? Icons.error_outline 
                        : Icons.check_circle_outline,
                    color: _statusMessage!.startsWith('Failed') 
                        ? Colors.red 
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.startsWith('Failed') 
                            ? Colors.red.shade800 
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
