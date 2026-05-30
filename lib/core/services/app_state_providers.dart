import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/storage/providers.dart';

// Supported app locales — must match `assets/l10n/app_*.arb`.
// `cyr` is treated as `uz_Cyrl` (Cyrillic Uzbek) and falls back to `uz` strings.
const supportedAppLocales = [
  Locale('uz'),
  Locale('uz', 'Cyrl'),
  Locale('ru'),
  Locale('en'),
];

const _kLocaleKey = 'app.locale';
const _kThemeKey = 'app.themeMode';

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kLocaleKey);
    if (raw == null) return const Locale('uz');
    final parts = raw.split('_');
    if (parts.length == 2) return Locale(parts[0], parts[1]);
    return Locale(parts[0]);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = locale.countryCode == null && locale.scriptCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode ?? locale.scriptCode}';
    await prefs.setString(_kLocaleKey, key);
    state = locale;
  }
}

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kThemeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kThemeKey, mode.name);
    state = mode;
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
