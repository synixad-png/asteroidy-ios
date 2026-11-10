# ASTEROIDY iOS — oryginalne planetarium PC v602: renderowanie bez kadrowania
Data: 2026-11-10

## Podstawa
Obowiązuje dokładna paczka `Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (Windows/SteamOS), a kod iOS rozwijany jest na gałęzi `feature/ios-h55-v580-native-entry`. Nie zmieniono działającego edytora 46 elementów.

**Potwierdzone w źródle Windows 11 v602:**
- `Windows/src/HudGlbAssets.cs::DrawHudGlb`: pełny HUD `ortho(0,1280,720,0,-2000,2000)`, bez przycinania do prostokąta `HudWidget`. Pozycja `Project(widget.X + Width/2, widget.Y + Height/2)`. Skala `0.44 * Width * widget.Scale / PlanetModelRadius463`. Orientacja modelu Y/X/Z, przesunięcie modelu o `-PlanetModelCenter463`.
- `Windows/src/HudLayout.cs`: `hud.planetarium` jest elementem HUD, a jego współrzędne F6 nie są pozycją obiektu misji.
- `Shared/assets/hud/default-layout.json`: zatwierdzone X=64.7882; Y=553.0863; scale=1.4702; pitch=-20.
- Oryginalny `Shared/assets/hud/planetarium.glb` SHA256 `71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860`, 141 węzłów, 159 kanałów, jeden klip `HUD_PLANETARIUM_PREMIUM_48S_LOOP`. Węzeł `world` (0) nie ma kanału animacji translacji. Nie zmieniono modelu ani animacji.

## Wykryta konkretna rozbieżność iOS
Poprzedni `HudPlanetariumHost600` ustawiał osobny `SCNView` o rozmiarze prostokąta F6 `250×135 * scale`. Taki view przycina geometrię wychodzącą poza mały prostokąt, czego nie robi PC, i posiada własny miniukład kamery zamiast pełnoekranowej projekcji HUD. Dodatkowo jego wcześniejsze osadzenie w zagnieżdżonej strukturze SwiftUI nie zapewniało niezależnej, jednoznacznej projekcji PC.

## Nowa implementacja
- `ASTEROIDYiOS/HudPlanetariumProjection.swift`: czysta matematyka od współrzędnych F6/wyświetlacza UIKit do nieruchomej kotwicy SceneKit, stałej skali 0.44×/radius i kamery ortograficznej o wysokości całego ekranu. Zero powiązania ze statkiem.
- `ASTEROIDYiOS/HudPlanetariumHost600.swift`: napisany na nowo, korzysta z `HudPlanetariumProjection`. Renderuje GLB na jednej, transparentnej pełnoekranowej warstwie HUD, bez `.position`/`.offset` małego widoku.
- `ASTEROIDYiOS/HudPlanetariumScene600.swift`: przebudowano rozmieszczenie grafu SceneKit: nieruchomy `PC602_HUD_SCREEN_ANCHOR`, skalujący `PC602_HUD_PIXEL_SCALE`, pivot Y/X/Z, offset oryginalnego centrum modelu; ortograficzna kamera na środku *całego* ekranu (nie obiektu). Odtwarzany jest nadal dokładnie oryginalny klip GLB; maski 72 bąbelków, błyski i istniejąca korona pozostają. Animator nie otrzymuje pozycji lotu ani przechyłu statku.
- Oryginalna fizyka, render Metal misji, sterowanie, SFX, mechanika łupów, wszystkie pozostałe elementy HUD i edytor nie są zmienione.

## Testy
- `Tests/HudPlanetariumProjectionTests.swift`: fizyczna matematyka projekcji 1280×720, iPhone 956×440 z wcięciami oraz iPad 1024×768. Testuje F6, skalę, połowę wysokości całego ekranu, stabilność kotwicy, większy od ramki F6 rozmiar modelu, brak renderu dla niewidocznego elementu.
- `Tests/HudV602TouchRuntimeContract.py`, `HudPlanetariumIntegration600Contract.py`, `HudMotionLiveRenderer600Contract.py`: sprawdzają podłączenie oryginalnego renderera i zakaz powrotu do kamery lotu/mini SCNView.
- Zweryfikowany przebieg HUD CI: https://github.com/synixad-png/asteroidy-ios/actions/runs/42914153563 — PASS verify-core i verify-ios-parser.
- Pełny Xcode arm64 Release, oryginalne zasoby, ZIP CRC oraz IPA: w chwili sporządzenia raportu kompilacja https://github.com/synixad-png/asteroidy-ios/actions/runs/42914153620 trwa. NIE podawać nowego IPA przed PASS.

## Uczciwe ograniczenia
Nie wykonywano interaktywnego testu iPhone/iPad ani fizycznego pomiaru wydajności SCNView/Metal. To implementacja odpowiadająca źródłowej projekcji PC na poziomie macierzy i skali; jej końcowe dopasowanie wizualne wymaga instalacji nowego IPA i rzeczywistego testu urządzenia.
