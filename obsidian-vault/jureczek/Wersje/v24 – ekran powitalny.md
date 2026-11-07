---
tags: [jureczek, wersja, ekran-powitalny, animacja, svg]
wersja: v24
status: etap 3 z 4 – 8 scen na telefonie, arkusz czeka na ocenę użytkownika
data: 2026-11-07
---
# v24 – ekran powitalny

Prośba użytkownika z 2026-11-07: zamiast ciemnego tła przy starcie animowany ekran powitalny. Wektorowy kamper z boku jedzie z lewej do prawej przez góry z paralaksą, jak początek ilustrowanej gry przygodowej. Decyzja: [[ADR-016 Ekran powitalny z warstw SVG]].

Praca jest podzielona na przystanki: styl (etap 1), animacja na jednej scenie (etap 2), pozostałe 7 scen (etap 3), dokończenie (etap 4). Ta notatka opisuje stan po etapie 3.

## Zakres
- **Fazy:** A wjazd kampera, B jazda z paralaksą, C przyspieszenie i odjazd, a na końcu przenikanie do ekranu startowego.
- **Czas:** minimum 3,5 s, ale bez blokowania startu. Faza C rusza raz, gdy aplikacja jest gotowa i minimum minęło.
- **Gotowość:** pierwszy wynik `foldersProvider` (dane albo błąd) i obraz nagłówka. Limit 10 s.
- **Pory dnia:** 4 palety wg `Landscape.at()`. W nocy świecą okna, przednia szyba, namiot i reflektor, a tylna lampa ma czerwoną poświatę.
- **Natywne tło:** neutralny gradient zmierzchu, ten sam w pierwszej klatce Fluttera, potem 0,4 s przejścia w niebo pory dnia.
- **Rysunki:** `tool/splash_art.py` generuje kampera, kamyk, 4 nieba i 8 scen po 7 warstw: Alpy, dolina z turkusowym jeziorem, łąki z krętą drogą, wąwóz z rzeką i wiaduktem, złoty las modrzewiowy, czerwone skały i stoliwa, fiord, wysoka przełęcz z głazami i wodospadem.
- **Zawieszenie:** dwa końce nadwozia na sprężynach, oparte o koła na własnych, sztywniejszych sprężynach. Nadwozie i nadkola się przechylają, a koła i cień zostają na drodze.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Użycie `bgs.png` | tylko styl i paleta; własna kompozycja, bez logo i odrysowywania |
| 2 | Wierność kampera | wszystko z `screen.png` (dach, deska, bagaże, lusterko) + kurz spod obu osi; najpierw bez podskoków, potem zawieszenie i kamyki na prośbę użytkownika (decyzja 14) |
| 3 | Zimny start z udostępnienia | bez minimum, faza C od razu po gotowości |
| 4 | Pominięcie stuknięciem | tak; przed gotowością zapamiętane, w fazie C ignorowane, w fazie A kamper rusza z bieżącego miejsca |
| 5 | Zawieszona gotowość | limit 10 s, potem ekran startowy z własnym stanem ładowania |
| 6 | Pierwsza klatka | natywny fiołkowy zmierzch, bo zasób Androida nie zależy od godziny |
| 7 | Wyjście | około 1,1 s: odjazd 0,7 s, przenikanie 0,5 s od 0,6 s; razem około 4,6 s |
| 8 | Różnorodność | 8 krajobrazów, czysty los przy każdym uruchomieniu, bez zapisu (etap 3) |
| 9 | „Usuń animacje” w systemie | nieruchoma scena 3,5 s, potem przenikanie |
| 10 | Napis | brak |
| 11 | Chmury | wspólny kłębiasty kontur z pasami światła; świadome odejście od referencji (brązowe kopuły, grube pasy, drobiny), która w pionowym kadrze wyglądała jak bąble |
| 12 | Góry | różne sylwetki; pierwszy kadr ułożony tak, by w pionie było widać różne kształty, bo dalekie warstwy prawie się nie przesuwają |
| 13 | Rysowanie | same `Picture`, bez rasteryzacji warstw, zob. pomiar niżej |
| 14 | Życie kampera | fizyka zamiast ręcznych klatek: hamowanie na wjeździe siada na przód, przyspieszanie na odjeździe na tył, po zatrzymaniu nadwozie odbija; kamyk unosi kolejno przednie i tylne koło |
| 15 | Kamyki | pierwszy najazd 1,7–2,2 s, kolejne co 3–5 s, różna wielkość; podczas odjazdu bez najazdów, bo kamper zmienia prędkość |
| 16 | Sceny 2–8 | te same klocki co w Alpach, własne okresy warstw i pierwszy kadr ułożony pod pion; kolory pierwszego planu różne tylko tam, gdzie zielony by nie pasował (modrzewie, stoliwa, przełęcz) |
| 17 | Wąwóz | most kończy się za ścianami skalnymi, żeby przy przewijaniu nie było widać urwanego końca |

