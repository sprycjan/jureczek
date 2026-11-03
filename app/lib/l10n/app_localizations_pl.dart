// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Jureczek';

  @override
  String get missingTokenTitle => 'Brak tokenu Mapbox';

  @override
  String get missingTokenMessage =>
      'Uruchom aplikację z tokenem:\nflutter run --dart-define-from-file=env/dev.json';

  @override
  String get pinSheetTitle => 'Miejsce';

  @override
  String pinAddedOn(String date) {
    return 'Dodano $date';
  }

  @override
  String get pinUnnamed => 'Bez nazwy';

  @override
  String get pinNameLabel => 'Nazwa';

  @override
  String get pinNoteLabel => 'Notatka';

  @override
  String get pinEdit => 'Edytuj';

  @override
  String get pinSave => 'Zapisz';

  @override
  String get pinCancel => 'Anuluj';

  @override
  String get pinDelete => 'Usuń';

  @override
  String get pinDeleted => 'Usunięto pinezkę';

  @override
  String get undo => 'Cofnij';

  @override
  String get pinsLoadError => 'Nie udało się wczytać pinezek';

  @override
  String get pinsSaveError => 'Nie udało się zapisać pinezki';

  @override
  String get pinAdded => 'Dodano pinezkę';

  @override
  String get searchOpen => 'Szukaj miejsca';

  @override
  String get searchClose => 'Zamknij wyszukiwanie';

  @override
  String get searchHint => 'Szukaj miejsca';

  @override
  String get pinColorLabel => 'Kolor';

  @override
  String get pinColorDefault => 'Kolor typu';

  @override
  String get pinColorReset => 'Domyślny';

  @override
  String get pinColorRed => 'Czerwony';

  @override
  String get pinColorRaspberry => 'Malinowy';

  @override
  String get pinColorRose => 'Różowy';

  @override
  String get pinColorCoral => 'Koralowy';

  @override
  String get pinColorOrange => 'Pomarańczowy';

  @override
  String get pinColorAmber => 'Bursztynowy';

  @override
  String get pinColorGold => 'Złoty';

  @override
  String get pinColorOlive => 'Oliwkowy';

  @override
  String get pinColorLime => 'Limonkowy';

  @override
  String get pinColorGreen => 'Zielony';

  @override
  String get pinColorMint => 'Miętowy';

  @override
  String get pinColorTeal => 'Morski';

  @override
  String get pinColorCyan => 'Turkusowy';

  @override
  String get pinColorSky => 'Błękitny';

  @override
  String get pinColorBlue => 'Niebieski';

  @override
  String get pinColorNavy => 'Granatowy';

  @override
  String get pinColorViolet => 'Fioletowy';

  @override
  String get pinColorPurple => 'Purpurowy';

  @override
  String get pinColorOrchid => 'Liliowy';

  @override
  String get pinColorBrown => 'Brązowy';

  @override
  String get pinColorSand => 'Piaskowy';

  @override
  String get pinColorSlate => 'Łupkowy';

  @override
  String get pinColorGraphite => 'Grafitowy';

  @override
  String get pinColorBlack => 'Czarny';

  @override
  String get mapZoomIn => 'Przybliż';

  @override
  String get mapZoomOut => 'Oddal';

  @override
  String get mapMyLocation => 'Moja lokalizacja';

  @override
  String get locationServiceOff => 'Lokalizacja w telefonie jest wyłączona';

  @override
  String get locationTurnOn => 'Włącz';

  @override
  String get locationDenied =>
      'Bez zgody na lokalizację nie pokażę, gdzie jesteś';

  @override
  String get locationDeniedForever =>
      'Dostęp do lokalizacji jest zablokowany – włącz go w ustawieniach aplikacji';

  @override
  String get locationOpenSettings => 'Ustawienia';

  @override
  String get locationUnavailable => 'Nie udało się ustalić położenia';

  @override
  String get mapStylesOpen => 'Style mapy';

  @override
  String get mapStylesClose => 'Zamknij style mapy';

  @override
  String get mapStyleVanventure => 'Domyślny';

  @override
  String get mapStyleOutdoors => 'Teren';

  @override
  String get mapStyleFaded3d => '3D';

  @override
  String get searchError => 'Nie udało się wyszukać – sprawdź połączenie';

  @override
  String get searchNoResults => 'Brak wyników';

  @override
  String get searchAddPin => 'Dodaj pinezkę';

  @override
  String get searchResultClose => 'Zamknij';

  @override
  String get pinAddressLabel => 'Adres';

  @override
  String get pinOpenInGoogleMaps => 'Otwórz w Google Maps';

  @override
  String get pinNewTitle => 'Nowa pinezka';

  @override
  String get pinDuplicate => 'Ta pinezka już jest';

  @override
  String get shareLoading => 'Odczytuję miejsce…';

  @override
  String get shareApproximate => 'Położenie przybliżone – sprawdź je na mapie';

  @override
  String get shareNotAPlace => 'To nie wygląda na miejsce';

  @override
  String get shareError =>
      'Nie udało się odczytać miejsca – sprawdź połączenie';

  @override
  String get shareNeedsSearch =>
      'Nie udało się ustalić położenia – wybierz miejsce z listy';

  @override
  String get shareSearchByName => 'Szukaj w wyszukiwarce';

  @override
  String get placeAdjust => 'Popraw położenie';

  @override
  String get placeAdjustHint => 'Przesuń mapę, żeby pinezka wskazywała miejsce';

  @override
  String get placeAdjustDone => 'Gotowe';

  @override
  String get pinCategoryLabel => 'Typ pinezki';

  @override
  String get pinCategoryStandard => 'Pinezka';

  @override
  String get pinCategoryGastronomy => 'Gastronomia';

  @override
  String get pinCategoryPlaces => 'Miejsca i zabytki';

  @override
  String get pinCategoryNature => 'Natura i widoki';

  @override
  String get pinCategoryActivities => 'Aktywności i szlaki';

  @override
  String get pinCategoryTravel => 'Podróż i baza vana';

  @override
  String get pinCategoryEntertainment => 'Rozrywka i kultura';

  @override
  String get pinCategoryPractical => 'Punkty praktyczne';

  @override
  String get folderLabel => 'Folder';

  @override
  String get folderNew => 'Nowy folder';

  @override
  String get folderEditTitle => 'Edytuj folder';

  @override
  String get folderQuickCreateTitle => 'Nowy folder';

  @override
  String get folderNameLabel => 'Nazwa folderu lub trasy';

  @override
  String get folderNameHint => 'np. Dzika Andaluzja kamperem, Bałkany 2025';

  @override
  String get folderNameRequired => 'Podaj nazwę folderu';

  @override
  String get folderDescriptionLabel => 'Krótki opis lub notatki załogi';

  @override
  String get folderDescriptionHint =>
      'Klify, bezpieczne dzikie parcele, dostęp do czystej wody i prądu…';

  @override
  String get folderIconLabel => 'Ikona kategorii';

  @override
  String get folderIconHint => 'Wybierz 1';

  @override
  String get folderColorLabel => 'Kolor akcentowy wyprawy';

  @override
  String get folderPreviewName => 'Nowa lista';

  @override
  String get folderCreate => 'Utwórz';

  @override
  String get folderCreateAndAddPins => 'Utwórz folder i dodaj pierwsze pinezki';

  @override
  String get folderSaveError => 'Nie udało się zapisać folderu';

  @override
  String get folderClose => 'Zamknij';

  @override
  String folderPinCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miejsca',
      many: '$count miejsc',
      few: '$count miejsca',
      one: '1 miejsce',
      zero: 'Brak miejsc',
    );
    return '$_temp0';
  }

  @override
  String get folderMenu => 'Więcej';

  @override
  String get folderEdit => 'Edytuj';

  @override
  String get folderIconCamper => 'Kamper';

  @override
  String get folderIconMountains => 'Góry';

  @override
  String get folderIconBeach => 'Wybrzeże';

  @override
  String get folderIconCamping => 'Biwak';

  @override
  String get folderIconHiking => 'Szlak';

  @override
  String get folderIconCafe => 'Kawiarnia';

  @override
  String get folderIconCompass => 'Kompas';

  @override
  String get folderIconForest => 'Las';

  @override
  String get folderIconCity => 'Miasto';

  @override
  String get folderIconCastle => 'Zamek';

  @override
  String get folderIconFood => 'Jedzenie';

  @override
  String get folderIconWine => 'Wino';

  @override
  String get folderIconBike => 'Rower';

  @override
  String get folderIconKayak => 'Kajak';

  @override
  String get folderIconSki => 'Narty';

  @override
  String get folderColorEmerald => 'Szmaragd leśny';

  @override
  String get folderColorAmber => 'Bursztyn latarni';

  @override
  String get folderColorGlacier => 'Błękit lodowcowy';

  @override
  String get folderColorHeather => 'Zmierzch wrzosowy';

  @override
  String get folderColorRaspberry => 'Malina';

  @override
  String get folderColorSapphire => 'Szafir';

  @override
  String get folderColorMeadow => 'Łąka';

  @override
  String get folderColorLagoon => 'Laguna';

  @override
  String get folderColorSlate => 'Łupek';

  @override
  String get homeGreeting => 'Cześć!';

  @override
  String get homeFoldersTitle => 'Moje listy podróży';

  @override
  String get homeAllPins => 'Mapa – wszystkie pinezki';

  @override
  String get homeEmptyTitle => 'Nie masz jeszcze żadnego folderu';

  @override
  String get homeEmptyMessage =>
      'Foldery zbierają pinezki jednej podróży albo o wspólnym mianowniku – np. „Portugalia 2026” czy „Ciekawe miejsca”.';

  @override
  String get homeEmptyAction => 'Utwórz pierwszy folder';

  @override
  String get mapAllPins => 'Wszystkie pinezki';

  @override
  String get mapBack => 'Wróć do listy folderów';

  @override
  String get placeCategoryGastronomy => 'Gastronomia';

  @override
  String get placeCategoryPlaces => 'Miejsca i atrakcje';

  @override
  String get placeCategoryNature => 'Natura i widoki';

  @override
  String get placeCategoryActivities => 'Aktywności i szlaki';

  @override
  String get placeCategoryTravel => 'Podróż i infrastruktura';

  @override
  String get placeCategoryEntertainment => 'Rozrywka i kultura';

  @override
  String get placeCategoryPractical => 'Punkty praktyczne';

  @override
  String get placeTypeRestaurant => 'Restauracja';

  @override
  String get placeTypeCafe => 'Kawiarnia';

  @override
  String get placeTypeBar => 'Bar';

  @override
  String get placeTypePub => 'Pub';

  @override
  String get placeTypeBakery => 'Piekarnia';

  @override
  String get placeTypePastryShop => 'Cukiernia';

  @override
  String get placeTypeIceCreamShop => 'Lodziarnia';

  @override
  String get placeTypeFoodTruck => 'Food truck';

  @override
  String get placeTypeWinery => 'Winnica';

  @override
  String get placeTypeBrewery => 'Browar';

  @override
  String get placeTypeCity => 'Duże miasto';

  @override
  String get placeTypeSmallTown => 'Miasteczko';

  @override
  String get placeTypeVillage => 'Wieś';

  @override
  String get placeTypeHistoricalMonument => 'Zabytek';

  @override
  String get placeTypeMuseum => 'Muzeum';

  @override
  String get placeTypeCastle => 'Zamek';

  @override
  String get placeTypePalace => 'Pałac';

  @override
  String get placeTypeChurch => 'Kościół';

  @override
  String get placeTypeMonastery => 'Klasztor';

  @override
  String get placeTypeRuins => 'Ruiny';

  @override
  String get placeTypeMonumentStatue => 'Pomnik';

  @override
  String get placeTypeHistoricalSite => 'Miejsce pamięci';

  @override
  String get placeTypeViewpoint => 'Punkt widokowy';

  @override
  String get placeTypeMountainPeak => 'Szczyt';

  @override
  String get placeTypeWaterfall => 'Wodospad';

  @override
  String get placeTypeLake => 'Jezioro';

  @override
  String get placeTypeBeach => 'Plaża';

  @override
  String get placeTypeIsland => 'Wyspa';

  @override
  String get placeTypeNationalPark => 'Park narodowy';

  @override
  String get placeTypeNatureReserve => 'Rezerwat przyrody';

  @override
  String get placeTypeCave => 'Jaskinia';

  @override
  String get placeTypeForest => 'Las';

  @override
  String get placeTypeGorgeCanyon => 'Wąwóz lub kanion';

  @override
  String get placeTypeSpring => 'Źródło';

  @override
  String get placeTypeRiver => 'Rzeka';

  @override
  String get placeTypeHikingTrail => 'Szlak pieszy';

  @override
  String get placeTypeCyclingRoute => 'Trasa rowerowa';

  @override
  String get placeTypeMotorcycleRoute => 'Trasa motocyklowa';

  @override
  String get placeTypeScenicDrive => 'Malownicza trasa';

  @override
  String get placeTypeCableCar => 'Kolejka linowa';

  @override
  String get placeTypeSkiSlope => 'Stok narciarski';

  @override
  String get placeTypeSwimmingSpot => 'Kąpielisko';

  @override
  String get placeTypeDivingSpot => 'Nurkowanie';

  @override
  String get placeTypeCampsite => 'Pole biwakowe';

  @override
  String get placeTypePicnicArea => 'Miejsce piknikowe';

  @override
  String get placeTypeHotel => 'Hotel';

  @override
  String get placeTypeGuesthouse => 'Pensjonat';

  @override
  String get placeTypeCampingGround => 'Kemping';

  @override
  String get placeTypeParkingLot => 'Parking';

  @override
  String get placeTypeGasStation => 'Stacja paliw';

  @override
  String get placeTypeEvCharging => 'Ładowarka EV';

  @override
  String get placeTypeAirport => 'Lotnisko';

  @override
  String get placeTypeRailwayStation => 'Dworzec kolejowy';

  @override
  String get placeTypeHarbour => 'Port';

  @override
  String get placeTypeMarina => 'Marina';

  @override
  String get placeTypeFerryTerminal => 'Terminal promowy';

  @override
  String get placeTypeTheatre => 'Teatr';

  @override
  String get placeTypeCinema => 'Kino';

  @override
  String get placeTypeArtGallery => 'Galeria sztuki';

  @override
  String get placeTypeConcertVenue => 'Sala koncertowa';

  @override
  String get placeTypeFestivalEvent => 'Festiwal lub wydarzenie';

  @override
  String get placeTypeAmusementPark => 'Park rozrywki';

  @override
  String get placeTypeWaterPark => 'Park wodny';

  @override
  String get placeTypeZoo => 'Zoo';

  @override
  String get placeTypeAquarium => 'Akwarium';

  @override
  String get placeTypeBotanicalGarden => 'Ogród botaniczny';

  @override
  String get placeTypeGroceryStore => 'Sklep spożywczy';

  @override
  String get placeTypePharmacy => 'Apteka';

  @override
  String get placeTypeAtm => 'Bankomat';

  @override
  String get placeTypePublicToilet => 'Toaleta';

  @override
  String get placeTypeTouristInfo => 'Informacja turystyczna';

  @override
  String get placeTypeBicycleRepair => 'Serwis rowerowy';

  @override
  String get placeTypeCarRepair => 'Warsztat samochodowy';

  @override
  String get placeTypeLaundromat => 'Pralnia samoobsługowa';

  @override
  String get placeIconsTitle => 'Ikony miejsc';

  @override
  String get placeIconsLibraryTab => 'Biblioteka';

  @override
  String get placeIconsMapTab => 'Mapa';

  @override
  String get placeIconsDarkBackground => 'Ciemne tło';

  @override
  String placeIconsSummary(int types, int categories) {
    return '$types typów · $categories kategorii';
  }

  @override
  String get placeIconsMapHint => 'Stuknij pinezkę, żeby ją zaznaczyć';

  @override
  String get placeTypeOther => 'Inne';
}
