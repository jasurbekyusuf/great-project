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
import 'package:loadme_mobile/features/loads/presentation/screens/load_details_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/load_form_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_filters_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/my_loads_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/faq_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/instructions_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/premium_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/privacy_policy_screen.dart';
import 'package:loadme_mobile/features/info/presentation/screens/terms_screen.dart';
import 'package:loadme_mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/default_commission_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_edit_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_statistics_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/saved_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/support_feedback_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/my_truck_detail_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/post_truck_detail_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/post_truck_form_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/truck_form_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/trucks_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/my_trucks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/guest',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthed = authState.valueOrNull != null;
      final inAuth = state.matchedLocation.startsWith('/auth');
      final inGuest = state.matchedLocation.startsWith('/guest');

      if (!isAuthed && !inAuth && !inGuest) return '/guest';
      if (isAuthed && (inAuth || inGuest)) return '/my-loads';
      return null;
    },
    routes: [
      // Guest mode reuses the same authed screens with `guest: true`.
      GoRoute(path: '/guest', builder: (_, __) => const LoadsScreen(guest: true)),
      GoRoute(path: '/guest-trucks', builder: (_, __) => const TrucksScreen()),
      GoRoute(
          path: '/guest-filters',
          builder: (_, __) => const LoadsFiltersScreen()),
      GoRoute(
          path: '/guest-load/:id',
          builder: (_, state) =>
              LoadDetailsScreen(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/guest-post-truck/:id',
          builder: (_, state) =>
              PostTruckDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/auth/splash', builder: (_, __) => const AuthSplashScreen()),
      GoRoute(
          path: '/auth/onboarding',
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(
          path: '/auth/welcome', builder: (_, __) => const AuthWelcomeScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/auth/verify',
          builder: (_, __) => const PhoneVerificationScreen()),
      GoRoute(
          path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/auth/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/loads', builder: (_, __) => const LoadsScreen()),
      GoRoute(path: '/my-loads', builder: (_, __) => const MyLoadsScreen()),
      GoRoute(
          path: '/loads/filters',
          builder: (_, __) => const LoadsFiltersScreen()),
      GoRoute(path: '/loads/add', builder: (_, __) => const LoadFormScreen()),
      GoRoute(path: '/add-load', builder: (_, __) => const LoadFormScreen()),
      GoRoute(
          path: '/loads/:id',
          builder: (_, state) =>
              LoadDetailsScreen(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/my-load/:id',
          builder: (_, state) => LoadDetailsScreen(
                id: state.pathParameters['id']!,
                ownerMode: true,
                isActive: state.uri.queryParameters['active'] != 'false',
              )),
      GoRoute(
          path: '/loads/:id/edit',
          builder: (_, state) =>
              LoadFormScreen(loadId: state.pathParameters['id'])),
      GoRoute(
          path: '/edit-load/:id',
          builder: (_, state) =>
              LoadFormScreen(loadId: state.pathParameters['id'])),
      GoRoute(path: '/trucks', builder: (_, __) => const TrucksScreen()),
      GoRoute(path: '/my-trucks', builder: (_, __) => const MyTrucksScreen()),
      GoRoute(path: '/add-truck', builder: (_, __) => const TruckFormScreen()),
      GoRoute(
          path: '/edit-truck/:id',
          builder: (_, state) =>
              TruckFormScreen(truckId: state.pathParameters['id'])),
      GoRoute(
          path: '/add-post-truck',
          builder: (_, __) => const PostTruckFormScreen()),
      GoRoute(
        path: '/edit-post-truck/:id',
        builder: (_, state) =>
            PostTruckFormScreen(postTruckId: state.pathParameters['id']),
      ),
      GoRoute(
          path: '/post-truck/:id',
          builder: (_, state) =>
              PostTruckDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(
          path: '/my-post-truck-detail/:id',
          builder: (_, state) => PostTruckDetailScreen(
                id: state.pathParameters['id']!,
                ownerMode: true,
                isActive: state.uri.queryParameters['active'] != 'false',
              )),
      GoRoute(
          path: '/my-truck/:id',
          builder: (_, state) => MyTruckDetailScreen(
                id: state.pathParameters['id']!,
                isActive: state.uri.queryParameters['active'] != 'false',
              )),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const ProfileEditScreen()),
      GoRoute(path: '/profile/statistics', builder: (_, __) => const ProfileStatisticsScreen()),
      GoRoute(path: '/profile/saved', builder: (_, __) => const SavedScreen()),
      GoRoute(path: '/profile/default-commission', builder: (_, __) => const DefaultCommissionScreen()),
      GoRoute(path: '/profile/support-feedback', builder: (_, __) => const SupportFeedbackScreen()),
      GoRoute(path: '/profile/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/instructions', builder: (_, __) => const InstructionsScreen()),
      GoRoute(path: '/faq', builder: (_, __) => const FaqScreen()),
      GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
    ],
  );
});
