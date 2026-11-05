# ASTEROIDY iOS — port Swift/Metal (projekt w trakcie rozwoju)

## Stan bieżący — 5 listopada 2026

Pełny, stały harmonogram 18 zadań i status prac: [PORT_STATUS_18_TASKS.md](PORT_STATUS_18_TASKS.md).

W repozytorium działa workflow GitHub Actions `.github/workflows/build-ios.yml` dla testów Swift/Linux oraz kompilacji Xcode/ARM64 na iPhone/iPad. **Rzeczywista kompilacja i udany upload niepodpisanego IPA** zostały potwierdzone dla commita `596767b`, w [przebiegu 42027976783](https://github.com/synixad-png/asteroidy-ios/actions/runs/42027976783). Artefakt jest niepodpisany i wymaga podpisania przed instalacją przez Sideloadly; nie przeprowadzono testu na fizycznym urządzeniu.

Późniejsze commity rozwijają zadanie 7: kolejność ochrony, rzeczywisty Guardian37, Talents78, tryb kooperacji, kolizje robotów i bryły bossa oraz regresję wielu trafień. **Nie należy utożsamiać wyników starszego udanego buildu z wynikami dla późniejszych commitów**; obowiązuje kontrola statusu GitHub Actions konkretnego SHA. Port nie jest ukończoną wersją gry Windows/SteamOS.

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
