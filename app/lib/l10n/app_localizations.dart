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
