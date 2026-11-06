# CARBONIS 01 — prawa połowa ekranu: skręt + ostrzał

**Data:** 6 listopada 2026. **Zmiana:** sterowanie dotykowe pierwszej misji ASTEROIDY iOS, bez przebudowy symulacji fizyki, projektu menu lub modeli 3D.

## Zaimplementowane

- **LEWA połowa:** bez zmian. `DragGesture(minimumDistance:0)` nadal aktualizuje wyłącznie `session.input(move:...)` z poprzednią czułością `/110`, a zwolnienie zeruje `move`.
- **PRAWA połowa:** zachowuje poprzedni `aim` sterowany przesunięciem palca (`/100`), ale `onChanged` przekazuje jednocześnie `shooting:true`. Minimalny dystans gestu wynosi 0, więc pojedyncze dotknięcie rozpoczyna ostrzał bez dodatkowego przycisku. `onEnded` przesyła jednocześnie zerowy `aim` i `shooting:false`. Trzymanie palca nie zmienia oryginalnych odstępów strzałów ani mocy: te pozostają w `CarbonisCombat568.fireSourceWeapon()` oraz zakupionych ulepszeniach.
- **Interfejs:** usunięto czerwony element `OGIEŃ`, jego odrębny `fireGesture` i identyfikator `sector01-fire-pulse`. Prawy obszar nie ma wizualnego analoga, podobnie jak lewy. HUD pokazuje pomoc `LEWA: LOT / PRAWA: SKRĘT + OGIEŃ`.
- **Nieblokujące nakładki:** pasywne HUD, radar i stopka nie przechwytują dotknięć (`allowsHitTesting(false)`), lecz przycisk powrotu, ekran podsumowania i serwis pozostają działającymi kontrolkami.
- **Przerwanie gestu:** po powrocie ze stanu nieaktywnego iOS `scenePhase` zwalnia oba wektory sterowania i `shooting`; również przy wyjściu z misji wywoływane jest `session.release()`.

## Co już istniało (nie wprowadzano regresji)

`CarbonisCombat568.swift` zawiera rzeczywiste pociski Pulse, Twin i Scatter wraz z opcjami mocy, szybkostrzelności, przebijania oraz trafianiem w skały i myśliwce. `SphereFlight67.tick` przenosi statek po sferze `Sphere67`, a `FlightDynamics556` obsługuje rozpędzanie, opóźnianie, bezwładność i wizualny przechył. Istnieją fizyczne kontakty, uszkodzenia i odrodzenia. **To adaptacja**, a nie w pełni zweryfikowana identyczność całego modelu fizyki Windows v568.

## Testy i ograniczenia

- `Tests/V568W3NativeMenuContract.py`: osobne strefy, zachowany ruch lewy i celowanie prawym, natychmiastowy `shooting:true`, wyłączenie po zwolnieniu, brak przycisku i blokujących nakładek.
- `Tests/IOSInterruptedTouchSourceContract.py`: brak zawieszonego ostrzału po nieaktywnym stanie aplikacji.
- `Tests/CarbonisCombat568Tests.swift`: pierwszy strzał od razu przy `shooting:true`, seria po utrzymaniu, brak nowych strzałów po `shooting:false`, dalszy ruch statku.
- Należy niezależnie potwierdzić sukces CI Swift/Linux i **natywnej kompilacji Xcode**. Tylko rzeczywisty test dwóch palców na iPhone/iPad może potwierdzić brak konfliktów gestów na danym urządzeniu.

Nie zmieniono planu całego portu (38% wykonane / 62% pozostało) ani listy 18 zadań; zadanie dotyczy konkretnej poprawki sterowania w pierwszej misji.
