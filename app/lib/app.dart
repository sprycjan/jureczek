import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/map/presentation/map_screen.dart';
import 'features/splash/presentation/splash_overlay.dart';
import 'l10n/app_localizations.dart';

class JureczekApp extends StatelessWidget {
  const JureczekApp({
    super.key,
    this.accessToken = mapboxAccessToken,
    this.showSplash = true,
  });

  final String accessToken;

  /// Testy wyłączają ekran powitalny: jego pętla nie pozwala na `pumpAndSettle`.
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      locale: const Locale('pl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Nad Navigatorem: ekran startowy powstaje od razu pod spodem, a mapa otwarta przez
      // udostępnienie przy zimnym starcie nie przykryje animacji.
      builder: showSplash && accessToken.isNotEmpty
          ? (context, child) => SplashOverlay(child: child!)
          : null,
      home: accessToken.isEmpty
          ? const MissingTokenView()
          : HomeScreen(accessToken: accessToken),
    );
  }
}
