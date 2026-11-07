# ASTEROIDY iOS v568 — realne zmniejszenie kosztów pocisków i wybuchów GPU
**Data:** 07.11.2026  
**Rzeczywisty build:** [GitHub Actions 42369280396](https://github.com/synixad-png/asteroidy-ios/actions/runs/42369280396) — **4/4 SUCCESS**.  
**Commit kompilowany:** `48f0360d451d4312e080006bdaed9be0f1ff74d6`.

## A. Wąskie gardła stwierdzone w kodzie (nie zmyślony profil urządzenia)

1. `Sector01CarbonisPreview568.swift` wcześniej co klatkę tworzył **trzy niezależne nowe MTLBuffer** (`gpu.makeBuffer(bytes:...)`) dla geometrii świateł, projektyli i odłamków. To oznaczało cykliczną alokację urządzeniową/sterownika i transfer dużych tablic przez kopie buforów. Miarą jest liczba alokacji i bajtów; nie znam rzeczywistego udziału w czasie klatki na urządzeniu użytkownika.
2. `CarbonisProjectileFX69.swift`: źródłowe trzy pierścienie pocisku i cztery radialne światła odtwarzały wiele razy pełne 12-floatowe wierzchołki sąsiednich trójkątów. Każdy pocisk ma 108 wierzchołków w trzech 6-segmentowych wstęgach oraz 504 w pierścieniach (612 bez indeksów). Każdy komplet czterech świateł zawiera 276 wierzchołków bez indeksów.
3. `Sector01Explosion524.metal`: pełny kamerowy kwadrat 3D uruchamiał fragment shader również w obszarze, w którym próbki 3D mają zawsze zerową alfa. Ścisły warunek źródłowego `smoothstep(0.70, 0.98)` pozwala wyciąć ten obszar **bez usuwania widzialnej części wybuchu**.

## B. Zaimplementowane optymalizacje — nie obniżki jakości

| Zmiana w działającym rendererze | Przed | Teraz | Weryfikacja |
|---|---|---|---|
| Geometria świecących pocisków | Wierzchołki każdego trójkąta osobno | `CarbonisIndexedFXMesh568`, shared vertex + index buffer | **45,59% mniej bajtów transferu**, rozwinięte trójkąty zgodne |
| 4 warstwy świateł na planecie | Powtarzane trójkąty promienistych wachlarzy | Indeksowane sektory z tą samą pozycją/kolorem | **55,43% mniej bajtów**, zgodność 0% i 400% |
| 3 dynamiczne zestawy geometrii | Nowy `MTLBuffer` w każdym frame dla świateł/pocisków/odłamków | Współdzielone `CarbonisFXStreamingBuffers568`, 3 klatki in-flight, semafor `addCompletedHandler`, alokacja tylko przy zwiększeniu pojemności | Ograniczona liczba alokacji, brak nadpisywania zasobów będących w użyciu GPU |
| Obszar wybuchu V8.2 | 2 trójkąty pokrywające kwadrat UV | 24-kątny wachlarz opisany na całym widocznym dysku efektu | **24,13% mniejszy obszar rasteryzacji** pojedynczego efektu, 250 000 punktów PASS |

Zachowano wszystkie warstwy wstęg, segmentację geodezyjną, kolory wroga i gracza, źródłowe alfa i jasność, 4 osobne światła planety, 24-segmentowe muzzle flashes, poświatę, 3D fragmenty i odłamki. Sam Explosion524 zachowuje 13 płatów, 22 próbki dla jakości GAMEPLAY (inne tryby nadal 32/48), szum 64³, daty zdarzeń, parametry i oryginalne równania koloru/światła. Nie wprowadzono samodzielnego limitu pocisków, zmiany obrażeń ani ograniczenia liczby wybuchów.

## C. Kontrola jakości i regresji

- `Tests/CarbonisProjectileFX69Tests.swift`: nowa siatka indeksowana rozwinięta do kolejnych trójkątów. Liczby liczb Float identyczne jak w starym rendererze, maksymalna różnica `< 0.000002`, wszystkie warstwy zachowane, wariant jasności 0 i 400%. W CI: **FX optimized: 45.59% projectile / 55.43% ground-light upload bytes saved**.
- `Tests/Explosion524ConservativePolygonTests.py`: **250 000** losowych punktów w dysku o oryginalnie niezerowej przezroczystości; wszystkie w nowym wielokącie. Matematycznie wykazano, że poza nowym dyskiem flash ma alfa poniżej oryginalnego progu odcięcia 0,012. Redukcja powierzchni **24,13%**.
- `Tests/CarbonisFXSourcePerformanceContract568.py`: obecność natywnego indeksowanego rysowania, trzech buforów klatkowych z ochroną przed nadpisaniem i nienaruszonych 13 płatów/22 kroków.
- Kompletna regresja gry w workflow (statek, kolizje, obrażenia, CARBONIS, zapis, W3, muzyka), cztery zakończone jobs **SUCCESS**; natywny shader i cały iPhoneOS ARM64 **skomplikowane prawidłowo**.
- Brak testu optycznego i wydajnościowego na fizycznym iPhonie/iPadzie. Wynik 35→60 FPS nie został potwierdzony. `SourcePerformance568` pozwala zweryfikować realny FPS podczas tej samej intensywnej walki; na urządzeniu wynik zależy także od rozdzielczości, modelu GPU, temperatury i obciążenia sceny.

## D. Prawdziwy IPA
- GitHub Actions run: https://github.com/synixad-png/asteroidy-ios/actions/runs/42369280396
- Artifact: https://github.com/synixad-png/asteroidy-ios/actions/runs/42369280396/artifacts/13573353077
- IPA: `ASTEROIDY_iOS_UNSIGNED.ipa`, **28 411 169** bajtów.
- SHA-256: `13438f6f2797623d2efe476b4abd0871b3976a12d2633d7340d08cd270036bf6`, dokładnie jak `reports/SHA256SUMS.txt`.
- CRC ZIP i IPA: **PASS**. `Info.plist`: iOS **17.0**, `UIDeviceFamily [1,2]`, `CFBundleIdentifier=com.synixad.asteroidyios`; Mach-O **ARM64**. **IPA niepodpisane**.
- Źródła iOS: repo `synixad-png/asteroidy-ios`; żadne repo gry Windows/SteamOS ani inne app nie zostały zmienione.

## E. Co pozostało / kolejny warunek zamknięcia
Porównać identyczną scenę z dużą liczbą pocisków i równoległych eksplozji na tym samym iPadzie (stara i nowa kompilacja, włączony prawdziwy licznik FPS, najlepiej kilka kolejnych przebiegów przy podobnej temperaturze urządzenia). Jeżeli nadal wystąpi 35 FPS, następnym etapem jest fizyczny profil GPU z identyfikacją rzeczywistego kosztu fragmentów raymarch, świateł i CPU, a nie arbitralna redukcja jakości.

Harmonogram 18 zadań nie został naruszony: **38% całości / 62% pozostało**, zadanie 14 **26% (0 pp)**. Optymalizacja nienowego zakresu nie została policzona jako kolejna przeniesiona funkcja.
