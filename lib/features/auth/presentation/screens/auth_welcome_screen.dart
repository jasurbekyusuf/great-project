import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/shared/design_system/ds_button.dart';

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
    try {
      final result = await ref.read(authControllerProvider.notifier).checkUserPhone(_phoneController.text.trim());
      ref.read(authFlowProvider.notifier).setPhoneCheckResult(
            phone: _phoneController.text.trim(),
            smsId: result.smsId,
            userFound: result.userFound,
          );
      if (mounted) context.go('/auth/verify');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    ref.read(localeProvider.notifier).state = Locale(e.$1);
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22, color: Color(0xFF101828)),
                  ),
                  const Expanded(
                    child: Text('Kirish', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF101828))),
                  ),
                  GestureDetector(
                    onTap: _openLanguageSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE4E7EC)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text('UZ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          const Text("O'Z", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF101828))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("LoadMe'ga xush kelibsiz!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF344054))),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tabIndex = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: isPhoneTab ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text('Telefon raqami', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF101828))),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _tabIndex = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !isPhoneTab ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text('Telegram', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF101828))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Telefon raqami ${isPhoneTab ? '*' : ''}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF344054)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                        style: TextStyle(fontSize: 16, color: Color(0xFF344054), height: 1.4),
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
                height: 64,
                radius: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
