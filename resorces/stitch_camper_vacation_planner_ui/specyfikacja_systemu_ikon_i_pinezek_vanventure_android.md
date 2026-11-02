# Google Stitch – Complete Map Pin & Standalone Category Icon Design System
**Target Platform:** Android (Material 3 / Jetpack Compose)  
**Brand Identity:** Wanderlust Illustrated / Modern Travel & Location Discovery

---

## 1. Architektura Systemu i Geometria Wektorowa

### 1.1 Siatka Bazowa i Jednostki (dp)
Wszystkie zasoby zaprojektowano na jednolitej siatce opartej o współrzędne 24x24 dp (skalowalne do 32dp, 40dp i 48dp).
- **Standalone Icons:** Bounding box `24 x 24 dp`, wewnętrzny obszar rysunkowy `20 x 20 dp` (2dp padding). Grubość obrysu (stroke): `1.75 dp` / stała geometria konturów z zaokrągleniami `stroke-linejoin: round` i `stroke-linecap: round`.
- **Map Pins (Default):** Szerokość `36 dp`, wysokość `44 dp`. Średnica główki pinu `36 dp`, iglica schodząca z promieniem `4 dp` ku dołowi, cień elevation `4 dp` (`ambientShadowColor = 0x1A000000`, `spotShadowColor = 0x26000000`).
- **Map Pins (Selected):** Skalowanie `1.15x` (szerokość `42 dp`, wysokość `52 dp`), pierścień akcentujący `3 dp` w kolorze białym/kontrastowym, podbity cień elevation `8 dp`.

---

## 2. Paleta Barwna Kategorii (Category Color System)

Każda z 7 głównych kategorii posiada ścisłe tokeny barwne dla trybu jasnego i ciemnego z zachowaniem kontrastu WCAG AA:

| Główna Kategoria | Barwa Wiodąca | Hex Light (Container / OnContainer) | Hex Dark (Surface / Icon) |
|---|---|---|---|
| **Gastronomia (Gastronomy)** | Ciepły pomarańcz / Bursztyn | `#E65100` / `#FFF3E0` | `#FFB74D` / `#2D1600` |
| **Miejsca i Zabytki (Places & Culture)** | Głęboki błękit szafirowy | `#1565C0` / `#E3F2FD` | `#90CAF9` / `#001E3D` |
| **Natura i Widoki (Nature & Viewpoints)** | Świeża leśna zieleń / Szmaragd | `#2E7D32` / `#E8F5E9` | `#81C784` / `#052E0B` |
| **Aktywności (Activities & Sport)** | Dynamiczny fiolet / Ametyst | `#7B1FA2` / `#F3E5F5` | `#CE93D8` / `#2A003D` |
| **Podróż i Infrastruktura (Travel & Transit)** | Nowoczesny łupek / Stalowy błękit | `#455A64` / `#ECEFF1` | `#B0BEC5` / `#1A2328` |
| **Rozrywka i Wydarzenia (Entertainment)** | Żywa magenta / Malina | `#C2185B` / `#FCE4EC` | `#F48FB1` / `#380017` |
| **Punkty Praktyczne (Practical Places)** | Czysty turkus / Cyan | `#00838F` / `#E0F7FA` | `#4DD0E1` / `#00282C` |

---

## 3. Kompletna Macierz Symboli (58 Typów Lokalizacji)

### 3.1 Gastronomia (Amber `#E65100`)
1. **Restauracje (Restaurants):** Talerz z widelcem i nożem
2. **Kawiarnie (Cafes):** Filiżanka kawy ze wznoszącą się parą
3. **Bary (Bars):** Kieliszek koktajlowy z plasterkiem limonki
4. **Puby (Pubs):** Kufel piwa z pianą
5. **Piekarnie (Bakeries):** Bochenek chleba / rogalik croissant
6. **Cukiernie (Pastry shops):** Porcja tortu / babeczka cupcake
7. **Lodziarnie (Ice cream shops):** Rożek z gałkami lodów
8. **Food trucki (Food trucks):** Furgonetka z markizą gastronomiczną
9. **Winiarnie (Wineries):** Butelka wina z kieliszkiem
10. **Browary (Breweries):** Kłos jęczmienia i kadź warzelna

### 3.2 Miejsca i Atrakcje (Deep Blue `#1565C0`)
11. **Duże miasta (Cities):** Trzy drapacze chmur o zróżnicowanej wysokości
12. **Małe miasteczka (Small towns):** Dwa kameralne domki z dwuspadowym dachem
13. **Wioski (Villages):** Chata wiejska z ogrodzeniem i drzewem
14. **Zabytki historyczne (Historical monuments):** Klasyczny cokół z obeliskiem
15. **Muzea (Museums):** Fronton antyczny z 4 kolumnami i tympanonem
16. **Zamki i pałace (Castles & palaces):** Wieża zamkowa z blankami (bramami)
17. **Kościoły i klasztory (Churches & monasteries):** Fasada kościelna ze strzelistą wieżą i dzwonnicą
18. **Ruiny (Ruins):** Przełamana kolumna rzymska ze spękaniem
19. **Pomniki i statuy (Monuments & statues):** Postać na cokole
20. **Miejsca pamięci (Historical sites):** Pamiątkowa płyta ze zniczem

