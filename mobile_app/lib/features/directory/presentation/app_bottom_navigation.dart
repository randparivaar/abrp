import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/directory/presentation/my_family_provider.dart';

class AppBottomNavigation extends ConsumerWidget {
  final int currentIndex;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: colorScheme.secondary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) async {
          if (index == currentIndex) return;

          if (index == 0) {
            context.go('/');
          } else if (index == 1) {
            context.go('/directory');
          } else if (index == 2) {
            // Check if family is onboarded
            final myFamilyAsync = ref.read(myFamilyProvider);
            final myFamilyVal = myFamilyAsync.value;
            if (myFamilyVal != null && myFamilyVal['family'] != null) {
              final familyId = myFamilyVal['family']['id'];
              context.go('/family/$familyId/tree');
            } else {
              try {
                final myFamily = await ref.refresh(myFamilyProvider.future);
                if (myFamily != null && myFamily['family'] != null) {
                  final familyId = myFamily['family']['id'];
                  if (context.mounted) {
                    context.go('/family/$familyId/tree');
                  }
                } else {
                  if (context.mounted) {
                    context.go('/onboard-family');
                  }
                }
              } catch (_) {
                if (context.mounted) {
                  context.go('/onboard-family');
                }
              }
            }
          } else if (index == 3) {
            context.go('/ads');
          } else if (index == 4) {
            Scaffold.of(context).openDrawer();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Directory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_outlined),
            activeIcon: Icon(Icons.account_tree),
            label: 'Tree',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Ads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
