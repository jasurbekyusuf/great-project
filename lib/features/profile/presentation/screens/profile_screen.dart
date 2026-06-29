import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/auth/presentation/providers/current_user_provider.dart';
import 'package:loadme_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/floating_market_nav.dart';

/// Figma "Profil" (6985:12842). A blue gradient header with a ringed avatar, a
/// role pill, name + phone and an edit pen; then a row of three quick-action
/// cards (Qo'llanmalar / Bog'lanish / Saqlanganlar); then grouped settings rows
/// and an app version.
///
/// The layout is identical for every role — only the role pill text differs
/// (Haydovchi / Dispecher / Yuk egasi). See [_roleLabel].
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleSyncProvider);
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: FigmaPalette.sheetBg,
      // Bottom nav provided by ScaffoldWithNav.
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (profile) {
          // Right-hand values for the settings rows.
          final locale = ref.watch(localeProvider);
          final themeMode = ref.watch(themeModeProvider);
          final currencyCode = ref.watch(currencyProvider);

          final settings = <_RowData>[
            _RowData(
              icon: LucideIcons.dollarSign,
              title: 'form.label.currency'.tr(ref),
              value: _currencyShort(currencyCode),
              onTap: () => _openCurrencyPicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.languages,
              title: 'profile.language'.tr(ref),
              value: _localeLabel(locale),
              onTap: () => _openLanguagePicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.sun,
              title: 'picker.theme'.tr(ref),
              value: _themeLabel(ref, themeMode),
              onTap: () => _openThemePicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.logOut,
              title: 'profile.logoutRow'.tr(ref),
              onTap: () => _confirmLogout(context, ref),
            ),
          ];

          return Stack(
            children: [
              // Figma "Profil" blue gradient backdrop (#CCDDFF → sheetBg),
              // ~399px tall, sitting behind the avatar + name block.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 399,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFCCDDFF), FigmaPalette.sheetBg],
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  // Clear the floating nav (it overlays the body) plus the
                  // bottom safe-area inset, so the version text can scroll into
                  // view on short screens.
                  padding: EdgeInsets.only(
                    bottom: FloatingMarketNav.reservedHeight +
                        MediaQuery.of(context).viewPadding.bottom +
                        24,
                  ),
                  child: Column(
                    children: [
                      _ProfileHeader(
                        fullName: profile.fullName,
                        phone: profile.phone,
                        avatarUrl: profile.avatarUrl,
                        roleLabel: _roleLabel(ref, role),
                        onEdit: () => context.push('/profile/edit'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _QuickActionsRow(
                              guidesLabel: 'profile.guides'.tr(ref),
                              contactLabel: 'profile.contact'.tr(ref),
                              savedLabel: 'profile.saved'.tr(ref),
                              onGuides: () => context.push('/instructions'),
                              onContact: () => context.push('/profile/chat'),
                              onSaved: () => context.push('/profile/saved'),
                            ),
                            const SizedBox(height: 16),
                            _SettingsGroup(rows: settings),
                            const SizedBox(height: 16),
                            _SettingsGroup(rows: [
                              _RowData(
                                icon: LucideIcons.fileText,
                                title: 'profile.terms'.tr(ref),
                                onTap: () => context.push('/terms'),
                              ),
                              _RowData(
                                icon: LucideIcons.circleHelp,
                                title: 'profile.faq'.tr(ref),
                                onTap: () => context.push('/faq'),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            Text(
                              '${'profile.version'.tr(ref)} 1.2.0',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 20 / 14,
                                fontWeight: FontWeight.w400,
                                color: FigmaPalette.notifTitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _roleLabel(WidgetRef ref, String role) => switch (role) {
        'carrier' => 'role.carrier'.tr(ref),
        'broker' => 'role.broker'.tr(ref),
        _ => 'role.shipper'.tr(ref),
      };

  static String _localeLabel(Locale locale) {
    if (locale.languageCode == 'ru') return 'Русский';
    if (locale.languageCode == 'en') return 'English';
    if (locale.scriptCode == 'Cyrl' || locale.countryCode == 'Cyrl') {
      return 'Ўзбекча';
    }
    return "O'zbekcha";
  }

  static String _themeLabel(WidgetRef ref, ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'theme.dark'.tr(ref),
        ThemeMode.light => 'theme.light'.tr(ref),
        ThemeMode.system => 'theme.system'.tr(ref),
      };

  // Figma currency picker (7073:13603): code → "Name (CODE)" label. The
  // settings row shows the short name (text before the parenthesis).
  static const _currencies = <({String code, String label})>[
    (code: 'USD', label: 'Dollar (USD)'),
    (code: 'UZS', label: "So'm (UZS)"),
    (code: 'RUB', label: 'Rubl (RUB)'),
    (code: 'EUR', label: 'Yevro (EUR)'),
    (code: 'KZT', label: 'Tenge (KZT)'),
    (code: 'KGS', label: 'Som (KGS)'),
    (code: 'CNY', label: 'Yuan (CNY)'),
    (code: 'TJS', label: 'Somoni (TJS)'),
    (code: 'TMT', label: 'Manat (TMT)'),
  ];

  static String _currencyShort(String code) {
    for (final c in _currencies) {
      if (c.code == code) return c.label.split(' (').first;
    }
    return "So'm";
  }

  Future<void> _openCurrencyPicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(currencyProvider);
    final selected = await showDsSelectSheet<String>(
      context: context,
      title: 'picker.currency'.tr(ref),
      items: [
        for (final c in _currencies)
          DsSelectItem(value: c.code, label: c.label),
      ],
      currentValue: current,
      saveLabel: 'common.save'.tr(ref),
    );
    if (selected != null) {
      await ref.read(currencyProvider.notifier).setCurrency(selected);
    }
  }

  Future<void> _openLanguagePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localeProvider);
    final selected = await showDsSelectSheet<Locale>(
      context: context,
      title: 'picker.language'.tr(ref),
      items: const [
        DsSelectItem(value: Locale('uz', 'Cyrl'), label: 'Ўзбекча'),
        DsSelectItem(value: Locale('uz'), label: "O'zbekcha (Lotin)"),
        DsSelectItem(value: Locale('ru'), label: 'Русский'),
      ],
      currentValue: current,
      saveLabel: 'common.save'.tr(ref),
    );
    if (selected != null) {
      await ref.read(localeProvider.notifier).setLocale(selected);
    }
  }

  Future<void> _openThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showDsSelectSheet<ThemeMode>(
      context: context,
      title: 'picker.theme'.tr(ref),
      items: [
        DsSelectItem(
          value: ThemeMode.light,
          label: 'theme.light'.tr(ref),
          icon: LucideIcons.sun,
        ),
        DsSelectItem(
          value: ThemeMode.dark,
          label: 'theme.dark'.tr(ref),
          icon: LucideIcons.moon,
        ),
        DsSelectItem(
          value: ThemeMode.system,
          label: 'theme.system'.tr(ref),
          icon: LucideIcons.sunMoon,
        ),
      ],
      currentValue: current,
      saveLabel: 'common.save'.tr(ref),
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDsCenteredConfirm(
      context,
      icon: LucideIcons.logOut,
      title: 'profile.logoutMessage'.tr(ref),
      confirmText: 'profile.logoutConfirm'.tr(ref),
      cancelText: 'common.cancel'.tr(ref),
    );
    if (!ok) return;
    await ref.read(profileControllerProvider.notifier).logout();
    if (context.mounted) context.go('/auth/welcome');
  }
}

class _RowData {
  const _RowData({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.roleLabel,
    required this.onEdit,
  });

  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String roleLabel;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    // Figma frame 2087329877: 16px screen margin, internal pad t24/l16/r16/b16
    // for the avatar+name block; the edit pen is anchored to the frame's
    // top-right corner (24px from the screen edge, 8px below the status bar).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AvatarWithPill(avatarUrl: avatarUrl, roleLabel: roleLabel),
                  const SizedBox(height: 8),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w600,
                      color: FigmaPalette.notifTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (phone != null)
                    Text(
                      phone!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        fontWeight: FontWeight.w400,
                        color: FigmaPalette.inkBody,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: const Icon(LucideIcons.squarePen,
                    size: 24, color: FigmaPalette.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithPill extends StatelessWidget {
  const _AvatarWithPill({required this.avatarUrl, required this.roleLabel});

  final String? avatarUrl;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 116,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Figma: a 102 circle with a 3px #004EEB@40% OUTSIDE ring (outer
          // ⌀108), a 4px gap, then the 94 avatar image.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 108,
              height: 108,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: FigmaPalette.primary.withValues(alpha: 0.40),
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: FigmaPalette.notifIconTile,
                        alignment: Alignment.center,
                        child: const Icon(LucideIcons.user,
                            size: 40, color: FigmaPalette.primary),
                      ),
              ),
            ),
          ),
          // Role pill, overlapping the avatar bottom (Figma: 12/18, #101828).
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14101828), // #101828 @ 8%
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(
                  fontSize: 12,
                  height: 18 / 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF101828),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-action cards
// ---------------------------------------------------------------------------

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.guidesLabel,
    required this.contactLabel,
    required this.savedLabel,
    required this.onGuides,
    required this.onContact,
    required this.onSaved,
  });

  final String guidesLabel;
  final String contactLabel;
  final String savedLabel;
  final VoidCallback onGuides;
  final VoidCallback onContact;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickCard(
            icon: LucideIcons.bookOpen,
            label: guidesLabel,
            onTap: onGuides,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickCard(
            icon: LucideIcons.messageCircle,
            label: contactLabel,
            onTap: onContact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickCard(
            icon: LucideIcons.bookmark,
            label: savedLabel,
            onTap: onSaved,
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A101828), // #101828 @ 4%
                offset: Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconTile(size: 40, radius: 12, iconSize: 24, icon: icon),
              const SizedBox(height: 12),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.notifTitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.icon,
  });

  final double size;
  final double radius;
  final double iconSize;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FigmaPalette.notifIconTile,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: icon == null
          ? null
          : Icon(icon, size: iconSize, color: FigmaPalette.primary),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings group + rows
// ---------------------------------------------------------------------------

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              _SettingsRow(data: rows[i]),
              if (i != rows.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 56),
                  child: Divider(
                      height: 1, thickness: 1, color: FigmaPalette.divider),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _RowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _IconTile(size: 32, radius: 10, iconSize: 20, icon: data.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    color: FigmaPalette.notifTitle,
                  ),
                ),
              ),
              if (data.value != null) ...[
                const SizedBox(width: 8),
                Text(
                  data.value!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                    color: FigmaPalette.inkMuted,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              // Figma chevron vector: #000000, 1.5px stroke, 4x8 glyph.
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: Color(0xFF000000)),
            ],
          ),
        ),
      ),
    );
  }
}
