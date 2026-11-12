# O01 — audyt bazowy PC v602 ↔ iOS: macierz procedur i rozbieżności

Data audytu: 2026-11-12. Obowiązujący, **niezmieniony** harmonogram: `Reports/PC602_IOS_H290_STALY_HARMONOGRAM_2026-11-12.md`, punkt **O01**. Gałąź `feature/ios-pc602-newhome-world-source` (PR #29), stan porównywany: commit `551dc5eb1de6830fe83771babddad9ecc761e7fd`. **W tym audycie nie zmieniono mechaniki ani zasobów aplikacji.**

## Tożsamość oryginału — bez substytutów

- Źródło: oryginalna paczka użytkownika `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, sprawdzona w lokalnym środowisku, SHA-256: `359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b`.
- Referencja zawsze: **`Windows/src/` z PC v602**. Nie wolno przyjmować starszego v580/v568 ani gałęzi SteamOS za równoważne źródło bez udowodnienia identyczności bajtowej.
- Niezależnie policzone SHA-256 istotnych plików C#: `HomeFlight291.cs` = `7c26c62fc8010064f419512e83ce7b61e94cff8764d92cf595675c39d02a61d5`; `Orbit50.cs` = `8154038327fd78129cd8678bc482103f78bfa5e5c9756b344790cdba73aee5de`; `SphereCombat67.cs` = `c7bed25e62a06f4ef5d20ed9d1dc3fd0791780ec1dbe9746d40635904675e0be`; `Game.cs` = `34fd8b2877f5784a68ad7b2a7d31d59f506d3254a499c9124e720958f6e651ea`; `SaveManager61.cs` = `79e8162cae1966fb0c593f7c9bc666d7735965d650e855c4b1d2afb123b745e3`; `Hub90.cs` = `a908a3632d22fab0932798405e0d0faff39334e2f1298d9e2d607d5b42587a4d`.
- Pełny zestaw 19 oryginalnych odcisków źródeł, weryfikowanych wyłącznie gdy oryginalny ZIP jest dostępny: `Tests/PC602O01SourceBaseline.py`. **CI pozbawione ZIP nie może twierdzić, że niezależnie odczytało oryginalne źródło PC.**

## Weryfikacja aktywnej ścieżki gry

PC v602 `Game.Step` w `Game.cs`, tryb `Mode.Orbit` → `Orbit50.cs:94` `StepOrbit50`. W `NewHome290.Enabled` natychmiast wywoływane jest `HomeFlight291.cs:25` `StepHomeFlight291`:
1. `SphereCombat67.cs:64–90` `DirectFlight67`;
2. `SphereCombat67.cs:61` `MoveShip67`;
3. `SphereCombat67.cs:62` `UpdateSphereCamera67`;
4. przeliczenie pozycji, wysokości, stanu lotu, celu i odległości;
5. `HomeFlight291.cs:55–61` `StepHomeWeaponTest292`.

Aktualny iOS wykonuje `PC602HomeWorldSession291.swift:63–78` → `PC602HomeFlight291.step` → `PC602HomeWeaponTest292.step`, ale to **nie dowodzi identycznych wyników liczbowych** z procedurami PC. Stary `OrbitWorld51.Move51` nie jest aktywną gałęzią fizyki na H290 w PC v602; nie dodawać kolizji asteroid na podstawie tego pliku. `HomeFlight291.cs:62` jawnie zabrania symulacji przeciwników, trafień, nagród i zaliczania misji na H290.

## Macierz źródło PC → port iOS, fakty i dowody

Kolumna „wniosek” rozróżnia: **ZGODNE STATYCZNIE** (zidentyfikowany oryginalny warunek/wzór), **ROZBIEŻNOŚĆ** (konkretne odmienne zachowanie w źródłach), **NIEZWERYFIKOWANE** (brak porównawczego wyniku). „Zgodne statycznie” nie oznacza zatwierdzenia obrazu/fizyki na iPhonie.

| Obszar O01 | PC v602 — plik i rzeczywista procedura | iOS — aktywne miejsce | Wniosek / dowód |
|---|---|---|---|
| Wejście na orbitę | `Orbit50.cs:46–49` `EnterOrbit50` czyści walkę, zeruje szybkość i przywraca `InitializeHomeFlight291` | `PC602HomeWorldDriver291.start`, `PC602HomeFlight291.init/resetToTarget` | **NIEZWERYFIKOWANE**: semantyka czyszczenia wszystkich stanów PC nie jest jeszcze odtworzona testem porównawczym |
| Ruch i kamera | `HomeFlight291.cs:25–50`; `SphereCombat67.cs:61–64`, kolejność DirectFlight→MoveShip→UpdateSphereCamera | `PC602HomeWorldSession291.advance`; `PC602HomeFlight291.step` | **ZGODNE STATYCZNIE** co do ścieżki i kolejności głównych działań; fizyczna trajektoria PC↔iOS NIEZWERYFIKOWANA |
| Konfiguracja VANGUARDA | `Campaign37.cs` + `Modules97.cs`; `SphereCombat67.cs:67–89` używa aktualnych parametrów statku | `PC602HomeWorldDriver291.start` tworzy `Equipment(craft:.vanguard)` bez poziomów, choć `H55SourceMechanics580.State` przechowuje `engine`/`thruster`/`stabilizer` | **ROZBIEŻNOŚĆ — O02**: ulepszenia nie są przekazywane do aktualnej konfiguracji lotu H290 |
| Strzelnica | `HomeFlight291.cs:55–62`: realny `Game.Fire()`, tymczasowe zachowanie `Shots` i `IonAmmo`, geodezyjne pociski, zero nagród | `PC602HomeWorldSession291.swift:72–76` + `PC602HomeWeaponTest292.swift` | **ROZBIEŻNOŚĆ — O03**: iOS odtwarza salwy, ale nie wykonuje pełnego kodu `Fire()` z tymczasowym stanem amunicji jonowej |
| Zakaz sztucznych walk H290 | `HomeFlight291.cs:62` jednoznacznie nie symuluje wrogów, asteroid, nagród i ukończeń | `PC602HomeWeaponTest292.swift:3–7` bez trafień/nagród | **ZGODNE STATYCZNIE**; nie implementować obcej mechaniki |
| Oświetlenie słoneczne | `Orbit50.cs:22–24` `SunDirection111`: kąt `0.62+max(0,time)*0.047`, y `0.25+sin(angle*0.33)*0.13`; `PlanetLife52.cs:19–29` | `PC602HomeScene291.swift:243–249` analogiczny wzór i wektor światła | **ZGODNE STATYCZNIE** co do wzoru kierunku, nie zmieniać bez udokumentowanego błędu; zgodność oświetlenia GPU NIEZWERYFIKOWANA |
| Gwiazdy i tło | `GpuIntro41.cs:451–454` `IntroSky(glow,nebula,rays,true)`, 1500 gwiazd na promieniu 900 | `SourceCombatSky568.swift` + `PC602HomeScene291.swift:255–264`, przekazywana rzeczywista kamera i skala | **NIEZWERYFIKOWANE — O04**: użytkownik wcześniej zgłosił brak gwiazd; naprawa skali w kodzie nie potwierdza widoczności na urządzeniu |
| Opcje nieba | `HomeFlight291.cs:106,113` jawnie przyjmuje `glow`/`nebula`/`rays` | `PC602HomeScene291.swift:258–263` nie przekazuje wszystkich opcji do `originalSky.draw` (domyślne `true`) i odczytuje `glowEnabled` podczas `init` | **ROZBIEŻNOŚĆ — O04**: część ustawień grafiki nie wpływa na H290 tak jak na PC |
| Atmosfera, pociski, pas, wrak | `HomeFlight291.cs:106–125`, ustalona kolejność przejść | `PC602HomeScene291.swift`, `PC602HomeAtmosphere47.swift`, `PC602HomeProjectileLights296.swift`, `PC602OrbitBelt51.swift`, `SourceHomeWreck209.swift` | **NIEZWERYFIKOWANE — O04**: w portcie są moduły, ale brak pełnego porównania renderu i wydajności z PC |
| Dodatkowe działka VANGUARDA | `GunMesh101.cs:121–123`: `DrawCraftModules95` NIE rysuje dla `CraftType==1` | `SourceHomeVanguard431.swift`, brak doklejania zewnętrznych działek | **ZGODNE STATYCZNIE**: nie dodawać działek |
| Atlas i OPCJE | `Orbit50.cs:89–93` `OrbitEntryMission56`, `CycleOrbitTarget51` i hit-test atlasu; PC HUD nawigacyjny | `PC602OrbitHud330.swift`, `PC602HomeWorldPage291.swift`, `App.swift` | **NIEZWERYFIKOWANE — O05**: osobna dotykowa implementacja, krytyczne testy prawdziwych dotknięć/W3 nieprzeprowadzone |
| Dokowanie — warunek | `Hub90.cs:34–48`, realny wrak, odległość ≤43.2 m i stan trybu | `PC602HomeFlight291.canDock90` + `PC602HomeHubRoute90.enterFromOrbit` | **ZGODNE STATYCZNIE** co do ograniczeń, bez przejścia E2E na fizycznym iPhonie |
| Powrót z H55 | `Hub90.cs:57–65` `ExitHub90` zeruje `OrbitSpeed50`/`OrbitVelocity51`, zapisuje profil/talenty | `PC602HomeWorldSession291.finishPhysicalH55Visit` jedynie `route.exitHangar()`; `driver.exitH55` odświeża broń | **ROZBIEŻNOŚĆ — O06**: w aktywnej sesji iOS nie ma źródłowego zerowania prędkości po wyjściu z H55 |
| Start misji 01 | `Orbit50.cs:53–76` `LaunchOrbitMission50`/`StartHubMission261` resetuje stan i uruchamia prawdziwe `Wave()` i `BeginLevelIntro()` | `App.enterOrbitMission291`, `inspectSourceSector`, `beginMissionIntro568`, `Sector01Scene568` | **NIEZWERYFIKOWANE — O07/O08**: ścieżka jest podłączona, ale brak kompletnego testu PC↔iOS stanu każdej fazy |
| Powrót po misji do orbity | `Game.cs:114` `Continue()` dla `PlanetHub50 && HubMission50` wywołuje `EnterOrbit50()` z czyszczeniem walki | `App.swift:244–260` wywołuje `homeWorld291.refreshCampaign(campaign)` na zachowanej sesji H290 | **ROZBIEŻNOŚĆ — O07**: brak pełnej procedury `EnterOrbit50` po serwisie/wyjściu |
| Świadome wyjście z misji do W3 | `Game.cs:115` `ReturnToMenu()` zapisuje checkpoint/profil, czyści aktywną walkę i zmienia tryb | `Sector01Scene568.exitMission568` → `App.onExitToMainMenu` | **NIEZWERYFIKOWANE — O07**: rozdzielono callbacki W3/orbita, ale nie udowodniono identycznej semantyki resetów PC |
| CARBONIS 01: zdarzenia walki | `Game.cs` + `Physics68.cs` + `Wave`/`FinishLevel`/`Shop` | `Sector01Scene568.swift` i aktywny `CarbonisSession568` | **NIEZWERYFIKOWANE — O08**: brak pełnego porównania deterministycznego jedynej grywalnej misji |
| Struktura zapisów | `SaveManager61.cs:38–46`: tekstowy format `ASTEROIDY-SAVE-369` w `slot1..3.sav`, 17 pól `meta`, 11 pól orbity, shop/talenty/moduły/tarcza, SHA256 | `PC602OrbitSave61.swift:15–28,84–118`: własny JSON i mniejszy zestaw pól | **ROZBIEŻNOŚĆ — O09**: różne pola i format. PC `.sav` jest tekstowy, nie binarny. Nie zakładać zgodności zapisów |
| Zapisy w misji i kasowanie | `SaveManager61.cs:44–46,86–99`: checkpoint, zapis w misji, `DeleteSlot61`, potwierdzanie nadpisania/usunięcia | `PC602OrbitSave61.swift` i `PC602HomeWorldPage291.swift`: sloty orbity, bez kasowania i potwierdzenia | **ROZBIEŻNOŚĆ — O09** |
| Audio | `MusicAudio.cs`/`MusicSynth.cs` + wywołania w `Game.cs` i `Renderer.cs` | `OriginalAudioAV568.swift`; natywne AVFoundation | **NIEZWERYFIKOWANE — O10**: nie wykonano pełnego porównania przejść i wyjścia PCM do PC v602 |
| Wydanie i test E2E | PC referencyjny Windows; rzeczywisty H290/H55/Carbonis01 | skrypty `.github/workflows` i testy `Tests` | **NIEZWERYFIKOWANE — O11/O12**: test kompilacji i kontrakt nie zastępuje testu gry i GPU na urządzeniu |

## Granice zakresu, których nie wolno rozszerzyć

- **Wyłącznie grywalna CARBONIS 01 i VANGUARD.** Markery 02–26 zachowują autentyczne dane atlasu, ale nie uruchamiają nieistniejących portów.
- **H55 H01–H16** ma osobny zamrożony harmonogram i nie wolno zmieniać jego wewnętrznych mechanizmów na podstawie oceny O01.
- O01 NIE upoważnia do przepisywania oryginalnych wywołań losowo: następny **O02** obejmuje tylko rozbieżności lotu VANGUARDA udowodnione przez źródła (konfiguracja silnika/dysz/stabilizatora i pomiary trajektorii), bez resetów O06/O07, zapisów O09 ani poprawek nieba O04 w tym etapie.

## Stan O01 i warunki dalszego przejścia

**O01: porównanie źródeł i mapowanie aktywnych ścieżek — WYKONANE; brak porównawczego testu liczbowego PC↔iOS oznacza, że nie wolno ogłosić zgodności mechaniki ani zamknąć etapów O02–O10.** Skontrolowano dokładny ZIP v602 i odciski plików C# oraz odpowiadające aktywne moduły Swift/Metal z przypisaniem konkretnych procedur. Macierz odróżnia rozbieżności od rzeczy niezweryfikowanych. Test regresyjny tożsamości źródeł: `Tests/PC602O01SourceBaseline.py`; w CI przy braku oryginalnego ZIP wymaga jawnego oznaczenia, że potwierdzono tylko iOS, nie pełną zgodność.

**Status harmonogramu O01–O12 pozostaje w tej samej kolejności i zakresie**:
| ID | Zadanie | Stan | Co faktycznie zmieniono | Dowód testu / blokada |
|---|---|---|---|---|
| O01 | Audyt bazowy PC v602 ↔ obecny port | **W TOKU DO ODBIORU** | Ta macierz i odciski źródeł; bez zmian mechaniki | ZIP i źródła skontrolowane; test narzędzia/CI do odnotowania |
| O02 | Lot i sterowanie VANGUARDA na H290 | W TOKU (stary kod) | Bez zmian w O01 | brak pomiarów PC↔iOS |
| O03 | Strzelnica H290 i uzbrojenie VANGUARDA | W TOKU (stary kod) | Bez zmian w O01 | rozbieżność jonów |
| O04 | Oryginalny świat H290 | W TOKU (stary kod) | Bez zmian w O01 | niepełne opcje nieba; brak testu GPU |
| O05 | HUD H290, atlas, pauza i OPCJE | W TOKU (stary kod) | Bez zmian w O01 | test dotykowy oczekuje |
| O06 | Dokowanie i rzeczywisty powrót H290 ↔ H55 | W TOKU (stary kod) | Bez zmian w O01 | reset prędkości różni się |
| O07 | Przejścia orbita ↔ CARBONIS 01 ↔ W3 | W TOKU (stary kod) | Bez zmian w O01 | reset po misji różni się |
| O08 | Zgodność rozgrywki CARBONIS 01 | W TOKU (stary kod) | Bez zmian w O01 | brak pełnego E2E PC↔iOS |
| O09 | Zapisy i kontynuacja gry | W TOKU (stary kod) | Bez zmian w O01 | różne pola i zachowania |
| O10 | Oryginalne audio | W TOKU (stary kod) | Bez zmian w O01 | porównanie PCM nieukończone |
| O11 | Regresja integracyjna i ochrona zatwierdzonych systemów | NIE ROZPOCZĘTE W ZAKRESIE O11 | Bez zmian | końcowe E2E |
| O12 | Odbiór wydania iOS / IPA | NIE ROZPOCZĘTE W ZAKRESIE O12 | Bez zmian | odbiór na urządzeniu |

Następna dozwolona praca: zakończyć odbiór źródłowego O01; po jego zamknięciu przejść do O02 w niezmienionej kolejności.
