# ASTEROIDY iOS v568 — grupowanie renderowania asteroid Metal (07.11.2026)

## Źródłowa rozbieżność
Windows v568 ma osobny mechanizm `GpuRockInstancing75`, natomiast aktywne iOS `Sector01CarbonisPreview568.swift` wykonywało osobny `drawPrimitives` na każdą widoczną asteroidę. Jest to wykazany narzut API CPU/Metal, ale jego udział w spadkach z 60 do 35 FPS na urządzeniu użytkownika NIE został zmierzony.

## Implementacja
- `Sector01Carbonis568.metal`: osobny vertex+fragment instanced, korzystający z tej samej 12-floatowej siatki i oryginalnych obliczeń toon/rim; każda asteroida ma własną macierz MVP/model.
- `Sector01CarbonisPreview568.swift`: zachowany źródłowy VisibleSurface73, procedury obrotu skał i cache geometrii po shape; widoczne skały grupowane po shape, jedno `drawPrimitives(instanceCount:)` na grupę zamiast jednego na obiekt.
- `CarbonisFXStreamingBuffers568.swift`: nowa rola `rockInstances` we współdzielonej trójklatkowej puli Metal, z zabezpieczeniem przed nadpisaniem danych używanych przez GPU. Brak alokacji per-frame po ustabilizowaniu pojemności.
- Zawsze zachowano wcześniejszy shader i osobne rysowanie jako awaryjny fallback przy braku bufora instancji.
- Nie zmieniano źródłowej liczby asteroid, obrażeń, symulacji Physics68, efektów wybuchów, ustawień W3, planet ani harmonogramu 18 zadań.

## Kontrola
Kontrakt `Tests/CarbonisFXSourcePerformanceContract568.py` sprawdza powiązanie Metal/Swift, instancing, fallback i matematyczną identyczność całego bloku obliczeń toon fragmentu. Natywne kompilacje iOS/Metal w Actions oraz testy fizycznego urządzenia należy raportować osobno; brak pomiaru FPS oznacza brak potwierdzenia wzrostu.
