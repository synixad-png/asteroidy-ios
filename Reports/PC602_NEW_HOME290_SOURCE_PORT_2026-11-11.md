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
- `PC602HomeScene291.swift` i shader `.metal` są przygotowane do prawdziwego renderowania H290 w świecie orbitalnym, ale **jeszcze nie są połączone z aktywną grą**; nie ma potwierdzonego renderu GPU z urządzenia ani zweryfikowanego porównania pikseli z PC;
- 820 asteroid oryginalnego pasa (wraz z fizyką), wrak i jego źródłowa geometria, oświetlenie pocisków, statek/strzały w trybie niebojowym;
- przygotowano geometrię i rysowanie 26 oryginalnych markerów `PC602HomeBeacons291.swift` w rendererze świata; sterowanie wyborem i lotem do misji oraz przejście scen w grze pozostają niepodłączone;
- przejście NOWA GRA → planeta główna zamiast obecnego skrótu do CARBONIS, dopiero po źródłowym runtime;
- źródłowa bramka dokowania `Hub90.CanDock90` i faktyczny punkt wraku są zaimplementowane w stanie `PC602HomeFlight291`, ale **nie podłączono jeszcze wejścia do H55**, zapisu aktywnego świata ani testu na urządzeniu;
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

## Etap 3 — rzeczywista scena planety Metal (kod źródłowy, jeszcze bez wpięcia)

- `ASTEROIDYiOS/SourceNewHome290MetalAssets.swift`: 1 właściciel bufora GPU (24 797 952 bajty dokładnej geometrii), oryginalnego JPEG i mapy emisji, odtwarzanych z istniejących GitHub ZIP v568, w pełni sprawdzanych SHA-256. Wspólny `MTLDevice` → 1 niemodyfikowany zasób GPU współdzielony przez menu W3 i nową scenę.
- `W3HomePlanetMetal568.swift` używa tego współdzielonego właściciela; bez ponownego wczytywania JPEG i kopiowania geometrii w pamięci GPU. Renderer W3 zachowuje tryb przezroczysty i oryginalne transformacje; jego fragment `W3HomePlanet290.metal` pozostał bez zmian merytorycznych.
- Regresja oświetlenia wykryta w audycie względem oryginalnego `GpuToon60.cs`: normalne i wektor do kamery muszą być liczone w **przestrzeni eye/model-view**, nie w przestrzeni świata. `PC602HomeScene291.swift` przekazuje model-view do shadera; światło `GpuShip.FighterLight(false)` zachowuje źródłowy kierunek `(-0.6,0.8,1.4,0)` w eye space. Kontrakt `PC602HomeScene291Contract.py` pilnuje tej zależności.
- Oba renderery używają teraz **tej samej instancji `MTLDevice`** (`SourceNewHome290MetalAssets.defaultDevice`), aby cache współdzielonej siatki H290 i JPEG/poświaty naprawdę działał, nawet gdy dwa wywołania `MTLCreateSystemDefaultDevice` zwróciłyby różne obiekty opakowujące ten sam GPU.
- `SourceHome290Vertex.metalh`: wspólny dekoder dokładnego układu 12×float GLB bez duplikacji implementacji, używany przez podgląd W3 i `PC602HomeScene291.metal`.
- `PC602HomeScene291.swift` i `.metal`: prawdziwe 172 208 trójkątów H290, skala 100, kamera świata `PC602HomeWorldView291`, dwie oryginalne grupy materiałowe, mieszanie emisji lawy w tym samym przebiegu shadera. Scena przyjmuje realny stan `PC602HomeFlight291`, nie wykonuje własnego ruchu planety.
- `PC602HomeBeacons291.swift`: 26 faktycznych punktów przy powierzchni H290, po 40 linii pierścienia, promień 8 m / 3,4 m, kolory zależne od rzeczywistego stanu ukończenia; marker GPU renderowany po planecie z testem głębokości i wyłączonym zapisem Z. Przebudowa bufora tylko przy zmianie wybranego celu lub postępu kampanii, nie w każdej klatce.
- `PC602HomeFlight291.swift`: położenie doku jest zawsze obliczane z `NewHome290.WreckPosition`, już od inicjalizacji znana jest prawdziwa odległość od doku. `Hub90.CanDock90`: próg 43,2 m oraz wymagane planetHub/orbit/!busy/!talentOpen/!miningDetached. Bramka nie uruchamia jeszcze H55.
- `Tests/PC602HomeFlight291Tests.swift`: wartości referencyjne źródłowych markerów 26 sektorów i bramki dokowania; `Tests/PC602HomeScene291Contract.py`: dedykowany kontrakt zgodności źródła i braku duplikacji GPU.
- `.github/workflows/verify-pc602-home-metal291.yml`: rzeczywisty `xcodebuild` iPhone+iPad ARM64, testy regresji oryginalnego menu W3 i kontroli zasobów, bez pakowania IPA.

