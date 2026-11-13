## BLOKADA ZATWIERDZONEJ BAZY — WYMAGANA ZGODA UŻYTKOWNIKA (13.11.2026)

**Nadrzędne polecenie użytkownika po scaleniu PR #36.** Zatwierdzony stan `main`, w tym VANGUARD, BASTION, KESTREL, animowany BOREAS, naprawy IPA, H55/H290, HUD oraz istniejące mechaniki, jest bazą **nietykalną bez uprzedniej, wyraźnej zgody użytkownika**. Dotyczy to także optymalizacji, porządkowania i „drobnych” poprawek.

1. **ZANIM COKOLWIEK ZMIENISZ** w ASTEROIDY iOS (kod, dane, modele, animacje, konfigurację, testy, workflow GitHub Actions, instrukcje, gałęzie, PR lub `main`), opisz dokładnie planowane zmiany oraz co pozostanie nietknięte. Wyświetl użytkownikowi interaktywny przycisk potwierdzenia z jednoznacznym komunikatem, np. „Zatwierdzam wskazane zmiany ASTEROIDY iOS”. Nie traktuj samej prośby o analizę, diagnostykę czy przygotowanie planu jako zgody na zapis.
2. **BRAK KLIKNIĘCIA = BRAK MODYFIKACJI.** Przed otrzymaniem potwierdzenia wykonuj wyłącznie operacje odczytu, porównania i diagnostykę bez skutków ubocznych. Nie twórz commitów, PR, gałęzi ani nie uruchamiaj zadań mogących modyfikować repozytorium lub jego stan.
3. Zgoda dotyczy **wyłącznie zakresu wskazanego w komunikacie**. Każda kolejna, rozszerzona albo niezależna zmiana wymaga ponownego przycisku i zgody. Nie traktuj starej zgody jako blankietowego upoważnienia.
4. **Nie używaj force-push, resetu `main`, nadpisywania historii ani usuwania zatwierdzonych elementów.** Nowy kod rozwijaj na osobnej gałęzi dopiero po zatwierdzeniu zakresu; scalenie do `main` wymaga odrębnego potwierdzenia i pełnych testów regresji.
5. Jeśli środowisko nie udostępnia interaktywnego przycisku, **nie wykonuj zmian na podstawie milczenia**. Poproś o jednoznaczne potwierdzenie w obsługiwanym interfejsie. Tekstowa zasada w repozytorium nie zastępuje technicznej blokady GitHub (branch protection/ruleset); nie deklaruj jej włączenia bez sprawdzenia ustawień.
6. Wyjątek dla tego jednorazowego zapisu: użytkownik wyraźnie zlecił ustanowienie niniejszej ochrony. Nie wykorzystuj tego upoważnienia do żadnych dodatkowych zmian w grze.

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
- Regresja pasa: `.github/workflows/source-tests.yml` (job `verify-pc602-belt`) obejmuje rzeczywisty generator .NET, kontrolę wszystkich siatek Python oraz loader Swift; przy zmianie kodu renderera iOS dodatkowo wymagana jest `.github/workflows/mac-tests.yml` (job `source-home-metal`, faktyczny iPhone+iPad ARM64). Testy Linux, SHA/CRC i kompilacja bez GPU nie dowodzą wyglądu ani FPS na urządzeniu.


- **PC602 wrak 3D / H55 Dock209:** wrak orbitujący wokół H290 NIE jest osobnym GLB. Jest autorskim proceduralnym źródłem C# `GpuIntro41.DrawDetailedResearchWreck211(211,true)`. Pozycja i rotacje całego obiektu MUSZĄ pochodzić z `NewHome290.WreckPosition`, `Rotate(31° Y)`, `Rotate(-9° Z)`, `Scale(0.6048)`, a rzeczywisty promień dokowania z `DockRadius295=43.2`. Nie zastępować kadłuba generatywnym GLB ani kulą. `PC602WreckDebris209.swift` zawiera już 146 oryginalnych plus 15 dodatkowych odłamków i 1932 oryginalne konstrukcyjne trójkąty kostek; **kompletny oryginalny kadłub, śluzy, zabrudzenia, rysy i 7 faz dynamicznych lamp zostały już ponownie użyte** z `ResearchWreckGeometry214.makeOrbitHome602()` przez `SourceHomeWreck209.swift`; trzeba jeszcze potwierdzić prawdziwy iOS GPU i doprowadzić do grywalnej integracji sceny.
- `PC602HomeHubRoute90.swift` to osobna, zweryfikowana przejściówka źródłowych stanów `Hub90.EnterHub90`, `EnterMenuHangar397` i `ExitHub90`. Orbitę można przerwać na rzecz H55 tylko jeśli live `HomeFlight291.canDock90` potwierdzi rzeczywistą odległość, a wejście do H55 z W3 ma wrócić do menu bez automatycznego zapisu kampanii. Wykorzystać tę samą istniejącą `H55ScenePage580`, `H55Entry580`, `H55Arrival580`; nie tworzyć drugiej sceny H55, własnego spawn pointu ani odliczania. **Nie jest jeszcze spięte z aktywnym App.swift.**
- Źródłowe testy `.github/workflows/source-tests.yml` (job `original-wreck-and-dock`; Ubuntu/Swift, rzeczywisty Sphere67/FlightDynamics, hash i geometryczne rekordy wraku) mają PASS. Nowe Swift i ich shader/render wymagają również pełnej kompilacji macOS iPhone+iPad ARM64 oraz interaktywnego sprawdzenia GPU przed jakimkolwiek stwierdzeniem, że planeta jest grywalna. Nie wydawać niedokończonego IPA jako końcowej wersji.

