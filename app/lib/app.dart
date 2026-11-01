import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/map/presentation/map_screen.dart';
import 'l10n/app_localizations.dart';

class JureczekApp extends StatelessWidget {
  const JureczekApp({super.key, this.accessToken = mapboxAccessToken});

  final String accessToken;

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
      home: MapScreen(accessToken: accessToken),
    );
  }
}
