import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pl')];

  /// No description provided for @appTitle.
  ///
  /// In pl, this message translates to:
  /// **'Jureczek'**
  String get appTitle;

  /// No description provided for @missingTokenTitle.
  ///
  /// In pl, this message translates to:
  /// **'Brak tokenu Mapbox'**
  String get missingTokenTitle;

  /// No description provided for @missingTokenMessage.
  ///
  /// In pl, this message translates to:
  /// **'Uruchom aplikację z tokenem:\nflutter run --dart-define-from-file=env/dev.json'**
  String get missingTokenMessage;

  /// No description provided for @pinSheetTitle.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce'**
  String get pinSheetTitle;

  /// No description provided for @pinAddedOn.
  ///
  /// In pl, this message translates to:
  /// **'Dodano {date}'**
  String pinAddedOn(String date);

  /// No description provided for @pinUnnamed.
  ///
  /// In pl, this message translates to:
  /// **'Bez nazwy'**
  String get pinUnnamed;

  /// No description provided for @pinNameLabel.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa'**
  String get pinNameLabel;

  /// No description provided for @pinNoteLabel.
  ///
  /// In pl, this message translates to:
  /// **'Notatka'**
  String get pinNoteLabel;

  /// No description provided for @pinEdit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get pinEdit;

  /// No description provided for @pinSave.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get pinSave;

  /// No description provided for @pinCancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get pinCancel;

  /// No description provided for @pinDelete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get pinDelete;

  /// No description provided for @pinDeleted.
  ///
  /// In pl, this message translates to:
  /// **'Usunięto pinezkę'**
  String get pinDeleted;

  /// No description provided for @undo.
  ///
  /// In pl, this message translates to:
  /// **'Cofnij'**
  String get undo;

  /// No description provided for @pinsLoadError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wczytać pinezek'**
  String get pinsLoadError;

  /// No description provided for @pinsSaveError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zapisać pinezki'**
  String get pinsSaveError;

  /// No description provided for @pinAdded.
  ///
  /// In pl, this message translates to:
  /// **'Dodano pinezkę'**
  String get pinAdded;

  /// No description provided for @searchOpen.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj miejsca'**
  String get searchOpen;

  /// No description provided for @searchClose.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij wyszukiwanie'**
  String get searchClose;

  /// No description provided for @searchHint.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj miejsca'**
  String get searchHint;

  /// No description provided for @pinColorLabel.
  ///
  /// In pl, this message translates to:
  /// **'Kolor'**
  String get pinColorLabel;

  /// No description provided for @pinColorDefault.
  ///
  /// In pl, this message translates to:
  /// **'Kolor typu'**
  String get pinColorDefault;

  /// No description provided for @pinColorReset.
  ///
  /// In pl, this message translates to:
  /// **'Domyślny'**
  String get pinColorReset;

  /// No description provided for @pinColorRed.
  ///
  /// In pl, this message translates to:
  /// **'Czerwony'**
  String get pinColorRed;

  /// No description provided for @pinColorRaspberry.
  ///
  /// In pl, this message translates to:
  /// **'Malinowy'**
  String get pinColorRaspberry;

  /// No description provided for @pinColorRose.
  ///
  /// In pl, this message translates to:
  /// **'Różowy'**
  String get pinColorRose;

  /// No description provided for @pinColorCoral.
  ///
  /// In pl, this message translates to:
  /// **'Koralowy'**
  String get pinColorCoral;

  /// No description provided for @pinColorOrange.
  ///
  /// In pl, this message translates to:
  /// **'Pomarańczowy'**
  String get pinColorOrange;

  /// No description provided for @pinColorAmber.
  ///
  /// In pl, this message translates to:
  /// **'Bursztynowy'**
  String get pinColorAmber;

  /// No description provided for @pinColorGold.
  ///
  /// In pl, this message translates to:
  /// **'Złoty'**
  String get pinColorGold;

  /// No description provided for @pinColorOlive.
  ///
  /// In pl, this message translates to:
  /// **'Oliwkowy'**
  String get pinColorOlive;

  /// No description provided for @pinColorLime.
  ///
  /// In pl, this message translates to:
  /// **'Limonkowy'**
  String get pinColorLime;

  /// No description provided for @pinColorGreen.
  ///
  /// In pl, this message translates to:
  /// **'Zielony'**
  String get pinColorGreen;

  /// No description provided for @pinColorMint.
  ///
  /// In pl, this message translates to:
  /// **'Miętowy'**
  String get pinColorMint;

  /// No description provided for @pinColorTeal.
  ///
  /// In pl, this message translates to:
  /// **'Morski'**
  String get pinColorTeal;

  /// No description provided for @pinColorCyan.
  ///
  /// In pl, this message translates to:
  /// **'Turkusowy'**
  String get pinColorCyan;

  /// No description provided for @pinColorSky.
  ///
  /// In pl, this message translates to:
  /// **'Błękitny'**
  String get pinColorSky;

  /// No description provided for @pinColorBlue.
  ///
  /// In pl, this message translates to:
  /// **'Niebieski'**
  String get pinColorBlue;

  /// No description provided for @pinColorNavy.
  ///
  /// In pl, this message translates to:
  /// **'Granatowy'**
  String get pinColorNavy;

  /// No description provided for @pinColorViolet.
  ///
  /// In pl, this message translates to:
  /// **'Fioletowy'**
  String get pinColorViolet;

  /// No description provided for @pinColorPurple.
  ///
  /// In pl, this message translates to:
  /// **'Purpurowy'**
  String get pinColorPurple;

  /// No description provided for @pinColorOrchid.
  ///
  /// In pl, this message translates to:
  /// **'Liliowy'**
  String get pinColorOrchid;

  /// No description provided for @pinColorBrown.
  ///
  /// In pl, this message translates to:
  /// **'Brązowy'**
  String get pinColorBrown;

  /// No description provided for @pinColorSand.
  ///
  /// In pl, this message translates to:
  /// **'Piaskowy'**
  String get pinColorSand;

  /// No description provided for @pinColorSlate.
  ///
  /// In pl, this message translates to:
  /// **'Łupkowy'**
  String get pinColorSlate;

  /// No description provided for @pinColorGraphite.
  ///
  /// In pl, this message translates to:
  /// **'Grafitowy'**
  String get pinColorGraphite;

  /// No description provided for @pinColorBlack.
  ///
  /// In pl, this message translates to:
  /// **'Czarny'**
  String get pinColorBlack;

  /// No description provided for @mapZoomIn.
  ///
  /// In pl, this message translates to:
  /// **'Przybliż'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In pl, this message translates to:
  /// **'Oddal'**
  String get mapZoomOut;

  /// No description provided for @mapMyLocation.
  ///
  /// In pl, this message translates to:
  /// **'Moja lokalizacja'**
  String get mapMyLocation;

  /// No description provided for @locationServiceOff.
  ///
  /// In pl, this message translates to:
  /// **'Lokalizacja w telefonie jest wyłączona'**
  String get locationServiceOff;

  /// No description provided for @locationTurnOn.
  ///
  /// In pl, this message translates to:
  /// **'Włącz'**
  String get locationTurnOn;

  /// No description provided for @locationDenied.
  ///
  /// In pl, this message translates to:
  /// **'Bez zgody na lokalizację nie pokażę, gdzie jesteś'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In pl, this message translates to:
  /// **'Dostęp do lokalizacji jest zablokowany – włącz go w ustawieniach aplikacji'**
  String get locationDeniedForever;

  /// No description provided for @locationOpenSettings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get locationOpenSettings;

  /// No description provided for @locationUnavailable.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się ustalić położenia'**
  String get locationUnavailable;

  /// No description provided for @mapStylesOpen.
  ///
  /// In pl, this message translates to:
  /// **'Style mapy'**
  String get mapStylesOpen;

  /// No description provided for @mapStylesClose.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij style mapy'**
  String get mapStylesClose;

  /// No description provided for @mapStyleVanventure.
  ///
  /// In pl, this message translates to:
  /// **'Domyślny'**
  String get mapStyleVanventure;

  /// No description provided for @mapStyleOutdoors.
  ///
  /// In pl, this message translates to:
  /// **'Teren'**
  String get mapStyleOutdoors;

  /// No description provided for @mapStyleFaded3d.
  ///
  /// In pl, this message translates to:
  /// **'3D'**
  String get mapStyleFaded3d;

  /// No description provided for @searchError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się wyszukać – sprawdź połączenie'**
  String get searchError;

  /// No description provided for @searchNoResults.
  ///
  /// In pl, this message translates to:
  /// **'Brak wyników'**
  String get searchNoResults;

  /// No description provided for @searchAddPin.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj pinezkę'**
  String get searchAddPin;

  /// No description provided for @searchResultClose.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get searchResultClose;

  /// No description provided for @pinAddressLabel.
  ///
  /// In pl, this message translates to:
  /// **'Adres'**
  String get pinAddressLabel;

  /// No description provided for @pinOpenInGoogleMaps.
  ///
  /// In pl, this message translates to:
  /// **'Otwórz w Google Maps'**
  String get pinOpenInGoogleMaps;

  /// No description provided for @pinNewTitle.
  ///
  /// In pl, this message translates to:
  /// **'Nowa pinezka'**
  String get pinNewTitle;

  /// No description provided for @pinDuplicate.
  ///
  /// In pl, this message translates to:
  /// **'Ta pinezka już jest'**
  String get pinDuplicate;

  /// No description provided for @shareLoading.
  ///
  /// In pl, this message translates to:
  /// **'Odczytuję miejsce…'**
  String get shareLoading;

  /// No description provided for @shareApproximate.
  ///
  /// In pl, this message translates to:
  /// **'Położenie przybliżone – sprawdź je na mapie'**
  String get shareApproximate;

  /// No description provided for @shareNotAPlace.
  ///
  /// In pl, this message translates to:
  /// **'To nie wygląda na miejsce'**
  String get shareNotAPlace;

  /// No description provided for @shareError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się odczytać miejsca – sprawdź połączenie'**
  String get shareError;

  /// No description provided for @shareNeedsSearch.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się ustalić położenia – wybierz miejsce z listy'**
  String get shareNeedsSearch;

  /// No description provided for @shareSearchByName.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj w wyszukiwarce'**
  String get shareSearchByName;

  /// No description provided for @placeAdjust.
  ///
  /// In pl, this message translates to:
  /// **'Popraw położenie'**
  String get placeAdjust;

  /// No description provided for @placeAdjustHint.
  ///
  /// In pl, this message translates to:
  /// **'Przesuń mapę, żeby pinezka wskazywała miejsce'**
  String get placeAdjustHint;

  /// No description provided for @placeAdjustDone.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe'**
  String get placeAdjustDone;

  /// No description provided for @pinCategoryLabel.
  ///
  /// In pl, this message translates to:
  /// **'Typ pinezki'**
  String get pinCategoryLabel;

  /// No description provided for @pinCategoryStandard.
  ///
  /// In pl, this message translates to:
  /// **'Pinezka'**
  String get pinCategoryStandard;

  /// No description provided for @pinCategoryGastronomy.
  ///
  /// In pl, this message translates to:
  /// **'Gastronomia'**
  String get pinCategoryGastronomy;

  /// No description provided for @pinCategoryPlaces.
  ///
  /// In pl, this message translates to:
  /// **'Miejsca i zabytki'**
  String get pinCategoryPlaces;

  /// No description provided for @pinCategoryNature.
  ///
  /// In pl, this message translates to:
  /// **'Natura i widoki'**
  String get pinCategoryNature;

  /// No description provided for @pinCategoryActivities.
  ///
  /// In pl, this message translates to:
  /// **'Aktywności i szlaki'**
  String get pinCategoryActivities;

  /// No description provided for @pinCategoryTravel.
  ///
  /// In pl, this message translates to:
  /// **'Podróż i baza vana'**
  String get pinCategoryTravel;

  /// No description provided for @pinCategoryEntertainment.
  ///
  /// In pl, this message translates to:
  /// **'Rozrywka i kultura'**
  String get pinCategoryEntertainment;

  /// No description provided for @pinCategoryPractical.
  ///
  /// In pl, this message translates to:
  /// **'Punkty praktyczne'**
  String get pinCategoryPractical;

  /// No description provided for @folderLabel.
  ///
  /// In pl, this message translates to:
  /// **'Folder'**
  String get folderLabel;

  /// No description provided for @folderNew.
  ///
  /// In pl, this message translates to:
  /// **'Nowy folder'**
  String get folderNew;

  /// No description provided for @folderEditTitle.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj folder'**
  String get folderEditTitle;

  /// No description provided for @folderQuickCreateTitle.
  ///
  /// In pl, this message translates to:
  /// **'Nowy folder'**
  String get folderQuickCreateTitle;

  /// No description provided for @folderNameLabel.
  ///
  /// In pl, this message translates to:
  /// **'Nazwa folderu lub trasy'**
  String get folderNameLabel;

  /// No description provided for @folderNameHint.
  ///
  /// In pl, this message translates to:
  /// **'np. Dzika Andaluzja kamperem, Bałkany 2025'**
  String get folderNameHint;

  /// No description provided for @folderNameRequired.
  ///
  /// In pl, this message translates to:
  /// **'Podaj nazwę folderu'**
  String get folderNameRequired;

  /// No description provided for @folderDescriptionLabel.
  ///
  /// In pl, this message translates to:
  /// **'Krótki opis lub notatki załogi'**
  String get folderDescriptionLabel;

  /// No description provided for @folderDescriptionHint.
  ///
  /// In pl, this message translates to:
  /// **'Klify, bezpieczne dzikie parcele, dostęp do czystej wody i prądu…'**
  String get folderDescriptionHint;

  /// No description provided for @folderIconLabel.
  ///
  /// In pl, this message translates to:
  /// **'Ikona kategorii'**
  String get folderIconLabel;

  /// No description provided for @folderIconHint.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz 1'**
  String get folderIconHint;

  /// No description provided for @folderColorLabel.
  ///
  /// In pl, this message translates to:
  /// **'Kolor akcentowy wyprawy'**
  String get folderColorLabel;

  /// No description provided for @folderPreviewName.
  ///
  /// In pl, this message translates to:
  /// **'Nowa lista'**
  String get folderPreviewName;

  /// No description provided for @folderCreate.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz'**
  String get folderCreate;

  /// No description provided for @folderCreateAndAddPins.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz folder i dodaj pierwsze pinezki'**
  String get folderCreateAndAddPins;

  /// No description provided for @folderSaveError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zapisać folderu'**
  String get folderSaveError;

  /// No description provided for @folderClose.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get folderClose;

  /// No description provided for @folderPinCount.
  ///
  /// In pl, this message translates to:
  /// **'{count, plural, =0{Brak miejsc} =1{1 miejsce} few{{count} miejsca} many{{count} miejsc} other{{count} miejsca}}'**
  String folderPinCount(int count);

  /// No description provided for @folderMenu.
  ///
  /// In pl, this message translates to:
  /// **'Więcej'**
  String get folderMenu;

  /// No description provided for @folderEdit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get folderEdit;

  /// No description provided for @folderIconCamper.
  ///
  /// In pl, this message translates to:
  /// **'Kamper'**
  String get folderIconCamper;

  /// No description provided for @folderIconMountains.
  ///
  /// In pl, this message translates to:
  /// **'Góry'**
  String get folderIconMountains;

  /// No description provided for @folderIconBeach.
  ///
  /// In pl, this message translates to:
  /// **'Wybrzeże'**
  String get folderIconBeach;

  /// No description provided for @folderIconCamping.
  ///
  /// In pl, this message translates to:
  /// **'Biwak'**
  String get folderIconCamping;

  /// No description provided for @folderIconHiking.
  ///
  /// In pl, this message translates to:
  /// **'Szlak'**
  String get folderIconHiking;

  /// No description provided for @folderIconCafe.
  ///
  /// In pl, this message translates to:
  /// **'Kawiarnia'**
  String get folderIconCafe;

  /// No description provided for @folderIconCompass.
  ///
  /// In pl, this message translates to:
  /// **'Kompas'**
  String get folderIconCompass;

  /// No description provided for @folderIconForest.
  ///
  /// In pl, this message translates to:
  /// **'Las'**
  String get folderIconForest;

  /// No description provided for @folderIconCity.
  ///
  /// In pl, this message translates to:
  /// **'Miasto'**
  String get folderIconCity;

  /// No description provided for @folderIconCastle.
  ///
  /// In pl, this message translates to:
  /// **'Zamek'**
  String get folderIconCastle;

  /// No description provided for @folderIconFood.
  ///
  /// In pl, this message translates to:
  /// **'Jedzenie'**
  String get folderIconFood;

  /// No description provided for @folderIconWine.
  ///
  /// In pl, this message translates to:
  /// **'Wino'**
  String get folderIconWine;

  /// No description provided for @folderIconBike.
  ///
  /// In pl, this message translates to:
  /// **'Rower'**
  String get folderIconBike;

  /// No description provided for @folderIconKayak.
  ///
  /// In pl, this message translates to:
  /// **'Kajak'**
  String get folderIconKayak;

  /// No description provided for @folderIconSki.
  ///
  /// In pl, this message translates to:
  /// **'Narty'**
  String get folderIconSki;

  /// No description provided for @folderColorEmerald.
  ///
  /// In pl, this message translates to:
  /// **'Szmaragd leśny'**
  String get folderColorEmerald;

  /// No description provided for @folderColorAmber.
  ///
  /// In pl, this message translates to:
  /// **'Bursztyn latarni'**
  String get folderColorAmber;

  /// No description provided for @folderColorGlacier.
  ///
  /// In pl, this message translates to:
  /// **'Błękit lodowcowy'**
  String get folderColorGlacier;

  /// No description provided for @folderColorHeather.
  ///
  /// In pl, this message translates to:
  /// **'Zmierzch wrzosowy'**
  String get folderColorHeather;

  /// No description provided for @folderColorRaspberry.
  ///
  /// In pl, this message translates to:
  /// **'Malina'**
  String get folderColorRaspberry;

  /// No description provided for @folderColorSapphire.
  ///
  /// In pl, this message translates to:
  /// **'Szafir'**
  String get folderColorSapphire;

  /// No description provided for @folderColorMeadow.
  ///
  /// In pl, this message translates to:
  /// **'Łąka'**
  String get folderColorMeadow;

  /// No description provided for @folderColorLagoon.
  ///
  /// In pl, this message translates to:
  /// **'Laguna'**
  String get folderColorLagoon;

  /// No description provided for @folderColorSlate.
  ///
  /// In pl, this message translates to:
  /// **'Łupek'**
  String get folderColorSlate;

  /// No description provided for @homeGreeting.
  ///
  /// In pl, this message translates to:
  /// **'Cześć!'**
  String get homeGreeting;

  /// No description provided for @homeFoldersTitle.
  ///
  /// In pl, this message translates to:
  /// **'Moje listy podróży'**
  String get homeFoldersTitle;

  /// No description provided for @homeAllPins.
  ///
  /// In pl, this message translates to:
  /// **'Mapa – wszystkie pinezki'**
  String get homeAllPins;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz jeszcze żadnego folderu'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In pl, this message translates to:
  /// **'Foldery zbierają pinezki jednej podróży albo o wspólnym mianowniku – np. „Portugalia 2026” czy „Ciekawe miejsca”.'**
  String get homeEmptyMessage;

  /// No description provided for @homeEmptyAction.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz pierwszy folder'**
  String get homeEmptyAction;

  /// No description provided for @mapAllPins.
  ///
  /// In pl, this message translates to:
  /// **'Wszystkie pinezki'**
  String get mapAllPins;

  /// No description provided for @mapBack.
  ///
  /// In pl, this message translates to:
  /// **'Wróć do listy folderów'**
  String get mapBack;

  /// No description provided for @placeCategoryGastronomy.
  ///
  /// In pl, this message translates to:
  /// **'Gastronomia'**
  String get placeCategoryGastronomy;

  /// No description provided for @placeCategoryPlaces.
  ///
  /// In pl, this message translates to:
  /// **'Miejsca i atrakcje'**
  String get placeCategoryPlaces;

  /// No description provided for @placeCategoryNature.
  ///
  /// In pl, this message translates to:
  /// **'Natura i widoki'**
  String get placeCategoryNature;

  /// No description provided for @placeCategoryActivities.
  ///
  /// In pl, this message translates to:
  /// **'Aktywności i szlaki'**
  String get placeCategoryActivities;

  /// No description provided for @placeCategoryTravel.
  ///
  /// In pl, this message translates to:
  /// **'Podróż i infrastruktura'**
  String get placeCategoryTravel;

  /// No description provided for @placeCategoryEntertainment.
  ///
  /// In pl, this message translates to:
  /// **'Rozrywka i kultura'**
  String get placeCategoryEntertainment;

  /// No description provided for @placeCategoryPractical.
  ///
  /// In pl, this message translates to:
  /// **'Punkty praktyczne'**
  String get placeCategoryPractical;

  /// No description provided for @placeTypeRestaurant.
  ///
  /// In pl, this message translates to:
  /// **'Restauracja'**
  String get placeTypeRestaurant;

  /// No description provided for @placeTypeCafe.
  ///
  /// In pl, this message translates to:
  /// **'Kawiarnia'**
  String get placeTypeCafe;

  /// No description provided for @placeTypeBar.
  ///
  /// In pl, this message translates to:
  /// **'Bar'**
  String get placeTypeBar;

  /// No description provided for @placeTypePub.
  ///
  /// In pl, this message translates to:
  /// **'Pub'**
  String get placeTypePub;

  /// No description provided for @placeTypeBakery.
  ///
  /// In pl, this message translates to:
  /// **'Piekarnia'**
  String get placeTypeBakery;

  /// No description provided for @placeTypePastryShop.
  ///
  /// In pl, this message translates to:
  /// **'Cukiernia'**
  String get placeTypePastryShop;

  /// No description provided for @placeTypeIceCreamShop.
  ///
  /// In pl, this message translates to:
  /// **'Lodziarnia'**
  String get placeTypeIceCreamShop;

  /// No description provided for @placeTypeFoodTruck.
  ///
  /// In pl, this message translates to:
  /// **'Food truck'**
  String get placeTypeFoodTruck;

  /// No description provided for @placeTypeWinery.
  ///
  /// In pl, this message translates to:
  /// **'Winnica'**
  String get placeTypeWinery;

  /// No description provided for @placeTypeBrewery.
  ///
  /// In pl, this message translates to:
  /// **'Browar'**
  String get placeTypeBrewery;

  /// No description provided for @placeTypeCity.
  ///
  /// In pl, this message translates to:
  /// **'Duże miasto'**
  String get placeTypeCity;

  /// No description provided for @placeTypeSmallTown.
  ///
  /// In pl, this message translates to:
  /// **'Miasteczko'**
  String get placeTypeSmallTown;

  /// No description provided for @placeTypeVillage.
  ///
  /// In pl, this message translates to:
  /// **'Wieś'**
  String get placeTypeVillage;

  /// No description provided for @placeTypeHistoricalMonument.
  ///
  /// In pl, this message translates to:
  /// **'Zabytek'**
  String get placeTypeHistoricalMonument;

  /// No description provided for @placeTypeMuseum.
  ///
  /// In pl, this message translates to:
  /// **'Muzeum'**
  String get placeTypeMuseum;

  /// No description provided for @placeTypeCastle.
  ///
  /// In pl, this message translates to:
  /// **'Zamek'**
  String get placeTypeCastle;

  /// No description provided for @placeTypePalace.
  ///
  /// In pl, this message translates to:
  /// **'Pałac'**
  String get placeTypePalace;

  /// No description provided for @placeTypeChurch.
  ///
  /// In pl, this message translates to:
  /// **'Kościół'**
  String get placeTypeChurch;

  /// No description provided for @placeTypeMonastery.
  ///
  /// In pl, this message translates to:
  /// **'Klasztor'**
  String get placeTypeMonastery;

  /// No description provided for @placeTypeRuins.
  ///
  /// In pl, this message translates to:
  /// **'Ruiny'**
  String get placeTypeRuins;

  /// No description provided for @placeTypeMonumentStatue.
  ///
  /// In pl, this message translates to:
  /// **'Pomnik'**
  String get placeTypeMonumentStatue;

  /// No description provided for @placeTypeHistoricalSite.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce pamięci'**
  String get placeTypeHistoricalSite;

  /// No description provided for @placeTypeViewpoint.
  ///
  /// In pl, this message translates to:
  /// **'Punkt widokowy'**
  String get placeTypeViewpoint;

  /// No description provided for @placeTypeMountainPeak.
  ///
  /// In pl, this message translates to:
  /// **'Szczyt'**
  String get placeTypeMountainPeak;

  /// No description provided for @placeTypeWaterfall.
  ///
  /// In pl, this message translates to:
  /// **'Wodospad'**
  String get placeTypeWaterfall;

  /// No description provided for @placeTypeLake.
  ///
  /// In pl, this message translates to:
  /// **'Jezioro'**
  String get placeTypeLake;

  /// No description provided for @placeTypeBeach.
  ///
  /// In pl, this message translates to:
  /// **'Plaża'**
  String get placeTypeBeach;

  /// No description provided for @placeTypeIsland.
  ///
  /// In pl, this message translates to:
  /// **'Wyspa'**
  String get placeTypeIsland;

  /// No description provided for @placeTypeNationalPark.
  ///
  /// In pl, this message translates to:
  /// **'Park narodowy'**
  String get placeTypeNationalPark;

  /// No description provided for @placeTypeNatureReserve.
  ///
  /// In pl, this message translates to:
  /// **'Rezerwat przyrody'**
  String get placeTypeNatureReserve;

  /// No description provided for @placeTypeCave.
  ///
  /// In pl, this message translates to:
  /// **'Jaskinia'**
  String get placeTypeCave;

  /// No description provided for @placeTypeForest.
  ///
  /// In pl, this message translates to:
  /// **'Las'**
  String get placeTypeForest;

  /// No description provided for @placeTypeGorgeCanyon.
  ///
  /// In pl, this message translates to:
  /// **'Wąwóz lub kanion'**
  String get placeTypeGorgeCanyon;

  /// No description provided for @placeTypeSpring.
  ///
  /// In pl, this message translates to:
  /// **'Źródło'**
  String get placeTypeSpring;

  /// No description provided for @placeTypeRiver.
  ///
  /// In pl, this message translates to:
  /// **'Rzeka'**
  String get placeTypeRiver;

  /// No description provided for @placeTypeHikingTrail.
  ///
  /// In pl, this message translates to:
  /// **'Szlak pieszy'**
  String get placeTypeHikingTrail;

  /// No description provided for @placeTypeCyclingRoute.
  ///
  /// In pl, this message translates to:
  /// **'Trasa rowerowa'**
  String get placeTypeCyclingRoute;

  /// No description provided for @placeTypeMotorcycleRoute.
  ///
  /// In pl, this message translates to:
  /// **'Trasa motocyklowa'**
  String get placeTypeMotorcycleRoute;

  /// No description provided for @placeTypeScenicDrive.
  ///
  /// In pl, this message translates to:
  /// **'Malownicza trasa'**
  String get placeTypeScenicDrive;

  /// No description provided for @placeTypeCableCar.
  ///
  /// In pl, this message translates to:
  /// **'Kolejka linowa'**
  String get placeTypeCableCar;

  /// No description provided for @placeTypeSkiSlope.
  ///
  /// In pl, this message translates to:
  /// **'Stok narciarski'**
  String get placeTypeSkiSlope;

  /// No description provided for @placeTypeSwimmingSpot.
  ///
  /// In pl, this message translates to:
  /// **'Kąpielisko'**
  String get placeTypeSwimmingSpot;

  /// No description provided for @placeTypeDivingSpot.
  ///
  /// In pl, this message translates to:
  /// **'Nurkowanie'**
  String get placeTypeDivingSpot;

  /// No description provided for @placeTypeCampsite.
  ///
  /// In pl, this message translates to:
  /// **'Pole biwakowe'**
  String get placeTypeCampsite;

  /// No description provided for @placeTypePicnicArea.
  ///
  /// In pl, this message translates to:
  /// **'Miejsce piknikowe'**
  String get placeTypePicnicArea;

  /// No description provided for @placeTypeHotel.
  ///
  /// In pl, this message translates to:
  /// **'Hotel'**
  String get placeTypeHotel;

  /// No description provided for @placeTypeGuesthouse.
  ///
  /// In pl, this message translates to:
  /// **'Pensjonat'**
  String get placeTypeGuesthouse;

  /// No description provided for @placeTypeCampingGround.
  ///
  /// In pl, this message translates to:
  /// **'Kemping'**
  String get placeTypeCampingGround;

  /// No description provided for @placeTypeParkingLot.
  ///
  /// In pl, this message translates to:
  /// **'Parking'**
  String get placeTypeParkingLot;

  /// No description provided for @placeTypeGasStation.
  ///
  /// In pl, this message translates to:
  /// **'Stacja paliw'**
  String get placeTypeGasStation;

  /// No description provided for @placeTypeEvCharging.
  ///
  /// In pl, this message translates to:
  /// **'Ładowarka EV'**
  String get placeTypeEvCharging;

  /// No description provided for @placeTypeAirport.
  ///
  /// In pl, this message translates to:
  /// **'Lotnisko'**
  String get placeTypeAirport;

  /// No description provided for @placeTypeRailwayStation.
  ///
  /// In pl, this message translates to:
  /// **'Dworzec kolejowy'**
  String get placeTypeRailwayStation;

  /// No description provided for @placeTypeHarbour.
  ///
  /// In pl, this message translates to:
  /// **'Port'**
  String get placeTypeHarbour;

  /// No description provided for @placeTypeMarina.
  ///
  /// In pl, this message translates to:
  /// **'Marina'**
  String get placeTypeMarina;

  /// No description provided for @placeTypeFerryTerminal.
  ///
  /// In pl, this message translates to:
  /// **'Terminal promowy'**
  String get placeTypeFerryTerminal;

  /// No description provided for @placeTypeTheatre.
  ///
  /// In pl, this message translates to:
  /// **'Teatr'**
  String get placeTypeTheatre;

  /// No description provided for @placeTypeCinema.
  ///
  /// In pl, this message translates to:
  /// **'Kino'**
  String get placeTypeCinema;

  /// No description provided for @placeTypeArtGallery.
  ///
  /// In pl, this message translates to:
  /// **'Galeria sztuki'**
  String get placeTypeArtGallery;

  /// No description provided for @placeTypeConcertVenue.
  ///
  /// In pl, this message translates to:
  /// **'Sala koncertowa'**
  String get placeTypeConcertVenue;

  /// No description provided for @placeTypeFestivalEvent.
  ///
  /// In pl, this message translates to:
  /// **'Festiwal lub wydarzenie'**
  String get placeTypeFestivalEvent;

  /// No description provided for @placeTypeAmusementPark.
  ///
  /// In pl, this message translates to:
  /// **'Park rozrywki'**
  String get placeTypeAmusementPark;

  /// No description provided for @placeTypeWaterPark.
  ///
  /// In pl, this message translates to:
  /// **'Park wodny'**
  String get placeTypeWaterPark;

  /// No description provided for @placeTypeZoo.
  ///
  /// In pl, this message translates to:
  /// **'Zoo'**
  String get placeTypeZoo;

  /// No description provided for @placeTypeAquarium.
  ///
  /// In pl, this message translates to:
  /// **'Akwarium'**
  String get placeTypeAquarium;

  /// No description provided for @placeTypeBotanicalGarden.
  ///
  /// In pl, this message translates to:
  /// **'Ogród botaniczny'**
  String get placeTypeBotanicalGarden;

  /// No description provided for @placeTypeGroceryStore.
  ///
  /// In pl, this message translates to:
  /// **'Sklep spożywczy'**
  String get placeTypeGroceryStore;

  /// No description provided for @placeTypePharmacy.
  ///
  /// In pl, this message translates to:
  /// **'Apteka'**
  String get placeTypePharmacy;

  /// No description provided for @placeTypeAtm.
  ///
  /// In pl, this message translates to:
  /// **'Bankomat'**
  String get placeTypeAtm;

  /// No description provided for @placeTypePublicToilet.
  ///
  /// In pl, this message translates to:
  /// **'Toaleta'**
  String get placeTypePublicToilet;

  /// No description provided for @placeTypeTouristInfo.
  ///
  /// In pl, this message translates to:
  /// **'Informacja turystyczna'**
  String get placeTypeTouristInfo;

  /// No description provided for @placeTypeBicycleRepair.
  ///
  /// In pl, this message translates to:
  /// **'Serwis rowerowy'**
  String get placeTypeBicycleRepair;

  /// No description provided for @placeTypeCarRepair.
  ///
  /// In pl, this message translates to:
  /// **'Warsztat samochodowy'**
  String get placeTypeCarRepair;

  /// No description provided for @placeTypeLaundromat.
  ///
  /// In pl, this message translates to:
  /// **'Pralnia samoobsługowa'**
  String get placeTypeLaundromat;

  /// No description provided for @placeIconsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Ikony miejsc'**
  String get placeIconsTitle;

  /// No description provided for @placeIconsLibraryTab.
  ///
  /// In pl, this message translates to:
  /// **'Biblioteka'**
  String get placeIconsLibraryTab;

  /// No description provided for @placeIconsMapTab.
  ///
  /// In pl, this message translates to:
  /// **'Mapa'**
  String get placeIconsMapTab;

  /// No description provided for @placeIconsDarkBackground.
  ///
  /// In pl, this message translates to:
  /// **'Ciemne tło'**
  String get placeIconsDarkBackground;

  /// No description provided for @placeIconsSummary.
  ///
  /// In pl, this message translates to:
  /// **'{types} typów · {categories} kategorii'**
  String placeIconsSummary(int types, int categories);

  /// No description provided for @placeIconsMapHint.
  ///
  /// In pl, this message translates to:
  /// **'Stuknij pinezkę, żeby ją zaznaczyć'**
  String get placeIconsMapHint;

  /// No description provided for @placeTypeOther.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get placeTypeOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
