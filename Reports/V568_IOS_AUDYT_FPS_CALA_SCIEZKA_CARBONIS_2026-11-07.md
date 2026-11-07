# ASTEROIDY iOS v568 — audyt FPS CARBONIS i ustawień (7 listopada 2026)

## Potwierdzone w prawdziwych plikach oryginalnego Windows iOS

| Badany etap | Oryginalny Windows | Port iOS przed audytem | Po audycie |
|---|---|---|---|
| Tekstury CARBONIS | `GpuPlanet.cs:175–224` — GDI+ składa i buforuje `CarbonisCombined469` przy zmianie jasności lawy | Fragment GPU próbkował base, emission i irradiance przy rysowaniu pikseli | Jedna wynikowa 4096×2048 RGBA po jednorazowym compute Metal, przebudowa tylko po zmianie jasności |
| Opaque planety | `GpuPlanet.cs:251` wyłącza BLEND | Przezroczyste mieszanie powierzchni | Blending wyłączony, C279 ma alpha 1 dla każdego z 137067 wierzchołków |
| Back-face C279 | `GpuPlanet.cs:251` **wyłącza GL_CULL_FACE** | Obie strony każdej ściany | iOS-only culling tylnych ścian, test 270249 trójkątów skierowanych na zewnątrz; **wymaga testu wyglądu** |
| Ukryte skały i wrogowie | `GpuSphere67.cs:20–39` `VisibleSurface73` | Rysowane niezależnie od kamery | Konserwatywna sfera wewnątrz oryginalnego terenu, test frustum iPada/iPhone’a, symulacja bez zmian |
| Rysowanie wielu asteroid | `GpuRockInstancing75` przy progu liczby asteroid | Oddzielne draw calls | **Nadal otwarte** — potencjalna strata CPU do potwierdzenia profilowaniem |
| Wyświetlanie FX | Oryginalne suwakowe presety Explosion524 / ShotLight285 | Wspólny nienazwany iOS-only switch w GRAFIKA oraz sztywne stałe limity | Dwie osobne opcje we właściwych kartach, źródłowe suwaki mają działanie także z obniżoną jakością |
| FPS / czas GPU | Co 0,5 s, także diagnostyka gry | Zastępcze `1/FPS` mogło być błędnie opisane jako `GPU ms` | Rzeczywiste GPU ms albo `n/d`; osobno CPU, symulacja i WAIT |

### Rzeczywiste dane źródłowe
Oryginalny C279: **270249** trójkątów / **810747** indeksów / **137067** wierzchołków, wszystkie trójkąty zwrócone na zewnątrz; max/min promienia źródłowego 1.096075/0.91967547, po normalizacji min 0.8390625. `SourceVisibleSurface73` stosuje bezpieczny wewnętrzny promień 0.80. Materiały: base **4096×2048 RGB JPEG**, emission **4096×2048 RGB PNG**, irradiance **1024×512 RGB PNG**, w MTL compute resamplowany liniowo z clamp-to-edge, tak jak zamysł bilinear GDI+ źródła. Połączenie RGB zachowuje mnożniki 1/0,8/0,5, progi maski 0,12/0,46 oraz odbite światło.

### Ograniczenia
Nie istnieje pomiar FPS na fizycznym urządzeniu po tych zmianach, więc **nie ma dowodu usunięcia spadków do 35 FPS**. Nie wykonano interaktywnego porównania wyglądu iOS z Windows, zwłaszcza po iOS-only cullingu; nie deklarować 100% zgodności obrazu. Reszta 25 misji iOS nadal czeka na implementację — nie można ich testować end-to-end jako gotowych scen.

### Weryfikacja
- Linux: oryginalne misje, walka, geodezja, ustawienia, źródłowe siatki, 270249 orientacji trójkątów, wejścia 4:3 i 16:9, źródłowa receptura lawy, podgląd efektów.
- Xcode: źródła iPhoneOS ARM64, Metal fragment/compute, pełne IPA bez podpisu — [sprawdź aktualny workflow](https://github.com/synixad-png/asteroidy-ios/actions/runs/42377930287).
- Raport użytkownika TXT zawiera rozwinięty opis zakresu i pozostałych niewiadomych. Harmonogram 18 zadań niezmieniony: 38% zrobione, 62% pozostało, zadanie 14: 26%.

### Kryterium rozwiązania problemu
Porównać minimalny FPS podczas tego samego przeładowanego starcia. Jeżeli GPU ms przekracza ~16,7 ms przy 60 Hz, problem leży w wydajności GPU; jeżeli przekracza CPU work albo WAIT, zbadać CPU/sterownik, w tym instancing. Bez tych wyników nie wprowadzać kolejnych dowolnych ograniczeń rozdzielczości ani pomijać mechanik fizycznych.