### Wynik weryfikacji na obecnym etapie

- Wcześniejsze testy pierwotnych H290 + matematyki lotu/camera Swift: PASS, np. https://github.com/synixad-png/asteroidy-ios/actions/runs/43065654956.
- Audyt `No Slop` po zmianach: PASS, np. https://github.com/synixad-png/asteroidy-ios/actions/runs/43069193783.
- Pierwszy nowy ARM64 build https://github.com/synixad-png/asteroidy-ios/actions/runs/43067551826 wykrył błąd składni w sprawdzeniu rozmiaru bufora; poprawiono w commit `3acb063f205473a93889c1e9db51a2327395956a`.
- Późniejsze przebiegi z poprawką i nowymi markerami / dockiem: **w kolejce**, np. https://github.com/synixad-png/asteroidy-ios/actions/runs/43069193932. Brak podstaw do deklaracji udanej nowej kompilacji ARM64 lub fizycznego testu GPU.
- Rzeczywistego aktywnego świata orbitalnego, pełnej nawigacji, modeli wraku, 820 asteroid, statku i integracji startu misji **nie ukończono**. Nie utworzono IPA.

**Zasada przechowywania:** pełny ZIP v602 zostaje tylko w Bibliotece ChatGPT. Do repozytorium trafiają wyłącznie konkretne implementowane moduły i zasoby konieczne w runtime, albo możliwe do byte-identycznego odtworzenia z GitHuba. Nie wolno kopiować pełnego ZIP ani masowo przenosić zbędnych archiwów źródłowych.

## Następna implementacja

Najpierw uzyskać pełny PASS macOS/iOS ARM64 dla dodanego renderera, a następnie porównać prawdziwy render na iOS z kodem PC. Dopiero potem dołączać oryginalny pas 820 asteroid, statek, siatkę wraku i dokowanie do H55, oryginalną nawigację/wybór misji. Żadnych zastępczych modeli. Wpiąć menu dopiero po pełnej, rzeczywistej ścieżce gameplay i testach regresji. Nie podnosić procentu ukończenia pełnej planety za sam import źródeł.


## Etap 4 — oryginalny pas 820 asteroid, kod C# → Swift/Metal

**Źródło i zakres:** PC v602 w Bibliotece ChatGPT, Windows/src/OrbitWorld51.cs (`BuildBelt51`, 820 × `Random(4109)`) i Windows/src/GpuIntro41.cs (`IntroStone`, `StoneNormal56`, `StoneFace`, `StoneSubdivide56`, `PrepareIntroBelt`, `BeltVisibleInOrbit135`, `DrawIntroBelt`). Zależności źródłowe: `Intro41.cs` (trajektoria kamery 16 s do wykluczania obiektów z kadru), `NewHome290.cs` (prawdziwa fizyczna mapa H290 512×256 i położenie wraku), `Orbit50.cs` (`Rotate`), `PlanetLife52.cs` (`Basis`). **Nie przenosimy pełnej paczki v602.**

