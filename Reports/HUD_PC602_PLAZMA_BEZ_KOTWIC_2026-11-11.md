# ASTEROIDY iOS — samodzielne pasma plazmy, bez punktów zaczepienia
Data: 2026-11-11

## Decyzja użytkownika
Zrezygnowano z **jakiegokolwiek przyczepiania końców plazmy do planetarium lub do drugiego widgetu**. Każdy pasek musi dać się osobno przesuwać w dotykowym edytorze F6 bez pociągania pozostałych wskaźników ani planetarium. Kolory i wartości: kadłub czerwony góra, pancerz pomarańczowy środek, tarcza zielona dół. Zatrzymanie krzyżowania czerwonej i zielonej wstęgi.

## Fakty o zatwierdzonym układzie v602
Oryginalny `HudLayout600.defaults()` i `Assets/hud/default-layout.json` przechowują górny widget z ID `shield.bar` (y=577.9584), środkowy `armor.bar` (y=614.8741) i dolny `hull.bar` (y=654.6442). Ich zapisane położenia *nie zostały zmienione*. Należy odróżniać identyfikatory zapisanych obszarów od odczytów stanu statku: logiczne źródła danych mają stale kolejność [hull,armor,shield].

## Nowa implementacja
- `ASTEROIDYiOS/HudPlasmaLayer600.swift`: renderuje 5 oryginalnych wstęg i 7 nieregularnych jęzorów niezależnie przez `SourceCombatHUD331.widgetContext`. Mapowanie geometryczne widocznych pasm: `["shield.bar","armor.bar","hull.bar"]`; wartości, tints i maksimum pozostają `[hull,armor,shield]`. Żadnej interpolacji łączącej punkt modelu z końcem paska, żadnych pośrednich kotwic.
- `ASTEROIDYiOS/HudPlanetariumMetal600.swift`: własna projekcja F6 planetarium oraz oryginalny `HudMotionProject600`/waga widgetu planetarium. Położenia pasków nie wpływają już na centrum ani przechył modelu. Oryginalny model GLB, 159 kanałów animacji oraz naprawa 418 resetów bąbelków nie uległy zmianie.
- Całkowicie usunięto nieużywane moduły `HudPlasmaBridge600.swift` i `HudPlanetariumPlasmaAnchor600.swift` oraz stare testy wymagające ich istnienia.
- `Tests/HudPlasmaIndependent600Tests.swift` i `Tests/HudPlasmaIndependent600Contract.py`: sprawdzają właściwy porządek kolorów i trzech rzędów, niezależną edycję każdej belki i planetarium, brak starych modułów oraz niezmieniony GLB v602.
- Zaktualizowano kontrakty źródeł i dwa workflow: kontrola HUD-u oraz tworzenie IPA.

## Uwagi
W celach zachowania osobistych ustawień zapisanych na urządzeniu i układu zatwierdzonego przez użytkownika nie migrowano ani nie nadpisano F6 JSON. Dlatego górna wizualna belka kadłuba wykorzystuje odziedziczony identyfikator edytora `shield.bar`, a dolna wizualna belka tarczy — `hull.bar`. Dotyk fizycznej belki nadal umożliwia przesuwanie właściwego widocznego elementu. Jeśli w przyszłości użytkownik będzie chciał zmiany także nazw w selektorze F6, wymaga to osobnego zadania, a nie ponownego przyczepiania plazmy.

## Status
GitHub HUD contracts #228: verify-core PASS i verify-ios-parser PASS. No Slop #1011 PASS. Pełny iOS ARM64 Release #125: w chwili pisania raportu trwa kompilacja, nie można jeszcze przypisać mu PASS ani twierdzić, że użytkownik sprawdził obraz na iPadzie.
