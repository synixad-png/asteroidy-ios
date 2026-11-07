# ASTEROIDY iOS v568 — audyt chwilowych spadków FPS po zimnym starcie iPada

**Data:** 07.11.2026. **Podstawa:** użytkownik potwierdził po optymalizacjach Explosion524 i ProjectileLight285, że natychmiast po uruchomieniu gry z ekranu głównego iPada trafienia potrafią obniżyć FPS; po odczekaniu około 2–3 minut gra utrzymuje **60 FPS także przy strzelaniu i trafieniach**. Podczas wcześniejszych spadków licznik pokazywał CPU całkowity ~1,9 ms, CPU SYM ~0,6 ms, CPU WAIT ~0,1 ms, GPU ~2,9 ms. Są to odczyty zgłoszone na urządzeniu, nie powtórzony test laboratoryjny.

## Co naprawdę potwierdza kod źródłowy

W `ASTEROIDYiOS/OriginalAudioAV568.swift`:
- `prepareMenuAtStartup()` jest wywoływane przy uruchomieniu aplikacji. Tworzy dwie oryginalne ścieżki muzyczne menu (0 i 1), po czym natychmiast generuje kolejnych **13 utworów** (`2..<15`) na workerze z `qos:.userInitiated`.
- W `OriginalMusicSynth568.generate` pojedynczy utwór składa się z **128 taktów** 44,1 kHz stereo. Występują wielomilionowe przebiegi po Float, konwolucyjny pogłos FFT (blok n=131072, hop=65536), mastering i duże zapisy WAV. Praca w tle może obciążać CPU, pamięć i I/O, nawet gdy czas pojedynczego callbacku Metal wynosi tylko ~2 ms.
- Istniał już `SourceBackgroundMusicGate568` z `setAllowed(false)` przy `beginMissionIntro568`, `enterMission` i aktywnej misji, lecz generator sprawdzał go głównie na progowych komunikatach statusu (aranżacja co 8 taktów, pogłos co 8 bloków). **Długie wewnętrzne pętle liczbowe nadal wykonywały pracę**, zanim dotarły do kolejnego punktu zatrzymania.
- Efekt ten jest zgodny z opisanym wzorcem rozgrzewania 2–3 min, lecz **nie jest jeszcze bezpośrednio zmierzoną przyczyną 15-FPS spadków**. Mogą współistnieć rozgrzewka Metal, alokacje efektów/rocków, I/O lub scheduling. Nie wolno mylić korelacji z dowodem.

## Zmiana — izolowana do prawidłowych modułów źródłowych

1. **`ASTEROIDYiOS/OriginalAudioAV568.swift`:** startupowe utwory menu 0 i 1 pozostają w niezmienionej ścieżce `.userInitiated`, aby nie opóźnić wejścia do W3. **Wyłącznie pozostałe 13** uruchamia się na osobnej kolejce `.utility`, co chroni pierwszeństwo animacji i wejść dotykowych. Pozostaje oryginalna numeracja/ścieżki muzyki, nadal tworzone w runtime, bez zmiany muzyki i dźwięków SFX. Generator otrzymuje `checkpoint` sprawdzający ten sam dotychczasowy gate przed kontynuacją CPU podczas misji.
2. **`ASTEROIDYiOS/OriginalMusicSynth568.swift`:** opcjonalny, domyślnie pusty `checkpoint:()->Void={}` wywoływany na bezpiecznych granicach utworu i bloków. Obejmuje każdy takt aranżacji, fazy mieszania/delay/sidechain (~16 384 próbek), convolution FFT **przed każdym blokiem** i długie filtry SOS, mastering (~16 384 próbek) oraz zapis WAV (~8192 próbek). Żadnych zmian równań, RNG, liczby próbek, parametrów generatora, liczby taktów czy brzmienia.
3. **`Tests/OriginalMusicSynth568Tests.swift`:** 5 oryginalnych aranżacji, deterministyczność, zawartość poprawnego WAV oraz NOWY test porównujący ścieżkę z checkpointami i bez — **bajtowo identyczny WAV** oraz wielokrotne wezwania checkpointów.
4. **`Tests/OriginalMusicCombatPause568Contract.py`:** zapewnia niezmienność pierwszych dwóch ścieżek, 13 pozostałych, QoS, gate w misji, 128 taktów/44.1 kHz i regularne checkpointy, bez zmian w kodzie misji, efektów, pocisków, planet i interfejsu.

## Potwierdzone wyniki GitHub Actions

