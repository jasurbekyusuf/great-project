import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/auth_flow_provider.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma "Siz kimsiz?" (Authorization → Login 6937:24348). A title row with a
/// trailing chat-bubble button, a "Foydalanuvchi turini tanlang" role picker
/// (3 cards), an "Ishlash shaklini tanlang" person-type picker (2 cards) and a
/// name field, with a pinned "Davom etish" button and a terms line beneath it.
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
  // Value + icon only; the displayed label is localized via [_roleLabel].
  static const _roles = [
    ('carrier', LucideIcons.truck),
    ('broker', LucideIcons.headset),
    ('shipper', LucideIcons.package),
  ];

  // Person type → web person_type (individual | legal).
  static const _types = [
    ('individual', LucideIcons.user),
    ('legal', LucideIcons.building2),
  ];

  // Register uses 'Logist/Dispetcher' for broker (the profile screen shows the
  // shorter 'Dispecher'), so broker maps to its own key here.
  String _roleLabel(String value) {
    switch (value) {
      case 'broker':
        return 'register.role.broker'.tr(ref);
      case 'shipper':
        return 'role.shipper'.tr(ref);
      default:
        return 'role.carrier'.tr(ref);
    }
  }

  String _typeLabel(String value) => value == 'legal'
      ? 'register.type.legal'.tr(ref)
      : 'register.type.individual'.tr(ref);

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
    // Name / company name is optional on the backend (`full_name`/`company_name`
    // are simply omitted when empty), so the flow no longer blocks on an empty
    // field — e.g. a legal user can continue with only the org name, or none.
    final name = _nameController.text.trim();
    final isLegal = flow.personType == 'legal';
    setState(() => _loading = true);
    try {
      final (session, fail) =
          await ref.read(authControllerProvider.notifier).register(
                registrationToken: flow.registrationToken,
                role: flow.role,
                personType: flow.personType,
                fullName: isLegal || name.isEmpty ? null : name,
                companyName: isLegal && name.isNotEmpty ? name : null,
              );
      if (!mounted) return;
      if (fail != null || session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(fail?.message ?? 'common.error'.tr(ref))),
        );
        return;
      }
      // Keep the synchronous role state in step with the new session so the
      // role-aware navigation routes correctly right away.
      ref.read(currentUserRoleSyncProvider.notifier).setRole(flow.role);
      // Post-registration location primer ("Lokatsiyaga ruxsat bering"): asks
      // for the OS location permission, then continues to the role-aware home.
      context.go('/location-permission');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'register.title'.tr(ref),
                                style: const TextStyle(
                                  fontSize: 32,
                                  height: 38.7 / 32,
                                  fontWeight: FontWeight.w600,
                                  color: FigmaPalette.countLabel,
                                ),
                              ),
                              _ChatIconButton(onTap: () {}),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Foydalanuvchi turini tanlang — 3 role cards.
                          _SectionLabel('register.roleSection'.tr(ref)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (var i = 0; i < _roles.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _RoleCard(
                                    icon: _roles[i].$2,
                                    label: _roleLabel(_roles[i].$1),
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
                          _SectionLabel('register.typeSection'.tr(ref)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (var i = 0; i < _types.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _TypeCard(
                                    icon: _types[i].$2,
                                    label: _typeLabel(_types[i].$1),
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
                          _SectionLabel(isLegal
                              ? 'register.companyLabel'.tr(ref)
                              : 'register.nameLabel'.tr(ref)),
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
            // Pinned bottom (Figma order): terms line on top, then the primary
            // "Davom etish" button beneath it, anchored to the safe-area bottom.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'register.termsPrefix'.tr(ref)),
                        TextSpan(
                          text: 'register.termsLink'.tr(ref),
                          style: const TextStyle(color: FigmaPalette.primary),
                        ),
                        TextSpan(text: 'register.termsSuffix'.tr(ref)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 22 / 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2F3136),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PrimaryButton(
                    label: 'auth.continue'.tr(ref),
                    loading: _loading,
                    onPressed: _continue,
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

/// 32×32 r10 outlined chat-bubble button at the top-right of the title (Figma
/// "Buttons" — #F2F4F7 1px border, #303236 icon). Opens support chat.
class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FigmaPalette.chipBg, width: 1),
        ),
        child: const Icon(
          LucideIcons.messageCircle,
          size: 20,
          color: FigmaPalette.inkBody,
        ),
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
          border: Border.all(
            color: selected ? FigmaPalette.primary : Colors.transparent,
            width: 1,
          ),
        ),
        // Figma role card is a vertical SPACE_BETWEEN stack: icon pinned to the
        // top, label pinned to the bottom. (A rigid icon→label gap is what made
        // the 2-line "Logist/Dispetcher" overflow the 112px card by 2px.)
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconTile(icon: icon, selected: selected),
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
          border: Border.all(
            color: selected ? FigmaPalette.primary : Colors.transparent,
            width: 1,
          ),
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
                      selected ? FigmaPalette.primary : FigmaPalette.inkBody,
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
class _NameField extends ConsumerWidget {
  const _NameField({required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          fontWeight: FontWeight.w400,
          color: FigmaPalette.inkStrong,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          constraints: const BoxConstraints(),
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: 'register.nameHint'.tr(ref),
          hintStyle: const TextStyle(
            fontSize: 16,
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
