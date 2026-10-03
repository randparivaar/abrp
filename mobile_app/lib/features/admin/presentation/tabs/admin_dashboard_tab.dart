import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/auth_controller.dart';

class AdminDashboardTab extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final int pendingFamiliesCount;
  final int pendingBusinessesCount;
  final int adsCount;
  final Future<void> Function()? onRefresh;

  const AdminDashboardTab({
    super.key,
    required this.onTabSelected,
    this.pendingFamiliesCount = 0,
    this.pendingBusinessesCount = 0,
    this.adsCount = 0,
    this.onRefresh,
  });

  Widget _dashStatCard({
    required BuildContext context,
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
    required BuildContext context,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Admin';
    final userRole = authState.user?.role ?? 'admin';
    final isAdmin = userRole == 'admin';
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> modules = [
      {
        'title': 'Family Approvals',
        'subtitle': 'Review submitted family records',
        'icon': Icons.groups_rounded,
        'badge': pendingFamiliesCount,
        'color': const Color(0xFF1976D2),
        'tab': 1,
      },
      {
        'title': 'Business Approvals',
        'subtitle': 'Approve community business profiles',
        'icon': Icons.business_center_rounded,
        'badge': pendingBusinessesCount,
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
          'badge': adsCount,
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
          'tab': 6,
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

    final totalPending = pendingFamiliesCount + pendingBusinessesCount;

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
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
                    ? [
                        colorScheme.primary.withValues(alpha: 0.3),
                        colorScheme.primaryContainer.withValues(alpha: 0.2)
                      ]
                    : [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.75)
                      ],
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  context: context,
                  label: 'Pending Families',
                  value: '$pendingFamiliesCount',
                  icon: Icons.family_restroom_rounded,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dashStatCard(
                  context: context,
                  label: 'Pending Businesses',
                  value: '$pendingBusinessesCount',
                  icon: Icons.storefront_rounded,
                  color: const Color(0xFFE65100),
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _dashStatCard(
                    context: context,
                    label: 'Ad Campaigns',
                    value: '$adsCount',
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
                context: context,
                title: m['title'] as String,
                subtitle: m['subtitle'] as String,
                icon: m['icon'] as IconData,
                color: color,
                badge: badge,
                onTap: () => onTabSelected(m['tab'] as int),
              );
            },
          ),
        ],
      ),
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }
}
