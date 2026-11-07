# ASTEROIDY iOS v568 — optymalizacja **samych strzałów**, bez zmian efektów i obrażeń
**Data:** 07.11.2026. **Zakres:** iPhone Pro i iPad Pro, natywna ścieżka Sector 01 CARBONIS na wspólnym silniku Swift/Metal. **Źródło reguł gry:** rzeczywisty port oryginalnych procedur Windows v568 `Combat69`, `Physics68`, `ShotAppearance151`, `GpuSphere67.PlanetLightLayer170`.

## Potwierdzona przyczyna potencjalnego obciążenia CPU

`CarbonisCombat568.stepShots` dla KAŻDEGO aktywnego pocisku w każdym kroku symulacji 120 Hz wykonuje pętle po przeciwnikach i skałach. Pierwotny port obliczał `Sphere67.delta` (trigonometria i mapa logarytmiczna na kuli) przed sprawdzeniem, czy cel może znaleźć się na drodze tego pocisku. Wiele kosztownych przeliczeń dotyczyło odległych obiektów, które z całą pewnością nie mogły zostać trafione.

`CarbonisProjectileFX69.indexedVertices` w KAZDEJ klatce, niezależnie od wybuchów, wykonywał 12 drogich reprojekcji geograficznych dla 6 odcinków świetlnego śladu strzału, generował sześć oddzielnych wierzchołków dla dwóch trójkątów każdej smugi i ponownie obliczał te same sin/cos dla kolejnych 32/28/24-segmentowych obręczy. Niezależnie `indexedGroundLights` wyznaczał nową bazę sferyczną i sin/cos dla wszystkich 4 oryginalnych warstw (lub 1 warstwy budżetowej) każdego pocisku. Ten koszt istnieje również przy całkowitym braku wybuchów.

## Zmiany izolowane w odpowiedzialnych plikach

1. `ASTEROIDYiOS/CarbonisCombat568.swift` — nowy niewielki `ShotSweepGate568` bezpośrednio przy źródłowych testach trafień. Najpierw testuje zmianę szerokości geograficznej i maksymalną możliwą odległość po cięciwie na jednostkowej kuli. Może pomijać tylko obiekty **na pewno nieosiągalne** podczas aktualnego kroku. Warunek zawiera konserwatywny margines 0,25 jednostki źródłowej dla błędów zmiennoprzecinkowych. `Sphere67.delta`, `CombatCollision556.segmentHit`, `projectedHit71`, oryginalne obrażenia, pancerz, odrzut, szybkostrzelność, śmierć i fizyka pozostały nienaruszone. Ten sam filtr działa dla pocisków wroga i gracza, nie zmieniając decyzji o trafieniu.
2. `ASTEROIDYiOS/CarbonisProjectileFX69.swift` — zoptymalizowana **prawdziwa** ścieżka renderowania `indexedRibbon`: wciąż **sześć** odcinków i wszystkie oryginalne trzy przenikające się smugi `27/165/240` alfa, ale cztery współdzielone narożniki na prostokąt zamiast 6 zduplikowanych, i pojedyncza rekurencja sferyczna zamiast odtwarzania współrzędnych geograficznych wielokrotnie na klatkę. Zachowane `ribbon` z poprzedniej implementacji jest niezależną bazą weryfikacji geometrii — nie jest wywoływane w produkcyjnym renderowaniu.
3. W tym samym, właściwym module `CarbonisProjectileFX69.swift` — niezmienne wzorce sin/cos obliczane jednokrotnie dla dokładnie istniejących rozdzielczości kół `12,18,22,24,28,32`. `OrbFrame` (kamera i oś billboardu) wyznaczana raz na pocisk, wspólna dla oryginalnych 32/28/24 radialnych rdzeni. `GroundFrame` (normalna powierzchni i baza sferyczna) wyznaczana raz na pocisk zamiast powtarzania dla 4 warstw oryginalnego oświetlenia. Zachowane długości/radiusy, kolory i wszystkie widoczne trójkąty.
4. Aktualny `ASTEROIDYiOS/Sector01CarbonisPreview568.swift` nie wymaga zmian. Jego już działające pomiary `FPS / GPU ms / CPU ms / FX CPU P / FX CPU W` pozostają, co pozwala rozdzielić prawdziwy koszt pocisków od wybuchów. Zachowane iPad 4:3, iPhone 15 Pro Max 19.5:9, dotyk lewej i prawej części, strzał przez przytrzymanie prawej, Intro41 i W3.

**Nie dodano** żadnych ustawień ani nowych kategorii, nie ingerowano w 43 zasoby audio, shadery wybuchów, planetę, wrak czy inne sektory.

## Weryfikacja jakości i uczciwy zakres
- `Tests/SourceShotSweepGate568Tests.swift`: **45 000 losowych kandydatów** (w tym prawdziwe możliwe trafienia), **2 000 przypadków biegunów i przejścia przez szew kuli**. Jeśli stary kod trafia, nowy filtr MUST dopuszczać oryginalny test — inaczej test zatrzymuje wydanie. Dodatkowo porównanie kosztu CPU dla **10 752 identycznych kandydatów** starego i nowego kodu na runnerze Linux Swift, z wymaganą równością liczby trafień; nie jest to benchmark GPU ani FPS urządzenia.
- `Tests/CarbonisProjectileFX69Tests.swift`: oryginalna rozwinięta lista trójkątów, RGB, alfa, wszystkie warstwy świetlne, 0–400% jasności, wszystkie efekty pocisków i światła. Każdy wierzchołek z indeksów musi zgadzać się ze źródłową listą trójkątów w tolerancji `0,000002`. Brak uproszczeń lub nowych sztucznych wizualizacji.
- `Tests/SourceShotCollisionAndDrawing568Contract.py` i aktualny `Tests/CarbonisFXSourcePerformanceContract568.py`: kontrakty dotyczą odpowiedzialnych modułów, źródłowej balistyki i bieżącego strumieniowania GPU, włącznie z oryginalnymi parametrami.
- Zostają pełne testy CARBONIS 01, historii 26 sektorów, kolizji, odgłosów, zmian profilu, GPU i macierz regresji gry.

**Wyniki poszczególnych GitHub Actions podać dopiero po faktycznym zakończeniu.** Kompilacja źródeł Swift/Metal na macOS i pełny build urządzeniowy IPA to dwa oddzielne wymagania; bez rzeczywistego testu iPhone/iPad nie ma dowodu, że FPS przy samych strzałach wzrosło z np. 35 do 60.

## Co dalej
1. Przejść testy zgodności źródeł + raport różnicy CPU w identycznym środowisku.
2. Skopiować wyłącznie te konkretne, sprawdzone pliki do `main` bez regresji optymalizacji Explosion524.
3. Skompilować niepodpisane IPA dla urządzeń iPhone+iPad ARM64 i zweryfikować identyczność źródeł.
4. Na fizycznym urządzeniu sprawdzić *tylko strzelanie*, przy tych samych warunkach: `GPU ms`, `CPU SYM`, `FX CPU P`, FPS bez wybuchów i po rozpoczęciu ognia. W razie dominacji GPU dalszym kierunkiem będzie render instancjonowany `ProjectileLight285`, nie ślepe cięcie efektów lub jakości.

Status całego portu: **18 niezmiennych zadań, 38% wykonane / 62% pozostało**.