### 3.3 Natura i Punkty Widokowe (Green `#2E7D32`)
21. **Punkty widokowe (Viewpoints):** Lornetka panoramiczna na statywie
22. **Góry i szczyty (Mountains & peaks):** Dwa ośnieżone szczyty górskie
23. **Wodospady (Waterfalls):** Półka skalna ze spadającymi kaskadami wody
24. **Jeziora (Lakes):** Tafla wody z trzcinami i zarysem brzegu
25. **Plaże (Beaches):** Parasol plażowy wkopany w piasek i fala
26. **Wyspy (Islands):** Piaszczysty atol z samotną palmą kokosową
27. **Parki narodowe (National parks):** Sylwetka jodły na tle wschodzącego słońca
28. **Rezerwaty przyrody (Nature reserves):** Liść dębu otoczony tarczą ochronną
29. **Jaskinie (Caves):** Łukowate wejście do groty ze stalaktytami
30. **Lasy (Forests):** Grupa trzech sosen i świerków
31. **Wąwozy i kaniony (Gorges & canyons):** Pęknięcie kanionu z wijącą się rzeką
32. **Źródła i rzeki (Springs & rivers):** Wijący się meander rzeczny z kropelkami

### 3.4 Aktywności i Sport (Purple `#7B1FA2`)
33. **Szlaki piesze (Hiking trails):** But trekkingowy / słupek ze szlakowskazem
34. **Trasy rowerowe (Cycling routes):** Sylwetka roweru górskiego
35. **Trasy motocyklowe (Motorcycle routes):** Kask motocyklowy i zakręt drogi
36. **Malownicze trasy samochodowe (Scenic drives):** Kamper / kabriolet na wijącej się serpentynie
37. **Kolejki linowe (Cable cars):** Wagonik kolejki gondolowej na linie
38. **Stoki narciarskie (Ski slopes):** Skrzyżowane narty z kijkami
39. **Kąpieliska (Swimming spots):** Pływak na falach wodnych
40. **Miejsca do nurkowania (Diving spots):** Maska do snorkelingu z rurką
41. **Pola biwakowe (Campsites):** Namiot typu igloo z wejściem
42. **Miejsca piknikowe (Picnic areas):** Drewniany stół piknikowy z ławami

### 3.5 Podróż i Infrastruktura (Slate `#455A64`)
43. **Hotele (Hotels):** Łóżko hotelowe z zagłówkiem i lampką
44. **Pensjonaty (Guesthouses):** Przytulny pensjonat B&B z dymiącym kominem
45. **Kempingi z parcelami (Camper parks):** Kamper podłączony do słupka mediów
46. **Parkingi (Parking lots):** Litera „P” z zadaszeniem
47. **Stacje paliw (Gas stations):** Dystrybutor paliwowy z wężem
48. **Stacje ładowania EV (EV stations):** Dystrybutor z wtyczką elektryczną i błyskawicą
49. **Lotniska (Airports):** Samolot pasażerski wznoszący się w powietrze
50. **Dworce kolejowe (Railway stations):** Front nowoczesnego pociągu
51. **Przystanie i mariny (Harbours & marinas):** Kotwica okrętowa z liną
52. **Terminale promowe (Ferry terminals):** Prom pasażersko-samochodowy na falach

### 3.6 Rozrywka i Kultura (Pink / Magenta `#C2185B`)
53. **Teatry (Theatres):** Maski teatralne (komedia i tragedia)
54. **Kina (Cinemas):** Pudełko popcornu i klaps filmowy
55. **Galerie sztuki (Art galleries):** Paleta malarska z pędzlem
56. **Sale koncertowe (Concert venues):** Gitara akustyczna i nuty muzyczne
57. **Festiwale i eventy (Festivals):** Scena z reflektorami i flagami
58. **Parki rozrywki (Amusement parks):** Koło młyńskie (diabelski młyn)
59. **Parki wodne (Water parks):** Zakręcona zjeżdżalnia wodna
60. **Ogrody zoologiczne (Zoos & aquariums):** Ślad łapy niedźwiedzia i ryba
61. **Ogrody botaniczne (Botanical gardens):** Egzotyczny kwiat monstery w donicy

### 3.7 Punkty Praktyczne (Turquoise `#00838F`)
62. **Sklepy spożywcze (Grocery stores):** Wózek sklepowy pełen produktów
63. **Apteki (Pharmacies):** Krzyż apteczny z laską Eskulapa
64. **Bankomaty (ATMs):** Terminal bankomatu z wysuwaną kartą płatniczą
65. **Toalety publiczne (Public toilets):** Piktogram WC (postać męska/damska)
66. **Informacja turystyczna (Tourist info):** Litera „i” wpisana w okrąg informacyjny
67. **Serwisy rowerowe (Bicycle repair):** Zębatka rowerowa ze skrzyżowanym kluczem
68. **Warsztaty samochodowe (Car repair):** Klucz francuski na tle koła samochodowego
69. **Pralnie samoobsługowe (Laundromats):** Pralka bębnowa z bańkami mydlanymi

---

## 4. Wytyczne Implementacji Jetpack Compose (Android)

```kotlin
// Przykład uniwersalnego komponentu MapPinMarker w Jetpack Compose
@Composable
fun MapPinMarker(
    category: LocationCategory,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val scale by animateFloatAsState(if (isSelected) 1.15f else 1.0f)
    val elevation = if (isSelected) 8.dp else 4.dp
    
    Box(
        modifier = modifier
            .scale(scale)
            .shadow(elevation, shape = PinShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        // Podkład pod pin (kontur łezki)
        Canvas(modifier = Modifier.size(width = 36.dp, height = 44.dp)) {
            drawPinBackground(
                fillColor = if (isSelected) category.selectedColor else category.primaryColor,
                strokeColor = if (isSelected) Color.White else Color.Transparent,
                strokeWidth = 3.dp.toPx()
            )
        }
        // Wektorowy symbol kategorii wyśrodkowany w główce pinu
        Icon(
            imageVector = category.icon,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier
                .padding(top = 2.dp)
                .size(20.dp)
        )
    }
}
```
