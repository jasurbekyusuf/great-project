import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppEnv {
  const AppEnv({required this.baseApiUrl});

  final String baseApiUrl;
}

final appEnvProvider = Provider<AppEnv>((_) {
  const fromDefine = String.fromEnvironment('API_BASE_URL');
  return AppEnv(
    baseApiUrl: fromDefine.isEmpty ? 'https://test-api.loadme.uz/api' : fromDefine,
  );
});
