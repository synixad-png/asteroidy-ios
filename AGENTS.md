# AGENTS.md — stałe reguły jakości ASTEROIDY iOS

**Obowiązuje przy każdej następnej zmianie, PR, audycie, optymalizacji i wydaniu.**
Użytkownik wyraźnie zakazał „AI slop / slap code”: kodu pozornego, prowizorycznego,
powielanego, trudnego do poprawiania oraz niezweryfikowanych „optymalizacji”.
Ten dokument jest wymaganiem repozytorium, a nie propozycją.

## Podstawowe zasady

1. **Nie zgaduj oryginalnej gry.** Wierność zachowania ma wynikać z konkretnych
   źródeł ASTEROIDY Windows/SteamOS v568, istniejącego portu lub zweryfikowanego
   testu użytkownika. Nie podmieniaj brakujących danych źródłowych innymi.
   Jeśli mechaniki/zasobu nie da się zweryfikować, wskaż „nie wiem”, nie dopisuj
   hipotetycznej implementacji.
2. **Małe, ograniczone zmiany.** Najpierw odczytaj kod i zależności; ustal
   przyczynę na podstawie logów/testów, potem zmieniaj najmniejszy konieczny
   fragment. Nie dodawaj kolejnego równoległego rozwiązania obok aktywnego.
   Usuń nieużywany wariant po potwierdzeniu, że nie jest potrzebny testom ani
   innym scenom. Nie komplikuj kodu nowymi warstwami bez konkretnego powodu.
3. **Jedna odpowiedzialność.** Renderowanie Metal, symulacja, audio, HUD,
   zasoby, stan zapisu i diagnostyka powinny mieć odrębne API i właścicieli.
   Uogólniaj wyłącznie autentycznie wspólną logikę; powtarzanych bloków
   nie kopiuj w nowe miejsca. Unikaj plików „god objects”. W istniejących
   dużych modułach rozdzielaj odpowiedzialności stopniowo, z testami, zamiast
   przepisywać całość w jednym niezabezpieczonym commicie.
4. **Zero pozornego działania.** Żadnych atrap HUD-u, dźwięków, planet, fizyki,
   misji, liczników, FPS i podmienionych modeli przedstawianych jako oryginał.
   Nie wprowadzaj nieużywanych suwaków, pustych przycisków, tymczasowych
   obejść, martwych flag ani fałszywie zielonych testów.
5. **Obsługuj błędy jawnie.** W krytycznych ścieżkach nie stosuj
   `try!`, `as!`, `fatalError`, pustych `catch`, ukrywania błędów zapisu
   pliku ani dowolnego fallbacku. Jedyny zaakceptowany wyjątek to
   dwa strażniki nieistniejących kluczy oryginalnych filtrów SOS w
   `OriginalMusicSynth568.swift`, objęte dokładnym testem
   `Tests/OriginalMusicFilterKeys568Contract.py`; nie zamieniaj ich na
   hipotetyczne współczynniki ani nie dodawaj nowych bez testu.
   Oczekiwane braki zasobów mogą dawać
   bezpieczne `nil`, ale stan musi być rozpoznawalny, a test musi odróżniać
   brak od sukcesu. Diagnostyka nie może udawać ukończenia testu.
6. **Nie degraduj klatek.** W ścieżce klatki i `MTKViewDelegate.draw(in:)`
   unikaj odczytów dysku, budowania pipeline'ów i tekstur, synchronicznych
   wywołań audio, pracy blokującej główny wątek oraz nieograniczonych
   kolejek/allocacji. Zmianę wydajności oceniaj pomiarami CPU/GPU/wait i
   rzeczywistymi FPS, nie samą kompilacją ani spekulacją.
7. **Chronione zachowania:** potwierdzone przez użytkownika 60 FPS po
   wyprowadzeniu SFX poza główny wątek; poprawne iPad 4:3 i iPhone 15 Pro Max
   19.5:9; sterowanie lewa/prawa strona (automatyczny ogień przy dotyku prawej),
   pauza, oryginalne SFX i ich odtworzenie po wygaszeniu ekranu; właściwe
   źródłowe elementy HUD-u; sekwencje misji, uszkodzenia, zapis i nagrody.
   Żadnej regresji iPada przy naprawie iPhone'a.
