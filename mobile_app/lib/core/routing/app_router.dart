import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:mobile_app/features/admin/presentation/admin_screen.dart';
import 'package:mobile_app/features/directory/presentation/family_onboarding_screen.dart';
import 'package:mobile_app/features/directory/presentation/family_tree_screen.dart';
import 'package:mobile_app/features/directory/presentation/family_member_detail_screen.dart';
import 'package:mobile_app/features/directory/presentation/directory_screen.dart';
import 'package:mobile_app/features/directory/presentation/business_directory_screen.dart';
import 'package:mobile_app/features/auth/presentation/splash_screen.dart';
import 'package:mobile_app/features/auth/presentation/onboarding_screen.dart';

part 'app_router.g.dart';

/// A [ChangeNotifier] that listens to [AuthState] changes and notifies
/// GoRouter to re-evaluate its redirect logic without rebuilding the router.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) {
      notifyListeners();
    });
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authProvider);
}

// keepAlive: true ensures the router is NEVER recreated when auth state
// changes, which was causing the splash screen to replay on login/signup.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _AuthRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    // Handle custom deep link scheme: abrp://member/{familyId}/{memberId}
    // This redirects the custom URI to the internal /member/:familyId/:memberId route
    redirectLimit: 10,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = notifier.authState;
      final isAuthenticated = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Allow splash and onboarding screens to display without redirection
      if (isSplash || isOnboarding) return null;

      // 1. If not authenticated and not currently on login page, send to /login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // 2. If authenticated and on login page, send to home
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      // 3. Admin & Moderator guard: restrict access to /admin
      if (state.matchedLocation.startsWith('/admin')) {
        final role = authState.user?.role;
        if (role != 'admin' && role != 'moderator') {
          return '/'; // Redirect unauthorized users to Home
        }
      }

      return null; // Continue to the requested path
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/directory',
        builder: (context, state) => const DirectoryScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/onboard-family',
        builder: (context, state) => const FamilyOnboardingScreen(),
      ),
      GoRoute(
        path: '/family/:familyId/tree',
        builder: (context, state) => FamilyTreeScreen(
          familyId: int.parse(state.pathParameters['familyId']!),
        ),
      ),
      GoRoute(
        path: '/member/:familyId/:memberId',
        builder: (context, state) {
          final familyId = int.parse(state.pathParameters['familyId']!);
          final memberId = int.parse(state.pathParameters['memberId']!);
          return _MemberDeepLinkScreen(familyId: familyId, memberId: memberId);
        },
      ),
      GoRoute(
        path: '/business-directory',
        builder: (context, state) => const BusinessDirectoryScreen(),
      ),
    ],
  );
}

/// Handles deep link navigation to a specific member profile.
/// Loads the family tree data and opens the correct MemberDetailScreen.
class _MemberDeepLinkScreen extends ConsumerWidget {
  final int familyId;
  final int memberId;

  const _MemberDeepLinkScreen({required this.familyId, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(familyTreeProvider(familyId));

    return treeAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading member profile...'),
            ],
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Could not load profile: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/directory'),
                child: const Text('Go to Directory'),
              ),
            ],
          ),
        ),
      ),
      data: (treeData) {
        final member = treeData.members.firstWhere(
          (m) => m.id == memberId,
          orElse: () => treeData.members.first,
        );
        // Replace with actual member detail screen directly
        return FamilyMemberDetailScreen(
          member: member,
          familyMembers: treeData.members,
          familyId: familyId,
        );
      },
    );
  }
}
