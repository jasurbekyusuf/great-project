import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/support/domain/entities/support_message.dart';
import 'package:loadme_mobile/features/support/presentation/controllers/support_chat_controller.dart';
import 'package:loadme_mobile/shared/widgets/frosted_section_header.dart';

/// Figma "Bog'lanish" support chat (7099:12958 + its focused / sent states),
/// wired to the real backend (`/feedback/support/chat/`): REST history + send,
/// a 4s delta poll and a live WebSocket (see [SupportChatController]).
///
/// A frosted, rounded-bottom header ("Chat" + back chevron), a scrollable
/// thread with a left-aligned white operator bubble and a quick-reply list
/// card, plus any right-aligned light-blue user bubbles; then a rounded input
/// bar with a paperclip, "Xabar yozing" placeholder and a paper-plane send
/// button (gray when empty, blue when there is text; a blue ring while the
/// field is focused).
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  /// Static client greeting (NOT from the API) shown above the FAQ buttons.
  static const _welcome =
      'Assalomu alaykum! Sizga qanday yordam bera olaman?';

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focusNode.removeListener(_onChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final ok = await ref.read(supportChatControllerProvider.notifier).send(text);
    // Restore the text on failure so the user can retry; the SnackBar is shown
    // by the errorMessage listener below.
    if (!ok && mounted) {
      _controller
        ..text = text
        ..selection = TextSelection.collapsed(offset: text.length);
    }
  }

  /// Tapping an FAQ button is self-service: the backend records the question +
  /// an automated answer in the thread and returns both (no operator is
  /// pinged). The controller appends them; free-text still reaches the operator.
  void _askFaq(String id) {
    ref.read(supportChatControllerProvider.notifier).askFaq(id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportChatControllerProvider);

    ref
      // Auto-scroll to the newest message whenever the thread grows.
      ..listen(
        supportChatControllerProvider.select((s) => s.messages.length),
        (prev, next) {
          if (next != (prev ?? 0)) _scrollToBottom();
        },
      )
      // Surface a one-shot send/load error as a SnackBar.
      ..listen(
        supportChatControllerProvider.select((s) => s.errorMessage),
        (_, msg) {
          if (msg != null && msg.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(SnackBar(content: Text(msg)));
            ref.read(supportChatControllerProvider.notifier).consumeError();
          }
        },
      );

    final hasText = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      body: Column(
        children: [
          const FrostedSectionHeader(title: 'Chat'),
          Expanded(child: _body(state)),
          _InputBar(
            controller: _controller,
            focusNode: _focusNode,
            focused: _focusNode.hasFocus,
            hasText: hasText,
            onSend: _handleSend,
            onAttach: _showAttachSoon,
          ),
        ],
      ),
    );
  }

  Widget _body(SupportChatState state) {
    switch (state.phase) {
      case SupportChatPhase.loading:
        return const Center(
          child: CircularProgressIndicator(color: FigmaPalette.primary),
        );
      case SupportChatPhase.error:
        return _ErrorView(
          message: state.errorMessage ?? 'Chatni yuklab bo‘lmadi.',
          onRetry: () =>
              ref.read(supportChatControllerProvider.notifier).retry(),
        );
      case SupportChatPhase.ready:
        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            // Static greeting + backend FAQ buttons stay pinned at the top, so
            // the user can keep tapping them or type a custom question at any
            // point in the thread.
            const _OperatorBubble(
              name: 'Loadme Operator',
              text: _welcome,
              time: 'Hozir',
            ),
            if (state.hasFaqs) ...[
              const SizedBox(height: 8),
              _QuickReplyCard(
                faqs: state.faqs,
                askingId: state.askingFaqId,
                onTap: _askFaq,
              ),
            ],
            for (final m in state.messages) ...[
              const SizedBox(height: 8),
              _bubble(m),
            ],
          ],
        );
    }
  }

  Widget _bubble(SupportMessage m) {
    final text = _displayText(m);
    if (m.isFromStaff) {
      return _OperatorBubble(
        name: m.senderName.isEmpty ? 'Support' : m.senderName,
        text: text,
        time: _timeLabel(m.createdAt),
      );
    }
    return _UserBubble(
      text: text,
      time: m.pending ? 'Yuborilmoqda…' : _timeLabel(m.createdAt),
    );
  }

  /// Text to render — falls back to attached file names when a message carries
  /// only files (the Figma thread has no dedicated file bubble yet).
  String _displayText(SupportMessage m) {
    if (m.text.trim().isNotEmpty) return m.text;
    final names =
        m.files.map((f) => f.originalName).where((n) => n.isNotEmpty).toList();
    if (names.isNotEmpty) return names.join('\n');
    return '';
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final sameDay =
        now.year == local.year && now.month == local.month && now.day == local.day;
    if (sameDay) return 'Bugun, $hh:$mm';
    final dd = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$dd.$mo, $hh:$mm';
  }

  void _showAttachSoon() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('Fayl biriktirish tez orada qo‘shiladi.')),
      );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: FigmaPalette.notifTitle,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Qayta urinish',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bubbles
// ---------------------------------------------------------------------------

class _OperatorBubble extends StatelessWidget {
  const _OperatorBubble({
    required this.name,
    required this.text,
    required this.time,
  });

  final String name;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 261),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.zero,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: FigmaPalette.notifTitle,
                ),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.notifTitle,
                  ),
                ),
              ],
              if (time.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 14.5 / 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A93A8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 241),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFC2D7FF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.zero,
              bottomLeft: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (text.isNotEmpty)
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.notifTitle,
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 14.5 / 12,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-reply list card
// ---------------------------------------------------------------------------

class _QuickReplyCard extends StatelessWidget {
  const _QuickReplyCard({
    required this.faqs,
    required this.onTap,
    this.askingId,
  });

  final List<SupportFaq> faqs;

  /// Id of the FAQ whose `ask/` POST is in flight — its row shows a spinner and
  /// the whole card stops accepting taps until it resolves.
  final String? askingId;
  final ValueChanged<String> onTap;

  static const _radius = BorderRadius.only(
    topLeft: Radius.zero,
    topRight: Radius.circular(16),
    bottomRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
  );

  @override
  Widget build(BuildContext context) {
    final busy = askingId != null;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 297),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: _radius),
          child: ClipRRect(
            borderRadius: _radius,
            child: Column(
              children: [
                for (var i = 0; i < faqs.length; i++) ...[
                  _QuickReplyRow(
                    label: faqs[i].question,
                    loading: askingId == faqs[i].id,
                    // Block taps while any ask is in flight to avoid double-posts.
                    onTap: busy ? null : () => onTap(faqs[i].id),
                  ),
                  if (i != faqs.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Divider(
                          height: 1, thickness: 1, color: FigmaPalette.divider),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickReplyRow extends StatelessWidget {
  const _QuickReplyRow({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.notifTitle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FigmaPalette.primary,
                  ),
                )
              else
                const Icon(LucideIcons.chevronRight,
                    size: 16, color: Color(0xFF000000)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.hasText,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool hasText;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused ? FigmaPalette.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14101828), // #101828 @ 8%
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAttach,
                child: const Icon(LucideIcons.paperclip,
                    size: 20, color: Color(0xFF000000)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: FigmaPalette.notifTitle,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    hintText: 'Xabar yozing',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w400,
                      color: FigmaPalette.label,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSend,
                child: Icon(
                  LucideIcons.send,
                  size: 20,
                  color: hasText ? FigmaPalette.primary : const Color(0xFF8A93A8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
