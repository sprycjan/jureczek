import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'features/map/presentation/map_labels.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(mapboxAccessToken);
  MapboxMapsOptions.setLanguage(mapLabelLanguage);
  _registerFontLicenses();
  runApp(const ProviderScope(child: JureczekApp()));
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
