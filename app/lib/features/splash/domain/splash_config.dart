import 'dart:ui';

/// Wszystkie parametry ekranu powitalnego w jednym miejscu.
class SplashConfig {
  const SplashConfig({
    this.minimumDuration = const Duration(milliseconds: 3500),
    this.readinessLimit = const Duration(seconds: 10),
    this.launchFade = const Duration(milliseconds: 400),
    this.firstFrameLimit = const Duration(seconds: 1),
    this.enterDuration = const Duration(milliseconds: 1300),
    this.driveOffDuration = const Duration(milliseconds: 700),
    this.fadeDelay = const Duration(milliseconds: 600),
    this.fadeDuration = const Duration(milliseconds: 500),
    this.speedScale = 1.0,
    this.camperAnchor = 0.5,
    this.driveOffWheelBoost = 3.0,
    this.dustPuffs = 5,
    this.dustLife = const Duration(milliseconds: 900),
    this.dustDrift = 170,
    this.dustRise = 26,
    this.dustSize = 0.62,
    this.dustFrontPuffs = 3,
    this.dustFrontSize = 0.72,
    this.suspensionHz = 1.6,
    this.suspensionDamping = 0.3,
    this.suspensionCoupling = 0.18,
    this.squat = 2.6,
    this.wheelHz = 7,
    this.wheelDamping = 0.35,
    this.pebbleFirst = (1.7, 2.2),
    this.pebbleEvery = (3.0, 5.0),
    this.pebbleLift = 5,
    this.pebbleContact = 30,
  });

  /// Najkrótszy czas ekranu; udostępnienie, stuknięcie i błąd grafik go pomijają.
  final Duration minimumDuration;

  /// Po tym czasie ekran znika, nawet gdy aplikacja nie zgłosiła gotowości.
  final Duration readinessLimit;

  /// Przejście z gradientu w scenę, tylko gdy scena spóźniła się na pierwszą klatkę.
  final Duration launchFade;

  /// Tyle najwyżej pierwsza klatka Fluttera czeka na scenę; potem pokazuje gradient.
  final Duration firstFrameLimit;

  /// Wjazd kampera (faza A).
  final Duration enterDuration;

  /// Odjazd kampera (faza C).
  final Duration driveOffDuration;

  /// Po takim czasie odjazdu zaczyna się przenikanie do ekranu startowego.
  final Duration fadeDelay;
  final Duration fadeDuration;

  /// Mnożnik tempa jazdy: krajobrazu i kół. Prędkości warstw są w manifeście.
  final double speedScale;

  /// Środek kampera w trakcie jazdy, jako ułamek szerokości widoku.
  final double camperAnchor;

  /// O ile szybciej kręcą się koła pod koniec odjazdu (1 = dwa razy szybciej).
  final double driveOffWheelBoost;

  /// Kurz za kamperem: liczba obłoków, czas życia, droga i wzniesienie w jednostkach
  /// sceny oraz skala rysunku w największym momencie.
  final int dustPuffs;
  final Duration dustLife;
  final double dustDrift;
  final double dustRise;
  final double dustSize;

  /// Kurz spod przedniego koła: liczba obłoków i skala względem tylnego.
  final int dustFrontPuffs;
  final double dustFrontSize;

  /// Zawieszenie: częstotliwość własna nadwozia i tłumienie (1 = bez kołysania).
  final double suspensionHz;
  final double suspensionDamping;

  /// Jak mocno uderzenie w jedną oś przechyla drugi koniec nadwozia w przeciwną stronę.
  final double suspensionCoupling;

  /// O tyle jednostek sceny siada oś przy pełnym przyspieszeniu albo hamowaniu.
  final double squat;

  /// Koło na oponie: sztywniejsze od nadwozia, dlatego podskakuje szybko i krótko.
  final double wheelHz;
  final double wheelDamping;

  /// Kamyk: pierwszy najazd przedniego koła (od–do, w sekundach od startu), odstęp
  /// między kolejnymi, wysokość uniesienia koła i długość kontaktu w jednostkach sceny.
  final (double, double) pebbleFirst;
  final (double, double) pebbleEvery;
  final double pebbleLift;
  final double pebbleContact;

  /// Zapas na spóźnioną albo niewczytaną scenę, ten sam co w `launch_background.xml`.
  /// Przy normalnym starcie go nie widać: okno startowe jest wyłączone, a scena zdąża.
  static const launchSky = [
    Color(0xFF7D74B4),
    Color(0xFFB884AE),
    Color(0xFFD98E9E),
  ];
}
