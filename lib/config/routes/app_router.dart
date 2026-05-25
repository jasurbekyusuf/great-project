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
import 'package:loadme_mobile/features/loads/presentation/screens/guest_loads_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_filters_screen.dart';
import 'package:loadme_mobile/features/loads/presentation/screens/loads_screen.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:loadme_mobile/features/trucks/presentation/screens/trucks_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/guest',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isAuthed = authState.valueOrNull != null;
      final inAuth = state.matchedLocation.startsWith('/auth');
      final inGuest = state.matchedLocation == '/guest';

      if (!isAuthed && !inAuth && !inGuest) return '/guest';
      if (isAuthed && (inAuth || inGuest)) return '/loads';
      return null;
    },
    routes: [
      GoRoute(path: '/guest', builder: (_, __) => const GuestLoadsScreen()),
      GoRoute(path: '/auth/splash', builder: (_, __) => const AuthSplashScreen()),
      GoRoute(path: '/auth/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/welcome', builder: (_, __) => const AuthWelcomeScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/verify', builder: (_, __) => const PhoneVerificationScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/auth/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/loads', builder: (_, __) => const LoadsScreen()),
      GoRoute(path: '/loads/filters', builder: (_, __) => const LoadsFiltersScreen()),
      GoRoute(path: '/loads/add', builder: (_, __) => const LoadFormScreen()),
      GoRoute(path: '/loads/:id', builder: (_, state) => LoadDetailsScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/loads/:id/edit', builder: (_, state) => LoadFormScreen(loadId: state.pathParameters['id']!)),
      GoRoute(path: '/trucks', builder: (_, __) => const TrucksScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );
});
