import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/storage/providers.dart';

/// Maps the app locale to the backend's `Accept-Language` header so it can
/// localise country/region/truck-type names and error messages.
///   uz + Cyrl -> "uz-cyrl",  ru -> "ru",  en -> "en",  else -> "uz".
String _acceptLanguage(Locale locale) {
  if (locale.languageCode == 'uz' && locale.scriptCode == 'Cyrl') {
    return 'uz-cyrl';
  }
  switch (locale.languageCode) {
    case 'ru':
      return 'ru';
    case 'en':
      return 'en';
    case 'uz':
    default:
      return 'uz';
  }
}

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final secure = ref.watch(secureTokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.baseApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // `__anon` requests skip the token on purpose (anonymous retry of a
        // public feed after a stale token was rejected) — see onError below.
        if (options.extra['__anon'] != true) {
          final token = await secure.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        options.headers['Accept-Language'] =
            _acceptLanguage(ref.read(localeProvider));
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final isRefreshCall =
            error.requestOptions.path.contains('/users/token/refresh');
        final alreadyRetried = error.requestOptions.extra['__retried'] == true;

        // On 401, try to refresh the JWT once, then replay the original request.
        if (status == 401 && !isRefreshCall && !alreadyRetried) {
          final refreshToken = await secure.readRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: env.baseApiUrl));
              final res = await refreshDio.post<dynamic>(
                '/users/token/refresh/',
                data: {'refresh': refreshToken},
              );
              final body = res.data;
              final data = (body is Map && body['data'] is Map)
                  ? body['data'] as Map
                  : (body is Map ? body : const <dynamic, dynamic>{});
              final newAccess = data['access']?.toString();
              final newRefresh = data['refresh']?.toString();
              if (newAccess != null && newAccess.isNotEmpty) {
                await secure.writeAccessToken(newAccess);
                if (newRefresh != null && newRefresh.isNotEmpty) {
                  await secure.writeRefreshToken(newRefresh);
                }
                final req = error.requestOptions;
                req.headers['Authorization'] = 'Bearer $newAccess';
                req.extra['__retried'] = true;
                final replay = await dio.fetch<dynamic>(req);
                return handler.resolve(replay);
              }
            } catch (_) {
              await secure.clear();
            }
          }
        }

        // Public marketplace feeds (`/loads/available/`,
        // `/trucks/routes/available/`) are readable without auth, but the
        // backend rejects a *stale* token with 401. If we still have a 401
        // here (no refresh token, or the refresh failed), replay the request
        // once anonymously so guests — and users whose session expired — keep
        // seeing the public feed instead of an Unauthorized error.
        final isPublicFeed = error.requestOptions.path.contains('/available');
        final triedAnon = error.requestOptions.extra['__anon'] == true;
        if (status == 401 && isPublicFeed && !triedAnon) {
          final req = error.requestOptions;
          req.extra['__anon'] = true;
          req.extra['__retried'] = true;
          req.headers.remove('Authorization');
          try {
            final replay = await dio.fetch<dynamic>(req);
            return handler.resolve(replay);
          } catch (_) {
            // Fall through to the normal 401 handling below.
          }
        }

        if (status == 401) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: const UnauthorizedFailure('Unauthorized'),
              response: error.response,
            ),
          );
          return;
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// Maps any thrown object (typically [DioException]) into a typed [AppFailure].
///
/// Repository methods catch and run their throw through this helper before
/// converting it into a `Result<T>`. Never returns a generic Exception.
AppFailure mapDioException(Object error) {
  if (error is DioException) {
    if (error.error is AppFailure) return error.error! as AppFailure;
    final status = error.response?.statusCode;
    final backendMessage = _backendMessage(error.response?.data);
    if (status == 401) return const UnauthorizedFailure();
    if (status == 404) return const NotFoundFailure();
    return NetworkFailure(
      backendMessage ?? error.message ?? 'Network error',
      code: status,
      cause: error,
    );
  }
  return UnknownFailure(error.toString(), error);
}

/// Pulls a human-readable message out of the backend error envelope.
/// Handles `{ detail }`, `{ message }`, and the `{ success:false, data:{...} }`
/// wrapper, falling back to the first field error DRF returns.
String? _backendMessage(Object? data) {
  if (data is! Map) return null;
  final inner = data['data'] is Map ? data['data'] as Map : data;
  final detail = inner['detail'] ?? inner['message'] ?? data['detail'] ?? data['message'];
  if (detail != null) return detail.toString();
  // DRF field errors: { field: ["msg", ...] }
  for (final value in inner.values) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.isNotEmpty) return value;
  }
  return null;
}
