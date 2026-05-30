import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/app_typography_tokens.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

// Mirrors `client_frontend_web-master/src/modules/ProfileEditPage/index.jsx`.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();
  final _telegram = TextEditingController();
  bool _isCompany = false;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _company.dispose();
    _telegram.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.space;
    final t = context.types;

    return AppScaffold(
      title: 'profile.edit'.tr(ref),
      padded: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(s.lg, s.lg, s.lg, 96),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(radius: 44, backgroundColor: c.primary50),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: s.xl),
          _Label('profileEdit.fullName'.tr(ref), t),
          TextField(controller: _fullName, decoration: const InputDecoration(hintText: 'Ivanov Ivan')),
          SizedBox(height: s.md),
          _Label('profileEdit.phone'.tr(ref), t),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+998 90 123 45 67'),
          ),
          SizedBox(height: s.md),
          SwitchListTile.adaptive(
            value: _isCompany,
            onChanged: (v) => setState(() => _isCompany = v),
            title: Text('profileEdit.isCompany'.tr(ref)),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isCompany) ...[
            _Label('profileEdit.companyName'.tr(ref), t),
            TextField(controller: _company, decoration: const InputDecoration(hintText: 'OOO Example')),
            SizedBox(height: s.md),
          ],
          _Label('profileEdit.telegram'.tr(ref), t),
          TextField(controller: _telegram, decoration: const InputDecoration(hintText: '@username')),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.t);
  final String text;
  final AppTypographyTokens t;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: t.caption.copyWith(color: context.colors.textSecondary)),
    );
  }
}
