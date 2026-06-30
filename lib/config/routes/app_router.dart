import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/auth_splash_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/auth_welcome_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/phone_verification_screen.dart';
import 'package:loadme_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:loadme_mobile/features/garage/presentation/screens/garage_screen.dart';
import 'package:loadme_mobile/features/garage/presentation/screens/transport_detail_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/faq_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/instructions_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/premium_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/privacy_policy_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/terms_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/load_details_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/load_form_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_filters_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/my_loads_screen.dart';
import 'package:loadme_mobile/features/locations/presentation/screens/location_permission_screen.dart';
import 'package:loadme_mobile/features/magnit/presentation/screens/magnit_screen.dart';
import 'package:loadme_mobile/features/market/presentation/screens/market_screen.dart';
import 'package:loadme_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notification_detail_screen.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/default_commission_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/saved_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/support_chat_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/support_feedback_screen.dart';
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

/// Pure auth-gate decision, factored out of the router so it can be unit-tested
/// without spinning up a widget tree. Returns the path to redirect to, or null
/// to stay put.
///
/// - A logged-out user outside the guest/auth areas is sent to `/guest`.
/// - A logged-in user sitting on a guest/auth screen (e.g. the cold-start
///   landing, or right after login) is sent to their role home: carrier looks
///   for cargo (`/loads`); shipper / broker look for trucks (`/trucks`). Mirrors
///   the web `getPostLoginPath`.
String? resolveStartupRedirect({
  required bool isAuthed,
  required String location,
  required String role,
}) {
  final inAuth = location.startsWith('/auth');
  final inGuest = location.startsWith('/guest');

  if (!isAuthed && !inAuth && !inGuest) return '/guest';
  if (isAuthed && (inAuth || inGuest)) {
    return role == 'carrier' ? '/loads' : '/trucks';
  }
  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/guest',
    redirect: (context, state) => resolveStartupRedirect(
      isAuthed: ref.read(authControllerProvider).valueOrNull != null,
      location: state.matchedLocation,
      role: ref.read(currentUserRoleSyncProvider),
    ),
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
        builder: (_, state) => TransportDetailScreen(id: state.pathParameters['id']!),
      ),

      // ---- Auth flow (no bottom nav) ---------------------------------------
      GoRoute(path: '/auth/splash', builder: (_, __) => const AuthSplashScreen()),
      GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/welcome', builder: (_, __) => const AuthWelcomeScreen()),
      GoRoute(path: '/auth/verify', builder: (_, __) => const PhoneVerificationScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),

      // ---- Post-registration location primer (no bottom nav) ---------------
      // Top-level (NOT under /auth) so the now-authed user isn't bounced to
      // their role home by the redirect before they see the location prompt.
      GoRoute(
        path: '/location-permission',
        builder: (_, __) => const LocationPermissionScreen(),
      ),

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
                    // Render above the shell (root navigator) so the bottom
                    // nav bar is hidden — the Figma filter screen is full-screen.
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const LoadsFiltersScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/trucks',
                builder: (_, __) => const MarketScreen(initialTab: MarketTab.trucks),
              ),
            ],
          ),

          // Branch 1 — Post (add load / truck / posted truck)
          StatefulShellBranch(
            navigatorKey: _postKey,
            routes: [
              GoRoute(
                path: '/add-post-truck',
                builder: (_, __) => const PostTruckFormScreen(),
              ),
            ],
          ),

          // Branch 2 — Garaj (vehicles + saved routes); my-loads/trucks kept
          // as reachable sub-routes but no longer the tab's landing screen.
          StatefulShellBranch(
            navigatorKey: _myKey,
            initialLocation: '/garage',
            routes: [
              GoRoute(
                path: '/garage',
                builder: (_, __) => const GarageScreen(),
              ),
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
                  GoRoute(
                    path: 'chat',
                    // Full-screen chat (Figma "Bog'lanish") — render above the
                    // shell so the bottom nav bar is hidden.
                    parentNavigatorKey: _rootKey,
                    builder: (_, __) => const SupportChatScreen(),
                  ),
                  GoRoute(path: 'premium', builder: (_, __) => const PremiumScreen()),
                ],
              ),
              GoRoute(path: '/instructions', builder: (_, __) => const InstructionsScreen()),
              GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
              GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
              GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
            ],
          ),
        ],
      ),

      // ---- Full-screen detail pages (root navigator → no bottom nav) ------
      // Defined as top-level routes (siblings of the shell) so they render
      // above it. go_router forbids a shell sub-route from pointing at the
      // root navigator key, hence they live here rather than in a branch.
      GoRoute(
        path: '/loads/:id',
        builder: (_, state) =>
            LoadDetailsScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post-truck/:id',
        builder: (_, state) =>
            TransportDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/my-load/:id',
        builder: (_, state) => LoadDetailsScreen(
          id: state.pathParameters['id']!,
          ownerMode: true,
          isActive: state.uri.queryParameters['active'] != 'false',
        ),
      ),
      // Add-load form — full-screen task page (no bottom nav, back chevron),
      // opened from the centre "+" nav button (shipper/broker) and the
      // "Mening yuklarim" empty-state CTA. Lives at the root navigator so the
      // bottom navigation bar is hidden, matching the Figma full-page design.
      GoRoute(
        path: '/add-load',
        builder: (_, __) => const LoadFormScreen(),
      ),
      // Add-transport form — full-screen task page (no bottom nav), reached via
      // the garage "Qo'shish" CTA / my-trucks header.
      // Magnit — load-matching alert form, opened from the centre nav button.
      GoRoute(path: '/magnit', builder: (_, __) => const MagnitScreen()),
      // Xabarlar — full-screen notifications overlay opened from the bottom-nav
      // Xabarlar slot. Lives at the root navigator (like /magnit) so the push
      // sits cleanly ABOVE the shell and pops back to whatever branch was
      // active. Previously this was nested under the Profile branch, which
      // tangled it with the IndexedStack and intermittently surfaced Xabarlar
      // when switching to another tab (Garaj).
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
        routes: [
          GoRoute(
            path: 'announcement',
            builder: (_, state) => NotificationDetailScreen(
              notification: state.extra is AppNotification
                  ? state.extra! as AppNotification
                  : null,
            ),
          ),
        ],
      ),
      // Transport detail — opened from a Garaj → Transportlar card.
      GoRoute(
        path: '/transport/:id',
        builder: (_, state) =>
            TransportDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/add-truck',
        builder: (_, __) => const TruckFormScreen(),
      ),
    ],
  );
});
