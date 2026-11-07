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

## Konsekwencje
- Grafikę poprawia się w generatorze, a SVG jest wynikiem.
- Parametry animacji są w `SplashConfig`, a prędkości warstw w generatorze.
- Zapas rastra na P30 jest mały, więc sceny nie mogą być cięższe od „Alp”. Wszystkie 8 scen mieści się w tym budżecie (ścieżki: 498–1664, odcinki: 21 699–44 933) i na P30 jedzie około 60 klatek/s; pierwsze 3 s po wczytaniu są najsłabsze, zob. [[v24 – ekran powitalny]]. Gdyby były albo pojawiły się przycięcia, kolejny krok to raster wolnych warstw (niebo, chmury, dalekie góry) do obrazu wielkości widoku.
- Android 12+ pokazuje przed Flutterem własny ekran z ikoną; P30 tego nie sprawdzi ([[Backlog]]).
- Grafika jest ozdobą: błąd wczytania daje sam gradient i normalny start.

## Powiązane
[[v24 – ekran powitalny]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[ADR-002 Riverpod]], [[00 Jureczek – przegląd]]
