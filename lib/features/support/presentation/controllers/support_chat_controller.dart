import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/env/app_env.dart';
import 'package:loadme_mobile/core/logging/app_logger.dart';
import 'package:loadme_mobile/core/network/dio_client.dart';
import 'package:loadme_mobile/core/storage/providers.dart';
import 'package:loadme_mobile/features/support/data/datasources/support_chat_remote_data_source.dart';
import 'package:loadme_mobile/features/support/data/support_chat_socket.dart';
import 'package:loadme_mobile/features/support/domain/entities/support_message.dart';
import 'package:uuid/uuid.dart';

/// REST data source over the shared Dio (auth header is auto-attached; the
/// origin is needed to absolutise relative file URLs).
final supportChatDataSourceProvider =
    Provider<SupportChatRemoteDataSource>((ref) {
  return SupportChatRemoteDataSource(
    ref.watch(dioProvider),
    origin: ref.watch(appEnvProvider).origin,
  );
});

enum SupportChatPhase { loading, ready, error }

/// Immutable view-state for the chat screen.
class SupportChatState {
  const SupportChatState({
    this.messages = const [],
    this.phase = SupportChatPhase.loading,
    this.sending = false,
    this.live = false,
    this.errorMessage,
  });

  /// Chronological, oldest→newest.
  final List<SupportMessage> messages;
  final SupportChatPhase phase;

  /// A POST is in flight (the send button is busy).
  final bool sending;

  /// The live WebSocket is currently connected (purely informational).
  final bool live;

  /// Transient error to surface once (e.g. a failed send) — the screen shows a
  /// SnackBar then calls [SupportChatController.consumeError].
  final String? errorMessage;

  bool get isReady => phase == SupportChatPhase.ready;
  bool get hasUserMessage => messages.any((m) => !m.isFromStaff);

