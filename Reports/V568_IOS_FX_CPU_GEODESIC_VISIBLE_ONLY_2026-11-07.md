# ASTEROIDY iOS v568 — źródłowa optymalizacja CPU efektów 3D bez cięcia jakości

**Cel:** ograniczenie spadków około 60→35 FPS w intensywnej walce na iPhone/iPad Pro. To są **zmiany działającego kodu renderowania**, a nie proponowane ustawienia lub deklarowane FPS. Podstawą jest oryginalny `Sphere67`, `GpuSphere67`, `Explosion524` z Windows v568 i port ASTEROIDY Metal.

## Rzeczywiste niepotrzebne operacje wykryte w kodzie
1. `CarbonisExplosion524Meshes.sphereLine` dzieli źródłowy łuk na **6 części**. Każda z 6 iteracji wywoływała od nowa `Sphere67.offset`, geograficzne `canonical`, `coordinates`, `normal`, funkcje trygonometryczne. Jedno pierścieniowe światło wykonuje 32 odcinki × 6 powtórzeń. Maksymalnie 24 pierścienie = do **4608 kosztownych reprojekcji na klatkę**; do tego linie iskier i fragmentów.
2. Renderer generował pełną geometrię ringów, smug i szczątków również po całkowicie niewidocznej stronie planety i poza kadrem.
3. Host wolumetrycznego Explosion524 obliczał **17 pozycji gazowych kłębów** z sin/cos/exp nawet gdy shader zużywał tylko **13** (domyślny oryginał) lub **7** (iOS ekonomiczny). Następnie dodatkowo alokował `Array(prefix)`.
4. Poprzednia funkcja `SourceVisibleSurface73` sprawdzała pełne *zawieranie* rzutowanej sfery w polu widzenia zamiast jej *przecięcia* z frustum. Mogła niesłusznie ukrywać duży pierścień, którego środek był widoczny. Zastąpiono ją konserwatywnym testem granicznym sfery względem czterech płaszczyzn perspektywy.

## Rzeczywiste poprawki
- `CarbonisExplosion524Meshes.swift`: `SourceGeodesicStep568` generuje oryginalne 6 punktów łuku bez sześciu kolejnych odwrotnych projekcji na sferę, za pomocą jednej pary cos/sin przyrostu i rekurencji na jednostkowych wektorach 3D. **Nadal 32 krawędzie na pierścień, 6 podziałów na łuk, ta sama grubość, kolor, czas życia i fizyka.**
- `CarbonisExplosion524Meshes.swift`: tylko gdy realna gra przekaże proporcje kadru (`aspect`) pomijane są całkowicie niewidoczne renderowane cząstki, pierścienie i odłamki. Rozmiary obwiedni są konserwatywne (0,06 / 0,45 / większy z 0,30 i 4% rozmiaru odłamka w skali świata); testy bez `aspect` zachowują rysowanie wszystkiego.
- `CarbonisExplosion524Renderer.swift`: wolumen o realnym `extent` nie jest rysowany, jeśli całkowicie niewidoczny, z zapasem `1.6×extent+0.03`. W podglądzie ustawień nie culluje się nic (domyślny nil).
- `CarbonisExplosion524Renderer.swift`: CPU liczy tylko źródłowy prefiks kłębów potrzebny aktualnemu presetowi; nie zmieniono ani jednego pola, kształtu czy równania w shaderze Metal `Sector01Explosion524.metal`.
- `SourceVisibleSurface73.swift`: poprawione bezpieczne przecięcie sfery z frustum; zachowane source occlusion `innerTerrainRadius=0.80` i original C279.
- `SourcePerformance568.swift` i `Sector01CarbonisPreview568.swift`: do **istniejącego licznika FPS w GRAFIKA** dołożono trzecią linię `FX CPU P ... / W ... ms`: CPU przygotowania geometrii pocisków/świateł (P) i wybuchów/odłamków (W). Oryginalny FPS, **rzeczywiste GPU ms** (albo n/d), CPU całkowite, SYM i WAIT pozostają i są rozdzielone; bez nowych przełączników lub zmian w ustawieniach WYBUCHY/POCISKI.

## Testy weryfikujące oryginał, nie deklarujące rezultatów na urządzeniu
- W `SourceGeodesicFX568Tests.swift`: **2400** niezależnych losowych łuków, **6** punktów każdy = **14 400 porównań** z oryginalnym `Sphere67.delta + Sphere67.offset`; maksymalna odchyłka z testu Linux: **0,000001476** jednostki przy limicie 0,00005.
- Jedyny faktyczny benchmark przenośny: **72 000 punktów** oryginalnym algorytmem w **30,7 ms** oraz nowym w **3,9 ms** na **runnerze Linux GitHub Actions** (około **7,9× szybsza sama matematyka łuków**). To nie jest renderowanie GPU, miernik urządzenia ani wynik FPS w ASTEROIDY. Czas ma wartość porównawczą dla tego samego kodu na tym samym runnerze.
- Testy przygotowania geometrii: przed i po `aspect:16/9` identyczna 32×6 geometria pierścienia na ekranie; całkowicie zasłonięty pierścień z przeciwnej strony planety jest pomijany; brak mutacji `CarbonisDestruction524`.
- Kontrakt `Tests/FXCPUGeodesicSourceContract568.py` pilnuje kategorii ustawień, źródłowych podziałów, przejścia przez aktywny renderer, starego shadera i znaczników rzeczywistej telemetrii.
- `SourceVisibleSurface73Tests.swift` dodaje osobną kontrolę pierścienia `worldRadius=0.45` we frustach iPad 4:3, 16:9 iPhone oraz 19.5:9.
- Pełny stan CI należy potwierdzić w GitHub Actions po finalnym commicie. Sam benchmark i bezbłędna kompilacja nie oznaczają sprawdzonego wyglądu efektów na prawdziwym urządzeniu.

## Ograniczenia i co dalej
- Nie ma fizycznego testu iPhone/iPad ani porównania 35→60 FPS. Celem kolejnego testu jest odczyt *GPU ms / CPU ms / SYM / WAIT / FX CPU P / FX CPU W* na tym samym starciu przed i po nowym IPA.
- Nie zmieniać kolizji, 120Hz fizyki, obrażeń, licznika życia, dropów, ilości pocisków, jakości graficznej wybranej przez użytkownika, źródłowego CARBONIS C279, odległych planet ani wraku ResearchWreck214.
- Zachować stały harmonogram portu 18 zadań: **38% wykonane, 62% pozostało** bez sztucznego podwyższania.

