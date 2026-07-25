import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_app/features/auth/presentation/auth_controller.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:mobile_app/features/admin/presentation/admin_screen.dart';
import 'package:mobile_app/features/directory/presentation/family_onboarding_screen.dart';
import 'package:mobile_app/features/directory/presentation/family_tree_screen.dart';
import 'package:mobile_app/features/directory/presentation/directory_screen.dart';
import 'package:mobile_app/features/directory/presentation/business_directory_screen.dart';
import 'package:mobile_app/features/auth/presentation/splash_screen.dart';
import 'package:mobile_app/features/auth/presentation/onboarding_screen.dart';

part 'app_router.g.dart';

/// A [ChangeNotifier] that listens to [AuthState] changes and notifies
/// GoRouter to re-evaluate its redirect logic without rebuilding the router.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) {
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
    // refreshListenable triggers redirect() re-evaluation without rebuilding
    // the router itself, so the current location is preserved.
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

      // 3. Admin guard: restrict access to /admin
      if (state.matchedLocation.startsWith('/admin')) {
        final role = authState.user?.role;
        if (role != 'admin') {
          return '/'; // Redirect non-admins to Home
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
        path: '/business-directory',
        builder: (context, state) => const BusinessDirectoryScreen(),
      ),
    ],
  );
}