8. **Utrzymuj czyste zależności.** Nie usuwaj źródeł Windows/SteamOS ani
   oryginalnych zasobów używanych do porównania, testów i odtwarzania
   kompilacji. Nie „sprzątaj” ślepo wersjonowanych plików, dopóki nie sprawdzisz
   importów, zasobów runtime i wszystkich testów.
9. **Test przed scaleniem:** test źródłowy + deterministyczny test mechaniki
   + regresja istniejących funkcji + faktyczna kompilacja Swift/Metal iOS.
   Przy zmianach UI uwzględnij bezpieczne obszary 4:3/19.5:9, a przy
   zmianach audio/FX testy FPS, pauzy i wybudzania. CI nie zastępuje
   interaktywnego testu urządzenia. Bez dowodu nie deklaruj zgodności 1:1,
   gotowego IPA, działania 60 FPS ani pełnego ukończenia gry.
10. **Dokumentuj trwałe ustalenia:** PR ma wskazywać konkretną przyczynę
    zmiany, źródło/raport, zakres zmodyfikowanych plików, testy, świadomie
    nietknięte mechanizmy i ograniczenia. Każde uproszczenie kodu ma
    usuwać konkretny problem, nie powiększać repo dla pozoru postępu.

## Stała kontrola jakości

- Uruchamiaj `python3 Tools/code_quality_audit.py --root . --gate` oraz
  `python3 Tests/CodeQualityAuditTests.py` i
  `python3 Tests/OriginalMusicFilterKeys568Contract.py`; raport audytu jest artefaktem CI.
- Statyczne ostrzeżenie to **kandydat** do ręcznej oceny, nie automatyczny
  dowód błędu. Nie kasuj funkcji tylko dlatego, że ma wiele linii.
- Nie „naprawiaj” wymagań ani testów tylko po to, aby były zielone. Zmiany
  kontraktu muszą zachować jego pierwotną intencję.
- Priorytet refaktoryzacji: potwierdzony błąd albo ryzyko regresji →
  duplikacja i granice modułów → usprawnienie czytelności, bez zmiany
  funkcjonalności i bez wzrostu kosztu każdej klatki.
- Zapisuj otwarte ryzyka w `Reports/CODE_QUALITY_AUDIT_2026-11-08.md`;
  nie uznawaj ich za rozwiązane bez testu.

## PC v602 — główna planeta orbitalna NewHome290 (2026-11-11)