1. `Tools/PC602OrbitBelt51.cs` zawiera ograniczone do aktualnej funkcji, jawnie oznaczone źródłowe równania C# z oryginalnego PC, uruchamiane w .NET 8 poza aplikacją iOS. Odtwarza dokładnie kolejność losowań `Random(4109)`, przestawienia obiektów utrudniających kadr intro, lokowanie asteroid `H290.Surface(direction)+19..26 m`, strefę wykluczenia wraku, 20 trójkątów bazowego icosahedronu, autorskie kraterowanie i podziały 2/3.
2. `Tools/stage_pc602_orbit_belt51.py` uruchamia generator wyłącznie podczas budowania zasobów, sprawdza SHA-256 źródłowej mapy H290 i weryfikuje format `B051`. Powstaje dokładnie jeden binarny, niekopiowany do GitHuba gotowiec `ASTEROIDYiOS/Assets/PC602OrbitBelt51.bin`; sceny Metal nie uruchamiają C# ani generatora.
3. Rzeczywisty generator C# na Ubuntu/.NET 8 dał **PASS**: 820 osobnych asteroid (656 podstawowych, 164 szczegółowe), **1 259 520 wierzchołków / 419 840 trójkątów**, dokładnie **50 403 776 bajtów**. SHA256 dla tego przebiegu Linux: `553336e3f071bbb09cf6ba4b1b7cbc36b6bc346537cf8fb06343b90f807f4f63`. Wynik deterministyczny w tym środowisku; nie zakładamy automatycznie identyczności wszystkich zaokrągleń `Math.Sin` Windows/macOS bez dodatkowego testu porównawczego.
4. `ASTEROIDYiOS/PC602OrbitBelt51.swift` importuje dokładny strumień 10 float na wierzchołek, odrzuca niekompletną geometrię lub tablicę 820 rekordów, uwzględnia źródłową skalę świata **3,2×** i źródłowy frustum `BeltVisibleInOrbit135`; brak nowej generatorowej geometrii w iOS.
5. `ASTEROIDYiOS/PC602OrbitBelt51.metal` korzysta z oryginalnych pozycji, normalnych i barw oraz oświetlenia `GpuToon60` w przestrzeni kamery. `PC602HomeScene291.swift` rysuje rzeczywiste asteroidowe siatki po planecie H290, a przed markerami misji. **Jeden bufor GPU** jest tworzony podczas inicjalizacji; każda klatka tylko odrzuca niewidoczne zakresy. Sąsiadujące widoczne zakresy są łączone w jedno wywołanie `drawPrimitives` bez kopiowania wierzchołków (dla wszystkich widocznych 820 asteroid = 1 wywołanie).
6. Test `Tests/PC602OrbitBelt51Tests.py` sprawdził wszystkie oryginalne przedziały siatek, oba poziomy szczegółowości, położenie względem prawdziwego H290, próbki geometrii i normalnych. Źródłowe `IntroScene41.P.Unit` dzieli przez `max(0.00001, length)`, dlatego wiele oryginalnych normalnych ma długość mniejszą niż 1 — zachowano te dokładne wartości, nie zmieniano ich na sztucznie znormalizowane. Test ma **PASS**.
7. `Tests/PC602OrbitBelt51Tests.swift`: prawdziwy kompilator Swift na Ubuntu uruchomił test odczytu pliku, źródłowej wysokości, zakresów 820 siatek, frustum i błędów celowo uszkodzonego zasobu. **PASS**.
8. Workflow `.github/workflows/verify-pc602-belt-source.yml` potwierdza razem rzeczywisty `.NET 8` C#, Python i Swift: https://github.com/synixad-png/asteroidy-ios/actions/runs/43073328702.
9. Workflow `.github/workflows/verify-pc602-home-metal291.yml` jest rozszerzony o `setup-dotnet`, staging geometrii i rzeczywisty `xcodebuild` ARM64 dla obu rodzin iOS. **Wynik ARM64 jeszcze niepotwierdzony:** zadania Apple pozostają w kolejce. Testowy CI Linux nie potwierdza poprawności shaderów Metal na GPU.

**Ograniczenia:** brak grywalnego aktywnego świata, modelu statku i wraku, połączenia H55, wejścia do misji, testu dotyku i FPS; nie wydano IPA. Oryginalny `OrbitWorld51.Move51` obsługuje legacy orbit, podczas gdy nowy `HomeFlight291` korzysta z `MoveShip67` — nie wprowadzono hipotetycznych kolizji asteroid do ścieżki, w której nie potwierdzono ich wywołania. Po zweryfikowaniu kompilacji Apple następnym modułem jest widoczny źródłowy wrak 3D i interakcja dokowania, a następnie prawdziwy statek / sterowanie / integracja misji.

**Zasada dostarczania:** repozytorium zawiera źródła C#/Swift/Metal i testy potrzebne do tego etapu, a nie cały ZIP PC v602. Niezmodyfikowany oryginał jest w Bibliotece ChatGPT; źródłowe dane H290 istnieją już w zweryfikowanych archiwach GitHub v568.


## Etap 5 — prawdziwy wrak PC602: pole odłamków i bezpieczny routing dokowania H55

**Weryfikacja źródła:** oryginalna paczka PC v602 z Biblioteki; oryginalny `Windows/src/GpuIntro41.cs` SHA-256 `cdeecc6eedc96084e12d50d4062ba981feb404ade6b9d6b25ae333e43486c45e`, `Windows/src/GpuAmbient37.cs` SHA-256 `92f9d3e096d77e2eed1f9a0f42e206ef8d433148637c2b7f5bfc27d633560636`, `Windows/src/Hub90.cs` SHA-256 `a908a3632d22fab0932798405e0d0faff39334e2f1298d9e2d607d5b42587a4d`, `Windows/src/NewHome290.cs` SHA-256 `01a402967eee017a9e1d1fc526b974969c3055f5aea1904eab6140a002950500`.

