import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/config/routes/app_router.dart';
import 'package:loadme_mobile/core/services/app_state_providers.dart';
import 'package:loadme_mobile/core/theme/app_theme.dart';

class LoadmeApp extends ConsumerWidget {
  const LoadmeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Loadme',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Dark tema hali tayyor emas — system/foydalanuvchi dark tanlasa ham
      // light ko'rinsin (aks holda UI buziladi).
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
