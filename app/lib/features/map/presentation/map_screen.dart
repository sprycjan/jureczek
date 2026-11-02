import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/haptics/haptics.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../folders/application/folders_providers.dart';
import '../../folders/presentation/folder_badge.dart';
import '../../share/application/shared_place_controller.dart';
import '../application/place_search_controller.dart';
import '../application/pins_providers.dart';
import '../domain/duplicate_pin.dart';
import '../domain/pin_category.dart';
import '../domain/place_pin.dart';
import '../domain/place_suggestion.dart';
import '../domain/poi_place.dart';
import 'map_style.dart';
import 'map_style_picker.dart';
import 'map_tools.dart';
import 'new_pin_sheet.dart';
import 'pin_details_sheet.dart';
import 'pin_drop.dart';
import 'pin_form_fields.dart';
import 'place_adjust_overlay.dart';
import 'place_search_field.dart';
import 'search_result_card.dart';

/// Środek Polski i zoom obejmujący cały kraj – start, gdy nie ma pinezek.
final _polandViewport = CameraViewportState(
  center: Point(coordinates: Position(19.4, 52.0)),
  zoom: 5.3,
);

/// Wygląd pinezki na mapie: typ i to, czy jest zaznaczona (otwarty arkusz).
typedef _PinLook = (PinCategory, bool);

/// Id obrazka w stylu mapy – jeden bitmap na wygląd, wspólny dla wszystkich pinezek.
String _lookImageId(_PinLook look) =>
    'pin-${look.$1.key}-${look.$2 ? 'selected' : 'default'}';

/// Rozmiar PNG (szerokość, wysokość) z nagłówka IHDR.
Size _pngSize(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  return Size(data.getUint32(16).toDouble(), data.getUint32(20).toDouble());
}

/// Zapas na narysowanie pinezki przez Mapbox, zanim zniknie nakładka –
/// bez niego przez klatkę nie widać żadnej i pinezka miga.
const _mapRenderDelay = Duration(milliseconds: 150);

/// Czas zamykania arkusza – nowa pinezka spada dopiero na odsłoniętą mapę.
const _sheetCloseDelay = Duration(milliseconds: 250);

/// Najbliższy zoom przy dopasowaniu kamery do pinezek – jedna pinezka
/// pokazuje się z okolicą, a nie z bliska ulicy.
const _fitMaxZoom = 12.0;

/// Margines od krawędzi ekranu przy dopasowaniu kamery do pinezek.
const _fitPadding = 48.0;

/// Zoom po przelocie do wyniku wyszukiwania lub udostępnionego miejsca.
const _resultZoom = 15.0;

/// Odstęp narzędzi od krawędzi ekranu (pod paskiem statusu).
const _toolsPadding = 16.0;