W źródłowym PC wrak NIE jest osobnym GLB. Obiekt tworzy `GpuIntro41.DrawDetailedResearchWreck211(211,true)`, ze ścian WreckBox209, siatek paneli, anten, zabrudzeń `WreckSketchBox215`, śluz, lamp ostrzegawczych i pola odłamków. Dokowanie obsługuje `Hub90.CanDock90`, a otwarcie tej samej sceny H55/H72 używa innych warunków dla orbity i menu W3.

**Wykonane i zapisane na GitHubie:**
- `ASTEROIDYiOS/PC602WreckDebris209.swift`: transkrypcja `SpaceHash207` i `SpaceRand207` z identyczną arytmetyką `uint32` (przepełnienie 32-bitowe) oraz 146 pierwszych i 15 dodatkowych kostek odłamków z `GpuIntro41.cs:398-415`. Zachowuje seed 211, długość smugi 178, kolory, rozmiary i odchylenia, bez losowania na każdej klatce.
- Ta sama jednostka zawiera **początkowe 36 wierzchołków każdej oryginalnej kostki WreckBox209**, z sześcioma ścianami, orientacją i charakterystycznymi przyciemnieniami RGB — łącznie **5 796 wierzchołków i 1 932 trójkąty konstrukcyjne**. To NIE jest pełny model wraku: oryginalne rysy, zabrudzenia, ślady farby i segmenty kadłuba nadal pozostają do przeniesienia.
- Pozycja całego wraku używa *dokładnie* `NewHome290.WreckPosition()`, `Rotate(31° Y)`, `Rotate(-9° Z)`, `Scale(0.504*1.20=0.6048)`. Nie wolno nadawać odłamkom osobnego początku sceny ani przesuwać punktu dokowania.
- `ASTEROIDYiOS/PC602HomeHubRoute90.swift`: źródłowe bramkowanie `Hub90.EnterHub90` przez `PC602HomeFlight291.CanDock90` (dokładnie 43.2 m, tryb Orbit, PlanetHub, !SceneBusy, !TalentOpen, !MiningDetached). Niezależna ścieżka `EnterMenuHangar397` otwiera **tę samą scenę H55** jako wizytę wystawową, a `ExitHub90` zwraca do menu lub do aktualnego lotu zgodnie ze źródłem; nie przyznaje misji, nagród ani nie tworzy punktu zapisu z wejścia w menu.
- `Tests/PC602WreckDock209Tests.swift`: oryginalne wartości hash / jitter i pierwszych oraz ostatnich odłamków, wszystkie 161 fragmentów, sześć ścian i cienie, skala i transformacja świata, granica 43.2 m (43.201 odrzucone), wyłączenie dokowania przy nieuprawnionych stanach oraz obydwie ścieżki wejścia i wyjścia H55.
- `.github/workflows/verify-pc602-wreck-dock209.yml`: kompiluje **rzeczywiste** iOS `Sphere67.swift`, `FlightDynamics556.swift`, `PC602HomeFlight291.swift` i źródłowy `Vec2`, używa H290 z czterech zweryfikowanych repozytoryjnych archiwów, wykonuje powyższe testy z włączonymi asercjami i bramkę jakości. **PASS:** https://github.com/synixad-png/asteroidy-ios/actions/runs/43087683149.
- Nowe pliki Swift dodano do monitorowania przez `.github/workflows/verify-pc602-home-metal291.yml` (kompilacja iPhone+iPad/Metal). Najnowszy komplet iOS ARM64 po zmianach **nie ma jeszcze potwierdzonego wyniku** — nie wystawiać IPA ani nie ogłaszać ukończenia renderowania.

**Nieukończone / następny etap:** odtworzenie *wszystkich* metod `WreckPanelGrid213`, `WreckBridge213`, `WreckAirlock211`, `WreckWindowRow211`, `WreckSketchBox215`, `WreckWarningLamp213` i batchowania oryginalnej geometrii kadłuba 3D, następnie wierne oświetlenie, rysy i animacje lamp z `weatherTime65`, a dopiero potem GPU render wraku wraz z odłamkami. Routing H55 to obecnie **oddzielny, przetestowany moduł**, ale NIE jest jeszcze podłączony do aktywnego GameView, który pozostaje na obecnej działającej ścieżce W3 / H55 / Carbonis. Następnie statek gracza, sterowanie, przejścia misji, pełna integracja i IPA. Wygenerowanie struktur danych ani poprawne testy jednostkowe nie potwierdzają obrazu na urządzeniu lub grywalnej planety.


