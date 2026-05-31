import 'package:get_it/get_it.dart';

/// Global service locator instance.
///
/// Centralised dependency wiring complements Riverpod providers:
/// - **Riverpod** owns UI-tied state and feature controllers.
/// - **GetIt** owns app-level singletons (Logger, Storage, ApiClient) and
///   pure-Dart services (UseCases, Repositories) that don't need a `Ref`.
///
/// Register in `lib/core/di/register_dependencies.dart` once at app startup.
final getIt = GetIt.instance;
