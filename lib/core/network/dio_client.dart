import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/constants/app_constants.dart';
import 'package:loadme_mobile/core/errors/failure.dart';
import 'package:loadme_mobile/core/storage/providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final env = ref.watch(appEnvProvider);
  final storage = ref.watch(storageProvider);
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
        final token = await storage.read('access_token');
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

Failure mapDioException(Object error) {
  if (error is DioException && error.error is Failure) {
    return error.error! as Failure;
  }
  if (error is DioException) {
    return NetworkFailure(error.message ?? 'Network error', code: error.response?.statusCode);
  }
  return const UnknownFailure('Unknown error');
}
