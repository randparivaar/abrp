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
import 'package:mobile_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:mobile_app/features/directory/presentation/active_ads_screen.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/directory/presentation/business_profile_detail_screen.dart';
import 'package:mobile_app/features/events/presentation/events_list_screen.dart';
import 'package:mobile_app/features/profile/presentation/privacy_policy_screen.dart';
import 'package:mobile_app/features/profile/presentation/terms_and_conditions_screen.dart';
import 'package:mobile_app/features/profile/presentation/faq_support_screen.dart';
import 'package:mobile_app/features/profile/presentation/donation_screen.dart';
import 'package:mobile_app/features/profile/presentation/committee_screen.dart';

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
    // and abrp://business/{id}
    redirectLimit: 10,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = notifier.authState;
      final isAuthenticated = authState.user != null;

      // Handle custom deep link scheme (abrp://business/123 or abrp://member/1/2)
      if (state.uri.scheme == 'abrp') {
        final host = state.uri.host;
        final segments = state.uri.pathSegments;
        if (host == 'business' || (segments.isNotEmpty && segments.first == 'business')) {
          final id = segments.isNotEmpty ? segments.last : '';
          if (id.isNotEmpty) return '/business/$id';
        }
        if (host == 'member' || (segments.isNotEmpty && segments.first == 'member')) {
          if (segments.length >= 2) {
            return '/member/${segments[segments.length - 2]}/${segments.last}';
          }
        }
      }

      final isLoggingIn = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      final isPrivacy = state.matchedLocation == '/privacy-policy';
      final isTerms = state.matchedLocation == '/terms-and-conditions';
      final isHelpSupport = state.matchedLocation == '/help-support';

      // Allow splash, onboarding, forgot password, and legal screens to display without redirection
      if (isSplash || isOnboarding || isForgotPassword || isPrivacy || isTerms || isHelpSupport) return null;

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
      // ── Auth flow: top-level (no back-stack parent needed) ──
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
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Legal pages at top-level for unauthenticated access (from login screen)
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-and-conditions',
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/help-support',
        builder: (context, state) => const FaqSupportScreen(),
      ),

      // ── Main app: nested under '/' so back gesture pops to Home ──
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'donate',
            builder: (context, state) => const DonationScreen(),
          ),
          GoRoute(
            path: 'committee',
            builder: (context, state) => const CommitteeScreen(),
          ),
          GoRoute(
            path: 'directory',
            builder: (context, state) => const DirectoryScreen(),
          ),
          GoRoute(
            path: 'admin',
            builder: (context, state) {
              final secParam = state.uri.queryParameters['section'];
              return AdminScreen(section: secParam);
            },
          ),
          GoRoute(
            path: 'onboard-family',
            builder: (context, state) => const FamilyOnboardingScreen(),
          ),
          GoRoute(
            path: 'family/:familyId/tree',
            builder: (context, state) => FamilyTreeScreen(
              familyId: int.parse(state.pathParameters['familyId']!),
            ),
          ),
          GoRoute(
            path: 'member/:familyId/:memberId',
            builder: (context, state) {
              final familyId = int.parse(state.pathParameters['familyId']!);
              final memberId = int.parse(state.pathParameters['memberId']!);
              return _MemberDeepLinkScreen(familyId: familyId, memberId: memberId);
            },
          ),
          GoRoute(
            path: 'business-directory',
            builder: (context, state) => const BusinessDirectoryScreen(),
          ),
          GoRoute(
            path: 'ads',
            builder: (context, state) => const ActiveAdsScreen(),
          ),
          GoRoute(
            path: 'events',
            builder: (context, state) => const EventsListScreen(),
          ),
          GoRoute(
            path: 'business/:businessId',
            builder: (context, state) {
              final businessId = int.parse(state.pathParameters['businessId']!);
              return _BusinessDeepLinkScreen(businessId: businessId);
            },
          ),
        ],
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

/// Handles deep link navigation to a specific business profile.
/// Fetches the business details and displays BusinessProfileDetailScreen.
class _BusinessDeepLinkScreen extends ConsumerStatefulWidget {
  final int businessId;

  const _BusinessDeepLinkScreen({required this.businessId});

  @override
  ConsumerState<_BusinessDeepLinkScreen> createState() => _BusinessDeepLinkScreenState();
}

class _BusinessDeepLinkScreenState extends ConsumerState<_BusinessDeepLinkScreen> {
  BusinessProfile? _business;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBusiness();
  }

  Future<void> _fetchBusiness() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get('/directory/businesses');
      final list = (response.data['businesses'] as List<dynamic>? ?? []);
      final found = list.firstWhere(
        (b) => b['id'] == widget.businessId,
        orElse: () => null,
      );

      if (found != null) {
        if (mounted) {
          setState(() {
            _business = BusinessProfile.fromJson(found);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Business profile not found.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load business profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading business profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _business == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.storefront_outlined, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(_error ?? 'Could not find business profile.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/business-directory'),
                  child: const Text('Go to Business Directory'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BusinessProfileDetailScreen(business: _business!);
  }
}
