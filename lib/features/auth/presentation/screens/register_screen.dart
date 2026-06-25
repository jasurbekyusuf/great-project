import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/shared/widgets/mobile_language_pill.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "O'zingiz haqingizda" (Authorization → Login 6937:24348). A language
/// pill, the title, a "Foydalanuvchi turini tanlang" role picker (3 cards), an
/// "Ishlash shaklini tanlang" person-type picker (2 cards) and a name field,
/// with a pinned "Davom etish" button and a terms line beneath it.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  bool _loading = false;

  // Role cards → web roles. Haydovchi=carrier, Logist=broker, Yuk egasi=shipper.
  static const _roles = [
    ('carrier', 'Haydovchi', LucideIcons.truck),
    ('broker', 'Logist/Dispetcher', LucideIcons.headset),
    ('shipper', 'Yuk egasi', LucideIcons.package),
  ];

  // Person type → web person_type (individual | legal).
  static const _types = [
    ('individual', 'Jismoniy', LucideIcons.user),
    ('legal', 'Yuridik', LucideIcons.building2),
  ];

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final flow = ref.read(authFlowProvider);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ism va familiyangizni kiriting')),
      );
      return;
    }
    final isLegal = flow.personType == 'legal';
    setState(() => _loading = true);
    try {
      final (session, fail) =
          await ref.read(authControllerProvider.notifier).register(
                registrationToken: flow.registrationToken,
                role: flow.role,
                personType: flow.personType,
                fullName: isLegal ? null : name,
                companyName: isLegal ? name : null,
              );
      if (!mounted) return;
      if (fail != null || session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fail?.message ?? 'Xatolik')),
        );
        return;
      }
      // Keep the synchronous role state in step with the new session so the
      // role-aware navigation routes correctly right away.
      ref.read(currentUserRoleSyncProvider.notifier).setRole(flow.role);
      // Mirrors the web getPostLoginPath: carrier looks for loads, the
      // shipper / broker roles look for trucks.
      context.go(flow.role == 'carrier' ? '/loads' : '/trucks');
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
    final flow = ref.watch(authFlowProvider);
    final isLegal = flow.personType == 'legal';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MobileLanguagePill(
                      label: "O'zbekcha",
                      onTap: _openLanguageSheet,
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "O'zingiz haqingizda",
                            style: TextStyle(
                              fontSize: 32,
                              height: 38.7 / 32,
                              fontWeight: FontWeight.w600,
                              color: FigmaPalette.countLabel,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Foydalanuvchi turini tanlang — 3 role cards.
                          const _SectionLabel('Foydalanuvchi turini tanlang'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (var i = 0; i < _roles.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _RoleCard(
                                    icon: _roles[i].$3,
                                    label: _roles[i].$2,
                                    selected: flow.role == _roles[i].$1,
                                    onTap: () => ref
                                        .read(authFlowProvider.notifier)
                                        .setRole(_roles[i].$1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Ishlash shaklini tanlang — 2 person-type cards.
                          const _SectionLabel('Ishlash shaklini tanlang'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (var i = 0; i < _types.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _TypeCard(
                                    icon: _types[i].$3,
                                    label: _types[i].$2,
                                    selected: flow.personType == _types[i].$1,
                                    onTap: () => ref
                                        .read(authFlowProvider.notifier)
                                        .setPersonType(_types[i].$1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Ism va familiyangiz / Tashkilot nomi.
                          _SectionLabel(
                              isLegal ? 'Tashkilot nomi' : 'Ism va familiyangiz'),
                          const SizedBox(height: 8),
                          _NameField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pinned bottom: primary button + terms line.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PrimaryButton(
                    label: 'Davom etish',
                    loading: _loading,
                    onPressed: _continue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Davom etish orqali foydalanish shartlariga rozilik bildirasiz',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 22 / 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF303236),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading (fs16 w500 #0B1020), e.g. "Foydalanuvchi turini tanlang".
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w500,
        color: FigmaPalette.countLabel,
      ),
    );
  }
}

/// Vertical role card: 40×40 r12 icon tile over a label, 112 tall, r16 #F2F4F7.
/// Selected → blue (#D6E6FF) tile and #004EEB text; otherwise a #E4E9F2 tile.
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FigmaPalette.chipBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconTile(icon: icon, selected: selected),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 2,
              style: TextStyle(
                fontSize: 14,
                height: 19 / 14,
                fontWeight: FontWeight.w400,
                color: selected ? FigmaPalette.primary : FigmaPalette.countLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal person-type card: 40×40 r12 icon tile beside a label, 64 tall.
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FigmaPalette.chipBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _IconTile(icon: icon, selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  height: 19 / 14,
                  fontWeight: FontWeight.w400,
                  color:
                      selected ? FigmaPalette.primary : FigmaPalette.countLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 40×40 r12 icon tile: #D6E6FF + #004EEB icon when selected, else #E4E9F2.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.selected});
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFD6E6FF) : const Color(0xFFE4E9F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: selected ? FigmaPalette.primary : FigmaPalette.countLabel,
      ),
    );
  }
}

/// Full-width 56px r12 text field (#F2F4F7) with a "Kiriting" placeholder and a
/// blue focus ring, matching the welcome phone field.
class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FigmaPalette.chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? FigmaPalette.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        cursorColor: FigmaPalette.primary,
        cursorWidth: 1.5,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w400,
          color: FigmaPalette.inkStrong,
        ),
        decoration: const InputDecoration(
          isCollapsed: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: 'Kiriting',
          hintStyle: TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w400,
            color: FigmaPalette.label,
          ),
        ),
      ),
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
