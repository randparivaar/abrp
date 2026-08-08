import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/localization/app_language.dart';
import 'package:mobile_app/core/localization/app_translations.dart';
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
                if (isStaff)
                  _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: user?.role == 'admin' 
                      ? AppTranslations.get('admin_dashboard', lang) 
                      : AppTranslations.get('zone_coordinator_panel', lang),
                    onTap: () {
                      context.pop();
                      context.push('/admin');
                    },
                    primaryColor: primaryColor,
                  ),
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
}