## Pliki
- `tool/splash_art.py`: generator SVG, palet i manifestu. SVG się nie edytuje.
- `assets/splash/`: wyjście generatora (67 SVG, około 3,5 MB, 406 tokenów kolorów).
- `lib/features/splash/domain/splash_config.dart`: wszystkie parametry w jednym miejscu.
- `lib/features/splash/domain/splash_gate.dart`: czysta bramka gotowości, jedno wyzwolenie.
- `lib/features/splash/domain/splash_manifest.dart`: opis grafik.
- `lib/features/splash/application/splash_motion.dart`: `SplashFrame`, fazy A/B/C, zawieszenie i kamyki, bez zegara.
- `lib/features/splash/data/splash_art_loader.dart`: `ColorMapper` palety, wczytanie tylko wybranej sceny.
- `lib/features/splash/presentation/splash_scene_painter.dart`: paralaksa, kamper na zawieszeniu, kurz, kamyki.
- `lib/features/splash/presentation/splash_overlay.dart`: nakładka, gotowość, cykl życia.
- `lib/app.dart`: `MaterialApp.builder` z nakładką, parametr `showSplash`.
- `lib/dev/splash_main.dart`: podgląd z pomiarem klatek, poza aplikacją.
- `android/app/src/main/res/drawable*/launch_background.xml`: gradient zmierzchu.
- `pubspec.yaml`: katalogi grafik.
- **Testy:** `test/features/splash/` (bramka, ruch, nakładka, spójność grafik).

## Pomiar na P30
Tryb `--profile`, rysowanie przez Impeller na OpenGLES, 7 warstw na scenie:
- około 60 klatek/s (180 klatek na 3 s), także w nocy;
- build około 2,3 ms; raster p50 15,4 ms, p90 około 16,5 ms, p99 18–24 ms;
- 3–15% klatek przekracza 16,7 ms rastra;
- wczytanie sceny około 140 ms.

Zapas jest mały: **sceny 2–8 nie mogą być cięższe od „Alp”**. Płynności w samej aplikacji nie zmierzyłem osobno, ten sam malarz działał w podglądzie. Pomiar jest sprzed zawieszenia, kurzu spod przedniej osi i kamyków.

Pomiar po etapie 3, ze wszystkimi 8 scenami, zawieszeniem, kurzem i kamykami (podgląd, `--profile`, pora zachodu, okna po około 3 s):
- około 60 klatek/s w każdej scenie, raster p50 13,8–16,0 ms, wczytanie sceny 69–145 ms;
- **pierwsze okno po wczytaniu sceny jest najgorsze:** 8–42 ze 180 klatek ponad 16,7 ms rastra, p99 do około 36 ms; to właśnie okno widać przy starcie, a kolejne mają 1–26 takich klatek;
- budżet: najcięższe są modrzewie (1664 ścieżki, 39 244 odcinki) i Alpy (1657, 44 933); ścieżek modrzewie mają o 7 więcej, odcinków mniej.

Pomiar dotyczy podglądu, gdzie scena zmieniana jest po długim przytrzymaniu, a nie zimnego startu aplikacji.

