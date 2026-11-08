# ASTEROIDY iOS — H04: Dist2, BodyClear i cztery sfery (PC v580)
Data: 2026-11-08. Etap w niezmiennym harmonogramie H01–H16.

## Podstawa źródłowa, bez zgadywania
**Wyłącznie oryginalny `Windows/src/HubWalk375.cs` z ASTEROIDY PC v580**, klasa `H55FullCollision379`: `Dist2`, `BodyClear`, `Penetration382`, `ContactNormal401`, `CameraClear406`. H02: `HangarCollision441.FromGlb`, H03: `Support` i indeks 2m. Zatwierdzony GLB 126 419 336 B, SHA256 `00e6ba4ab2cce025b1290265052c1e252e149209f6fcbbc50b5d569af4592461`.

## Rzeczywista implementacja
- `ASTEROIDYiOS/H55TriangleBody580.swift`: rozszerzenie źródłowego `H55SpatialSupport580`; bez nowej geometrii, bez powtórnego indeksowania i bez podmiany raycastu SceneKit.
- `distanceSquared379`: wszystkie regiony Ericsona (A/B/C, AB/AC/BC, wnętrze płaszczyzny) i próg degeneracji dokładnie jak w C#.
- `bodyClear379`: kontrola oryginalnych granic H72, zadokowanego statku i dynamicznie wyłączonych prefabów H02 oraz czterech sfer postaci: promień **0,325 m**, środki na `feet+0.335, +0.780, +1.225, +1.670 m`. Testy wymagają dodatniej energii zderzenia w oryginalnym progowaniu `d² < r² - 0.001`. Niskie listwy i śruby pod podłogą do istniejącego pułapu **0,5 m** nie stają się pełnymi ścianami.
- `penetration382`: łączna energia nakładania sfer i trójkątów; bez zastępczej fizyki, oryginalny hard-stop dla statku/mapy.
- `contactNormal401`: oryginalny gradient energii z krokiem 0,032 m, próg i kierunek normalnej kontaktu bez wymyślania fizyki.
- `cameraClear406`: niezależna kula małej kamery i dokładne odległości do trójkątów/prefabów.
- H03 otrzymał tylko udostępnienie istniejących `cells` i `proxyCells` modułowi H04; same dane i wzory H03 niezmienione.

## Ważna zgodność źródła
Oryginalna funkcja C# `Dist2` przy trójkątnym regionie BC używa `bp + w*(C-B)` — inaczej niż klasyczny wariant tej formuły. Odrębny przypadek testowy wykazał wynik **8,5** dla trójkąta (0,0,0)/(2,0,0)/(0,2,0) i punktu (1.5,1.5,0). Port zachowuje wynik **8,5** dokładnie zgodnie z PC v580, zamiast bez zgody „poprawiać” zachowanie oryginału. Nie oznacza to, że ten zapis jest matematycznie idealny — jest to zweryfikowane źródło gry.

## Testy
- `Tests/H55TriangleBody580Tests.swift`: odległości w regionach trójkąta, ściana o dwóch trójkątach, cztery rzeczywiste sfery, pudło prefabu, statek, granice, energia penetracji, gradient kontaktu, kamera i odrzucanie wadliwej kolizji.
- Lokalna kompilacja Swift oraz testy jednostkowe **PASS**; dedykowany GitHub workflow H04 **PASS**, kompilacja iOS source-only **PASS**, code quality **PASS**.
- **Test porównawczy na prawdziwym GLB**: załadowano istniejące H02 **803 538** trójkątów statycznych i **233** bryły prefabów; uruchomiono **805** zestawów `BodyClear379`, `Penetration382`, `CameraClear406` na rzeczywistej geometrii. Niezależna implementacja wzorów PC C# w Python/NumPy z wykorzystaniem tych samych surowych wierzchołków zweryfikowała **805/805** bez rozbieżności logicznych; maks. bezwzględna różnica energii **0,00007622**. Kontrola **74** wektorów `ContactNormal401` wykazała 0 błędów, maks. różnica składowej **0,00000216**. Kontrole są reprezentatywne, nie pełnym brute force wszystkich możliwych pozycji świata.
- Test na fizycznym iPhonie/iPadzie **nieprzeprowadzony**. Długa regresja całej gry ma osobny status GitHub CI.

## Zależności / kolejny etap
H04 kończy **implementację i możliwe testy źródłowe** oryginalnego `Dist2/BodyClear`; nie jest jeszcze podłączony do fizyki gracza w realnym podglądzie. Zamierzony stan chroni przed przedwczesnymi zmianami H06. Następnie **H05** użyje tej konkretnej geometrii, podpór, czterech sfer oraz procedur `HubWalkPlaceAtEntry380`, `HubWalkSpawnClear380` i `BeginHubScene397`, aby umożliwić rzeczywiste, bezkolizyjne wejście bez zgadywania.
Nie wydano nowego IPA — nie zmieniłoby ono jeszcze zachowania wejścia do hangaru.