## Etap 6 — kompletny, źródłowy wrak orbitalny: ponowne użycie Wreck211 i Metal

**Wykryta i wykorzystana wcześniejsza implementacja:** plik `ASTEROIDYiOS/ResearchWreckGeometry214.swift` jest już pełną transkrypcją oryginalnego `GpuIntro41.DrawDetailedResearchWreck211` dla wariantu bojowego. Zawiera **cały kadłub**, wszystkie panele, odsłonięte żebra, moduły laboratoryjne, okna, trzy śluzy, anteny, znakowania, dziesiątki warstw zabrudzeń, zarysowania, wycieki i siedem źródłowych lamp. Istniejący `SourceCombatWreck214.swift` zawierał już natywny renderer oraz oryginalny ABI shaderów Metal `combatWreckTriangleVertex214` / `combatWreckLineVertex214` w `Sector01Carbonis568.metal`. **Nie ma potrzeby pisać wymyślonego modelu ani duplikować całego generatora.**

Zmodyfikowano tylko metodę `Builder.drawSourceWreck214(seed:debris:trail:)`, aby zachować niezmieniony wcześniejszy wariant bojowy `112 / 118`, a dodana `ResearchWreckGeometry214.makeOrbitHome602()` wywołuje dokładnie `seed:211,debris:146,trail:178` z PC v602 `GpuIntro41.cs:333–415`, kiedy NewHome290.Enabled jest true. Ten sam oryginalny kod budowy kadłuba jest wykorzystywany przez obydwa warianty. Dwa dodatkowe niemutujące liczniki `hullVertices`, `hullLineVertices` wyznaczają prawdziwą granicę pomiędzy wspólnym kadłubem a różniącymi się smugami odłamków.

`ASTEROIDYiOS/SourceHomeWreck209.swift` tworzy **jeden komplet buforów GPU** z gotowych wierzchołków (11 float na trójkątowy wierzchołek, 7 float na wierzchołek rysy), wykorzystuje istniejące funkcje źródłowego renderera Metal z obsługą czasowych faz lamp i nie przelicza geometrii w czasie rysowania. Stosuje rzeczywisty oryginalny `T(H290.WreckPosition()) * Ry(31°) * Rz(-9°) * Scale(0.6048)`, `OrbitWorld50.SunDirection111(OrbitTime50)` (kąt = 0.62 + time×0.047) i źródłowe `weatherTime65=OrbitTime50`. Kolorystyka korzysta ze sprawdzonego, współdzielonego shaderu badawczego z wariantu bojowego — **zgodność oświetlenia per-pixel z dawnym fixed-function OpenGL nie została udowodniona**.

`ASTEROIDYiOS/PC602HomeScene291.swift` rysuje teraz tę pełną scenę 3D po pasie 820 asteroid, przed markerami 26 misji. Nie renderuje równolegle częściowego `PC602WreckDebris209.structuralBoxFaces()`, więc **nie duplikuje pola odłamków**. Istniejąca ścieżka misji i W3 pozostaje bez zmian.

**Test regresyjny:** `Tests/PC602OrbitWreck211Tests.swift` kompiluje autentyczny `ResearchWreckGeometry214.swift`, zestawia oba warianty przy tym samym seed 211 oraz porównuje **każdy źródłowy wierzchołek / kolor / normalną / fazę lampy kadłuba i każdą linię zadrapania**, sprawdza wszystkie siedem unikalnych faz `[0,110,220,270,310,420,490]`, rzeczywiste limity bufora GPU, deterministyczne odtwarzanie i brak regresji `make(sector:1)`. GitHub Actions Ubuntu z tym testem: **PASS** https://github.com/synixad-png/asteroidy-ios/actions/runs/43089764668. `Tests/PC602HomeScene291Contract.py` chroni rzeczywistą integrację render pass i prawidłową kolejność, a `.github/workflows/verify-pc602-home-metal291.yml` weryfikuje autentyczny build iPhone/iPad ARM64, gdy job dobiegnie końca.

**Pozostałe zadania:** wynik ostatniej kompilacji pełnej gałęzi ARM64 i rzeczywisty framebuffer iPhone/iPad; **model statku i jego źródłowy silnik w tym świecie**, ruch/strzelanie/tarcza/HUD/interakcja dotykowa, faktyczne przejście dokowanie↔H55 podłączone do aktywnej sceny, integracja 26 misji, źródłowe efekty atmosfery i nieba, bezpieczne zapisy i pakiet IPA. Nie twierdzić, że widoczność wraku na prawdziwym GPU lub pełna grywalność są już potwierdzone.