- Źródłem prawdy jest oryginalny ZIP ASTEROIDY PC v602 SHA256 `359abd889544c846faa9426fd291df8528951ed2253fe67c47dbb9e9d9f2103b`. Odtwarzać mechanikę zgodnie z `NewHome290.cs`, `HomeFlight291.cs`, `Orbit50.cs`, `OrbitWorld51.cs`, `SphereCombat67.cs`, `FlightDynamics298.cs`, `GpuNewHome290.cs`.
- NIE utożsamiać planety głównej z `HudPlanetarium...`, podglądem `W3HomePlanetMetal568`, ani planetą bojową CARBONIS/C279. Te systemy mają różne renderery, skalę i przeznaczenie.
- Wszystkie źródłowe dane runtime wymagane w nowym porcie umieszczać w repozytorium (lub odtwarzać deterministycznie z obecnych czterech SHA-pinned archiwów GitHub); nie uzależniać wydania od plików poza repozytorium.
- **Pełnego ZIP-a z PC v602 nie dodawać do GitHuba.** Zostaje w Bibliotece ChatGPT jako źródło odniesienia. Przenosić wyłącznie te pojedyncze źródła, zasoby i narzędzia, które są potrzebne do właśnie wdrażanej funkcji. Duże już istniejące archiwa v568/PC586 wykorzystać ponownie i zweryfikować SHA-256, nie duplikować w GitHubie.
- Import nowego komponentu nie oznacza jego aktywacji w grze. Zmiany podłączenia do menu i H55 dopiero gdy oryginalny renderer świata, statek, pas asteroid, wrak, dokowanie, misje i regresja przejdą testy. W raporcie oddzielać kod przygotowany od grywalnej funkcji.
- Oryginalna siatka 172208 trójkątów, 2 materiały, bazowy JPEG, `home293.glow.png` i mapa fizyczna 512×256 muszą być byte-verified; bez proceduralnych zamienników. W v602 SHA tych trzech plików jest identyczne jak w GitHub v568. Importer/CI: `Tools/stage_pc602_newhome290.py`.
- Przed aktywacją trybu planeta główna wymagane są realny `HomeFlight291`, `HomeScene291`/Metal, źródłowe 820 asteroid, wrak dokujący, wejścia w misje i H55. Nie zastępować lotu fałszywą animacją podglądu. NIE zmieniać obecnego przycisku NOWA GRA, dopóki źródłowe mechanizmy i testy nie przejdą.
- Testy źródła i status nieukończenia: `Tests/PC602NewHome290Tests.swift` i `Reports/PC602_NEW_HOME290_SOURCE_PORT_2026-11-11.md`. Zgodność danych wysokości != ukończony świat orbitalny lub gotowe IPA.
- **Pas 820 asteroid PC602:** używać źródłowego `OrbitWorld51.BuildBelt51` i `GpuIntro41.PrepareIntroBelt` z `Tools/PC602OrbitBelt51.cs`, a nie zastępczych sfer lub przybliżonych siatek. Generator uruchamia się poza grą iOS podczas budowania przez `Tools/stage_pc602_orbit_belt51.py`; końcowy zasób `PC602OrbitBelt51.bin` (50 403 776 bajtów w przebiegu Ubuntu .NET8, 820 asteroid, 419 840 trójkątów) musi być w docelowej aplikacji. Na GitHubie pozostawić generator i źródło H290, nie pełny v602 ZIP ani dodatkowy duplikat 50 MB.
- Nie poprawiać źródłowych normalnych `StoneNormal56` „do długości 1” w pliku: `IntroScene41.P.Unit` stosuje `max(.00001f,Length)`; wiele krótkich oryginalnych normalnych jest autentycznych. Nie dopisywać hipotetycznych kolizji asteroid do nowego `HomeFlight291`, który w PC używa `MoveShip67`; `OrbitWorld51.Move51` jest osobną ścieżką legacy.
- Regresja pasa: `.github/workflows/verify-pc602-belt-source.yml` obejmuje rzeczywisty generator .NET, kontrolę wszystkich siatek Python oraz loader Swift; przy zmianie kodu renderera iOS dodatkowo wymagana jest `.github/workflows/verify-pc602-home-metal291.yml` (faktyczny iPhone+iPad ARM64). Testy Linux, SHA/CRC i kompilacja bez GPU nie dowodzą wyglądu ani FPS na urządzeniu.


- **PC602 wrak 3D / H55 Dock209:** wrak orbitujący wokół H290 NIE jest osobnym GLB. Jest autorskim proceduralnym źródłem C# `GpuIntro41.DrawDetailedResearchWreck211(211,true)`. Pozycja i rotacje całego obiektu MUSZĄ pochodzić z `NewHome290.WreckPosition`, `Rotate(31° Y)`, `Rotate(-9° Z)`, `Scale(0.6048)`, a rzeczywisty promień dokowania z `DockRadius295=43.2`. Nie zastępować kadłuba generatywnym GLB ani kulą. `PC602WreckDebris209.swift` zawiera już 146 oryginalnych plus 15 dodatkowych odłamków i 1932 oryginalne konstrukcyjne trójkąty kostek; **brakuje** właściwego kadłuba, śluz, smug zabrudzeń, zadrapań i dynamicznych lamp, pełnego renderowania iOS.
- `PC602HomeHubRoute90.swift` to osobna, zweryfikowana przejściówka źródłowych stanów `Hub90.EnterHub90`, `EnterMenuHangar397` i `ExitHub90`. Orbitę można przerwać na rzecz H55 tylko jeśli live `HomeFlight291.canDock90` potwierdzi rzeczywistą odległość, a wejście do H55 z W3 ma wrócić do menu bez automatycznego zapisu kampanii. Wykorzystać tę samą istniejącą `H55ScenePage580`, `H55Entry580`, `H55Arrival580`; nie tworzyć drugiej sceny H55, własnego spawn pointu ani odliczania. **Nie jest jeszcze spięte z aktywnym App.swift.**
- Źródłowe testy `.github/workflows/verify-pc602-wreck-dock209.yml` (Ubuntu/Swift, rzeczywisty Sphere67/FlightDynamics, hash i geometryczne rekordy wraku) mają PASS. Nowe Swift i ich shader/render wymagają również pełnej kompilacji macOS iPhone+iPad ARM64 oraz interaktywnego sprawdzenia GPU przed jakimkolwiek stwierdzeniem, że planeta jest grywalna. Nie wydawać niedokończonego IPA jako końcowej wersji.
