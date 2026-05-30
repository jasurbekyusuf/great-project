import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_confirmation_modal.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_bottom_nav.dart';
import 'package:loadme_mobile/shared/widgets/mobile_list_row.dart';

// Mirrors `client_frontend_web-master/src/modules/Profile/index.jsx`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (profile) => ListView(
          padding: EdgeInsets.zero,
          children: [
            _ProfileHead(
              fullName: profile.fullName,
              phone: profile.phone,
              rating: null,
              avatarUrl: null,
              verified: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: MobileListGroup(
                children: [
                  MobileListRow(
                    leadingIcon: Icons.edit_outlined,
                    title: 'profile.edit'.tr(ref),
                    onTap: () => context.push('/profile/edit'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.bar_chart_rounded,
                    title: 'profile.statistics'.tr(ref),
                    onTap: () => context.push('/profile/statistics'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.attach_money_rounded,
                    title: 'profile.changeCurrency'.tr(ref),
                    onTap: () => _openCurrencyPicker(context, ref),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.bookmark_outline_rounded,
                    title: 'profile.saved'.tr(ref),
                    onTap: () => context.push('/profile/saved'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.workspace_premium_outlined,
                    title: 'profile.premium'.tr(ref),
                    onTap: () => context.push('/profile/premium'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.percent_rounded,
                    title: 'profile.commission'.tr(ref),
                    onTap: () => context.push('/profile/default-commission'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.language_rounded,
                    title: 'profile.language'.tr(ref),
                    onTap: () => _openLanguagePicker(context, ref),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.brightness_6_outlined,
                    title: 'profile.theme'.tr(ref),
                    onTap: () => _openThemePicker(context, ref),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.description_outlined,
                    title: 'profile.terms'.tr(ref),
                    onTap: () => context.push('/terms'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.privacy_tip_outlined,
                    title: 'profile.privacy'.tr(ref),
                    onTap: () => context.push('/privacy-policy'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.help_outline_rounded,
                    title: 'profile.faq'.tr(ref),
                    onTap: () => context.push('/faq'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.support_agent_outlined,
                    title: 'profile.support'.tr(ref),
                    onTap: () => context.push('/profile/support-feedback'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.ondemand_video_outlined,
                    title: 'profile.instructions'.tr(ref),
                    onTap: () => context.push('/instructions'),
                  ),
                  MobileListRow(
                    leadingIcon: Icons.logout_rounded,
                    title: 'profile.logout'.tr(ref),
                    titleColor: c.error,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        DsActionDrawerItem(value: Locale('uz', 'Cyrl'), label: 'Ўзбекча (кирил)'),
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
        DsActionDrawerItem(value: ThemeMode.system, label: 'theme.system'.tr(ref)),
        DsActionDrawerItem(value: ThemeMode.light, label: 'theme.light'.tr(ref)),
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

class _ProfileHead extends StatelessWidget {
  const _ProfileHead({
    required this.fullName,
    required this.phone,
    required this.rating,
    required this.avatarUrl,
    required this.verified,
  });

  final String fullName;
  final String? phone;
  final double? rating;
  final String? avatarUrl;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle, width: 1)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(s.radiusXl),
          bottomRight: Radius.circular(s.radiusXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: c.primary50,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(_initials(fullName), style: t.h3.copyWith(color: c.primary))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.h3),
                        ),
                        if (verified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, size: 18, color: c.primary),
                        ],
                      ],
                    ),
                    if (phone != null) ...[
                      const SizedBox(height: 4),
                      Text(phone!, style: t.body.copyWith(color: c.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (rating != null) ...[
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rating!.toStringAsFixed(1), style: t.bodyLgMedium),
                  const SizedBox(width: 4),
                  Icon(Icons.star_rounded, color: c.warning300, size: 20),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
