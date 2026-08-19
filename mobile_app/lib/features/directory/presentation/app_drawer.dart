import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/localization/app_language.dart';
import 'package:mobile_app/core/localization/app_translations.dart';
import 'package:mobile_app/core/theme/theme_notifier.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';
import 'package:mobile_app/features/directory/presentation/my_family_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final lang = ref.watch(languageStateProvider);
    final user = ref.watch(authProvider).user;
    final isStaff = user?.role == 'admin' || user?.role == 'moderator';
    final currentThemeMode = ref.watch(themeModeProvider);

    return Drawer(
      width: 280,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.zero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABRP',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Akhil Bharat Rander Parivar',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  icon: Icons.person_outline,
                  title: 'My Profile',
                  onTap: () {
                    context.pop();
                    context.push('/profile');
                  },
                  primaryColor: primaryColor,
                ),
                if (isStaff) ...[
                  ExpansionTile(
                    leading: Icon(Icons.admin_panel_settings_outlined, color: primaryColor),
                    title: Text(
                      user?.role == 'admin' 
                        ? AppTranslations.get('admin_dashboard', lang) 
                        : AppTranslations.get('zone_coordinator_panel', lang),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    childrenPadding: const EdgeInsets.only(left: 16),
                    children: [
                      _buildDrawerSubItem(
                        icon: Icons.dashboard_outlined,
                        title: 'Dashboard Overview',
                        onTap: () {
                          context.pop();
                          context.push('/admin?section=-1');
                        },
                        primaryColor: primaryColor,
                      ),
                      _buildDrawerSubItem(
                        icon: Icons.groups_outlined,
                        title: 'Family Approvals',
                        onTap: () {
                          context.pop();
                          context.push('/admin?section=0');
                        },
                        primaryColor: primaryColor,
                      ),
                      _buildDrawerSubItem(
                        icon: Icons.business_center_outlined,
                        title: 'Business Approvals',
                        onTap: () {
                          context.pop();
                          context.push('/admin?section=1');
                        },
                        primaryColor: primaryColor,
                      ),
                      if (user?.role == 'admin') ...[
                        _buildDrawerSubItem(
                          icon: Icons.campaign_outlined,
                          title: 'Ad Campaigns',
                          onTap: () {
                            context.pop();
                            context.push('/admin?section=2');
                          },
                          primaryColor: primaryColor,
                        ),
                        _buildDrawerSubItem(
                          icon: Icons.manage_accounts_outlined,
                          title: 'User & Coordinator Roles',
                          onTap: () {
                            context.pop();
                            context.push('/admin?section=3');
                          },
                          primaryColor: primaryColor,
                        ),
                      ],
                      _buildDrawerSubItem(
                        icon: Icons.notifications_outlined,
                        title: 'Dispatch Notifications',
                        onTap: () {
                          context.pop();
                          final notifIndex = user?.role == 'admin' ? 4 : 2;
                          context.push('/admin?section=$notifIndex');
                        },
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ],
                _buildDrawerItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Events',
                  onTap: () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Events will be available soon.')),
                    );
                  },
                  primaryColor: primaryColor,
                ),
                _buildDrawerItem(
                  icon: Icons.storefront_outlined,
                  title: 'Business Directory',
                  onTap: () {
                    context.pop();
                    context.push('/business-directory');
                  },
                  primaryColor: primaryColor,
                ),
                _buildDrawerItem(
                  icon: Icons.campaign_outlined,
                  title: 'Active Ads & Offers',
                  onTap: () {
                    context.pop();
                    context.push('/ads');
                  },
                  primaryColor: primaryColor,
                ),
                _buildDrawerItem(
                  icon: Icons.account_tree_outlined,
                  title: 'Family Tree',
                  onTap: () async {
                    context.pop();
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );
                    ref.read(myFamilyProvider.future).then((myFamilyVal) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (myFamilyVal != null && myFamilyVal['family'] != null) {
                          final familyId = myFamilyVal['family']['id'];
                          context.push('/family/$familyId/tree');
                        } else {
                          context.push('/onboard-family');
                        }
                      }
                    }).catchError((_) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        context.push('/onboard-family');
                      }
                    });
                  },
                  primaryColor: primaryColor,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Divider(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    height: 1,
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.groups_outlined,
                  title: 'Committee',
                  onTap: () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Committee details will be available soon.')),
                    );
                  },
                  primaryColor: primaryColor,
                ),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support will be available soon.')),
                    );
                  },
                  primaryColor: primaryColor,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  child: Divider(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    height: 1,
                  ),
                ),

                // Theme Mode Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: Text(
                          'APPEARANCE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildThemeOption(
                              context: context,
                              ref: ref,
                              mode: ThemeMode.light,
                              currentMode: currentThemeMode,
                              icon: Icons.light_mode_outlined,
                              selectedIcon: Icons.light_mode,
                              label: 'Light',
                              activeColor: primaryColor,
                            ),
                            _buildThemeOption(
                              context: context,
                              ref: ref,
                              mode: ThemeMode.dark,
                              currentMode: currentThemeMode,
                              icon: Icons.dark_mode_outlined,
                              selectedIcon: Icons.dark_mode,
                              label: 'Dark',
                              activeColor: primaryColor,
                            ),
                            _buildThemeOption(
                              context: context,
                              ref: ref,
                              mode: ThemeMode.system,
                              currentMode: currentThemeMode,
                              icon: Icons.brightness_auto_outlined,
                              selectedIcon: Icons.brightness_auto,
                              label: 'Auto',
                              activeColor: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Donate Now Button
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Material(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Donate feature coming soon. Thank you for your generosity!')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 14),
                            Text(
                              'Donate Now',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.pop();
              ref.read(authProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDrawerSubItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: primaryColor.withValues(alpha: 0.8), size: 20),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = currentMode == mode;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
