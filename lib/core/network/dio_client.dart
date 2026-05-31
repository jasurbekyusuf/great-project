import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/constants/app_constants.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/storage/providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final secure = ref.watch(secureTokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: env.baseApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      queryParameters: const {'project-id': AppConstants.projectId},
      headers: const {'Environment-Id': AppConstants.environmentId},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secure.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(options.method.toUpperCase()) &&
            options.data is Map<String, dynamic> &&
            (options.data as Map<String, dynamic>).containsKey('data') == false) {
          options.data = {'data': options.data};
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
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
    if (status == 401) return const UnauthorizedFailure();
    if (status == 404) return const NotFoundFailure();
    return NetworkFailure(
      error.message ?? 'Network error',
      code: status,
      cause: error,
    );
  }
  return UnknownFailure(error.toString(), error);
}
