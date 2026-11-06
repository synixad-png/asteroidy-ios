# ASTEROIDY v568 — WAVE(): audyt pełnych źródeł Windows i SteamOS
Data kontroli: 2026-11-06. Zakres: rzeczywiste pliki źródłowe, nie tylko wyciąg audytowy.

## Istotna korekta wcześniejszych raportów
Wcześniejszy raport stwierdzał, że definicji `Wave()` nie ma w dostępnych źródłach. To było NIEPRAWIDŁOWE uogólnienie z niepełnego archiwum `ASTEROIDY_v568_AUDYT_26_PLANET_STATKOW_BOSSOW_I_ZASOBOW.zip` (66 347 483 bajty, tylko 32 pliki C#).

**Pełne archiwum** użytkownika w Bibliotece ChatGPT: `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (150 473 406 bajtów), SHA-256 całego archiwum `271229a995c6e0a096ec401ba969c795a2fe4a4954462465ec1de2e1af5caaa7`, zawiera 1788 pozycji oraz 771 plików C# (307 z `Windows/src`, 279 z `SteamOS/src`, pozostałe w innych katalogach); przeprowadzono pomyślną kontrolę CRC wszystkich pozycji (Python zipfile.testzip -> PASS).

`Wave()` występuje w:
- `Windows/src/Game.cs`, wiersze **90–101**, SHA256 całego Game.cs: `cb0b398ccf47408174b392ea3e5827d53c188e08c293fe8632ac3898c1e25aae`.
- `SteamOS/src/Game.cs`, wiersze **90–101**, SHA256 całego Game.cs: `3a8381d2083e35fa4eea53040f23d4e31572975a8e80fd3451d423d7bca7bb71`.
- Sam blok funkcji `public void Wave(){...}` jest **bajtowo identyczny logicznie po dekodowaniu UTF-8** między tymi platformami: SHA256 = `e3ee8a2816d28045a2c788ad238df952473e1f58c6292e6e1f0b18ef368e8925`.
- Wywołanie z misji orbitalnej: `Windows/src/Orbit50.cs:58–75`, `StartHubMission261` → `Wave()` → `BeginLevelIntro()`.

## Potwierdzony przepływ procedury Wave()
1. `ResetTactics71()`, `ResetBoost71()`, `ClearDestruction524()`, `BeginRewards57()`, `ConfigureActionSector()`; zerowanie licznika trafień AMIGA i przygotowanie strażnika.
2. `SectorRockCount` z `Action38.cs:4` uwzględnia liczbę fali, trudność, tryb sferyczny i skalę 0,8; `HeavyCount`, `DenseCount`, `ArmoredCount` z `Game.cs:83–86` wyznaczają klasy skał.
3. Pętla tworzy obiekty `Rock` z poziomami tier, losową pozycją `V(Rand(0,W),Rand(0,H))`, wyklucza odległość od statku mniejszą niż 260 w `WorldDelta67`, ustala kierunek, prędkość, rotację i seed. `PrepareRock70()` z `Balance70.cs:5–6` ustala prawdziwe HP i skalę sferyczną. Wyniki trafiają do `Rocks`.
4. `Bugs.Clear()` oraz `RobotDebris70.Clear()`. Poza specjalnym światem AMIGA lvl 25: `SpawnShooters71()` z `EnemyTactics71.cs:30` dodaje uzbrojone myśliwce, `SpawnRobots70()` z `RobotSnake70.cs:8–14` dodaje robotyczne węże zależnie od poziomu i trudności.
5. Zerowanie `NextWave`, reset nagród i podsumowania, powiadomienia o nowych klasach skał dla poziomów 3, 7, 10.

## Powiązany dalszy przebieg misji
- `Action38.cs:7`: `ConfigureActionSector()` ustawia `ResetObjective65()`, zegary, `IncomingRocksLeft`, terminy kolejnych posiłków i parametry loot.
- `Action38.cs:9–10`: `SpawnIncoming()` oraz `StepAction(dt)` dostarczają do dwóch asteroid w jednej turze, przy spełnieniu zegara lub niskiej liczby skał; nie należy traktować tego jako funkcji jednoznacznej z `Wave()`.
- `Gameplay65.cs:6–11`: typ celu: normalne czyszczenie, eskorta (2,11,21), obrona (5,14,23), fale przetrwania (9,17).
- `Combat69.cs:8`: `MissionCleared69` wymaga ukończonego celu, braku zagrożeń i — dla wymagających tego sektorów — pokonanego bossa. Nie wolno zaliczać samego wyczyszczenia inicjalnych asteroid.
- `AmigaBounce265.cs` i `Amiga266Tests.cs`: sektor 25 jest osobnym trybem pokazowym, nie zwykłą falą zakończoną zwycięstwem.

## CARBONIS 01 — zweryfikowany przykład
Dla `Level=1`, `Difficulty=1` (NORMALNY), `SphereActive67=true`: `WaveCount(1)=8`, `SectorRockCount=round(8 × 2 × 0,8)=13`. `StartingFighterCount96=2`, ale `SpawnShooters71` używa `n=StartingFighterCount96+2` — tworzy **4 myśliwce**. `RobotCount70=0`. `ReinforcementQuota=0`, przy celu `Clear` pozostaje 0 planowanych posiłków. To odczyt kodu, nie wynik uruchomienia gry na urządzeniu.

**Wykryta rozbieżność w źródłowych testach:** `Windows/src/Gameplay77Tests.cs:11–15` oczekuje liczby myśliwców równej `StartingFighterCount96`, podczas gdy aktualna implementacja `EnemyTactics71.cs:30` tworzy `StartingFighterCount96+2`. Te dwa warunki są sprzeczne. Bez uruchomienia testu z pełnym projektem nie można twierdzić, że oryginalny zestaw testów jest PASS.

## Przeniesienie na iOS — stan rzeczywisty
W repozytorium `synixad-png/asteroidy-ios` są już oddzielne, testowe mechanizmy skał i fizyki (`SphereSector556.swift`) oraz nowy `MissionStart261.swift`. Jednak ekran `Sector01Scene568.swift` jest nadal inspektorem oryginalnej planety C279, nie gotową sceną walki. **Znalezienie źródeł nie oznacza wdrożenia Wave w iOS**.

Dalsze prace należy prowadzić z pełnego archiwum v568, przenosząc dokładną logikę `Wave()` i zależności z `Game.cs`, `Action38.cs`, `EnemyTactics71.cs`, `RobotSnake70.cs`, `Balance70.cs`, `Gameplay65.cs`, `Combat69.cs`. Przed podłączeniem gry rozwiązać/udokumentować wykrytą rozbieżność count+2 w oryginalnych testach. Utrzymać dotychczasowe mechanizmy 7/8 i zapis kampanii.

**Weryfikacja w bieżącej analizie:** lista 1788 wpisów, 771 C#, CRC PASS, obecność wszystkich 12 sprawdzanych kluczowych plików i metod PASS, zgodność obu bloków Wave SHA256 PASS. Nie uruchamiano oryginalnych testów C# ani Xcode/Metal iPhone — nie ma podstaw do ich zaliczenia. Postęp projektu pozostaje 29% wykonane / 71% pozostało; sam audyt nie zwiększa postępu. Nie generowano IPA.
