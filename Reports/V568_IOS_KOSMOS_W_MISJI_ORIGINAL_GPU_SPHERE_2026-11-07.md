# ASTEROIDY iOS v568 — źródłowa scena kosmiczna MISJI, nie samej planety
**Data:** 07.11.2026. **Główna gałąź:** `synixad-png/asteroidy-ios`. **Baza porównawcza:** przekazane autentyczne `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`.

## 1. Potwierdzone zachowanie oryginalnego kodu Windows
- `Windows/src/GpuSphere67.cs:414–425`: w trybie walki `SphereScene67` najpierw wykonuje `IntroSky(glow,nebula,rays,true)`, następnie `IntroProjection` i `DrawPlanetSolid`, po nim `DrawAtmosphere47`, `DrawCombatResearchWreck214(g)`, dopiero następnie obiekty świata, broń i statek. Tę kolejność usunięto z portu iOS przez pominięcie warstw; rzeczywistą rozbieżność naprawiono.
- `Windows/src/GpuIntro41.cs:122–127,451–456`: źródłowe warstwy przestrzeni: **24 dalekie chmury, 3 animowane obiekty planetarne z rzeczywistymi kierunkami (gazowy olbrzym po prawej, niebieski świat nisko, czerwony świat po lewej), czarna dziura, 12 bliskich chmur, 1500 gwiazd, 5 promieni światła**. Każdy obiekt podlega `SkyProject55` i orientacji właściwej kamery walki.
- `Windows/src/GpuSphere67.cs:369–413`: oryginalny wrak badawczy nie jest dowolnym drugim przeciwnikiem. Ma źródłowy kierunek `(-0.7, 0.22, -0.68)` (znormalizowany), pozycję `sphereEye + skyDirection * 900 + cameraRight * 80 + cameraUp * 52`, orientację wyprowadzoną z osi kamery i obroty `Rz(-11°), Ry(24°), Rx(26°)`, skalę `2.20`. Wrak rysowany po sprawdzeniu widoczności planety z pierścieniami, dlatego nie musi występować na ekranie podczas każdej orientacji kamery. Nie dodano wymyślonej niezależnej animacji.
- `Windows/src/GpuIntro41.cs:199–415`: kadłub stacji/rozbitego statku `DrawDetailedResearchWreck211(level+214,false)`, jego panele, metaliczne elementy, okna, drzwiczki, anteny, żebra, uszkodzenia, smugi brudu, rysy, 7 lamp ostrzegawczych oraz **112** oryginalnych fragmentów. Deterministyczne położenia odłamków z `SpaceRand207` z `Windows/src/GpuAmbient37.cs:6–7`.
- `Windows/src/GpuPlanetGltf463.cs:41,69`: prawdziwa źródłowa wielkość planety misji wyznaczana przez `MissionPlanetScale523(100)`; nie zmniejszano jej na wyczucie, by sztucznie pokazać więcej kosmosu.

## 2. Zmiany w aktywnym porcie iOS
- Nowy `ASTEROIDYiOS/SourceCombatSky568.swift` tworzy na istniejących oryginalnych algorytmach i shaderach `SphereSky207`, `SphereNebula556`, `DeepSkyPlanets55`, `BlackHoleSky55`, `SphereSolarOverlay556` rzeczywistą warstwę kosmosu w aktualnej kamerze `SphereCameraView556`. Geometria i tekstury są buforowane, a planety/obiekty nieodkryte nie są generowane na ślepo w każdej klatce.
- Nowy `ASTEROIDYiOS/ResearchWreckGeometry214.swift` przenosi źródłowe procedury budowy rozbitego statku z GPU Intro41: raz generuje statyczną geometrię i obliczenia kolorów z oryginalnymi stałymi, 112 fragmentów i 7 faz migania.
- `ASTEROIDYiOS/SourceCombatWreck214.swift` renderuje odległy wrak przy zachowaniu rzeczywistych macierzy źródłowych, widoczności i pozycji przy odległym pierścieniowym obiekcie; trójkąty i linie rysowane są z właściwym depth-test, bez ingerencji w symulację.
- `ASTEROIDYiOS/Sector01Carbonis568.metal`: odrębne shadery proceduralnego wraku z miganiem świateł `sin(g.Time * 4.8 + phase)`. Składniki oświetlenia oparte na `PlanetSun71`, `planetAmbient269` i `GpuShip.keyDiffuse`; **porównania piksel po pikselu z Windows OpenGL fixed-function jeszcze nie ma**. Nie wolno deklarować takiej dokładności.
- `ASTEROIDYiOS/Sector01CarbonisPreview568.swift`: nieprzezroczysta scena walki CARBONIS wywołuje kosmos **PRZED** planetą, wrak **PO** planecie/atmosferze a **PRZED** asteroidami, przeciwnikami i statkiem. Przezroczysty, izolowany podgląd planety w W3 pozostaje bez kosmosu.
- Testy `Tests/CombatOriginalSkyWreck214Contract.py` i `Tests/ResearchWreckGeometry214Tests.swift` oraz dwie bramki workflow GitHub chronią pozycję obiektów, kolejność i deterministyczną geometrię.

## 3. Weryfikacja, ograniczenia
- Kontrakt statyczny danych nieba: **PASS**.
- Linux Swift dla generatora oryginalnej geometrii: **PASS**. Zbudowano **28 920 wierzchołków trójkątów i 5 364 wierzchołki linii**; 112 fragmentów, 7 źródłowych faz świateł, powtarzalność geometrii — PASS.
- Kontrolna natywna kompilacja iOS/Metal źródeł: **PASS** w teście `Compile iOS source only` (GitHub Actions #380).
- Pełny niepodpisany IPA, test na prawdziwym iPhone/iPad oraz wizualne porównanie punktów kamer: raportować dopiero po rzeczywistej weryfikacji workflow GitHub #132 i obrazu z urządzenia.
- Zachowano oryginalną `MissionPlanetScale523`, obrót statku, źródłowe efekty, audio, sterowanie dotykiem, kolizje, sektory i ustawienia. Nie zmieniono żadnej fizyki ani punktów zdobywania nagród.
- W porcie rzeczywiście grywalna pozostaje pierwsza misja CARBONIS. Dodana warstwa źródłowego kosmosu jest przygotowana do ponownego użycia dla dalszych misji, lecz nie czyni ich grywalnymi.
- **Harmonogram 18 zadań bez zmiany numerów i bez naciągania procentów: 38% / 62%.**

