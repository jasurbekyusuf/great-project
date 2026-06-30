import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Kodni kiriting" (Authorization → Login 6937:24987). A back chevron,
/// the big title + masked-phone subtitle, six r12 code boxes that pull up the
/// system numeric keypad, and a "Kodni qayta yuborish" row with a countdown.
/// Verification auto-submits once all six digits are entered (no extra button).
const _kOtpLength = 6;

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  // Resend countdown: 1 minute (Figma + product spec).
  int _seconds = 60;
  Timer? _timer;
  bool _loading = false;
  // True after a wrong code: boxes turn red and "Kod xato kiritildi" shows
  // below them (Figma 6937:25204 error state). Cleared as soon as the user
  // edits the code again.
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  /// "+998901234567" → "+998 9 **** 67" (matches the Figma mock mask).
  String _maskedPhone() {
    final phone = ref.read(authFlowProvider).phone;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final rest = digits.startsWith('998') ? digits.substring(3) : digits;
    if (rest.length < 3) return phone;
    return '+998 ${rest.substring(0, 1)} **** ${rest.substring(rest.length - 2)}';
  }

  Future<void> _onChanged(String value) async {
    // Any edit clears the error state (red boxes / message go away).
    setState(() => _error = false);
    if (value.length == _kOtpLength && !_loading) {
      await _submit();
    }
  }

  Future<void> _submit() async {
    final flow = ref.read(authFlowProvider);
    final code = _otpController.text.trim();
    if (code.length < _kOtpLength) return;
    // Code is complete — close the OS autofill session so the platform stops
    // offering the (now consumed) SMS code.
    TextInput.finishAutofillContext();
    ref.read(authFlowProvider.notifier).setOtp(code);
    setState(() => _loading = true);
    final (result, fail) =
        await ref.read(authControllerProvider.notifier).verifyOtp(
              phone: flow.phone,
              channel: flow.channel,
              purpose: flow.purpose,
              code: code,
            );
    if (!mounted) return;
    setState(() => _loading = false);
    if (fail != null || result == null) {
      // Wrong code → show the Figma inline error (red boxes + message) instead
      // of surfacing the raw API/Dio exception. The entered digits stay put so
      // the user can fix them; editing clears the error via _onChanged.
      setState(() => _error = true);
      return;
    }
    if (result.session != null) {
      // Authenticated → land on the role home (carrier: loads, others: trucks),
      // mirroring the web getPostLoginPath.
      final role = await ref.refresh(currentUserRoleProvider.future);
      ref.read(currentUserRoleSyncProvider.notifier).setRole(role);
      if (mounted) context.go(role == 'carrier' ? '/loads' : '/trucks');
    } else {
      // New user → carry the registration_token to the register screen.
      ref
          .read(authFlowProvider.notifier)
          .setRegistrationToken(result.registrationToken ?? '');
      // Push so the user can still go back if they typed the wrong OTP.
      await context.push<void>('/auth/register');
    }
  }

  Future<void> _resend() async {
    final flow = ref.read(authFlowProvider);
    final (result, fail) = await ref
        .read(authControllerProvider.notifier)
        .checkUserPhone(phone: flow.phone, channel: flow.channel);
    if (fail != null || result == null) return;
    ref.read(authFlowProvider.notifier).setPhoneCheckResult(
          phone: flow.phone,
          channel: flow.channel,
          purpose: result.purpose,
        );
    _otpController.clear();
    setState(_startTimer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back chevron, aligned to the 12px screen inset.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkResponse(
                  onTap: () => context.pop(),
                  radius: 20,
                  child: const Icon(LucideIcons.chevronLeft,
                      size: 24, color: FigmaPalette.countLabel),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'verify.title'.tr(ref),
                      style: const TextStyle(
                        fontSize: 32,
                        height: 38.7 / 32,
                        fontWeight: FontWeight.w600,
                        color: FigmaPalette.countLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_maskedPhone()} ${'verify.subtitleSuffix'.tr(ref)}',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 22 / 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF303236),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _OtpBoxes(
                      controller: _otpController,
                      focusNode: _otpFocus,
                      length: _kOtpLength,
                      value: _otpController.text,
                      onChanged: _onChanged,
                      hasError: _error,
                    ),
                    if (_error) ...[
                      const SizedBox(height: 8),
                      Text(
                        'verify.codeError'.tr(ref),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 22 / 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF303236),
                        ),
                      ),
                    ],
                    // Remainder of the 176px input zone (boxes sit at its top).
                    const SizedBox(height: 120),
                    const SizedBox(height: 32),
                    _ResendRow(
                      seconds: _seconds,
                      canResend: _seconds <= 0,
                      onResend: () => _resend(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six 49×56 r12 boxes (#F2F4F7) showing the entered digits. A single
/// transparent [TextField] overlays the row to drive the system numeric
/// keypad; the active box renders our own blinking caret.
class _OtpBoxes extends StatefulWidget {
  const _OtpBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final String value;
  final ValueChanged<String> onChanged;
  final bool hasError;

  @override
  State<_OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<_OtpBoxes> {
  Timer? _blink;
  bool _caretOn = true;

  @override
  void initState() {
    super.initState();
    _blink = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _caretOn = !_caretOn);
    });
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _blink?.cancel();
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final focused = widget.focusNode.hasFocus;
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final filled = i < value.length;
              final active = focused && i == value.length;
              return Container(
                width: 49,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FigmaPalette.chipBg,
                  borderRadius: BorderRadius.circular(12),
                  // Wrong code → every box gets the #E73B36 error ring (Figma
                  // 6937:25204). Otherwise the current box gets the #004EEB
                  // ring at the Border.all default width (1.0), matching the
                  // focused phone field on the welcome screen.
                  border: widget.hasError
                      ? Border.all(color: FigmaPalette.otpErrorBorder)
                      : active
                          ? Border.all(color: FigmaPalette.primary)
                          : null,
                ),
                child: filled
                    ? Text(
                        value[i],
                        style: const TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w400,
                          color: FigmaPalette.countLabel,
                        ),
                      )
                    : SizedBox(
                        width: 2,
                        height: 24,
                        child: (active && _caretOn)
                            ? const DecoratedBox(
                                decoration: BoxDecoration(
                                    color: FigmaPalette.countLabel),
                              )
                            : null,
                      ),
              );
            }),
          ),
          Positioned.fill(
            // Let the OS auto-read the incoming SMS code and fill it without
            // typing: iOS surfaces it in the QuickType bar; Android 12+ shows
            // an "Autofill from SMS" suggestion above the keyboard. Filling the
            // field fires onChanged, which auto-submits once all digits land.
            child: AutofillGroup(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                onChanged: widget.onChanged,
                showCursor: false,
                cursorWidth: 0,
                enableInteractiveSelection: false,
                style: const TextStyle(color: Colors.transparent, height: 0.01),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero,
                  fillColor: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma "Buttons" resend row: refresh glyph · "Kodni qayta yuborish" · "Ns".
/// Muted and disabled while the countdown runs; tappable once it hits zero.
class _ResendRow extends ConsumerWidget {
  const _ResendRow({
    required this.seconds,
    required this.canResend,
    required this.onResend,
  });

  final int seconds;
  final bool canResend;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelColor = canResend ? FigmaPalette.ink : const Color(0xFF818A9C);
    return Material(
      // Figma resend control is a full-width white button with a 1px #EAECF0
      // hairline border, r14.
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FigmaPalette.divider),
      ),
      child: InkWell(
        onTap: canResend ? onResend : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(LucideIcons.rotateCw, size: 20, color: labelColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'verify.resend'.tr(ref),
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (!canResend) ...[
                const SizedBox(width: 6),
                Text(
                  '$seconds ${'verify.secondsShort'.tr(ref)}',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF303236),
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
