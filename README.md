# ASTEROIDY iOS — natywny port Swift/Metal (projekt w trakcie rozwoju)

## Najnowszy etap: CARBONIS 01 — walka → wygrana → raport → serwis → zapis (06.11.2026)

**Port całej gry: 38% implementacyjnie (+2 pp), 62% pozostało.** W pierwszej misji działa źródłowa sekwencja `Game.Wave` (13 asteroid, cztery myśliwce), kolizje sferyczne, broń Pulse/Twin/Scatter z zakupionymi ulepszeniami, odłamki, realistyczne zbieranie żetonów i `Game.FinishLevel`. Po zwycięstwie powstaje raport `LevelSummary166` z premią 12 żetonów i przyciskiem serwisu po 4,2 s. Wyniki i zasoby zapisują się trwale, ukończenie CARBONIS odblokowuje sektor02, a powtórka nie przyznaje drugi raz nagrody. Po porażce dostępne jest ponowienie misji.

**[Testy 42269114054 — PASS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42269114054):** 335 realnych kroków bitwy 120 Hz, 18 asercji end-to-end, 41 kontroli serwisu, zapisu i ochrony replay. Test jest automatyczny i wykorzystuje kierowane pociski: nie jest potwierdzeniem ręcznej gry na iPhonie. **Najnowszy IPA nadal wymaga potwierdzenia Xcode**; oryginalne SFX i wizualna weryfikacja Apple GPU nie są ukończone. Nie deklarować 100% gotowości pierwszej misji ani wszystkich 25 grywalnych sektorów.

[Stały harmonogram 18 zadań](PORT_STATUS_18_TASKS.md) · [Raport etapu CARBONIS01](Reports/V568_CARBONIS01_FINISH_REWARDS_SERVICE_E2E_2026-11-06.md) · [GitHub build IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42269114054).

Starsze komunikaty 36%, 35% itd. poniżej są historycznym zapisem prac, nie aktualnym stanem wydania.


## Aktualizacja 06.11.2026 — drugi myśliwiec źródłowy i 450 profili zachowania

**Port iOS: 36% zaimplementowano / 64% pozostało.** Z oryginalnego `Windows/src/ShipMesh.cs` przeniesiono `ShipMesh(1,false)` (drugi myśliwiec, 5521 trójkątów) obok istniejącego rodzaju 0 (5345). Oba mają oddzielne proceduralne bryły, 8 grup materiałowych, cache GPU Metal i barwy pochodzące z `GpuRobot70`. Skalowanie świecącego rdzenia o 15% podczas ostrzeżenia nie zmienia pozostałej geometrii. `ShooterTactics71` przenosi pełne parametry AI, strzałów i obrażeń sześciu rodzajów myśliwców dla 25 poziomów i wszystkich trudności. Aktywny CARBONIS 01 wciąż wykorzystuje wyłącznie typ 0 — nie są to ukończone misje 2–25.

