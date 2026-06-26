import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Thin wrapper around the live support-chat WebSocket.
///
/// The socket **only receives** JSON message payloads (the client never sends
/// over it — sending stays on REST). It is deliberately "dumb": it surfaces
/// decoded messages and a single `onDown` signal; reconnection, back-off and
/// `?after_id=` reconciliation are owned by the controller so the socket can
/// be torn down and recreated cleanly on each attempt.
///
/// A rejected handshake (invalid token / guest, missing staff RBAC) closes
/// with code 4401 — the controller then stops retrying and relies on polling.
class SupportChatSocket {
  SupportChatSocket({
    required this.url,
    required this.onMessage,
    required this.onDown,
  });

  /// Full `wss://…/ws/support/chat/?token=…|guest_id=…` URL.
  final String url;

  /// Called with each decoded JSON object pushed by the server.
  final void Function(Map<String, dynamic> payload) onMessage;

  /// Called once when the socket errors or closes. The `closeCode` is the WS
  /// close code when available (4401 ⇒ auth rejected — do not retry).
  final void Function(int? closeCode) onDown;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  bool _disposed = false;
  bool _downReported = false;

  void connect() {
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      _sub = channel.stream.listen(
        (event) {
          if (event is! String) return;
          try {
            final decoded = jsonDecode(event);
            if (decoded is Map<String, dynamic>) onMessage(decoded);
          } catch (_) {
            // Ignore non-JSON / malformed frames — REST stays authoritative.
          }
        },
        onError: (_) => _reportDown(),
        onDone: _reportDown,
        cancelOnError: true,
      );
    } catch (_) {
      _reportDown();
    }
  }

  void _reportDown() {
    if (_disposed || _downReported) return;
    _downReported = true;
    onDown(_channel?.closeCode);
  }

  Future<void> close() async {
    _disposed = true;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
