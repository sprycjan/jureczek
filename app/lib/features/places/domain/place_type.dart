import 'place_category.dart';

/// Typ miejsca (v15) – 74 typy w 7 kategoriach, każdy z własnym symbolem.
///
/// [key] to nazwa plików w `assets/place_icons/<kategoria>/`
/// (`<key>_icon.svg`, `<key>_default.svg`, `<key>_selected.svg`), generowanych
/// przez `tool/place_icons.py`. Kolejność = kolejność w generatorze i w galerii.
/// Gdy typ trafi do bazy, [key] staje się trwały – nie zmieniać istniejących wartości.
enum PlaceType {
  // Gastronomia
  restaurant(PlaceCategory.gastronomy, 'restaurant'),
  cafe(PlaceCategory.gastronomy, 'cafe'),
  bar(PlaceCategory.gastronomy, 'bar'),
  pub(PlaceCategory.gastronomy, 'pub'),
  bakery(PlaceCategory.gastronomy, 'bakery'),
  pastryShop(PlaceCategory.gastronomy, 'pastry_shop'),
  iceCreamShop(PlaceCategory.gastronomy, 'ice_cream_shop'),
  foodTruck(PlaceCategory.gastronomy, 'food_truck'),
  winery(PlaceCategory.gastronomy, 'winery'),
  brewery(PlaceCategory.gastronomy, 'brewery'),

  // Miejsca i atrakcje
  city(PlaceCategory.places, 'city'),
  smallTown(PlaceCategory.places, 'small_town'),
  village(PlaceCategory.places, 'village'),
  historicalMonument(PlaceCategory.places, 'historical_monument'),
  museum(PlaceCategory.places, 'museum'),
  castle(PlaceCategory.places, 'castle'),
  palace(PlaceCategory.places, 'palace'),
  church(PlaceCategory.places, 'church'),
  monastery(PlaceCategory.places, 'monastery'),
  ruins(PlaceCategory.places, 'ruins'),
  monumentStatue(PlaceCategory.places, 'monument_statue'),
  historicalSite(PlaceCategory.places, 'historical_site'),

  // Natura i widoki
  viewpoint(PlaceCategory.nature, 'viewpoint'),
  mountainPeak(PlaceCategory.nature, 'mountain_peak'),
  waterfall(PlaceCategory.nature, 'waterfall'),
  lake(PlaceCategory.nature, 'lake'),
  beach(PlaceCategory.nature, 'beach'),
  island(PlaceCategory.nature, 'island'),
  nationalPark(PlaceCategory.nature, 'national_park'),
  natureReserve(PlaceCategory.nature, 'nature_reserve'),
  cave(PlaceCategory.nature, 'cave'),
  forest(PlaceCategory.nature, 'forest'),
  gorgeCanyon(PlaceCategory.nature, 'gorge_canyon'),
  spring(PlaceCategory.nature, 'spring'),
  river(PlaceCategory.nature, 'river'),

  // Aktywności i szlaki
  hikingTrail(PlaceCategory.activities, 'hiking_trail'),
  cyclingRoute(PlaceCategory.activities, 'cycling_route'),
  motorcycleRoute(PlaceCategory.activities, 'motorcycle_route'),
  scenicDrive(PlaceCategory.activities, 'scenic_drive'),
  cableCar(PlaceCategory.activities, 'cable_car'),
  skiSlope(PlaceCategory.activities, 'ski_slope'),
  swimmingSpot(PlaceCategory.activities, 'swimming_spot'),
  divingSpot(PlaceCategory.activities, 'diving_spot'),
  campsite(PlaceCategory.activities, 'campsite'),
  picnicArea(PlaceCategory.activities, 'picnic_area'),

  // Podróż i infrastruktura
  hotel(PlaceCategory.travel, 'hotel'),
  guesthouse(PlaceCategory.travel, 'guesthouse'),
  campingGround(PlaceCategory.travel, 'camping_ground'),
  parkingLot(PlaceCategory.travel, 'parking_lot'),
  gasStation(PlaceCategory.travel, 'gas_station'),
  evCharging(PlaceCategory.travel, 'ev_charging'),
  airport(PlaceCategory.travel, 'airport'),
  railwayStation(PlaceCategory.travel, 'railway_station'),
  harbour(PlaceCategory.travel, 'harbour'),
  marina(PlaceCategory.travel, 'marina'),
  ferryTerminal(PlaceCategory.travel, 'ferry_terminal'),

  // Rozrywka i kultura
  theatre(PlaceCategory.entertainment, 'theatre'),
  cinema(PlaceCategory.entertainment, 'cinema'),
  artGallery(PlaceCategory.entertainment, 'art_gallery'),
  concertVenue(PlaceCategory.entertainment, 'concert_venue'),
  festivalEvent(PlaceCategory.entertainment, 'festival_event'),
  amusementPark(PlaceCategory.entertainment, 'amusement_park'),
  waterPark(PlaceCategory.entertainment, 'water_park'),
  zoo(PlaceCategory.entertainment, 'zoo'),
  aquarium(PlaceCategory.entertainment, 'aquarium'),
  botanicalGarden(PlaceCategory.entertainment, 'botanical_garden'),

  // Punkty praktyczne
  groceryStore(PlaceCategory.practical, 'grocery_store'),
  pharmacy(PlaceCategory.practical, 'pharmacy'),
  atm(PlaceCategory.practical, 'atm'),
  publicToilet(PlaceCategory.practical, 'public_toilet'),
  touristInfo(PlaceCategory.practical, 'tourist_info'),
  bicycleRepair(PlaceCategory.practical, 'bicycle_repair'),
  carRepair(PlaceCategory.practical, 'car_repair'),
  laundromat(PlaceCategory.practical, 'laundromat');

  const PlaceType(this.category, this.key);

  final PlaceCategory category;
  final String key;

  static const _dir = 'assets/place_icons';

  /// Samodzielna ikona 24×24 dp w kolorze kategorii.
  String get iconAsset => '$_dir/${category.key}/${key}_icon.svg';

  /// Pinezka (36×44 dp, zaznaczona 42×52 dp) z marginesem na cień – patrz `PlacePinGeometry`.
  String pinAsset({bool selected = false}) =>
      '$_dir/${category.key}/${key}_${selected ? 'selected' : 'default'}.svg';

  /// Typy danej kategorii w kolejności z generatora.
  static List<PlaceType> of(PlaceCategory category) => [
    for (final type in values)
      if (type.category == category) type,
  ];

  /// Nieznany klucz to `null` – wywołujący wybiera zapasowy wygląd.
  static PlaceType? fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return null;
  }
}
