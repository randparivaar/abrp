import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final _imageUrlController = TextEditingController();

  final Map<String, String> _selectedRecipients = {};
  bool _sendNotificationToAll = true;
  bool _isSendingNotification = false;
  String? _statusMessage;

  // Mode: 0 = Festival / Daily Wish Poster, 1 = General Announcement
  int _selectedMode = 0;
  String _selectedWishType = 'festival'; // 'festival', 'birthday', 'anniversary', 'announcement'
  String? _selectedPosterUrl;
  String? _selectedPosterName;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
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

  void _openR2PosterPickerDialog() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _R2PosterPickerSheet(
        onPosterSelected: (url, name) {
          setState(() {
            _selectedPosterUrl = url;
            _selectedPosterName = name;
            _imageUrlController.text = url;
          });
        },
      ),
    );
  }

  void _applyPresetWish(String title, String body, String type) {
    setState(() {
      _titleController.text = title;
      _bodyController.text = body;
      _selectedWishType = type;
    });
  }

  Future<void> _dispatchNotification() async {
    if (!_sendNotificationToAll && _selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient member.')),
      );
      return;
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final imageUrl = _selectedPosterUrl ?? _imageUrlController.text.trim();

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
      final endpoint = _selectedMode == 0 ? '/notifications/send-wish' : '/notifications/send-test';

      final response = await dio.post(endpoint, data: {
        'title': title,
        'body': body,
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'type': _selectedWishType,
        'targetType': _sendNotificationToAll ? 'all' : 'user',
        'targetIds': _sendNotificationToAll ? ['all'] : _selectedRecipients.keys.toList(),
      });

      setState(() {
        _isSendingNotification = false;
        _statusMessage = response.data['message'] ?? 'Notification dispatched successfully!';
      });

      _titleController.clear();
      _bodyController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedPosterUrl = null;
        _selectedPosterName = null;
      });
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
    final isDark = theme.brightness == Brightness.dark;
    final AppLanguage lang =
        widget.lang ?? ref.watch(languageStateProvider) ?? AppLanguage.en;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode Switch (Festival / Wishes Poster vs General Notice)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMode = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 0
                            ? (isDark ? theme.colorScheme.primary : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedMode == 0
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        '🌸 त्यौहार / शुभकामना पोस्टर',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: _selectedMode == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 0
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMode = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMode == 1
                            ? (isDark ? theme.colorScheme.primary : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedMode == 1
                            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        '📢 सामान्य सूचना',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: _selectedMode == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _selectedMode == 1
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Preset Quick Wishes Chips (Mode 0) ──
          if (_selectedMode == 0) ...[
            Text(
              'त्वरित शुभकामना टेम्पलेट / Presets:',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Text('🪔'),
                    label: const Text('दीपावली'),
                    onPressed: () => _applyPresetWish(
                      'शुभ दीपावली की हार्दिक शुभकामनाएँ 🪔',
                      'समस्त रांदेर परिवार समाज को प्रकाश पर्व दीपावली की हार्दिक शुभकामनाएँ। माँ लक्ष्मी आपके जीवन में सुख, शांति और समृद्धि का वास करें।',
                      'festival',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Text('🎨'),
                    label: const Text('होली'),
                    onPressed: () => _applyPresetWish(
                      'रंगोत्सव होली की हार्दिक शुभकामनाएँ 🎨',
                      'आप सभी को रंगों और उल्लास के पावन पर्व होली की अनंत मंगलकामनाएँ। रांदेर परिवार सदा खुशहाल रहे।',
                      'festival',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Text('🕉️'),
                    label: const Text('महावीर जयंती'),
                    onPressed: () => _applyPresetWish(
                      'भगवान महावीर जयंती की शुभकामनाएँ 🕉️',
                      'जियो और जीने दो के संदेशवाहक भगवान महावीर स्वामी के जन्म कल्याणक की समस्त रांदेर परिवार को बधाई।',
                      'festival',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Text('🎂'),
                    label: const Text('जन्मदिन'),
                    onPressed: () => _applyPresetWish(
                      'जन्मदिन की हार्दिक शुभकामनाएँ 🎂',
                      'ईश्वर से आपके उत्तम स्वास्थ्य, दीर्घायु एवं मंगलमय जीवन की प्रार्थना करते हैं।',
                      'birthday',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Poster Selection Section (Mode 0) ──
          if (_selectedMode == 0) ...[
            Text(
              'पोस्टर चयन / Poster Image:',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    onPressed: _openR2PosterPickerDialog,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(
                      _selectedPosterName != null
                          ? 'पोस्टर: $_selectedPosterName'
                          : 'R2 स्टोरेज से पोस्टर चुनें / Select from R2',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_selectedPosterUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Remove Poster',
                    onPressed: () {
                      setState(() {
                        _selectedPosterUrl = null;
                        _selectedPosterName = null;
                        _imageUrlController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // Live Poster Preview Box
            if (_selectedPosterUrl != null && _selectedPosterUrl!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.preview_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          'Live Poster Preview (Notification Popup)',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: _selectedPosterUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          // ── Target Audience Selector ──
          const Text(
            'Target Audience / प्राप्तकर्ता',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('📢 All Members / सभी सदस्य'),
                selected: _sendNotificationToAll,
                onSelected: (val) => setState(() => _sendNotificationToAll = true),
              ),
              ChoiceChip(
                label: const Text('👤 Specific Members'),
                selected: !_sendNotificationToAll,
                onSelected: (val) => setState(() => _sendNotificationToAll = false),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_sendNotificationToAll) ...[
            ElevatedButton.icon(
              onPressed: _openRecipientSelectorSheet,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text('Select Members (${_selectedRecipients.length} selected)'),
            ),
            const SizedBox(height: 12),
          ],

          // ── Title Input ──
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: AppTranslations.get('notification_title', lang),
              hintText: 'e.g. शुभ दीपावली / Community Notice',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),

          // ── Body Message Input ──
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: AppTranslations.get('notification_body', lang),
              hintText: 'Enter full greeting or notification content...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Icon(Icons.message_outlined),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSendingNotification ? null : _dispatchNotification,
              icon: _isSendingNotification
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSendingNotification
                    ? 'Dispatching...'
                    : (_selectedMode == 0
                        ? '🚀 शुभकामना पोस्टर भेजें / Dispatch Wish Poster'
                        : '📢 सूचना भेजें / Dispatch Notice'),
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // ── Status Message Feedback ──
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusMessage!.startsWith('Failed') ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _statusMessage!.startsWith('Failed') ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage!.startsWith('Failed') ? Icons.error_outline : Icons.check_circle_outline,
                    color: _statusMessage!.startsWith('Failed') ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: TextStyle(
                        color: _statusMessage!.startsWith('Failed') ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
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

/// Modal Sheet to search and pick a poster from Cloudflare R2
class _R2PosterPickerSheet extends ConsumerStatefulWidget {
  final Function(String url, String name) onPosterSelected;
  const _R2PosterPickerSheet({required this.onPosterSelected});

  @override
  ConsumerState<_R2PosterPickerSheet> createState() => _R2PosterPickerSheetState();
}

class _R2PosterPickerSheetState extends ConsumerState<_R2PosterPickerSheet> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _posters = [];

  @override
  void initState() {
    super.initState();
    _loadPosters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosters([String search = '']) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/notifications/posters', queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
      });

      final list = List<Map<String, dynamic>>.from(response.data['posters'] ?? []);
      setState(() {
        _posters = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load posters: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Text(
                'Cloudflare R2 पोस्टर गैलरी',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search poster by name (e.g. diwali, holi)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () => _loadPosters(_searchController.text),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (val) => _loadPosters(val),
          ),
          const SizedBox(height: 14),

          // Grid View of Posters
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _posters.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text('No posters found in R2 bucket', style: GoogleFonts.inter()),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: _posters.length,
                            itemBuilder: (ctx, index) {
                              final p = _posters[index];
                              final url = p['publicUrl'] as String;
                              final name = p['filename'] as String? ?? p['key'] as String;

                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  widget.onPosterSelected(url, name);
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                          child: CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover,
                                            placeholder: (ctx, url) => const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            errorWidget: (ctx, url, err) => const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          name,
                                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
