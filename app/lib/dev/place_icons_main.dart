import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/places/presentation/place_icon_gallery.dart';
import '../l10n/app_localizations.dart';

/// Galeria ikon miejsc (v15) – osobny punkt wejścia, aplikacja go nie używa:
/// `flutter run -d <telefon> -t lib/dev/place_icons_main.dart --dart-define-from-file=env/dev.json`
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(mapboxAccessToken);
  runApp(
    MaterialApp(
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
      home: const PlaceIconGallery(),
    ),
  );
}
