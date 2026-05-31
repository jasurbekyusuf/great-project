import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/core/result/result.dart';

/// Repository-side helper that runs a block, logs any thrown error, maps it
/// to a typed `AppFailure` and returns a `Result<T>`.
///
/// Every repository implementation should funnel its remote/storage calls
/// through this — keeping `try/catch` out of the rest of the codebase.
///
/// ```dart
/// AsyncResult<User> getUser(String id) =>
///     Guard.run(() => _remote.fetchUser(id), tag: 'UserRepository');
/// ```
class Guard {
  const Guard._();

  static AsyncResult<T> run<T>(
    Future<T> Function() block, {
    String tag = 'Repository',
  }) async {
    try {
      return success(await block());
    } catch (e, st) {
      AppLogger.tagged(tag).e('error', e, st);
      return failure(mapDioException(e));
    }
  }
}
