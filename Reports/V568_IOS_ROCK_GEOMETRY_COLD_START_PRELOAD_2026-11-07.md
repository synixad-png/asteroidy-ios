# ASTEROIDY iOS v568 — eliminacja generowania 80 wariantów skał w klatkach walki

Data: 07.11.2026. Baza: main po poprawce audio #137, merge PR #2 `a92df9ee1c085a0b1cdde0b3a9a81cc3d4487ad5`.

## Problem potwierdzony w źródłach

Użytkownik zaobserwował spadki klatek podczas trafień w pierwszych 2–3 minutach od zimnego startu, następnie stabilne 60 FPS. Osobna poprawka audio v568 przeniosła generowanie 13 ścieżek na kolejkę .utility i dodała bezpieczne punkty zatrzymania; dotychczasowa wersja #137 jest zachowana jako punkt porównawczy.

W `Sector01CarbonisPreview568.swift` inicjalizator renderera Metal tworzył bufory dla kształtów wyłącznie początkowych asteroid. Kod renderowania po pierwszym pojawieniu się nieobecnego kształtu wywoływał synchronicznie `CarbonisRockGeometry568.vertices(shape:)` oraz `gpu.makeBuffer(...)` w klatce 3D. Ten dodatkowy koszt mógł następować podczas podziału skał Physics68, spawnu i strzelania, niezależnie od samych shaderów wybuchów.

## Zrealizowana poprawka

- `CarbonisRockGeometry568.swift`: niezmieniony algorytm StoneSubdivide56/RockVertices75; dodano wyłącznie stałą liczby osiągalnych kształtów `sourceShapeCount=8*5*2=80`. `shapeSeed & 7` daje 8 ziaren, `tier` pięć wartości 0–4, a `fragment` dwa stany.
- `Sector01CarbonisPreview568.swift`: w inicjalizatorze **prawdziwej misji** (`gameSession != nil`) tworzone jest wszystkie 80 oryginalnych siatek i `MTLBuffer`, zanim renderer otrzyma pierwszą klatkę 3D. W podglądzie menu W3 (`gameSession == nil`) nadal tworzone są wyłącznie początkowe kształty; zachowany jest dotychczasowy fallback na wypadek niezidentyfikowanego kształtu.
- `Tests/CarbonisRockGeometry568Tests.swift`: test obejmuje wszystkie 80 wariantów zamiast 45, wymaga 960 wierzchołków i stride 12, poprawnych normalnych, skończonych współrzędnych, kolorów i deterministyczności.
- `Tests/RockShapeWarmup568Contract.py`: test pilnuje dokładnego źródłowego odwzorowania, przygotowania przed walką oraz pozostawienia odrębnego lekkiego W3.

Teoretyczny koszt pamięci 80 buforów siatek: **80 × 960 × 12 × 4 = 3 686 400 B (około 3,52 MiB GPU)** na renderer. To suma wynikająca ze stride; nie jest pomiarem alokatora Metal ani pamięci współdzielonej. Tworzenie całego zestawu na głównym wątku może wydłużyć wejście do pierwszej misji. Tego czasu nie zmierzono na fizycznym urządzeniu.

## Weryfikacja

- [PR #2](https://github.com/synixad-png/asteroidy-ios/pull/2), ukończone i scalone po testach.
- [CI PR pierwsze uruchomienie](https://github.com/synixad-png/asteroidy-ios/actions/runs/42410578478) i [CI PR końcowe](https://github.com/synixad-png/asteroidy-ios/actions/runs/42410671547): oba **2/2 PASS** — natywna kompilacja Swift/Metal bez IPA i pełna macierz regresji rozgrywki, w tym geometria wszystkich 80 wariantów; zadanie publikujące do main pominięte prawidłowo.
- [Główne testy po merge #413](https://github.com/synixad-png/asteroidy-ios/actions/runs/42411007705) oraz [kompilacja IPA #138](https://github.com/synixad-png/asteroidy-ios/actions/runs/42411007709) uruchomione po merge. Ich końcowy wynik wymaga osobnego potwierdzenia; nie deklarować PASS przed sprawdzeniem statusu.

## Pozostało i ograniczenia

Prawdziwy test zimnego startu iPada i iPhone'a: porównać bez zmian ustawień IPA #137 oraz IPA #138, szybkość wejścia do misji, strzelanie i trafienia w pierwszych 2–3 minutach oraz po 3 minutach; spisać FPS, CPU, SYM, WAIT, GPU ms. Testy CI nie dowodzą rzeczywistego wzrostu FPS. Nie zmieniano obrażeń, trajektorii, źródłowych shaderów, pocisków, efektów wybuchu, muzyki, układu 4:3/19,5:9 ani ustawień grafiki.

Harmonogram całego portu pozostaje niezmieniony: **18 zadań; 38% ukończone i 62% pozostało**. Wąska optymalizacja czasu wykonania nie zwiększa funkcjonalnego pokrycia portu.
