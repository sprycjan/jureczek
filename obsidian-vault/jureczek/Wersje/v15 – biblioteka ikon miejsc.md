---
tags: [jureczek, wersja, pinezki, ikony]
wersja: v15
status: zaimplementowana – sprawdzona przez adb, czeka na ocenę użytkownika
data: 2026-11-03
---
# v15 – biblioteka ikon miejsc

Zadanie z 2026-11-03: komplet pinezek i ikon dla wszystkich typów miejsc wg specyfikacji Stitch. Zadanie było pisane pod Jetpack Compose. Tu jest przełożone na Flutter ([[ADR-011 Biblioteka ikon miejsc w SVG]]).

## Zakres
- **74 typy** w 7 kategoriach, każdy z własnym symbolem: gastronomia 10, miejsca i atrakcje 12, natura i widoki 13, aktywności i szlaki 10, podróż i infrastruktura 11, rozrywka i kultura 10, punkty praktyczne 8.
- Dla każdego typu 3 SVG (**222 pliki**):
  - pinezka 36×44 dp z cieniem,
  - zaznaczona 42×52 dp z białym pierścieniem 3 dp i mocniejszym cieniem,
  - samodzielna ikona 24×24 dp w kolorze kategorii na przezroczystym tle.
- Kolory kategorii wg specyfikacji (primary / light container / dark container, a dla ciemnego motywu także `onDarkContainer` ze Stitch) w jednym miejscu: `PlaceCategory`.
- Komponenty: `PlacePin(type, selected:, width:)`, `PlaceIcon(type, size:, color:)`, `PlaceIconBadge(type, dark:)`, `renderPlacePinPng` (PNG dla Mapbox).
- **Galeria deweloperska** (osobny punkt wejścia): karta „Biblioteka” pokazuje wszystkie kategorie, typy, oba stany pinezki, ikonę, ikonę na tle kategorii, kolory i przełącznik jasne/ciemne tło. Karta „Mapa” pokazuje 26 pinezek różnych typów w Krakowie i Tatrach, a tap zaznacza pinezkę.
- Aplikacja główna **bez zmian**: formularz pinezki i baza dalej mają 8 typów z v9.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Compose → ? | Flutter: widżety zamiast composabli, `flutter_svg` zamiast Vector Drawable – [[ADR-011 Biblioteka ikon miejsc w SVG]] |
| 2 | Źródło rysunków | jeden skrypt `tool/place_icons.py` (symbole + tokeny), SVG generowane |
| 3 | Cień | `feDropShadow` w SVG (dla projektanta) + ten sam cień malowany we Flutterze (`ImageFiltered` / `ImageFilter.blur`) |
| 4 | Symbol w pinezce | biały, pole 22 dp (25.7 w zaznaczonej), obrys przeliczony na 1.8 dp jak w matrycy Stitch |
| 5 | Ikona na ciemnym tle | w galerii kolor `darkContainer` (np. #455A64 ginie na granacie) |
| 6 | Katalogi | `assets/place_icons/<kategoria>/`, nie `assets/markers` (tamte to PNG z v9) |
| 7 | Galeria | osobny `lib/dev/place_icons_main.dart`, bez wejścia z aplikacji |
| 8 | Podobne typy | kemping (kamper + słupek) ≠ pole biwakowe (namiot); szczyt (góry) ≠ punkt widokowy (lornetka na statywie); jezioro (trzciny + fale) ≠ rzeka (meander); zamek (blanki) ≠ pałac (kopuła); teatr (maski) ≠ kino (klaps) ≠ sala koncertowa (nuty) |

## Zależności
- `flutter_svg: ^2.3.2`

## Pliki
- `app/tool/place_icons.py`: generator SVG (nowy); opcjonalnie arkusz podglądu HTML
- `app/assets/place_icons/{gastronomy,places,nature,activities,travel,entertainment,practical}/*.svg`: 222 pliki (nowe), `pubspec.yaml`: katalogi assetów
- `app/lib/features/places/domain/place_category.dart`: enum `PlaceCategory` z tokenami kolorów (nowy)
- `app/lib/features/places/domain/place_type.dart`: enum `PlaceType` (74), ścieżki assetów, `of`, `fromKey` (nowy)
- `app/lib/features/places/presentation/place_icons.dart`: `PlacePinGeometry`, `PlaceIcon`, `PlaceIconBadge`, `PlacePin`, `renderPlacePinPng` (nowy)
- `app/lib/features/places/presentation/place_labels.dart`: polskie nazwy kategorii i typów (nowy)
- `app/lib/features/places/presentation/place_icon_gallery.dart`: galeria + mapa (nowy)
- `app/lib/dev/place_icons_main.dart`: punkt wejścia galerii (nowy)
- `app/lib/l10n/app_pl.arb`: `placeCategory*`, `placeType*`, `placeIcons*`
- `app/test/features/places/place_icons_test.dart`: 10 testów (nowy)

## Pułapki
- `flutter_svg` pomija `<filter>` z ostrzeżeniem `unhandled element <filter/>` – cień trzeba malować samemu. Parametry są w `PlacePinGeometry`, a test porównuje je z SVG.
- `renderPlacePinPng`: najpierw wektor do obrazu w docelowej gęstości, potem cień z obrazu (`Paint.imageFilter`) w pikselach urządzenia. Dzięki temu sigma rozmycia nie zależy od transformacji canvasu.
- `PlacePin` ma rozmiar samego korpusu, a cień i margines viewBox wychodzą poza niego (`Stack(clipBehavior: none)`).
- Galeria podmienia aplikację na telefonie (ten sam `applicationId`). Dane zostają, ale potem trzeba znowu wgrać `lib/main.dart`.
- Testy galerii: `TabBarView` też jest `Scrollable`, więc listę trzeba szukać przez `find.descendant(of: CustomScrollView)`.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 197/197 (w tym 10 nowych: liczby typów, komplet 222 SVG bez sierot, kolory, cień = SVG, unikalne symbole, wczytanie przez `flutter_svg`, rozmiary widżetów, galeria, PNG zwykły i zaznaczony)
- [x] PNG z `renderPlacePinPng` porównany wzrokowo z SVG w Chrome – ten sam kształt i cień
- [x] P30 przez adb: galeria – wszystkie kategorie, pinezki z cieniem, ikony i tła na ciemnym i jasnym tle
- [x] P30 przez adb: mapa – pinezki w Krakowie, czubek w punkcie (Zamek Wawel), tap zaznacza (pierścień, większa), tap w inną przenosi zaznaczenie
- [x] P30: po testach wgrana z powrotem zwykła aplikacja
- [ ] Użytkownik: czytelność symboli, rozróżnialność podobnych typów, porównanie z matrycą Stitch

## Poprawki po teście
- Podpowiedź na mapie zasłaniała skalę Mapbox – przesunięta niżej (`top: 44`). Start mapy na zoomie 14.2 zamiast 13.2 (pinezki w centrum nachodziły na siebie). Sprawdzone przez adb.

## Otwarte
- ✅ Zrobione w [[v16 – typy miejsc w pinezkach]]. Pierwotnie: podpięcie typów do pinezek: kolumna typu w bazie (migracja), wybór typu w formularzu (74 pozycje → wyszukiwarka albo wybór kategoria → typ), mapa na `renderPlacePinPng`, własny kolor ([[ADR-010 Kolor pinezki z warstw]] nie obejmuje SVG).
- Podpowiedź typu z POI Mapbox (`maki`) – teraz jest dla czego.
- Symbole do oceny: wąwóz/kanion, motocykl, festiwal, warsztat samochodowy – najtrudniejsze do narysowania w 20 dp.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[v9 – kategorie pinezek]], [[v14 – lokalizacja, ikony POI i kolor pinezki]], [[Backlog]]