[**Kontrola gałęzi #409**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408520112): **3/3 zadania PASS**, w tym natywna kompilacja iOS Swift/Metal na macOS i pełna macierz testów walki, pocisków, fizyki i misji.

Wyniki oryginalnego generatora:
- `PASS source music combat checkpoints: 67 waits, WAV byte parity` — dla próbki utworu z oddzielnego przebiegu z 67 kontrolami zatrzymania i przebiegu bez nich wynikowe pliki WAV były **identyczne bajtowo**.
- `PASS source music track 0, 1, 4, 7, 14` — oryginalne 44,1 kHz stereo WAV w pełnym pięcioutworowym teście.
- `PASS source synthesis, five arrangements, deterministic repeat`.
- `PASS 2 original startup menu tracks keep priority; 13 full source songs move to utility queue`.

Pełny build ARM64 IPA pozostaje osobną kontrolą; wyniki GPU/FPS na fizycznym urządzeniu nie były mierzone.

## Potwierdzenia wymagane przed zamknięciem

- Native Swift/Metal compile oraz testy grafiki/misji: kontrola `verify-combat-only.yml`.
- Native Swift `OriginalMusicSynth568Tests`: porównanie WAV z checkpointem i bez checkpointu musi być **identyczne bajtowo**.
- Pełne urządzeniowe Xcode iOS ARM64 IPA i sprawdzenie `Tools/verify_ipa.py`, CRC, zawartości `Payload`.
- **Fizyczny iPad/iPhone**: przy zimnym uruchomieniu spróbować serii trafień podczas pierwszych 2–3 minut oraz po 3 minutach, z `CPU`, `SYM`, `WAIT`, `FX CPU P/W`, `GPU ms` i FPS; bez tego nie twierdzić, że stutter jest definitywnie usunięty.

## Wynik wydania urządzeniowego

- [**GitHub Actions #137**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945096) — **4/4 PASS**. `xcodebuild Release -sdk iphoneos` **BUILD SUCCEEDED**, kompilator Apple Metal PASS.
- Commit dokładnie użyty do IPA: `99da170c8c2b5a5b5c2eee2b0bcb1cf62cd4fbc9`.
- [Artefakt IPA dla iPhone/iPad](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945096/artifacts/13589017064), nazwa `ASTEROIDY-iOS-device-unsigned-ipa`. Zewnętrzny ZIP GitHub: **27 999 687 bajtów**, SHA-256 **zewnętrznego ZIP**, nie wewnętrznego IPA: `0aa13e012d438b7a4109915b9a43831eb6578989f6a3e09f532099b669a05c42`. Niepodpisany plik w archiwum: `ASTEROIDY_iOS_UNSIGNED.ipa`.
- `unzip -t` i `Tools/verify_ipa.py` — **PASS**: `Payload`, `Info.plist`, architektura ARM64 dla urządzeń fizycznych, iPhone/iPad, iOS 17.0+, komplet zasobów, CRC. 43 oryginalne audio SFX/głosy/intro i brak nagranych utworów muzycznych w IPA; generacja 15 utworów w runtime zachowana.
- [**Natywne testy i pełna regresja walki #410**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945112) — **3/3 PASS**.
- Nadal nie przeprowadzono interaktywnej próby zimnego startu na iPadzie Pro ani iPhonie. Brak dowodu, że usunięto pełny spadek 15 FPS. Drugim potwierdzonym *mechanizmem mogącym powodować jednorazowe przycięcia* jest leniwe tworzenie nowych wariantów geometrii asteroid: w `Sector01CarbonisPreview568.swift` wczytuje się wstępnie tylko kształty początkowych asteroid, a kolejne `CarbonisRockGeometry568.vertices(shape:)` i `MTLBuffer` powstają przy pierwszym pojawieniu się nowego wariantu. Mechanizm nie był zmieniany w tym wydaniu, aby sprawdzić osobno efekt poprawki audio.

## Ryzyko i brak zmian

Gate jest kooperacyjny i zatrzymuje pracę między bezpiecznymi porcjami DSP; nie ingeruje w głos aktualnie odtwarzany, efekty trafień ani w szablon muzyki. Pamięć pośrednia częściowo zsyntetyzowanego utworu może pozostawać zajęta podczas wstrzymania — jest to osobny, mierzalny temat, nie powód do zmiany modelu audio bez testu. Nie poprawiono/nie pogorszono wydajności GPU bezpośrednio; celem jest usunięcie konkurencji obliczeniowej i nieprzewidzianych skoków FPS podczas fazy rozruchu.

**Status harmonogramu portu:** 18 niezmiennych zadań, 38% wykonane i 62% pozostało; ten wąski fix nie uzasadnia podwyższenia całości.
