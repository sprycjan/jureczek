import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../share/application/shared_place_controller.dart';
import '../application/place_search_controller.dart';
import '../application/pins_providers.dart';
import '../domain/duplicate_pin.dart';
import '../domain/place_pin.dart';
import '../domain/place_suggestion.dart';
import '../domain/poi_place.dart';
import 'map_tools.dart';
import 'new_pin_sheet.dart';
import 'pin_details_sheet.dart';
import 'pin_form_fields.dart';
import 'place_adjust_overlay.dart';
import 'place_search_field.dart';
import 'search_result_card.dart';

/// Środek Polski i zoom obejmujący cały kraj.
final _polandViewport = CameraViewportState(
  center: Point(coordinates: Position(19.4, 52.0)),
  zoom: 5.3,
);

const _pinAsset = 'assets/markers/pin.png';

/// Zoom po przelocie do wyniku wyszukiwania lub udostępnionego miejsca.
const _resultZoom = 15.0;

/// Odstęp narzędzi od krawędzi ekranu (pod paskiem statusu).
const _toolsPadding = 16.0;

/// Rozmiar okrągłego przycisku-narzędzia (domyślny [IconButton]).
const _toolSize = 48.0;

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.accessToken});

  final String accessToken;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _map;
  PointAnnotationManager? _pinManager;
  Uint8List? _pinImage;
  Cancelable? _tapEvents;

  /// Pinezki narysowane na mapie i odwrotne mapowanie dla tapnięć.
  final _annotationsByPinId = <String, PointAnnotation>{};
  final _pinIdByAnnotationId = <String, String>{};

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
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _tapEvents?.cancel();
    _searchText.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    await _placeOrnaments(map);
    final bytes = await rootBundle.load(_pinAsset);
    _pinImage = bytes.buffer.asUint8List();
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

    // POI ze stylu Standard: tap pokazuje kartę jak wynik wyszukiwania,
    // long-tap od razu stawia pinezkę z nazwą w punkcie POI, nie pod palcem.
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
        if (place == null) return;
        _run(
          () => ref
              .read(pinsControllerProvider)
              .add(lat: place.lat, lng: place.lng, name: place.name),
        );
      }),
    );

    map.addInteraction(
      LongTapInteraction.onMap((context) {
        final position = context.point.coordinates;
        _run(
          () => ref
              .read(pinsControllerProvider)
              .add(lat: position.lat.toDouble(), lng: position.lng.toDouble()),
        );
      }),
    );

    // Tworzony po pinezkach, więc znacznik wyniku leży nad nimi.
    _resultManager = await map.annotations.createCircleAnnotationManager();

    // Tap w mapę chowa podpowiedzi i klawiaturę; tekst w polu zostaje.
    map.addInteraction(
      TapInteraction.onMap(
        (_) => _searchFocus.unfocus(),
        stopPropagation: false,
      ),
    );

    _scheduleSync(ref.read(pinsProvider).value ?? const []);

    final pending = _pendingResult;
    _pendingResult = null;
    if (pending != null) await _showResult(pending);
  }

  /// Mapa leży pod paskiem statusu, więc kompas schodzi pod lupę,
  /// a skala na dół – po prawej, bo lewy dół zajmuje logo i atrybucja Mapbox.
  Future<void> _placeOrnaments(MapboxMap map) async {
    final insets = MediaQuery.paddingOf(context);
    await map.compass.updateSettings(
      CompassSettings(
        position: OrnamentPosition.TOP_RIGHT,
        marginTop: insets.top + _toolsPadding + _toolSize + 12,
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

  void _scheduleSync(List<PlacePin> pins) {
    _pins = pins;
    _sync = _sync.then((_) => _syncPins()).catchError((Object e) {
      debugPrint('Synchronizacja pinezek nie powiodła się: $e');
    });
  }

  /// Doprowadza pinezki na mapie do stanu z bazy: usuwa zbędne, dorysowuje brakujące.
  Future<void> _syncPins() async {
    final manager = _pinManager;
    final image = _pinImage;
    if (manager == null || image == null) return;

    final pins = _pins;
    final wantedIds = {for (final pin in pins) pin.id};

    final stale = _annotationsByPinId.keys
        .where((id) => !wantedIds.contains(id))
        .toList();
    for (final id in stale) {
      final annotation = _annotationsByPinId.remove(id)!;
      _pinIdByAnnotationId.remove(annotation.id);
      await manager.delete(annotation);
    }

    for (final pin in pins) {
      if (_annotationsByPinId.containsKey(pin.id)) continue;
      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(pin.lng, pin.lat)),
          image: image,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: 0.6,
        ),
      );
      _annotationsByPinId[pin.id] = annotation;
      _pinIdByAnnotationId[annotation.id] = pin.id;
    }
  }

  void _onPinTapped(PointAnnotation annotation) {
    final pinId = _pinIdByAnnotationId[annotation.id];
    final pin = _pins.where((p) => p.id == pinId).firstOrNull;
    if (pin == null || !mounted) return;

    _clearResult();
    _openPinSheet(pin);
  }

  /// [notice] trafia do arkusza, bo snackbar byłby pod nim niewidoczny.
  void _openPinSheet(PlacePin pin, {String? notice}) {
    showModalBottomSheet<void>(
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
      ),
    );
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
      setState(() => _searchOpen = true);
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
          circleColor: Colors.blue.toARGB32(),
          circleStrokeColor: Colors.white.toARGB32(),
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

  /// Formularz z danymi wyniku; pinezka powstaje dopiero po „Zapisz”.
  void _addResultPin(PlaceResult result) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => NewPinSheet(
        place: result,
        onSave: (details) async {
          try {
            await ref
                .read(pinsControllerProvider)
                .add(
                  lat: result.lat,
                  lng: result.lng,
                  name: details.name,
                  address: details.address,
                  note: details.note,
                  sourceUrl: result.sourceUrl,
                );
          } catch (e) {
            debugPrint('Zapis pinezki nie powiódł się: $e');
            return false;
          }
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          _clearResult();
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.pinAdded)));
          return true;
        },
      ),
    );
  }

  /// Nowe udostępnienie zastępuje wszystko, co było otwarte.
  void _onSharedPlace(SharedPlaceState state) {
    final l10n = AppLocalizations.of(context);
    switch (state) {
      case SharedPlaceLoading():
        Navigator.of(context).popUntil((route) => route.isFirst);
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
      return const _MissingTokenView();
    }

    ref.listen(pinsProvider, (_, next) {
      switch (next) {
        case AsyncData(:final value):
          _scheduleSync(value);
        case AsyncError(:final error):
          debugPrint('Odczyt pinezek nie powiódł się: $error');
          _showError(AppLocalizations.of(context).pinsLoadError);
        default:
      }
    });
    ref.listen(
      sharedPlaceControllerProvider,
      (_, next) => _onSharedPlace(next),
    );

    final l10n = AppLocalizations.of(context);
    final result = _result;
    final sharing =
        ref.watch(sharedPlaceControllerProvider) is SharedPlaceLoading;

    return PopScope(
      // Wstecz najpierw zamyka wyszukiwanie, poprawianie i kartę wyniku, dopiero potem aplikację.
      canPop: !_searchOpen && result == null && !sharing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searchOpen) {
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
              styleUri: MapboxStyles.STANDARD,
              viewport: _polandViewport,
              onMapCreated: _onMapCreated,
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
                      ],
                    ),
                  ],
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

class _MissingTokenView extends StatelessWidget {
  const _MissingTokenView();

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
