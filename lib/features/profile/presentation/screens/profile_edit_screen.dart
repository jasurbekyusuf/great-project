import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/update_profile_use_case.dart';
import 'package:loadme_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:loadme_mobile/shared/design_system/ds_action_drawer.dart';
import 'package:loadme_mobile/shared/design_system/ds_error_state.dart';
import 'package:loadme_mobile/shared/design_system/ds_loader.dart';
import 'package:loadme_mobile/shared/widgets/app_scaffold.dart';

/// Figma "Profil tahrirlash" (6183:57809): a centered avatar, then the editable
/// account fields — Full name, Phone (locked: the OTP login identity), Telegram,
/// Whatsapp and a Profile-type selector — over a pinned full-width "Saqlash"
/// button. Values are prefilled from [profileControllerProvider]; Save PATCHes
/// `/users/me/` through [ProfileController.updateProfile] and pops on success.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _fullName = TextEditingController();
  final _telegram = TextEditingController();
  final _whatsapp = TextEditingController();

  // Read-only identity + the current Profile-type choice.
  String _phone = '';
  String? _personType;

  // Local path of a freshly picked avatar (null = keep the server photo). Sent
  // as the multipart `photo` on Save; previews immediately from the file.
  String? _pickedPhotoPath;

  // Snapshot of the loaded values, so Save only lights up on a real change.
  bool _prefilled = false;
  String _initFullName = '';
  String _initTelegram = '';
  String _initWhatsapp = '';
  String? _initPersonType;

  bool _saving = false;

  @override
  void dispose() {
    _fullName.dispose();
    _telegram.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  // Copy the loaded profile into the fields exactly once; later rebuilds (e.g.
  // the post-save state push) must not clobber the user's in-progress edits.
  void _prefill(ProfileEntity p) {
    if (_prefilled) return;
    _prefilled = true;
    _fullName.text = p.fullName == '-' ? '' : p.fullName;
    _telegram.text = p.telegramUsername ?? '';
    _whatsapp.text = p.whatsappNumber ?? '';
    _phone = p.phone ?? '';
    _personType = p.personType;
    _initFullName = _fullName.text.trim();
    _initTelegram = _telegram.text.trim();
    _initWhatsapp = _whatsapp.text.trim();
    _initPersonType = _personType;
  }

  bool get _dirty =>
      _pickedPhotoPath != null ||
      _fullName.text.trim() != _initFullName ||
      _telegram.text.trim() != _initTelegram ||
      _whatsapp.text.trim() != _initWhatsapp ||
      _personType != _initPersonType;

  String _headerTitle(ProfileEntity? p) {
    if (p == null) return 'profile.edit'.tr(ref);
    final company = p.companyName?.trim() ?? '';
    return company.isNotEmpty ? company : p.fullName;
  }

  Future<void> _pickType() async {
    final selected = await showDsSelectSheet<String>(
      context: context,
      title: 'profileEdit.profileType'.tr(ref),
      items: [
        DsSelectItem(
          value: 'individual',
          label: 'profileEdit.typeIndividual'.tr(ref),
        ),
        DsSelectItem(value: 'legal', label: 'profileEdit.typeLegal'.tr(ref)),
      ],
      currentValue: _personType ?? 'individual',
      saveLabel: 'common.save'.tr(ref),
    );
    if (selected != null && mounted) {
      setState(() => _personType = selected);
    }
  }

  /// Avatar tap: pick a new photo from the camera or gallery. The chosen file is
  /// previewed at once and uploaded as the multipart `photo` on Save.
  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera, color: FigmaPalette.ink),
              title: Text('profileEdit.fromCamera'.tr(ref)),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: FigmaPalette.ink),
              title: Text('profileEdit.fromGallery'.tr(ref)),
              onTap: () => Navigator.of(sheetCtx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() => _pickedPhotoPath = picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profileEdit.photoError'.tr(ref))),
      );
    }
  }

  Future<void> _save() async {
    // Capture everything that needs `context`/`ref` before the await so the
    // async gap can't reference a possibly-unmounted element.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final savedMsg = 'profileEdit.saved'.tr(ref);
    final errLabel = 'profileEdit.saveError'.tr(ref);

    setState(() => _saving = true);

    // Empty optional fields are sent as null (not ''), so an untouched handle is
    // never blanked on the backend. The leading `@` is stripped from Telegram.
    String? clean(String s) => s.trim().isEmpty ? null : s.trim();
    final tg = _telegram.text.trim();

    final failure =
        await ref.read(profileControllerProvider.notifier).updateProfile(
              UpdateProfileInput(
                fullName: _fullName.text.trim(),
                telegramUsername:
                    tg.isEmpty ? null : (tg.startsWith('@') ? tg.substring(1) : tg),
                whatsappNumber: clean(_whatsapp.text),
                personType: _personType,
                photoPath: _pickedPhotoPath,
              ),
            );

    if (!mounted) return;
    setState(() => _saving = false);

    if (failure == null) {
      messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
      await navigator.maybePop();
    } else {
      messenger
          .showSnackBar(SnackBar(content: Text('$errLabel: ${failure.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return AppScaffold(
      title: _headerTitle(state.valueOrNull),
      padded: false,
      backgroundColor: FigmaPalette.sheetBg,
      body: state.when(
        loading: () => const DsLoader(),
        error: (e, _) => DsErrorState(message: e.toString()),
        data: (profile) {
          _prefill(profile);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    _avatar(profile.avatarUrl),
                    const SizedBox(height: 24),
                    _labeled(
                      'profileEdit.fullName'.tr(ref),
                      required: true,
                      child: TextField(
                        controller: _fullName,
                        onChanged: _onChanged,
                        style: const TextStyle(fontSize: 16, color: FigmaPalette.ink),
                        decoration: _dec(hint: 'profileEdit.fullNameHint'.tr(ref)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labeled(
                      'profileEdit.phone'.tr(ref),
                      required: true,
                      child: _lockedBox(_phone),
                    ),
                    const SizedBox(height: 16),
                    _labeled(
                      'profileEdit.telegram'.tr(ref),
                      child: TextField(
                        controller: _telegram,
                        onChanged: _onChanged,
                        style: const TextStyle(fontSize: 16, color: FigmaPalette.ink),
                        decoration: _dec(hint: '@username'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labeled(
                      'profileEdit.whatsapp'.tr(ref),
                      child: TextField(
                        controller: _whatsapp,
                        onChanged: _onChanged,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(fontSize: 16, color: FigmaPalette.ink),
                        decoration: _dec(hint: '+998 90 123 45 67'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _labeled(
                      'profileEdit.profileType'.tr(ref),
                      child: _typeBox(),
                    ),
                  ],
                ),
              ),
              _saveBar(),
            ],
          );
        },
      ),
    );
  }

  void _onChanged(String _) => setState(() {});

  Widget _avatar(String? url) {
    // A just-picked local file wins over the server photo so the preview is
    // instant; otherwise fall back to the network avatar, then the placeholder.
    final ImageProvider? provider = _pickedPhotoPath != null
        ? FileImage(File(_pickedPhotoPath!))
        : (url != null ? NetworkImage(url) : null);

    return Center(
      child: GestureDetector(
        onTap: _pickPhoto,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: FigmaPalette.avatarBg,
                ),
                child: provider != null
                    ? Image(
                        image: provider,
                        fit: BoxFit.cover,
                        width: 96,
                        height: 96,
                      )
                    : const Icon(LucideIcons.user,
                        size: 44, color: FigmaPalette.muted),
              ),
              // Camera badge — signals the avatar is tappable to change the photo.
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: FigmaPalette.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(LucideIcons.camera,
                      size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeled(String label, {required Widget child, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w400,
                color: FigmaPalette.tertiary,
              ),
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Color(0xFFF04438)),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _dec({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        hintStyle: const TextStyle(fontSize: 16, color: FigmaPalette.muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FigmaPalette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FigmaPalette.primary, width: 1.4),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FigmaPalette.divider),
        ),
      );

  Widget _lockedBox(String value) => Container(
        height: 52,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: FigmaPalette.chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FigmaPalette.divider),
        ),
        child: Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 16, color: FigmaPalette.muted),
        ),
      );

  Widget _typeBox() {
    final label = _personType == 'legal'
        ? 'profileEdit.typeLegal'.tr(ref)
        : 'profileEdit.typeIndividual'.tr(ref);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _pickType,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FigmaPalette.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: FigmaPalette.ink),
              ),
            ),
            const Icon(LucideIcons.chevronDown,
                size: 20, color: FigmaPalette.muted),
          ],
        ),
      ),
    );
  }

  Widget _saveBar() {
    final enabled = _dirty && _fullName.text.trim().isNotEmpty && !_saving;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled
                  ? FigmaPalette.primary
                  : FigmaPalette.primary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? _save : null,
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'common.save'.tr(ref),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