- **PC602 kompletny wrak orbitalny:** korzystać z `ResearchWreckGeometry214.makeOrbitHome602()` — zawiera oryginalne i JEDYNE źródło wszystkich paneli, śluz, okien, anten, zabrudzeń, zadrapań i 7 migających lamp. Różnica wobec istniejącego sprawnego wariantu bojowego to tylko dokładny `seed:211, debris:146, trail:178`; `ResearchWreckGeometry214.make(sector:)` musi zachować 112 odłamków, 118m i dotychczasowy wygląd. Nie implementować drugiego kopiowanego generatora, nie używać wyłącznie częściowych kostek `PC602WreckDebris209` jako pełnego kadłuba, nie dublować odłamków w shaderach.
- `SourceHomeWreck209.swift` wykorzystuje istniejący shader `Sector01Carbonis568.metal` (11-float hull, 7-float scratches) z prawdziwą `SunDirection111` i oryginalnym przemnożeniem `T(WreckPosition)*Ry(31)*Rz(-9)*Scale(.6048)`, bez ciągłego przebudowywania geometrii. Obecna implementacja świadomie nie twierdzi, że odtwarza pixel-perfect fixed-function GL oświetlenie. Cały świat `PC602HomeScene291` nadal jest niezależny od aktywnej ścieżki W3/H55/Carbonis.
- Test `Tests/PC602OrbitWreck211Tests.swift` porównuje wszystkie dane bazowego kadłuba i linii rys po rzeczywistej granicy danych; należy go utrzymywać przy zmianach. Nie publikować IPA z niekompletną grą orbitalną pod etykietą gotowej głównej planety.


- **PC602 źródłowy Vanguard431 / HomeShipPose291:** dla faktycznej planety głównej v602 statkiem grającym może być tylko **prawdziwy model wybranego typu**. Zweryfikowany ShipType=1 VANGUARD431 ma 194427 oryginalnych wierzchołków i 2 punkty dysz, SHA256 źródłowego pełnego `Vanguard431Source.mesh` `f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a`, JPEG `2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95`. Źródłowy C# `Vanguard431.TryApply` ma tylko slot materiałowy 0. Używać istniejących poprawnych zasobów i shaderów `sourceVanguardVertex431` + `sourceVanguardTexturedToonFragment431` zamiast ponownie przerabiać GLB. `PC602HomeShipPose291` odtwarza `HomeFlight291.cs:144-158`: poziom +12 m, nos kierunek VisualHeading81, skrzydło Cross(heading,surface), bank Ry/ pitch Rx, współczynnik `11.2*((144.19674+15)/(720/PI))*.65*1.35` = ok. 6.826792, *dodatkowo* źródłowy suwak `OrbitShipScale472`. Nie nadpisywać go skalą podglądu W3, misji ani własną oceną z obrazu. 5 pozostałych craft nadal wymaga osobnych modeli; nigdy nie zastępować ich VANGUARD-em po cichu. Dwie oryginalne dysze i `DrawCraftModules95` nie są jeszcze wdrożone jako efekty w nowej scenie.
- **PC602 pojedynczy kontroler świata:** `PC602HomeWorldSession291.swift` jest jedynym przyszłym właścicielem źródłowej fizyki i statusu sesji orbitalnej. `PC602HomeFlightInput291.swift` musi pobierać faktycznie wybrane akcje z `SourceControls586.Profile` + `SourceHardwareInput586.Snapshot` — nie dodawać kopii statycznej tabeli klawiszy iOS i nie ignorować zatwierdzonego remapowania. Zachować oddzielne stany pauzy, 26 celów misji i `Hub90.CanDock90`; żadnych losowych sukcesów misji przy dotarciu do punktu. Nie podłączać częściowego trybu do działającego W3/Carbonis/H55 przed pełną i sprawdzoną integracją. Linux Swift z asercjami PASS: https://github.com/synixad-png/asteroidy-ios/actions/runs/43093484237. Automatyczne testy nie dowodzą jeszcze, że app działa na iPhonie ani że istnieje instalowalna IPA.


