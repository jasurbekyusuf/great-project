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

/// Figma "Profil" (6985:12842 carrier / 7073:13659 yuk egasi). A blue gradient
/// header with a ringed avatar, a role pill, name + phone and an edit pen; then,
/// for carriers, a row of three quick-action cards (Qo'llanmalar / Bog'lanish /
/// Saqlanganlar); then grouped settings rows and an app version.
///
/// Drivers (carrier) get the quick-action cards. Dispatchers (broker) and cargo
/// owners (shipper) share the simpler "yuk egasi" layout where Saqlanganlar is
/// the first settings row instead.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleSyncProvider);
    final isCarrier = role == 'carrier';
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

          final settings = <_RowData>[
            if (!isCarrier)
              _RowData(
                icon: LucideIcons.bookmark,
                title: 'Saqlanganlar',
                onTap: () => context.push('/profile/saved'),
              ),
            _RowData(
              icon: LucideIcons.dollarSign,
              title: 'Valyuta',
              value: "So'm",
              onTap: () => _openCurrencyPicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.languages,
              title: 'Ilova tili',
              value: _localeLabel(locale),
              onTap: () => _openLanguagePicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.sun,
              title: 'Ekran rejimi',
              value: _themeLabel(themeMode),
              onTap: () => _openThemePicker(context, ref),
            ),
            _RowData(
              icon: LucideIcons.logOut,
              title: 'Akkauntdan chiqish',
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
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _ProfileHeader(
                        fullName: profile.fullName,
                        phone: profile.phone,
                        avatarUrl: profile.avatarUrl,
                        roleLabel: _roleLabel(role),
                        onEdit: () => context.push('/profile/edit'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            if (isCarrier) ...[
                              _QuickActionsRow(
                                onGuides: () => context.push('/instructions'),
                                onContact: () =>
                                    context.push('/profile/support-feedback'),
                                onSaved: () => context.push('/profile/saved'),
                              ),
                              const SizedBox(height: 16),
                            ],
                            _SettingsGroup(rows: settings),
                            const SizedBox(height: 16),
                            _SettingsGroup(rows: [
                              _RowData(
                                icon: LucideIcons.fileText,
                                title: 'Foydalanish shartlari',
                                onTap: () => context.push('/terms'),
                              ),
                              _RowData(
                                icon: LucideIcons.circleHelp,
                                title: 'Ko\'p beriladigan savollar',
                                onTap: () => context.push('/faq'),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            const Text(
                              'Versiya 1.2.0',
                              style: TextStyle(
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

  static String _roleLabel(String role) => switch (role) {
        'carrier' => 'Haydovchi',
        'broker' => 'Dispecher',
        _ => 'Yuk egasi',
      };

  static String _localeLabel(Locale locale) {
    if (locale.languageCode == 'ru') return 'Русский';
    if (locale.languageCode == 'en') return 'English';
    if (locale.scriptCode == 'Cyrl') return 'Ўзбекча';
    return "O'zbekcha";
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'Tungi',
        ThemeMode.light => 'Kunduzgi',
        ThemeMode.system => 'Tizim',
      };

  Future<void> _openCurrencyPicker(BuildContext context, WidgetRef ref) async {
    await showDsActionDrawer<String>(
      context: context,
      title: 'picker.currency'.tr(ref),
      items: const [
        DsActionDrawerItem(value: 'USD', label: 'USD'),
        DsActionDrawerItem(value: 'UZS', label: 'UZS'),
        DsActionDrawerItem(value: 'RUB', label: 'RUB'),
      ],
      currentValue: 'UZS',
    );
  }

  Future<void> _openLanguagePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(localeProvider);
    final selected = await showDsActionDrawer<Locale>(
      context: context,
      title: 'picker.language'.tr(ref),
      items: const [
        DsActionDrawerItem(value: Locale('uz'), label: "O'zbekcha (lotin)"),
        DsActionDrawerItem(
            value: Locale('uz', 'Cyrl'), label: 'Ўзбекча (кирил)'),
        DsActionDrawerItem(value: Locale('ru'), label: 'Русский'),
        DsActionDrawerItem(value: Locale('en'), label: 'English'),
      ],
      currentValue: current,
    );
    if (selected != null) {
      await ref.read(localeProvider.notifier).setLocale(selected);
    }
  }

  Future<void> _openThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showDsActionDrawer<ThemeMode>(
      context: context,
      title: 'picker.theme'.tr(ref),
      items: [
        DsActionDrawerItem(
            value: ThemeMode.system, label: 'theme.system'.tr(ref)),
        DsActionDrawerItem(
            value: ThemeMode.light, label: 'theme.light'.tr(ref)),
        DsActionDrawerItem(value: ThemeMode.dark, label: 'theme.dark'.tr(ref)),
      ],
      currentValue: current,
    );
    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setThemeMode(selected);
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDsConfirmation(
      context,
      title: 'profile.logoutTitle'.tr(ref),
      message: 'profile.logoutMessage'.tr(ref),
      confirmText: 'profile.logout'.tr(ref),
      cancelText: 'common.cancel'.tr(ref),
      intent: DsConfirmIntent.logout,
      icon: Icons.logout_rounded,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
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
          Positioned(
            right: 0,
            top: 8,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: const Icon(LucideIcons.squarePen,
                  size: 24, color: FigmaPalette.primary),
            ),
          ),
        ],
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
      height: 114,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 102 ring: 3px #004EEB @40%, 4px inner padding.
          Container(
            width: 102,
            height: 102,
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
                          size: 36, color: FigmaPalette.primary),
                    ),
            ),
          ),
          // Role pill, overlapping the avatar bottom by 12px.
          Positioned(
            top: 90,
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
                  fontSize: 13,
                  height: 18 / 13,
                  fontWeight: FontWeight.w500,
                  color: FigmaPalette.notifTitle,
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
// Quick-action cards (carrier only)
// ---------------------------------------------------------------------------

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onGuides,
    required this.onContact,
    required this.onSaved,
  });

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
            label: 'Qo\'llanmalar',
            onTap: onGuides,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickCard(
            icon: LucideIcons.messageCircle,
            label: 'Bog\'lanish',
            onTap: onContact,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickCard(
            icon: LucideIcons.bookmark,
            label: 'Saqlanganlar',
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
              const Icon(LucideIcons.chevronRight,
                  size: 16, color: FigmaPalette.label),
            ],
          ),
        ),
      ),
    );
  }
}
