import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import 'wish_poster_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _todayList = [];
  List<Map<String, dynamic>> _earlierList = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/notifications');

      final today = List<Map<String, dynamic>>.from(response.data['today'] ?? []);
      final earlier = List<Map<String, dynamic>>.from(response.data['earlier'] ?? []);
      final unread = (response.data['unreadCount'] as num?)?.toInt() ?? 0;

      setState(() {
        _todayList = today;
        _earlierList = earlier;
        _unreadCount = unread;
        _isLoading = false;
      });

      // Requirement: Auto mark today's notifications as read when opening this screen
      final hasUnreadToday = today.any((n) => n['isRead'] == false);
      if (hasUnreadToday) {
        _autoMarkTodayRead();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load notifications: $e';
      });
    }
  }

  Future<void> _autoMarkTodayRead() async {
    try {
      final dio = ref.read(apiClientProvider);
      for (final n in _todayList) {
        if (n['isRead'] == false) {
          n['isRead'] = true;
          dio.post('/notifications/${n['id']}/read').then((_) => null, onError: (_) => null);
        }
      }
      if (mounted) {
        setState(() {
          _unreadCount = _earlierList.where((n) => n['isRead'] == false).length;
        });
      }
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/notifications/read-all');

      setState(() {
        for (var n in _todayList) {
          n['isRead'] = true;
        }
        for (var n in _earlierList) {
          n['isRead'] = true;
        }
        _unreadCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _openNotification(Map<String, dynamic> item) {
    // Mark as read in local state and fire background request
    if (item['isRead'] == false) {
      setState(() {
        item['isRead'] = true;
        if (_unreadCount > 0) _unreadCount--;
      });
      final dio = ref.read(apiClientProvider);
      dio.post('/notifications/${item['id']}/read').then((_) => null, onError: (_) => null);
    }

    final metadata = (item['metadata'] as Map<String, dynamic>?) ?? {};
    final posterUrl = item['imageUrl'] as String? ?? metadata['posterUrl'] as String?;
    final title = item['title'] as String? ?? 'ABRP Samaj';
    final body = item['body'] as String?;
    final wishType = item['type'] as String?;
    final memberName = metadata['memberName'] as String?;
    final spouseName = metadata['spouseName'] as String?;
    final avatarUrl = metadata['avatarUrl'] as String?;
    final coupleNames = metadata['coupleNames'] as String?;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WishPosterScreen(
          posterUrl: posterUrl,
          title: title,
          body: body,
          wishType: wishType,
          memberName: memberName,
          spouseName: spouseName,
          avatarUrl: avatarUrl,
          coupleNames: coupleNames,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'सूचनाएँ / Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(
                'Mark read',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchNotifications,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: GoogleFonts.inter()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // ── Section 1: Today's Notifications ──
                      _buildSectionHeader('आज की सूचनाएँ / Today', Icons.today_rounded, const Color(0xFFD97706)),
                      const SizedBox(height: 10),
                      if (_todayList.isEmpty)
                        _buildEmptyState(
                          'आज कोई नई सूचना नहीं है',
                          'No new notifications for today. Check back later!',
                          isDark,
                        )
                      else
                        ..._todayList.map((n) => _buildNotificationCard(n, isDark)),

                      const SizedBox(height: 24),

                      // ── Section 2: Earlier Notifications ──
                      if (_earlierList.isNotEmpty) ...[
                        _buildSectionHeader('पूर्व सूचनाएँ / Earlier', Icons.history_rounded, Colors.grey.shade600),
                        const SizedBox(height: 10),
                        ..._earlierList.map((n) => _buildNotificationCard(n, isDark)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] as String? ?? 'ABRP Samaj';
    final body = item['body'] as String? ?? '';
    final imageUrl = item['imageUrl'] as String?;
    final isRead = item['isRead'] as bool? ?? false;
    final type = item['type'] as String? ?? 'general';

    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(item['createdAt']);
    } catch (_) {}

    final timeStr = createdAt != null ? DateFormat('hh:mm a').format(createdAt) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead
              ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
              : const Color(0xFFD97706).withValues(alpha: 0.5),
          width: isRead ? 1 : 1.5,
        ),
      ),
      color: isRead
          ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
          : (isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openNotification(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Thumbnail or Icon
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      width: 58,
                      height: 58,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (ctx, url, err) => _buildTypeIcon(type),
                  ),
                )
              else
                _buildTypeIcon(type),

              const SizedBox(width: 14),

              // Title & Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'View poster →',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
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

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case 'birthday':
        icon = Icons.cake_rounded;
        bgColor = const Color(0xFFEFF6FF);
        iconColor = const Color(0xFF2563EB);
        break;
      case 'anniversary':
        icon = Icons.favorite_rounded;
        bgColor = const Color(0xFFFDF2F8);
        iconColor = const Color(0xFFDB2777);
        break;
      case 'festival':
        icon = Icons.celebration_rounded;
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFD97706);
        break;
      default:
        icon = Icons.notifications_active_rounded;
        bgColor = const Color(0xFFF3F4F6);
        iconColor = const Color(0xFF4B5563);
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 28),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 36, color: Color(0xFFD97706)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
