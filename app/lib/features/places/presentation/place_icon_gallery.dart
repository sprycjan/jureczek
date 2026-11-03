import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../map/presentation/map_style.dart';
import '../domain/place_category.dart';
import '../domain/place_type.dart';
import 'place_icons.dart';
import 'place_labels.dart';

/// Ekran deweloperski (v15): cała biblioteka ikon miejsc – każda kategoria,
/// każdy typ w trzech wariantach – i podgląd pinezek na prawdziwej mapie.
/// Uruchamiany osobnym punktem wejścia `lib/dev/place_icons_main.dart`.
class PlaceIconGallery extends StatelessWidget {
  const PlaceIconGallery({super.key, this.showMap = true});

  /// Testy wyłączają kartę mapy (Mapbox to widok platformowy).
  final bool showMap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: showMap ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.placeIconsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.placeIconsLibraryTab),
              if (showMap) Tab(text: l10n.placeIconsMapTab),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [const _Library(), if (showMap) const _PinMapPreview()],
        ),
      ),
    );
  }
}

class _Library extends StatefulWidget {
  const _Library();

  @override
  State<_Library> createState() => _LibraryState();
}

class _LibraryState extends State<_Library> {
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final background = _dark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF4F1EA);
    final foreground = _dark ? Colors.white : const Color(0xFF1B1B1B);
    final muted = foreground.withValues(alpha: 0.6);
    return ColoredBox(
      color: background,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.placeIconsSummary(
                        PlaceType.values.length,
                        PlaceCategory.values.length,
                      ),
                      style: TextStyle(color: muted),
                    ),
                  ),
                  Text(
                    l10n.placeIconsDarkBackground,
                    style: TextStyle(color: foreground),
                  ),
                  Switch(
                    value: _dark,
                    onChanged: (v) => setState(() => _dark = v),
                  ),
                ],
              ),
            ),
          ),
          for (final category in PlaceCategory.values) ...[
            SliverToBoxAdapter(
              child: _CategoryHeader(
                category,
                foreground: foreground,
                muted: muted,
              ),
            ),
            SliverList.builder(
              itemCount: PlaceType.of(category).length,
              itemBuilder: (context, i) => _TypeRow(
                PlaceType.of(category)[i],
                dark: _dark,
                foreground: foreground,
                muted: muted,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader(
    this.category, {
    required this.foreground,
    required this.muted,
  });

  final PlaceCategory category;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: category.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label(l10n),
                  style: TextStyle(
                    color: foreground,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${_hex(category.primary)} · ${_hex(category.lightContainer)} · '
                  '${_hex(category.darkContainer)} · ${PlaceType.of(category).length}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          for (final color in [
            category.primary,
            category.lightContainer,
            category.darkContainer,
          ])
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: muted, width: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow(
    this.type, {
    required this.dark,
    required this.foreground,
    required this.muted,
  });

  final PlaceType type;
  final bool dark;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label(l10n),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    type.key,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 48, child: Center(child: PlacePin(type))),
          SizedBox(
            width: 54,
            child: Center(child: PlacePin(type, selected: true)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            height: 44,
            child: Center(
              // Na ciemnym tle kolor kategorii bywa za ciemny (#455A64) – stąd jaśniejszy kontener.
              child: PlaceIcon(
                type,
                color: dark ? type.category.darkContainer : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 44,
            child: Center(child: PlaceIconBadge(type, dark: dark)),
          ),
        ],
      ),
    );
  }
}

/// Mapa z pinezkami różnych typów w Krakowie i Tatrach; tap zaznacza pinezkę.
class _PinMapPreview extends StatefulWidget {
  const _PinMapPreview();

  @override
  State<_PinMapPreview> createState() => _PinMapPreviewState();
}