## Blokada edytora HUD misji CARBONIS 01 (polecenie użytkownika 12.11.2026)

Podczas napraw H290 **nie wolno edytować** działającego edytora HUD misji:
`ASTEROIDYiOS/HudLayoutEditor600.swift`,
`ASTEROIDYiOS/HudControlLayout600.swift`,
`ASTEROIDYiOS/HudLayout600.swift`,
`ASTEROIDYiOS/HudEditorGeometry.swift` ani jego integracji
`ASTEROIDYiOS/Sector01Scene568.swift`.
Edytor H290 używa **wyłącznie** własnych plików `PC602OrbitHUDLayout291`,
`PC602OrbitHUDEditor291` i aktywnego `PC602HomeWorldPage291`.
Test `Tests/PC602UnifiedHUDMenu291Contract.py` sprawdza niezmienność
pięciu plików źródłowych edytora misji na podstawie ich blob SHA Git.
Modyfikacja tych plików jest zabroniona bez osobnego, wyraźnego
polecenia użytkownika dotyczącego misji i świadomej aktualizacji
odpowiadającego im testu. Weryfikacja kompilacji nie zastępuje
interaktywnego testu przenoszenia przycisków na iPhonie/iPadzie.


## Stała polityka gałęzi i kompletnego IPA — stan po scaleniu PR #36 (13.11.2026)

**Najnowsza wyraźna decyzja użytkownika:** działające testowe IPA zostało zaakceptowane i zależny łańcuch KESTREL, BOREAS oraz naprawy został scalony do `main` przez PR #36, commit `c51c0f54c096a1197cf3e3699535e9b0c7fbace4`. Ta decyzja zastępuje dawny zakaz scalenia PR #32/#33. Przed każdą kolejną pracą czytaj aktualny `main` i aktualne PR; nie wnioskuj ze starszego opisu gałęzi, że funkcji brakuje.

1. **BAZA ROZWOJU:** bieżący `main` zawiera kod KESTRELA, BOREASA (97 oryginalnych kanałów animacji), poprawek H55/H290, dekodowania RFC1950 i napraw startu scen. Gałęzie `feature/ios-kestrel-pc609` oraz `feature/ios-boreas-test-05` są historią zależnych PR #32/#33; zachowaj je, nie usuwaj automatycznie i nie implementuj ponownie ich zmian. PR #36 jest scalony.
2. **IPA MA BYĆ SAMOWYSTARCZALNE W ZAKRESIE OBIEKTÓW GRY:** wszystkie wymagane modele, tekstury i animacje, w tym oryginalne VANGUARD, BASTION, KESTREL i BOREAS (97 kanałów), wbudowuj w IPA i ładuj bez ręcznego importu. Brak któregokolwiek obiektu nie pozwala na deklarację kompletnego IPA.
3. **JEDYNY WYJĄTEK — HANGAR:** pełny `hangar_h55.glb` pozostaje importowany oddzielnie zatwierdzonym mechanizmem H55. Nie wbudowuj hangaru tylko dla ujednolicenia.
4. **WYBÓR ŹRÓDŁA BUILDU:** kolejne zmiany i wydania bazuj na aktualnym `main`, po zweryfikowaniu SHA i kodu. Nie buduj nowych wersji z historycznych gałęzi bez nowego wyraźnego polecenia; nie kopiuj funkcji już scalonych.
5. **ŹRÓDŁA OBIEKTÓW:** wyłącznie oryginalne, zweryfikowane zasoby PC609 i oryginalne importery danych; żadnych zastępczych siatek, duplikacji renderera czy pozornej implementacji. Kontroluj SHA-256 i końcową zawartość IPA.
6. **BRAMKA ODBIORU IPA:** kompilacja iPhone/iPad ARM64, integralność ZIP/IPA, wymagane zasoby, testy modeli i BOREASA oraz regresji HUD, H55, zapisów, tarcz v608 i pancerza v609. Oddziel wyniki CI od fizycznych testów urządzeń. Użytkownik potwierdził działanie wcześniejszego testowego IPA, ale nie jest to automatyczny test nowego buildu z `main`.
7. **NIE DOPISUJ PONOWNIE SCALONYCH FUNKCJI:** porównaj stan `main`, PR, merge-base i aktualne testy przed zmianą; nie dubluj istniejących ścieżek. Nie usuwaj historycznych gałęzi ani niezgłoszonych commitów bez analizy.
8. **ODTWARZALNOŚĆ MIĘDZY ROZMOWAMI:** odczytuj ten plik, bieżący `main`, status PR i Actions przed zadaniem. Nie przywracaj historycznej polityki zakazu integracji KESTRELA/BOREASA.
