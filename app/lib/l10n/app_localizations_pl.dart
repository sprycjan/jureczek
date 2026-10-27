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
}
