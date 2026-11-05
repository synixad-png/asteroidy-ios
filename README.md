# ASTEROIDY iOS — natywny port Swift/Metal (projekt w trakcie rozwoju)

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
