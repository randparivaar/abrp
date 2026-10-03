import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../directory/presentation/app_drawer.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_family_approvals_tab.dart';
import 'tabs/admin_business_approvals_tab.dart';
import 'tabs/admin_events_tab.dart';
import 'tabs/admin_advertisements_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_notifications_tab.dart';

class AdminScreen extends ConsumerStatefulWidget {
  final dynamic section;
  final int initialSection;

  const AdminScreen({
    super.key,
    this.section,
    this.initialSection = 0,
  });

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  int _selectedTabIndex = 0;

  int _pendingFamiliesCount = 0;
  int _pendingBusinessesCount = 0;
  int _adsCount = 0;
  int _totalUsersCount = 0;

  int _resolveTabIndex(dynamic sectionKey, bool isAdmin) {
    if (sectionKey == null) return 0;
    final key = sectionKey.toString().trim().toLowerCase();

    if (key == 'dashboard' || key == 'overview') return 0;
    if (key == 'families' || key == 'family') return 1;
    if (key == 'businesses' || key == 'business') return 2;

    if (isAdmin) {
      if (key == 'events' || key == 'event') return 3;
      if (key == 'ads' || key == 'banners' || key == 'campaigns') return 4;
      if (key == 'users' || key == 'user' || key == 'roles') return 5;
      if (key == 'notifications' || key == 'notification' || key == 'notif') {
        return 6;
      }
    } else {
      if (key == 'notifications' || key == 'notification' || key == 'notif') {
        return 3;
      }
    }

    final parsed = int.tryParse(key);
    if (parsed != null) {
      final maxTabs = isAdmin ? 6 : 3;
      return parsed.clamp(0, maxTabs);
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    final isAdmin = authState.user?.role == 'admin';
    _selectedTabIndex =
        _resolveTabIndex(widget.section ?? widget.initialSection, isAdmin);
    _fetchBadgeCounts();
  }

  @override
  void didUpdateWidget(covariant AdminScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.section != oldWidget.section ||
        widget.initialSection != oldWidget.initialSection) {
      final authState = ref.read(authProvider);
      final isAdmin = authState.user?.role == 'admin';
      final newIndex =
          _resolveTabIndex(widget.section ?? widget.initialSection, isAdmin);
      if (newIndex != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = newIndex;
        });
      }
    }
  }

  Future<void> _fetchBadgeCounts() async {
    try {
      final dio = ref.read(apiClientProvider);
      final authState = ref.read(authProvider);
      final isAdmin = authState.user?.role == 'admin';

      final results = await Future.wait([
        dio.get('/directory/moderation/pending-families').then((res) =>
            ((res.data['pendingFamilies'] as List<dynamic>?) ?? []).length).catchError((_) => 0),
        dio.get('/directory/moderation/pending-businesses').then((res) =>
            ((res.data['pendingBusinesses'] as List<dynamic>?) ?? []).length).catchError((_) => 0),
        if (isAdmin)
          dio.get('/ads/admin/all').then((res) =>
              ((res.data['ads'] as List<dynamic>?) ?? []).length).catchError((_) => 0)
        else
          Future.value(0),
      ]);

      if (mounted) {
        setState(() {
          _pendingFamiliesCount = results[0];
          _pendingBusinessesCount = results[1];
          if (isAdmin) _adsCount = results[2];
        });
      }
    } catch (_) {}
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == 'admin';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<({IconData icon, String label, int badge})> tabs = [
      (icon: Icons.dashboard_rounded, label: 'Dashboard', badge: 0),
      (icon: Icons.groups_rounded, label: 'Families', badge: _pendingFamiliesCount),
      (icon: Icons.business_center_rounded, label: 'Businesses', badge: _pendingBusinessesCount),
      if (isAdmin) (icon: Icons.event_available_rounded, label: 'Events', badge: 0),
      if (isAdmin) (icon: Icons.campaign_rounded, label: 'Ads', badge: _adsCount),
      if (isAdmin) (icon: Icons.manage_accounts_rounded, label: 'Users', badge: _totalUsersCount),
      (icon: Icons.notifications_rounded, label: 'Notifications', badge: 0),
    ];

    if (_selectedTabIndex >= tabs.length) {
      _selectedTabIndex = 0;
    }

    final tabTitles = [
      'Dashboard',
      'Family Approvals',
      'Business Approvals',
      if (isAdmin) 'Events & Bulletins',
      if (isAdmin) 'Ad Campaigns',
      if (isAdmin) 'User & Coordinator Roles',
      'Dispatch Notifications',
    ];

    final isCompactScreen = MediaQuery.of(context).size.width < 600;

    final tabBody = IndexedStack(
      index: _selectedTabIndex.clamp(0, tabTitles.length - 1),
      children: [
        AdminDashboardTab(
          onTabSelected: _onTabSelected,
          pendingFamiliesCount: _pendingFamiliesCount,
          pendingBusinessesCount: _pendingBusinessesCount,
          adsCount: _adsCount,
          onRefresh: _fetchBadgeCounts,
        ),
        const AdminFamilyApprovalsTab(),
        const AdminBusinessApprovalsTab(),
        if (isAdmin) const AdminEventsTab(),
        if (isAdmin)
          AdminAdvertisementsTab(
            onCountChanged: (count) {
              if (mounted) setState(() => _adsCount = count);
            },
          ),
        if (isAdmin)
          AdminUsersTab(
            onTotalCountChanged: (count) {
              if (mounted) setState(() => _totalUsersCount = count);
            },
          ),
        const AdminNotificationsTab(),
      ],
    );

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
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isCompactScreen
          ? Column(
              children: [
                // Top Horizontal Scrollable Tab Bar for Mobile Screens
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surface
                        : colorScheme.surfaceContainerLowest,
                    border: Border(
                      bottom: BorderSide(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final t = tabs[i];
                      final isSelected = _selectedTabIndex == i;
                      final hasBadge = t.badge > 0;

                      return ChoiceChip(
                        showCheckmark: false,
                        avatar: null,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            hasBadge
                                ? Badge(
                                    label: Text('${t.badge}',
                                        style: const TextStyle(fontSize: 8)),
                                    child: Icon(
                                      t.icon,
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    t.icon,
                                    size: 18,
                                    color: isSelected
                                        ? Colors.white
                                        : colorScheme.onSurfaceVariant,
                                  ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Text(t.label),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => _onTabSelected(i),
                        selectedColor: colorScheme.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 8 : 4,
                          vertical: 4,
                        ),
                        backgroundColor: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(child: tabBody),
              ],
            )
          : Row(
              children: [
                // NavigationRail for Tablets & Desktops
                NavigationRail(
                  selectedIndex: _selectedTabIndex,
                  onDestinationSelected: _onTabSelected,
                  labelType: NavigationRailLabelType.all,
                  minWidth: 72,
                  groupAlignment: -1.0,
                  backgroundColor: isDark
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerLowest,
                  selectedIconTheme: IconThemeData(color: colorScheme.primary),
                  unselectedIconTheme: IconThemeData(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  selectedLabelTextStyle: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary),
                  unselectedLabelTextStyle: GoogleFonts.inter(
                      fontSize: 10,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
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
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                Expanded(child: tabBody),
              ],
            ),
    );
  }
}
