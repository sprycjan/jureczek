---
tags: [jureczek, srodowisko]
---
# Środowisko dev

## Narzędzia (stan na 2026-10-25)
- macOS na Intelu (i7-1068NG7). Emulator x86_64 działa, ale wolno: Vulkan przez SwiftShader.
- Flutter 3.41.6 / Dart 3.11.4.
- Android Studio + SDK (platformy 31–36.1, build-tools do 37). AVD: **`Pixel_8`**.
- JDK: Flutter używa JDK z Android Studio (`/Applications/Android Studio.app/Contents/jbr`, **Java 25**). Systemowa `java` nie jest zainstalowana.
- `adb` nie jest w PATH: `~/Library/Android/sdk/platform-tools/adb`. Warto dodać do PATH.

## Telefon przez adb – przydatne
- **Testy ręczne robimy na telefonie** (Huawei P30). Emulator `Pixel_8` na Macu z Intelem jest zbyt wolny (debug build startuje kilka minut).
- Gdy podłączone jest kilka urządzeń: `export ANDROID_SERIAL=<id>` (w zsh `ADB="adb -s X"` w zmiennej nie zadziała, bo zsh nie dzieli słów).
- ⚠️ APK zbudowany przez `flutter run` na emulator ma tylko `x86_64`. Na telefonie (arm64) taki APK pada przy starcie (`Could not find 'libflutter.so'`). Na telefon zawsze buduj przez `flutter run -d <telefon>`.
- Gesty: długie przytrzymanie to `input swipe x y x y 1200`, a tapnięcie to `input tap x y`. Tekst: `input text "Bilety%sonline"` (`%s` = spacja, bez polskich znaków).
- Podgląd bazy (debug build): `adb exec-out run-as pl.mc.jureczek cat app_flutter/jureczek.sqlite > j.sqlite`, potem `sqlite3 j.sqlite`.
- Zgoda na lokalizację bez klikania: `adb shell pm grant pl.mc.jureczek android.permission.ACCESS_FINE_LOCATION` (i `…COARSE…`). `pm revoke` zabija aplikację.
- ⚠️ „Wstecz” na ekranie startowym zamyka aplikację – kolejne gesty trafiają w pulpit telefonu. Powrót: `adb shell monkey -p pl.mc.jureczek -c android.intent.category.LAUNCHER 1`.
- Kopia bazy przed instalacją nowej wersji (pinezki już znikały): polecenie z „Podgląd bazy” do pliku poza repo.
- Test migracji na urządzeniu: zbuduj lokalnie bazę w starym schemacie (`sqlite3`, `PRAGMA user_version = N`), `adb push` do `/data/local/tmp`, a potem `run-as pl.mc.jureczek cp` do `app_flutter/jureczek.sqlite` przy zatrzymanej aplikacji.
- Wersja `--profile` na telefon bez `flutter run`: `flutter build apk --profile --target-platform android-arm64 --dart-define-from-file=env/dev.json`, potem `adb install -r build/app/outputs/flutter-apk/app-profile.apk`. `flutter run --no-resident ... | tail` potrafił wisieć ponad godzinę bez nowej wersji; zawartość APK można sprawdzić przez `unzip -p`.
- Huawei nie ma `screenrecord`, a Flutter nie trafia do `gfxinfo`. Przebieg animacji sprawdzamy serią `adb exec-out screencap -p`, a czasy klatek przez `FrameTiming` w trybie `--profile`.
- Ekran powitalny: grafiki `python3 -I tool/splash_art.py assets/splash --preview <katalog>` (podgląd w Chrome), a arkusz pierwszych kadrów to `--sheet <katalog> [all|sceny,po,przecinku] [pory,po,przecinku]`. Podgląd na telefonie to `lib/dev/splash_main.dart`: stuknięcie zmienia porę dnia, długie przytrzymanie scenę, w logu są czasy klatek. Zob. [[v24 – ekran powitalny]].
- Obrót przez adb: `settings put system accelerometer_rotation 0`, potem `settings put system user_rotation 1` (0 to pion). Po teście przywrócić `accelerometer_rotation 1` i `user_rotation 0`.
- Płynność prawdziwej aplikacji: tymczasowy `SchedulerBinding.instance.addTimingsCallback` w `main.dart` i kilka razy `am force-stop` + `monkey`. Pierwszy start po `adb install` odrzucić: ma przerwę około 900 ms niezależnie od kodu. Log wypisywać z `Timer`, bo po zniknięciu animacji nie ma już klatek i callback nie wraca. Nieudany `flutter build` zostawia stary APK, a `adb install` i tak zgłosi `Success`, więc wynik builda trzeba sprawdzić.

