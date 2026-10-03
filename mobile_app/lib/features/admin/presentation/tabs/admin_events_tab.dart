import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../events/presentation/events_provider.dart';
import '../../../events/presentation/event_form_dialog.dart';
import '../../../events/presentation/event_detail_screen.dart';

class AdminEventsTab extends ConsumerStatefulWidget {
  const AdminEventsTab({super.key});

  @override
  ConsumerState<AdminEventsTab> createState() => _AdminEventsTabState();
}

class _AdminEventsTabState extends ConsumerState<AdminEventsTab> {
  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _mon(int m) => _months[m.clamp(1, 12)];

  void _refreshAdminEvents() {
    ref.invalidate(adminEventsProvider);
    ref.invalidate(activeEventsProvider);
  }

  Widget _eventPlaceholder(ColorScheme cs) => Container(
        width: 60,
        height: 60,
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

  @override
  Widget build(BuildContext context) {
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
                          style: GoogleFonts.outfit(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      adminEventsAsync.when(
                        data: (list) => Text(
                          '${list.length} total · ${list.where((e) => e.isActive).length} active',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
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
                          Icon(Icons.event_busy_rounded,
                              size: 56,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No events yet.',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Text('Tap "Add Event" to create the first one.',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: eventsList.map((eventItem) {
                    final hasAlbum =
                        eventItem.externalAlbumUrl?.isNotEmpty == true;
                    final galleryCount = eventItem.galleryUrls.length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: eventItem.isActive
                              ? Colors.green.withValues(alpha: 0.4)
                              : colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
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
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              _eventPlaceholder(colorScheme),
                                        )
                                      : _eventPlaceholder(colorScheme),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            !(e.year == d.year &&
                                                e.month == d.month &&
                                                e.day == d.day);
                                        final dateStr = isMulti
                                            ? '📅 ${d.day} ${_mon(d.month)} → ${e.day} ${_mon(e.month)} ${e.year}'
                                            : '📅 ${d.day} ${_mon(d.month)} ${d.year}';
                                        final days = isMulti
                                            ? e.difference(d).inDays + 1
                                            : null;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dateStr +
                                                  (eventItem.venue?.isNotEmpty ==
                                                          true
                                                      ? '  ·  📍${eventItem.venue}'
                                                      : ''),
                                              style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (days != null) ...[
                                              const SizedBox(height: 2),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '$days-Day Event',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme
                                                        .onPrimaryContainer,
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
                                              _miniChip(
                                                  '$galleryCount photos',
                                                  Icons
                                                      .photo_library_outlined),
                                            if (hasAlbum)
                                              _miniChip(
                                                  'Album', Icons.link_rounded,
                                                  color:
                                                      const Color(0xFF4285F4)),
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
                                          builder: (_) => EventDetailScreen(
                                              event: eventItem),
                                        ),
                                      );
                                    } else if (action == 'delete') {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(
                                              'Delete "${eventItem.title}"?'),
                                          content: const Text(
                                              'This action cannot be undone.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: const Text('Cancel')),
                                            FilledButton(
                                                style: FilledButton.styleFrom(
                                                    backgroundColor:
                                                        colorScheme.error),
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: const Text('Delete')),
                                          ],
                                        ),
                                      );
                                      if (ok == true && mounted) {
                                        final deleted = await eventsService
                                            .deleteEvent(eventItem.id);
                                        if (!mounted) return;
                                        if (deleted) {
                                          _refreshAdminEvents();
                                          messenger.showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Event deleted.')),
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Delete failed. Try again.')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                        value: 'view',
                                        child: Row(children: [
                                          Icon(Icons.visibility_outlined,
                                              size: 18),
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
                                              style:
                                                  TextStyle(color: Colors.red))
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
                                      width: 8,
                                      height: 8,
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
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    final ok = await eventsService
                                        .toggleEventStatus(eventItem.id,
                                            isActive: newVal);
                                    if (!mounted) return;
                                    if (ok) {
                                      _refreshAdminEvents();
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(newVal
                                              ? 'Event activated.'
                                              : 'Event deactivated.'),
                                          backgroundColor: newVal
                                              ? Colors.green
                                              : Colors.red.shade700,
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Failed to update status.')),
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
                      const Icon(Icons.error_outline,
                          size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Failed to load events',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
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
}
