import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/errors/app_failure.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';
import 'package:loadme_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:loadme_mobile/features/profile/domain/use_cases/update_profile_use_case.dart';
import 'package:loadme_mobile/features/profile/presentation/controllers/profile_controller.dart';
import 'package:loadme_mobile/features/profile/presentation/screens/profile_edit_screen.dart';

/// Serves a fixed profile and records the Save payload, so the screen never
/// touches Dio: both `build` and `updateProfile` are overridden, so neither the
/// use case nor the network is reached.
class _FakeProfile extends ProfileController {
  _FakeProfile(this._profile);

  final ProfileEntity _profile;
  UpdateProfileInput? captured;

  @override
  Future<ProfileEntity> build() async => _profile;

  @override
  Future<AppFailure?> updateProfile(UpdateProfileInput input) async {
    captured = input;
    state = AsyncData(_profile);
    return null;
  }
}

Widget _app(_FakeProfile fake) => ProviderScope(
      overrides: [
        // `.tr(ref)` reads appL10nProvider -> localeProvider -> SharedPreferences
        // (which is "Override in main"); pin a locale so the chain never runs.
        appL10nProvider.overrideWithValue(AppL10n(const Locale('uz'))),
        profileControllerProvider.overrideWith(() => fake),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const ProfileEditScreen(),
      ),
    );

void main() {
  testWidgets('prefills the fields from the loaded profile', (tester) async {
    await tester.pumpWidget(
      _app(
        _FakeProfile(
          const ProfileEntity(
            guid: 'g',
            fullName: 'Nikolayev Nikolay',
            companyName: 'ExportView LTD', // header title, so the field stays unique
            phone: '+998 99 999 99 99',
            telegramUsername: 'niko',
            whatsappNumber: 'nikonil',
            personType: 'individual',
          ),
        ),
      ),
    );
    await tester.pump(); // resolve the async build

    expect(find.text('Nikolayev Nikolay'), findsOneWidget); // full name field
    expect(find.text('+998 99 999 99 99'), findsOneWidget); // locked phone box
    expect(find.text('niko'), findsOneWidget); // telegram field
    expect(find.text('nikonil'), findsOneWidget); // whatsapp field
  });

  testWidgets('Save forwards the edited values to updateProfile',
      (tester) async {
    final fake = _FakeProfile(
      const ProfileEntity(
        guid: 'g',
        fullName: 'Old Name',
        phone: '+998 99 999 99 99',
        telegramUsername: 'old',
        whatsappNumber: 'oldwa',
        personType: 'individual',
      ),
    );
    await tester.pumpWidget(_app(fake));
    await tester.pump();

    // Edit the full name so the form is dirty and Save enables.
    await tester.enterText(find.byType(TextField).first, 'New Name');
    await tester.pump();

    // uz "Saqlash".
    await tester.tap(find.text('Saqlash'));
    await tester.pump(); // start _save (spinner shows)
    await tester.pump(); // let the update future complete

    expect(fake.captured, isNotNull);
    expect(fake.captured!.fullName, 'New Name');
    expect(fake.captured!.telegramUsername, 'old');
    expect(fake.captured!.whatsappNumber, 'oldwa');
    expect(fake.captured!.personType, 'individual');
  });

  testWidgets('Save is disabled until something changes', (tester) async {
    final fake = _FakeProfile(
      const ProfileEntity(
        guid: 'g',
        fullName: 'Old Name',
        phone: '+998 99 999 99 99',
        telegramUsername: 'old',
        whatsappNumber: 'oldwa',
        personType: 'individual',
      ),
    );
    await tester.pumpWidget(_app(fake));
    await tester.pump();

    // No edits yet -> tapping Save must not call updateProfile.
    await tester.tap(find.text('Saqlash'));
    await tester.pump();
    await tester.pump();

    expect(fake.captured, isNull);
  });
}
