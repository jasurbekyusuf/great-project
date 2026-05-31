import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';
import 'package:loadme_mobile/shared/widgets/mobile_language_pill.dart';
import 'package:loadme_mobile/shared/widgets/mobile_segmented_tab.dart';

class AuthWelcomeScreen extends ConsumerStatefulWidget {
  const AuthWelcomeScreen({super.key});

  @override
  ConsumerState<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends ConsumerState<AuthWelcomeScreen> {
  final _phoneController = TextEditingController(text: '+998');
  int _tabIndex = 0;
  bool _loading = false;

  Future<void> _continue() async {
    setState(() => _loading = true);
    final phone = _phoneController.text.trim();
    final (result, fail) =
        await ref.read(authControllerProvider.notifier).checkUserPhone(phone);
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
          smsId: result.smsId,
          userFound: result.userFound,
        );
    context.go('/auth/verify');
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
              const Text('Tilni tanlang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
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
                    child: Text(e.$3, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(e.$2, style: const TextStyle(fontSize: 16)),
                  trailing: Icon(
                    locale.languageCode == e.$1 ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: locale.languageCode == e.$1 ? const Color(0xFF0057FF) : const Color(0xFFD0D5DD),
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
    final isPhoneTab = _tabIndex == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/guest');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Color(0xFF101828)),
                  ),
                  const Expanded(
                    child: Text('Kirish', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                  ),
                  MobileLanguagePill(label: "O'Z", onTap: _openLanguageSheet),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("LoadMe'ga xush kelibsiz!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xFF475467), height: 1.5)),
                    const SizedBox(height: 16),
                    MobileSegmentedTab(
                      items: const ['Telefon raqami', 'Telegram'],
                      selectedIndex: _tabIndex,
                      onChanged: (index) => setState(() => _tabIndex = index),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Telefon raqami ${isPhoneTab ? '*' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF475467), height: 1.43),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('UZ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF98A2B3), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isPhoneTab) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Sizda O'zbekiston raqami yo'qmi? Muammo emas!\nTelegram orqali tizimga kiring va platformaning barcha imkoniyatlaridan foydalaning.",
                        style: TextStyle(fontSize: 14, color: Color(0xFF475467), height: 1.43),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DsButton(
                label: isPhoneTab ? 'Davom etish' : 'Kodni yuborish',
                onPressed: _continue,
                loading: _loading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
