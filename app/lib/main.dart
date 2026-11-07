import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/home/domain/landscape.dart';
import 'features/map/presentation/map_labels.dart';
import 'features/splash/application/splash_start.dart';
import 'features/splash/domain/splash_config.dart';
import 'features/splash/presentation/splash_overlay.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(mapboxAccessToken);
  MapboxMapsOptions.setLanguage(mapLabelLanguage);
  _registerFontLicenses();
  runApp(
    ProviderScope(
      child: JureczekApp(
        // Bez tokenu nie ma nakładki, która zwolniłaby pierwszą klatkę.
        splashStart: mapboxAccessToken.isEmpty
            ? null
            : SplashStart(
                art: loadRandomSplashArt(Landscape.at(DateTime.now())),
                deferFirstFrame: binding.deferFirstFrame,
                allowFirstFrame: binding.allowFirstFrame,
                limit: const SplashConfig().firstFrameLimit,
              ),
      ),
    ),
  );
}

/// Licencje OFL dołączonych czcionek – widoczne na liście licencji aplikacji.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, file) in [
      ('Epilogue', 'OFL-Epilogue.txt'),
      ('Space Grotesk', 'OFL-SpaceGrotesk.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
