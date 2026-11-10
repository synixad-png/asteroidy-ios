# ASTEROIDY iOS — PC v602: przepisany edytor HUD i ekranowe planetarium
Data: 2026-11-10
Repo: synixad-png/asteroidy-ios
Gałąź: feature/ios-h55-v580-native-entry
Baza oryginalna: Asteroidy_v602_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip

## Potwierdzone źródła
- Windows/src/HudLayout.cs — 46 widgetów, ScreenLeft/ScreenTop, SelectAt, StartDrag/Drag, ograniczenia 12 px, skala 3D 0.1–6.
- Windows/src/RendererHudLayout.cs — edycja zatrzymuje grę, zapis i anulowanie są oddzielne.
- Windows/src/HudGlbAssets.cs — cała animowana scena 3D jest renderowana w przestrzeni ekranu 1280×720, poza kamerą misji. F6 dotyczy pojedynczej instancji HUD.
- Shared/assets/hud/default-layout.json — zatwierdzone współrzędne, w tym planetarium X=64.7882,Y=553.0863,scale=1.4702,pitch=-20.
- Shared/assets/hud/planetarium.glb — oryginalny model ma 141 węzłów i 159 kanałów. Główny węzeł world nie jest kanałem translacji animacji.

## Zastąpiona implementacja
- HudLayoutEditor600.swift — napisany na nowo: jedna UIViewRepresentable/TouchSurface przechwytuje realny dotyk w pauzowanej misji. Nie używa starych nakładających się SwiftUI DragGesture/MagnificationGesture. Pełna obsługa zaznaczania wszystkich widgetów, przesuwania, szczypania, listy 46 elementów, widoczności, osi 3D, zapisu/anulowania, eksportu/importu JSON i przywracania oryginalnych wartości.
- HudEditorGeometry.swift — jeden czysty moduł geometrii źródłowej: przy kolizji hitboxów najmniejszy obszar ma pierwszeństwo, a remis rozstrzyga odwrotna kolejność PC. Oddzielne kotwice iPhone/iPad, model GLB skalowany wokół środka, bez wpływu na symulację.
- HudLayoutMarker600.swift — usunięty nieużywany stary kod widoków hit-test.
- HudPlanetariumHost600.swift — napisany na nowo jako ekranowa GeometryReader z bezwzględnym przesunięciem ramki w pikselach wyświetlacza. Nie jest elementem sceny świata ani odbiorcą przesunięć od ruchu kamery. Wewnętrzny HudPlanetariumScene600 i oryginalne 159 kanałów GLB pozostają niezmienione.
- Sector01Scene568.swift — usunięty jedynie nieużywany argument motionActive hosta; mechanika i Metal niezmienione.

## Testy
- Nowy wykonywalny HudEditorGeometryTests.swift — 46 hitboxów, priorytet małych elementów, dwie niezależne selekcje radar/planetarium, przeciąganie bez ruszania sąsiednich elementów, skala, niewidoczne widgety, współrzędne iPhone oraz iPad.
- Zaktualizowane realne kontrakty: HudLayout600Contract.py, HudV602TouchRuntimeContract.py, HudMotionLiveRenderer600Contract.py, HudPlanetariumIntegration600Contract.py.
- Rozszerzony workflow HUD i workflow pełnego IPA o kompilację i wykonanie testu geometrii.
- GitHub Actions HUD validation #184, run 42908963500: verify-core PASS, verify-ios-parser PASS.
- Code Quality / No Slop: poprzednie sprawdzone commity PASS.
- Pełny Xcode ARM64 Release i kompletne IPA dla ostatniego commita: w czasie zapisu tego raportu NIEPOTWIERDZONE; run 42908963138 oczekiwał na uruchomienie.

## Niezależna weryfikacja urządzenia — konieczna
- Brak testu dotykowego na fizycznym iPhonie/iPadzie oraz renderowania GPU/SceneKit.
- Po skompilowaniu IPA sprawdzić rzeczywistą możliwość zmiany wyboru radar -> planetarium -> inny element, zapis/odczyt, brak ruchu całego planetarium wraz z kamerą, oryginalną animację wewnętrzną oraz osadzenie poprawnego GLB. Brak takich testów oznacza, że nie można jeszcze deklarować naprawy jako w 100% zweryfikowanej.

Nie modyfikowano oryginalnego PC v602, świata Metal, fizyki, kolizji, sterowania, łupów, broni, NPC ani wewnętrznych klatek GLB.
