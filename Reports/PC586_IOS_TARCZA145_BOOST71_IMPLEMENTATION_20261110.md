# ASTEROIDY iOS — etap PC v586 / Tarcza145 i Boost71
Data: 2026-11-10

## Baza i zakres
- Referencja PC: `Asteroidy_v586_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` z Biblioteki.
- Oryginalne źródła: `Windows/src/Tarcza145.cs`, `Windows/src/Boost71.cs`, `Windows/src/Game.cs` oraz cztery GLB z `Shared/assets/pickups`.
- Gałąź iOS: `feature/ios-h55-v580-native-entry`.
- Commit ostatniej implementacji/testów: `91c7a1078e87dd3f59b23d1011b3e8df65406301` (przed dodaniem tego raportu).
- **Nie zmieniać** zatwierdzonego HUD 3D, portu H55/H71, oryginalnych zasobów GLB ani mechanik nagród/pieniędzy.

## Zrealizowana mechanika (prawdziwe obiekty symulacji CARBONIS 01)
- `ASTEROIDYiOS/SourcePickupAbilities586.swift`: nowa natywna struktura `SourceTarcza145` (60/100 energii początkowo, drain 12/s przy przytrzymaniu, +20 z ogniwa, koszt trafienia 35, nietykalne odrębne `shieldCharges`, 0.28 s ochrony, 0.37 s flash).
- `SourceBoost71`: 3 maks. ładunki, pojedyncza aktywacja na 0.9 s, 2.6-krotna prędkość, osłona przed obrażeniami, jeden atak taranowania na unikalną asteroidę lub przeciwnika (8/6 obrażeń), wykorzystywanie istniejącej ścieżki obrażeń, zniszczeń i nagród.
- `SourceLegacyPickupDrops586`: szanse upuszczenia ogniwa tarczy na rock 3/2/1 = 20%/10%/3.5%, wroga = 55%; boost początkowo po 4–7 zniszczonych asteroidach, następnie co 5–9. Lifetime tarczy 23 s, dopalacza 25 s, limit współdzielonej listy 96.
- `CarbonisCombat568.swift`: nowe rodzaje przedmiotów do `tokenPickups`; bez drugiej fizyki lub portfela, prawdziwe aktualizacje energii i ładunków, prawdziwa kolejność przechwytywania trafień (guardian → ręcznie aktywowana tarcza → kupiona osłona), aktywny ram oparty na oryginalnym `CombatCollision556.segmentHit` z ochroną przed powtórnym uszkodzeniem.
- `Sphere67.swift`: opcjonalny boostMultiplier do istniejącej ścieżki `SphereFlight67.tick`; domyślny brak boost zachowuje starą arytmetykę.
- `CarbonisSession568.swift`: prawdziwe wartości `tarczaEnergy` i `boostCharges` w dotychczasowym `SourceCombatHUD331`, jednokrotne `useBoost71`, przytrzymanie `holdShield145`. Zawieszenie aplikacji i pauza wyłączają przytrzymanie.
- `Sector01Scene568.swift`: dotykowe sterowanie przytrzymaniem osłony i przyciskiem dopalacza; źródłowy HUD nadal rysowany w czterech rogach bez zmiany geometrii.

## Zweryfikowane testy
- GitHub Actions **42782251600**, `verify-combat-no-ipa` **SUCCESS** na commicie `91c7a107...`. Nowe testy w `Tests/CarbonisCombat568Tests.swift` sprawdzają: fizyczne zebranie ogniwa i dopalacza, aktualizację prawdziwej energii/ładunków, 12/s drain, uderzenie za 35 energii przed tarczą pasywną, 0.9 s boost, jeden hit na rock, 8 punktów obrażeń HP, statystyczną liczbę dropów oraz deterministyczny RNG bez regresji misji.
- Test kontraktu źródłowego modeli/Metal/sterowania, GitHub Actions **42782008844** — **SUCCESS**.
- Code Quality / No Slop na najnowszym kodzie — **SUCCESS**.
- Starsze testy H11 Guardian/Rail/Swarm **SUCCESS** po dodaniu modułu źródłowego.
- Native Xcode debug/ARM64 compilation była wcześniej zweryfikowana dla implementacji; niezależne joby pełnej kompilacji i ponownego wydania Release na najnowszej wersji mogą być nadal w kolejce. **Nie twierdzić, że nowa IPA jest gotowa, dopóki GitHub Release i weryfikacja rzeczywistego IPA nie przejdą.**

## Uczciwie opisane różnice i ograniczenia
- Oryginalny PC wykorzystuje jeden wspólny `Game.random` dla części dropów. W przeniesionym iOS zachowano istniejące, już działające losowania graczy, asteroid i AI; ogniwa Tarcza145/Boost71 mają **niezależny deterministyczny strumień .NET** o identycznych źródłowych progach i częstotliwościach, ale nie identyczną sekwencję wszystkich liczb losowych PC.
- Wersja natywnego renderera iOS korzysta ze źródłowej, wcześniej przyjętej skali świata. Boost używa `topSpeed × 0.40 × 2.6` z oryginalnej formuły `Physics68.SurfaceSpeed68` i `Boost71.StepBoost71`, ale pełnego interaktywnego porównania iPhone/PC nie wykonano.
- Testów rzeczywistego GPU, ergonomii dotyku, FPS 60 i faktycznego zachowania na fizycznym iPhonie/iPadzie nie przeprowadzono.
- **Ostatnia opublikowana IPA testowa PC v586 poprzedza tę implementację. Nie przedstawiać jej jako IPA z działającą Tarczą145 i Boostem71.**
- Pełny router 60 akcji PC/5 opcji wejścia, mapowania klawiatura/gamepad, menu 65 pozycji, migracja oraz testy fizycznych urządzeń pozostają nieukończone.

## Harmonogram po tym etapie (12 niezmiennych pozycji)
1. Audyt PC v586 100%.
2. Cztery oryginalne modele GLB 90%, fizyczne renderowanie na urządzeniach niezweryfikowane.
3. Jasność modeli 85%, test GPU na urządzeniach do wykonania.
4. Drop Energia/Bomba + Tarcza/Boost 95%, regresja źródeł PASS.
5. Integracja zasobów z prawdziwą symulacją 95%.
6. Niezależne skale pięciu typów 85%.
7. Audyt 60 akcji 20%.
8. Router wejścia 0%.
9. Przewijane menu 65 pozycji 0%.
10. Migracja ustawień 0%.
11. Regresje/testy końcowe 55%.
12. IPA po aktualizacji abilities 55% (nowa IPA **nie** została jeszcze wydana).
Przy równych wagach: 57% w przybliżeniu.

## Następny krok
Odebrać wynik Release ARM64 dla aktualnego kodu, spakować bez zmiany EXE wszystkie 15 zweryfikowanych zasobów GLB/Mesh/JPEG i sprawdzić `default.metallib`, ARM64, CRC, SHA256 i tożsamość EXE. Następnie przejść do następnego punktu stałego harmonogramu: router 60 akcji i przewijane menu — bez cofania zmian HUD/H55/H71.
