import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/auth_splash_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/auth_welcome_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/phone_verification_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/faq_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/instructions_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/premium_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/privacy_policy_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/terms_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/load_details_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/load_form_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_filters_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/my_loads_screen.dart';
import 'package:loadme_mobile/features/market/presentation/screens/market_screen.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/default_commission_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/saved_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/support_feedback_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/my_truck_detail_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/my_trucks_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/post_truck_detail_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/post_truck_form_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/truck_form_screen.dart';
import 'package:loadme_mobile/shared/widgets/scaffold_with_nav.dart';

// Each top-level tab gets its own Navigator key so its back-stack is preserved
// across tab switches (StatefulShellRoute pattern).
final _rootKey = GlobalKey<NavigatorState>();
final _searchKey = GlobalKey<NavigatorState>();
final _postKey = GlobalKey<NavigatorState>();
final _myKey = GlobalKey<NavigatorState>();
final _profileKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/guest',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthed = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final inAuth = loc.startsWith('/auth');
      final inGuest = loc.startsWith('/guest');

      if (!isAuthed && !inAuth && !inGuest) return '/guest';
      if (isAuthed && (inAuth || inGuest)) return '/my-loads';
      return null;
    },
    routes: [
      // ---- Guest mode (no bottom nav, single screen) ------------------------
      GoRoute(
        path: '/guest',
        builder: (_, __) => const MarketScreen(guest: true),
      ),
      GoRoute(
        path: '/guest-trucks',
        builder: (_, __) =>
            const MarketScreen(guest: true, initialTab: MarketTab.trucks),
      ),
      GoRoute(path: '/guest-filters', builder: (_, __) => const LoadsFiltersScreen()),
      GoRoute(
        path: '/guest-load/:id',
        builder: (_, state) => LoadDetailsScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/guest-post-truck/:id',
        builder: (_, state) => PostTruckDetailScreen(id: state.pathParameters['id']!),
      ),

      // ---- Auth flow (no bottom nav) ---------------------------------------
      GoRoute(path: '/auth/splash', builder: (_, __) => const AuthSplashScreen()),
      GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/welcome', builder: (_, __) => const AuthWelcomeScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/verify', builder: (_, __) => const PhoneVerificationScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ---- Authed shell with bottom nav (4 independent stacks) -------------
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          // Branch 0 — Search (loads + trucks tabs share the same root URL)
          StatefulShellBranch(
            navigatorKey: _searchKey,
            routes: [
              GoRoute(
                path: '/loads',
                builder: (_, __) => const MarketScreen(),
                routes: [
                  GoRoute(
                    path: 'filters',
                    builder: (_, __) => const LoadsFiltersScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        LoadDetailsScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: '/trucks',
                builder: (_, __) => const MarketScreen(initialTab: MarketTab.trucks),
              ),
              GoRoute(
                path: '/post-truck/:id',
                builder: (_, state) =>
                    PostTruckDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),

          // Branch 1 — Post (add load / truck / posted truck)
          StatefulShellBranch(
            navigatorKey: _postKey,
            routes: [
              GoRoute(path: '/add-load', builder: (_, __) => const LoadFormScreen()),
              GoRoute(path: '/add-truck', builder: (_, __) => const TruckFormScreen()),
              GoRoute(
                path: '/add-post-truck',
                builder: (_, __) => const PostTruckFormScreen(),
              ),
            ],
          ),

          // Branch 2 — My loads / trucks + edit forms + detail
          StatefulShellBranch(
            navigatorKey: _myKey,
            routes: [
              GoRoute(
                path: '/my-loads',
                builder: (_, __) => const MyLoadsScreen(),
                routes: [
                  GoRoute(
                    path: 'edit/:id',
                    builder: (_, state) =>
                        LoadFormScreen(loadId: state.pathParameters['id']),
                  ),
                ],
              ),
              GoRoute(
                path: '/my-trucks',
                builder: (_, __) => const MyTrucksScreen(),
              ),
              GoRoute(
                path: '/my-load/:id',
                builder: (_, state) => LoadDetailsScreen(
                  id: state.pathParameters['id']!,
                  ownerMode: true,
                  isActive: state.uri.queryParameters['active'] != 'false',
                ),
              ),
              GoRoute(
                path: '/my-truck/:id',
                builder: (_, state) => MyTruckDetailScreen(
                  id: state.pathParameters['id']!,
                  isActive: state.uri.queryParameters['active'] != 'false',
                ),
              ),
              GoRoute(
                path: '/my-post-truck-detail/:id',
                builder: (_, state) => PostTruckDetailScreen(
                  id: state.pathParameters['id']!,
                  ownerMode: true,
                  isActive: state.uri.queryParameters['active'] != 'false',
                ),
              ),
              GoRoute(
                path: '/edit-load/:id',
                builder: (_, state) =>
                    LoadFormScreen(loadId: state.pathParameters['id']),
              ),
              GoRoute(
                path: '/edit-truck/:id',
                builder: (_, state) =>
                    TruckFormScreen(truckId: state.pathParameters['id']),
              ),
              GoRoute(
                path: '/edit-post-truck/:id',
                builder: (_, state) =>
                    PostTruckFormScreen(postTruckId: state.pathParameters['id']),
              ),
            ],
          ),

          // Branch 3 — Profile + all its sub-screens + info pages
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(path: 'edit', builder: (_, __) => const ProfileEditScreen()),
                  GoRoute(
                    path: 'statistics',
                    builder: (_, __) => const ProfileStatisticsScreen(),
                  ),
                  GoRoute(path: 'saved', builder: (_, __) => const SavedScreen()),
                  GoRoute(
                    path: 'default-commission',
                    builder: (_, __) => const DefaultCommissionScreen(),
                  ),
                  GoRoute(
                    path: 'support-feedback',
                    builder: (_, __) => const SupportFeedbackScreen(),
                  ),
                  GoRoute(path: 'premium', builder: (_, __) => const PremiumScreen()),
                ],
              ),
              GoRoute(path: '/instructions', builder: (_, __) => const InstructionsScreen()),
              GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
              GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
              GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
              GoRoute(
                path: '/notifications',
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
