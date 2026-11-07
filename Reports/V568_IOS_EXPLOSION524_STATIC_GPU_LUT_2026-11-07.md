# ASTEROIDY iOS v568 — Explosion524, optymalizacja istniejącego modułu Metal
**Data:** 07.11.2026. **Baza:** zatwierdzone źródła iOS v568 / źródłowe procedury oryginału Windows `Explosion524`. Bez numerowania nowej wersji przed ukończoną kompilacją urządzeniową.

## Granice zmian — brak „slop code”
Zmiany funkcjonalne są wyłącznie w dwóch istniejących, właściwych plikach:
1. `ASTEROIDYiOS/CarbonisExplosion524Renderer.swift` — zasoby GPU, oryginalne 24 wierzchołkowe narożniki wielokąta i parametry pojedynczego wybuchu.
2. `ASTEROIDYiOS/Sector01Explosion524.metal` — właściwy shader Explosion524 (wierzchołki i raymarching).
Nie dopisano wybuchów do `App.swift`, `CarbonisCombat568.swift`, `Sector01Scene568.swift`, kodu pocisków ani ogólnych ustawień. Własne testy w `Tests/`, konfiguracja testów wyłącznie w `.github/workflows/`.

## Faktyczne, zmierzalne zmiany
- Przed: dla każdego widocznego wybuchu w każdej klatce CPU budował 24 trójkąty = 72 wierzchołki × 5 float = **1440 B** i wysyłał przez `setVertexBytes`; ponadto obliczał dla każdej współrzędnej lokalnej `center+right*...+up*...`.
- Teraz: niezmienny 24-trójkątny wachlarz zawiera **72 × 2 float = 576 B** i jest tworzony oraz przekazywany do jednego `MTLBuffer` **raz na renderer**. Vertex shader przelicza światowe położenia z `centerExtent/right/up` przekazanych w oryginalnym jednoklatkowym `Parameters` (+48 B na wybuch). Bez dynamicznej kopii 1440 B/wybuch/klatka. Nie zmienia się liczba trójkątów ani widoczna powierzchnia.
- Przed: w `explosionField524` każda próbka GPU dla każdego kłębu wykonywała dwa kosztowne dzielenia przez `radius²·0.56` i `radius²·2`, chociaż promień jest stały przez całe rysowanie wybuchu.
- Teraz: CPU oblicza dwa odwrotne współczynniki **raz na kłąb i wybuch**, przechowując je w 3. istniejącym `float4 smokeShape` (zajmują nieużywane dotychczas pola z/w). Shader mnoży przez te liczby; nadal zachowuje wszystkie 13 domyślnych i maksymalnie 17 oryginalnych kłębów. Przy 13 kłębach i 22 próbkach górna granica to **572 dzielenia GPU na piksel** zastąpione mnożeniami — faktyczny GPU compiler i liczba próbek mogą zmniejszać korzyść.
- Przed: stałe `exp(-age*1.3)`, `exp(-max(0,age-0.45)*1.25)` i `smoothstep(0.35,1.95,age)` były zapisane wewnątrz samplingu. Teraz są obliczane przed pętlą i przekazywane do funkcji pola, przy tych samych równaniach; kompilator mógł już wcześniej wykonać część tej optymalizacji.
- Oryginalne `R8 64³` dane Xorshift, liczby kroków, szum, paleta termiczna, `alpha`, współczynniki dymu i ognia, życie wybuchu, sceny planety i kosmosu oraz opcje `WYBUCHY` pozostają nienaruszone.