**Testy [42260834217](https://github.com/synixad-png/asteroidy-ios/actions/runs/42260834217): PASS** — 97 301 sprawdzeń geometrii, 6307 reguł AI, regresje pierwszej misji i wcześniejszych mechanizmów. Nowy efekt rdzeni ma późniejszy przebieg testowy. **Pierwszy niepodpisany IPA jest naprawdę dostępny** z przebiegu [42259012837](https://github.com/synixad-png/asteroidy-ios/actions/runs/42259012837) (ok. 26,3 MB), ale pochodzi ze starszego kodu i nie zawiera nowych myśliwców i reguł. Natywne uruchomienie tego kodu na iPhonie/iPadzie nadal niepotwierdzone. [Raport](Reports/V568_SOURCE_SHOOTER_KIND1_450_TACTICS_2026-11-06.md) · [Harmonogram 18 zadań](PORT_STATUS_18_TASKS.md).

Poniższe wpisy 35% i wcześniejsze pozostają wyłącznie historią rozwoju.


## Aktualizacja 06.11.2026 — pierwszy źródłowy myśliwiec 3D, kolizje i trafienia

**Port: 35% zaimplementowane / 65% pozostało.** CARBONIS 01 ma teraz w kodzie cztery proceduralne myśliwce typu 0 pochodzące z oryginalnego `Windows/src/ShipMesh.cs` i `BossMesh65/GpuRobot70`, ze wspólną siatką Metal i ośmioma materiałami. AI `EnemyTactics71` porusza nimi i ostrzega przed ostrzałem; `Physics68` rozwiązuje fizyczne zderzenia oraz odrzuty; broń Pulse uwzględnia zasłanianie myśliwców przez asteroidy, prawidłową punktację i 18 krótkotrwałych fragmentów małej skały. Pierwsza misja jest więc rozwijana na prawdziwym kodzie, nie atrapach.

**[Testy GitHub Swift/Linux: PASS — 42256245496](https://github.com/synixad-png/asteroidy-ios/actions/runs/42256245496)** obejmują nową siatkę, fizykę oraz reguły pierwszej misji. **Xcode, GPU Apple i nowy IPA nie zostały potwierdzone** — zadanie macOS pozostaje w kolejce. To nie oznacza kompletnego portu 25 misji ani gotowego wydania iOS. [Raport techniczny](Reports/V568_CARBONIS_SOURCE_FIGHTERS_PHYSICS_SHARDS_2026-11-06.md) · [Stały harmonogram](PORT_STATUS_18_TASKS.md).

Poniżej pozostawiono historyczne wpisy 33%, 31% i wcześniejsze.


## Aktualny stan 06.11.2026 — grywalna misja CARBONIS w kodzie, weryfikacja IPA

**33% całego portu ukończone implementacyjnie / 67% pozostało.** Kod pierwszej misji CARBONIS 01 zawiera teraz autentyczny model statku VANGUARD v568, kamerę za statkiem, natywne sterowanie dotykowe, strzelanie, radar i HUD, symulowanych czterech wrogów, poruszające się źródłowe asteroidy, obrażenia, trzy życia oraz końcowy stan zwycięstwa/przegranej. To nie oznacza ukończenia 25 misji PC ani całego projektu; przeciwnicy nie mają jeszcze swoich oryginalnych siatek 3D, pozostałe planety, bossowie, audio i część mechanik wciąż czekają.

Na wyraźne polecenie użytkownika przygotowano kompilację **niepodpisanego iPhone/iPad IPA**. Najnowszy przebieg [GitHub Actions 42247840690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42247840690) na `macos-15-intel` (Linux PASS, macOS Xcode oczekuje w kolejce) testuje kod Swift przed Xcode i pakuje sprawdzony IPA tylko po prawidłowej kompilacji. **Wyniku Xcode i istnienia nowego artefaktu na tym etapie nie potwierdzono.** [Raport](Reports/V568_CARBONIS_LIVE_COMBAT_2026-11-06.md) | [Harmonogram 18 zadań](PORT_STATUS_18_TASKS.md).

Dalsze prace: autentyczna siatka myśliwców z ShipMesh/BossMesh65 i integracja brakujących mechanik oraz pozostałych sektorów.


## AKTUALNY POSTĘP — 6 listopada 2026: autentyczne asteroidy w scenie CARBONIS

**31% wykonano, 69% pozostało.** W kodzie natywnego Swift/Metal wdrożono źródłowe siatki asteroid `RockVertices75` z Windows v568 (20-ścienny bryła, dwukrotny podział, kraterowanie i kolory), ruch na sferze `SphereAsteroid556.advance`, źródłowe ułożenie `StampSphere67` oraz toon z oryginalnego `GpuRockInstancing75`. Scena C279 renderuje przygotowane obiekty `Game.Wave()` obok oryginalnej planety; każdy kształt ma współdzielony bufor GPU.

**Weryfikacja:** lokalnie 43 385 asercji Swift/Linux PASS, Xcode/GPU Apple tej rewizji **niepotwierdzone**. To nie jest jeszcze kompletna gra: myśliwce/AI, sterowanie statkiem, broń, kolizje i rozstrzygnięcie misji pozostają do wdrożenia. [Techniczny raport](Reports/V568_STAGE_C_ORIGINAL_ROCK_RENDERER_2026-11-06.md) · [18 zadań](PORT_STATUS_18_TASKS.md). Bez nowego IPA.

Poniżej pozostawiono historyczny stan 30% po przygotowaniu pierwszej fali.

## AKTUALNY POSTĘP — 6 listopada 2026 (po wdrożeniu początkowej WAVE)

**30% wykonane / 70% pozostało.** Do natywnego wejścia na CARBONIS 01 dodano źródłową inicjalizację `Game.Wave()` z oryginalnych Windows/SteamOS v568: asteroidy, uzbrojeni myśliwce, robotyczne węże, parametry i limity posiłków. Scena wyświetla prawdziwe liczby struktur początkowych, a jej dane powstają z `MissionStart261` + `MissionWave568`. **Wciąż nie ma aktywnego renderowania ani AI tych przeciwników, lotu i wyniku misji w scenie CARBONIS.** Moduł `MissionIncoming568` odtwarza też źródłowy zegar `StepAction` i `SpawnIncoming`, lecz na razie jest wpięty jako stan przygotowany, nie aktywny system walki. Lokalnie Swift/Linux 909 testów fali + 633 testy posiłków Action38 + 12 testów wejścia = **1554 PASS**; natywne iOS CI po aktualnych commitach pozostaje niepotwierdzone. [Pełny raport](Reports/V568_STAGE_C_WAVE_PREPARED_2026-11-06.md), [18-zadaniowy harmonogram](PORT_STATUS_18_TASKS.md).

Poprzednie wartości 29% oraz opis braku źródłowej `Wave()` w sekcjach historycznych są już nieaktualne. Nie wygenerowano nowego IPA.

## Bieżący postęp projektu — 6 listopada 2026

**29% wykonane, 71% pozostało.** Natywne menu W3 → wybór 26 sektorów → oryginalna scena 3D CARBONIS 01 jest dostępna w źródłach; nie jest jeszcze pełną grywalną misją. Kolejny krok etapu C: źródłowa mechanika startu, fale i kontakt statku z terenem. [Stały harmonogram 18 zadań](PORT_STATUS_18_TASKS.md).

Ostatnia zmiana: **dokładny odczyt oryginalnej mapy wysokości CARBONIS 512×256** (`CarbonisSurface277.swift`, na podstawie Windows v568 `Carbonis277.cs`). Inspektor wywołuje prawdziwe `SurfaceRadius`, wejście wymaga poprawnego SHA-256 szóstego źródłowego zasobu. **Lokalne testy Swift/Linux 27/27 PASS**; nowa kompilacja Xcode i test fizycznego iOS **jeszcze niepotwierdzone**. [Raport i ograniczenia](Reports/V568_STAGE_C_CARBONIS_TERRAIN_SOURCE_2026-11-06.md).

**Zweryfikowano źródło WAVE:** pełny ZIP Windows/SteamOS v568 w Bibliotece zawiera `Game.Wave()` (`Windows/src/Game.cs:90–101`, `SteamOS/src/Game.cs:90–101`) i wszystkie kluczowe zależności. Dwie definicje `Wave()` mają ten sam SHA-256. [Audyt pełnych źródeł i testów](Reports/V568_WAVE_FULL_SOURCE_AUDIT_2026-11-06.md). To koryguje wcześniejszy, błędny wniosek wyciągnięty z niepełnego archiwum. **Wdrożenie pełnej WAVE do misji CARBONIS na iOS jest nadal do zrobienia.**

**Aktualny kod nie wydaje nowego IPA.** Poprzednie IPA na Dysku Google jest starszym wydaniem i nie zawiera najnowszego terenu/rozwoju misji. Całość gry nie jest jeszcze ukończona.


## Aktualna kompilacja IPA — 5 listopada 2026

Na wyraźne polecenie użytkownika uruchomiono **budowanie niepodpisanego IPA dla fizycznego iPhone'a/iPada** z commita `18e18797046dd37807650313990913dce38ab522`:

- [GitHub Actions — build iOS IPA, run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545).
- Workflow: `.github/workflows/build-ios.yml` (uruchomiony przez zmianę tego pliku na gałęzi `main`).
- W pierwszej fazie Swift/Linux sprawdza regresje oryginalnego v556. Na macOS kompilowane są źródła przez XcodeGen i Xcode dla **iphoneos arm64**. Dopiero po udanej kompilacji tworzony jest `ASTEROIDY_iOS_UNSIGNED.ipa`, sprawdzany CRC/Info.plist/Mach-O oraz zasoby.
- Artefakt GitHub ma nazwę **`ASTEROIDY-iOS-device-unsigned-ipa`** i jest przechowywany **14 dni**; zawiera niepodpisany IPA, środowisko budowania, sumę SHA256 oraz wynik walidacji.
- **Nie deklarować, że IPA już istnieje, dopóki przebieg nie jest zakończony z wynikiem SUCCESS, a artefakt nie został opublikowany.** Kompilacja to nie test uruchomienia na fizycznym iPhonie.

### Jak pobrać i zainstalować po sukcesie workflow

1. Otwórz [przebieg kompilacji](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545) i poczekaj, aż pokaże **Success**.
2. W dolnej części strony, w sekcji **Artifacts**, wybierz `ASTEROIDY-iOS-device-unsigned-ipa`. GitHub pobierze ZIP zawierający `ASTEROIDY_iOS_UNSIGNED.ipa` oraz raporty.
3. Rozpakuj ZIP i wybierz plik IPA w Sideloadly na Windows. **To IPA jest niepodpisane** — instalacja na iPhonie wymaga poprawnego podpisania przy użyciu odpowiedniej metody; sam ZIP nie instaluje gry.
4. Jeśli kompilacja zakończy się błędem, czytaj błąd na poziomie konkretnego zadania, nie traktuj poprzednich udanych buildów jako potwierdzenia tej rewizji.

### Osobne kontrole infrastruktury i renderera

- **Zasoby oryginalnego v556:** `python3 Tools/verify_ios_inputs.py` sprawdza cztery referencyjne SHA-256, formaty AS3D/ASMO, powiązanie animacji z geometrią, `project.yml` i wejścia `Ship.metal`. [GitHub Actions 42053587593 — PASS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42053587593). Nie używa zewnętrznych bibliotek.
- **Kamera Metal:** zmiana `Sphere67.swift`, `MetalRenderer.swift` i `Ship.metal` odtwarza źródłowy `SphereCombat67.cs` i `GpuSphere67.cs`, z orbitującym widokiem nad planetą i prawidłowym wektorem kamery w oświetleniu BRDF. [GitHub Actions 42052748443 — PASS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443). Jest to test matematyczny oraz składni Swift, nie test Metal GPU; dokumentacja w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.
- **Wersje:** IPA z uruchomionego run `42051262545` ma SHA `18e187970`. Zmiany kamery i walidatora powstały **później**, dlatego nie wchodzą do tamtej kompilacji. Nie wolno przedstawiać tego IPA jako wydania ze zmianami po tym SHA.

### Niebo planety — autentyczna tekstura z oryginalnego v556

Na podstawie rzeczywistych `Windows/src/GpuAmbient37.cs:5`, `GpuIntro41.cs:23,451–452` oraz `Gpu2DRenderer.cs:68,70,74` przeniesiono proceduralną `StarTexture` 64×64 BGRA PArgb i gwiezdne `IntroHalo`. Widok planetarny zachowuje 1500 kierunków, w tym 206 dodatkowych jasnych halo, w jednym buforze i jednym rysowaniu Metal. Promienie 10/21 px i podstawowe `size*2` oraz `ONE/ONE_MINUS_SRC_ALPHA` wynikają z oryginalnego kodu; nie są wymyślonymi efektami. Testy Swift/Linux i statyczna kontrola pipeline'u: [PASS, run 42065903420](https://github.com/synixad-png/asteroidy-ios/actions/runs/42065903420). **Natywna kompilacja Xcode/Apple Metal i test obrazu są nadal niepotwierdzone.** Mgławice, promienie i czarna dziura są już zaimplementowane w kolejnych commitach, lecz natywna kompilacja Apple GPU pozostaje niepotwierdzona. Szczegóły w [audycie zadania 2](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Źródłowe promienie słoneczne w Metal — zadanie 2

Obok prawdziwej `StarTexture` 64×64 i gwiazd `IntroHalo` port odtwarza teraz również `GpuIntro41.cs:454`: trzy oryginalne teksturowane poświaty słońca (promienie 130/55/15 px) oraz pięć wachlarzy `SoftRay` z `GpuCosmos39.cs:8–10`. Kod `SphereSolarOverlay556` tworzy łącznie **738 statycznych wierzchołków** i wykonuje jedno rysowanie GPU z oryginalnym premultiplikowanym blendingiem; projekcja `SkyProject55` aktualizuje tylko 16-bajtowy uniform względem sferycznej kamery. [Test Swift/Linux i kontraktów kodu — PASS, GitHub 42068464591](https://github.com/synixad-png/asteroidy-ios/actions/runs/42068464591). Apple Xcode/Metal i fizyczny iPhone **nie zostały jeszcze potwierdzone**; mgławice i czarna dziura są już zaimplementowane, a trzy planety tła z `DrawDeepSpace55` zostały dodane w kolejnym etapie; nadal wymagają testu na urządzeniu. Szczegółowy audyt: [AUDYT_ZADANIE_2_v556_METAL_CAMERA.md](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Mgławice GpuCosmos39 i GpuIntro41 — oryginalny kod v556

Podgląd planety korzysta teraz z autentycznego generatora `CloudHash` i pięciu oktaw `CloudNoise` w teksturach `NebulaTexture` 256×256. Źródłowe **24 dalekie i 12 bliskich warstw** są renderowane przy użyciu dwóch palet w jednej dwuwarstwowej teksturze, bez tworzenia nowych buforów w każdej klatce; `SkyProject55` wyliczany jest bez translacji kamery. Test oryginalnych wzorów, pikseli BGRA, projekcji wszystkich 36 warstw i statycznego połączenia Metal: **[PASS, GitHub Actions 42071274522](https://github.com/synixad-png/asteroidy-ios/actions/runs/42071274522)**. Apple GPU i fizyczny iPhone nie zostały jeszcze zweryfikowane. Trzy planety głębokiego kosmosu zostały dodane w późniejszym etapie; wszystkie elementy nieba nadal wymagają natywnej weryfikacji GPU. Patrz [AUDYT_ZADANIE_2_v556_METAL_CAMERA.md](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Czarna dziura z oryginalnego v556 — trzy obrazy i dziesięć warstw

Z `GpuIntro41.cs:62–127` przeniesiono algorytm **3 oddzielnych tekstur 640×640 BGRA/PArgb**: tylnego dysku akrecyjnego, czarnego rdzenia i przedniego dysku zachodzącego przed środek. Przy domyślnie włączonym glow scena korzysta z **3 poświat StarTexture, 4 animowanych promieni i 3 dysków**, rysowanych we właściwej kolejności. Wszystkie obrazy generowane są tylko raz, a shader Metal dostaje w kolejnych klatkach wyłącznie położenie i zmienne animacji. Naprawiono też kolejność mgławic: 24 odległe → obiekty tła → 12 bliskich. **[Swift/Linux + statyczna kontrola Metal — PASS, GitHub 42074436010](https://github.com/synixad-png/asteroidy-ios/actions/runs/42074436010)**. Nadal brak testu uruchomienia na iPhone i wyniku kompilacji Apple Metal dla tego commita. Trzy planety głębokiego kosmosu przeniesiono w późniejszym commicie; działanie na iPhonie nadal wymaga potwierdzenia. [Audyt źródłowy](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Trzy planety tła z oryginalnego BuildDeepPlanet55 (obecny stan)

Port ma teraz także wszystkie trzy planety 320×220 z `GpuIntro41.cs:27–63`: gazowego olbrzyma z pierścieniami, niebieski świat z chmurami i czapami polarnymi oraz czerwony świat z pasmami i śladami atmosferycznymi. `DeepSkyPlanets55.swift` odtwarza rzeczywistą kolorystykę powierzchni `PlanetShade55`, źródłowe kierunki/animacje `AnimatedSkyDirection55`, poświaty i projekcje. `MetalRenderer` dzieli jeden zasób GPU na trzy warstwy tekstur i wykorzystuje istniejące shadery czarnej dziury, bez ponownej generacji obrazów w każdej klatce. Oryginalny porządek rysowania: **24 dalekie mgławice → trzy planety → czarna dziura → 12 bliższych chmur → gwiazdy i promienie**. [Testy matematyczne Swift/Linux i kontrakt shaderów — PASS, GitHub 42077736535](https://github.com/synixad-png/asteroidy-ios/actions/runs/42077736535).

**Ograniczenia:** pikselowa antyaliasingowa rasteryzacja łuków i pierścieni Windows GDI+ jest przybliżeniem; nie jest gwarantowany wygląd 1:1. Natywna kompilacja aktualnych shaderów Apple Metal i uruchomienie na fizycznym iPhonie **nie zostały jeszcze potwierdzone**. Procent zadania 2 wynosi **64%**, nie 100%. [Pełny audyt](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md) i [harmonogram](PORT_STATUS_18_TASKS.md).

### Optymalizacja widoczności nieba iOS (poprzedni etap zadania 2 — 65%)

Zgodnie z oryginalnym `GpuIntro41.DrawSkyPlanet55/DrawSkyBlackHole55` i `GpuCosmos39.CloudLayer` duże obrazy proceduralne są teraz alokowane w Metal **dopiero przy pierwszym rzeczywistym pojawieniu się obiektu na ekranie**, nie w konstruktorze renderera. `SkyTextureGate55` zapobiega wielokrotnym alokacjom w każdej klatce, zachowując źródłową kolejność 24 dalekich chmur → 3 planety → czarna dziura → 12 bliskich chmur. W trybie płaskiej areny tworzenie **6 284 288 B nieskompresowanych danych tekstur BGRA8** zostaje odroczone. To wyliczenie rozmiaru danych, **nie wynik pomiaru VRAM lub FPS**. [Pełny Swift/Linux i statyczny kontrakt Metal — PASS, run 42081362292](https://github.com/synixad-png/asteroidy-ios/actions/runs/42081362292). Natywne Xcode/Apple Metal i ekran fizycznego iPhone'a **niepotwierdzone**.

**Jednorazowa kompilacja IPA na polecenie użytkownika:** [GitHub Actions 42078976090](https://github.com/synixad-png/asteroidy-ios/actions/runs/42078976090) została zlecona **przed** tą optymalizacją, na commicie `d475b114`, a późniejsze commity nie są częścią jej snapshotu. Nie uruchamiano drugiego builda IPA i nie prowadzono automatycznego sprawdzania jego statusu. Plik IPA można uznać za gotowy dopiero po udanym zakończeniu workflow i opublikowaniu prawdziwego artefaktu.

### Ładowanie oryginalnych planet i mgławic dopiero przy widoczności (aktualny etap — 67%)

Zgodnie z prawdziwym `Windows/src/GpuIntro41.cs` i `GpuCosmos39.cs` generowanie bitmap jest teraz osobne dla **każdego** z 3 stylów planet tła i 2 motywów mgławic. Wcześniej pierwsza widoczna planeta/chmura wyzwalała obliczenie wszystkich odpowiednich obrazów; obecnie `SkyTextureSliceCache55` i `MetalRenderer.ensureDeepPlanetTextures55(style:)` / `ensureCloudTextures55(camera:)` odraczają obliczenie i przesłanie każdej bitmapy do pierwszej widoczności jej własnego stylu/motywu. Każdy już przesłany obraz jest współdzielony i nie powstaje od nowa w każdej klatce.

Zachowano istniejące dwie tablice tekstur Metal (3 i 2 warstwy), palety i geometrię oryginału, projekcję, shadery, mieszanie PArgb oraz kolejność 24 dalekie chmury → planety → czarna dziura → 12 bliskich chmur → gwiazdy i słońce. **To nie oznacza zmierzonego wzrostu FPS ani oszczędności VRAM:** rozmiar tablic GPU jest niezmieniony; odroczono pracę CPU i upload niewidocznych obrazów.

Doprecyzowano testy 6 kolejności planet i obu motywów mgławic. Izolowany test cache w Swift/Linux i 14 kontroli statycznych na aktualnych źródłach zakończyły się **PASS**; pełne źródłowe testy GitHub Actions najnowszego commita oraz natywne kompilacje Apple/Xcode/Metal **nie mają jeszcze potwierdzonego wyniku**. Rzeczywisty obraz i wydajność na iPhone/iPad **nie były zweryfikowane**. Nie zlecano kolejnego IPA. [Raport z 18 zadaniami](PORT_STATUS_18_TASKS.md) i [pełny audyt](AUDYT_ZADANIE_2_v556_METAL_CAMERA.md).

### Zgodność płaszczyzn odcinania Metal z GpuIntro41 v556 (zadanie 2 — 68%)

Oryginalna sferyczna kamera v556 używa `IntroProjection` z near=0.4 i far=1600, ale port iOS dotąd korzystał z płaszczyzn 0.1/20 skopiowanych z płaskiej areny. `SphereProjection556.clipPlanes(spherical:)` normalizuje wartości C# przez źródłowy promień Boreas 100×1.4419674; renderer Metal zachowuje płaski zakres bez zmiany. Rozszerzono test kamery o NDC-depth oraz dodano statyczny kontrakt `SphereProjectionSourceContract556.py`, uruchamiany na Linux. Poprawiono też przestarzałe odwołanie w teście `SkyTextureGateSourceContract55.py`.

Przy kompletnych dwóch motywach mgławic `ensureCloudTextures55` korzysta teraz z `SkyTextureSliceCache55.allUploaded` i rezygnuje ze zbędnych **36 CPU-projekcji oraz tworzenia Set co klatkę**. Bieżącą widoczność nadal prawidłowo projektuje istniejący shader GPU. Testy kolejności pierwszych załadowań zachowano. Nie wykonano pomiarów FPS ani natywnego testu Apple Metal/iPhone; oszczędności wydajności nie deklarujemy.

Wynik potwierdzonych wcześniejszych testów regresji Swift/Linux: [GitHub Actions 42086918193](https://github.com/synixad-png/asteroidy-ios/actions/runs/42086918193), job `source-camera-linux` PASS. Natywny job macOS pozostaje niepotwierdzony. Aktualizacja cache ma oddzielny, późniejszy przebieg CI; dopiero jego wynik potwierdzi cały nowy zestaw. Jednorazowy IPA tylko dla iPhone'a pochodzi z wcześniejszego commita `e00e716` i **nie obejmuje** tych późniejszych zmian, jeśli się zbuduje. Żadnej kolejnej kompilacji IPA nie uruchamiano.

### Stan portowania

Zatwierdzona, niezmienna lista 18 zadań i procenty: [PORT_STATUS_18_TASKS.md](PORT_STATUS_18_TASKS.md). Dotychczas moduły 7 i 8 zamknięto implementacyjnie, ale nadal brakuje pełnej gry i testów dotykowych/Metal na urządzeniu. Do zamknięcia całej aplikacji konieczna jest sekwencyjna realizacja pozostałych etapów, zaczynając od **zadania 1: kompilacja i infrastruktura iOS**.

Pełen wynik poprzedniej udanej kompilacji IPA jest udokumentowany dla commita `596767b`, [run 42027976783](https://github.com/synixad-png/asteroidy-ios/actions/runs/42027976783). **Ten stary IPA nie zawiera obecnych zmian.**

## Historia bazowego portu v18

Instrukcja historycznego przekazania: [START_DRUGI_CZAT.md](START_DRUGI_CZAT.md). Raport ówczesnego stanu: [ASTEROIDY_iOS_v18_RAPORT.md](ASTEROIDY_iOS_v18_RAPORT.md). Poniższy opis dotyczy historycznych etapów v14–v18 i nie jest aktualną informacją o stanie kompilacji.

Poniżej zachowano historyczny opis rozwoju v14–v18.

Baza: ASTEROIDY v556, niezależny port iOS. Nie jest to ukończony port ani podpisany IPA.

Wprowadzono `BoreasMorphRenderer556.swift`, `BoreasMorphBinding556.json` i procedurę reprodukowalnego eksportu `Tools/export_boreas_morph_binding.py`. Renderer Metal w trybie planetarnym aktualizuje geometrię według oryginalnych klatek GLB, interpoluje sześć morph targetów i odtwarza normalne. Przy aktualizacji używa nowego bufora GPU, pozostawiając indeksy bez zmian.

Testy: `python Tests/test_morph_export.py <zip_v556> ASTEROIDYiOS/Assets/Boreas556.asmo` i `python Tests/test_binding_export.py` (ten drugi używa źródeł v556 z archiwum lokalnego). Statyczne sprawdzenie składni Swift i uruchomienie modułu animacji w Swift Linux przeszły, ale kompilacja Xcode oraz wykonanie GPU Metal **nie były dostępne**.

Raport i dokładne ograniczenia: `RAPORT_v14.txt`. Nie utworzono paczki wydaniowej ani IPA.

### v15 — optymalizacja normalnych Boreas (wersja robocza)
W `BoreasMorphRenderer556.swift` normalne przeliczane są tylko dla
27 035 deformowanych wierzchołków i 54 066 ich trójkątów.
Pozostałe 4 320 wierzchołków / 7 488 trójkątów są niezmienne.
Test `BoreasMorphOptimization556Tests.swift` porównuje normalne z pełnym
przeliczeniem w sześciu fazach cyklu. Lokalny test Swift/Linux: PASS.
Kompilacja Xcode i wizualny test GPU Metal: NIE WYKONANO.

### v16 — potrójne bufory animacji (wersja robocza)
- Trzy bufory MTLBuffer są alokowane jeden raz przy ładowaniu Boreas.
- MorphBufferSlots.swift pilnuje, aby zapisy CPU omijały bufory mające niezakończone odwołania GPU.
- Zwolnienie referencji odbywa się w MTLCommandBuffer.addCompletedHandler.
- Gdy nie ma wolnego bufora, pomijany jest upload tej klatki, bez czekania na GPU.
- Test własności buforów i kompilacja modułu pod Swift/Linux: PASS; parse całych źródeł: PASS.
- Brak kompilacji Xcode, brak testu Metal GPU, brak pomiaru FPS iOS.
- Nie dodawano animacji transformacji innych obiektów GLB; pozostaje zadaniem.

### v17 — redukcja kopiowania animacji (wersja robocza)
- Reużywalny scratch wierzchołków, zakresowy upload tylko dynamicznej siatki (27 035 z 31 355).
- Lokalne porównanie Swift/Linux 10 próbek animacji: PASS; brak kompilacji Xcode/Metal i pomiarów FPS.
- Szczegóły: `RAPORT_v17.txt`.

### v18 — rozdzielone pomiary CPU/GPU (roboczo)
Dodano `RenderTelemetry.swift` i `Tests/RenderTelemetryTests.swift`.
Pomiar obejmuje CPU morph, CPU upload, opcjonalnie czas GPU command buffer.
Dla `ASTEROIDY_IOS_PROFILE=1` log diagnostyczny pojawia się co ok. 5 s w trybie planetarnym.
Testy Swift/Linux i zgodności z rzeczywistym GLB v556 przeszły; kompilacji Xcode ani testu GPU nie przeprowadzono.
Pełny wykaz wyników i ograniczeń: `RAPORT_v18.txt`.
