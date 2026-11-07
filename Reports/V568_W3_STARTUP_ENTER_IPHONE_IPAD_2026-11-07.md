# ASTEROIDY iOS — oryginalny ekran startowy Windows W3 po generowaniu muzyki
Data: 07.11.2026

## Podstawa źródłowa
- `Windows/src/Program.cs:91,94`: najpierw oryginalne `CombatSound.Prepare` i `MusicBank.Prepare`; gdy `preparingMusic` jest aktywne, ekran startowy nie przyjmuje poleceń.
- `Windows/src/Program.cs:120-123`: w trybie W3 logo wymaga Enter/Space; bez automatycznego timeoutu (legacy 4.4 s jest tylko przy starym menu).
- `Windows/src/Program.cs:227,263`: click LPM i przycisk A lub Start pada.
- `Windows/src/ProgramW3Native315.cs:26-30`: `SkipW3Startup327` tworzy animację `splash -> home`, resetuje klawisze.
- `Windows/src/UiW3NativeLayout315.cs:455-470`: źródłowe napisy/logo na współdzielonym tle i pasek statusu.
- `Windows/src/UiW3NativeLayout315.cs:82-123`: zasłona 1,25 s, krycie 36% / odkrywanie 64%; natywna geometria zamiast HTML.

## Dokładny zakres implementacji
1. `W3StartupPolicy568.swift`: czysty kontrakt fazy audio/splash/menu; tylko jawny Enter/space/touch/gamepad A/Start; brak automatycznego timeoutu; diagnostyka ma osobną bramkę.
2. `W3StartupSplash568.swift`: natywny SwiftUI, tylko jedno współdzielone tło/logo `SourceW3Images568.pair` SHA-verified, oryginalne napisy/pulsowanie, focus klawiatury, dotknięcie całego ekranu, A/Start poprzez GameController, zasłona 0.45+0.80 s i blokada wielokrotnego wejścia.
3. `App.swift`: zachowany `OriginalAudioLoadingView568` aż `audio.startupComplete`; W3 HOME zablokowany na czas bramki i całego przejścia; tylko normalny pierwszy start, nie powrót z CARBONIS 01; testy renderowania nadal mogą użyć jawnych flag diagnostycznych.
4. `W3MainMenu568.swift`: nie usuwać pierwotnych assetów, tylko udostępnić współdzielone obrazy ekranowi splash.
5. `Tests/W3StartupPolicy568Tests.swift`, `Tests/W3StartupContract568.py`, `W3MenuUITests/W3StartupSplashUITests.swift`, aktualizacja istniejącego `W3NewGameUITests.swift` i odpowiednich workflow.
6. Nie zmieniano `OriginalMusicSynth568`, `OriginalAudioAV568`, `Sector01CarbonisPreview568`, kodu CARBONIS i fizyki ani plików modeli/tekstur.

## Wyniki
- Źródła: 6ed2ed0cf29216ad56b395f5e448569f09a8f6f0, poprawka błędów Swift 6e5e8aba975eb1064a15a911e02a90986a9386c9; wydanie na podstawie d53722495e184af13a552b1e1f6e700836a7bbfb.
- Apple/Xcode 16.4 iOS ARM64/iPhone/iPad: https://github.com/synixad-png/asteroidy-ios/actions/runs/42362411634 — wszystkie jobs SUCCESS.
- Artefakt: https://github.com/synixad-png/asteroidy-ios/actions/runs/42362411634/artifacts/13570810784; `ASTEROIDY_iOS_UNSIGNED.ipa` 28 379 641 bajtów.
- SHA256 IPA: `f395f4e32fbe9709e7e8df3762853b04fbd85ded8c904bffa588a0bf9c3d5ea4` — porównano z załączonym raportem, CRC ZIP/IPA PASS.
- Architektura ARM64, iPhone i iPad, iOS17+, pakiet com.synixad.asteroidyios.
- Interaktywne testy iPhone+iPad: https://github.com/synixad-png/asteroidy-ios/actions/runs/42362578089 — należy sprawdzić zakończony wynik przed wpisaniem PASS. Fizycznego urządzenia nie sprawdzano. Nie należy mylić nieudanego testu środowiska simctl z błędem aplikacji.
- Wydanie jest niepodpisane i wymaga podpisu do instalacji.

## Stały harmonogram 18 zadań
Port 38% wykonano / 62% pozostaje. Tylko 14. zadanie: 24% -> 25% (+1 pp); inne bez zmian. Źródłowy splash gotowy w kodzie i kompilacji, lecz pełne 44 ekrany W3 i ich finalna zgodność nadal nieukończone.

| Nr | Stałe zadanie harmonogramu | Wykonano | Zmiana |
|---:|---|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 32% | 0 pp |
| 5 | Animacje modeli GLB | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 43% | 0 pp |
| 7 | Kolizje, obrażenia i zniszczenia | 100% | 0 pp |
| 8 | Asteroidy i fale walki | 100% | 0 pp |
| 9 | Bronie i trafienia | 24% | 0 pp |
| 10 | Przeciwnicy i AI | 11% | 0 pp |
| 11 | Bossowie i ich mechaniki | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 30% | 0 pp |
| 13 | Kampania — 26 sektorów atlasu | 37% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 25% | +1 pp |
| 15 | Dźwięki i muzyka | 60% | 0 pp |
| 16 | Zapisywanie i wczytywanie gry | 32% | 0 pp |
| 17 | Sterowanie | 41% | 0 pp |
| 18 | Optymalizacja i testy | 18% | 0 pp |

## Następny obszar
Dalszy punkt 14: źródłowa obsługa pozostałych ekranów W3, zachowanie pełnej kampanii i urządzeniowa weryfikacja, bez regresji obecnego startu i audio.