## Pułapki
- `SvgAssetLoader` z `assetBundle: rootBundle` nie przejdzie do izolatu („object is unsendable”). Bundle podajemy tylko w testach.
- Nocna nakładka leży nad całym nadwoziem, więc przykrywa wszystko, co w dzień jest nad szybą. Podziałka i lusterko są wspólnymi elementami i są rysowane w obu wersjach.
- Cień kampera leży na drodze, a nadkola należą do nadwozia, dlatego `camper_under.svg` rozdzielono na cień i nadkola.
- Fizyka liczy się krokiem 1/240 s: sprężyna koła jest sztywna, a krok równy klatce mógłby ją rozhuśtać.
- Przezroczystość na `Picture` wymaga `saveLayer`, dlatego kurz rośnie i maleje do zera zamiast wygasać.
- Nakładka musi być zawsze drugim dzieckiem tego samego `Stack`, inaczej zniknięcie przebudowałoby ekran startowy.
- `AnnotatedRegion` po zniknięciu nie przywraca paska stanu, więc robi to `SystemChrome.setSystemUIOverlayStyle`.
- Rendering Fluttera nie trafia do `gfxinfo`, a Huawei nie ma `screenrecord`. Czasy klatek mierzy `FrameTiming` w podglądzie.
- `flutter run --no-resident ... | tail` potrafi wisieć ponad godzinę i nie zbudować nowej wersji. Pewniej: `flutter build apk --profile`, potem `adb install -r`. Warto sprawdzić, co jest w APK, przez `unzip -p`.
- `pumpAndSettle` wisi przy zapętlonej animacji, dlatego przy pustym tokenie i z `showSplash: false` nakładki nie ma.
- W teście animacja kończy się dopiero po przekroczeniu swojej długości: `pump(500 ms)` przy 500 ms nie wystarczy.
- Tokeny kolorów numeruje kolejność pierwszego użycia, więc nowe kolory na poziomie modułu generatora zmieniają pliki wszystkich scen. Rysunek zostaje ten sam; sprawdzone porównaniem SVG po podstawieniu palety.
- Warstwa daleka musi schodzić poniżej najwyższego punktu wzgórz, inaczej u stóp gór prześwituje niebo. Stąd woda rysowana 90 jednostek poniżej końca gradientu i niższa podstawa gór w stoliwach i na przełęczy.
- Wolna warstwa przesuwa się w lewo, więc to, co leży na lewo od pierwszego kadru, nigdy się nie pokaże. Elementy dla oka trzeba kłaść w kadrze albo na prawo od niego.
- Wodospad zaczyna się na `Massif.sky_y(x)`, a nie na stałej wysokości, bo inaczej spada z nieba.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 349/349 (test grafik wymaga teraz dokładnie 8 scen)
- [x] P30 przez adb: natywny gradient, przejście w niebo, wjazd, jazda z paralaksą, odjazd, ekran startowy
- [x] P30 przez adb: stuknięcie po gotowości daje odjazd i przenikanie
- [x] P30 przez adb: zimny start z udostępnienia, mapa z wynikiem po około 1,5 s (bez wcześniejszego zrzutu samej nakładki)
- [x] P30 przez adb: „Usuń animacje” (`animator_duration_scale` 0) daje nieruchomą scenę i przenikanie; ustawienie przywrócone
- [x] P30: 4 palety, tylna lampa, nocna przednia szyba, podziałka i lusterko
- [ ] Użytkownik: płynność i tempo wyjścia na telefonie
- [x] P30 przez adb: przechył przy hamowaniu na wjeździe, kamyk na linii kół, kurz przy obu osiach (zrzuty; samego podskoku koła zrzuty nie złapały, sprawdzają go testy)
- [ ] Użytkownik: czy kurz pasuje
- [ ] Użytkownik: siła przechyłu i podskoku na kamyku
- [x] Chrome: pierwszy kadr 8 scen w 4 porach (32 kombinacje), kadry po 4,6 s i 10 s jazdy, układ poziomy o zachodzie
- [x] P30 przez adb: każda z 8 scen wczytuje się i jedzie (zrzuty o zachodzie), czasy klatek jak wyżej
- [x] P30 przez adb: zwykła aplikacja po etapie 3, losowa scena, potem ekran startowy
- [ ] Użytkownik: ocena arkusza 32 kombinacji
- [ ] Etap 4: obrót ekranu w trakcie animacji, szew pętli przy dłuższej jeździe

## Poprawki po teście
- Chmury narysowane od nowa po uwadze „wyglądają jak bąble”.
- Różne sylwetki gór po uwadze „nie muszą być wszystkie spiczaste”.
- Tylne światło na czerwono w nocy (prośba użytkownika).
- Noc: świeci przednia szyba, lusterko nie jest zasłonięte, podziałka szyby kabiny wróciła (uwaga użytkownika).
- Kurz także za przednimi kołami, zawieszenie reagujące na przyspieszanie i hamowanie, kamyki na drodze (prośba użytkownika).
- Etap 3, własny przegląd arkusza przed pokazaniem: filary mostu i rzeka wisiały w powietrzu, fiord nie miał stromych ścian, pod wodą i u stóp gór prześwitywało niebo, wodospad na przełęczy zaczynał się w powietrzu, chmura zasłaniała słońce na łąkach.

## Otwarte
- Etap 3: werdykt użytkownika do arkusza 32 kombinacji.
- Na ścianach wąwozu jasna płyta skalna wygląda jak przyklejony wielokąt; czeka na ocenę arkusza.
- Etap 4: obrót, szew pętli, udostępnienie z 8 scenami, `CLAUDE.md`.
- Skała jest bardziej kanciasta niż na referencji; użytkownik zaakceptował styl z 2026-11-07.
- `resorces/bgs.png` nie jest w repo: to cudza ilustracja, służy tylko jako referencja.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-016 Ekran powitalny z warstw SVG]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[v10 – foldery i ekran startowy]], [[Backlog]]
