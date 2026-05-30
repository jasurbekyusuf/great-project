import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppEnv {
  const AppEnv({required this.baseApiUrl, required this.useFakeData});

  final String baseApiUrl;
  final bool useFakeData;
}

final appEnvProvider = Provider<AppEnv>((_) {
  const fromDefine = String.fromEnvironment('API_BASE_URL');
  // Flip to false (or pass --dart-define=USE_FAKE_DATA=false) once the real
  // backend URL is known. Default = local fake data so the app runs offline.
  const fakeFromDefine = String.fromEnvironment('USE_FAKE_DATA', defaultValue: 'true');
  return AppEnv(
    baseApiUrl: fromDefine.isEmpty ? 'https://test-api.loadme.uz/api' : fromDefine,
    useFakeData: fakeFromDefine.toLowerCase() != 'false',
  );
});
