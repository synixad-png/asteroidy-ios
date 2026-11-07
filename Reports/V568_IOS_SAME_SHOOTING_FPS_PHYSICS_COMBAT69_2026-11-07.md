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

## Wykonane i potwierdzone testy porównawcze
- [GitHub Actions #405](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404255441): **3/3 PASS** — kontrolna kompilacja Swift/Metal na macOS, testy całej fizyki i misji oraz oryginalne pociski.
- Spośród 45 000 losowych sprawdzeń **30 763 (68,36%)** kandydatów okazało się niemożliwych do trafienia i zostało odfiltrowanych. **Wszystkie 13 063** oryginalnie wykryte trafienia przeszły nowy filtr. Dodatkowo potwierdzono **2 000** przypadków przejść przez bieguny i szew geograficzny.
- Pomiar tego samego kodu CPU na GitHub Linux Swift dla **10 752** identycznych kandydatów: **6,94 ms** dotychczasowego sprawdzania → **1,89 ms** po zastosowaniu konserwatywnego filtra, **3,67× szybciej w tym konkretnym fragmencie**. Liczba faktycznych trafień identyczna (30). Jedynie **48** kandydatów dotarło do kosztownego wąskiego testu. Nie jest to pomiar całej gry ani GPU urządzenia.
- Rozwinięte listy trójkątów oryginalnych smug, wszystkich 3 rdzeni i 4 pełnych warstw oświetlenia zostały porównane z legacy `CarbonisProjectileFX69.vertices/groundLights`: **27 sprawdzeń PASS**, tolerancja każdego elementu `<0.000002`. Źródłowo indeksowana geometria redukuje przesyłanie danych względem nieindeksowanej listy o **51,47% dla pocisków** i **55,43% dla świateł** w tym zestawie. Jest to łączna oszczędność obecnego indeksowanego toru względem legacy, a nie przyrost wyłącznie niniejszego commita.
- Najnowszy wariant dodatkowo pomija krótkotrwałe tablice Swift przy zapisie współrzędnych/indeksów; test tej końcowej zmiany i kompilacja urządzeniowego IPA są rozdzielone od #405 i muszą mieć własny wynik przed zamknięciem wydania.

**Kompilacja źródeł Swift/Metal i pełny build urządzeniowy IPA to oddzielne wymagania; bez rzeczywistego testu iPhone/iPad nie ma dowodu, że FPS przy samych strzałach wzrosło z np. 35 do 60.**

## Wydanie kompletne — finalne GitHub Actions
- [**IPA #136 — build iPhone/iPad ARM64**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404992031): **4/4 PASS**, w tym testy źródłowe sektora CARBONIS, kompilacja Apple Metal oraz `xcodebuild Release -sdk iphoneos` z wynikiem **BUILD SUCCEEDED**.
- Zweryfikowany SHA źródłowego commita będącego podstawą IPA: `7f60e9515e34a014cca8b3fb2ea82912395b30a9`.
- [**Artefakt IPA #136**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404992031/artifacts/13587322531) — `ASTEROIDY-iOS-device-unsigned-ipa`. GitHub dostarcza ZIP **27 997 100 bajtów** zawierający `ASTEROIDY_iOS_UNSIGNED.ipa`; SHA-256 **ZEWNĘTRZNEGO ZIP GitHub**, nie IPA: `1818b54123e78c7388bd21fb292da6a1cbba81d71387330ceae8358bdbb6e7d9`.
- Oryginalny `unzip -t` IPA: **PASS (CRC)**, `Tools/verify_ipa.py`: **PASS** — `Payload`, `Info.plist`, fizyczne ARM64, minimalny iOS 17.0, `UIDeviceFamily` iPhone/iPad, zasoby. Potwierdzone 43 źródłowe nagrania SFX/głosów, generowane w runtime 15 utworów, bez dodatkowych zapisanych plików muzycznych.
- [CI źródeł #407](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404635881): 3/3 PASS po ostatnich zmianach optymalizacyjnych; [#408](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404991956) natywna kontrolna kompilacja i testy walki PASS, ale pomocnicze publikowanie statusu testu na GitHub FAIL. To nie był błąd kodu strzałów; osobny pełny build #136 jest PASS.
- **Żadnego interaktywnego testu na fizycznym iPhonie 15 Pro Max ani iPadzie Pro nie wykonano.** Nie potwierdzono spadku liczby milisekund GPU ani FPS na urządzeniu; nie wolno deklarować osiągnięcia stałych 60 FPS.

## Co dalej
1. Przejść testy zgodności źródeł + raport różnicy CPU w identycznym środowisku.
2. Skopiować wyłącznie te konkretne, sprawdzone pliki do `main` bez regresji optymalizacji Explosion524.
3. Skompilować niepodpisane IPA dla urządzeń iPhone+iPad ARM64 i zweryfikować identyczność źródeł.
4. Na fizycznym urządzeniu sprawdzić *tylko strzelanie*, przy tych samych warunkach: `GPU ms`, `CPU SYM`, `FX CPU P`, FPS bez wybuchów i po rozpoczęciu ognia. W razie dominacji GPU dalszym kierunkiem będzie render instancjonowany `ProjectileLight285`, nie ślepe cięcie efektów lub jakości.

Status całego portu: **18 niezmiennych zadań, 38% wykonane / 62% pozostało**.