const _samples = <(PlaceType, double, double)>[
  (PlaceType.castle, 19.9354, 50.0541),
  (PlaceType.church, 19.9393, 50.0617),
  (PlaceType.museum, 19.9330, 50.0640),
  (PlaceType.cafe, 19.9449, 50.0590),
  (PlaceType.restaurant, 19.9372, 50.0580),
  (PlaceType.pub, 19.9465, 50.0518),
  (PlaceType.iceCreamShop, 19.9410, 50.0560),
  (PlaceType.railwayStation, 19.9470, 50.0675),
  (PlaceType.parkingLot, 19.9265, 50.0600),
  (PlaceType.pharmacy, 19.9420, 50.0650),
  (PlaceType.atm, 19.9350, 50.0625),
  (PlaceType.theatre, 19.9405, 50.0645),
  (PlaceType.hotel, 19.9500, 50.0600),
  (PlaceType.river, 19.9300, 50.0500),
  (PlaceType.botanicalGarden, 19.9575, 50.0630),
  (PlaceType.airport, 19.7848, 50.0777),
  (PlaceType.zoo, 19.8510, 50.0540),
  (PlaceType.mountainPeak, 19.9817, 49.2321),
  (PlaceType.viewpoint, 19.9620, 49.2500),
  (PlaceType.lake, 20.0710, 49.2010),
  (PlaceType.hikingTrail, 20.0000, 49.2600),
  (PlaceType.cableCar, 19.9820, 49.2420),
  (PlaceType.campingGround, 19.9400, 49.2900),
  (PlaceType.skiSlope, 19.9300, 49.2780),
  (PlaceType.waterfall, 19.9700, 49.2700),
  (PlaceType.guesthouse, 19.9550, 49.3000),
];

class _PinMapPreviewState extends State<_PinMapPreview> {
  MapboxMap? _map;
  PointAnnotationManager? _manager;
  Cancelable? _tapEvents;
  final _typeById = <String, PlaceType>{};
  PointAnnotation? _selected;
  double _iconSize = 1;

  static const _pixelRatio = 3.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _iconSize = MediaQuery.devicePixelRatioOf(context) / _pixelRatio;
  }

  @override
  void dispose() {
    _tapEvents?.cancel();
    super.dispose();
  }

  Future<void> _onStyleLoaded(MapboxMap map) async {
    final manager = await map.annotations.createPointAnnotationManager();
    _manager = manager;
    for (final (type, lng, lat) in _samples) {
      final annotation = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: await renderPlacePinPng(type, pixelRatio: _pixelRatio),
          iconImage: '${type.key}_default',
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: _iconSize,
        ),
      );
      _typeById[annotation.id] = type;
    }
    _tapEvents = manager.tapEvents(onTap: (a) => unawaited(_select(a)));
  }

  Future<void> _select(PointAnnotation annotation) async {
    final manager = _manager;
    if (manager == null) return;
    final previous = _selected;
    if (previous != null) {
      await _setLook(manager, previous, selected: false);
    }
    if (previous?.id == annotation.id) {
      _selected = null;
      return;
    }
    _selected = annotation;
    await _setLook(manager, annotation, selected: true);
  }

  Future<void> _setLook(
    PointAnnotationManager manager,
    PointAnnotation annotation, {
    required bool selected,
  }) async {
    final type = _typeById[annotation.id]!;
    annotation
      ..image = await renderPlacePinPng(
        type,
        selected: selected,
        pixelRatio: _pixelRatio,
      )
      ..iconImage = '${type.key}_${selected ? 'selected' : 'default'}'
      ..symbolSortKey = selected ? 1 : 0;
    await manager.update(annotation);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        MapWidget(
          styleUri: mapStyleUri,
          textureView: true,
          viewport: CameraViewportState(
            center: Point(coordinates: Position(19.94, 50.058)),
            zoom: 14.2,
          ),
          onMapCreated: (m) => _map = m,
          onStyleLoadedListener: (_) => unawaited(_onStyleLoaded(_map!)),
        ),
        Positioned(
          left: 16,
          right: 16,
          // Pod skalą Mapbox w lewym górnym rogu.
          top: 44,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  l10n.placeIconsMapHint,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
