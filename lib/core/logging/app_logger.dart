import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// App-wide logger.
///
/// Use through [appLogger] for ad-hoc logs, or call [AppLogger.tagged] from
/// a class to get a namespaced logger:
///
/// ```dart
/// final _log = AppLogger.tagged('AuthRepository');
/// _log.i('User logged in: $guid');
/// _log.e('Login failed', failure);
/// ```
///
/// In release builds the logger uses [Level.warning] to keep output quiet;
/// in debug builds it stays at [Level.debug] for full visibility.
class AppLogger {
  AppLogger._();

  static final Logger _instance = Logger(
    level: kReleaseMode ? Level.warning : Level.debug,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static Logger get instance => _instance;

  /// Returns a logger that prepends [tag] to every message.
  static _TaggedLogger tagged(String tag) => _TaggedLogger(tag, _instance);
}

/// Top-level convenience for quick logging.
Logger get appLogger => AppLogger.instance;

class _TaggedLogger {
  const _TaggedLogger(this._tag, this._logger);
  final String _tag;
  final Logger _logger;

  void t(Object? msg, [Object? error, StackTrace? st]) =>
      _logger.t('[$_tag] $msg', error: error, stackTrace: st);
  void d(Object? msg, [Object? error, StackTrace? st]) =>
      _logger.d('[$_tag] $msg', error: error, stackTrace: st);
  void i(Object? msg, [Object? error, StackTrace? st]) =>
      _logger.i('[$_tag] $msg', error: error, stackTrace: st);
  void w(Object? msg, [Object? error, StackTrace? st]) =>
      _logger.w('[$_tag] $msg', error: error, stackTrace: st);
  void e(Object? msg, [Object? error, StackTrace? st]) =>
      _logger.e('[$_tag] $msg', error: error, stackTrace: st);
}