## ⚠️ Pułapka: Gradle vs Java 25
`flutter create` generuje Gradle 8.14, który nie działa z Java 25 (build kończy się błędem „What went wrong: 25.0.3”). Rozwiązanie: w `app/android/gradle/wrapper/gradle-wrapper.properties` ustawić `gradle-9.1.0-all.zip`. AGP 8.11.1 i Kotlin 2.2.20 działają z nim bez zmian. Pierwszy build trwa ~7 min (pobieranie Gradle i Mapbox SDK).

## Uruchomienie
```bash
cd app
cp env/dev.example.json env/dev.json   # wpisz swój token pk.…
flutter emulators --launch Pixel_8      # albo telefon przez USB z debugowaniem
flutter run --dart-define-from-file=env/dev.json
```
Bez `--dart-define-from-file` aplikacja pokaże komunikat „Brak tokenu Mapbox”.

Galeria ikon miejsc (v15, osobny punkt wejścia, podmienia aplikację na telefonie – potem wgrać zwykłą):
```bash
flutter run -d <telefon> -t lib/dev/place_icons_main.dart --dart-define-from-file=env/dev.json
python3 -I tool/place_icons.py assets/place_icons [podglad.html]   # po zmianie symboli
```

## Jakość
```bash
flutter analyze   # 0 issues
flutter test      # repozytorium i kontroler (drift in-memory), arkusz pinezki, ekran bez tokenu
flutter gen-l10n  # po zmianie plików ARB (robi się też automatycznie przy build)
dart run build_runner build   # po zmianie tabel drift (generuje *.g.dart), ~1 min za pierwszym razem
```

- Na macOS nie ma komendy `timeout`. Żeby wiszący test kończył się błędem, używaj `flutter test --timeout 30s`.
- Riverpod 3 wstrzymuje providery bez słuchaczy, więc w testach `container.read(streamProvider.future)` może wisieć w nieskończoność. Najpierw `container.listen(provider, (_, _) {})`, potem `pumpEventQueue()` i `read(provider).requireValue`.

## Context7 / Node
- Reguła: dokumentację bibliotek sprawdzamy przez `npx ctx7@latest` (library → docs).
- 2026-10-25: Homebrew-owy Node był zepsuty (brak `libsimdjson.33.dylib`). Po `brew reinstall node` wymaga jeszcze `brew link node`.
- Awaryjnie działa HTTP API: `curl "https://context7.com/api/v2/context?libraryId=/mapbox/mapbox-maps-flutter&query=...&type=txt"`.

## Claude Code (od 2026-10-26)
- `CLAUDE.md` w katalogu głównym projektu wczytuje się na starcie każdej sesji. Zawiera komendy, pułapki, reguły i mapę tego vaulta: najpierw przegląd i najnowsza wersja, reszta na żądanie.
- Skill `/vault-update` (`.claude/skills/vault-update/`) dokumentuje zmianę w vaulcie: notatkę wersji, ADR, roadmapę, Backlog i notatki techniczne.
- Skill `/make-it-better [kierunek]` (globalny, `~/.claude/skills/make-it-better/`, poza repo) sam wybiera jedną odważną zmianę, robi krótki research w sieci i dowozi zmianę na gałęzi `make-it-better/*`. Do `main` trafia dopiero po teście na telefonie i werdykcie „merguj”; pozostałe werdykty to „popraw” i „porzuć”. Historia uruchomień jest w `~/.claude/make-it-better/jureczek.md`. Co 5. uruchomienie to porządki w kodzie bez wzrostu liczby linii. Uruchamiany tylko ręcznie, serie przez `/loop` na jednej gałęzi.
- Hook w `.claude/settings.json` po każdym Write/Edit pliku `.dart` uruchamia `dart format`.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-003 Token Mapbox]]
