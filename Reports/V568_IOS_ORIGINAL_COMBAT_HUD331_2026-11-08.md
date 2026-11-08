# ASTEROIDY iOS v568 — audyt i port HUD misji 331 (08.11.2026)

## Źródło

Oryginalna baza dostarczona przez użytkownika: `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, zweryfikowany plik `Windows/src/RendererW3Combat331.cs`. SHA-256: `8119c1d98936e0c5ec602b49cc98f41f945312792122b33ce82740735ba0ffc3`; układ `Windows/src/UiScale336.cs` (`f95fe03e52937aece2f0192dbcfb6c657b2774a03bb521c5f2d8eee3dff9bdcb`). Porównano C# z `ASTEROIDYiOS/Sector01Scene568.swift` i `CarbonisSession568.swift` na aktualnej bazie po naprawie SFX #9.

## Port rzeczywistej misji CARBONIS 01

- `SourceCombatHUD331.swift` używa przezroczystego SwiftUI Canvas, natywnego ekranu 1280×720 dopasowanego do rozmiaru iPhone/iPad. Usunięto robocze pełnoszerokie nagłówki, prostokątny radar i diagnostyczny żółty pasek z misji.
- Pozycje według źródła: górny pasek x20–1262, radar (91,612) r69 z 32 znacznikami, wskaźniki 14 segmentów x191 y565/613/661, okrągłe wskaźniki x920/1020/1120/1220 przy y628.
- Radar liczy `Sphere67.normal` i iloczyny skalarne względem `game.flight.camera.focus/right/up`. Dot < -0,06 ukrywa daleką półkulę. Asteroidy, myśliwce i żetony pochodzą z tej samej symulacji walki co renderer planety.
- Kadłub, pancerz, życia, punkty, broń, ulepszenia, ładunki osłony i żetony są odczytywane ze stanu `CarbonisCombat568`, w tym istniejącego profilu sklepu. Bez nowych zapisów i mutacji stanu gry.
- Źródłowa energia `Tarcza145` nie działa jeszcze w tej wersji aktywnej walki CARBONIS iOS: HUD wyświetla myślnik, zamiast udawać mechaniczną osłonę. Broń jonowa, bomby i dopalacze w CARBONIS nie są wdrożone: aktualne wartości 0 nie są przyciskami ani atrapą działania.
- Oryginalny skrót pauzy na urządzeniu dotykowym pozostaje oddzielnym małym przyciskiem. Zachowano pauzę `Game.Paused`, obie połówki ekranu do lotu/skrętu i natychmiastowy ogień przy dotknięciu prawej strony.
- HUD bierze gotowy `@Published` snapshot 10Hz. Brak własnego timera, pętli fizyki, zmian shaderów Metal i wywołań AVAudioPlayer. Zweryfikowana przez użytkownika poprzednia baza audio z 60 FPS pozostaje w nienaruszonych plikach.

## Kontrole

Kod HUD i jego połączeń znajduje się w PR #10:
https://github.com/synixad-png/asteroidy-ios/pull/10

Brama CI **bez tworzenia IPA**:
https://github.com/synixad-png/asteroidy-ios/actions/runs/42468530315

Kontrakt `Tests/IOSOriginalCombatHUD331Contract.py` sprawdza źródłowe współrzędne, segmenty, radar, pochodzenie danych, pasywne dotykanie oraz niezależność audio/Metal; dotychczasowy kontrakt W3 zaktualizowano tak, aby nie wymagał starego panelu. CI testuje kod Swift także przez kompilację Xcode. Wyniki każdej rewizji należy czytać z przypisanego SHA, a nie mieszać z wcześniejszymi nieudanymi rewizjami.

**Granica potwierdzenia:** brak autentycznego porównawczego zrzutu piksel-do-piksela z Windows i testów interaktywnych iPhone/iPad dla nowego HUD. Nie przypisywać HUD-owi potwierdzonych 60 FPS na urządzeniu bez nowego testu. Aktualna funkcjonalność dotyczy grywalnej CARBONIS 01; pełne pozostałe 25 misji wciąż wymagają portowania.

**Harmonogram:** 18 ustalonych zadań bez zmiany zakresu; rozdział nr 14 `Menu W3, HUD i ustawienia`. Postęp całego portu pozostaje 38% implementacji / 62% do ukończenia, bez sztucznego naliczania innych nieukończonych ekranów.
