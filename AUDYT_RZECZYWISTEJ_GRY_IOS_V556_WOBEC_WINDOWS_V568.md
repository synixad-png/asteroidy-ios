# ASTEROIDY iOS — zweryfikowany punkt odniesienia i plan odchodzenia od prototypu

Data: 2026-11-05. Repozytorium iOS: `synixad-png/asteroidy-ios`.

## Źródło pierwowzoru, nie zgadywać

W Bibliotece użytkownika rzeczywiście odnaleziono i zweryfikowano archiwum `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (150 473 406 B, 1 788 plików, SHA256 `271229a995c6e0a096ec401ba969c795a2fe4a4954462465ec1de2e1af5caaa7`). Jest to *późniejszy* wariant gry PC niż dotychczasowa referencja C# v556 portu iOS. Przenoszenie zachowania między v556 i v568 musi być oparte na jawnej weryfikacji różnic, a nie cichej zamianie baz.

Sprawdzone rzeczywiste pliki oryginału:
- `Windows/src/Game.cs`: `Mode` obejmuje `Menu, Playing, Paused, GameOver, Shop, Victory, Tunnel, Jump, Intro, Orbit, Hub90, StoryPrologue359`; `Mode=Mode.Menu` przy starcie (linie 26, 68); `Wave()` buduje obiekty i przeciwników (90–100), `Start()` czyści i ustawia pełną grę (104).
- `Windows/src/Program.cs`: okno tworzy oryginalny `Game` z `SceneTransitions=true, PlanetHub50=true, SphereCombat67=true` (19), a główna akcja z menu wywołuje `StartCampaign()` (np. 180).
- `Windows/src/RendererW3Home328.cs`: faktyczne siedem elementów HOME to `NOWA GRA`, `KONTYNUUJ`, `KAMPANIA`, `HANGAR`, `USTAWIENIA`, `AUTORZY`, `WYJŚCIE` (11–12); ekran ma układ paneli HOME, podgląd obracanej planety i statku (45–61, 219–289).
- `Windows/src/GpuIntro41.cs`: oryginalny pas intro opiera się na `OrbitWorld50.Belt51` i 820 modelach kamieni, z oryginalną geometrią i cullingiem (4–21); nie oznacza to, że 820 asteroid ma pojawić się w każdej misji.
- `Windows/src/Orbit50.cs`: `EnterOrbit50` i `LaunchOrbitMission50` sterują przejściem do misji (46, 53), nie jest to ekwiwalent samego `SphereSector556`.

## Stan porównywanego portu iOS

- `ASTEROIDYiOS/GameCore.swift` zawiera odseparowaną, płaską scenę treningową; domyślny licznik to 9 asteroid, nie oryginalny stan `Game.Mode.Menu`.
- `ASTEROIDYiOS/SphereSector556.swift` świadomie opisuje się jako izolowany *test sector*, bez całego kontrolera misji, pełnego AI, bossów czy odblokowań kampanii.
- `ASTEROIDYiOS/App.swift` dotąd otwierał płaską scenę. Od aktualizacji `46a7ded` defaultem jest istniejący renderer oryginalnego `Boreas556.as3d`; arena pozostaje dostępna diagnostycznie. **To poprawa punktu wejścia dla testów grafiki, nie port oryginalnego HOME ani prawdziwa misja 01.**
- `ASTEROIDYiOS/CampaignProgress556.swift` zawiera logikę maski odblokowań, ale atlas jest tylko do odczytu; nie wolno przyznawać za jego pomocą ukończeń misji diagnostycznych.

## Następna praca — bez zmiany stałej listy 18 zadań

**Bieżące zadanie 2 — Metal (nadal otwarte):**
1. Potwierdzić kompilację najnowszego `App.swift` i `MetalRenderer.swift` przez Xcode bez IPA; następnie zweryfikować render/culling/skalę z modeli i oryginalnego `GpuSphere67`. Nie przypisywać PASS z testów Swift/Linux do Apple GPU.
2. Związać rzeczywiste obiekty renderingu oraz parametry kamer, efektów i sekwencji ze źródłem v556; używać v568 tylko po sprawdzeniu zmian między wersjami.
3. Do porównań wizualnych używać wyłącznie autentycznych klatek aplikacji i rzeczywistej gry źródłowej. Nie prezentować zewnętrznych screenów jako wyniku portowania.

**Kiedy zadanie 2 zostanie domknięte:** kontynuować istniejące zadania 3–6 (PBR, zasoby GLB, animacje, fizyka); zachować testy i gotowe moduły 7–8. Dopiero po integracji zależności wdrażać zadania 9–14: pełne bronie, AI/bossów, prawdziwy kontroler misji i źródłowe HOME W3. Brakujące procedury muszą pochodzić z oryginalnego kodu, nie z diagnostycznego `GameCore`. Odrębne zadanie 18 obejmie testy na fizycznych iPhone/iPad.

## Konfiguracja obu urządzeń

`project.yml` już miało `TARGETED_DEVICE_FAMILY='1,2'`; jednorazowe IPA z run `42090319849` celowo wymuszało tylko iPhone. Dla następnego **wyraźnie zamówionego** IPA dodano `.github/workflows/build-ios-iphone-ipad-manual.yml`, `workflow_dispatch` only, `macos-15-intel`, `ARCHS=arm64`, `TARGETED_DEVICE_FAMILY=1,2`, weryfikacja `Tools/verify_ipa.py` sprawdza `UIDeviceFamily={1,2}`. Stare IPA nie zyskuje obsługi iPada wstecznie. Nowe IPA nie zostało wygenerowane.

**Status testów na dzień aktualizacji:** nowe testy kontraktu startowego i zasobów Swift/Linux zakończyły się PASS w run `42093245632`. Test Metal/Xcode w run `42093300828` oczekiwał na macOS; testu nowych zmian na prawdziwym telefonie/tablecie nie wykonano. Bez potwierdzenia nie podwyższać historycznych postępów zadania 1=88%, zadania 2=68%, całego portu=27%.

## Aktualizacja: źródłowe siatki asteroid przelotu — 05.11.2026

Nowy `ASTEROIDYiOS/IntroRockGeometry41.swift` portuje dokładnie wskazane procedury z `Windows/src/GpuIntro41.cs:13–21` i `Windows/src/PlanetLife52.cs:12`: ikosaedr i 20 trójkątów, deterministyczną deformację `IntroStone(p,seed)` z trzema kraterami, finite-difference `StoneNormal56`, odwracanie kolejności wierzchołków przy ujemnym iloczynie wektorowym, oryginalne tony RGB i mnożniki co siódmego seeda oraz oryginalną rekurencję podziału (`size>1.15 ? 3 : 2`, tj. 1280 lub 320 trójkątów na skałę). Sformułowanie "dokładnie" oznacza zgodność przeniesionych wzorów i struktury, **nie** pikselową tożsamość CPU Swift/Metal/GDI+, którą należy osobno potwierdzić. Wspólna skala świata to `1/144.19674`.

Renderer `MetalRenderer.swift` nie generuje wszystkich ~820 szczegółowych siatek przy starcie. Dla faktycznie widocznych skał buduje maksymalnie jedną geometrię na klatkę, przechowuje do 256 GPUModel z FIFO, a dopóki szczegółowy model nie jest dostępny używa starego oktaedru tylko jako jawnego placeholdera w tej klatce. W razie błędu alokacji skała zachowuje proxy i rejestrowana jest diagnostyka, bez blokady całego widoku. To **nie** potwierdza stabilnych 60 FPS; czas generowania oraz pamięć muszą zostać zmierzone na urządzeniu. W pełni bez tymczasowej geometrii dopiero wtedy, gdy aktywne widoczne skały mają już swoje siatki.

`Tests/IntroRockGeometry41Tests.swift` obejmuje liczbę trójkątów i wierzchołków obu poziomów, normalne i kolory oraz efekt seeda; `Tests/IntroOrbitSourceContract41.py` pilnuje połączenia geometrii z prawdziwym Metal i cache. Istniejąca kontrola `verify-metal-camera.yml` kompiluje oba testy na Linux, a `verify-ios-inputs.yml` parsuje źródła Swift. Po dodaniu generatora *nie należy* ponownie deklarować wyniku PASS starej rewizji jako testu obecnej: wyniki wymagają nowego przebiegu GitHub Actions, a natywny Xcode/Metal i fizyczny iPhone/iPad pozostają niezweryfikowane. Nowego IPA nie wywołano. Numer zadania 2 w stałym harmonogramie pozostaje 70% do czasu zakończenia testów.

## Dalszy audyt i integracja renderera, 05.11.2026 — rzeczywisty IntroSky i obrót Belt51

Porównano lokalnie faktycznie dostarczone archiwum PC v568, konkretnie `Windows/src/GpuIntro41.cs:451–455,490–493`, `Windows/src/Intro41.cs:50–81` i `Windows/src/OrbitWorld51.cs`. Potwierdzono brakujące względem iOS szczegóły:
- Oryginalny pas jest renderowany po `shipTranslate(PlanetCenter)` i `shipRotate(time*.2f, 0,1,0)`. W iOS wcześniej wszystkie skały pozostawały nieruchome. Obecnie `IntroOrbit41.beltRotationDegrees` i `beltWorldPosition` oraz macierz Metal `T(PlanetCenter)*Ry(time*.2)*T(rock.center)` zapewniają spójny obrót całości i testy cullingu na identycznie obróconych pozycjach. Zachowano wariant legacy generatora; nowy `NewHome290.Enabled` w v568 wymaga osobno autentycznej geometrii i nie jest przez to naprawiony.
- `CinematicIntro41` wywołuje pełne `IntroSky(glow,nebula,rays)`: 24 mgławice dalekie, 3 teksturowane planety, 3-warstwową czarną dziurę, 12 mgławic bliskich, 1500 gwiazd i pięć promieni słonecznych. W iOS cinematic rysował dotychczas **tylko 1500 gwiazd**. Przeniesiono pełne istniejące już procedury shaderów/tekstur ze zweryfikowanego trybu `GpuSphere67` do rozłącznej sceny intro, bez zmiany kodu trybu sferycznego. Dla projekcji `SkyProject55` dodano `IntroOrbit41.skyCamera(time:)`, która pobiera rzeczywiste osie right/up/focus z `IntroScene41.frame`. Kolejność nakładek zachowuje oryginał. Duże tekstury nadal korzystają z cache lazy GPU, bez kopiowania bitmap między trybami.
- Dodano numeryczne przypadki źródłowego obrotu Belt51 (0/10/16 s) oraz zgodności osi IntroSky do `Tests/IntroOrbit41Tests.swift` i ochronę kolejności efektów w `Tests/IntroOrbitSourceContract41.py`. Zaktualizowano stary kontrakt `SkyTextureGateSourceContract55.py`, aby sprawdzał właściwy renderer sferyczny zamiast mylić dwa tryby i pierwszy napotkany fragment sky.
- `Tests/IntroOrbit41Tests.swift` początkowo wykrył błąd składni w nowym teście wielowierszowego operatora Swift; naprawiono go w commit `0d2b07f`. Kontrola parsowania Swift i oryginalnych zasobów GitHub run `42100472060` **PASS**. Pełne testy numeryczne po poprawce i kompilacja Apple Metal dla ostatecznego pakietu źródeł nadal **oczekują na potwierdzenie** w run `42100560721` (source-camera-linux wykonywany, Xcode w kolejce). Nie przenosić na tę rewizję wcześniejszych zielonych wyników.
- Wciąż nie ma materiałów NewHome290, pełnych źródłowych materiałów PBR/tekstur planet i wszystkich źródłowych efektów biome/DrawPlanetLava/DrawWeather. Nie wywołano nowego IPA ani nie sprawdzono tego na iPhonie/iPadzie. Numery wykonanych etapów 18 pozostają niezmienione; zadanie 2 w ostatnim zatwierdzonym raporcie 72%, projekt 27% odniesienia.

## 05.11.2026 — poprawka animacji Boreas w intro i kosztu budowy Belt51

Źródło: **rzeczywiste** archiwum użytkownika `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`. `Windows/src/GpuIntro41.cs:490,492` wywołuje `EnsureIntroPlanet(game.Level)`, ustawia `weatherTime65=time` i rysuje `DrawPlanetSolid()`. `Windows/src/GpuPlanet.cs:149` wywołuje `DrawReplacedPlanet463(weatherTime65,true)` z `Windows/src/GpuPlanetGltf463.cs:70–73`, a to wykonuje `planetGltf463.AnimatePlanet463(time,true)`. W iOS wcześniej animacja `BoreasMorphRenderer556` była odtwarzana **tylko** w osobnej walce sferycznej, natomiast podczas `IntroOrbit41` trójbuforowy GLB pozostawał na ostatnim lub początkowym morfie.

Poprawiono `MetalRenderer.swift`: źródłowa sekwencja przelotu aktualizuje teraz model z `IntroTime` przed `retainCurrent` i `drawMesh`; walka nadal używa dotychczasowego `planetAnimationTime`. Oba tryby współdzielą tę samą, wyodrębnioną ścieżkę `uploadBoreasMorphIfNeeded(seconds:)`: maksymalnie 30 Hz, `MorphBufferSlots.reserveWrite/publish/cancelWrite/retainCurrent/release`, aktualizacja wyłącznie zakresu `planetAnimator.dynamicVertexRange` i zachowanie statycznych wierzchołków. Zmiana sceny resetuje `lastPlanetMorphUpload`, aby powrót do walki nie zatrzymał animacji po intro; zawinięcie zegara 16→0 również wymusza właściwą klatkę. Nie zmieniano żadnych zasobów GLB, animacji, geometrii poza mechanizmem aktualizacji.

Osobno `IntroOrbit41.swift` zachowuje oryginalną sekwencję `Windows/src/OrbitWorld51.cs:5–7` zawierającą 81 próbek kamery i statku (0–16 s co 0,2 s), ale wylicza te niezmienne próbki **raz** przed rozmieszczaniem 820 asteroid. Wcześniej wyliczano je wielokrotnie podczas testów korytarza skał. Żadnych parametrów generatora, seeda `4109`, rozmiarów, trajektorii ani reguł przesuwania nie zmieniono; nowy test porównuje próbki z oryginalnymi `camera(t),ship(t)`.

Testy: [42102273792](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273792) `source-camera-linux` **PASS** (w tym nowy `Tests/IntroBoreasMorphSourceContract556.py`, uzupełniony `IntroOrbit41Tests.swift`, siatki, projekcja, obecne mechaniki). [42102273356](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273356) szybki preflight składni Swift i autentycznych zasobów **PASS**. To weryfikacja wykonywanego kodu Swift na Linux oraz źródłowych kontraktów, nie natywnego GPU. **Drugi job Xcode/Metal w przebiegu 42102273792 był nadal queued**, nie wykonano interaktywnego testu iPhone/iPad. Nowego IPA nie zbudowano.

Zakres ograniczeń: ta implementacja odtwarza morf dla rzeczywistego, już przekonwertowanego **Boreas v556**, a nie automatycznie wszystkie planetarne modele z oryginalnej gry v568. Dalsza zgodność pozostałych planet, świateł, atmosfery, skal statku oraz pełnej kampanii wymaga osobnej implementacji na źródłach. Sposób wyliczania próbek ogranicza liczbę obliczeń, lecz wielkości rzeczywistego przyspieszenia i FPS na urządzeniu **nie zmierzono**. W raportach nie udawać poprawnej kompilacji Apple ani gotowego IPA.