/// Rozmiar okrągłego przycisku-narzędzia (domyślny [IconButton]).
const _toolSize = 48.0;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.accessToken, this.folderId});

  final String accessToken;

  /// Tryb folderu (v10): widać tylko jego pinezki i do niego trafiają nowe.
  /// `null` – wszystkie pinezki, wybór folderu w formularzu, udostępnienia.
  final String? folderId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  PointAnnotationManager? _pinManager;

  /// PNG pinezek 3x dla każdego wyglądu; gotowe, gdy niepuste.
  final _pinImages = <_PinLook, Uint8List>{};

  /// Obrazki spadających pinezek, zdekodowane zawczasu (`precacheImage`).
  final _dropImages = <PinCategory, MemoryImage>{};

  /// Mapbox rysuje obrazek w pikselach fizycznych: PNG 3x × ta skala = rozmiar w dp.
  double _pinIconSize = 1;

  /// Pinezka z otwartym arkuszem – rysowana jako zaznaczona.
  String? _selectedPinId;
  Cancelable? _tapEvents;

  /// Pinezki narysowane na mapie i odwrotne mapowanie dla tapnięć.
  final _annotationsByPinId = <String, PointAnnotation>{};
  final _pinIdByAnnotationId = <String, String>{};
  final _lookByPinId = <String, _PinLook>{};

  /// Nowe pinezki, które jeszcze spadają: na mapie są niewidoczne,
  /// a nad mapą leci ich nakładka [PinDrop].
  final _droppingIds = <String>{};

  /// Osobny notifier, żeby start i koniec spadania nie przebudowywały całego ekranu.
  final _drops = ValueNotifier(
    const <({String id, Offset anchor, PinCategory category})>[],
  );

  /// Ostatni stan z bazy, do którego doprowadzamy mapę.
  List<PlacePin> _pins = const [];

  /// Kolejne synchronizacje idą po sobie, żeby się nie przeplatały.
  Future<void> _sync = Future.value();

  /// Tymczasowy znacznik wybranego wyniku wyszukiwania (nie jest pinezką).
  CircleAnnotationManager? _resultManager;
  PlaceResult? _result;

  /// Wynik, który przyszedł, zanim mapa była gotowa (udostępnienie przy zimnym starcie).
  PlaceResult? _pendingResult;

  /// Tryb „Popraw położenie”: miejsce wskazuje celownik na środku mapy.
  bool _adjusting = false;

  bool _searchOpen = false;
  final _searchText = TextEditingController();

  /// Zasłona w kolorze tła do wczytania stylu – bez niej przy wejściu na mapę
  /// miga pusta klatka (v11; od v12 styl jest własny, bez nakładanej palety).
  /// Zasłona schodzi, gdy styl jest wczytany, a kamera ustawiona na pinezkach –
  /// inaczej na chwilę widać Polskę przed przeskokiem.
  final _styleReady = ValueNotifier(false);
  bool _styleLoaded = false;
  bool _cameraPlaced = false;
  Timer? _curtainFallback;
  final _searchFocus = FocusNode();

  /// Bieżący styl mapy i rozwinięta lista stylów (v13).
  MapStyleOption _style = MapStyleOption.vanventure;
  bool _stylesOpen = false;

  @override
  void initState() {
    super.initState();
    // Udostępnienia obsługuje tylko mapa wszystkich pinezek; ekran startowy
    // otwiera ją, gdy udostępnienie się zaczyna – stąd stan bieżący na starcie.
    if (widget.folderId == null) {
      ref.listenManual(sharedPlaceControllerProvider, (previous, next) {
        if (previous == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _onSharedPlace(next);
          });
        } else {
          _onSharedPlace(next);
        }
      }, fireImmediately: true);
    }
  }

  @override
  void dispose() {
    _tapEvents?.cancel();
    _drops.dispose();
    _styleReady.dispose();
    _curtainFallback?.cancel();
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onStyleLoaded() {
    if (_styleLoaded) {
      _onStyleSwitched();
      return;
    }
    _styleLoaded = true;
    _updateCurtain();
  }

  /// Zmiana stylu: lista się zamyka, kamera pochyla się do 3D albo prostuje.
  Future<void> _selectStyle(MapStyleOption style) async {
    setState(() => _stylesOpen = false);
    final map = _map;
    if (map == null || style == _style) return;
    final pitch = style.pitch;
    setState(() => _style = style);
    try {
      await map.setStyleURI(style.uri);
      if ((await map.getCameraState()).pitch != pitch) {
        await map.easeTo(
          CameraOptions(pitch: pitch),
          MapAnimationOptions(duration: 800),
        );
      }
    } catch (e) {
      debugPrint('Zmiana stylu mapy nie powiodła się: $e');
    }
  }

  /// Nowy styl nie ma obrazków pinezek (dodawanych do stylu przy tworzeniu
  /// anotacji), więc pinezki rysujemy od nowa. Znacznik wyniku też.
  Future<void> _onStyleSwitched() async {
    final map = _map;
    if (map == null) return;
    final config = _style.basemapConfig;
    if (config.isNotEmpty) {
      try {
        await map.setStyleImportConfigProperties('basemap', config);
      } catch (e) {
        debugPrint('Konfiguracja stylu Standard nie powiodła się: $e');
      }
    }
    _sync = _sync
        .then((_) async {
          await _pinManager?.deleteAll();
          _annotationsByPinId.clear();
          _pinIdByAnnotationId.clear();
          _lookByPinId.clear();
        })
        .catchError((Object e) {
          debugPrint(
            'Czyszczenie pinezek po zmianie stylu nie powiodło się: $e',
          );
        });
    _scheduleSync(ref.read(pinsProvider).value ?? _pins);
    final result = _result;
    if (result != null && !_adjusting) await _showResult(result, fly: false);
  }

  void _toggleStyles() {
    if (_searchOpen) _closeSearch();
    setState(() => _stylesOpen = !_stylesOpen);
  }

  void _updateCurtain() {
    if (mounted && _styleLoaded && _cameraPlaced) _styleReady.value = true;
  }

  /// Raz, gdy są i mapa, i pinezki: kamera obejmuje wszystkie widoczne pinezki.
  /// Bez pinezek albo z wynikiem do pokazania (udostępnienie) zostaje widok startowy.
  Future<void> _placeCamera() async {
    final map = _map;
    final all = ref.read(pinsProvider).value;
    if (_cameraPlaced || map == null || all == null || _pinImages.isEmpty) {
      return;
    }
    _cameraPlaced = true;
    final pins = _visible(all);
    if (pins.isNotEmpty && _result == null && _pendingResult == null) {
      try {
        final insets = MediaQuery.paddingOf(context);
        // Pinezka stoi czubkiem na punkcie, więc u góry trzeba miejsca na jej
        // wysokość – ponad narzędziami pod paskiem statusu.
        final pinHeight =
            _pngSize(_pinImages[(PinCategory.fallback, false)]!).height /
            pinImageScale;
        final camera = await map.cameraForCoordinatesPadding(
          [
            for (final pin in pins)
              Point(coordinates: Position(pin.lng, pin.lat)),
          ],
          CameraOptions(),
          MbxEdgeInsets(
            top: insets.top + _toolsPadding + _toolSize + pinHeight,
            left: _fitPadding,
            bottom: insets.bottom + _fitPadding,
            right: _fitPadding,
          ),
          _fitMaxZoom,
          null,
        );
        await map.setCamera(camera);
      } catch (e) {
        debugPrint('Dopasowanie kamery do pinezek nie powiodło się: $e');
      }
    }
    _updateCurtain();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    // Gdyby styl się nie wczytał (np. brak sieci), zasłona nie może zostać na zawsze.
    _curtainFallback = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _styleReady.value = true;
    });
    await _placeOrnaments(map);
    await _loadPinImages();
    final manager = await map.annotations.createPointAnnotationManager();
    _pinManager = manager;
    _tapEvents = manager.tapEvents(onTap: _onPinTapped);

    // Long-tap na pinezce nic nie robi – stopPropagation nie przepuszcza go
    // do interakcji na całej mapie, więc nie powstaje dubel. Id managera to id warstwy.
    map.addInteraction(
      LongTapInteraction(
        FeaturesetDescriptor(layerId: manager.id),
        (_, _) {},
        stopPropagation: true,
      ),
    );

    // POI z warstwy etykiet własnego stylu: tap pokazuje kartę jak wynik wyszukiwania,
    // long-tap od razu stawia pinezkę z nazwą w punkcie POI, nie pod palcem.
    map.addInteraction(
      TapInteraction(FeaturesetDescriptor(layerId: poiLabelLayerId), (poi, _) {
        _searchFocus.unfocus();
        final place = placeFromPoi(
          name: poi.properties['name'] as String?,
          geometry: poi.geometry,
        );
        if (place != null) _showResult(place, fly: false);
      }),
    );
    map.addInteraction(
      LongTapInteraction(FeaturesetDescriptor(layerId: poiLabelLayerId), (
        poi,
        _,
      ) {
        final place = placeFromPoi(
          name: poi.properties['name'] as String?,
          geometry: poi.geometry,
        );
        if (place == null) return;
        _addResultPin(place);
      }),
    );

    // Styl 3D (Standard) ma POI w featuresecie `poi`.
    map.addInteraction(
      TapInteraction(StandardPOIs(), (poi, _) {
        _searchFocus.unfocus();
        final place = placeFromPoi(name: poi.name, geometry: poi.geometry);
        if (place != null) _showResult(place, fly: false);
      }),
    );
    map.addInteraction(
      LongTapInteraction(StandardPOIs(), (poi, _) {
        final place = placeFromPoi(name: poi.name, geometry: poi.geometry);
        if (place != null) _addResultPin(place);
      }),
    );

    map.addInteraction(
      LongTapInteraction.onMap((context) {
        final position = context.point.coordinates;
        _addResultPin(
          PlaceResult(
            name: null,
            lat: position.lat.toDouble(),
            lng: position.lng.toDouble(),
          ),
        );
      }),
    );

    // Tworzony po pinezkach, więc znacznik wyniku leży nad nimi.
    _resultManager = await map.annotations.createCircleAnnotationManager();

    // Tap w mapę chowa podpowiedzi i klawiaturę; tekst w polu zostaje.
    map.addInteraction(
      TapInteraction.onMap((_) {
        _searchFocus.unfocus();
        if (_stylesOpen && mounted) setState(() => _stylesOpen = false);
      }, stopPropagation: false),
    );

    _scheduleSync(ref.read(pinsProvider).value ?? const []);
    await _placeCamera();

    final pending = _pendingResult;
    _pendingResult = null;
    if (pending != null) await _showResult(pending);
  }

  Future<void> _loadPinImages() async {
    _pinIconSize = MediaQuery.devicePixelRatioOf(context) / pinImageScale;
    for (final category in PinCategory.values) {
      for (final selected in [false, true]) {
        final data = await rootBundle.load(category.asset(selected: selected));
        _pinImages[(category, selected)] = data.buffer.asUint8List();
      }
      final drop = MemoryImage(_pinImages[(category, false)]!);
      _dropImages[category] = drop;
      if (mounted) await precacheImage(drop, context);
    }
  }

  /// Mapa leży pod paskiem statusu, więc kompas schodzi pod narzędzia (lupa, style),
  /// a skala na dół – po prawej, bo lewy dół zajmuje logo i atrybucja Mapbox.
  Future<void> _placeOrnaments(MapboxMap map) async {
    final insets = MediaQuery.paddingOf(context);
    await map.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: insets.top + _toolsPadding + 2 * (_toolSize + 12),
        marginRight: _toolsPadding + 4,
      ),
    );
    await map.scaleBar.updateSettings(
      ScaleBarSettings(
        position: OrnamentPosition.BOTTOM_RIGHT,
        marginBottom: insets.bottom + 8,
        marginRight: _toolsPadding,
      ),
    );
  }

  /// Pinezki widoczne w tym trybie mapy.
  List<PlacePin> _visible(List<PlacePin> all) {
    final folderId = widget.folderId;
    if (folderId == null) return all;
    return [
      for (final pin in all)
        if (pin.folderId == folderId) pin,
    ];
  }

  void _scheduleSync(List<PlacePin> pins) {
    _pins = _visible(pins);
    _sync = _sync.then((_) => _syncPins()).catchError((Object e) {
      debugPrint('Synchronizacja pinezek nie powiodła się: $e');
    });
  }

  /// Doprowadza pinezki na mapie do stanu z bazy: usuwa zbędne, dorysowuje brakujące.
  Future<void> _syncPins() async {
    final manager = _pinManager;
    if (manager == null || _pinImages.isEmpty) return;

    final pins = _pins;
    final wantedIds = {for (final pin in pins) pin.id};

    var changed = false;
    final stale = _annotationsByPinId.keys
        .where((id) => !wantedIds.contains(id))
        .toList();
    for (final id in stale) {
      final annotation = _annotationsByPinId.remove(id)!;
      _pinIdByAnnotationId.remove(annotation.id);
      _lookByPinId.remove(id);
      await manager.delete(annotation);
      changed = true;
    }

    for (final pin in pins) {
      final look = (pin.category, pin.id == _selectedPinId);
      final existing = _annotationsByPinId[pin.id];
      if (existing != null) {
        if (_lookByPinId[pin.id] == look) continue;
        existing
          ..image = _pinImages[look]
          ..iconImage = _lookImageId(look);
        await manager.update(existing);
        _lookByPinId[pin.id] = look;
        changed = true;
        continue;
      }
      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(pin.lng, pin.lat)),
          image: _pinImages[look],
          iconImage: _lookImageId(look),
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: _pinIconSize,
          iconOpacity: _droppingIds.contains(pin.id) ? 0 : 1,
        ),
      );
      _annotationsByPinId[pin.id] = annotation;
      _pinIdByAnnotationId[annotation.id] = pin.id;
      _lookByPinId[pin.id] = look;
      changed = true;
    }
    if (changed) await _repaintMap();
  }

  /// Mapa jako TextureView (TLHC) pokazuje klatkę o jedną „spóźnioną”:
  /// po zmianie pinezek (wygląd, widoczność, dodanie, usunięcie) Mapbox
  /// rysuje jedną klatkę na żądanie, a na ekranie zostaje
  /// poprzednia – dopóki mapy się nie poruszy.
  /// Dodatkowe przerysowanie wypycha właściwą klatkę na ekran.
  Future<void> _repaintMap() async {
    final map = _map;
    if (map == null) return;
    await map.triggerRepaint();
    await Future<void>.delayed(_mapRenderDelay);
    if (mounted) await _map?.triggerRepaint();
  }

  Future<void> _setPinOpacity(String id, double opacity) {
    return _sync = _sync
        .then((_) async {
          final manager = _pinManager;
          final annotation = _annotationsByPinId[id];
          if (manager == null || annotation == null) return;
          if (annotation.iconOpacity == opacity) return;
          annotation.iconOpacity = opacity;
          await manager.update(annotation);
          await _repaintMap();
        })
        .catchError((Object e) {
          debugPrint('Zmiana widoczności pinezki nie powiodła się: $e');
        });
  }

  /// Nowa pinezka zostaje na mapie niewidoczna, dopóki nie spadnie [_dropPin].
  void _holdPin(String id) {
    _droppingIds.add(id);
    _setPinOpacity(id, 0);
  }

  Future<void> _dropPin(
    String id, {
    required double lat,
    required double lng,
    required PinCategory category,
  }) async {
    final map = _map;
    if (map == null || _dropImages.isEmpty || !mounted) return _landPin(id);
    try {
      final pixel = await map.pixelForCoordinate(
        Point(coordinates: Position(lng, lat)),
      );
      if (!mounted) return;
      _drops.value = [
        ..._drops.value,
        (id: id, anchor: Offset(pixel.x, pixel.y), category: category),
      ];
    } catch (e) {
      debugPrint('Pozycja spadającej pinezki nieznana: $e');
      _landPin(id);
    }
  }

  /// Nakładka znika dopiero, gdy pod nią stoi już widoczna pinezka Mapbox.
  Future<void> _landPin(String id) async {
    _droppingIds.remove(id);
    await _setPinOpacity(id, 1);
    await Future<void>.delayed(_mapRenderDelay);
    if (!mounted) return;
    _drops.value = [
      for (final drop in _drops.value)
        if (drop.id != id) drop,
    ];
  }

  void _onPinTapped(PointAnnotation annotation) {
    final pinId = _pinIdByAnnotationId[annotation.id];
    final pin = _pins.where((p) => p.id == pinId).firstOrNull;
    if (pin == null || !mounted) return;

    _clearResult();
    _openPinSheet(pin);
  }

  /// [notice] trafia do arkusza, bo snackbar byłby pod nim niewidoczny.
  Future<void> _openPinSheet(PlacePin pin, {String? notice}) async {
    _selectPin(pin.id);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Pozwala arkuszowi urosnąć nad klawiaturę przy edycji.
      isScrollControlled: true,
      builder: (sheetContext) => PinDetailsSheet(
        pin: pin,
        notice: notice,
        onDelete: () {
          Navigator.of(sheetContext).pop();
          _deletePin(pin.id);
        },
        onSave: (details) => _savePinDetails(pin.id, details),
        canMoveFolder: true,
      ),
    );
    if (_selectedPinId == pin.id) _selectPin(null);
  }

  void _selectPin(String? id) {
    _selectedPinId = id;
    _scheduleSync(ref.read(pinsProvider).value ?? _pins);
  }

  /// Błąd pokazuje sam arkusz, bo snackbar byłby pod nim niewidoczny.
  Future<bool> _savePinDetails(String id, PinDetailsInput details) async {
    try {
      await ref
          .read(pinsControllerProvider)
          .updateDetails(
            id,
            name: details.name,
            note: details.note,
            address: details.address,
            category: details.category,
            folderId: details.folderId,
          );
      return true;
    } catch (e) {
      debugPrint('Zapis nazwy/notatki nie powiódł się: $e');
      return false;
    }
  }

  Future<void> _deletePin(String id) async {
    final controller = ref.read(pinsControllerProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final removed = await _run(() => controller.remove(id));
    if (removed == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.pinDeleted),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _run(() => controller.restore(removed)),
          ),
        ),
      );
  }

  void _toggleSearch() {
    if (_searchOpen) {
      _closeSearch();
    } else {
      setState(() {
        _searchOpen = true;
        _stylesOpen = false;
      });
    }
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _searchText.clear();
    ref.read(placeSearchControllerProvider.notifier).reset();
    setState(() => _searchOpen = false);
  }

  /// Otwiera wyszukiwarkę z wpisaną nazwą, np. gdy udostępnionego miejsca
  /// nie udało się zlokalizować pewnie.
  void _searchFor(String name) {
    _clearResult();
    _searchText.text = name;
    setState(() => _searchOpen = true);
    _searchFocus.requestFocus();
    _onSearchChanged(name);
  }

  void _onSearchChanged(String text) {
    ref
        .read(placeSearchControllerProvider.notifier)
        .onQueryChanged(text, proximity: _cameraCenter);
  }

  Future<LatLng?> _cameraCenter() async {
    final map = _map;
    if (map == null) return null;
    final center = (await map.getCameraState()).center.coordinates;
    return (lat: center.lat.toDouble(), lng: center.lng.toDouble());
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    final result = await ref
        .read(placeSearchControllerProvider.notifier)
        .select(suggestion);
    // Przy błędzie pole zostaje otwarte z komunikatem w miejscu listy.
    if (result == null || !mounted) return;

    _closeSearch();
    await _showResult(result);
  }

  /// Pokazuje miejsce z kartą „Dodaj pinezkę”. Gdy w pobliżu jest już pinezka,
  /// zamiast tego otwiera jej arkusz. Przybliżone położenie nie jest sprawdzane,
  /// bo może być daleko od prawdziwego – sprawdzamy je po poprawieniu.
  Future<void> _showResult(PlaceResult result, {bool fly = true}) async {
    if (_map == null) {
      _pendingResult = result;
      return;
    }
    if (!result.approximate) {
      final duplicate = nearestPinWithin(_pins, (
        lat: result.lat,
        lng: result.lng,
      ), duplicateThresholdMeters(result.lat, _resultZoom));
      if (duplicate != null) return _showDuplicate(duplicate);
    }

    final point = Point(coordinates: Position(result.lng, result.lat));
    setState(() => _result = result);

    final manager = _resultManager;
    if (manager != null) {
      await manager.deleteAll();
      await manager.create(
        CircleAnnotationOptions(
          geometry: point,
          circleRadius: 9,
          circleColor: Nocturnal.secondary.toARGB32(),
          circleStrokeColor: Nocturnal.surface.toARGB32(),
          circleStrokeWidth: 3,
        ),
      );
    }
    if (fly) await _flyTo(point);
  }

  Future<void> _flyTo(Point point) async {
    await _map?.flyTo(
      CameraOptions(center: point, zoom: _resultZoom),
      MapAnimationOptions(duration: 1500),
    );
  }

  Future<void> _showDuplicate(PlacePin pin) async {
    _clearResult();
    _openPinSheet(pin, notice: AppLocalizations.of(context).pinDuplicate);
    await _flyTo(Point(coordinates: Position(pin.lng, pin.lat)));
  }

  void _clearResult() {
    _pendingResult = null;
    if (_result == null && !_adjusting) return;
    setState(() {
      _result = null;
      _adjusting = false;
    });
    _resultManager?.deleteAll();
  }

  /// Znacznik znika, a miejsce wskazuje celownik na środku mapy.
  void _startAdjust() {
    setState(() => _adjusting = true);
    _resultManager?.deleteAll();
  }

  Future<void> _finishAdjust() async {
    final result = _result;
    final center = await _cameraCenter();
    if (result == null || center == null || !mounted) return;
    setState(() => _adjusting = false);
    await _showResult(result.movedTo(center), fly: false);
  }

  Future<void> _cancelAdjust() async {
    final result = _result;
    setState(() => _adjusting = false);
    if (result != null) await _showResult(result, fly: false);
  }

  /// Formularz z danymi wyniku; pinezka powstaje dopiero po „Zapisz”
  /// i spada, gdy arkusz się zamknie.
  Future<void> _addResultPin(PlaceResult result) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? addedId;
    var category = PinCategory.fallback;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => NewPinSheet(
        place: result,
        chooseFolder: widget.folderId == null,
        onSave: (details) async {
          category = details.category;
          try {
            final folderId =
                widget.folderId ??
                details.folderId ??
                await ref.read(foldersControllerProvider).ensureDefault();
            addedId = await ref
                .read(pinsControllerProvider)
                .add(
                  folderId: folderId,
                  lat: result.lat,
                  lng: result.lng,
                  name: details.name,
                  address: details.address,
                  note: details.note,
                  sourceUrl: result.sourceUrl,
                  category: details.category,
                );
          } catch (e) {
            debugPrint('Zapis pinezki nie powiódł się: $e');
            return false;
          }
          _holdPin(addedId!);
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          _clearResult();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.pinAdded)));
          return true;
        },
      ),
    );

    final id = addedId;
    if (id == null) return;
    await Future<void>.delayed(_sheetCloseDelay);
    await _dropPin(id, lat: result.lat, lng: result.lng, category: category);
  }

  /// Nowe udostępnienie zastępuje wszystko, co było otwarte.
  void _onSharedPlace(SharedPlaceState state) {
    final l10n = AppLocalizations.of(context);
    switch (state) {
      case SharedPlaceLoading():
        // Zamyka arkusze i dialogi nad mapą, ale nie samą mapę (pod nią jest start).
        final mapRoute = ModalRoute.of(context);
        Navigator.of(context).popUntil((route) => route == mapRoute);
        if (_searchOpen) _closeSearch();
        _clearResult();
      case SharedPlaceReady(:final place):
        _showResult(place);
      case SharedPlaceNotAPlace():
        _showError(l10n.shareNotAPlace);
      case SharedPlaceFailed():
        _showError(l10n.shareError);
      case SharedPlaceNeedsSearch(:final name):
        _searchFor(name);
        _showError(l10n.shareNeedsSearch);
      case SharedPlaceIdle():
    }
  }

  /// Wykonuje zapis do bazy; przy błędzie pokazuje snackbar.
  Future<T?> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('Zapis pinezki nie powiódł się: $e');
      if (mounted) _showError(AppLocalizations.of(context).pinsSaveError);
      return null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.accessToken.isEmpty) {
      return const MissingTokenView();
    }

    ref.listen(pinsProvider, (_, next) {
      switch (next) {
        case AsyncData(:final value):
          _scheduleSync(value);
          _placeCamera();
        case AsyncError(:final error):
          debugPrint('Odczyt pinezek nie powiódł się: $error');
          _showError(AppLocalizations.of(context).pinsLoadError);
        default:
      }
    });

    final l10n = AppLocalizations.of(context);
    final result = _result;
    final sharing =
        ref.watch(sharedPlaceControllerProvider) is SharedPlaceLoading;

    return PopScope(
      // Wstecz najpierw zamyka wyszukiwanie, poprawianie i kartę wyniku, dopiero potem aplikację.
      canPop: !_searchOpen && !_stylesOpen && result == null && !sharing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_stylesOpen) {
          setState(() => _stylesOpen = false);
        } else if (_searchOpen) {
          _closeSearch();
        } else if (_adjusting) {
          _cancelAdjust();
        } else if (sharing) {
          ref.read(sharedPlaceControllerProvider.notifier).cancel();
        } else {
          _clearResult();
        }
      },
      child: Scaffold(
        // Klawiatura nie zmienia rozmiaru mapy; lista podpowiedzi sama się do niej dopasowuje.
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            MapWidget(
              styleUri: mapStyleUri,
              // Domyślny SurfaceView (HC) nie bierze udziału w animacji trasy
              // i pokazuje pustą klatkę – mapa „wskakiwała” i migała (v11).
              // TLHC + TextureView składa mapę jak zwykły widżet Fluttera.
              textureView: true,
              // ignore: experimental_member_use
              androidHostingMode: AndroidPlatformViewHostingMode.TLHC_HC,
              viewport: _polandViewport,
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: (_) => _onStyleLoaded(),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder(
                  valueListenable: _styleReady,
                  builder: (context, ready, _) => AnimatedOpacity(
                    opacity: ready ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: const ColoredBox(color: mapBackgroundColor),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ValueListenableBuilder(
                    valueListenable: _drops,
                    builder: (context, drops, _) => Stack(
                      children: [
                        for (final drop in drops)
                          PinDrop(
                            key: ValueKey(drop.id),
                            image: _dropImages[drop.category]!,
                            anchor: drop.anchor,
                            size:
                                _pngSize(_pinImages[(drop.category, false)]!) /
                                pinImageScale,
                            onImpact: ref.read(hapticsProvider).tap,
                            onLanded: () => _landPin(drop.id),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_searchOpen)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(_toolsPadding),
                  child: _MapModeChip(folderId: widget.folderId),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(_toolsPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        // Pole wysuwa się z lupy w lewo.
                        transitionBuilder: (child, animation) => SizeTransition(
                          sizeFactor: animation,
                          axis: Axis.horizontal,
                          axisAlignment: 1,
                          child: child,
                        ),
                        child: _searchOpen
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: PlaceSearchField(
                                  controller: _searchText,
                                  focusNode: _searchFocus,
                                  state: ref.watch(
                                    placeSearchControllerProvider,
                                  ),
                                  onChanged: _onSearchChanged,
                                  onSelected: _onSuggestionSelected,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    MapTools(
                      children: [
                        MapToolButton(
                          icon: _searchOpen ? Icons.close : Icons.search,
                          tooltip: _searchOpen
                              ? l10n.searchClose
                              : l10n.searchOpen,
                          onPressed: _toggleSearch,
                        ),
                        MapToolButton(
                          icon: _stylesOpen
                              ? Icons.close
                              : Icons.layers_outlined,
                          tooltip: _stylesOpen
                              ? l10n.mapStylesClose
                              : l10n.mapStylesOpen,
                          onPressed: _toggleStyles,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_stylesOpen)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    // Obok przycisku stylów: pod lupą, na lewo od kolumny narzędzi.
                    padding: const EdgeInsets.only(
                      top: _toolsPadding + _toolSize + 12,
                      right: _toolsPadding + _toolSize + 12,
                    ),
                    child: MapStylePicker(
                      selected: _style,
                      onSelected: _selectStyle,
                    ),
                  ),
                ),
              ),
            if (_adjusting) const PlaceAdjustCrosshair(),
            if (sharing || result != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    // Od dołu zostaje miejsce na logo i atrybucję Mapbox, które muszą być widoczne.
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: sharing
                        ? SearchResultCard.loading(
                            onClose: ref
                                .read(sharedPlaceControllerProvider.notifier)
                                .cancel,
                          )
                        : _adjusting
                        ? PlaceAdjustCard(
                            onDone: _finishAdjust,
                            onCancel: _cancelAdjust,
                          )
                        : SearchResultCard(
                            result: result!,
                            onAddPin: () => _addResultPin(result),
                            onAdjust: _startAdjust,
                            onSearch: result.approximate && result.name != null
                                ? () => _searchFor(result.name!)
                                : null,
                            onClose: _clearResult,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lewy górny róg mapy: powrót do listy folderów i nazwa bieżącego folderu.
class _MapModeChip extends ConsumerWidget {
  const _MapModeChip({required this.folderId});

  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final folder = folderId == null
        ? null
        : ref
              .watch(foldersProvider)
              .value
              ?.where((f) => f.id == folderId)
              .firstOrNull;
    return ConstrainedBox(
      // Zostawia miejsce na kolumnę narzędzi po prawej.
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width - 2 * _toolsPadding - 72,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 3,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: Semantics(
            button: true,
            label: l10n.mapBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 8),
                  if (folder != null)
                    FolderBadge(
                      icon: folder.icon,
                      color: folder.color,
                      size: 28,
                    )
                  else
                    Icon(Icons.map_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      folder?.name ?? l10n.mapAllPins,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MissingTokenView extends StatelessWidget {
  const MissingTokenView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                l10n.missingTokenTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.missingTokenMessage, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