## Rygor porównania
- `Tests/Explosion524GpuAlgebraAndStaticMeshTests.py`: sprawdzenie przyporządkowania identycznych pól C/Metal/Swift, starego i nowego przekształcenia 72 wierzchołków; **70 000 losowych porównań float32** dawnego wzoru dzielenia z nowym mnożeniem odwrotności promienia. Warunek błędu względnego `≤0.000003` (3 ppm), nie deklaracja bitowej identyczności wyniku.
- `Tests/Explosion524ConservativePolygonTests.py`: nadal oryginalne **250 000 punktów** potwierdza wypełnienie niezerowej powierzchni wybuchu. Zmieniono wyłącznie kontrolę miejsca generowania wierzchołków: stały shader GPU zamiast uprzednio dynamicznego CPU.
- `Tests/Explosion524OptimizedRayBoundsTests.py`: niezależnie pilnuje, by nie odrzucić jakiejkolwiek próbki niezerowej alfa.
- Oryginalne testy fizyki, bronii, kolizji, dźwięku, HUD, misji i profilu nadal stanowią bramki CI.

**Ważne:** nie wykonano testu pikselowego obrazu ani benchmarku fizycznego iPhone/iPad. Mniej instrukcji i kopii nie oznacza potwierdzonego wzrostu FPS z 35 do 60. Natywna kompilacja i raport IPA są potwierdzone niżej.

## Wyniki weryfikacji gałęzi przed wydaniem
- [GitHub Actions #397](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395393809): **3/3 zadania PASS** (kompilacja Swift/Metal w Xcode, wszystkie testy walki i źródłowy kontrakt geometrii).
- **70 000 porównań w precyzji float32**: maksymalny błąd względny `0.000000221` (2,21×10⁻⁷), limit testu 3×10⁻⁶ — **PASS**.
- Stary i nowy wachlarz: 72 współrzędne narożników i ten sam zakres UV, test oryginalnej obwiedni 250 000 punktów — **PASS**.
- Optymalizacja źródłowych granic raymarchingu: 2 648 776 zbadanych próbek, w tym 985 640 matematycznie zerowych pominiętych — **PASS**, bez cięcia faktycznego efektu.
- Natywny build urządzeniowego IPA i obserwacja GPU/termiki na fizycznym urządzeniu to **oddzielna kontrola po połączeniu do main**.

## Następny krok
Ukończyć test całego native ARM64 IPA oraz odczytać na fizycznym urządzeniu GPU ms / CPU ms / FX CPU W przy podobnej liczbie nakładających się eksplozji. Jeżeli GPU nadal dominuje, konieczny jest Metal Debugger/Performance HUD, a nie przypadkowa redukcja próbek lub liczby efektów.

Harmonogram portu jest zachowany: **18 niezmiennych zadań, 38% ukończone / 62% pozostało**.

## Finalny wynik wydania
- [GitHub Actions #134 — Xcode iPhone/iPad IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864027): **4/4 PASS**, commit źródłowy `d7bb3e701cc2b085210f840908f25b72da0dd5c7`.
- **Xcode Release / iPhoneOS ARM64 — BUILD SUCCEEDED**. Nowy `Sector01Explosion524.metal` skompilowano przy użyciu kompilatora Metal firmy Apple.
- [Pobierz niepodpisane IPA w artefakcie](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864027/artifacts/13583633282): w archiwum GitHub `ASTEROIDY-iOS-device-unsigned-ipa.zip` znajduje się `ASTEROIDY_iOS_UNSIGNED.ipa`. Rozmiar zewnętrznego artefaktu ZIP: **27 967 024 B**.
- SHA-256 **zewnętrznego artefaktu GitHub ZIP**, nie samego IPA: `2f784cbd978ccf6529c3bb2df669ac6ac147e6b4c8dc4927b6dd887e19fa9288`.
- GitHub `unzip -t` / `Tools/verify_ipa.py` — **PASS**: ZIP CRC, `Payload`, ARM64, iPhone/iPad, iOS 17.0+, zasoby, bundle `com.synixad.asteroidyios`; plik IPA pozostaje niepodpisany.
- [GitHub Actions #398 — główna gałąź testów bojowych](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864016): **3/3 PASS**.
- **Brak testów interaktywnych na fizycznym iPhone/iPadzie. Wzrost FPS nie został zmierzony**, wygląd wybuchów w ruchu wymaga porównania przez użytkownika.
