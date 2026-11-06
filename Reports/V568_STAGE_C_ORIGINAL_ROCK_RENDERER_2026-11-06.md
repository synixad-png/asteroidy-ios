# ASTEROIDY iOS v568 — etap C: widoczne, poruszające się asteroidy na CARBONIS

Data: 2026-11-06. Źródło: pełny oryginalny Windows/SteamOS v568. Prace w natywnym Swift/Metal, bez WebView i bez tworzenia IPA.

## Rzeczywiste zmiany

1. `CarbonisRockGeometry568.swift` rekonstruuje proceduralną geometrię asteroid z `Windows/src/GpuIntro41.cs:13–18` (ikosahedron, 20 ścian, `StoneSubdivide56` 2×, `IntroStone`, `StoneNormal56`, kraterowanie, kolory) oraz `Windows/src/GpuSphere67.cs:123–124` (`RockVertices75`, seed kształtu i paleta klas pancerza). Każda siatka ma **960 oryginalnych wierzchołków**; dwa dodatkowe zerowe pola UV służą jedynie zgodności bufora z 12-float vertex-layout planety C279. Nie zastępują wierzchołków, normalnych ani palety skał.

2. W `Sector01Carbonis568.metal` dodano `sector01SourceRockFragment568` — pasmowe oświetlenie toon i rim z `Windows/src/GpuRockInstancing75.cs:49–50`; niezależne od oryginalnego dwumateriałowego PBR-preview C279. Istniejący fragment planety zachowano.

3. `Sector01CarbonisPreview568.swift` przyjmuje rzeczywiste obiekty `Game.Wave()`. Buforuje proceduralną geometrię tylko raz na unikalny kształt (`MTLBuffer` per shape), renderuje 3D asteroidy po źródłowym modelu planety, przydziela każdy do `StampSphere67` (`GpuSphere67.cs:8,63,133`, oryginalna normalna sfery + dwie osie styczne, położenie na shellu nad terenem i oryginalny obrót 41°/23°), a w kolejnych klatkach wywołuje `SphereAsteroid556.advance(dt:)`. Pętlę czasu ograniczono do 0,05 s kroku po przerwaniu klatki. Nie zmieniono oryginalnej geometrii, indeksów, UV i tekstur planety.

4. `Sector01Scene568.swift` przekazuje obiekty `preparedWave.encounter.rocks` do natywnego renderera i jasno rozróżnia ruch asteroid od niezaimplementowanych myśliwców/AI, statku i rozstrzygnięcia misji. Wspólna baza `MissionStart261 + MissionWave568 + MissionIncoming568` z poprzedniego etapu pozostaje.

5. Dodano `Tests/CarbonisRockGeometry568Tests.swift`; rozszerzono `.github/workflows/verify-combat-only.yml` i dotychczasowy `Tests/V568W3NativeMenuContract.py` o regresje prawdziwej geometrii asteroid i jej integracji w C279. **IPA nie powstało.**

## Kontrola, co potwierdzone

- Lokalnie **43 385 asercji Swift/Linux PASS**: 45 wariantów źródłowego kształtu, 960 wierzchołków, wszystkie normalne skierowane na zewnątrz, skończone wartości, oryginalna paleta, spójność koloru/alpha/UV, deterministyczność i różnice kształtów. Testy używają lekkich odpowiedników obiektów ruchu, nie pełnego iOS SDK.
- 10/10 statycznych kontroli kodu GitHub PASS dla źródłowych reguł, buforów GPU, rysowania 3D, zasilania danymi `Wave()`, zachowania obu oryginalnych materiałów planety i jawnego braku ukończonej misji.
- Pełny oryginalny archiwum v568 (150 473 406 B) było wcześniej zweryfikowane CRC, źródła C# bez hipotez.
- **Ważne:** rzeczywistego wykonania nowego Metal renderera na urządzeniu, kompatybilności GPU Apple oraz końcowego `xcodebuild` po tej zmianie jeszcze nie zweryfikowano. Kod i wywołania draw zostały wdrożone, ale nie wolno twierdzić, że widok na fizycznym iPhonie został potwierdzony. GitHub Actions został skonfigurowany do kompilacji iOS bez IPA; brak potwierdzonego wyniku końcowego.

## Pozostała praca zgodnie z C → D

- Uruchomienie oryginalnego statku w rzeczywistej misji i aktywna kamera przypisana do lotu, zamiast kontrolowanego palcem oglądania planety.
- Natywny renderer i logika aktywnych czterech myśliwców CARBONIS oraz robotów na dalszych poziomach (źródłowe `EnemyTactics71` i `RobotSnake70`).
- Połączenie `MissionIncoming568.step` z aktywnym `Game.Step`, życie statku, strzały, kolizja z mapą 512×256, wymagane cele i warunki zwycięstwa/przegranej, potwierdzenie natywnych testów iOS.
- Nie uruchamiać sztucznego 26 poziomu `Wave()`; nie zmieniać istniejących mechanizmów 7/8 i zapisu kampanii.

## Postęp

Proponowany ostrożny postęp projektu po nowej rzeczywistej funkcji renderowania: **31% wykonane / 69% pozostało**. Zadanie 4 (modele statków i planet) 24% (+2 pp); zadanie 12 (misje planetarne) 12% (+2 pp); pozostałe 16 zadań bez zmiany. Wyniki te nie oznaczają zweryfikowanego obrazu ani kompletnej gry.
