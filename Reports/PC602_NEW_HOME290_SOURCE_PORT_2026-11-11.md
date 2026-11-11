# ASTEROIDY iOS — główna planeta PC v602 (NewHome290)

Data: 2026-11-11
Baza prac: `feature/ios-h55-v580-native-entry` / commit `f8cd258387c1ec6765d763287a217193ef2a19d3`.
Nowa odizolowana gałąź: `feature/ios-pc602-newhome-world-source`.
Oryginał dostarczony przez użytkownika: `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, SHA256 `359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b`.

## Cel i granice

"Planeta główna" oznacza świat orbitalny NEW HOME, a NIE małe planetarium HUD i NIE planetę bojową CARBONIS/C279. Wersja PC v602 korzysta z oryginalnego `NewHome290` (siatka GLB pochodzenia H290), `HomeFlight291` (źródłowy geodezyjny lot jak w misji 1), oryginalnego atlasu 26 poziomów, pasa asteroid, wraku/dokowania i powrotu do hangaru. W3 HOME posiada dodatkowo odrębny podgląd tej samej planety.

Zasada: żadnych kul proceduralnych, wymyślonych siatek, zastępczych modeli, atrap przycisków, przerabiania fizyki C279 na ślepo lub nowych wymyślonych planet. Dla brakujących funkcji pozostawić status NIEUKOŃCZONE.

## Zweryfikowane pliki źródłowe PC v602

- `Windows/src/NewHome290.cs`: `01a402967eee017a9e1d1fc526b974969c3055f5aea1904eab6140a002950500`
- `Windows/src/GpuNewHome290.cs`: `12e793211514ad7224f8628bbe3c79a07ae9de8354123ea4c7d6183082f5b256`
- `Windows/src/HomeFlight291.cs`: `7c26c62fc8010064f419512e83ce7b61e94cff8764d92cf595675c39d02a61d5`
- `Windows/src/SphereCombat67.cs`: `c7bed25e62a06f4ef5d20ed9d1dc3fd0791780ec1dbe9746d40635904675e0be`
- `Windows/src/FlightDynamics298.cs`: `111420ecfa889d360bc5557a56b3be8cab1846ed54fa6f30184da78b9a1e5fd0`
- `Windows/src/Orbit50.cs`: `8154038327fd78129cd8678bc482103f78bfa5e5c9756b344790cdba73aee5de`
- `Windows/src/OrbitWorld51.cs`: `eb11e470fede861365143b1d11c74aacafa728f73f2092d4ab2f43ba756d276b`
- `Windows/src/GpuW3HomeReal333.cs`: `839f1bd3ac42632d72208671ae336859144e0ef0564365dedb241d68e3d5a065`

Oryginalne źródła `home290.mesh.gz` (`025a3ad6...`), `home290.texture.jpg` (`4987f35c...`) i `home293.glow.png` (`6f1debd1...`) są BYTE-IDENTYCZNE w paczce v602 i czterech audytowanych archiwach v568 już przechowywanych na GitHubie. Nie kopiujemy ich ponownie, nie tworzymy zamienników i nie zakładamy podobieństwa bez SHA. Wszystkie wymagane do dotychczasowego etapu źródłowe zasoby można odtworzyć z GitHub przy użyciu `Tools/stage_pc602_newhome290.py`, bez pobierania pliku ZIP v602 z czatu.

## Wdrożony, zweryfikowany zakres

1. Deterministyczne przygotowanie dokładnej geometrii H290: 172 208 oryginalnych trójkątów, dwie grupy materiałowe, bazowy JPEG, lawowa mapa GLOW i pełna oryginalna fizyczna mapa wysokości 512×256. Wysokości źródłowe nie są geometrycznie rekonstruowane z punktów.
2. Nowy `ASTEROIDYiOS/PC602NewHome290.swift` zawiera `NewHome290.HeightAt` (equirectangular + 100x + bilinear), `SpawnPosition`, `SafePosition`, `OrbitWorld50.Beacon(1...26)`, `NewHome290.WreckPosition`, `OrbitWorld51.SurfaceDistance51` i `MissionArea51`, bez błędnych danych zastępczych.
3. Tests `PC602NewHome290Tests.swift`: 7 źródłowych wysokości z prawdziwej mapy, sektory 1/9/17/25/26, autorski wrak, spawn, przejścia warunków misji, odrzucenie błędnych danych.
4. `.github/workflows/verify-pc602-newhome290.yml`: macOS, weryfikacja 4 oryginalnych ZIP v568 z GitHub, SHA gotowych zasobów, realny kompilator Swift i wykonywalny test oryginalnych wartości. Wynik widoczny w GitHub Actions.

## NIEUKOŃCZONE — nie deklarować dostępności planety w grze

- Runtime aktywnego świata i jego interaktywny ekran: implementacja `PC602HomeFlight291.swift` istnieje i ma testy autonomicznej fizyki, ale nie jest jeszcze połączona z rzeczywistym trybem gry; oryginalny `Ram71` i kolizje pasa pozostają niewdrożone;
- natywne Metal `HomeScene291` dla pełnego świata, nie mylić z działającym W3 podglądem planety;
- 820 asteroid oryginalnego pasa (wraz z fizyką), wrak i jego źródłowa geometria, oświetlenie pocisków, statek/strzały w trybie niebojowym;
- prawdziwe aktywne markery 26 sektorów, wybór/odblokowania i lot do misji;
- przejście NOWA GRA → planeta główna zamiast obecnego skrótu do CARBONIS, dopiero po źródłowym runtime;
- oryginalne dokowanie, H55, zapisy profili i regresja na iPhone/iPad;
- pełny rzeczywisty build Release IPA z nowym grywalnym światem i test sprzętowy.

Nie wolno podmieniać przycisku NOWA GRA, dopóki kompletna ścieżka źródłowego lotu, misji i hangaru nie jest gotowa. Poprzednie źródłowe mechanizmy W3/H55/C279/HUD są na bazowej gałęzi nienaruszone.

## Etap 2 — HomeFlight291, zweryfikowana fizyka i kamera

- Nowy `ASTEROIDYiOS/PC602HomeFlight291.swift`: źródłowe `EnterOrbit50(reset:true)` + `InitializeHomeFlight291`, `StepHomeFlight291`, `DirectFlight67`, `MoveShip67`, `UpdateSphereCamera67` z użyciem istniejącego `Sphere67`, `SphereFlight67` i `FlightDynamics556` (bez drugiego silnika ruchu).
- Przeniesiono oryginalne parametry wszystkich sześciu statków z `Campaign37.cs` i `Physics68.cs`, wraz z silnikami, stabilizatorami i rangą dysz, masą, czasami reakcji, różnymi czasami roll/pitch dla TITAN/MAMMOTH oraz ograniczeniem skrętu VANGUARD X.
- Rozróżniono stan sterowania, blokadę kierunku prawego drążka po jego puszczeniu, przerwanie tej blokady klawiaturą, 12 m nad rzeczywistą siatką, bezwładność po puszczeniu gazu, obliczenie dystansu do hangaru i stref misji.
- Rozszerzono tylko konfigurację już istniejącego `FlightDynamics556`: nowe pola mają domyślne wartości identyczne z dotychczasową ścieżką iOS. Nie zmieniono `CarbonisCombat568.swift`, `W3MainMenu568.swift`, `App.swift`, `H55ScenePage580.swift` ani misji.
- Nowy `ASTEROIDYiOS/PC602HomeWorldView291.swift`: oryginalna macierz `OrbitWorld50.View` dla kamery 400 m, perspektywa źródła `.4/1600` z adaptacją depth OpenGL→Metal, prawdziwa kontrola zasłonięcia beaconów przez geometrię H290 (21 próbek), format 16:9 i 4:3.
- `Tests/PC602HomeFlight291Tests.swift` kompiluje rzeczywiste źródłowe `Sphere67.swift`, `FlightDynamics556.swift` i `PC602HomeFlight291.swift` ze strukturą `Vec2` pobraną bez zmiany z `GameCore.swift`. Sprawdza 6 mas/prędkości, czas reakcji, ekranowe wejście sterowania, wysokość nad autentycznym H290, kamerę, geodezję, latanie bez napędu, 26 sektorów i Aim latch.
- Test podstawowej mechaniki HomeFlight z realnym kompilatorem Swift/macOS: PASS https://github.com/synixad-png/asteroidy-ios/actions/runs/43064119991.
- Testy rozszerzonej kamery i zasłaniania beaconów: do potwierdzenia osobno, zgodnie ze stanem CI.

## Następna implementacja

Doprowadzić dedykowany natywny renderer `HomeScene291` do użycia oryginalnej GLB H290 (100% siatki), zgodnego oświetlenia PC602 i wspólnej fizyki, następnie oryginalny pas 820 asteroid, statek, wrak, nawigację i dock. Testować niezależnymi golden-traces PC→Swift na tych samych danych i iOS ARM64 przed wpięciem menu. Nie podnosić procentu "pełnej planety" za sam source-import.
