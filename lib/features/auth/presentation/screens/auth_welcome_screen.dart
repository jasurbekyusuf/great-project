import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/shared/widgets/mobile_language_pill.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

/// Figma "Keling boshlaymiz!" (Authorization → Login 6937:23686). A language
/// pill, a big title, a Sms-kod / Telegram segmented control, a description and
/// a +998 phone entry, with a pinned "Kodni olish" primary button.
class AuthWelcomeScreen extends ConsumerStatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  ConsumerState<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends ConsumerState<AuthWelcomeScreen> {
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  int _tabIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _loading = true);
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final phone = '+998$digits';
    // Tab 0 = Sms-kod, tab 1 = Telegram. SMS is UZ +998 only (always true here).
    final channel = _tabIndex == 0 ? 'sms' : 'telegram';
    final (result, fail) = await ref
        .read(authControllerProvider.notifier)
        .checkUserPhone(phone: phone, channel: channel);
    if (!mounted) return;
    setState(() => _loading = false);
    if (fail != null || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fail?.message ?? 'Xatolik')),
      );
      return;
    }
    ref.read(authFlowProvider.notifier).setPhoneCheckResult(
          phone: phone,
          channel: channel,
          purpose: result.purpose,
        );
    // push (not go) so the user can tap back to fix the phone number.
    await context.push<void>('/auth/verify');
  }

  void _openLanguageSheet() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final locale = ref.watch(localeProvider);
        final options = const [
          ('uz', "O'zbekcha (lotin)", 'UZ'),
          ('ru', 'Russkiy', 'RU'),
          ('en', 'English', 'EN'),
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E7EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Tilni tanlang',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828))),
              const SizedBox(height: 8),
              ...options.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 28,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(e.$3,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(e.$2, style: const TextStyle(fontSize: 16)),
                  trailing: Icon(
                    locale.languageCode == e.$1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: locale.languageCode == e.$1
                        ? const Color(0xFF0057FF)
                        : const Color(0xFFD0D5DD),
                  ),
                  onTap: () {
                    ref.read(localeProvider.notifier).setLocale(Locale(e.$1));
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _phoneFocus.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MobileLanguagePill(
                      label: "O'zbekcha",
                      onTap: _openLanguageSheet,
                    ),
                    const SizedBox(height: 32),
                    // Figma: the pill sits at 12px, while the title/form block is
                    // inset a further 8px (20px from the screen edge).
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keling boshlaymiz!',
                            style: TextStyle(
                              fontSize: 32,
                              height: 38.7 / 32,
                              fontWeight: FontWeight.w600,
                              // Figma welcome title is #131313 (the OTP title is
                              // #0B1020 — they intentionally differ).
                              color: FigmaPalette.inkStrong,
                            ),
                          ),
                          const SizedBox(height: 24),
                          MobileSegmentedTab(
                            items: const ['Sms-kod', 'Telegram'],
                            selectedIndex: _tabIndex,
                            onChanged: (index) =>
                                setState(() => _tabIndex = index),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Telefon raqamingizni kiriting. Biz unga tasdiqlash kodini yuboramiz.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 22 / 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF303236),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Country box: UZ flag + +998 prefix.
                              Container(
                                height: 56,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: FigmaPalette.chipBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset('assets/icons/flag_uz.svg',
                                        width: 24, height: 18),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '+998',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: FigmaPalette.countLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Phone number field (blue ring on focus).
                              Expanded(
                                child: Container(
                                  height: 56,
                                  // Center the digits on the same line as the
                                  // "+998" box. The box is a fixed 56px and
                                  // centers its child via `alignment`, while
                                  // `isCollapsed: true` (below) shrinks the field
                                  // to its text height so that alignment bites.
                                  // Centering through a tall decorator instead
                                  // (`textAlignVertical`) is fragile: a stray
                                  // `isDense`/`isCollapsed` or a `style.height`
                                  // multiplier silently defeats it and the digits
                                  // ride to the top.
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: FigmaPalette.chipBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: focused
                                          ? FigmaPalette.primary
                                          : Colors.transparent,
                                      // Figma focus stroke is w1.0 (Border.all's
                                      // default width), down from the old 1.5.
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocus,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [_PhoneFormatter()],
                                    cursorColor: FigmaPalette.primary,
                                    cursorWidth: 1.5,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: FigmaPalette.inkStrong,
                                    ),
                                    decoration: const InputDecoration(
                                      // Collapse to text height so the parent's
                                      // `alignment: Alignment.center` centers the
                                      // digits vertically in the 56px box.
                                      isCollapsed: true,
                                      // The app theme's inputDecorationTheme sets
                                      // `constraints: minHeight 44`; without
                                      // clearing it the decorator stays 44px tall
                                      // and top-aligns the text, so the digits
                                      // ride ~10dp high above the "+998" box.
                                      constraints: BoxConstraints(),
                                      filled: false,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      hintText: '00 000 00 00',
                                      hintStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: FigmaPalette.label,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: _PrimaryButton(
                label: _tabIndex == 0 ? 'Kodni olish' : 'Kodni yuborish',
                loading: _loading,
                onPressed: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Groups a 9-digit UZ mobile number as "90 123 45 67" (2-3-2-2).
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Figma auth primary button: 48px, r14, #004EEB, 14/600 white label.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: Material(
        color: FigmaPalette.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