  SupportChatState copyWith({
    List<SupportMessage>? messages,
    SupportChatPhase? phase,
    bool? sending,
    bool? live,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SupportChatState(
      messages: messages ?? this.messages,
      phase: phase ?? this.phase,
      sending: sending ?? this.sending,
      live: live ?? this.live,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final supportChatControllerProvider =
    AutoDisposeNotifierProvider<SupportChatController, SupportChatState>(
  SupportChatController.new,
);

/// Orchestrates the 3 layers from `frontend-support-chat-integration`:
///   * REST = source of truth — history, send, read;
///   * a 4s delta poll (`?after_id=`) keeps the thread live and is the reliable
///     fallback whenever the socket is down;
///   * the WebSocket adds instant delivery, with exponential-backoff reconnect
///     and a reconcile poll on every (re)connect.
/// All inbound messages are de-duplicated by id, so the poll and the socket can
/// safely overlap.
class SupportChatController extends AutoDisposeNotifier<SupportChatState> {
  static final _log = AppLogger.tagged('SupportChat');

  /// Shared with analytics — a stable per-device id used as `X-Guest-Id`
  /// before the user registers (carried over to the account on sign-up).
  static const _guestIdKey = 'app.guest_id';
  static const _pollInterval = Duration(seconds: 4);
  static const _backoffSeconds = [2, 4, 8, 16, 30];

  Timer? _poll;
  Timer? _reconnect;
  SupportChatSocket? _socket;
  int _reconnectAttempt = 0;

  /// Newest real (non-temp) message id — the cursor for delta polls.
  String? _lastId;
  String? _guestId;
  bool _disposed = false;

  SupportChatRemoteDataSource get _ds =>
      ref.read(supportChatDataSourceProvider);

  @override
  SupportChatState build() {
    ref.onDispose(_teardown);
    Future.microtask(_bootstrap);
    return const SupportChatState();
  }

  // --- lifecycle -------------------------------------------------------------

  Future<void> _bootstrap() async {
    try {
      _guestId = await _ensureGuestId();
      final history = await _ds.getHistory(guestId: _guestId);
      if (_disposed) return;
      _lastId = _newestRealId(history);
      state = state.copyWith(messages: history, phase: SupportChatPhase.ready);
      unawaited(_markReadSafe());
      _startPolling();
      await _connectSocket();
    } catch (e) {
      if (_disposed) return;
      _log.w('bootstrap failed: $e');
      state = state.copyWith(
        phase: SupportChatPhase.error,
        errorMessage: _msg(e),
      );
    }
  }

  /// Retry after an error state (pull-to-retry button on the screen).
  Future<void> retry() async {
    if (state.phase == SupportChatPhase.loading) return;
    state = state.copyWith(phase: SupportChatPhase.loading, clearError: true);
    await _bootstrap();
  }

  Future<String> _ensureGuestId() async {
    final storage = ref.read(storageProvider);
    var id = await storage.read(_guestIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await storage.write(_guestIdKey, id);
    }
    return id;
  }

  // --- sending ---------------------------------------------------------------

  /// Sends [text] via REST with an optimistic local bubble. Returns `false`
  /// (and sets [SupportChatState.errorMessage]) if the POST failed, so the
  /// screen can restore the typed text for a retry.
  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return false;

    final temp = SupportMessage.optimistic(trimmed);
    state = state.copyWith(
      messages: [...state.messages, temp],
      sending: true,
      clearError: true,
    );

    try {
      final real = await _ds.sendMessage(text: trimmed, guestId: _guestId);
      final list = state.messages.where((m) => m.id != temp.id).toList();
      if (!list.any((m) => m.id == real.id)) list.add(real);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _lastId = _newestRealId(list) ?? _lastId;
      state = state.copyWith(messages: list, sending: false);
      return true;
    } catch (e) {
      _log.w('send failed: $e');
      final list = state.messages.where((m) => m.id != temp.id).toList();
      state = state.copyWith(
        messages: list,
        sending: false,
        errorMessage: _msg(e),
      );
      return false;
    }
  }

  /// Clears the one-shot [SupportChatState.errorMessage] after the screen has
  /// shown it.
  void consumeError() => state = state.copyWith(clearError: true);

  // --- polling ---------------------------------------------------------------

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => unawaited(_pollDelta()));
  }

  Future<void> _pollDelta() async {
    if (_disposed) return;
    try {
      final fresh = _lastId == null
          ? await _ds.getHistory(guestId: _guestId)
          : await _ds.getMessagesAfter(_lastId!, guestId: _guestId);
      _ingest(fresh);
    } catch (_) {
      // Transient — keep the last good state and retry on the next tick.
    }
  }

  // --- websocket -------------------------------------------------------------

  Future<void> _connectSocket() async {
    if (_disposed) return;
    final url = await _socketUrl();
    if (url == null) return; // no identity → polling only
    _socket = SupportChatSocket(
      url: url,
      onMessage: _onSocketMessage,
      onDown: _onSocketDown,
    )..connect();
    state = state.copyWith(live: true);
    // Pull anything missed during the (re)connect gap.
    unawaited(_pollDelta());
  }

  Future<String?> _socketUrl() async {
    final env = ref.read(appEnvProvider);
    final base = '${env.wsOrigin}/ws/support/chat/';
    final token = await ref.read(secureTokenStorageProvider).readAccessToken();
    if (token != null && token.isNotEmpty) return '$base?token=$token';
    if (_guestId != null && _guestId!.isNotEmpty) {
      return '$base?guest_id=$_guestId';
    }
    return null;
  }

  void _onSocketMessage(Map<String, dynamic> json) {
    _reconnectAttempt = 0; // a live frame ⇒ the connection is healthy
    _ingest([
      SupportMessage.fromJson(json, origin: ref.read(appEnvProvider).origin),
    ]);
  }

  void _onSocketDown(int? code) {
    if (_disposed) return;
    state = state.copyWith(live: false);
    _socket?.close();
    _socket = null;
    if (code == 4401) {
      _log.w('WS rejected (4401) — falling back to polling');
      return; // auth invalid: do not retry, polling carries the thread
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    final idx = _reconnectAttempt.clamp(0, _backoffSeconds.length - 1);
    final delay = Duration(seconds: _backoffSeconds[idx]);
    _reconnectAttempt++;
    _reconnect = Timer(delay, () {
      if (!_disposed) unawaited(_connectSocket());
    });
  }

  // --- merge / read ----------------------------------------------------------

  void _ingest(List<SupportMessage> incoming) {
    if (_disposed || incoming.isEmpty) return;
    final known = {for (final m in state.messages) m.id};
    final additions = [
      for (final m in incoming)
        if (m.id.isNotEmpty && !known.contains(m.id)) m,
    ];
    if (additions.isEmpty) return;

    final merged = [...state.messages, ...additions]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _lastId = _newestRealId(merged) ?? _lastId;
    state = state.copyWith(messages: merged);

    if (additions.any((m) => m.isFromStaff)) unawaited(_markReadSafe());
  }

  Future<void> _markReadSafe() async {
    try {
      await _ds.markRead(guestId: _guestId);
    } catch (_) {
      // Best-effort — the badge will reconcile on the next open.
    }
  }

  String? _newestRealId(List<SupportMessage> list) {
    for (final m in list.reversed) {
      if (!m.isTemp && m.id.isNotEmpty) return m.id;
    }
    return null;
  }

  String _msg(Object e) => mapDioException(e).message;

  void _teardown() {
    _disposed = true;
    _poll?.cancel();
    _reconnect?.cancel();
    _socket?.close();
  }
}
