# ASTEROIDY iOS v568 — oryginalny przelot Intro41 przed CARBONIS 01
**Data:** 07.11.2026. **Baza:** oryginalny Windows/SteamOS v568 i istniejący port Metal iPhone/iPad. Numeru wersji nie podniesiono.

## Źródła oryginalne: sprawdzone w rzeczywistym archiwum v568
- `Windows/src/Intro41.cs`: `Game.BeginLevelIntro`, `Game.StepIntro`, `FinishIntro`, 16 sekund, `ApproachStart=8.4`, `ArrivalTime=15.2`, reset symulacji gry przy przejściu do Playing i źródłowy tor kamery.
- `Windows/src/GpuIntro41.cs`: kolejność rysowania `IntroSky`, pas asteroid (`OrbitWorld51`, 820 obiektów), prawdziwa planeta misji z `MissionPlanetScale523(24)`, oryginalny Vanguard431 + wydechy GpuShip491 + atmosfera GpuPlanet47.
- `Windows/src/RendererW3Transitions319.cs`: faktyczny panel `DrawW3MissionArrival319` — ROZPOCZĘCIE MISJI, CEL OPERACJI, procent przelotu, ENTER/A POMIŃ; zachowane proporcje 4:3 / 16:9 w natywnym SwiftUI.
- `Windows/src/PlanetBiomes.cs`: CARBONIS 01, nazwa `CARBONIS / PBR`, świecenie atmosfery `#EC4E19`. Nie wolno pokazywać Boreas GLB (poziom 5) przy locie do Carbonis.
- `Windows/src/MusicAudio.cs`: IntroMusic43 na poziomie 15 (oddzielny PCM 16s), docelowa muzyka misji startuje dopiero po zakończeniu intro.
- `Windows/src/Program.cs`: Enter oraz A/Start pomijają Intro. Na iOS pad/touch chroniony po 0.6 s, sprzętowy Enter działa natychmiast.

## Wdrożone w porcie
1. `ASTEROIDYiOS/CarbonisIntroPlanet568.swift`: rzeczywista indeksowana planeta CARBONIS C279 z identycznych SHA-256 źródłowych assetów i połączeniem 3 map do jednej tekstury `CarbonisCombined469` przez jednorazowy shader Metal; skala introspekcyjna odpowiada źródłowemu `MissionPlanetScale523(24)`.
2. `ASTEROIDYiOS/MetalRenderer.swift`: historyczny 16-sekundowy `IntroOrbit41` uruchamiany jednokrotnie w trybie misji, używający oryginalnego statku, kamer, pasa asteroid, plazmy silników. Przy misji 01 renderowana jest C279 i pomarańczowa atmosfera `#EC4E19`, a nie diagnostyczna planeta Boreas; jej dotychczasowy tryb diagnostyczny pozostawiono bez zmian.
3. `ASTEROIDYiOS/MissionCinematic568.swift`: natywny ekran przelotu 3D z oryginalnymi etykietami W3, procentowym paskiem i pomijaniem touch/Enter/Space/pad A/Start, czyszczeniem sterowania oraz ochroną przed podwójnym przejściem.
4. `ASTEROIDYiOS/App.swift`: dwie rzeczywiste ścieżki wejścia do obecnie grywalnej misji (Nowa gra i wybór z atlasu) uruchamiają Intro41 przed utworzeniem aktywnej `Sector01Scene568`. Ponowienie po porażce także uruchamia Intro41 i zachowuje blokadę podwójnych nagród już zaliczonej misji. Nie włącza się symulacji Physics68 podczas przelotu.
5. `ASTEROIDYiOS/OriginalAudioAV568.swift`: dedykowany oryginalny `Audio568/Intro43.m4a` zamiast zastępczej muzyki; poprawna kolejność menu→Intro43→MusicMix.TrackFor(mission), reset na powrót do mapy, ochrona przed spóźnionymi eventami fazy walki podczas restartu.
6. `Tests/MissionIntro41SourceContract568.py`: kontrakt integracji obejmujący planetę, oryginalne źródła, audio i zachowanie rozgrywki. Włączony do workflow testów i pełnej kompilacji iOS.

## Ograniczenia i testy
- 26-planetowy atlas działa, ale tylko misja 01 CARBONIS ma obecnie port rzeczywistej sceny walki. Dalsze sektory muszą poczekać na własne oryginalne assety i pętle rozgrywki — bez udawanych wejść do nieukończonych misji.
- Istniejące intro iOS jest w pewnych aspektach częściowym portem: skomplikowane asteroidowe siatki IntroStone tworzy progresywnie; opcjonalnie występuje historyczny wielościenny placeholder, a nowa nieukończona gałąź oryginalnego NewHome290 pozostaje do źródłowego uzupełnienia. Nie należy deklarować 100% zgodności każdej klatki z Windows.
- Kontrakt statyczny i testy źródłowe nie są testem interaktywnym na fizycznym iPhonie/iPadzie. Wymagane natywne Apple Xcode/Metal ARM64, pełny IPA, porównanie końcowej sceny i wydajności na urządzeniu. Wynik należy raportować dopiero po zakończeniu GitHub Actions.
- Nie modyfikowano `Windows/SteamOS`, parametrów fizyki, hitboxów, zachowania pocisków, ustawień efektów i oryginalnej geometrii C279.
- Stały harmonogram 18 zadań: **38% wykonane / 62% pozostało**. Ten etap jest integracją istniejących źródeł i sceny iOS; procent całego portu bez podwyższenia przed rzeczywistą weryfikacją.

