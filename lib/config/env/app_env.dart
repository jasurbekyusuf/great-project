import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selectable backend targets.
///
/// Pick one at build/run time with `--dart-define=ENV=local` (defaults to
/// `prod`). To point at an ad-hoc host (a teammate's machine, an ngrok tunnel)
/// without touching code, pass `--dart-define=API_ORIGIN=http://192.168.1.5:8000`.
enum AppEnvironment { local, prod }

class AppEnv {
  const AppEnv({required this.environment, required this.origin});

  final AppEnvironment environment;

  /// Scheme + host (+ port), no trailing slash, e.g.
  /// `https://backend-dev.loadme.uz`. Used directly as the REST origin and to
  /// absolutise the relative `/media/...` URLs the backend returns.
  final String origin;

  /// REST root the Dio client talks to: `<origin>/api/v1`.
  String get baseApiUrl => '$origin/api/v1';

  /// WebSocket origin derived from [origin]: `https` → `wss`, `http` → `ws`.
  /// The support-chat socket appends `/ws/support/chat/?token=…|guest_id=…`.
  String get wsOrigin => origin.startsWith('https')
      ? origin.replaceFirst('https', 'wss')
      : origin.replaceFirst('http', 'ws');

  bool get isLocal => environment == AppEnvironment.local;
}

// Backend origins (no trailing slash, no `/api/v1`). `prod` mirrors the web
// client's `.env.production`, which currently targets the public dev server.
const _localOrigin = 'http://10.0.18.110:8000';
const _prodOrigin = 'https://backend-dev.loadme.uz';

final appEnvProvider = Provider<AppEnv>((_) {
  const envName = String.fromEnvironment('ENV', defaultValue: 'prod');
  const originOverride = String.fromEnvironment('API_ORIGIN');

  final environment = switch (envName.toLowerCase()) {
    'local' => AppEnvironment.local,
    _ => AppEnvironment.prod,
  };

  var origin = originOverride.isNotEmpty
      ? originOverride
      : (environment == AppEnvironment.local ? _localOrigin : _prodOrigin);
  if (origin.endsWith('/')) origin = origin.substring(0, origin.length - 1);

  return AppEnv(environment: environment, origin: origin);
});
