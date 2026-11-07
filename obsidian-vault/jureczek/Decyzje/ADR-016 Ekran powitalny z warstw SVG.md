---
tags: [jureczek, adr, ekran-powitalny, svg]
status: przyjęta
data: 2026-11-07
---
# ADR-016: Ekran powitalny z warstw SVG

## Kontekst
Aplikacja startowała od ciemnego tła. Użytkownik chce animowanej ilustracji: kamper jadący przez góry, kilka krajobrazów, 4 pory dnia. Ekran ma pasować do faktycznej gotowości aplikacji i nie może jej opóźniać.

## Rozważane opcje
- **Rive albo Lottie:** gotowa animacja, ale nowa zależność, zewnętrzny edytor i brak prostego przebarwiania scen.
- **Gotowe obrazy PNG:** proste rysowanie, ale 8 scen × 4 pory × warstwy to duży APK.
- **Warstwy SVG z generatora + `flutter_svg` + `CustomPainter`:** bez nowych zależności, mały rozmiar, pełna kontrola, ale rysowanie w każdej klatce kosztuje.
- **Nakładka nad Navigatorem albo osobna trasa startowa:** trasa opóźniałaby budowę ekranu startowego i gryzła się z mapą otwieraną przez udostępnienie.

## Decyzja
- `tool/splash_art.py` generuje SVG z tokenami kolorów zamiast barw. `palettes.json` mapuje token na kolor pory dnia, a `ColorMapper` podstawia go przy wczytaniu.
- Warstwy są kafelkami o własnym okresie i prędkości z `manifest.json`. Każda jest o 2 jednostki szersza od okresu, żeby na szwie nie było szczeliny.
- `SplashOverlay` leży w `MaterialApp.builder`, nad Navigatorem. `HomeScreen` powstaje od razu pod spodem.
- `SplashGate` to czysta klasa z timerami: jedno wyzwolenie, testowana w `fake_async`.
- Rysujemy same `Picture`. Na P30 daje to około 60 klatek/s, bez kosztu pamięci rastra ([[v24 – ekran powitalny]]).
- `SplashStart` wczytuje scenę od `main()` i wstrzymuje pierwszą klatkę Fluttera do jej gotowości, najwyżej 1 s. Gradient we Flutterze zostaje tylko na spóźnienie albo błąd.
- Okno startowe Androida jest wyłączone (`windowDisablePreview`), bo to zasób stały, wpisany w APK, który nie zna sceny ani pory dnia. Pierwszym obrazem jest scena rozwijana z pulpitu.
- Sceny idą po kolei, a licznik jest w `SharedPreferences` po stronie Androida: jest dostępny przed bazą i nie wymaga nowej zależności.

## Konsekwencje
- Grafikę poprawia się w generatorze, a SVG jest wynikiem.
- Parametry animacji są w `SplashConfig`, a prędkości warstw w generatorze.
- Zapas rastra na P30 jest mały, więc sceny nie mogą być cięższe od „Alp”. Wszystkie 8 scen mieści się w tym budżecie (ścieżki: 498–1657, odcinki: 21 699–44 933; najcięższe są same Alpy) i na P30 jedzie około 60 klatek/s; przy zimnym starcie przerwy przypadają na pierwszą sekundę, gdy wczytuje się scena, zob. [[v24 – ekran powitalny]]. Gdyby były albo pojawiły się przycięcia, kolejny krok to raster wolnych warstw (niebo, chmury, dalekie góry) do obrazu wielkości widoku.
- Android 12+ pokazuje przed Flutterem własny ekran z ikoną; P30 tego nie sprawdzi ([[Backlog]]).
- Grafika jest ozdobą: błąd wczytania daje sam gradient i normalny start.
- Po kliknięciu przez około 0,4 s (`release`) nie widać reakcji. Dokumentacja Androida opisuje `windowDisablePreview` właśnie jako źródło takiego odczucia dłuższego startu. Android 12+ i tak pokazuje własny ekran ([[Backlog]]).
- Pierwsza klatka przychodzi o około 100 ms później niż dawna klatka z gradientem, ale scena jest w pełni widoczna o około 400 ms wcześniej.

## Powiązane
[[v24 – ekran powitalny]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[ADR-002 Riverpod]], [[00 Jureczek – przegląd]]
