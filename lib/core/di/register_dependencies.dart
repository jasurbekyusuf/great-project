import 'package:loadme_mobile/core/di/service_locator.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:logger/logger.dart';

/// Register app-level singletons in the GetIt service locator.
///
/// Called once from `main()` before the app boots. Riverpod still owns
/// UI-tied state; [getIt] holds pure-Dart services that don't need a `Ref`.
Future<void> registerDependencies() async {
  if (getIt.isRegistered<Logger>()) return; // hot-restart guard

  getIt
    .registerSingleton<Logger>(AppLogger.instance);
}
