## ETAP — 07.11.2026: preloading geometrii asteroid bez chwilowego generowania podczas trafień

**Wdrożono po audycie źródeł i testach:** inicjalizator renderera misji CARBONIS przygotowuje wszystkie **80** osiągalnych oryginalnych wariantów StoneSubdivide56/RockVertices75 (8 ziaren × 5 poziomów × 2 stany fragmentacji) przed pierwszą klatką misji; podczas podziału i trafienia nie powinien już tworzyć brakujących oryginalnych `MTLBuffer`. Menu W3 zachowuje lżejsze przygotowanie początkowych skał, bez zmiany wzorów geometrii i fizyki. Pełne źródłowe testy obu uruchomień PR **2/2 PASS**, w tym wszystkie 80 wariantów i natywny Swift/Metal. [PR #2](https://github.com/synixad-png/asteroidy-ios/pull/2) scalono jako `a92df9ee`. [Raport techniczny](Reports/V568_IOS_ROCK_GEOMETRY_COLD_START_PRELOAD_2026-11-07.md).

**Weryfikacja wydania:** [IPA #138](https://github.com/synixad-png/asteroidy-ios/actions/runs/42411007709) **4/4 PASS** (Xcode Release iOS ARM64, Apple Metal, CRC ZIP, `Tools/verify_ipa.py`), [pobierz artefakt IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42411007709/artifacts/13588989521), 28 000 414 B, zewnętrzny ZIP SHA256 `ee836f220eac307b8518c43b28513279c063e6c25932ddc6a77b2fe60ae1ade5`; [testy główne #413](https://github.com/synixad-png/asteroidy-ios/actions/runs/42411007705) **3/3 PASS** po ponowieniu pomocniczego kroku raportującego, który wcześniej miał konflikt GitHub 409. Nadal nie zmierzono faktycznego FPS ani dodatkowego czasu inicjalizacji na fizycznym iPadzie/iPhonie. Nie deklarować usunięcia przycinki bez testu. Poprawka audio z IPA #137 zachowana.

**Stałe 18 zadań portu: 38% wykonane / 62% pozostało.**

## ETAP — 07.11.2026: rozruch audio powodujący możliwe spadki FPS przy trafieniach

**Nowa obserwacja użytkownika:** przy uruchomieniu iPada z ekranu głównego przez pierwsze 2–3 minuty trafienia obniżają FPS, a później przy identycznym strzelaniu i trafieniach stabilne 60 FPS. To wskazuje na konkurencyjne **prace w tle podczas zimnego startu**, nie udowadnia winy GPU ani wybuchów. Źródła potwierdziły, że po 2 utworach menu gra generuje w tle 13 oryginalnych utworów muzycznych 128 taktów × 44,1 kHz, obejmujących długie FFT/mastering/WAV. Dotąd przygotowanie korzystało z `qos:.userInitiated`, a blokada podczas misji sprawdzana była za rzadko.

**Naprawa ograniczona do źródłowych modułów audio** `OriginalAudioAV568.swift` i `OriginalMusicSynth568.swift`: dwa oryginalne utwory menu zachowują szybkie przygotowanie `.userInitiated`, a pozostałe 13 pracuje w osobnej kolejce `.utility`. Dodano krótkie, bezpieczne checkpointy w syntezie/FFT/miksowaniu/masteringu i zapisie WAV, wykorzystujące istniejący `musicGate` podczas gry. **Nie zmieniono ani jednej formuły audio, próbek PCM, szybkostrzelności, wybuchów, kolizji, efektów, GPU ani konfiguracji iPada/iPhone'a.**

**Dowody i zakres:** test porównuje WAV wygenerowany z checkpointem i bez niego **bajtowo**, zachowując 15 utworów, 128 taktów i 44,1 kHz. [Kontrola kodu audio na GitHub Actions #409](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408520112): **3/3 PASS** — natywna kompilacja iOS Swift/Metal, pełne testy rozgrywki oraz **67 checkpointów z WAV bajtowo identycznym** względem poprzedniego generatora. [Raport techniczny](Reports/V568_IOS_AUDIO_STARTUP_COMBAT_STUTTER_2026-11-07.md). Pełne testy iOS: [**#410**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945112) **3/3 PASS**; urządzeniowe [**IPA #137**](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945096) **4/4 PASS** (Apple Metal, Xcode `BUILD SUCCEEDED`, ARM64, CRC `Tools/verify_ipa.py`). [Pobierz niepodpisane IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42408945096/artifacts/13589017064), 27 999 687 B, SHA-256 zewnętrznego ZIP `0aa13e012d438b7a4109915b9a43831eb6578989f6a3e09f532099b669a05c42`. **Pozostał fizyczny pomiar pierwszych 2–3 minut** na iPadzie/iPhonie. Alternatywna hipoteza: pierwsze użycie kolejnych wariantów asteroid tworzy dodatkowe bufory `MTLBuffer` na klatce — nie zmieniano tego mechanizmu w wydaniu audio. Nie deklarować potwierdzonego zniknięcia spadków FPS bez testu na urządzeniu.

**Harmonogram portu nadal ma dokładnie 18 zadań: 38% wykonane, 62% pozostało.**

## ETAP — 07.11.2026: konkretna optymalizacja SAMEGO STRZELANIA dla iPhone i iPad

**Potwierdzony koszt źródłowy:** każdy aktywny pocisk w 120 Hz symulacji sprawdzał wszystkie skały/przeciwników, nawet geograficznie nieosiągalnych podczas danej klatki, z kosztownym `Sphere67.delta`. Niezależnie renderer wielokrotnie liczył sin/cos i pełne współrzędne geodezyjne dla pierścieni, smug i oświetlenia każdego strzału. Oba koszty istnieją nawet wtedy, gdy nie ma wybuchów.

**Zmiany wyłącznie we właściwych plikach:** `CarbonisCombat568.swift`: konserwatywny `ShotSweepGate568` odrzuca tylko pewne pudła, pozostawiając nietknięte oryginalne swept hit, obrażenia, cooldown, fizykę i zasięg. `CarbonisProjectileFX69.swift`: indeksowane bez duplikacji narożników trzy 6-segmentowe źródłowe smugi, preobliczone 12/18/22/24/28/32 sin/cos, jedna podstawa sferyczna na pocisk i jedna orientacja jego trzech pierścieni, bez małych alokacji Swift na każdy wierzchołek/indeks. **Żadnych zmian w Explosion524, w opcjach grafiki, jakości 3D, misjach, sterowaniu, HUD, iPad 4:3 i iPhone 15 Pro Max 19,5:9.**

**Potwierdzony wynik źródłowych testów:** [CI #405](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404255441) **3/3 PASS**, z 45 000 kandydatów 30 763 (**68,4%**) wyeliminowano przed drogim testem bez utraty żadnego z **13 063** trafień; dodatkowo 2000 przypadków biegunów/szwu kuli. Dla 10 752 identycznych kandydatów pomiar **CPU na Linux Swift**: **6,94 → 1,89 ms (3,67× szybszy sam test kolizji)**. Test oryginalnych kolorów, 3 warstw smug i 4 warstw światła **PASS**, bez zmiany wartości trójkątów ponad `0.000002`. Dodatkowe wyeliminowanie małych alokacji zaliczyło [CI #407](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404635881) **3/3 PASS**. Właściwe [IPA #136](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404992031) — **4/4 PASS** (`xcodebuild Release/ARM64 BUILD SUCCEEDED`, Apple Metal, oryginalne audio, CRC ZIP IPA i `Tools/verify_ipa.py` PASS). [Pobierz niepodpisane IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42404992031/artifacts/13587322531); kompilacja z commita `7f60e9515e34a014cca8b3fb2ea82912395b30a9`, archiwum ZIP 27 997 100 B, SHA-256 `1818b54123e78c7388bd21fb292da6a1cbba81d71387330ceae8358bdbb6e7d9`. **Fizyczny pomiar FPS przy ciągłym strzelaniu na iPhonie i iPadzie nadal nie został wykonany.** Raport: [V568_IOS_SAME_SHOOTING_FPS_PHYSICS_COMBAT69_2026-11-07.md](Reports/V568_IOS_SAME_SHOOTING_FPS_PHYSICS_COMBAT69_2026-11-07.md).

**Stały harmonogram całego portu:** 18 niezmiennych zadań; **38% wykonane / 62% pozostało**.

## ETAP — 07.11.2026: źródłowy W3 na iPhone 15 Pro Max 19,5:9 + iPad 4:3

**Implementacja wykonana:** iPhone 15 Pro Max poziomo `932×430` pt (`2796×1290` px) ma własną rzeczywiście dostępną szerokość po odjęciu `UIWindow.safeAreaInsets`. Wspólna polityka `W3AdaptiveViewport568` chroni oryginalne pełnoekranowe 4:3 paski iPada, a nowy natywny `W3SafeAreaReader568` dostarcza rzeczywiste marginesy Dynamic Island/home indicator bez arbitralnych offsetów. `W3StartupSplash568` (napis ENTER, logo, górny/dolny pasek), `W3MainMenu568` (7 akcji, menu, ustawienia, bez zbyt wczesnej trzeciej kolumny, przewijalna **NOWA GRA**) i `MissionCinematic568` (prawdziwy przelot 3D i widoczny przycisk POMIŃ) korzystają z tego samego mechanizmu. Nie zmieniono kamery misji, wielkości planety, źródłowych tekstur, fizyki, auto-ognia ani optymalizacji Explosion524.

**Testy:** [iPhone/iPad CI #399](https://github.com/synixad-png/asteroidy-ios/actions/runs/42401141387) **3/3 PASS**, w tym natywna kompilacja Swift/Metal. Matematyczne testy chronią `932×430` z asymetrycznymi insetami, iPad `1024×768` z paskami 74/68, oryginalne FOV dla pełnego Metal 19,5:9 oraz dojście do opcji i potwierdzenia w NOWEJ GRZE. Pełna kompilacja urządzeniowa [IPA #135](https://github.com/synixad-png/asteroidy-ios/actions/runs/42401807414) zakończona sukcesem **4/4 PASS**, w tym Xcode ARM64, Apple Metal, pakowanie i publikacja [niepodpisanego IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42401807414/artifacts/13586042433) z dokładnie przetestowanego commita `08a8b95007ae`. Test rzeczywistego dotyku na iPhone 15 Pro Max pozostaje **niepotwierdzony**: symulator [#78](https://github.com/synixad-png/asteroidy-ios/actions/runs/42401807308) nie zwrócił listy urządzeń w 60 s, a [#65](https://github.com/synixad-png/asteroidy-ios/actions/runs/42401807332) nie osiągnął znacznika W3 po 242 s przygotowania ekranu/muzyki. Błędu nie należy deklarować jako usuniętego ani jako jednoznacznie środowiskowego. Raport: [V568_IOS_IPHONE_15_PRO_MAX_W3_19_5_9_2026-11-07.md](Reports/V568_IOS_IPHONE_15_PRO_MAX_W3_19_5_9_2026-11-07.md).

**Całość projektu bez sztucznego wzrostu zakresu:** 18 niezmiennych zadań; **38% wykonane / 62% pozostało**.

## ETAP — 07.11.2026: GPU wybuchów Explosion524, wyłącznie we własnym module

**Wykonano:** bez jakichkolwiek zmian w `App.swift`, fizyce, ustawieniach, pociskach, wraku czy planetach zredukowano koszt rysowania oryginalnych Explosion524. Dokładnie dwa pliki gry: `CarbonisExplosion524Renderer.swift` (jedna niezmienna siatka wachlarza 24-gon w stałym `MTLBuffer`; raz obliczane odwrotności promieni kłębów) i `Sector01Explosion524.metal` (bez przebudowy CPU geometrii i wielokrotnego dzielenia GPU; niezmienione noise/alpha/kolory i liczba próbek). Stały wachlarz ma 576 B zamiast 1440 B dynamicznej kopii na wybuch/klatkę. Teoretyczny maksymalny zysk na środku pojedynczego piksela przy 13 kłębach × 22 próbkach: 572 dzielenia GPU zastąpione mnożeniami; wynik rzeczywisty zależy od kompilatora, złożoności fragmentów i urządzenia.

**Testy:** [GitHub Actions #397](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395393809) **3/3 PASS**: źródłowa kontrola geometrii i 70 000 porównań `float32` (`max error = 0,000000221`), 250 000 punktów zakresu wybuchu, pełna regresja rozgrywki i natywna kompilacja kodu Swift/Metal w Xcode. Techniczny raport: [V568_IOS_EXPLOSION524_STATIC_GPU_LUT_2026-11-07.md](Reports/V568_IOS_EXPLOSION524_STATIC_GPU_LUT_2026-11-07.md). **Urządzeniowy build IPA zakończony:** [Xcode #134](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864027) — **4/4 PASS**, [pobierz IPA](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864027/artifacts/13583633282) (niepodpisane; ARM64, iOS 17+, CRC i assety PASS). [Testy głównej gałęzi #398](https://github.com/synixad-png/asteroidy-ios/actions/runs/42395864016) **3/3 PASS**. **Do zrobienia:** rzeczywisty pomiar GPU ms / FX CPU W i wizualny test na iPhonie i iPadzie. Brak zmierzonego wzrostu FPS, nie wolno deklarować „naprawiono 35 FPS”. **Harmonogram 18 zadań nadal: 38% ukończone / 62% pozostało.**

## ETAP — 07.11.2026: optymalizacja CPU wybuchów/pocisków, test oryginalnych łuków

**Wdrożone w prawdziwej misji CARBONIS 01 (kod Swift/Metal, a nie tylko propozycja):** `SourceGeodesicStep568` rysuje dokładnie oryginalne sześć podziałów każdej krawędzi 32-odcinkowych świetlnych pierścieni, ale bez sześciokrotnego przeliczania geograficznych współrzędnych. Kosmetyczne pierścienie, smugi, odłamki i wolumetryczne wybuchy pomija się wyłącznie wtedy, gdy są całkowicie niewidoczne w źródłowej kamerze; przy okazji poprawiono zbyt agresywny test `SourceVisibleSurface73`. CPU oblicza teraz tylko faktycznie potrzebne kłęby Explosion524, z zachowaniem oryginalnych shaderów i wyglądu. `GRAFIKA → LICZNIK WYDAJNOŚCI` pokazuje oprócz prawdziwego GPU ms dwa nowe realne czasy CPU przygotowania `FX P/W` bez tworzenia kolejnych suwaków. Kolizje, 120 Hz, ilość strzałów, hitboxy, pełna jakość wybuchów i podziały siatek niezmienione.

**Zweryfikowane:** [GitHub testy tylko bojowe #391](https://github.com/synixad-png/asteroidy-ios/actions/runs/42392206376): **3/3 PASS**, wraz z natywną kompilacją źródła Swift/Metal w Xcode. 14 400 punktów oryginalnych łuków o maksymalnym błędzie **0,000001476** jednostki; porównanie CPU 72 000 punktów na Linux runnerze: **30,7 ms przed → 3,9 ms po**. To **nie jest pomiar FPS na urządzeniu** ani gwarancja, że znikną spadki z 60 do 35 FPS. Raport: [V568_IOS_FX_CPU_GEODESIC_VISIBLE_ONLY_2026-11-07.md](Reports/V568_IOS_FX_CPU_GEODESIC_VISIBLE_ONLY_2026-11-07.md). **Następne:** natywny ARM64 unsigned IPA, bezpośrednie porównanie GPU/CPU/FX FPS na fizycznym iPhonie/iPadzie, dopiero potem dalsza optymalizacja ciężkich shaderów. Nie zmieniono harmonogramu **18 zadań: 38% wykonane / 62% pozostało**.

## ETAP — 07.11.2026: oryginalna przestrzeń kosmiczna we właściwej misji CARBONIS

**Wdrożono w rendererze rzeczywistej misji**, a nie w ekranie W3: dokładną kolejność z Windows `GpuSphere67.SphereScene67` — `IntroSky` (24 dalekie mgławice, 3 odległe planety, czarna dziura, 12 bliskich mgławic, 1500 gwiazd i 5 promieni), prawdziwą C279, `DrawCombatResearchWreck214` w kierunku pierścieniowego gazowego olbrzyma, a dopiero potem aktywną walkę. Wrak ma źródłową geometrię `DrawDetailedResearchWreck211` (112 szczątków, 7 lamp, panele, anteny i rysy) oraz jego oryginalny obrót i odległość. Nie dodano wymyślonej trasy ani nie zmieniono skali planety, fizyki czy hitboxów. Dotychczasowy przezroczysty podgląd planety w menu pozostał nietknięty.

**Raport z oryginalnymi referencjami:** [V568_IOS_KOSMOS_W_MISJI_ORIGINAL_GPU_SPHERE_2026-11-07.md](Reports/V568_IOS_KOSMOS_W_MISJI_ORIGINAL_GPU_SPHERE_2026-11-07.md). **Testy:** oryginalny porządek renderowania PASS, geometria badawczego wraku PASS (28 920 wierzchołków trójkątów / 5 364 wierzchołki linii), iOS natywna kontrolna kompilacja Swift/Metal PASS. Wynik pełnego niepodpisanego IPA i rzeczywisty wygląd na iPhonie/iPadzie muszą być weryfikowane osobno: [GitHub Actions #132](https://github.com/synixad-png/asteroidy-ios/actions/runs/42389087599). Ukończenie 25 dalszych scen misji NIE jest deklarowane. **Harmonogram 18 zadań bez sztucznego podwyższenia:** 38% wykonane, 62% pozostało.

## ETAP — 07.11.2026: autentyczny Intro41 przed CARBONIS 01 (misja i retry)

**Wykonano:** natywne 16-sekundowe `Intro41` przed wejściem do grywalnej CARBONIS 01 z W3 NOWA GRA i z atlasu, a także przed powtórzeniem nieudanej misji. Oryginalna kamera/820 asteroid/Vanguard431/plazma491/atmosfera47 z `GpuIntro41.cs`, poziom 1 ma teraz **rzeczywistą planetę C279 z źródłowych assetów**, a nie stary GLB Boreas poziomu 5. Ekran przelotu W3 v319, prawdziwy plik `Intro43.m4a` i obsługa dotyku/Enter/Space/pada A/Start. Fizyczna pętla walki nie działa podczas przelotu; zachowano ekran wyników, zapis oraz mechanizm niewypłacania ponownych nagród.

**Źródła i raport:** [oryginalny kod oraz ograniczenia](Reports/V568_IOS_INTRO41_PRZELOT_PRZED_KAZDA_MISJA_2026-11-07.md), realny commit portu [ca4014ea](https://github.com/synixad-png/asteroidy-ios/commit/ca4014ea9067ecc87c5e3c8200f71097a0facecb). Kontrakt `Tests/MissionIntro41SourceContract568.py` zabezpiecza połączenie. Dotychczasowe regresje Boreas oraz sterowania touch uzupełniono tak, by nie blokowały legalnej osobnej ścieżki CARBONIS. **Natywne Apple ARM64 i IPA oceniać tylko na podstawie najnowszego GitHub Actions**; test fizycznego iPhona/iPada, porównanie obrazu i 25 dalszych misji nieukończone.

**Nie zmieniono ustalonej listy 18 zadań i procentów:** 38% całego portu zrobione / 62% pozostało. Zadanie 14 MENU W3/ustawienia nadal 26%; nowa sekwencja jest szczegółowym podzakresem oryginalnej integracji scen.

## ETAP — 07.11.2026: source instancing asteroid Metal (FPS CARBONIS)

**Wykonano w aktualnym kodzie iOS:** usunięto odrębne wywołanie renderowania dla każdej widocznej asteroidy w CARBONIS na rzecz jednego `drawPrimitives(instanceCount:)` na grupę źródłowych siatek o tym samym shape, zgodnie z podejściem oryginalnego `GpuRockInstancing75`. Zachowano indywidualne macierze MVP/model, oryginalne kolory, pasma toon/rim, obrót, siatki 960-wierzchołkowe i SourceVisibleSurface73. Bufory instancji chroni 3-klatkowa pula Metal; przy niepowodzeniu alokacji zachowana jest pierwotna ścieżka rysowania. Kod gry, fizyka, wybuchy i suwaki W3 nietknięte.

**Dowód:** [commit instancing 58c23989](https://github.com/synixad-png/asteroidy-ios/commit/58c239890500bdc824196f8294abf1f97c059190), [raport techniczny](Reports/V568_IOS_GPU_ROCK_INSTANCING_2026-11-07.md). Źródłowa regresja Swift/Linux i kontrolna natywna kompilacja iOS/Metal **PASS**. Uruchomiony pełny workflow IPA: [GitHub Actions #124](https://github.com/synixad-png/asteroidy-ios/actions/runs/42379339918). W osobnym workflow testów naprawiono brakujące moduły `CarbonisIOSFXBudget568` oraz `CarbonisIndexedFXMesh568` w samodzielnym `swiftc`, bez zmiany gameplayu.

**Niepotwierdzone:** realny zysk FPS ani spadki 60→35 FPS na fizycznym iPhone/iPad; wyniku nie wolno zgadywać. **Harmonogram bez sztucznego wzrostu:** 18 zadań, 38% wykonane i 62% pozostało, zadanie 14 nadal 26%, do domknięcia zadania 18 konieczne pomiary na urządzeniu.

## ETAP — 07.11.2026: audyt FPS całej aktywnej ścieżki CARBONIS, realne poprawki i porządek ustawień

**Wydanie po audycie:** [GitHub Actions 42377930287](https://github.com/synixad-png/asteroidy-ios/actions/runs/42377930287) 4/4 SUCCESS, IPA ARM64 iPhone/iPad 28 423 961 B, SHA-256 `2115c831f0deac1b545b915b18abdadc554b0f1b93d3461a6cd4deff5fdc024f`, [artefakt 13576548730](https://github.com/synixad-png/asteroidy-ios/actions/runs/42377930287/artifacts/13576548730). Niezależne porównanie źródłowe Windows BGRA / Metal RGB — 10 000 próbek, maksymalna różnica 0 bajtów, [Linux SUCCESS 42378649398](https://github.com/synixad-png/asteroidy-ios/actions/runs/42378649398). Brak pomiaru FPS na fizycznym iOS, nie deklarować 60 FPS.

**Użytkownik potwierdził brak mierzalnej poprawy po dwóch wcześniejszych optymalizacjach.** Audyt porównał realny kod uruchamianej misji w `Sector01CarbonisPreview568.swift` z oryginalnym `Windows/src/GpuPlanet.cs` oraz `GpuSphere67.cs`; przyczyna dokładnych spadków do 35 FPS nie jest jeszcze rozpoznana na fizycznym urządzeniu, więc nie wolno deklarować stabilnych 60 FPS.

**Wykonano:** (1) buforowany raz i na zmianę jasności *CarbonisCombined469* — połączenie trzech oryginalnych map CARBONIS (RGB 4096×2048 + RGB 4096×2048 + irradiance 1024×512) w jedną teksturę Metal, zamiast trzech próbników i dodatkowych równań dla każdej klatki; (2) wyłączenie zbędnego blendingu nieprzezroczystej planety; (3) konserwatywne odrzucanie renderowania ukrytych asteroid i myśliwców bez ingerencji w fizykę; (4) rozdzielenie wcześniejszego błędnego przełącznika `GRAFIKA` między właściwe kategorie `WYBUCHY 3D` i `POCISKI`, osobne zapisy i migracja wyboru; (5) przywrócenie realnego wpływu oryginalnych suwaków na tryb oszczędny, spójny podgląd Metal oraz aktualizacja ustawień w misji co 0,25 s; (6) uczciwa diagnostyka GPU ms albo `n/d`, CPU ms, symulacja ms i czekanie na drawable. **WAŻNA KOREKTA:** Windows `GpuPlanet.cs:251` wyłącza GL_CULL_FACE, natomiast iOS stosuje osobne optymalizacyjne culling; to nie jest źródłowo identyczny stan i wymaga testu wizualnego. Całe oryginalne C279 ma 270249 trójkątów z orientacją na zewnątrz i 137067 nieprzezroczystych wierzchołków.

**Otwarta rozbieżność:** Windows stosuje instancing asteroid od odpowiedniego progu, a aktywny renderer iOS nadal wykonuje osobne wywołania draw dla poszczególnych widocznych skał. Nie wdrażano hipotetycznego rozwiązania bez pomiaru czasu CPU. Pełne 26-sektorowe wydanie iOS nadal nie istnieje; audyt obejmuje aktualnie działającą misję CARBONIS. [Raport techniczny](Reports/V568_IOS_AUDYT_FPS_CALA_SCIEZKA_CARBONIS_2026-11-07.md).

**Harmonogram pozostaje bez zawyżania procentów:** 18 zadań, **38%** zrealizowane / **62%** pozostało; zadanie 14 nadal **26% (0 pp)**. Weryfikacja z urządzenia iPhone/iPad i dokładne 35→60 FPS: **niepotwierdzone**.

---

## ETAP — 07.11.2026: rzeczywiste ograniczenie efektów iOS (odpowiedź na spadki 60→35 FPS)

**Zlecenie:** poprzednia optymalizacja siatek i GPU nie podniosła FPS na urządzeniu użytkownika; tym razem **celowo zmniejszono wizualny koszt** w realnym rendererze CARBONIS, bez dotykania liczby pocisków, zasięgu, fizyki, zadawania obrażeń i warunków ukończenia misji.

**Domyślny tryb oszczędny iOS (także dla istniejących instalacji):** jedna wolumetryczna eksplozja zamiast trzech; 10 próbek głębokości zamiast 22, 7 kłębów gazu zamiast 13, maksymalna widoczność eksplozji 1,9 s zamiast 4,2 s; jedna 12-segmentowa warstwa światła pocisku zamiast czterech (28+24+22+18 segmentów); usunięta tylko zewnętrzna aureola pocisku (nadal rysowany rdzeń i smuga); render maksymalnie 96 cząstek z 512, 48 części z 160, 12 dekoracyjnych odłamków na wybuch zamiast 35. Koszt liczenia wolumetrycznego w wariancie trzech nakładających się eksplozji spada teoretycznie z 858 do 70 pętli próbka×kłąb (**około 91,8% mniej**), **nie jest to zmierzony wzrost FPS**.

**Przywracanie jakości:** dodatkowy, prawdziwy przełącznik `USTAWIENIA → GRAFIKA → TRYB WYDAJNOŚCI iOS — MNIEJ EFEKTÓW`, zapisuje stan `UserDefaults`, domyślnie WŁĄCZONY. Wyłączenie przywraca pełną oryginalną liczbę warstw, próbek i efektów. Przełącznik jest iOS-only, nie udaje źródłowej opcji Windows; działa od kolejnego wejścia do misji. Oryginalne ustawienia Explosion524/ProjectileLight285 wciąż są przechowywane bez zmian.

**Weryfikacja:** [GitHub Actions 42371950545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42371950545) **4/4 SUCCESS**, w tym testy oryginalnej gry, nowe budżety GPU, porównanie pełnego trybu i kompilacja Xcode 16.4 iPhone/iPad ARM64. **IPA:** 28 415 845 B, SHA-256 `3c7975f9224144105bbc66be45fea85855ab85d2af1d511b6a7fabbde4b19711`, [artefakt 13574511452](https://github.com/synixad-png/asteroidy-ios/actions/runs/42371950545/artifacts/13574511452), commit kodu wydania `62a508593c7d3b4a6f2599baea1e53c75dc83327`. ZIP CRC PASS, IPA CRC PASS, ARM64, iOS 17+, rodziny urządzeń [1,2], niepodpisany. Brak testu fizycznego na iPadzie/iPhonie i porównania realnych 35→60 FPS; tego nie wolno dopisywać jako sukces.

**Nie zmieniać harmonogramu:** 18 zadań, **38%** portu / **62%** pozostało; zadanie 14 **26% (0 pp)**, ponieważ to cięcie istniejących efektów, nie nowa funkcja portu. [Raport techniczny](Reports/V568_IOS_LEKKIE_EFEKTY_FPS_2026-11-07.md).

---

## ETAP — 07.11.2026: rzeczywista optymalizacja GPU pocisków, świateł i wybuchów CARBONIS

**Wdrożono rzeczywiste zmiany renderera iOS v568 (bez obniżania jakości):** indeksowanie źródłowych sześcioczęściowych, trójwarstwowych smug i trzech pierścieni pocisków oraz wszystkich czterech warstw kolorowego oświetlenia powierzchni planety. Geometryczne porównanie każdej składowej Float 12 × vertex z oryginalnym wyjściem testowym: PASS, maksymalny błąd pod progiem 0,000002. Redukcja **rozmiaru geometrii przesyłanej do Metal: 45,59% pociski, 55,43% światło gruntowe**, przy zachowaniu identycznej liczby trójkątów, kolorów, alfa i hitboxów. Bufory dynamiczne pocisków, indeksów, światła i odłamków wykorzystują odtąd współdzielone trzy zestawy MTLBuffer i bezpieczne semafory zakończenia GPU; wyeliminowano tworzenie tych buforów co klatkę poza zmianami rozmiaru. Wybuch Explosion524 V8.2 otrzymał geometryczną osłonę 24-kątną zamiast pełnego kwadratu i ograniczenie pikseli o zerowym wkładzie — **24,13% mniejsza powierzchnia rasteryzacji** dużego wybuchu, zachowano wszystkie 13 płatów, 22 źródłowe próbki raymarch i recepturę 64³ szumu.

**Testy matematyczne / źródłowe:** [GitHub Actions 42369280396](https://github.com/synixad-png/asteroidy-ios/actions/runs/42369280396) **4/4 SUCCESS** (źródła, fizyka, Xcode 16.4, natywne ARM64). CI potwierdził 250 000 losowych punktów widocznego obszaru wybuchów, ścisłą tolerancję geometrii pocisków, ustawienia 0/400% oświetlenia, oryginalne efekty i pozostałą regresję świata. **Nie potwierdzono wzrostu całkowitego FPS z 35 do 60 na fizycznym urządzeniu**; redukcje oznaczają transfer bajtów i liczbę rasteryzowanych pikseli, a nie gwarantowaną poprawę klatkażu.

**IPA:** rzeczywiste niepodpisane `ASTEROIDY_iOS_UNSIGNED.ipa` **28 411 169 bajtów**, SHA-256 `13438f6f2797623d2efe476b4abd0871b3976a12d2633d7340d08cd270036bf6`, artefakt GitHub [13573353077](https://github.com/synixad-png/asteroidy-ios/actions/runs/42369280396/artifacts/13573353077), commit `48f0360d451d4312e080006bdaed9be0f1ff74d6`. CRC ZIP/IPA PASS, `com.synixad.asteroidyios`, Mach-O ARM64, iOS 17+, iPhone iPad `UIDeviceFamily [1,2]`. W3 i licznik FPS oraz generator muzyki nienaruszone. [Raport szczegółowy](Reports/V568_IOS_FX_GPU_POCISKI_WYBUCHY_OPTYMALIZACJA_2026-11-07.md).

**Stałe wskaźniki harmonogramu:** nadal 18 zadań, 38% przeniesione / 62% pozostaje, zadanie 14: 26% (**0 pp**). To optymalizacja istniejącej funkcji, nie kolejny przeniesiony ekran lub misja.

---

## ETAP — 07.11.2026: W3 iPad 4:3 oraz oryginalny licznik wydajności FPS

**Wykonano i wydano IPA:** w natywnym iOS poprawiono układ ekranu Enter/Start i MENU W3 pod rzeczywistą szerokość/wysokość ekranów 4:3 i 16:9. Zamiast skalować całą planszę 1280×720 na środku 4:3, nowy `W3AdaptiveViewport568` przypina górny pasek (oryginał 74 px na wysokim ekranie, 52 px na kompaktowym) do **y=0** i stopkę (68 / 37 px) do **rzeczywistego dołu**. Środek z oryginalnym logo i napisem `NACIŚNIJ ENTER / START` przelicza się niezależnie; usunięto źródło obniżonych pasów i pustych marginesów. W3 HOME również używa pełnego widoku, wysokości stopki zgodnej z oryginalnym W3 oraz prawidłowej zasłony. Zachowano wcześniej poprawioną przezroczystą planetę NewHome290.

**Licznik FPS z oryginału:** na podstawie `Windows/src/Menu139.cs` opcja ID **6** `Licznik wydajności`, `Controls.cs` akcja 32, `GpuRenderer.cs:EndFrame` (uśrednianie co **0,5 s**), `Renderer.cs:200` (nie pokazuj na menu), dodano działającą opcję `USTAWIENIA > GRAFIKA > LICZNIK WYDAJNOŚCI (POMIAR FPS)`. Domyślnie **wyłączona**, zapisuje się trwale w UserDefaults. Odczyt pochodzi wyłącznie z faktycznie **zakończonych buforów poleceń GPU Metal**, nie z deklarowanego 60/120 Hz. Wyświetla FPS i czas klatki podczas rozgrywki CARBONIS 01 i sceny diagnostycznej, bez dotykania fizyki, obsługi dotyku czy generowania muzyki; nie pokazuje się na ekranach W3 i startowym. Skrót fizycznej klawiatury **R** z Windows nie został osobno odwzorowany; iOS obsługuje przełącznik dotykowy.

**Realne wydanie:** [GitHub Actions 42366042540](https://github.com/synixad-png/asteroidy-ios/actions/runs/42366042540), wszystkie cztery jobs **SUCCESS**, commit `37bfaa58737401b0f21d6edf288b1a0145166269`. Artefakt [13571697864](https://github.com/synixad-png/asteroidy-ios/actions/runs/42366042540/artifacts/13571697864), rzeczywisty `ASTEROIDY_iOS_UNSIGNED.ipa` **28 405 298 B**; SHA-256 `2237a68516ea458bf63dda230be7c6d116717542df11c3efc8979d6e357bec33`. CRC ZIP + IPA PASS; SHA zgodna z raportem kompilacji; Mach-O ARM64, `UIDeviceFamily=[1,2]`, iOS 17+.

**Testy i granice potwierdzenia:** `Tests/W3AdaptiveViewport568Tests.swift`, `Tests/SourceFPSAccumulator568Tests.swift`, kontrakty źródłowe W3/Metal i pełna regresja Linux PASS. Kompilacja iOS/Metal PASS. Test z autentycznym obrazem ekranu iPada po zakończonym generowaniu muzyki oraz odczyt rzeczywistych FPS na fizycznym urządzeniu **nie zostały jeszcze potwierdzone**; nie deklarować wizualnej zgodności 1:1 ani urządzeniowego testu. IPA jest niepodpisane.

**Harmonogram:** nadal 18 ustalonych zadań, **38% całego portu / 62% pozostaje**. Zadanie **14 MENU W3, HUD i ustawienia: 26% (+1 pp)** za rzeczywistą opcję FPS, bez zawyżania wyniku za niepotwierdzoną fizycznie poprawkę układu. Wszystkie pozostałe zadania bez zmian. [Raport szczegółowy](Reports/V568_IOS_W3_IPAD_4X3_REAL_FPS_2026-11-07.md).

---

## ETAP — 07.11.2026: usunięcie nieoryginalnego radaru wokół planety w W3 GPU

**Oryginał zweryfikowany:** `Windows/src/RendererW3Home328.cs:255-256` wywołuje `c.Gpu.HomePlanetPreview333(435,176,455,455,...)` dla `IsGpu=true`; pomocniczy `DrawHomePlanetBackdrop333` (cztery obręcze, krzyż, elipsa) występuje **wyłącznie** w ścieżce zastępczej 2D `DrawHomePlanet333`. `Windows/src/GpuW3HomeReal333.cs:HomePlanetPreview333` stosuje `clear(0x0100)`, czyli czyści bufor głębokości, **bez zamalowania barwnego tła**. Sprawdzono identyczność oryginalnych plików ze źródłami v568: SHA-256 `839f1bd3ac42632d72208671ae336859144e0ef0564365dedb241d68e3d5a065` i `a696603703583df5e4363106389833d6fd9aaa59fd6b73fa5e1aec3f71f4a966`.

**Poprawiono:** na natywnym iOS `W3MainMenu568.swift` usunięto nieoryginalny przy planetarnym podglądzie prostokąt, obramowanie, pięć okręgów radaru, krzyż, złotą elipsę i debugowe podpisy; pozostawiono **wyłącznie** autentyczny obracający się model `NewHome290` 3D oraz dokładnie poprzednie przeciąganie palcem, bez sztucznego zamiennika 2D. `W3HomePlanetMetal568.swift` wymusza `isOpaque=false`, przezroczyste tło UIKit/CAMetalLayer i zerowanie osobnej warstwy Metal do alfa=0 każdą klatkę. Oryginalne tło całego menu W3 oraz panel nawigacyjny, planeta, logo i podgląd statku zachowano. SHA oryginalnych assetów/UV i geometria planety pozostają niezmienione.

**Kod:** [commit 90ebfa72](https://github.com/synixad-png/asteroidy-ios/commit/90ebfa72f93cdb33cf80305bc78f037d6267c7df). **Testy:** `Tests/V568W3PlanetTransparentSourceContract.py` jest częścią [workflow pełnego builda 42364176842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176842); niezależna kompilacja natywnego Swift/Metal w [workflow 42364176781](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176781) zakończyła się SUCCESS. Wynik prawdziwych zrzutów ekranu z iPhone/iPad należy oceniać osobno w [workflow 42364176785](https://github.com/synixad-png/asteroidy-ios/actions/runs/42364176785). Dotychczas nie potwierdzono fizycznego iPada. Nie oznaczano zrzutu obrazu jako zaliczonego, dopóki CI go nie udostępni.

**Harmonogram:** 18 zadań bez zmian, **38%** całego portu / **62%** pozostało; zadanie 14 **25%**, zmiana **0 pp** (naprawa regresji wyglądu, nie nowa funkcja). [Audyt źródłowy](Reports/V568_W3_HOME_PLANET_TRANSPARENT_SOURCE_AUDIT_2026-11-07.md).

---

## ETAP — 07.11.2026: oryginalny W3 splash po muzyce, Enter/Start przed menu

**Zrealizowano funkcję:** zgodnie z rzeczywistym źródłem `Windows/src/Program.cs:91-96,120-123,227,263`, `ProgramW3Native315.cs:SkipW3Startup327`, `UiW3NativeLayout315.cs:DrawW3Splash323, DrawW3ReferenceWipe327` po przygotowaniu oryginalnych efektów i dwóch utworów menu pokazuje się teraz pełnoekranowy ekran startowy z tym samym SHA-zweryfikowanym tłem i logo W3. Obowiązuje oryginalny tekst `NOWY SYSTEM NAWIGACJI`, `ORBITAL NAVIGATION SYSTEM`, `NACIŚNIJ ENTER / START`. **Nie ma automatycznego przejścia do menu**; Enter/spacja/dotknięcie lub przycisk A/Start pada rozpoczynają źródłową 1,25-sekundową zasłonę (0,45 s zasłaniania + 0,80 s odsłaniania), dopiero potem HOME W3 przyjmuje wejście. Ekran jest pokazywany raz przy starcie, a nie przy powrocie z misji. Istniejący kod generowania muzyki i sceny CARBONIS pozostaje niezmieniony.

**Realny pakiet IPA:** GitHub Actions [42362411634](https://github.com/synixad-png/asteroidy-ios/actions/runs/42362411634) **SUCCESS**, commit wydania `d53722495e184af13a552b1e1f6e700836a7bbfb`, artefakt [13570810784](https://github.com/synixad-png/asteroidy-ios/actions/runs/42362411634/artifacts/13570810784), `ASTEROIDY_iOS_UNSIGNED.ipa`: **28 379 641 B**, SHA-256 `f395f4e32fbe9709e7e8df3762853b04fbd85ded8c904bffa588a0bf9c3d5ea4`. Zbadano CRC ZIP, ARM64 Mach-O, Info.plist `UIDeviceFamily=[1,2]`, iOS17+ oraz porównano SHA z raportem Xcode. IPA jest **niepodpisane**.

**Testy:** `Tests/W3StartupPolicy568Tests.swift` i `Tests/W3StartupContract568.py` **PASS** w natywnym workflow z pełną regresją v568; Apple iPhone/iPad kompilacja **PASS**. Nowy rzeczywisty XCTest `W3StartupSplashUITests.swift` jest podłączony do workflow [42362578089](https://github.com/synixad-png/asteroidy-ios/actions/runs/42362578089) i bada zakaz przedwczesnego wejścia do HOME oraz dotknięcie ekranu po wygenerowaniu muzyki. **Wynik testów interakcyjnych na symulatorach wymaga odrębnego potwierdzenia**, nie zastępuje testu fizycznych urządzeń. Brak autentycznego zrzutu aplikacji; nie używać obrazów innych programów.

**Stały harmonogram:** 18 zadań bez zmian; całe przeniesienie **38% / 62% pozostało**, zadanie 14 `Menu W3, HUD i ustawienia` **25% (+1 pp)** za ukończoną implementację ekranu startowego, bez uznania 44 ekranów za gotowe. Pozostałe 17 wskaźników bez zmian. [Raport szczegółowy](Reports/V568_W3_STARTUP_ENTER_IPHONE_IPAD_2026-11-07.md).

---

## ETAP — 07.11.2026: poprawka kadrowania CARBONIS iPad 4:3 (bez zmiany geometrii)

**Poprawiono:** w natywnym `Sector01CarbonisPreview568.swift` projekcja gameplay `viewProjection` zachowuje źródłową poziomą szerokość kadru gry Windows v568 1280×720 przy ekranie iPada 4:3. Przy 4:3 pionowy współczynnik projekcji `2.0` → `1.5` (75%), a poziomy pozostaje `1.125`. iPhone o proporcjach co najmniej 16:9 zachowuje dotychczasowe parametry. **Nie przeskalowano planety, poświaty ani geometrii; cały gameplay i Atmosphere47 nadal używają wspólnej macierzy projekcji.** Zachowano v523 promień terenu i źródłowe materiały, UV, hitboxy, sterowanie oraz osobny podgląd atlasu. To dopasowanie viewportu iOS, nie modyfikacja zasad oryginalnej gry.

**Testy:** `MissionViewportFraming568Tests.swift` i `MissionViewportFraming568Contract.py` wraz z dotychczasowymi testami Linux PASS. Natywna kompilacja Xcode 16.4 iPhoneOS ARM64, iPhone/iPad (iOS 17+) **SUCCESS** w [GitHub Actions 42360663465](https://github.com/synixad-png/asteroidy-ios/actions/runs/42360663465). Artefakt [13569324989](https://github.com/synixad-png/asteroidy-ios/actions/runs/42360663465/artifacts/13569324989) zawiera niepodpisany IPA: 28 341 137 B, SHA-256 `1cffc3a63199e72bf75fe2edb3ad3d617cef967b40d6e65121ea7ef1b44450bd`; CRC, Info.plist, Mach-O PASS. Zmiana kodu [c3627bc](https://github.com/synixad-png/asteroidy-ios/commit/c3627bc03014677fb8e37ae259d758fe7bec4e42).

**Niepotwierdzone:** rzeczywisty obraz i test manualny na fizycznym iPadzie; IPA wymaga podpisania. Nie przedstawiać matematycznego testu dopasowania widoku jako zrzutu ekranowego urządzenia. **Harmonogram niezmieniony: 18 zadań, 38% portu / 62% pozostało; zadanie 14 24% (0 pp).** [Pełny raport techniczny](Reports/V568_IOS_CARBONIS_IPAD_4X3_VIEWPORT_2026-11-07.md).

---

## ETAP — 07.11.2026: NOWA GRA, źródłowa trudność i rzeczywisty IPA iPhone/iPad

**Ukończono kod i zbudowano zweryfikowany, niepodpisany IPA dla iPhone/iPad.** Wybór trudności wpływa na rzeczywistą CARBONIS 01, nowe dane profilu powstają dopiero po wymaganym backupie starego stanu, a 2P jest blokowany, nie symulowany. Niepełny pozostaje oryginalny 62-sekundowy prolog oraz 2-graczowa fizyka/sterowanie. Nowe źródła: [commit 7eb3b99c](https://github.com/synixad-png/asteroidy-ios/commit/7eb3b99cbe1384ec5d2b37ca4baf7ffe39082fcf). Kompilacja iOS: [GitHub Actions 42359364204](https://github.com/synixad-png/asteroidy-ios/actions/runs/42359364204) SUCCESS, [artefakt IPA 13568504263](https://github.com/synixad-png/asteroidy-ios/actions/runs/42359364204/artifacts/13568504263). Sam IPA ma 28 340 966 bajtów, CRC+SHA PASS, ARM64 iPhone/iPad. Brak testu fizycznego; iPhone simctl nie był dostępny na runnerze.

**Stałe wartości:** 38% portu / 62% pozostało, zadanie 14 nadal 24%. Lista 18 zadań pozostaje bez zmian.

---

## ETAP — 07.11.2026: usunięcie mieszanki starego menu i nowego W3

**Wykonano:** audyt oryginalnego `RendererW3Home328.cs`, `ProgramW3Native315.cs`, `UiW3NativeLayout315.cs`, `Menu139.cs` oraz 44 ekranów W3. Usunięto stare modalne przejścia kampanii, zastąpiono 6 poziomych zakładek listą 17 źródłowych kategorii (6 działających, 11 jeszcze nieprzeniesionych), rozdzielono NOWA GRA od KAMPANIA, schowano `SCENA TESTOWA` w tryb diagnostyczny, odwzorowano 1,25-sekundowe przejście zasłoną. Zachowano oryginalne 7 przycisków, tło/logo, NewHome290, Vanguard431 i wszystkie działające ustawienia. To **etap usuwania regresji**, a nie ogłoszenie ukończenia 44 ekranów.

**Audyt i szczegóły:** [Reports/V568_W3_MENU_MIXED_LEGACY_AUDIT_2026-11-07.md](Reports/V568_W3_MENU_MIXED_LEGACY_AUDIT_2026-11-07.md). Testy Swift/Xcode, źródłowe i simulator XCTest prowadzone przez GitHub Actions; brak testu fizycznego urządzenia. Nie generowano IPA przy samych poprawkach menu. Historyczne 18 etapów i 38%/62% bez sztucznego zwiększania postępu.

---

## WYDANIE IPA — 07.11.2026: optymalizacja Explosion524 + lawa v287

**Wersja:** zachowany numer bazowy v568, nowa rzeczywista kompilacja iPhone/iPad `7f82c7d2d95210f4a153694404bfb2f485c1edc6`. Zweryfikowany [GitHub Actions run 42355169830](https://github.com/synixad-png/asteroidy-ios/actions/runs/42355169830), trzy jobs **SUCCESS**, artefakt `13567093577` `ASTEROIDY-iOS-device-unsigned-ipa` dostępny w sekcji Artifacts (ZIP zawiera `ASTEROIDY_iOS_UNSIGNED.ipa`). Właściwy IPA: **28 275 180 bajtów / 28,28 MB**, SHA-256 `587e95a69df17d3f5d0c9337c1faa0cdc3244e8b932d22d91145a222661426fb`. Sprawdzono ZIP CRC, Mach-O ARM64, `UIDeviceFamily=[1,2]`, `com.synixad.asteroidyios`, zgodność z sumą SHA raportu, 0 nagrań `Music*.m4a`, oryginalna muzyka syntetyzowana podczas uruchomienia.

**Otrzymane zmiany:** PR #1 optymalizacji wybuchów **MERGED do main**, source 17-lobe CPU precomputation i pomijanie próbek o zerowej nieprzezroczystości; źródłowa regulacja natężenia emisji lawy v287 0–400% / 5% / default 180%, podłączona do jednoprzejściowej tekstury CARBONIS469 i poświaty NewHome293, zakładka PLANETY; wcześniej wdrożone poświata i atmosfera oraz skala statku zachowane. Świetliki na nocnej półkuli **celowo niewdrożone**. Dalszy audyt w [Reports/V568_IOS_PLANET_FX_LAVA_AUDIT_2026-11-07.md](Reports/V568_IOS_PLANET_FX_LAVA_AUDIT_2026-11-07.md).

**Ograniczenia:** Nie przeprowadzono porównawczego pomiaru FPS ani testu wyglądu na fizycznym iPhone/iPad, a opcje FERROFLUID (#85–87) oraz GLB PBR (#88–89) dotyczą nieprzeniesionych pełnych shaderów i scen, więc nie wstawiono nieaktywnych suwaków. IPA jest **niepodpisany**; instalacja wymaga podpisania. Nie podnoszono historycznego postępu 38% całego portu bez potwierdzenia brakujących scen.

---

## ETAP — 07.11.2026: zweryfikowana optymalizacja wybuchów i autentyczna emisja lawy

**Wykonano:** po [zielonym Metal/Xcode CI 42353888008](https://github.com/synixad-png/asteroidy-ios/actions/runs/42353888008) PR #1 optymalizacji Explosion524 włączono do main (bez usuwania efektów/odłamków). Na podstawie oryginalnego `Windows/src/GpuPlanet.cs:CarbonisCombined469`, `GpuNewHome290.cs`, `GpuToon60.cs` i `Menu139.cs #45` dodano regulowaną emisję lawy **0–400% krok 5, domyślnie 180%**, działającą na istniejącej źródłowej powierzchni CARBONIS C279 i poświacie NewHome290, bez nowych coplanarnych passów ani modyfikacji oryginalnych assetów. Nowy suwak jest w **USTAWIENIA > PLANETY** i zapisuje stan niezależnie od pozostałych opcji planet. Świetliki nie są wdrażane zgodnie z poleceniem użytkownika.

**Audyt wszystkich właściwych efektów i opcji:** [Reports/V568_IOS_PLANET_FX_LAVA_AUDIT_2026-11-07.md](Reports/V568_IOS_PLANET_FX_LAVA_AUDIT_2026-11-07.md). Wskazuje m.in. odrębne materiały FERROFLUID, GLB PBR, wodę proceduralną, animowaną pogodę, wulkany VULKARIS i biosferę; nie przypisuje ich sztucznie do CARBONIS. Nie wszystkie 26 planet są jeszcze grywalne. Stopień realizacji całego portu nie jest automatycznie zawyżany po tej poprawce.

---

## AKTUALNY ETAP — 07.11.2026: ustawienia oryginalnej wielkości statku v472 (STATEK)

**Wykonano:** odczytano rzeczywisty `Windows/src/Menu139.cs` (OptionGroups139 zakładka STATEK, identyfikatory **100/101**, `SettingsChoices325` 17 wartości **70–150% co 5%**, reset/domyślne **100%/100%**), `Windows/src/Renderer.cs` (`MissionShipScale472` i `OrbitShipScale472` w procentach, przenoszone do GPU jako `×0.01`), `GpuSphere67.cs:CraftSphere67` (skala **po** fizycznym StampSphere67, przed DrawFighterMesh oraz modułami), `Orbit50.cs:318` (oddzielne skalowanie statku w świecie orbitalnym). Dodano **STATEK** do istniejących ustawień W3 z oboma niezależnymi suwakami i zapisem UserDefaults w `SourceShipScale472.swift`, bez zastępczych wartości i bez ingerencji w model statku. W `Sector01CarbonisPreview568.swift` missionFactor obejmuje dokładnie ten sam `shipMatrix` użyty przez oryginalny model Vanguard431 **i pozycje / geometrię dysz 491**. W `MetalRenderer.swift` analogiczna skala po źródłowym sphereStamp obejmuje oba tryby modeli istniejącej diagnostycznej sceny sferycznej. **Skala jest wizualna:** bez zmian rozmiaru kolizji, hitboxów, prędkości, sterowania, obrażeń, AI, kształtu statków/tekstur i formatu scen.

**Ważna granica zgodności:** zapis suwaka `STATEK / SKALA W ŚWIECIE ORBITALNYM` działa, ale w obecnym porcie **nie ma jeszcze odpowiednika grywalnego źródłowego renderera `Orbit50`**. Dlatego wartości tego suwaka **nie przypisano fałszywie** do statku w menu W3 ani filmowego intro; ich zastosowanie w realnej orbicie wymaga portu tej sceny. Natomiast suwak `STATEK / SKALA W MISJACH` steruje rzeczywistym statkiem w misji CARBONIS 01.

**Testy:** [GitHub Actions 42353057454](https://github.com/synixad-png/asteroidy-ios/actions/runs/42353057454) **SUCCESS**: natywna kompilacja wszystkich źródeł Swift/Metal iPhoneOS ARM64 (bez IPA); testy Swift na granice 70/150, 5%, domyślne 100/100, dwa niezależne zapisy i odczyty, sprawdzenie ścieżki GPU modelu i dysz; pełna macierz testów źródłowej walki/fizyki **PASS**. Dodano rzeczywisty XCTest iPhone/iPad do zmian suwaków i ponownego uruchomienia aplikacji (run [42353126785](https://github.com/synixad-png/asteroidy-ios/actions/runs/42353126785)); wynik testu na symulatorze należy sprawdzić osobno. Nie testowano na fizycznym iPadzie. **Nie tworzono nowego IPA**; poprzedni IPA nie zawiera funkcji v472.

**Harmonogram:** bez zmiany listy 18 zadań ani historycznych procentów (cały port **38% / 62%**, zadanie 14 **24%**); nie podnosić postępu za nieprzeprowadzone interaktywne testy lub nieistniejącą grywalną scenę orbity. Kolejny zakres poza tą funkcją: niewdrożone oryginalne światła nocnej strony `GpuSphere67.cs:DrawPlanetFireflies438` oraz opcje #58–59, pełny port Orbital50.

---

## AKTUALNY ETAP — 07.11.2026: oryginalne efekty planety v568 w natywnym Metal iOS

**Wykonano w repo iOS:** zachowując rzeczywistą siatkę i trzy tekstury CARBONIS C279 oraz dotychczasową fizykę, do `Sector01CarbonisPreview568.swift` dodano źródłową kopułę atmosferyczną `GpuPlanet.cs:Atmosphere47` (24 pierścienie × 96 segmentów, test głębokości, blend SRC_ALPHA/ONE_MINUS_SRC_ALPHA), addytywny pierścień poświaty `GpuPlanetAnimation.cs:DrawPlanetGlow` w oryginalnym podglądzie planety (12 pierścieni × 96 segmentów, blend ONE/ONE) oraz terminator dzienno-nocny `GpuToon60.cs:202` w osobnym shaderze planety `Sector01Carbonis568.metal`. Atmosfera jest renderowana po planecie, poświata 2D przed planetą, zgodnie z porządkiem źródła; poświata 2D nie jest sztucznie wyświetlana nad polem walki. Tint CARBONIS jest oryginalny `#EC4E19`. Ustawienia `PLANETY` i `POSTPROCES` dodano do istniejącego `CarbonisVisualSettingsPanel568.swift`: `Glow — poświata` (Menu139 #2), `ŚWIATŁO PLANETY` (#55), `ŚWIATŁO PLANETY / PRĘDKOŚĆ` (#56, 0–400%, krok 5, domyślnie 100), `ŚWIATŁO PLANETY / JASNOŚĆ NOCY` (#57, 0–400%, krok 5, domyślnie 160). Opcje zapisują się w UserDefaults i trafiają do aktywnego renderera CARBONIS; nie ingerują w pociski, modele/statki, fizykę, pierwotne testy ani format źródeł.

**Testy:** lokalny Swift/Linux `SourcePlanetAtmosphere568Tests.swift` PASS (źródłowe rozmiary buforów, alpha krawędzi, kolory i geometria addytywna, zapis opcji, obliczanie położenia słońca). GitHub Actions [42352203527](https://github.com/synixad-png/asteroidy-ios/actions/runs/42352203527) **SUCCESS**: natywny build kompilacyjny Xcode/Metal dla iPhone/iPad (bez IPA) oraz pełne testy Linux/regresje gameplay PASS. Wcześniejsze błędy składni Swift z przejściowym commitu wykryto i poprawiono; zielony run jest podstawą weryfikacji. Nie wykonano interaktywnego testu na fizycznym iPadzie/iPhonie, nie potwierdzono wizualnej zgodności piksel w piksel ani pełnej zgodności oświetlenia PBR z Windows. Nie tworzono nowego IPA; ostatni podpisywalny instalator pochodzi sprzed tych efektów.

**Pozostałe efekty oryginału, których nie oznaczamy jako wdrożone:** `GpuSphere67.cs:DrawPlanetFireflies438` oraz ustawienia #58–59 (kolor i liczba świetlików nocnych), nieukończony pełny shader planetarny PBR/tekstur i pozostałe rodzaje planet. Zatwierdzona oryginalna warstwa `W3HomePlanet290` w menu głównym nie została zmieniona: source `GpuW3HomeReal333.cs` nie używa kopuły Atmosphere47 tego podglądu. Dalsze porównanie źródeł i test realnej sceny powinny poprzedzać rozszerzanie efektów.

---


## AKTUALNY ETAP — 07.11.2026: oryginalna synteza muzyki uruchamiana na iPhone/iPad

**Wykonano:** zamiast dołączać 15 AAC do IPA, przeniesiono oryginalny generator `Windows/src/MusicSynth.cs`, `SynthDsp.cs`, `SynthCoefficients.cs`, `SynthRandom.cs`, `MusicMaster.cs` na natywny Swift `ASTEROIDYiOS/OriginalMusicSynth568.swift` z oryginalną tablicą zig, filtrami SOS, aranżacjami 128 taktów, FFT 131072, masterem liniowym 44,1 kHz stereo. Synteza zachodzi **przy każdym uruchomieniu aplikacji**, nie podczas budowania; pierwsze dwa utwory przed menu, następne 13 w tle z pauzą podczas aktywnej walki. PCM trafia do prywatnego katalogu tymczasowego, czyszczonego przy kolejnym uruchomieniu; nagrania muzyczne AAC nie są częścią instalatora. Pozostają 34 SFX, 7 głosów PL, Intro43 i licencje (43 zasoby), dźwięk silnika, 2-sekundowy crossfade, STOP/REPLAY oraz podpięcie CARBONIS 01.

**Testy:** pełne utwory 0 Astral Gate oraz 14 Stellar Bloom wygenerowane natywnie; korelacje z poprzednim odniesieniem AAC odpowiednio **0,99968** i **0,99979** (różnice m.in. z kompresji AAC). Testy 5 różnych aranżacji i deterministycznego PCM PASS, Linux/testy fizyki PASS, macOS Xcode/Metal iPhoneOS ARM64 PASS, 43 zasoby w `.app` i **0 plików Music*.m4a** PASS, ZIP/CRC IPA PASS. Uruchomienie i odsłuch na fizycznym iOS **nieprzeprowadzone**. Uwaga: źródłowa synteza zapisuje czasowe nieskompresowane PCM, więc podczas działania gra może zająć znaczną ilość miejsca tymczasowego; to nie zwiększa rozmiaru IPA.

**Nowy IPA:** [GitHub Actions 42317382424](https://github.com/synixad-png/asteroidy-ios/actions/runs/42317382424) SUCCESS; artefakt 13551214705; **28 236 206 bajtów** (28,24 MB), SHA-256 `852dcf7de6b9d086200b11d88b5eb85edaa9ed7bd3174f30f44dec63cade28d9`, niepodpisany, iPhone i iPad. Poprzedni IPA 111 561 436 bajtów: oszczędność **83 325 230 bajtów (74,69%)**. GitHub commit implementacji `73dfc18d0ec64391d8f3babe4387f0056a8fdcd0`.

**Harmonogram niezmieniony:** 18 zadań; łączny postęp nadal **38%, pozostało 62%**; zadanie 15 nadal **60%** do czasu odsłuchu na fizycznym iOS, pełnej synchronizacji Intro43 i przeniesienia pozostałych wyzwalaczy 25 sektorów. Te liczby nie zostały podniesione samą kompilacją.

---

## ARCHIWUM — 06.11.2026: etap z nagraniami AAC przed korektą generatora

**Status:** oryginalna muzyka oraz efekty są już w kodzie i repozytorium iOS, nie jest to jednak potwierdzenie odsłuchu na fizycznym iPhonie/iPadzie. Odnaleziono pełną paczkę `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` w Bibliotece ChatGPT; wcześniejsze stwierdzenie o braku źródeł dotyczyło tylko czterech częściowych ZIP-ów GitHub i **jest nieaktualne**.

- **Źródła i nagrania:** [Github Actions 42298944326](https://github.com/synixad-png/asteroidy-ios/actions/runs/42298944326) — SUCCESS. `SourceExact568/` przechowuje oryginalne źródła C# generatora, a `ASTEROIDYiOS/Assets/Audio568/` zawiera 58 oryginalnych pozycji po konwersji audio na AAC (15 utworów Music0–14, 34 SFX, 7 polskich komunikatów, Intro43, licencje). Bez substytutów i bez nowych kompozycji.
- **Dwie fazy:** SFX i pierwsze utwory 0 „Astral Gate” / 1 „Orbital Pulse” przygotowywane przed otwarciem W3, reszta przygotowywana w tle; rzeczywista synteza oryginalnym C# wykonywana **przy budowaniu źródeł/zasobów**, a na iOS w tle odbywa się wstępne dekodowanie/wczytywanie tych samych utworów — nie należy tego błędnie nazywać runtime syntezą C# na iPhonie.
- **Odtwarzanie:** `OriginalAudioAV568` i `OriginalEngineDSP52` obsługują muzykę i 16 głośów SFX (w tym oryginalne czasy/przypisania dźwięków walki), dynamiczny dźwięk silnika, głośność muzyki 56% i SFX 100%, STOP/REPLAY w bibliotece 15 utworów, oryginalne 2-sekundowe equal-power przejścia, odłożony odsłuch jeszcze nieprzygotowanego utworu, przerwanie starszego komunikatu głosowego, zachowanie po zmianie sceny/tła.
- **CARBONIS 01:** realne wywołania SFX dla strzałów, wrogich salw, eksplozji asteroid i przeciwników, zbierania tokenów oraz oryginalny kod21 dla utraty życia/końca gry z testami osłony. `MusicMix.TrackFor`: zwycięstwo/porażka -> Music0, GameOver z tłumieniem .4, replay -> Music1, silnik 0 po zakończeniu.
- **Weryfikacja:** [Swift/Xcode 42302524489](https://github.com/synixad-png/asteroidy-ios/actions/runs/42302524489) PASS m.in. test equal-power 88200 ramek/44.1kHz; [Swift/Xcode 42302185649](https://github.com/synixad-png/asteroidy-ios/actions/runs/42302185649) PASS nowego SFX śmierci i regresji. Najnowsze [testy 42303421953](https://github.com/synixad-png/asteroidy-ios/actions/runs/42303421953) i osobne [XCTest iPhone/iPad 42303125651](https://github.com/synixad-png/asteroidy-ios/actions/runs/42303125651) — **stan sprawdzić**. W próbie iPada `simctl list devices available` przekroczył 60 s (błąd środowiska GitHub, nie dowód awarii aplikacji). Nie wykonano odsłuchu na fizycznym urządzeniu.
- **Co pozostało:** ręczny odsłuch na iPhone/iPad, pełna synchronizacja `Intro43` z oryginalną sceną intro (nie jest jeszcze normalną grywalną sceną iOS), pozostałe triggery dźwięków dotyczące jeszcze nieprzeniesionych mechanik/25 misji, porównanie subiektywne i próbkowe miksu AAC/Metal, pełna weryfikacja UI audio i stabilności symulatorów. **Nie wygenerowano nowego IPA**.

**Harmonogram 18 zadań — zachowany bez zmiany zakresu. Projekt: historyczne 38% / 62% pozostało (cały port, bez przeliczenia wag); zadanie 15: 60% za implementację źródłowych zasobów i kodu, 40% pozostało (bez fizycznych testów).**

| Nr | Zadanie | Postęp | Zmiana |
|---:|---|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 32% | 0 pp |
| 5 | Animacje modeli GLB | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 43% | 0 pp |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 0 pp |
| 9 | Bronie i trafienia | 24% | 0 pp |
| 10 | Przeciwnicy i AI | 11% | 0 pp |
| 11 | Bossowie i ich mechaniki | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 30% | 0 pp |
| 13 | Kampania — 26 sektorów atlasu | 37% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 24% | 0 pp |
| 15 | Dźwięki i muzyka | **60%** | **+50 pp** |
| 16 | Zapisywanie i wczytywanie gry | 32% | 0 pp |
| 17 | Sterowanie | 41% | 0 pp |
| 18 | Optymalizacja i testy | 18% | 0 pp |

---

## AKTUALNY ETAP — 06.11.2026: oryginalna muzyka i SFX, dwufazowy loader (BEZ IPA)

**Cały port: 38% wykonane, 62% pozostało (+0 pp).** W zakresie zadania 15 **infrastruktura audio 10% (+10 pp), oryginalna muzyka/SFX 0% (NIE przeniesiono brzmień)**. Audyt [42293009917](https://github.com/synixad-png/asteroidy-ios/actions/runs/42293009917) czterech paczek częściowych dowiódł braku generatora syntezy i prawdziwego pliku Intro43 PCM; dostępny jest wyłącznie obraz planet53.jpg. Oryginalny inwentarz potwierdza nazwę i SHA Intro43 PCM, ale nie zawiera jego bajtów. Wdrożono przygotowanie menu przy starcie, późniejsze przygotowanie audio tylko dla wczytywanej misji, cache oryginalnych wyników, odrzucanie spóźnionych żądań, zatrzymywanie po zmianie sceny oraz źródłowy tor AVAudioEngine; **z powodu brakujących źródeł obecnie niczego nie syntezuje ani nie odtwarza**. Nie dodano żadnych losowych melodii, plików WAV ani niezweryfikowanych suwaków. [Raport szczegółowy](Reports/V568_AUDIO_DWIE_FAZY_BEZ_ZAMIENNIKOW_2026-11-06.md).

| Nr | Stałe zadanie | Postęp | Zmiana |
|---:|---|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 32% | 0 pp |
| 5 | Animacje modeli GLB | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 43% | 0 pp |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 0 pp |
| 9 | Bronie i trafienia | 24% | 0 pp |
| 10 | Przeciwnicy i AI | 11% | 0 pp |
| 11 | Bossowie i ich mechaniki | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 30% | 0 pp |
| 13 | Kampania — 26 sektorów atlasu | 37% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 24% | 0 pp |
| 15 | Dźwięki i muzyka | **10% (tylko infrastruktura)** | **+10 pp** |
| 16 | Zapisywanie i wczytywanie gry | 32% | 0 pp |
| 17 | Sterowanie | 41% | 0 pp |
| 18 | Optymalizacja i testy | 18% | 0 pp |

**Pozostało konkretnie:** uzyskać rzeczywiste źródłowe procedury syntezy v568 i intro43.pcm.gz, przenieść muzykę menu i bank misji 1, powiązać oryginalne wyzwalacze SFX broni/wybuchów/silników/UI, odczytać autentyczne ustawienia, przetestować na iOS. Nie rozpoczynać zastępczej ścieżki ani następnego sektora. Bez generowania IPA i bez podnoszenia całkowitego wskaźnika bez testów.

---

## Wydany IPA — oryginalne silniki v491 / normalizacja C279 v523 (06.11.2026)

**GitHub Actions [42289576566](https://github.com/synixad-png/asteroidy-ios/actions/runs/42289576566) zakończył się SUCCESS** (Linux testy źródłowe oraz macOS natywne Xcode/Metal ARM64). Kompilacja z SHA źródeł `839edce5c5cb08e57bd11f614c7bc8513aa4f2bf`. Zweryfikowany ZIP artefaktu [13539047406](https://github.com/synixad-png/asteroidy-ios/actions/runs/42289576566/artifacts/13539047406) zawiera **ASTEROIDY_iOS_UNSIGNED.ipa** (27 059 072 bajtów, SHA-256 `b870ee6ef43c3c5e719fcd176d23fc0990f227aa07a5a059649faf662a91fad4`), platformę iPhoneOS z `UIDeviceFamily=[1,2]`, arm64, oryginalny `Vanguard431Source.mesh`, `Sector01CarbonisVertices.bin` oraz `default.metallib`. IPA ZIP CRC: PASS, zgodność hash z raportem CI: PASS. Brak podpisu i brak testu fizycznego iPhone/iPad; weryfikacja wzrokowa silników/skali na fizycznym GPU nadal nieprzeprowadzona. Osobny test na rzeczywistych 137067 wierzchołkach C279 z oryginalnego `carbonis279.mesh.gz`: obliczony promień 1.096075 i skala 0.9123463, PASS.

**Postęp całego portu: 38% / 62% pozostało (+0 pp)** — wydanie tej poprawki nie jest potwierdzeniem ukończenia 26 misji ani wszystkich testów urządzenia. Ustawienia silników pozostawiono bez fikcyjnych regulatorów (nie znaleziono potwierdzonego osobnego przełącznika w zweryfikowanych źródłach).

---

## Wdrożenie: plazma silników v491 i skala planety misji C279 v523 — 06.11.2026

**Wykonany zakres w kodzie (nie oznacza jeszcze testu GPU Apple):** w rzeczywistej walce CARBONIS 01 podłączono wcześniej istniejący źródłowo zgodny shader `fighterPlasmaVertex491`/`fighterPlasmaFragment491` (dwa oryginalne gniazda Vanguard431, trzy warstwy × trzy płaszczyzny × 16 segmentów, 1728 wierzchołków, blending SRC_ALPHA/ONE). Siła płomienia jest powiązana z oryginalnym `max(0.12, VisualPower298)`, a orientacja z tym samym modelem statku. Nie dodano fikcyjnych suwaków silnika: w dostępnym kodzie `GpuShip.cs`/`GpuSphere67.cs` nie potwierdzono osobnej regulacji wizualnej. Weryfikacja wartości planet odbywa się na `Windows/src/GpuPlanetGltf463.cs:37-69` oraz oryginalnych danych `carbonis279.mesh.gz`: rzeczywisty promień C279 = **1.09607509146**, współczynnik świata misji = **0.91234625053**; skanujemy oryginalne wierzchołki, nie konserwatywny `MaxRadius`. Transformację zastosowano **tylko do planety w rozgrywce**; W3 `NewHome290`, osobny podgląd C279, geometryczne wymiary statku i obiektów oraz fizyka nie są zmienione.

Test `Tests/CarbonisMissionPlanet523Tests.swift`: powtarzalny pomiar promienia, odwrotna skala, odrzucanie pustych, źle wyrównanych i NaN danych; lokalny Swift/Linux **PASS**. Testy w GitHub CI oraz kompilacja unsigned IPA na macOS są uruchamiane odrębnie; nie zakładamy PASS przed rzeczywistym wynikiem Apple. Zachowano bazę **38% / 62% pozostało** bez sztucznego podnoszenia.

---

## Kompilacja natywna Xcode — diagnoza i poprawka API Metal (06.11.2026)

[Run 42283783569](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283783569) zakończył się **FAIL** podczas natywnej kompilacji `compile-device`, mimo PASS bramki Linux. Rzeczywisty log Xcode wskazał jedno konkretne miejsce: `CarbonisExplosion524Renderer.swift:66:34` — `missing argument for parameter 'slice' in call`. W [commicie 6d212ed](https://github.com/synixad-png/asteroidy-ios/commit/6d212ed987ac89c84c590a68fd793a3b39ba6a0b) uzupełniono wymagany `slice:0` przy `MTLTexture.replace(region:mipmapLevel:slice:withBytes:bytesPerRow:bytesPerImage:)` dla 64³ tekstury szumu. Nie zmieniono shadera, ustawień, kolizji ani mechaniki. Automatyczna ponowna weryfikacja **bez IPA**: [GitHub Actions 42285668117](https://github.com/synixad-png/asteroidy-ios/actions/runs/42285668117), wynik natywnej kompilacji i Apple GPU **do potwierdzenia**. Testy interakcji ustawień na symulatorach [42285229667](https://github.com/synixad-png/asteroidy-ios/actions/runs/42285229667) także nie są jeszcze zaliczone. **Postęp: 38% / 62% pozostało (+0 pp).**

---

## CARBONIS 01 — weryfikacja interakcji i zapisu ustawień W3 (06.11.2026)

**38% portu wykonane / 62% pozostało (+0 pp).** Dodano natywny iOS XCTest na Apple Simulator iPhone/iPad sprawdzający obie zakładki WYBUCHY 3D i POCISKI: preset ASTEROIDA (92% rozmiaru i 11 kłębów), jakość BALANCED, jasność światła 0–400%, przełącznik mieszania kolorów oraz zapis po faktycznym zamknięciu i ponownym uruchomieniu procesu aplikacji. Dodano wyłącznie identyfikatory dostępności wartości istniejących kontrolek; bez zmian GPU/Metal, fizyki, hitboxów i broni. Naprawiono przestarzałą asercję dawnego podglądowego tytułu atlasu, która nie odpowiada już grywalnemu CARBONIS 01. Testy są podłączone do obecnego workflow `verify-v568-w3-navigation-ui.yml`, **bez tworzenia IPA**.

**Wyniki:** kod testów dodany, ale brak jeszcze zakończonego XCTest na Apple Simulator oraz testu fizycznych urządzeń; natywny build IPA 42283783569 nadal oczekuje na wynik zadania macOS. Testów nie oznaczono jako PASS. Dalej: odczytać wyniki Xcode i `.xcresult`, poprawić wykazane błędy, przetestować wygląd i wydajność efektów. **Globalne 38% / 62% bez zmiany**.

---

## CARBONIS 01 — WYBUCHY 3D / POCISKI, ustawienia jak w Windows v568 (06.11.2026)

**38% całego portu wdrożone / 62% pozostało — bez sztucznego podnoszenia procentów.** Z oryginalnych źródeł `Windows/src/Menu139.cs`, `Explosion524.cs`, `Combat69.cs`, `ShotAppearance151.cs`, `GpuSphere67.cs` przeniesiono prawdziwe **dwie zakładki menu W3**: „WYBUCHY 3D” (12 oryginalnych kontrolek, trzy presety, jakość 22/32/48 próbek, 3/4/6 wybuchów, suwak odłamków i natywny podgląd detonacji Metal) oraz „POCISKI” (3 kontrolki: jasność 0–400%, osiem źródłowych kolorów, mieszanie 48/52%). Ustawienia zapisują się trwale przez UserDefaults. Rzeczywisty renderer CARBONIS 01 pobiera ustawienia podczas wejścia do misji.

Dotychczasowe prostokątne smugi zastąpiono geodezyjnymi **sześcioczęściowymi, trójwarstwowymi** smugami, radialnymi rdzeniami o stałym rozmiarze ekranowym, błyskami wylotowymi myśliwców i **czterema warstwami światła każdego pocisku** na planecie. Pociski mają oryginalne barwy Pulse/Twin/Scatter oraz niebieskie/zielone/fioletowe barwy wrogów. Wybrany kolor w ustawieniach dotyczy **oświetlenia terenu**, nie zmienia barwy naturalnej pocisku ani mechaniki obrażeń i sterowania.

**Zweryfikowano:** [GitHub 42283180401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283180401) — **PASS 19 testów opcji + 17 testów efektów pocisków + 45 testów zniszczeń + 18 kontroli integracyjnych pierwszej misji i pełna regresja Swift/Linux**. [Build iOS 42283783569](https://github.com/synixad-png/asteroidy-ios/actions/runs/42283783569) — Linux preflight **PASS**, `compile-device` **queued** podczas wpisu. **Nie wykonano jeszcze** interaktywnej weryfikacji na iPhone/iPad, ani testu jakości obrazu i GPU Apple. [Raport szczegółowy](Reports/V568_CARBONIS01_USTAWIENIA_WYBUCHOW_I_POCISKOW_2026-11-06.md).

**Następne działanie:** uzyskać natywny wynik kompilacji Xcode/Metal, poprawić wyłącznie konkretnie wykazane błędy i potwierdzić na urządzeniu jednoczesne strzelanie/sterowanie, wygląd obydwu typów pocisków, suwak 400%, podgląd eksplozji i zapis po ponownym uruchomieniu. Nie przechodzić do kolejnej misji. 18 zadań stałego harmonogramu pozostaje bez zmian.

---

## POPRAWKA EFEKTÓW NISZCZENIA CARBONIS 01 — 06.11.2026

**Postęp portu pozostaje 38% / pozostało 62%** — nie podnoszono go przed testami renderowania Apple GPU. Dotychczas po zniszczeniu asteroidy lub myśliwca znikał model, a brakowało efektów wizualnych z oryginalnego Windows v568. Na podstawie **prawdziwej paczki źródeł Windows/SteamOS v568**, `Game.cs:224-230`, `BossTunnelGame.cs:96`, `GpuSphere67.cs:433,442-443`, `CombatPieces125.cs`, `GpuCombatPieces125.cs` i `Explosion524.cs`, przeniesiono odrębne reakcje: mała/średnia/duża skała **18/18/27** cząsteczek plus pierścień i objętościowy wybuch skali **9/15/23**; myśliwiec **22 pomarańczowe cząsteczki, 6 iskier, 11 metalowych szczątków 3D** plus wybuch paliwowy skali **14**; osobne efekty trafienia bez zniszczenia. Zachowano fizyczne odłamki, geometrię modeli, obrażenia, sterowanie i ukończenie misji.

Natywny shader `Sector01Explosion524.metal` przenosi 3D V8.2 gas/thermal raymarch (wspólna tekstura szumu `64³`, 13 kłębów, 22 próbki, najwyżej trzy równoczesne wolumetryczne eksplozje). `CarbonisExplosion524Meshes.swift` rysuje trójwymiarowe metalowe tetraedry, pierścienie i geodezyjne smugi; symulacja `CarbonisDestruction524.swift` uruchamia je **tylko** przy rzeczywistych trafieniach i śmierciach obiektów. **PASS:** [testy Swift/Linux 42276790554](https://github.com/synixad-png/asteroidy-ios/actions/runs/42276790554) — 45 nowych kontroli efektów i wcześniejsza pełna regresja pierwszej misji. **PASS:** [pre-build IPA 42277254285](https://github.com/synixad-png/asteroidy-ios/actions/runs/42277254285). `compile-device` w kolejce runnera macOS; nie ma potwierdzonego nowego IPA ani testu wizualnego na iPhone/iPad. [Pełny audyt źródeł i raport](Reports/V568_CARBONIS01_ORYGINALNE_EKSPLOZJE524_2026-11-06.md).

**Następny punkt do domknięcia:** natywna kompilacja MSL/Swift na Xcode i oględziny efektów w działającej pierwszej misji na fizycznym urządzeniu wraz z pomiarem wydajności. Nie przenosić w tym etapie żadnych kolejnych planet ani klas przeciwników; lista 18 zadań pozostaje niezmienna.

---

## POPRAWKA STEROWANIA CARBONIS 01 — 06.11.2026 (bez zmiany 18 zadań)

Prawa połowa ekranu zachowuje celowanie/skręt i jednocześnie **automatycznie strzela od pierwszego dotknięcia**, także podczas przeciągania palca; puszczenie prawego palca wyłącza ostrzał. Lewa połowa, czułość ruchu `/110`, prawa czułość celowania `/100` i mechanika lotu pozostają niezmienione. Usunięto osobny ekranowy przycisk „OGIEŃ”, a pasywny HUD i radar przepuszczają dotknięcia. Powrót z tła iOS resetuje zablokowane sterowanie. Testy regresji: źródłowy kontrakt SwiftUI/dotyku i fizyczny test ciągłego strzelania w logice `CarbonisCombat568`. [Raport techniczny](Reports/CARBONIS01_RIGHT_TOUCH_AUTO_FIRE_2026-11-06.md).

**Łączny postęp portu nadal 38% / pozostało 62%.** Nie ma podstaw, aby podnosić ten wskaźnik za małą poprawkę UI. Nadal pracujemy wyłącznie nad pierwszą misją. Odrębny status Xcode i testu dwóch palców na iPhone/iPad należy potwierdzić.

---

## AKTUALNY ETAP — 06.11.2026: CARBONIS 01 — od realnej walki do zapisu, nagród i serwisu

**Cały port: 38% wykonano implementacyjnie (+2 pp), 62% pozostało.** Lista 18 stałych zadań jest niezmienna; zmieniają się wyłącznie poparte kodem i testami procenty. **To nie jest 100% pierwszej misji na urządzeniu.** Nie uruchomiono najnowszej rewizji na fizycznym iPhonie, nie potwierdzono kompletnych oryginalnych SFX ani wizualnej zgodności z Windows v568.

Wdrożono dla wyłącznie pierwszej misji CARBONIS C279: oryginalną falę 13 asteroid i 4 myśliwców, pełniejsze `Physics68` i respawn, pierścienie żetonów na planetarnym GPU oraz radarze, rzeczywiste zbieranie i rozliczanie `DropLoot/MovePickup68`, `FinishLevel` (premia 12 żetonów), opóźniony raport `LevelSummary166` (4,2 s), zapis ukończenia `CampaignStore556`, trwałe odblokowanie sektora02, odporność na replay/dwukrotne naliczenie, natywny serwis sześciu oryginalnych ulepszeń i ich działanie w walce (Twin, Scatter, Power, Rapid, shield, życie), zapis portfela, ekwipunku, pozostałych żyć i osłon. Przy porażce można ponowić pierwszą misję bez fałszywej wygranej. Nie dodano grywalnej drugiej misji ani bossów.

**Dowód:** [GitHub Actions 42269114054](https://github.com/synixad-png/asteroidy-ios/actions/runs/42269114054) — **PASS `verify-sphere-linux`**, w tym **335 kroków faktycznej symulacji 120 Hz**, 18 testów integracyjnych źródłowej fali do trwałego rozliczenia oraz 41 kontroli serwisu/replay. Test używa deterministycznie kierowanych strzałów i weryfikuje rzeczywiste trafienia oraz warunki zwycięstwa, ale **nie dowodzi ręcznej gry na iPhonie**. `compile-device` dla najnowszej rewizji był **queued** podczas przygotowania raportu; źródłowy IPA dla tej rewizji nie jest jeszcze potwierdzony. [Pełny raport](Reports/V568_CARBONIS01_FINISH_REWARDS_SERVICE_E2E_2026-11-06.md).

| Nr | Stałe zadanie | Poprzednio | Obecnie | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 32% | 32% | 0 pp |
| 5 | Animacje modeli GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 41% | **43%** | **+2 pp** |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 18% | **24%** | **+6 pp** |
| 10 | Przeciwnicy i AI | 11% | 11% | 0 pp |
| 11 | Bossowie i ich mechaniki | 0% | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 22% | **30%** | **+8 pp** |
| 13 | Kampania — 26 sektorów atlasu | 35% | **37%** | **+2 pp** |
| 14 | Menu W3, HUD i ustawienia | 19% | **24%** | **+5 pp** |
| 15 | Dźwięki i muzyka | 0% | 0% | 0 pp |
| 16 | Zapisywanie i wczytywanie gry | 20% | **32%** | **+12 pp** |
| 17 | Sterowanie | 41% | 41% | 0 pp |
| 18 | Optymalizacja i testy | 14% | **18%** | **+4 pp** |

**Następny etap pracy nad tą samą pierwszą misją:** sprawdzić najnowszy build Xcode i IPA, usunąć ewentualne błędy, zweryfikować dotyk/wyniki/serwis/ponowne wejście na urządzeniu, a następnie przenieść oryginalne `CombatSound/Sounds79` oraz brakujące źródłowe efekty bez substytutów. Nie rozpoczynać prac nad planetą02, dopóki CARBONIS 01 nie jest faktycznie domknięty.

---

## AKTUALNY ETAP — 06.11.2026: drugi oryginalny myśliwiec i 450 profili AI

**Projekt implementacyjnie: 36% (+1 pp), pozostało 64%.** Bez zmian w niezmiennej liście 18 zadań. Dodano `ShipMesh(1,false)` z oryginalnego Windows v568 jako odrębny model proceduralny myśliwca o 5521 trójkątach, 8 grupach materiałów i własnych skrzydłach, działkach oraz barwach (pierwszy myśliwiec nadal 5345 trójkątów). Metal posiada osobne bufory dla źródłowych typów 0 i 1; inne brakujące typy nie są zastępowane atrapami. Oryginalna animacja ostrzeżenia powiększa tylko świecące rdzenie 5/6 o 15%, nie cały kadłub.

Dodatkowo `ShooterTactics71.swift` przenosi reguły `EnemyTactics71.cs` dla sześciu rodzajów przeciwników, 25 poziomów i 3 trudności; `CarbonisCombat568` korzysta z nich dla bieżącego sektora 01 bez zmiany zachowania pierwszej fali. **Zweryfikowano:** [GitHub Actions 42260834217](https://github.com/synixad-png/asteroidy-ios/actions/runs/42260834217) `verify-combat-no-ipa` **PASS**, 97 301 asercji geometrii i 6307 asercji reguł AI. Nowsza kontrola rdzeni Metal ma osobny przebieg; macOS dla obecnej rewizji jeszcze niezweryfikowany. **Starszy [IPA 42259012837](https://github.com/synixad-png/asteroidy-ios/actions/runs/42259012837) zbudowano poprawnie (26,3 MB), ale nie zawiera tych nowych zmian.** Nie przeprowadzono interaktywnego testu iPhone/iPad.

[Raport techniczny](Reports/V568_SOURCE_SHOOTER_KIND1_450_TACTICS_2026-11-06.md). Poziomy 2–25, bossowie, kompletna kampania, audio, wszystkie statki i materiały nie są ukończone. Typ 1 jest przygotowany dla późniejszych sektorów; CARBONIS 01 nadal spawnuje wyłącznie typ 0.

| Nr | Stałe zadanie | Poprzednio | Obecnie | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 28% | **32%** | **+4 pp** |
| 5 | Animacje modeli GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 41% | 41% | 0 pp |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 18% | 18% | 0 pp |
| 10 | Przeciwnicy i AI | 8% | **11%** | **+3 pp** |
| 11 | Bossowie i ich mechaniki | 0% | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 22% | 22% | 0 pp |
| 13 | Kampania — 26 sektorów atlasu | 35% | 35% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 19% | 19% | 0 pp |
| 15 | Dźwięki i muzyka | 0% | 0% | 0 pp |
| 16 | Zapisywanie i wczytywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 41% | 41% | 0 pp |
| 18 | Optymalizacja i testy | 12% | **14%** | **+2 pp** |

**Dalsza praca według A–J:** kontrola kompilacji bieżącego kodu w Xcode, realne włączenie klas kolejnych przeciwników na zgodnych sektorach, a później właściwe cele, bossowie, broń, audio, zapis i testy urządzeń. Poniżej wcześniejsze raporty 35%, 33%, 31% itd. są historią, nie nowym harmonogramem.

---

## NAJNOWSZY ETAP 06.11.2026 — źródłowe myśliwce CARBONIS 3D i fizyka Physics68

**Cały port implementacyjnie: 35% (+2 pp), pozostało 65%.** W bieżącym etapie dodano pełną proceduralną geometrię myśliwca typu 0, współdzieloną w Metal przez cztery jednostki, oraz pierścienie ostrzegające przed strzałem. AI poziomu 1 bazuje teraz na `EnemyTactics71.cs`, a kolizje statku, odrzut po trafieniu, priorytet trafień, zasłanianie przez asteroidy, punktacja i 18 nietrwałych odłamków na `Physics68.cs`, `HitBug` i `Game.Split`. Zachowano mechanizmy i zasoby dotychczasowej CARBONIS C279 bez ingerencji w samą geometrię planety.

**Testy tego etapu: [GitHub Actions 42256245496 — SUCCESS](https://github.com/synixad-png/asteroidy-ios/actions/runs/42256245496)** dla całego `verify-combat-no-ipa` (w tym nowych testów generatora myśliwców i fizyki oraz historycznych regresji). Kompilacja Xcode/macOS pozostaje **queued**, nowy IPA i test GPU Apple **niepotwierdzone**. Wszystkie 18 zadań są nadal w tym samym układzie. [Raport techniczny](Reports/V568_CARBONIS_SOURCE_FIGHTERS_PHYSICS_SHARDS_2026-11-06.md).

| Nr | Stałe zadanie | Poprzednio | Obecnie | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 24% | **28%** | **+4 pp** |
| 5 | Animacje modeli GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 41% | 41% | 0 pp |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 13% | **18%** | **+5 pp** |
| 10 | Przeciwnicy i AI | 3% | **8%** | **+5 pp** |
| 11 | Bossowie i ich mechaniki | 0% | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 18% | **22%** | **+4 pp** |
| 13 | Kampania — 26 sektorów atlasu | 35% | 35% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 19% | 19% | 0 pp |
| 15 | Dźwięki i muzyka | 0% | 0% | 0 pp |
| 16 | Zapisywanie i wczytywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 41% | 41% | 0 pp |
| 18 | Optymalizacja i testy | 10% | **12%** | **+2 pp** |

**Dalej:** kolejne typy przeciwników i misje źródłowe, w międzyczasie natywna kompilacja iOS, bez zastępowania rzeczywistych assetów atrapami i bez udawania gotowego IPA. Niżej pozostaje historia etapów 33%, 31%, 30% oraz wcześniejszych.

---

## NOWY ETAP 06.11.2026 — pierwsza interaktywna misja CARBONIS 01 (kod wdrożony, IPA weryfikowane)

**33% projektu ukończone implementacyjnie (+2 pp) / 67% pozostało.** Po wcześniejszym kroku 31% wdrożono źródłowy VANGUARD431 w scenie CARBONIS C279 z kamerą Sphere67, sterowaniem L/P bez widocznych analogów, osobnym przyciskiem ognia, klatkową symulacją pocisków i myśliwców z oryginalnej WAVE, rozpadem asteroid, uszkodzeniami, śmiercią, 0,2s warunkiem zwycięstwa i radarem rzeczywistych zagrożeń. `CarbonisSession568` jest wspólnym stanem logiki i Metal; nie jest to niezależna demonstracja Boreas. Zasoby planety z czterech audytowanych ZIP są teraz przygotowywane również podczas budowania IPA.

**Aktualne testy:** przebieg [GitHub Actions 42247230721](https://github.com/synixad-png/asteroidy-ios/actions/runs/42247230721) ma `verify-sphere-linux` **SUCCESS** (z realnym testem `CarbonisCombat568`), ale `compile-device` był nadal w kolejce macOS. W związku z udokumentowanymi problemami przydziału runnerów Apple uruchomiono alternatywny [przebieg 42247840690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42247840690) na `macos-15-intel`; jego wynik nie jest jeszcze potwierdzony. Najnowszy workflow wymaga przejścia smoke testu rzeczywistego `CarbonisCombat568` na Linux przed Xcode. **Nie ma jeszcze potwierdzonego działającego IPA**, nie przeprowadzono interaktywnego testu iPhone/iPad.

**Wyraźne granice:** gra na CARBONIS jest zaimplementowana w kodzie, ale oryginalne modele myśliwców (`ShipMesh/GpuRobot70`) nadal nie są renderowane w 3D; ich pozycje AI i pociski działają w symulacji i są pokazane na radarze. Nie ukończono 24 pozostałych misji PC, bonusowego widoku atlasu nr 26, bossów, pełnego uzbrojenia, efektów, audio, zapisu i testów GPU. Zwycięstwo próbnego sektora nie oznacza zaktualizowanej kampanii. [Raport prac](Reports/V568_CARBONIS_LIVE_COMBAT_2026-11-06.md).

| Nr | Stałe zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik graficzny Metal | 89% | 89% | 0 pp |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki, planety i zasoby 3D | 24% | 24% | 0 pp |
| 5 | Animacje modeli GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu i poruszanie po planetach | 35% | **41%** | **+6 pp** |
| 7 | Kolizje, obrażenia i zniszczenia (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale walki (dotychczasowy moduł) | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | **13%** | **+3 pp** |
| 10 | Przeciwnicy i AI | 0% | **3%** | **+3 pp** |
| 11 | Bossowie i ich mechaniki | 0% | 0% | 0 pp |
| 12 | Komplet misji planetarnych | 12% | **18%** | **+6 pp** |
| 13 | Kampania — 26 sektorów atlasu | 35% | 35% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 15% | **19%** | **+4 pp** |
| 15 | Dźwięki i muzyka | 0% | 0% | 0 pp |
| 16 | Zapisywanie i wczytywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | **41%** | **+6 pp** |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Dalsza kolejność A–J:** najpierw potwierdzić build iOS/IPA i działanie sterowania, następnie źródłowe modele myśliwców na C279, dalej oryginalne AI/zbrojenie/kolizje, cele, pozostałe misje, bossowie, audio, zapis i testy. Starsze 31% poniżej to historia, nie aktualny stan.

---

## AKTUALNY POSTĘP 06.11.2026 — źródłowe asteroidy C279 w natywnym Metal

**Całość: 31% wykonane (+1 pp), 69% pozostało.** Etap C: scena CARBONIS korzysta z rzeczywistego zestawu asteroid `MissionWave568`. W `Sector01CarbonisPreview568` zaimplementowano proceduralne siatki `RockVertices75`, buforowane według kształtu, źródłowe osadzenie `StampSphere67`, toon z `GpuRockInstancing75` i rzeczywiste klatkowe `SphereAsteroid556.advance(dt:)`. Oryginalne indeksy 810 747, 2 grupy materiałów, UV i 3 tekstury C279 zostały nietknięte.

**Weryfikacja:** lokalnie Swift/Linux **43 385 asercji geometrii PASS**; 10 kontroli źródła renderer/Metal i zachowania C279 PASS. GitHub Actions przygotowano do kompilacji oryginalnych modeli w Swift i natywnego Xcode. **Nie ma jeszcze potwierdzenia wyniku kompilacji iOS ani wykonania Metal na prawdziwym urządzeniu.** Myśliwce, AI, lot statku, kolizje i warunki zwycięstwa nie są gotowe. Nie wydano IPA. [Pełny raport źródłowy](Reports/V568_STAGE_C_ORIGINAL_ROCK_RENDERER_2026-11-06.md).

| Nr | Stałe zadanie | Poprzednio | Obecnie | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 22% | **24%** | **+2 pp** |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia — wcześniej zamknięty moduł | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale — wcześniej zamknięty moduł | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 10% | **12%** | **+2 pp** |
| 13 | Kampania — 26 sektorów atlasu | 35% | 35% | 0 pp |
| 14 | Menu W3 i HUD | 15% | 15% | 0 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Następne zadanie w C/D:** aktywny statek i prawdziwa kamera lotu na C279 (nie obrót planety jako inspekcja), następnie myśliwce/AI i łączenie istniejącego `SpawnIncoming` z klatkową symulacją oraz kolizjami. Zachować zakres 18 zadań. Starsze wartości 30% w historii poniżej nie są aktualnym stanem.

---

## BIEŻĄCY STAN — 06.11.2026: przygotowana źródłowa WAVE na CARBONIS

**Cały projekt: 30% wykonane (+1 pp) / 70% pozostało.** Ukończona implementacja początkowej źródłowej fali dla wszystkich 25 faktycznych poziomów PC: asteroid, uzbrojonych myśliwców, segmentowanych robotów, parametrów fal i początkowych limitów posiłków. Nie jest to jeszcze grywalna walka w CARBONIS — brakuje aktywnego AI, renderowania przeciwników i lotu/strzałów/wyniku.

W `GameView` po legalnym wyborze CARBONIS 01 tworzony jest teraz snapshot `MissionStart261` i `MissionWave568`, przekazywany do `Sector01Scene568`. Scena pokazuje **rzeczywiste dane 13 asteroid / 4 myśliwców / 0 robotów** dla normalnej trudności, bez fikcyjnych odblokowań. Po powrocie do atlasu snapshot jest usuwany. W źródłowym `Windows/src/Game.cs` `CampaignLength=25`, dlatego 26. pozycja atlasu nie jest automatycznie traktowana jako dodatkowy poziom `Wave()`.

**Weryfikacja:** Swift/Linux na lokalnych odpowiednikach zależności — **909 testów początkowej WAVE + 633 testy Action38 SpawnIncoming + 12 testów bramki PASS = 1554 asercje**, kontrole spójności repozytorium PASS, archiwum v568 CRC PASS. CI GitHub zostało uzupełnione, ale jego końcowy wynik oraz natywne wykonanie na iPhone/iPad dla tej rewizji **nie zostały jeszcze potwierdzone**. Bez nowego IPA.

| Nr | Stałe zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 22% | 22% | 0 pp |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia (wcześniejszy moduł) | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale (wcześniejszy moduł) | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 8% | 10% | +2 pp |
| 13 | Kampania — 26 sektorów atlasu | 35% | 35% | 0 pp |
| 14 | Menu W3, HUD i ustawienia | 15% | 15% | 0 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Ukończono także czysty moduł posiłków `MissionIncoming568`:** kontynuuje stan C# Random po pierwszej fali, odtwarza limity 2 skał, zegary `StepAction` i powiadomienie 1,6 s. Scheduler został dołączony do przygotowania CARBONIS i testów CI, ale **jeszcze nie działa w aktywnej pętli misji**. Nowy kod nie zmienił źródłowych modeli ani mechanizmów zadań 7/8.

**Następne w C/D:** aktywne renderowanie wygenerowanych statków/asteroid w C279, fizyka lotu i kamera, zintegrowana pętla AI, rzeczywiste `SpawnIncoming()`, broń, kolizje i wynik misji. Nie zamykać C ani D przed tym etapem. [Raport źródłowy i ograniczenia](Reports/V568_STAGE_C_WAVE_PREPARED_2026-11-06.md).

---

## KOREKTA ŹRÓDEŁ WAVE — 06.11.2026

**PEŁNE ŹRÓDŁA ODNALEZIONE.** `Game.Wave()` jest w oryginalnym v568: `Windows/src/Game.cs:90–101` oraz `SteamOS/src/Game.cs:90–101`; ich bloki mają identyczny SHA-256. Weryfikacja dotyczy kompletnego ZIP z Biblioteki (1788 pozycji; CRC PASS), nie ograniczonego audytu. [Pełne ustalenia](Reports/V568_WAVE_FULL_SOURCE_AUDIT_2026-11-06.md). **Wciąż brak wdrożenia kompletnej WAVE w rozgrywce CARBONIS na iOS.** Procenty projektu bez zmiany: 29% / 71%.

## AKTUALIZACJA 06.11.2026 — rzeczywisty teren C279, etap C bez sztucznego ukończenia

**Projekt: 29% wykonane / 71% pozostało (zmiana 0 pp). Stałe 18 zadań i ich dotychczasowe wartości bez zmian.** Ostatnia funkcja: `CarbonisSurface277.swift` — dokładny odczyt oryginalnej mapy wysokości CARBONIS 512×256 na podstawie `Carbonis277.cs:56–65` i `PlanetMesh.cs:193`. Inspektor planety korzysta z rzeczywistego wyniku `surfaceRadius(x:1,y:0,z:0)`; bramka wejścia wymaga również SHA-256 rzeczywistej mapy C279. Pozostają nienaruszone źródłowe indeksy, UV, materiały i blokady misji.

**Weryfikacja:** oryginalna mapa 524296 B, SHA-256 `3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39`; lokalne testy Swift/Linux 27/27 PASS na oryginalnym zasobie, włączone również do GitHub Actions bez IPA. **Natywny wynik iOS/Xcode tej rewizji niepotwierdzony.** To tylko próbnik terenu, nie działający kontroler kolizji statku.

**SKORYGOWANO po przeglądzie pełnej paczki źródłowej:** definicja `Wave()` ISTNIEJE w `Windows/src/Game.cs:90–101` i `SteamOS/src/Game.cs:90–101` w pełnym `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` (150 473 406 B, CRC PASS). Wcześniejszy brak dotyczył tylko 66 MB wyciągu audytowego. Należy teraz przenieść rzeczywiste `Wave()` wraz z `Action38.cs`, `EnemyTactics71.cs`, `RobotSnake70.cs`, `Balance70.cs` i podłączyć do CARBONIS; później dokończyć ruch i kolizje. Źródłowy przegląd i wykryta niezgodność starszego testu w [audycie WAVE](Reports/V568_WAVE_FULL_SOURCE_AUDIT_2026-11-06.md). Bez IPA.

[Pełny raport źródłowy](Reports/V568_STAGE_C_CARBONIS_TERRAIN_SOURCE_2026-11-06.md).

## UZUPEŁNIENIE 06.11.2026 — pierwsza część źródłowego StartHubMission261 (bez nowego IPA)

**Kod wdrożony:** `ASTEROIDYiOS/MissionStart261.swift` portuje sam etap przygotowania stanu z oryginalnego `PortingReferenceCode/v568/Windows/src/Orbit50.cs`, wiersze 58–78 (archiwum audytu v568): kontrolę 26 sektorów i blokad, reset statku/kamery, pięciu zbiorów obiektów, bossów, zdrowia i czasu, przywrócenie żyć oraz dokładnie `4.5 s` ochrony dla poziomów 1–4 i `3 s` dla 5–26. Moduł nie zmienia zapisu ani bitów ukończenia.

**Testy:** `Tests/MissionStart261Tests.swift` zawiera 171 asercji; analogiczny test kompilowany i uruchomiony lokalnie w Swift/Linux dał PASS. Workflow `verify-combat-only.yml` został uzupełniony o kompilację/uruchomienie testu oraz kompilację iOS bez IPA; końcowy wynik GitHub Actions dla nowej rewizji nie został jeszcze potwierdzony.

**Granica funkcjonalności:** zgodnie z oryginałem następne wywołania to `Wave()` i `BeginLevelIntro()`. Nie zostały jeszcze przeniesione, podobnie jak rzeczywisty lot/walka w sektorze C279. Nowy moduł przygotowujący **nie jest jeszcze podłączony do ekranu CARBONIS**, aby nie pokazywać pozornego startu gry. Następny krok: port źródłowej `Wave()` i inicjalizacja rzeczywistego runtime misji, a potem integracja z widokiem. Zamrożone mechanizmy 7/8 pozostawiono bez zmian.

**Procenty bez zmian:** 29% całego projektu / 71% pozostało. Sama pierwsza część inicjalizacji nie uzasadnia zwiększenia procentu całej gry. **Nie wygenerowano IPA.** Commity: `c6749960`, `674fd4fa`, `8ea6ac5d`.

# ASTEROIDY iOS — stały harmonogram portowania

## UZUPEŁNIENIE 06.11.2026 — bezpieczeństwo wejścia do CARBONIS (bez zmiany postępu)

W commitach `7438a823` i `9f769824` uszczelniono wejście do oryginalnej sceny C279: `Sector01CarbonisPreview568.isAvailable` sprawdza teraz nie tylko istnienie, ale również SHA-256 wszystkich pięciu źródłowych plików jeszcze przed wyborem sceny. Weryfikacja w rendererze Metal pozostaje niezależnie aktywna. Rozszerzono kontrakt `Tests/V568W3NativeMenuContract.py` o asercje tej bramki.

**Postęp bez zmian: 29% wykonane / 71% pozostało.** To naprawa ochronna etapu C, a nie implementacja `StartHubMission261`, fal, lotu czy wygranej. Natywna kompilacja po tych commitach i test na fizycznym iOS nie zostały jeszcze potwierdzone; poprzedni PASS `42225858732` dotyczy wcześniejszego snapshotu. Następne zadanie: rzeczywista logika startu misji na podstawie Windows v568, nie powtarzanie testów menu. Nowego IPA nie wydano.

## BIEŻĄCY STAN — etap C: wejście w rzeczywistą scenę CARBONIS, 06.11.2026

**Ocena projektu 29% wykonane (+1 pp) / 71% pozostało.**
Nowy przyrost jest oszacowaniem wdrożonej na iOS, skompilowanej
funkcjonalności przejścia do źródłowego sektora 01, a nie
deklaracją, że ten sektor jest już grywalny.
Poniższy harmonogram jest bieżący; starsze wartości poniżej
pozostają archiwalnymi raportami.

**Nowa funkcja:** `W3MainMenu568` → wybór z prawdziwego
26-sektorowego `CampaignAtlas556` → przycisk
`WEJDŹ NA CARBONIS 01 / ŹRÓDŁOWA SCENA 3D` →
`Sector01Scene568` z oryginalnym C279 Metal
(270249 trójkątów) → **WRÓĆ DO MAPY** przywraca
właściwy atlas. Jest obsługa obrotu planety palcem;
brak fikcyjnych nagród, włączania zablokowanych misji,
podmiany Carbonis na Boreas i fałszywego ukończenia.
Wszystkie 25 pozostałych sektorów mają zabezpieczoną
bramkę wejścia — nie są kierowane do Carbonis.
Źródłowe indeksy/UV/tekstury nadal nienaruszone.

[GitHub Actions 42225858732](https://github.com/synixad-png/asteroidy-ios/actions/runs/42225858732)
**PASS / PASS** — natywna kompilacja iOS Swift/Metal
oraz źródłowe testy wejścia, selekcji, kolizji i walki.
**Brak testu dotyku tej nowej trasy na fizycznym iOS**,
nie deklarować interaktywnego PASS na urządzeniu.

**Nadal do wykonania w C:** właściwy
`Game.StartHubMission261`, uruchomienie fal `Wave()`,
statek i kamera w realnym świecie Carbonis, kolizja
z mapą wysokości, broń, przeciwnicy, wynik
i zakończenie misji. To ma być kolejny zakres wdrożenia;
testy menu nie mogą ponownie zastąpić rozwoju gry.

**Stałe 18 zadań; wartości poprzednie i obecne:**

| Nr | Zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 22% | 22% | 0 pp |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 7% | 8% | +1 pp |
| 13 | Kampania — 26 sektorów | 34% | 35% | +1 pp |
| 14 | Menu W3, HUD i ustawienia | 14% | 15% | +1 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Raport techniczny:**
[Reports/V568_STAGE_C_CARBONIS_ENTRY_2026-11-06.md](Reports/V568_STAGE_C_CARBONIS_ENTRY_2026-11-06.md).

**IPA:** nowe wydanie nie było zlecone; wcześniejszy plik
na Dysku Google pozostaje starszym snapshotem.
Nie wydano nowego IPA.


## BIEŻĄCY STAN — REALNY POSTĘP, 06.11.2026 (obowiązuje przed starszymi wpisami)

**Ocena całego projektu: 28% wykonane (+1 pp), 72% pozostało.**
Procenty poniżej są ostrożną oceną realnego zakresu implementacji
i testów; wcześniejsze wpisy zachowano jako historię, a nie bieżący stan.

**Wykonano nowe funkcje, a nie kolejne powtórzenie testów menu:**

- **B. Wybór misji:** prawdziwe klikalne 26 pól kampanii w
  `App.swift` i `W3MainMenu568.swift`, autentyczne nazwy planet
  z audytu PC v568 (`MissionCatalog568.swift`), blokowanie
  niedostępnych sektorów zgodnie z `Orbit50.MissionUnlocked50`,
  podświetlenie wybranego sektora i zapis `selectedSector`
  w UserDefaults **osobno od bitów ukończonych misji**.
  Przypadkowe dotknięcie nie zalicza misji. Natywna kompilacja
  i testy czystej logiki **PASS**:
  [GitHub Actions 42220854317](https://github.com/synixad-png/asteroidy-ios/actions/runs/42220854317).
  Test interaktywny tej nowej funkcji na fizycznym iPhonie/iPadzie
  nie został wykonany; nie deklarować 100% gotowości B.
- **C. Pierwszy sektor CARBONIS:** oryginalna siatka C279,
  **270249 trójkątów, 137067 unikatowych wierzchołków,
  810747 oryginalnych indeksów, UV, 2 grupy materiałów i
  mapa wysokości 512×256**. Bez rekonstrukcji z OBB lub
  generowania zastępczej kuli. Oryginalne trzy tekstury są
  chronione SHA-256. Zamiast rozwijać geometrię do ~38,9 MB,
  zachowano GPU indexed mesh **9 822 204 B** bez zmiany
  źródłowej geometrii. Wdrożono źródłowy podgląd Carbonis
  po wybraniu sektora 01, nowy shader i renderer Metal.
  Test autentyczności [42222217173](https://github.com/synixad-png/asteroidy-ios/actions/runs/42222217173)
  **PASS**. Natywna kompilacja iOS wraz z regresjami
  [42223077726](https://github.com/synixad-png/asteroidy-ios/actions/runs/42223077726)
  **PASS** dla obu jobów. Zgodność PBR obrazu 1:1 z Windows,
  fizyczny render i prawdziwy start rozgrywki są jeszcze
  do wdrożenia/zweryfikowania.
- **A. Menu W3:** pozostają do zamknięcia ograniczenia testu
  interaktywnego iPada oraz pełna zgodność graficzna; nie
  blokują już przygotowania kolejnych elementów gry.
- **Czego NIE wykonano:** rzeczywistego `StartHubMission261`
  na wybranym sektorze, walki w źródłowej misji CARBONIS,
  śledzenia zwycięstwa/przegranej i 25 pozostałych grywalnych
  planet. **Nowego IPA nie wydano**. Poprzedni plik z Dysku
  Google nie zawiera tych nowych zmian.

**Stała lista 18 zadań — aktualne procenty i zmiany względem
poprzedniego raportu:**

| Nr | Stałe zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 20% | 22% | +2 pp |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 5% | 7% | +2 pp |
| 13 | Kampania — 26 sektorów | 30% | 34% | +4 pp |
| 14 | Menu W3, HUD i ustawienia | 10% | 14% | +4 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Następny krok wykonawczy:** faktyczne wejście z wyboru sektora
01 do źródłowej misji CARBONIS z prawdziwym trybem gry,
kamerą, kolizjami, falami i wynikiem. Dalsze testy menu
prowadzić jako rozwiązywanie konkretnych usterek, nie
nieskończoną blokadę rozwoju.

Dokładne dowody:
[Raport B/C CARBONIS](Reports/V568_STAGE_B_SELECTION_C_CARBONIS_SOURCE_2026-11-06.md).


## AKTUALIZACJA 06.11.2026 — realizacja A, faktyczne Apple GPU i XCTest

**ETAP A (MENU W3) W TRAKCIE; B JESZCZE NIEROZPOCZĘTY.**
Stały harmonogram 18 zadań: **27% wykonane / 73% pozostało**.
Zadanie 14 **10% (+0 pp)** — nie podwyższać bez ukończenia testów UI.

**Aktualna praca:** poprzednie sesje Apple Actions
[42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
i
[42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
zakończyły się niepowodzeniem, a zadania symulatorów anulowano;
nie dostarczyły pełnego wyniku nowej nawigacji.
Oba przepływy uruchomiono ponownie na **macos-15-intel**,
który wcześniej skutecznie kompilował i uruchamiał ASTEROIDY iOS.

- [GitHub Actions 42217818216 — oryginalne menu/planeta/okręt W3 GPU](https://github.com/synixad-png/asteroidy-ios/actions/runs/42217818216):
  **IPHONE SUCCESS** — rzeczywiste uruchomienie ekranu,
  oryginalne obrazy W3, planetarny model NewHome290 i ukończone
  komendy Metal oraz autentyczny zrzut ekranu.
  IPAD w momencie aktualizacji nadal uruchamiał rzeczywisty
  ekran i walidację GPU; nie zaliczono go bez wyniku końcowego.
- [GitHub Actions 42217810810 — siedem prawdziwych dotknięć W3](https://github.com/synixad-png/asteroidy-ios/actions/runs/42217810810):
  oba joby **IPHONE i IPAD wykonują rzeczywiste XCTest**,
  czyli dotknięcia 7 pozycji, wejścia do paneli, powroty i
  przejście do diagnostyki 3D. Nie deklarować PASS bez
  zakończonego testu; nie przedstawiać uruchomienia jako wyniku.
  W razie niepowodzenia pobrać zachowane `.xcresult`
  z drzewem dostępności i autentycznym zrzutem ekranu.
- Nie dokonano zmian w źródłowej geometrii, zapisach, kolizjach
  ani falach walki. **Nowego IPA nie generowano**; wcześniejszy
  zweryfikowany `W3_MENU_NAV` jest już na Dysku Google.

**Dalsza bramka:** bezpośrednie potwierdzenie siedmiu przycisków,
końcowy wynik obu GPU i ocena zgodności W3 z Windows.
Dopiero po zamknięciu A rozpoczyna się etap B — realny wybór misji.


## 06.11.2026 — POTWIERDZONE NOWE WYDANIE IPA W3 MENU NAV

**GitHub Actions 42212773252 — SUCCESS**. Nowy rzeczywisty,
**NIEPODPISANY** IPA do fizycznego iPhone/iPada:
`ASTEROIDY_v568_W3_MENU_NAV_iPhone_iPad_UNSIGNED.ipa`,
**14 103 697 B**; SHA256
`9b16daf6e045220140505ebbed99cf24befadbea8c0b7b2d8a1080df7b5c98ce`.
ZIP, iOS ARM64, oryginalne materiały W3/H290/Vanguard431
i wyniki `Tools/verify_ipa.py` — PASS, potwierdzone po
pobraniu pliku z GitHub. Snapshot wydania:
`1ebd88d37bd5cf0bb2b26ce961e067f4764b002c`.
[Artefakt GitHub 13500341359](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212773252/artifacts/13500341359).

Na **prywatnym Dysku Google użytkownika** potwierdzono
[ZIP z nowym IPA i raportami SHA/CRC](https://drive.google.com/file/d/1VyqprYPbt6KLGIqwKzgwrHzAGGqrGSyH/view?usp=drivesdk)
(13 943 090 B). ZIP trzeba rozpakować, by otrzymać plik
IPA. Jest to kopia całego artefaktu GitHub, nie błędnie nazwany ZIP
udający IPA. Raport:
[Reports/V568_W3_MENU_NAV_IPA_RELEASE_2026-11-06.md](Reports/V568_W3_MENU_NAV_IPA_RELEASE_2026-11-06.md).

**Postęp harmonogramu nie został sztucznie podwyższony:**
cały projekt **27% wykonane / 73% pozostało**,
zadanie 14 **10% (+0 pp)**. Etap A otwarty, ponieważ
[XCTest 42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
i [GPU 42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
nie mają jeszcze końcowego wyniku. Etapu B (wybór misji)
nie rozpoczęto. Fizyczna instalacja nie została przetestowana.


## OSTATNI RAPORT — 06.11.2026, nowe IPA W3 na życzenie

**ETAP A: W TRAKCIE. ETAP B: nierozpoczęty.** Pełna lista 18 zadań
i ich procenty pozostają niezmienione: **27% projektu wykonano,
73% pozostało**, zadanie 14 **10%, zmiana +0 pp**.

- Naprawiono osiągalność wszystkich siedmiu źródłowych pozycji
  W3 w poziomym widoku iPhone'a: `W3MainMenu568.swift`
  korzysta teraz z pionowo przewijanej nawigacji oraz
  minimalnych obszarów dotykowych **44 pt**. Zachowano
  oryginalną geometrię NewHome290, podgląd Vanguard431,
  sterowanie planetą, siedem polskich nazw oraz przejścia
  do istniejących paneli. Nie modyfikowano misji, broni
  ani zamrożonych mechanik 7/8.
- Rozszerzono `Tests/V568W3NativeMenuContract.py` o wymuszenie
  przewijania, 44-pt przycisków, identyfikatorów dostępności
  i zachowania rozdziału menu od sceny diagnostycznej.
- **Kompilacja źródłowa Swift/Metal na iOS: PASS**
  [42212331058](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331058)
  (job `Compile iOS source only`, wynik `success`).
  Pozostałe testy regresyjne iOS i Xbox/asteroid nie muszą
  być uznawane za zakończone przed ich faktycznym wynikiem.
- **Nowe, jednorazowe IPA użytkownika** (niepodpisane
  arm64 dla fizycznych iPhone/iPad) uruchomiono z
  rewizji `0873cae65b99c41d020f6e841407e468e077e2e8`:
  [42212392679](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212392679).
  Wydanie należy uznać za gotowe **wyłącznie** po
  zweryfikowanym `success`, kontroli SHA/CRC/7
  oryginalnych zasobów i pobraniu pliku IPA. W przypadku
  niepowodzenia nie podawać linku do nieistniejącego pliku.
- Osobne, niedokończone testy nawigacji
  [42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
  oraz grafiki GPU
  [42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
  pozostają odrębnymi bramkami zaliczenia A. NIE zaliczać
  ich na podstawie kompilacji IPA ani starego zrzutu.

**Następne:** zakończyć XCTest siedmiu rzeczywistych
dotknięć oraz powrotu ze sceny 3D i zamknąć etap A; dopiero
potem B — wybór misji. Wydany wcześniej IPA z rewizji
`5242e4f` na Dysku Google jest odrębną starszą wersją.


## AKTUALIZACJA ETAPU A — natywna nawigacja W3, ostatni stan 06.11.2026

**Stan A: OTWARTY; B nie rozpoczęty.** Cały projekt **27%**,
pozostało **73%**, zadanie nr 14 **10%, +0 pp**. Nie zmieniono
zakresu ani postępów pozostałych 17 zadań. Nie wydano nowego IPA.

Rzeczywiste XCTest
[42204712384](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712384)
wykazały niedostępność `w3-home-0` dla automatycznego
wyszukiwania obu urządzeń. Poprawiono semantykę
`accessibilityElement(children: .contain)`, nazwy/cechy
i stabilne identyfikatory siedmiu natywnych przycisków;
w XCTest poprawiono interpolację, ustawiono krajobrazowe
uruchamianie i zapisano pełny `.xcresult` z obrazem/hierarchią
w razie błędu. Środowiskowy timeout `simctl launch`
iPada wydłużono z 50 do wciąż ograniczonych 150 s.
Testy iPhone/iPad przeniesiono na standardowe `macos-15`
bez zmiany prawdziwych kontroli GPU i dotyku.

**Potwierdzone:** rzeczywista kompilacja iOS + testy regresji
[42210096215](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210096215)
PASS. **Oczekują na wykonanie** dwa nowe przebiegi:
[dotyk 42211323604](https://github.com/synixad-png/asteroidy-ios/actions/runs/42211323604)
oraz
[GPU 42211331700](https://github.com/synixad-png/asteroidy-ios/actions/runs/42211331700).
Tego wyniku NIE nazywać PASS, zanim GitHub Actions nie
potwierdzi wszystkich jobów. Dalsza bramka A:
rzeczywiste tapnięcia wszystkich 7 pozycji, powroty i
weryfikacja zgodności wizualnej z PC v568.


## BIEŻĄCY STAN — etap A / menu W3, 06.11.2026

**Kolejność A → B → C → D... bez zmian. Zadanie 14: 10% (+0 pp).
Postęp całego projektu: 27% wykonane / 73% pozostało.**

- **Potwierdzone:** dwie rzeczywiste symulacje GPU oryginalnego menu
  W3, NewHome290 i Vanguard431: [42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165)
  — oba joby PASS. Natywna kompilacja Swift/Metal oraz testy
  kolizji/asteroid po najnowszej zmianie dostępności:
  [42210096215](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210096215)
  — oba joby PASS.
- **Niepowodzenia wykryte faktycznymi testami:** poprzednie
  [XCTest 42204712384](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712384)
  nie znajdowały identyfikatorów przycisków `w3-home-0` na
  obu symulatorach; [GPU 42204712407](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712407)
  miał PASS iPhone i timeout 50 s na `simctl launch` iPada.
  **Nie zaliczono** tych prób.
- **Wdrożone naprawy:** SwiftUI udostępnia każdą z siedmiu
  akcji jako natywny element dostępności z nazwą i stabilnym
  identyfikatorem; XCTest sprawdza kontrolki w orientacji
  poziomej, naprawiono interpolację indeksu oraz włączono
  zrzut rzeczywistej hierarchii dostępności po niepowodzeniu.
  Czas operacji `simctl launch` ograniczono do 150 s (zamiast 50 s)
  bez osłabiania kontroli prawdziwego obrazu i ukończonych
  komend Metal.
- **Bieżące testy:** [XCTest siedmiu przycisków
  42210375096](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210375096)
  oraz [GPU iPhone/iPad
  42210271128](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210271128).
  Ich końcowy wynik **nie jest jeszcze potwierdzony**.
- **Etap A otwarty**, ponieważ nawigacja i pełna zgodność
  oświetlenia z Windows v568 nie są zaliczone. **Etap B
  jeszcze nierozpoczęty.** Wcześniej wydane, niepodpisane IPA
  pozostaje nienaruszone i jest na Dysku Google użytkownika.
  Nowego IPA nie generowano.


> **AKTUALNA KOLEJNOŚĆ WYKONAWCZA (06.11.2026):** na życzenie użytkownika
> priorytetem jest **widoczny przepływ gry**, nie pierwotna kolejność
> numerów: **A. natywne menu → B. wybór misji → C. wejście na planetę →
> D. pełna grywalna misja i wynik → E. kolejne planety/statki → F. AI i
> bossowie → G. kampania 26/26 → H. ustawienia/sterowanie → I. audio
> i zapis → J. optymalizacja i testy**. Szczegóły, bramki i zasady:
> [ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md](ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md).
> Późniejsza decyzja **zastępuje jedynie wykonawczą kolejność** („zadanie 9
> następne”) opisaną niżej jako historia. **Wszystkie 18 zadań, ich
> numery, zakresy i dotychczasowe procenty pozostają niezmienione.**
> Najbliższe do wykonania: **A. Menu, potem B. Wybór misji**.
> **06.11.2026 — IPA NA ŻĄDANIE WYDANE I SPRAWDZONE:**
> [GitHub Actions 42203939074](https://github.com/synixad-png/asteroidy-ios/actions/runs/42203939074)
> zakończony `success`, `ASTEROIDY_v568_W3_iPhone_iPad_UNSIGNED.ipa`
> (14 097 407 B, SHA256
> `ba0ab998837d6b769bb5ddfd2b027d712351dc6833390b80d12ab9a96b90ff2a`).
> Kompilacja fizycznego iOS ARM64, iPhone/iPad, 7 oryginalnych
> zasobów W3/Vanguard/H290 i CRC IPA — PASS.
> Potwierdzono hash ponownie po pobraniu pliku z GitHuba.
> **NIEPODPISANY:** niepotwierdzona instalacja na fizycznym iOS.
> Zobacz [raport wydania](Reports/V568_W3_IPA_RELEASE_2026-11-06.md).
> Snapshot wydania = `5242e4f`; dalsze commity nie znajdują się w IPA.
>
> **Etap A — GPU potwierdzone na iPhonie i iPadzie:**
> [GitHub Actions 42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165)
> oba joby `success`; NewHome290 516624 wierzchołków,
> oryginalny Vanguard431 194427 wierzchołków na iPadzie,
> zakończone komendy Metal i prawdziwe zrzuty. Po wydaniu IPA
> poszerzono *wyłącznie viewport* prawego podglądu statku
> ze 110 do 164 pt, nie zmieniając skali/siatki/animacji.
> Jest to kolejna wersja robocza, nie część wydanego IPA.
> Dotykowe 7 przycisków XCTest i porównanie oświetlenia
> 1:1 z Windows v568 nie są jeszcze zaliczone.
> Etap A **W TRAKCIE**, etap B jeszcze nierozpoczęty.
> **Zadanie 14: 10%, zmiana +0 pp; projekt 27%, pozostało 73%.**
>
> **Etap A, kolejny widoczny element (06.11.2026):** na podstawie
> źródłowego `GpuW3HomeReal333.cs` dodano do panelu HOME
> na iPadzie **oryginalny obracany statek Vanguard431**,
> zgodnie z domyślnym `Game.ShipType=1`. Nowy moduł
> `W3HomeShipPreview568.swift` korzysta z autentycznej
> siatki i tekstury w istniejącej paczce iOS, chronionych SHA256.
> Oddzielny shader W3 wykorzystuje źródłowy gładki
> Toon60, kamerę i rotację modelu. **Kompilacja iOS PASS**
> ([42202600804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202600804)).
> Realny test GPU podglądu statku i poprawionego światła planety:
> [42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165).
> Dotykowa nawigacja siedmiu przycisków:
> [42202807377](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202807377).
> **Wyniki obu wymagają potwierdzenia — nie uznawać ich za PASS
> dopóki nie zakończą się poprawnie**. Nie zmieniono
> zamkniętych mechanik 7/8 ani menu misji. **A nadal w trakcie,
> B nierozpoczęte; 14 = 10% (+0 pp), całe 27% / pozostaje 73%.**
> Bez IPA.
>
> **Kontynuacja testów W3 — najnowsza rewizja:** po dodaniu źródłowego
> podglądu statku Vanguard431 w menu testy interakcji zostały
> powiązane również z plikami podglądu statku, planety i
> kontraktu menu; zmiana tych plików wymusza XCTest iPhone/iPad.
> [Najnowszy test dotyku 42202753554](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202753554).
> [Test GPU 42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165).
> Nie zaliczać ich przed wynikami. Poprzedni test
> [42202329563](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202329563)
> zatrzymał się na preflight źródłowym, **nie na rzeczywistym dotyku**.
> Potwierdzona kompilacja iOS: job SUCCESS
> [42202600804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202600804).
> **A otwarte, B nierozpoczęte; zadanie 14: 10%, +0 pp;
> cały projekt: 27% / pozostało 73%. IPA nie generowano.**
>
> **Potwierdzony wynik etapu A — iPhone i iPad GPU PASS:**
> [workflow 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> zakończył oba symulatory wynikiem `success`.
> Natywna gra wyświetliła oryginalne logo i tło W3 oraz
> oryginalną planetę NewHome290 (172208 trójkątów), a Metal
> potwierdził wykonanie renderowania. Autentyczne obrazy:
> [iPhone](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493952002)
> i [iPad](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493651804).
> Oddzielne **testy siedmiu rzeczywistych dotknięć i powrotu**
> uruchomione w [workflow
> 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528).
> Nadal nie zaliczać etapu A przed wynikiem XCTest, porównaniem
> oświetlenia i potwierdzeniem pozostałych braków.
> **Nr 14: 10%, +0 pp. Projekt 27%, pozostało 73%. B jeszcze
> nierozpoczęte. Bez IPA.**
>
> **W3 — testy nawigacji (06.11.2026):** dodano natywny target
> `ASTEROIDYW3UITests` i dwie rzeczywiste próby XCTest
> na symulatorach iPhone/iPad: siedem dotykowych akcji W3 wraz z
> otwieraniem/zamykaniem paneli oraz wejście do diagnostycznej
> sceny 3D i powrót przez `MENU W3`.
> [Workflow 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528).
> Wyniki XCTest wymagają weryfikacji; nie oznaczać ich PASS,
> dopóki oba joby nie zakończą się sukcesem. Osobny
> [GPU/iPad 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> ma PASS na iPadzie, iPhone pozostawał w trakcie archiwizacji
> raportu. **A nadal w trakcie, B nierozpoczęte;
> zadanie 14: 10%, +0 pp; całość 27%, 73% pozostało.** Bez IPA.
>
> **Ostatni wynik kompilacji (06.11.2026):**
> [42198113777](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113777)
> potwierdził `Compile iOS source only — SUCCESS` dla
> wprowadzonej oryginalnej planety NewHome290 po naprawie
> macierzy normalnych w shaderze. Test faktycznego obrazu
> [42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> sprawdza oba symulatory Apple, oryginalne 5 zasobów W3/H290
> i dowód GPU. Nie zaliczać go przed zakończeniem. **A w trakcie;
> 14 nadal 10%, +0 pp; projekt 27% / pozostało 73%, bez IPA.**
>
> **Nowa implementacja etapu A (06.11.2026):** oryginalny model
> centralnej planety `NewHome290` v568, H290, **172208 trójkątów**,
> 516624 wierzchołków, dwie grupy materiałów i źródłowa mapa
> lawy zostały zaimplementowane w oddzielnym podglądzie Metal
> `W3HomePlanetMetal568.swift` / `W3HomePlanet290.metal`.
> Dodatkowo wdrożono obrót palcem i oryginalne wspólne tło/logo W3
> bez zmiany bajtów zasobów. Testy kompletnej grafiki Apple GPU i
> dotykowej nawigacji wciąż trwają, zatem **A niezamknięte**.
> Najnowszy [test iPhone+iPad
> 42197653964](https://github.com/synixad-png/asteroidy-ios/actions/runs/42197653964).
> Oświetlenie jest częściowym portem, a zgodność wizualna PC
> v568 nie została jeszcze wykazana. **Projekt 27%, pozostaje 73%,
> zadanie 14: 10%, +0 pp.** Bez IPA.
>
>
> **Aktualizacja implementacji 06.11.2026:** etap **A w trakcie**.
> Dodano natywny, obsługiwany dotykiem ekran W3 jako domyślne
> uruchomienie, 7 autentycznych etykiet z `RendererW3Home328.cs`,
> aktywne panele komunikujące rzeczywisty status funkcji,
> bezpieczny powrót do istniejącej sceny diagnostycznej i
> przycisk `MENU W3` w tej scenie. Kompilacja iOS dla wersji z menu
> w GitHub Actions **PASS** (`42193391940` oraz `42193674926`).
> Pierwszy autentyczny zrzut z obu symulatorów: workflow
> [42193792251](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
> — wynik należy sprawdzić osobno, nie uznawać oczekującego za PASS.
> Oryginalne tło/logo W3 i proceduralna planeta w menu są
> nadal brakujące; dotykowe przejścia end-to-end nieprzetestowane.
> **Postęp zadania 14: 10%, zmiana 0 pp, cały projekt 27%.**
> **Dalsza realizacja A:** dostępny oryginalny ZIP JPEG/PNG v568
> `ASTEROIDY_v568_W3_ORIGINAL_MENU_ASSETS.zip` (857501 bajtów)
> nie został jeszcze wgrany na GitHub; po wgraniu narzędzie
> `Tools/prepare_v568_w3_original_assets.py` automatycznie
> sprawdza SHA256 i dołącza dwa współdzielone obrazy W3 do aplikacji.
> Natywny SwiftUI `SourceW3Images568` już obsługuje prawdziwe
> obrazy i odrzuca zamienniki. Pierwsza próba screenshotu menu
> [42193792251](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
> nie zaliczyła instalacji iPhone przez timeout środowiska
> `simctl install` 85 s. Limit podniesiono do 300 s, a nowy
> [test obu symulatorów 42194736690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42194736690)
> został uruchomiony. Etap A nadal W TRAKCIE; procentów
> nie zwiększać przed dowodem rzeczywistych ekranów i nawigacji.

> Szczegółowe dowody i warunki zaliczenia:
> [ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md](ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md).


Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To zachowany wynik zbiorczy, bez ponownego ważenia 18 zadań. **Zadanie 7 — Kolizje, obrażenia i zniszczenia: 100% implementacji modułu, bez zmian. Zadanie 8 — Asteroidy i fale walki: 100% implementacji modułu (poprzednio 96%, +4 pp).** W oryginalnym kodzie C# v556 zweryfikowano `Game.Wave`, `Action38`, `Balance70`, `Physics68`, `AmigaBounce265` i `Game.Step`. Przeniesiono wytrzymałość i skalę skał, w tym +1 HP dla Coop62, kolejność wygasania odłamków/ruchu/posiłków/kolizji/strzałów, ostrzeżenie o posiłkach 1.6 s, 3 fale 16-sekundowe i specyficzną niezniszczalną mechanikę odbijanych kul sektora 25. **Swift/Linux: 25/25 zestawów PASS w GitHub Actions `42049818376`, commit `74fe326e1db29daac94e93a7ef8a906d327adefb`; uwzględniono regresję sektorów 9 i 17.** Osobna kontrola natywnej kompilacji Apple w tym przebiegu **czekała w kolejce** podczas raportowania — nie wolno twierdzić, że jej wynik PASS jest znany. iOS/Metal nie zostały interaktywnie sprawdzone na rzeczywistym urządzeniu (etap 18). **Nie utworzono IPA.** Zrealizowane zadania 7 i 8 podlegają regresji, nie rozpoczynać ich od nowa. Ponadto podłączono do interfejsu testowego iPhone'a sektory 1/9/17/25 przez `App.swift` i `MetalRenderer.swift`; ich wybór resetuje odrębny sektor, lot i diagnostyczny stan obrażeń bez ingerencji w kampanię. Natywne typowanie tej rewizji przez Xcode jeszcze oczekiwało na runner macOS. AI, bossowie, wszystkie bronie, komplet misji oraz kampania nadal należą do osobnych zadań 9–13.

**Aktualizacja zadania 1 — GitHub IPA:** użytkownik zlecił wygenerowanie niepodpisanego IPA. Workflow `build-ios.yml` uruchomiono poprzez commit `18e18797046dd37807650313990913dce38ab522`, [run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545). Faza Swift/Linux **PASS**, natywne `compile-device` w kolejce na macOS przy ostatnim sprawdzeniu. Bez sukcesu kompilacji i opublikowanego artefaktu nie należy deklarować dostępności IPA ani podwyższać zadania 1 do 100%. Po wdrożeniu i pomyślnym teście walidacji oryginalnych zasobów iOS stan zadania 1 wynosi **88% (poprzednio 85%, +3 pp)**; natywna kompilacja iOS oraz wynik IPA nadal pozostają do potwierdzenia.

**Aktualizacja zadania 2 — silnik Metal: 45% (poprzednio 40%, +5 pp).** Naprawiono źródłowo potwierdzoną rozbieżność z `SphereCombat67.cs:62` i `GpuSphere67.cs:414`: kamera sferyczna była obliczana, ale `MetalRenderer` rysował ze stałej kamery. `SphereCameraView556` przenosi wektory `SphereFocus67/Right67/Up67` i źródłową odległość oka `310/144.19674` w znormalizowanej skali; `MetalRenderer` wybiera dynamiczny widok tylko dla planety, `Ship.metal` liczy wektor BRDF od rzeczywistego oka. Arena płaska bez zmian. [Run 42052748443](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443) — test 8 pozycji i 240 kroków oraz parsing Swift **PASS**. Natywna kompilacja Xcode/Metal nowych zmian i wizualny test na urządzeniu nie zostały jeszcze wykonane. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Oddzielnie budowane IPA z `18e187970` nie zawiera tej późniejszej poprawki.


| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% |
| 2 | Silnik graficzny Metal | 89% |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% |
| 4 | Statki, planety i zasoby 3D | 20% |
| 5 | Animacje modeli GLB | 35% |
| 6 | Fizyka lotu i poruszanie po planetach | 35% |
| 7 | Kolizje, obrażenia i zniszczenia | 100% |
| 8 | Asteroidy i fale walki | 100% |
| 9 | Wszystkie bronie i efekty trafień | 10% |
| 10 | Przeciwnicy i sztuczna inteligencja | 0% |
| 11 | Bossowie i ich mechaniki | 0% |
| 12 | Komplet misji planetarnych | 5% |
| 13 | Kampania — 26 sektorów | 30% |
| 14 | Menu W3, HUD i ustawienia | 10% |
| 15 | Dźwięki i muzyka | 0% |
| 16 | Zapisywanie i wczytywanie gry | 20% |
| 17 | Sterowanie dotykowe i kontrolery | 35% |
| 18 | Optymalizacja i testy urządzeń | 10% |

## Weryfikacja

- Zadanie 7: moduły CombatVerifiedHit556, CombatTalentVitals78, CombatGuardian37, CombatVerifiedEncounter556 i PlanetDamageLab556; testy co-op, boss-body, robot collision i sekwencja obrażeń do respawnu.
- Testy: `Tests/CombatVerifiedEncounter556Tests.swift`, m.in. trzy życia, GameOver, dwaj gracze, obie gałęzie FailRescue, odzyskanie pełnego zdrowia po ratowaniu i dwa kontakty w jednej klatce przy wspólnych tarczach i strażniku — GitHub Actions Swift/Linux `42034275258` PASS. Nie wykonano kompilacji iOS/IPA dla tych zmian, zgodnie z poleceniem użytkownika.
- Oryginalne źródła C# oraz decyzje portowania udokumentowano w `AUDYT_GRA_V556_FAIL_RESCUE_SOURCE.md`. Domyślny konstruktor dwuosobowy włącza źródłowy tryb wspólnych zasobów; dawny tryb niezależny wymaga jawnego `independentDiagnosticCoop:true` i służy wyłącznie regresjom.
- Kompilacja kontrolna Xcode `build` w workflow `verify-combat-only.yml` sprawdza natywne źródła, ale **nie tworzy IPA**. Inny, celowo nieuruchamiany workflow `build-ios.yml` kompiluje oraz pakuje IPA.
- Wydanie testowe IPA z zakończonego przebiegu 42027976783 pochodzi z commita 596767b i nie obejmuje późniejszych zmian.


- Grywalna ścieżka Boreas: `PlanetDamageLab556` steruje oryginalnym `Tarcza145` przez przytrzymywanie w `App.swift`; `MetalRenderer` raportuje energię. Poprzednie kontrolne budowanie iPhoneOS zgłosiło `BUILD SUCCEEDED`, ale dotyczyło stanu przed zadaniem 8. Nie deklarować działania na urządzeniu bez jego testu.
- `CombatVerifiedEncounter556`: przy `devOpen` zgodnie z `Game.cs:234` zatrzymuje całą fazę walki i odracza rozliczenie ratowania; test regresji PASS.


**Weryfikacja źródłowych zasobów iOS:** dodano `Tools/verify_ios_inputs.py` i osobne `verify-ios-inputs.yml` (bez IPA). [Run 42053587593](https://github.com/synixad-png/asteroidy-ios/actions/runs/42053587593) — **PASS**: cztery autentyczne zasoby v556 zgodne SHA256 z historycznym manifestem, prawidłowe nagłówki `AS3D`/`ASMO`, 31 355 wierzchołków Boreas, 27 035 animowanych, 6 morph targetów i 126 klatek kluczowych, format bindingu, konfiguracja XcodeGen dla iPhone/iPad i nazwy wejść Metal. Ochrona hashy dotyczy **wyłącznie** tych czterech zasobów, nie zmieniającego się kodu Swift — nigdy nie nadpisywać manifestu bez audytu pochodzenia.

## Kontrola bieżąca — 05.11.2026

**Zadanie 1: 88% (bez zmiany).** Workflow publikacji niepodpisanego IPA `42051262545` przeszedł testy Swift/Linux, lecz pierwsza próba `compile-device` została **anulowana przed przydzieleniem runnera macOS**, bez kroków i bez logów kompilatora. Nie ma dowodów na błąd kodu; przyczyna anulowania nie jest potwierdzona. Ponowiono **wyłącznie anulowany job** przez GitHub Actions, co utworzyło próbę `run_attempt=2` tego samego przebiegu. Podczas ostatniego sprawdzenia `compile-device` nadal **queued**; opublikowane artefakty: **0**, IPA **niegotowe**. Nie uruchomiono nowego `build-ios.yml` na późniejszych commitach.

**Zadanie 2: 45% (bez zmiany postępu do czasu weryfikacji Apple Metal).** Po audycie oryginalnych `Orbit50.cs:32`, `GpuSphere67.cs:420` i `GpuIntro41.cs:455` wyeliminowano drugi problem renderera: duplikat macierzy widoku oraz błędne pionowe FOV `36°` w widoku planety zamiast źródłowych `53.1301°`. `SphereCameraView556.viewColumnMajor` jest wspólnym źródłem macierzy dla Swift/Linux i Metal; `SphereProjection556` wyznacza źródłowe pionowe FOV dla planety, bez zmiany płaskiej areny. [Run 42055630937](https://github.com/synixad-png/asteroidy-ios/actions/runs/42055630937): test macierzy, perspektywy i parsing Swift **PASS**. Xcode/Metal GPU po tych poprawkach nadal **niezweryfikowane**; nie deklarować kompletu iOS ani zwiększenia zadania 2 bez takiego testu. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.

**Kontrola IPA tylko na polecenie użytkownika:** użytkownik odwołał automatyczne sprawdzanie; harmonogram monitorowania IPA został **wyłączony**. Stan GitHub Actions i dostępność pliku należy sprawdzać wyłącznie po jego nowym, wyraźnym poleceniu. Nie ingeruje to w trwające zadania GitHub ani w sam projekt.

**Dalszy rozwój zadania 2 (45%, bez zawyżania):** w oparciu o bezpośrednie porównanie oryginalnego `Windows/src/GpuSphere67.cs:4,63,133–134,368` poprawiono modelowe osie statku i asteroid w `MetalRenderer`. `SphereSurfaceStamp556` odwzorowuje prawa/przód/normalna, przesunięcie `Shell67=HomeWorldOuterRadius523+15`, współczynnik `Scale67=Shell67/Sphere67.Radius`; modele dostają źródłowy `angle`, przechył i pochylenie, a sektor 25 radialny podskok. **PASS**: [GitHub Actions 42057687378](https://github.com/synixad-png/asteroidy-ios/actions/runs/42057687378), testy stempla w 8 punktach × 4 kierunkach, razem z kamerą i parsowaniem Swift. Nie twierdzić, że zmiana była już testowana w prawdziwym rendererze iPhone/Apple GPU. Wszystkie dane modeli, fizyka, kooperacja i kampania są nietknięte. Szczegóły: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. `Zadanie 1: 88%` i `zadanie 2: 45%` pozostają bez zwiększenia do czasu kolejnego potwierdzonego etapu.

**Aktualizacja najnowsza zadania 2 — niebo źródłowe, 05.11.2026:** **47% (poprzednio 45%, +2 pp)**. Na podstawie rzeczywistych `Windows/src/GpuAmbient37.cs:6–7` i `GpuIntro41.cs:25–26,452` odtworzono deterministyczny `SpaceHash207/SpaceRand207`, 1500 kierunków, wielkości i barw gwiazd oraz niebo związane z pozycją kamery w `MetalRenderer`; jeden statyczny bufor GPU zastępuje 1500 pojedynczych zgłoszeń. Odtworzono źródłowy `GpuSphere67.cs:420` kolor czyszczenia planety `(.012,.021,.04)`; płaska arena i jej wcześniejsze 130 gwiazd nie zostały zmienione. `Tests/SphereCameraView556Tests.swift` sprawdza niezależne, obliczone z oryginalnego uint-hash wartości i 1500 unormowanych kierunków. [GitHub Actions 42060152260](https://github.com/synixad-png/asteroidy-ios/actions/runs/42060152260) — **PASS** (Swift/Linux, parsing SwiftUI/Metal). Oryginalny `IntroHalo` z teksturowaną i przezroczystą poświatą, mgławice i promienie **NIE są jeszcze odtworzone**; GPU iPhone/Xcode nowych zmian **NIE testowano**. 47% jest oceną częściowej implementacji zgodnej z danymi źródłowymi, **nie** potwierdzeniem jakości grafiki na urządzeniu. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.

**Aktualizacja zadania 2 — nieprzezroczyste trójkąty zastąpione przez gwiazdy RGBA:** **48% (poprzednio 47%, +1 pp)**. W `MetalRenderer.swift` poprzednie 4500 wierzchołków trójkątów sky zamieniono na **1500 punktów GPU** z oryginalnymi z `GpuIntro41.cs` rozmiarami 0.7/1.4/2.8 px, paletą i przezroczystością. `Ship.metal` ma niezależne `skyPointVertex` i `skyPointFragment`, rozdzielone zgodnie z Metal Shading Language: `point_size` tylko w wyjściu vertex, `point_coord` z rasteryzatora. Nowy pipeline ma `sourceAlpha`/`oneMinusSourceAlpha` i **nie zapisuje głębi**, po narysowaniu nieba przywraca normalny pipeline PBR i depth test; płaska arena nietknięta. [GitHub Actions 42062234192](https://github.com/synixad-png/asteroidy-ios/actions/runs/42062234192) **PASS**: źródłowe testy Swift/Linux, odrębne statyczne testy kontraktu shaderów i parsowanie plików SwiftUI/Metal. Test statyczny **nie zastępuje kompilacji shaderów Apple Metal ani oględzin obrazu na iPhonie**. Autentyczny teksturowany `IntroHalo`, mgławice i promienie nadal **nie są odtworzone**. Wzrost o 1 pp wynika z wdrożenia przekazywania źródłowej alfy/rozmiaru i przetestowanego okablowania, nie z potwierdzonego wyglądu na GPU. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zawiera ograniczenia. **Nie sprawdzano IPA ani nie zmieniano automatyzacji** zgodnie z instrukcją użytkownika.

**Dokończenie skalowania gwiazd dla Retina (zadanie 2 bez zmiany 48%):** `GpuIntro41.cs:25–26` używa wzorca 720 px; w `SphereSky207.drawableScale`, `MetalRenderer` i `skyPointVertex` podano `height/720` z rzeczywistego `MTKView.drawableSize`. Efekt nie wymaga nowych buforów ani draw call. Testy 360/720/1440 px i przypadków nieprawidłowych oraz kontrakt danych GPU: [GitHub Actions 42062785842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42062785842) **PASS** (Swift/Linux, parsowanie Swift, kontrola statyczna MSL). 48% pozostaje, ponieważ nie przeprowadzono jeszcze właściwej kompilacji Metal ani testu obrazu na iPhonie. Rozmiary i alfa 1500 gwiazd zachowują dane oryginalnego `GpuIntro41.cs`; pełne źródłowe `IntroHalo` nadal nie jest przeniesione. Szczegóły w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Statusu IPA nie sprawdzano.

**Aktualizacja źródłowa zadania 2 — 52% (poprzednio 48%, +4 pp):** odnaleziono rzeczywisty ZIP oryginalnego ASTEROIDY v556 i sprawdzono `Windows/src/GpuAmbient37.cs:5–7`, `Gpu2DRenderer.cs:68,70,74`, `GpuIntro41.cs:23,451–452` i `GpuSphere67.cs:420`. W miejsce wcześniejszej przybliżonej maski punktowej `smoothstep` wprowadzono **dokładną generację tekstury 64×64 BGRA premultiplied StarTexture** z oryginalnego kodu, liniowe próbkowanie, źródłowe mieszanie `ONE/ONE_MINUS_SRC_ALPHA`, podstawowe średnice 2,8/5,6/11,2 px oraz dla gwiazd `rz>.87/.98` dodatkowe halo o średnicy 20/42 px z alfą 125/255. W jednym rysowaniu jest **1706 warstw dla 1500 źródłowych gwiazd** (1294 małe, 172 jasne, 34 bardzo jasne; 161 ciepłych). Osobna tekstura jest współdzielona; płaska arena i jej stary shader PBR są nietknięte. [GitHub Actions 42065903420](https://github.com/synixad-png/asteroidy-ios/actions/runs/42065903420): Swift/Linux + kontrakt shaderów **PASS**. Natywny `Xcode Metal/Swift compile-only` na macOS **czeka**; shader Metal nie jest jeszcze potwierdzony przez kompilator Apple ani testowany obrazowo na iPhonie. Ta zmiana zamyka **źródłowy port tekstury gwiezdnej i gwiezdnych IntroHalo**, ale **nie** cały `IntroSky` (mgławice, promienie, inne obiekty 2D) i nie zadanie 2 jako całość. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zawiera dokładne uzasadnienie, a stare opisy uproszczonych trójkątów są oznaczone jako stan historyczny. Procent 52% dotyczy prac implementacyjnych zweryfikowanych testami Swift/Linux, nie testów Apple GPU. **IPA nie sprawdzano**.

**Aktualizacja zadania 2 — Promienie słońca v556: 55% (poprzednio 52%, +3 pp).** Na podstawie realnych `Windows/src/GpuIntro41.cs:25,454` i `Windows/src/GpuCosmos39.cs:8–10` połączono z `MetalRenderer` poświaty słońca o promieniach 130/55/15 i pięć oryginalnych wachlarzy promieni (4×6 komórek, po 6 wierzchołków na komórkę), razem **738 wierzchołków**, bez animacji/losowych parametrów. `SphereSolarOverlay556` projektuje źródłowy kierunek `(0.6,0.8,0.32)*900` na ekran przez `SkyProject55` bez translacji oka, a renderer zmienia wyłącznie jednolity 16-bajtowy uniform, współdzieli teksturę `StarTexture` i wykonuje jedno rysowanie 2D przed planetą z premultiplikowaną alfą. Utrzymano dotychczasowy PBR i oddzielną płaską arenę. **PASS**: [GitHub Actions 42068464591](https://github.com/synixad-png/asteroidy-ios/actions/runs/42068464591), testy Swift/Linux geometrii i projekcji, statyczne testy shaderów, testy starszych mechanizmów kamery/gwiazd, parsowanie Swift. **Nie zaliczono jeszcze** natywnego Xcode/Apple Metal ani testów wizualnych GPU; zadanie `Xcode Metal/Swift compile verification ONLY (NO IPA)` było w kolejce, więc brak potwierdzenia kompilacji. W dalszym ciągu do przeniesienia zostały `DrawDeepSpace55/CloudLayer` (mgławice, planety tła, czarna dziura), opcje renderera i szersze efekty; brak udawania pełnego `IntroSky`. Szczegółowy audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Nie sprawdzano IPA.

**Aktualizacja zadania 2 — mgławice oryginalnego v556: 58% (poprzednio 55%, +3 pp).** Na podstawie rzeczywistych `Windows/src/GpuCosmos39.cs:4–7` oraz `GpuIntro41.cs:122,451` dodano `SphereNebula556` z dokładnym hashem 32-bit `CloudHash`, pięcioma oktawami `CloudNoise` i generacją premultiplikowanych tekstur **256×256**. W widoku planetarnym oryginał wykorzystuje dwie palety 0/1, współdzielone przez **24 dalekie + 12 bliższych warstw**, dlatego `MetalRenderer` tworzy tylko jedną 2-warstwową teksturę `MTLTextureType2DArray`, jedną niezmienną siatkę **216 wierzchołków** i jeden draw call GPU dla chmur przed gwiazdami/poświatami. `nebulaOverlayVertex` wykonuje `SkyProject55` w czasie renderowania, bez aktualizowania siatki i duplikowania pamięci. **PASS:** [GitHub Actions 42071274522](https://github.com/synixad-png/asteroidy-ios/actions/runs/42071274522) — testy Swift/Linux oryginalnych wyników hasha i pikseli BGRA, 36 warstw/projekcji, dotychczasowe testy kamery i słońca, kontrola statyczna połączeń shaderów oraz parsowanie Swift. **Wciąż brak** natywnego testu kompilatora Apple Metal, fizycznego iPhone'a oraz źródłowych planet głębokiego kosmosu i czarnej dziury z `DrawDeepSpace55`; poświaty nie gwarantują wierności obrazu 1:1. Nie zwiększono zadania 1 ani innych zadań. Kolejne prace pozostają w zadaniu 2; szczegółowy audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Status IPA zgodnie z poleceniem użytkownika **nie był sprawdzany**.

**Aktualizacja zadania 2 — czarna dziura v556: 61% (poprzednio 58%, +3 pp).** Bezpośrednio z oryginalnego `Windows/src/GpuIntro41.cs:62–127` przeniesiono trzy niezależne, generowane proceduralnie tekstury `BuildBlackHoleDisk55(false)`, `BuildBlackHoleCore55()`, `BuildBlackHoleDisk55(true)` po **640×640 BGRA/PArgb** każda. `BlackHoleSky55` zachowuje źródłowy obrót dysku 25°, oddzielny prześwit za rdzeniem, soczewkowanie oraz przedni pierścień; w jednym współdzielonym buforze tekstur Metal są **3 obrazy GPU**, generowane tylko raz. Jednym rysowaniem 60 wierzchołków rysuje **3 dodatkowe poświaty + 4 animowane promienie + 3 warstwy dysk/rdzeń/przód** w źródłowej kolejności. Poprawiono też wcześniejszą niezgodność `DrawDeepSpace55`: chmury są rysowane jako **24 dalekie → czarna dziura → 12 bliskich**, z tego samego współdzielonego bufora i 2 tekstur mgławic, bez nowych uploadów per klatka. Nadal **brakuje 3 planet tła**, więc obecna kolejność nie jest jeszcze pełnym oryginałem. **PASS**: [GitHub Actions 42074436010](https://github.com/synixad-png/asteroidy-ios/actions/runs/42074436010), `source-camera-linux` — wszystkie trzy wygenerowane tekstury i niezależne wartości pikseli, 10 warstw/projekcja, poprawne powiązania kodu Metal, regresje kamery/gwiazd/słońca/mgławic, parser Swift. **Nie wykonano jeszcze** natywnego testu Apple Metal/Xcode ani testu obrazu na fizycznym iPhonie; osobny `Xcode Metal/Swift compile verification ONLY (NO IPA)` oczekiwał na runner macOS. Zakres jest implementacyjny, bez deklaracji 100% zgodności wizualnej lub sprawdzenia wydajności; pozostałe 17 zadań i wynik zbiorczy 27% pozostają bez zmian. Szczegóły w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. **Nie sprawdzano IPA**.

**Aktualizacja zadania 2 — wszystkie trzy planety głębokiego kosmosu: 64% (poprzednio 61%, +3 pp).** Z rzeczywistych `Windows/src/GpuIntro41.cs:27–63,122–127` odtworzono `BuildDeepPlanet55(0,1,2)`: trzy różne obrazy **320×220**, dokładne wzory powierzchni `PlanetShade55`, źródłowe światła/pasma/chmury/blizny oraz oryginalne parametry pierścieni i refleksów GDI+. Każdy świat ma własną animację `AnimatedSkyDirection55`, ograniczenia projekcji `SkyProject55`, wymiary, maksymalną skalę i poświatę. `MetalRenderer` generuje trzy tekstury **tylko przy inicjalizacji**, przechowuje je we wspólnym `MTLTexture` trzywarstwowym i **ponownie wykorzystuje** istniejący premultiplikowany shader/pipeline czarnej dziury; trzy planety są rysowane **po 24 dalekich chmurach i przed czarną dziurą**, a 12 bliskich warstw zostaje po tych obiektach. **PASS:** [GitHub Actions 42077736535](https://github.com/synixad-png/asteroidy-ios/actions/runs/42077736535), `source-camera-linux` — 12 niezależnych kolorów referencyjnych, trzy pełne tekstury 320×220, PArgb, rzutowanie/animacja, kolejność rysowania i regresje kamery/gwiazd/słońca/mgławic/czarnej dziury. **Jawne ograniczenie:** GDI+ stosuje specyficzny antyaliasing elips i łuków — algorytm Swift odtwarza geometrię, ale wygładzenie pikseli pierścieni jest **przybliżeniem**, a nie kopią 1:1. Natywna kompilacja Xcode/Apple Metal i test na GPU iPhone'a dla bieżącego kodu nadal **niepotwierdzone**; procent 64% dotyczy sprawdzonej logiki źródłowej i połączeń, nie działającej gry na urządzeniu. Nie rozpoczynano zadania 3, zachowano pozostałych 17 procentów bez zmian; postęp zbiorczy **27% jest historycznym punktem odniesienia, nie nowym obliczeniem**. Szczegóły: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. **Statusu IPA nie sprawdzano.**

**Aktualizacja zadania 2 — odroczone tekstury v556: 65% (poprzednio 64%, +1 pp).** Oryginalne `GpuIntro41.DrawSkyPlanet55/DrawSkyBlackHole55` tworzą obrazy dopiero po pozytywnym `SkyProject55`, a `GpuCosmos39.CloudLayer` utrzymuje cache. Port iOS wcześniej tworzył trzy duże zasoby tekstur w `MetalRenderer.init`, nawet gdy działała tylko płaska arena. Dodano `SkyTextureGate55` i trzy cache opcjonalnych `MTLTexture` w `MetalRenderer`: **0 dużych alokacji w trybie płaskim**, planetę i czarną dziurę po raz pierwszy tworzy się wyłącznie po pozytywnym teście widoczności, chmury dopiero po źródłowym `SkyProject55` potwierdzającym widoczność przynajmniej jednej z 36 warstw podglądu sfery; wszystkie pozostają współdzielone i nie są wielokrotnie regenerowane. Przy błędzie alokacji jest czytelny `NSLog` i brak nieograniczonych ponownych prób. Odroczono tworzenie **6 284 288 B** nieskompresowanych danych BGRA8 (4 915 200 B czarna dziura + 844 800 B trzy planety + 524 288 B dwa motywy mgławic). **To nie jest pomiar VRAM ani FPS.** Zachowano źródłową kolejność renderowania, geometrię, wzory barw, kamery, shader PBR i moduły zadań 7/8. **PASS:** [GitHub Actions 42081362292](https://github.com/synixad-png/asteroidy-ios/actions/runs/42081362292), `source-camera-linux`: nowy test jednokrotnej alokacji, wszystkie poprzednie regresje oryginalnego nieba i kontrola statyczna wiązań Metal; natywna kompilacja Apple/Xcode i test fizycznego GPU nadal **niepotwierdzone**. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zaktualizowano. **Jednorazowy build IPA** zlecony przez użytkownika uruchomiono osobnym przebiegiem [42078976090](https://github.com/synixad-png/asteroidy-ios/actions/runs/42078976090) z commita `d475b114`, który według jedynej kontroli został przyjęty do kolejki. **Nie ma potwierdzenia gotowego IPA**; następnie kontynuowano implementację, więc nowe optymalizacje po tym commicie NIE znajdują się w jego snapshotcie. Nie uruchamiano drugiej kompilacji ani nie monitorowano dalej IPA. Łączny raportowany postęp 27% pozostaje punktem odniesienia, a pozostałe 17 zadań zachowuje poprzednie wartości.

## Aktualizacja zadania 2 — indywidualne ładowanie bitmap źródłowych, 05.11.2026

**Zadanie 2: 67% (poprzednio 65%, +2 pp).** Audyt bezpośrednio wskazuje, że oryginalne `GpuIntro41.DrawSkyPlanet55/BuildDeepPlanet55` i `GpuCosmos39.CloudLayer/NebulaTexture(theme)` inicjują **każdy** obraz oddzielnie przy pierwszej widoczności. Poprzedni port iOS co prawda odkładał utworzenie całej tablicy Metal do pierwszej widoczności, ale wtedy generował wszystkie trzy planety 320×220 i oba motywy mgławic 256×256, również niewidoczne.

- **Wdrożono:** `SkyTextureSliceCache55`, osobny stan gotowości każdego ze stylów 0/1/2 i motywów mgławic 0/1. `MetalRenderer.ensureDeepPlanetTextures55(style:)` generuje i przesyła pojedynczy obraz planety dopiero po źródłowym `DeepSkyPlanets55.project`. `ensureCloudTextures55(camera:)` sprawdza 36 kierunków `SphereNebula556.Layer.projected` i generuje wyłącznie widoczne motywy. Dane są przechowywane do końca życia renderera; nie ma wielokrotnego generowania dla widzianych wcześniej stylów.
- **Bez regresji architektury:** zachowano jedną teksturę tablicową Metal 3×320×220 i jedną 2×256×256, gotowe procedury generowania pikseli z v556, shadery `Ship.metal`, 24 dalekie chmury → trzy planety → czarna dziura → 12 bliskich chmur → gwiazdy/słońce, płaską arenę, etapy 7/8 i zasoby Windows/SteamOS. Nie zgłaszamy dodatkowej oszczędności VRAM: tablica GPU nadal rezerwuje rozmiar wszystkich warstw. Zysk dotyczy odroczenia **obliczeń i przesyłania bitmap** niewidocznych obiektów; nie ma pomiarów czasu klatki.
- **Testy:** lokalna kontrola izolowanej logiki Swift/Linux przeszła dla 6 permutacji widoczności planet i obu kolejności tematów mgławic, 240/720 ponownych odczytów oraz 14/14 kontroli kontraktu źródeł wykonanych na aktualnych plikach GitHub. Repozytoryjne testy `SkyTextureGate55Tests.swift`, `SkyTextureGateSourceContract55.py`, `DeepSkyPlanetsSourceContract556.py` i `NebulaSourceContract556.py` zostały rozszerzone.
- **Niepotwierdzone:** GitHub Actions `source-camera-linux` dla najnowszego commita oczekuje na runner; nie wolno przedstawiać go jako PASS. Natywna kompilacja Apple/Xcode/Metal, prawdziwe GPU, wizualna zgodność 1:1, FPS, VRAM oraz test na iPhone 15 Pro Max/iPad Pro M2 są nadal do wykonania. Nie uruchomiono kolejnego builda IPA ani nie sprawdzano jego wyniku.

**Łączny port: 27% (historyczny niezmieniony wskaźnik), pozostało 73%.** Zadanie 1: 88%, zadania 7 i 8: 100% implementacji każdego modułu, pozostałe zadania i stała lista 18 pozycji bez zmian. Następny zakres w otwartym zadaniu 2: doprowadzenie źródeł do natywnej kompilacji Apple, weryfikacja prawdziwego renderingu i pomiar GPU oraz naprawa wyłącznie potwierdzonych rozbieżności z v556.

## Aktualizacja zadania 2 — oryginalne near/far kamery Metal, 05.11.2026

**Zadanie 2: 68% (poprzednio 67%, +1 pp).** Kolejna bezpośrednio potwierdzona rozbieżność z kodem v556: `Windows/src/GpuIntro41.cs:455` i `GpuSphere67.cs:420` używają frustum `near=0.4`, `far=1600` w źródłowych jednostkach, a `Windows/src/GpuPlanetGltf463.cs` definiuje znormalizowaną skalę planety `100*1.4419674`. Poprzedni `MetalRenderer.perspective` używał dla **obu** kamer wartości `near=0.1,far=20` (ustawienie istniejącej płaskiej areny). To nie był oryginalny zakres depth clip dla sfery.

**Wdrożono wyłącznie w zadaniu 2:**
- `SphereProjection556.sourceFar=1600`, `normalizedNear=0.4/(100*1.4419674)`, `normalizedFar=1600/(100*1.4419674)` i `clipPlanes(spherical:)`. `MetalRenderer.perspective` pobiera obie płaszczyzny z tego samego źródła co znormalizowane modele i oko. Oryginalne 53.1301° FOV pozostaje, a płaska arena zachowuje **dokładnie** swoje dotychczasowe 0.1/20.
- `Tests/SphereCameraView556Tests.swift` sprawdza obie normalizacje, niezależny flat fallback, poprawne NDC z=0 na near i z=1 na far. Dodano `Tests/SphereProjectionSourceContract556.py` i test w workflow `verify-metal-camera.yml` **bez IPA**.
- Naprawiono wykryty błąd testu `Tests/SkyTextureGateSourceContract55.py`: kontrola porządku `project` przed `ensureDeepPlanetTextures55` wskazywała starą sygnaturę bez `style:`, mimo poprawnie zaktualizowanej implementacji. Dzięki temu test może realnie sprawdzać nową funkcję.

**Weryfikacja dostępna:** skompilowano i uruchomiono izolowany wycinek rzeczywistego nowego wzoru na Swift/Linux: znormalizowana sfera `near=0.002773988, far=11.095952`, płaska arena `near=0.1, far=20.0`, cztery granice NDC — **PASS**. Dodatkowe warunki źródłowe sprawdzono przez bezpośredni odczyt aktualnych plików GitHub. Natywna kompilacja Xcode/Metal, render na Apple GPU oraz test urządzeniowy **nie zostały potwierdzone**; nowe GitHub Actions mogą czekać w kolejce. Nie przedstawiać wycinka jako pełnego testu projektu.

**Granica zadania:** nie zmieniono żadnego C# Windows/SteamOS, zasad walki, mechanik zadań 7/8, formatów GLB, źródeł planet ani oddzielnego iPhone-only workflow. Łączny 27%/73% to nadal nieprzeliczany historyczny wskaźnik portu; pozostałe 17 wartości i pełna zatwierdzona lista nie ulegają zmianie. Zadanie 2 pozostaje **otwarte**; następny etap to natywna kompilacja Apple i przegląd rzeczywistego renderingu, bez udawania testów na fizycznym iPhonie.

## 05.11.2026 — iPhone + iPad, uruchamianie źródłowej sceny, audyt prawdziwej gry

- **Co wykonano:** `project.yml` zachowuje oryginalne `TARGETED_DEVICE_FAMILY: '1,2'`; dodano niezależny `build-ios-iphone-ipad-manual.yml` używający macOS Intel i walidacji IPA dla obu rodzin, uruchamiany **tylko ręcznie**. Nie odpalono nowego IPA. Przejściowy iPhone-only z run `42090319849` pozostaje wyłącznie poprzednim artefaktem iPhone.
- **Bieżące zadanie 2:** `App.swift` domyślnie kieruje do istniejącej oryginalnej sceny Boreas 3D zamiast 9-asteroidowej płaskiej areny testowej. Arena, testowe sektory 1/9/17/25, narzędzia diagnostyczne i atlas kampanii zachowano. Dwie zwarte linie przycisków ułatwiają przełączanie na obu urządzeniach. **To nadal testowa scena, a nie oryginalna pierwsza misja**.
- **Zweryfikowano:** GitHub run [42093245632](https://github.com/synixad-png/asteroidy-ios/actions/runs/42093245632) `original-assets` PASS: oryginalne zasoby i kontrakt domyślnej sceny/obu rodzin. Po zmianie workflow Xcode uruchomiono osobną weryfikację Apple `42093300828` **bez IPA**; wynik natywnego kompilatora i renderu urządzeniowego nie był jeszcze znany.
- **Źródła pełnej gry:** potwierdzono 150 MB archiwum użytkownika ASTEROIDY PC v568 (Windows+SteamOS). Właściwy `Game.Mode.Menu`, siedem przycisków W3 HOME, oryginalny 820-kamienny intro belt, wejście `StartCampaign/EnterOrbit50/LaunchOrbitMission50` są w C#. Repozytorium iOS ma jednak port wybranych mechanik v556; **nie utożsamiać go ze skończoną grą i nie zgadywać brakującego kontrolera misji**. Szczegóły w `AUDYT_RZECZYWISTEJ_GRY_IOS_V556_WOBEC_WINDOWS_V568.md`.
- **Następny krok:** domknięcie trwającego zadania 2: sprawdzenie rzeczywistej geometrii i sekwencji renderingu Metal oraz stopniowe wiązanie z oryginalnym rendererem i stanami gry. Nie rozpoczynać nowego zadania 14 ani nie deklarować uruchomienia misji przed integracją wymaganych modułów.
- **Zmiana postępu:** zadanie 1 **88% (0 pp)**, zadanie 2 **68% (0 pp)**, całość **27% (0 pp), pozostało 73%** — konfiguracja manualna i wstępny wybór sceny nie potwierdzają gotowości pełnej gry lub testu iPhone/iPad.

## 05.11.2026 — zadanie 2, NOWA SCENA: źródłowy przelot orbitalny 3D

**Postęp implementacyjny zadania 2: 70% (+2 pp wobec 68%).** Łączny wskaźnik odniesienia 27% (pozostało 73%) pozostaje bez zmian, ponieważ brak ponownego ważenia wszystkich zadań. Wszystkie pozostałe pozycje harmonogramu są bez zmian. Nowa scena nie oznacza ukończenia zadania 2 ani kompletnych misji.

**Wykonano rzeczywisty kod:**
- Nowy czysty Swift `ASTEROIDYiOS/IntroOrbit41.swift`: original `Windows/src/Intro41.cs:50–81`, 16 s, dokładny przebieg `Ship(t)`, `Camera(t)`, `CraftOrientation(t)`, `View`, oryginalny obrót planety 29+time*2.2°, źródłowa skala `MissionPlanetScale523(24)` normalizowana do 0,24.
- `OrbitWorld51.cs`: deterministyczny generator źródłowych **820 pozycji pasa asteroid**, seeded `Random(4109)`, wielkości, seed, kontrole wolnego korytarza kamery (4×81 próbek), reguły source cull. Uwzględniono **legacy** wariant pasa; gałąź `NewHome290.Enabled` w v568 zmienia położenia zgodnie z faktyczną geometrią terenu i nadal wymaga osobnego, zweryfikowanego portu. Nie udawać, że stary wariant = nowy teren.
- `MetalRenderer.swift` pokazuje inną, rozłączną scenę: źródłowy ruch kamery, 1 500 już przeniesionych gwiazd, oryginalny mesh Vanguard, prawdziwy model Boreas GLB w rozmiarze oryginalnego intro (a nie nowa kula), orbitalny pas 820 pozycji z frustum-cullingiem. W tej fazie siatki asteroid są tymczasowymi **oktaedrami** z portu, a wizualna skala statku oparta jest na sprawdzonym promieniu rzemiosła z walki; **oryginalne seed-specific `IntroStone`, `StoneNormal56`, pełne tło i efekty, oryginalny terrain-enabled belt wymagają jeszcze portu**.
- `App.swift` domyślnie pokazuje "PRZELOT ORBITALNY / ŹRÓDŁOWA KAMERA" z etykietą "SCENA ROBOCZA • NIE JEST PEŁNĄ MISJĄ", zegarem 0–16 s i przełącznikiem "BOREAS 3D"/"PRZELOT 3D". Istniejące testy sferyczne, osobna płaska arena, atlas 26 misji, zapis maski, mechaniki 7/8 zostały pozostawione; przelot **nie zalicza misji** i nie uruchamia sztucznej kampanii. Ponieważ prawdziwy kontroler misji nie istnieje, po 16 s przelot zapętla się jako podgląd.
- Konfiguracja `project.yml` i ręczny workflow `build-ios-iphone-ipad-manual.yml` nadal obsługują **oba urządzenia**, ARM64, iOS 17+, bez uruchamiania nowego IPA.

**Weryfikacja:** [GitHub Actions 42097505146](https://github.com/synixad-png/asteroidy-ios/actions/runs/42097505146), `source-camera-linux` PASS na źródłowej osi IntroScene41, 820 Belt51, kontraktach astronomii, kalibracji projekcji i kontroli regressions. [GitHub Actions 42097618493](https://github.com/synixad-png/asteroidy-ios/actions/runs/42097618493) PASS weryfikacji autentycznych zasobów, konfiguracji i parsowania zmienionego Swifta. `Xcode Metal/Swift compile verification ONLY (NO IPA)` dla najnowszego commita **nie zakończył się podczas raportowania**; nie ma dowodu pełnej kompilacji iOS ani testu Apple GPU. **Nowego IPA nie wygenerowano.**

**Następnie w zadaniu 2:** port oryginalnych `IntroStone` i `StoneNormal56` dla pasa, świateł/głębi/efektów intro z rzeczywistych źródeł, zgodność nowego `NewHome290` tam, gdzie ma zastosowanie; następnie kompilacja Xcode bez IPA. Dopiero po udanym buildzie można zgłosić użytkownikowi gotowość do *zlecenia* nowego unsigned IPA iPhone+iPad. Nie twierdzić, że scena jest 1:1 ani sprawdzona na urządzeniu.

## 05.11.2026 — kontynuacja zadania 2: źródłowe siatki IntroStone

Do nowej sceny `IntroOrbit41` dołączono `IntroRockGeometry41.swift` z oryginalnymi funkcjami `GpuIntro41.IntroStone`, `StoneNormal56`, `StoneFace` i `StoneSubdivide56` (20 ścian ikosaedru, 320/1280 trójkątów w zależności od rozmiaru, trzy kratery i odrębne seedy, kolory i normalne źródłowe). `MetalRenderer` tworzy szczegółowy model maksymalnie **jednej nowej widocznej skały na klatkę**, zachowuje do 256 modeli GPU i używa tymczasowego oktaedru wyłącznie do momentu utworzenia danego modelu. Celem jest uniknięcie jednorazowego obciążenia CPU/RAM przez 820 pełnych modeli, lecz **faktyczny koszt FPS i pamięci nie został zmierzony**.

`Tests/IntroRockGeometry41Tests.swift` sprawdza liczby wierzchołków, normalne i kolory. `Tests/IntroOrbitSourceContract41.py` pilnuje, czy renderer rzeczywiście korzysta z oryginalnej procedury i ma limit cache. Odrębny szybki preflight kodu Swift w [GitHub Actions 42098254707](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098254707) zakończył się PASS, natomiast pełna weryfikacja nowego generatora `42098229568` i kompilacja Xcode/Metal **nie były zakończone podczas ostatniego sprawdzenia**. Nie wpisywać PASS w testach geometrii na podstawie wyników starszych commitów. **Nie ma nowego IPA ani testu na prawdziwym iPhonie/iPadzie.**

Zmiana harmonogramu pozostaje **wyłącznie w zadaniu 2: 70% (+2 pp względem wcześniejszego 68%)**, projekt całościowo 27% (pozostało 73%). Wynik nie jest podnoszony za prace bez udanego testu geometrii. Następny krok: dokończyć aktualne testy i kompilację Xcode bez IPA, zachować oryginalne siatki oraz uzupełnić wymagane elementy wierności sceny. Powiadomienie o gotowości do zlecenia IPA jest monitorowane oddzielnie — dopiero po potwierdzonym sukcesie obu zadań CI.

## 05.11.2026 — wynik pełnego testu geometrii przelotu

W [GitHub Actions 42098229568](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098229568) zadanie `source-camera-linux` zakończyło się **PASS** po dodaniu szczegółowych asteroid: oryginalna geometria `IntroRockGeometry41` (320/1280 trójkątów), normalne, seedy, projekcja kamery, pas 820 skał oraz regresje dotychczasowych shaderów i geometrii. To weryfikacja wykonania kodu Swift na Linux, **nie** na GPU Apple. Drugi job `Xcode Metal/Swift compile verification ONLY (NO IPA)` w tym samym przebiegu nadal czekał na runner macOS. Szybki parser plików Swift i kontrola oryginalnych zasobów [42098254707](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098254707) również PASS. Brak testu iPhone/iPad oraz nowego IPA.

Za konkretną, wykonaną i przetestowaną geometrię indywidualnych skał postęp **zadania nr 2 wzrósł z 70% do 72% (+2 pp)**; od poprzedniej sesji raportowanej użytkownikowi 68% to łącznie **+4 pp**. Łączny historyczny postęp projektu nadal 27% (pozostało 73%), ponieważ nie przeważano zatwierdzonej listy zadań. Następna zależność: ukończenie kompilacji Apple Metal i weryfikacja pełnego 3D iOS przed świadomą próbą nowego IPA iPhone+iPad; stare IPA nie zawiera tej sceny.

## 05.11.2026 — kolejne funkcje i testy Metal, zadanie nr 2

**Zmiana zadania 2: 72% → 74% (+2 pp).** Wykonano i potwierdzono testami źródłowymi dwa konkretne elementy oryginalnego przelotu:
1. `GpuIntro41.CinematicIntro41`: pierścień 820 asteroid obraca się z dokładnym źródłowym `time*0.2°` wokół `IntroScene41.PlanetCenter`. Odcinanie niewidocznych skał używa pozycji **po** obrocie, zgodnej z macierzą Metal `T(center)*Ry(angle)*T(local)`. Nie zmieniono geometrii/kolizji trybu Boreas ani płaskiej areny.
2. Kompozycja źródłowego `GpuIntro41.IntroSky` w scenie orbitalnej: 24 dalekie chmury, 3 teksturowane planety, oryginalne dyski czarnej dziury, 12 bliskich chmur, 1500 gwiazd i 5 promieni słonecznych, w poprawnej kolejności. Wykorzystano istniejące zasoby/PSO i lazy texture cache z oryginalnego trybu sferycznego, lecz projekcję podłączono do `IntroScene41.View`, nie kamery walki.

**Potwierdzone testy:** [GitHub Actions 42100560721](https://github.com/synixad-png/asteroidy-ios/actions/runs/42100560721), `source-camera-linux` **SUCCESS** dla aktualnych plików kodu: matematyka kamery i obrotu, 820 pozycji, oryginalne siatki IntroStone, ochrona kolejności efektów i dotychczasowe mechanizmy sky. [GitHub Actions 42100472060](https://github.com/synixad-png/asteroidy-ios/actions/runs/42100472060) **SUCCESS**: parser Swift, autentyczne zasoby i preflight iPhone/iPad. `Xcode Metal/Swift compile verification ONLY (NO IPA)` w przebiegu 42100560721 **pozostawał w kolejce**, więc nie deklarować gotowego IPA ani testu GPU.

**Pozostało w zadaniu 2:** test natywnego Xcode na aktualnym źródle, rzeczywiste efekty światła i pogody/planety, materiały/tekstury wymagające odrębnych zadań 3–5, zgodność wersji z `NewHome290.Enabled` oraz weryfikacja jakości i FPS na prawdziwych urządzeniach (zadanie 18). Niezależna scena nadal jest podglądem, nie autentyczną pełną misją. Projekt według dotychczasowego zbiorczego wskaźnika odniesienia **27%**, pozostało **73%** — bez nowego ważenia stałej listy 18 zadań. Nie uruchamiano kompilacji IPA.

## 05.11.2026 — kolejna domknięta część zadania nr 2 (Metal 74→76%)

**Co wykonano:** Odtworzono brakującą animację oryginalnego modelu planety w scenie `IntroOrbit41` — `GpuIntro41.CinematicIntro41` wywołuje `DrawPlanetSolid` po ustawieniu `weatherTime65=IntroTime`, a `GpuPlanetGltf463` animuje glTF. Port `MetalRenderer.swift` teraz korzysta z jednego źródłowego `BoreasMorphRenderer556` dla obu kamer (intro: `IntroTime`, walka: dotychczasowy `planetAnimationTime`), zachowując zamrożone `MorphBufferSlots`, dynamiczny zakres siatki, częstotliwość 30 Hz i nienaruszone statyczne wierzchołki. Zmiana trybu i 16-sekundowe zawinięcie zegara wymuszają właściwą klatkę morfu, bez zamrażania po wyjściu z intro. Dodatkowo niezmienne 81 segmentów kamery/lotu z `OrbitWorld51.BuildBelt51` liczone jest raz i ponownie używane przy tworzeniu 820 źródłowych pozycji skał; seedy i algorytm pozostają bez zmian.

**Testy:** `source-camera-linux` [GitHub Actions 42102273792](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273792) **PASS**, w tym dodany kontrakt `Tests/IntroBoreasMorphSourceContract556.py`, test przebiegu 81 próbek i dotychczasowe testy źródłowe animacji/asteroid/rendererów; [preflight 42102273356](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273356) **PASS** dla pełnej składni Swift i zasobów. **Kompilacja Xcode/Metal nadal niepotwierdzona** — jej job w run 42102273792 pozostawał `queued`; bez IPA, bez interaktywnego testu Apple GPU i obu urządzeń.

**Postęp:** zadanie 2 — **76% (+2 pp względem poprzedniego raportu 74%)** za faktyczną implementację i testy regresji; zadania 1 i 3–18 bez zmian. Łączny dotychczasowy wskaźnik odniesienia **27%, pozostało 73%**, bez sztucznego zmieniania wag. Kod nie jest jeszcze pełną oryginalną misją, a v556 Boreas nie oznacza obsługi wszystkich planet v568.

**Co pozostało:** ukończenie natywnej kompilacji źródeł Xcode/Metal; następnie dalsza weryfikacja autentycznych efektów planety/atmosfery oraz skali i oświetlenia statku w cinematic, a później fizyczne testy sceny na iPhone i iPad. **Nie generować nowego IPA automatycznie** — tylko po poleceniu użytkownika i potwierdzeniu gotowości źródeł.

## 05.11.2026 — zadanie 2: oryginalna atmosfera 3D Boreas (76→78%)

**Wykonano i potwierdzono testami:**
- Port `Windows/src/GpuPlanet.cs:9–36`, źródłowa funkcja `AtmosphereVertex` i `DrawAtmosphere47`: **24 pierścienie × 96 segmentów × 2 trójkąty = 4608 trójkątów / 13824 wierzchołków**. Zachowano radialny profil `.058+.33*exp(-((r-1.055)/.125)^2)`, stopniowe wygaszenie przy promieniu 1,34, łuk 3D, skierowanie do prawdziwej kamery `IntroScene41` i kolory RGBA. Dla rzeczywistej `PlanetBoreas463` poziomu 5 użyto autentycznego `PlanetBiomes.cs:12` `Glow=0x95DBFF`; nie stosować tego koloru bez weryfikacji dla innych planet.
- `MetalRenderer.swift` rysuje teraz `IntroAtmosphere47.geometry()` **po GLB planety i po statku**, zgodnie z `Windows/src/GpuIntro41.cs:494`. Osobna konfiguracja blend `SRC_ALPHA,ONE_MINUS_SRC_ALPHA`, depth-test `.less`, **depth writes OFF**, brak PBR na tej półprzezroczystej powłoce. Nie zmieniono istniejącego opaque PBR, shaderów, animacji planety, pasa 820 asteroid ani trybów sferycznej i płaskiej walki.
- `Tests/IntroAtmosphere47Tests.swift` numerycznie sprawdza siatkę 13 824 wierzchołków, punkty kopuły, poziom alfa, profil jasności oraz bazę ortonormalną kamery (również bieguny). `Tests/IntroAtmosphereSourceContract47.py` pilnuje połączenia z prawdziwym Metal, kolejności planet→statek→atmosfera i stanu blend/depth.
- [GitHub Actions 42105492701](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105492701) `source-camera-linux` **SUCCESS**, w tym dwa nowe testy oraz wcześniejsza matematyka przelotu, siatki skał i animacja morfów. [GitHub Actions 42105503401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105503401) `original-assets` **SUCCESS** (zasoby, Swift frontend, kontrakty). Wyniki obowiązują tylko dla kodu, nie są potwierdzeniem wyglądu na iPhonie.
- **Aktualizacja zadania 2: 78% (+2 pp wobec 76%).** Pozostałe 17 zadań bez zmian; łączny dotychczasowy wskaźnik odniesienia **27%, pozostało 73%** (bez ponownego ważenia wszystkich zadań).

**Nadal pozostało:** natywna kompilacja Xcode/Metal na Apple, wierny dobór i dopasowanie geometrii/skali/tekstur statku i pozostałych światów z oryginału, pomiary wydajności GPU oraz testy interaktywne na iPhonie i iPadzie. Dla nowszych map nie udawać zgodności samej Boreas. Nowe IPA nie było budowane, a poprzedni artefakt iPhone-only nie zawiera najnowszej sceny.

## 05.11.2026 — testy i uporządkowanie kompilacji Apple, bez nowego IPA

Po zamknięciu implementacji atmosfery potwierdzono pełny `source-camera-linux` **SUCCESS** w [GitHub Actions 42105841484](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105841484) oraz `original-assets` **SUCCESS** w [42105503401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105503401); oba testują aktualną scenę orbitalną i mają źródłowe kontrakty `IntroAtmosphere47`. Poprzednio każdy commit weryfikacji `verify-metal-camera.yml` z `cancel-in-progress=true` anulował oczekujący w tym samym workflow job macOS. Oddzielono automatyczne source-only testy Linux od ręcznego Apple job, zachowując oryginalny `workflow_dispatch`. Aby realnie sprawdzić najnowszą źródłową scenę na kompilatorze Apple bez generowania IPA, uruchomiono jednorazowy niezależny workflow [42105890080](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105890080) dla `iPhone+iPad ARM64`, wyłącznie Swift/Metal. Ten job **nadal był queued** podczas ostatniego odczytu. Nie deklarować PASS Xcode, gotowego IPA ani testu na Apple GPU.

Stała lista 18 zadań i ich procenty bez zmian: zadanie 2 **78%**, łączny historyczny postęp **27%, pozostało 73%**. Następnie: wynik trwałego joba Xcode, audyt geometrii/tekstur/światła oryginalnego statku GLB z osobnym eksportem `Tools/export_vanguard.py` (ta konwersja nie jest wiernością materiałów PBR), sprawdzenie obrazów fizycznych urządzeń, a potem dalszy brakujący renderer bez przechodzenia do zadania 3 przed domknięciem 2. Nie generować IPA bez polecenia użytkownika.

## 05.11.2026 — kontynuacja zadania 2: Vanguard v4311 i źródłowa rotacja planety poziomu 5

**Realne wdrożenie:** `IntroVanguard431.swift` odtwarza lokalną skalę i środek modelu Vanguard na podstawie faktycznie wbudowanego w oryginalną grę PC `vanguard431.mesh.gz` (nagłówek `4311`, 194427 GPU wierzchołków) oraz `BakeInfo.json` i źródłowego GLB. Współczynniki *faktycznie używanego* modelu wynoszą `scale=3.265866381849069`, `center_glb.y=.18199390172958374`, podczas gdy zachowany `Vanguard556.as3d` eksportowano ze współczynnikiem `.32` i `centerY=.18`; dlatego przelot wykonuje `scale=(3.265866381849069/.32)/144.19674` oraz lokalne przesunięcie osi Z `(.18-.18199390172958374)*3.265866381849069/144.19674`. **Nie wymyślano nowego modelu i nie zmieniano źródłowego AS3D ani rozmiaru kolizji statku w trybie walki.** Zapis `Tools/bake_vanguard431.py` ma starszy współczynnik 2.88/0.12 i jest rozbieżny z *rzeczywistym* zasobem v568 — szczegóły w audycie.

**Druga źródłowa poprawka:** komputerowy `GpuPlanetGltf463.PlanetAssetBytes463` wczytuje Boreas wyłącznie przy `game.Level==5`. Wcześniejszy iOS obracał ten konkretny GLB według `PlanetRotation(level=1,t)`. Nowy `IntroOrbit41.boreasSourceLevel=5`, czyli rotacja `145+2.2*t` stopni, przy niezmienionych animacjach morfu i reszcie renderera.

**Weryfikacja:** [GitHub Actions 42108063917](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108063917) `source-camera-linux` zakończył się **SUCCESS** dla najnowszych testów numerycznych autentycznej geometrii/rozmiaru Vanguard, testów `Boreas level5` i wszystkich wcześniejszych testów skał, atmosfery, animacji, sky/PBR. [GitHub Actions 42108063893](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108063893) `original-assets` **SUCCESS**; dodatkowo wcześniejsza kompletna natywna kompilacja Apple [42105890080](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105890080) **SUCCESS** dotyczyła poprzedniej rewizji, a **nie** tych zmian. Dla obecnego kodu wykonano **nieanulowalne jednorazowe uruchomienie** [GitHub Actions 42108222094](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108222094), które testuje Xcode/Metal iPhone+iPad ARM64 bez IPA — `queued` podczas zapisu raportu. Nie deklarować natywnego PASS bieżącej rewizji przed jego rzeczywistym zakończeniem.

**Postęp zadania 2: 78% → 80% (+2 pp)** za konkretną korektę autentycznego modelu i prawidłowy obrót GLB z testami źródłowymi. Pozostałe 17 zadań i ich procenty niezmienione; historyczny wskaźnik całego projektu nadal **27%**, pozostało **73%** (wagi nie są przeliczane). **Braki wciąż istotne:** oryginalne UV/BaseColor/PBR modelu i źródłowe oświetlenie `FighterLight`, rzeczywisty wygląd na fizycznym iPhonie/iPadzie, optymalizacja pamięci/klatek, pełny kontroler misji/kampanii. IPA nadal nie zbudowano; status iOS powinien być potwierdzany z nowego przebiegu Xcode.

## 05.11.2026 — zadanie nr 2: plazma obu silników Vanguard v491 (80→82%)

**Co wdrożono:** prawdziwy `GpuShip.cs:19–63` z oryginalnej gry PC v568, dwie dysze ze źródłowego `vanguard431.mesh.gz` (wersja 4311), 3 warstwy × 3 płaszczyzny × 16 segmentów × 6 wierzchołków × 2 dysze = **1728 wierzchołków / 576 trójkątów**; oryginalne barwy biały–pomarańczowy–czerwony, okresowe fale, długość zależna od mocy silnika i przenikanie zgodne z `SRC_ALPHA,ONE`. Efekt liczony jest w osobnym shaderze `fighterPlasmaVertex491` przez `vertex_id`, bez nowego bufora geometrii per-frame. `MetalRenderer.swift`: statek GLB → 3D plazma obu dysz → źródłowa atmosfera 3D; zachowane oddzielne tryby gry, kolizje i trwałość buforów Boreas. Bez zgadywania położenia dysz.

**Testy źródłowe:** [42110230250](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110230250) `source-camera-linux` **PASS** oraz [42110230316](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110230316) preflight Swift/oryginalne zasoby **PASS**. `Tests/IntroEnginePlasma491Tests.swift` sprawdza 1728 wierzchołków, numeryczne stany czasu i mocy, oba rzeczywiste wyloty; `Tests/IntroEnginePlasmaSourceContract491.py` wiąże wszystkie wzory z shaderem i źródłową kolejnością rysowania. Starsze kontrakty nie mylą się już na współdzielonym depth state i wcześniejszych źródłowych overlayach Sky. 

**Natywny Apple:** dla dokładnego kodu z plazmą uruchomiono niezależny Xcode iPhone+iPad arm64 [42110465213](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110465213); ostatnio **queued**, brak kompletnej kompilacji w chwili zapisu raportu. Poprzedni PASS Xcode [42108222094](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108222094) obejmuje starszą rewizję BEZ tego nowego shadera — nie przedstawiać go jako potwierdzenia najnowszych zmian. Nowego IPA nie tworzono.

**Postęp:** zadanie 2 **82% (+2 pp)**; zadania pozostałe bez zmian, poprzedni historyczny całościowy wskaźnik **27%, pozostało 73%**, bez nieuzasadnionego przeważania. **Co pozostaje:** natywny PASS shadera Metal, źródłowe UV/tekstury/baseColor i `FighterLight(false)` Vanguard, następnie rzeczywisty test wyglądu i wydajności na iPhone + iPad, a później odtwarzanie całej misji. Nie deklarować ukończonej gry ani 100% zgodności.

## 05.11.2026 — kolejny zweryfikowany etap: źródłowe oświetlenie GpuToon60 (82→84%)

**Wykonano:** z bezpośredniego porównania `Windows/src/GpuShip.cs:10–16` i `Windows/src/GpuToon60.cs:29,34,64,279` w oryginalnym PC v568 ustalono, że Vanguard431 domyślnie korzysta z trzystopniowego shaderowego oświetlenia `BeginToon60(true,true)` przy `ToonEnabled60=true`, a nie z uproszczonego jednokierunkowego Cook–Torrance ani z dwuświatełkowego fixed-function fallback. Kierunek głównej lampy z `FighterLight(false)` to `(-.6,.8,1.4,w=0)` w eye-space. Dokładne źródłowe progi `0.25+0.33*smoothstep(.30,.32,d)+0.40*smoothstep(.70,.72,d)` i rim `.10*smoothstep(.72,.86,1-max(0,dot(N,V)))*smoothstep(.10,.30,d)` przeniesiono w `SourceFighterToon60.swift` i dedykowanym `sourceFighterToonFragment60` w `Ship.metal`. `MetalRenderer.swift` podaje rzeczywistą macierz `IntroScene41.View`, włącza ten PSO **tylko przy rysowaniu Vanguard**, a przed plazmą przywraca oryginalny pipeline. Bez ingerencji w planetę PBR, atmosferę, obie areny testowe i kolizje.

**Testy:** Swift/Linux `source-camera-linux` [42113405688](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113405688) **PASS**, preflight zasobów i składni [42113405405](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113405405) **PASS**. Testy obejmują numeryczne wartości progów i rim, eye-space `FighterLight`, ograniczenie PSO do statku i zachowanie pierwotnego PBR. Odrębna autentyczna kompilacja Apple [42113629084](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113629084) **SUCCESS**: Xcode Swift+Metal dla ARM64, `UIDeviceFamily={1,2}`, obecna domyślna scena przelotu z nowym shaderem i autentycznymi zasobami, `default.metallib` jest zbudowane. **Nie** wykonano fizycznego interaktywnego testu iPhone/iPad ani pomiaru GPU/FPS. **Nie tworzono IPA.**

**Uczciwy stan:** zadanie nr 2 **84% (+2 pp)**; inne 17 zadań bez zmian. Łączny dotychczasowy wskaźnik referencyjny **27%, pozostało 73%** (bez sztucznego przeliczania wag). Ponieważ kompilacja aktualnego źródła zakończyła się PASS, można na osobne polecenie uruchomić próbę ręcznego **unsigned IPA iPhone+iPad**, które wreszcie zawrze inną scenę niż płaska arena 9 asteroid. NIE nazywać jej skończoną pierwszą misją ani pełną grą.

**Wciąż brakuje** oryginalnych UV, tekstury `BaseColor` i pełnego materiału PC Vanguard. Obecne AS3D v1 zachowuje przybliżone kolory wierzchołków z wcześniejszym oświetleniem bake; nowe źródłowe pasma i rim są zgodne, ale obraz kadłuba nie jest 1:1. Konieczne są dalszy port realnych zasobów i weryfikacja na urządzeniach, później domknięcie zadania 2 przed przechodzeniem do 3–18.

## 05.11.2026 — zadanie nr 2: oryginalne UV i JPEG Vanguard, etap infrastruktury 84→85%

**Wykonano:** nowy parser `SourceVanguardMesh431.swift` dla autentycznego binarnego strumienia wersji 4311 `(x,y,z,nx,ny,nz,r,g,b,a,u,v)`; oryginalna siatka 194427 wierzchołków/64809 trójkątów w źródłowym układzie współrzędnych oraz rzeczywista mapa BaseColor 2048×2048 JPEG. Dodatkowy shader `sourceVanguardVertex431` + `sourceVanguardTexturedToonFragment431` w `Ship.metal` używa autentycznych UV bez V-flip, oryginalnego key light/GpuToon60, liniowej filtracji, mipmap i większej pamięci GPU `device`. `MetalRenderer.swift` wykrywa parę plików `Vanguard431Source.mesh` + `Vanguard431Base.jpg`, sprawdza ich SHA256 CryptoKit i rysuje źródłową, teksturowaną siatkę; **gdy binarek nie ma, dokładnie zachowuje poprzednią ścieżkę AS3D**. Zmiany nie dotykają kolizji, planet, plazmy, atmosfery i sterowania.

**Zasoby:** rzeczywiste dwa pliki binarne wyodrębniono z własnego ZIP PC v568 użytkownika, zweryfikowano sumy SHA256, oryginalną strukturę 4311, 194427 wierzchołków i fakt, że JPEG z runtime jest bajtowo identyczny z oryginalnym GLB. Udostępniono w rozmowie osobny ZIP zawierający dokładne bajty do `ASTEROIDYiOS/Assets`. Repozytorium GitHub **nie zawiera jeszcze tych dużych binarek** — funkcja materiałów jest więc gotowa w kodzie, lecz **nie będzie aktywna w nowym IPA bez dołączenia źródeł**. Pełne wymagania i importer `Tools/import_original_vanguard431.py`: [VANGUARD431_ORYGINALNE_ZASOBY_IOS.md](VANGUARD431_ORYGINALNE_ZASOBY_IOS.md). Nie udawać pełnej integracji.

**Testy:** [GitHub Actions 42120727178](https://github.com/synixad-png/asteroidy-ios/actions/runs/42120727178) Swift/Linux **SUCCESS** (parser i źródłowe kontrakty), [42120727204](https://github.com/synixad-png/asteroidy-ios/actions/runs/42120727204) preflight Swift/źródeł **SUCCESS**. Oddzielna, niezależna kompilacja natywna Apple [42121018526](https://github.com/synixad-png/asteroidy-ios/actions/runs/42121018526) **SUCCESS**, iPhone+iPad ARM64 i rzeczywiste shadery Metal; **bez nowego IPA, bez testu GPU na sprzęcie i bez zasobów źródłowych w repo**.

**Uzasadnienie wyniku:** zadanie 2 wzrosło **84%→85% (+1 pp)** wyłącznie za rzeczywistą kodową obsługę pierwotnej siatki i testy parsera/kompilacji; nie zaliczono importu tekstury w wydanej aplikacji. Pozostałe zadania 1 i 3–18 bez zmian; historyczny łączny wskaźnik odniesienia **27%, pozostało 73%**, bez przeważania listy. Dalej: rzeczywiste dodanie zweryfikowanych binarek do repo i ich runtime validation, porównanie GPU/JPEG na iPhonie/iPadzie, następnie brakujące efekty i dokończenie zadania 2, bez budowania niezmienionego IPA.

## 05.11.2026 — zadanie nr 2: potwierdzenie samplera źródłowego i bramka przyszłego wydania (85→86%)

**Co wykonano:** bezpośrednio porównano `Windows/src/GpuRenderer.cs:144–146` oryginalnego PC v568 z iOS. Potwierdzono `GL_RGBA8/GL_BGRA` (surowe UNORM, bez sprzętowego sRGB decode), `GL_CLAMP_TO_EDGE` i oba filtry `GL_LINEAR`, bez mipmap. W `Ship.metal` oraz `MetalRenderer.swift` poprawiono błędne `address::repeat`, `.SRGB:true` i `.generateMipmaps:true`; oryginalne UV bez V-flip pozostają. Odpowiada to źródłowemu samplingowi, nie obietnicy wizualnego 1:1.

**Przygotowano autentyczną paczkę aktywacji:** `Tools/prepare_vanguard431_assets.py` zna dokładną kompaktową paczkę `AssetsCompressed/Vanguard431_ORYGINALNE_UV_TEKSTURA_ZASOBY.zip` z tej rozmowy, a także odrzuca niekompletne/podmienione źródła, zanim zapisze jakąkolwiek binarkę aplikacji. Oryginalny ZIP użytkownika przechodzi CRC, SHA256, kontrolę formatu v4311 (194427 wierzchołków), 10802 trójkątów CPU i JPEG 2048² w lokalnym środowisku. `Tools/verify_original_vanguard_resources.py` wymusza te same prawdziwe dane przy standardowym przyszłym wydaniu. `Tools/verify_ipa.py` ma opcjonalną kontrolę rzeczywistej zawartości IPA `--require-vanguard-original`. Ręczny workflow `build-ios-iphone-ipad-manual.yml` wykonuje import i obie kontrole, domyślnie **odrzuca** nowe IPA pozbawione oryginalnego Vanguard. Starszy `AS3D` jest dostępny wyłącznie jako jawny wariant `compatibility_old_ship=true`. Poprzedni działający IPA pozostaje niezmieniony.

**Testy:** [42125357275](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125357275) Swift/Linux wszystkie testy źródłowe, w tym odrzucenie podmienionej/niepełnej paczki, **SUCCESS**; [42125348782](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125348782) Swift source/asset preflight **SUCCESS**; [42124960734](https://github.com/synixad-png/asteroidy-ios/actions/runs/42124960734) natywny Xcode Swift+Metal iPhone+iPad ARM64 z nowym samplerem **SUCCESS**. **Nie** przeprowadzono natywnego interaktywnego testu GPU/tekstury na fizycznych urządzeniach.

**Nierozwiązana zależność:** paczka binarna jest rzeczywiście w tej rozmowie, **ale nie jest obecna w publicznym repozytorium GitHub**. Testy źródłowe i Xcode kompilowały więc opcjonalną ścieżkę, lecz nie rysowały jeszcze rzeczywistej tekstury na iPhonie. Nie wolno deklarować pełnej funkcji ani budować nowego 'teksturami' IPA bez bezpośredniej integracji obu zweryfikowanych binarek. Dalszy krok: dodać kompaktową 3,53MB paczkę do `AssetsCompressed/` lub parę oryginalnych binarek do `ASTEROIDYiOS/Assets`, uruchomić realny build, zweryfikować zawartość IPA i potem test wyglądu i FPS.

**Postęp zadania 2:** **85% → 86% (+1 pp)** tylko za źródłową poprawkę i rygorystyczny, przetestowany proces wydawania; pozostałe pozycje 1 i 3–18 bez zmian. Łączny historyczny wskaźnik projektu **27%, pozostało 73%**, bez zmiany wag i bez naciągania gotowości.

## 06.11.2026 — domknięcie importu oryginalnego Vanguard431 w skompilowanej aplikacji (86→89%)

**Co zostało rzeczywiście wdrożone:**
- Użytkownik wgrał do `ASTEROIDYiOS/Assets` na `main` dwa oryginalne pliki PC v568: `Vanguard431Source.mesh` (**9 721 408 bajtów**) oraz `Vanguard431Base.jpg` (**1 275 318 bajtów**, 2048×2048). Oba pliki zweryfikowano według SHA-256 i Git blob SHA-1 wobec lokalnych źródeł, bez zamienników i pointerów LFS.
- `Tests/OriginalVanguard431InstalledAssetsTests.py` skanuje prawdziwy strumień **194 427** wierzchołków, ich normalne, RGBA i współrzędne UV oraz obie oryginalne dysze; nie jest to syntetyczna demonstracja modelu.
- `Tools/prepare_vanguard431_assets.py` obsługuje teraz **bezpośrednie umieszczenie zweryfikowanej pary w GitHubie** bez ponownego rozpakowywania ZIP. Uszkodzony lub częściowy upload odrzucany jest bez fallbacku niezgodnego z wydaniem teksturowanym. Test `Tests/PrepareVanguardPackTests.py` pokrywa ścieżkę pozytywną i negatywną.
- `Tools/verify_compiled_vanguard431_app.py` sprawdza już **rzeczywisty wynik kompilacji Apple**, a nie tylko źródłową listę plików: oryginalny mesh/JPEG wewnątrz `.app`, SHA-256, Info.plist `UIDeviceFamily=[1,2]`, fizyczny iOS arm64 Mach-O, iOS 17+ i `default.metallib`. Istniejący `MetalRenderer.swift` wybiera dokładną siatkę/UV i bazowy JPEG z oryginalnego modelu po przejściu własnego testu CryptoKit, zachowując dotychczasową ścieżkę AS3D jako fallback.

**Wykonane testy i wyniki:** [Source kamera i regresje 42168920268](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920268) **SUCCESS**; [preflight 42168920269](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920269) **SUCCESS**; [pełna natywna kompilacja Release z weryfikacją zasobów wewnątrz `.app` 42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848) **SUCCESS**. Logi kompilacji potwierdzają obecność obydwu oryginalnych binarek w gotowym `.app` i brak błędów SHA256. Żadnego IPA ani testu na fizycznym urządzeniu w tym etapie nie wykonywano.

**Uzasadniony postęp:** zadanie 2 **89% (+3 pp)** za ukończone faktyczne dostarczenie materiału i kontrolę natywnego `.app`; 17 pozostałych pozycji niezmienionych, łącznie historycznie **27%**, pozostało **73%** bez przeliczania wag. *Nie* stwierdzamy 100% renderer parity: brak interaktywnej kontroli koloru/UV/GPU/FPS na urządzeniu, źródłowego shaderowania całej gry i pełnych misji.

**Następny krok:** dokończyć zadanie 2 w zakresie rzeczywistych efektów i optymalizacji, a przy osobnym poleceniu wygenerowania IPA przygotować nowe niepodpisane wydanie iPhone+iPad już z rzeczywistym Vanguard431 oraz sprawdzić pliki wewnątrz IPA przed udostępnieniem. Nie zastępować wcześniej działającego IPA bez testu.

**Końcowa kontrola po zabezpieczeniu wydania:** nowa domyślna ścieżka iPhone+iPad wymaga oryginalnej siatki/tekstury, a ręczny `compatibility_old_ship=true` usuwa oba pliki **wyłącznie z tymczasowego checkoutu Github Actions** przed XcodeGen, dzięki czemu stary AS3D jest rzeczywiście używany tylko na wyraźny wybór. Test `ReleaseGateVanguard431Tests.py` zabezpiecza to zachowanie. Ostatni [preflight 42169385020](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169385020) **SUCCESS** oraz [pełne źródłowe testy regresji 42169384956](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169384956) **SUCCESS**. Natywna kontrola `.app` pozostaje **SUCCESS** z [42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848); po niej zmieniano wyłącznie skrypty i raporty, nie rendering. Nie uruchamiano nowego IPA.

## 06.11.2026 — zadanie 2: rzeczywisty smoke test grafiki ASTEROIDY w symulatorach iOS

**Wykonano:** dodano `Tools/verify_simulator_render_snapshot.swift` — natywny na macOS, rozpoznający rzeczywisty PNG z `xcrun simctl io screenshot`. Algorytm próbuje środkowej części własnego renderu, wymaga wielu różnych komórek RGB, wyraźnego zakresu jasności i odrzuca pusty/monochromatyczny obraz. Jego `--self-test` weryfikuje zarówno celowe odrzucenie jednolitego obrazu, jak i akceptację zmiennego wzorca testowego; wzorzec służy wyłącznie do testu detektora, **nie** jest przedstawiany jako ekran gry.

Dodano jednorazowy niezależny workflow [ASTEROIDY iOS genuine simulator 42169972297](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297). Uruchamia tylko **rzeczywistą aplikację ASTEROIDY z repozytorium użytkownika** i przygotowanymi wcześniej, potwierdzonymi oryginalnymi zasobami Vanguard431, w kolejności: sprawdzenie obu rzeczywistych zasobów, test detektora ekranu, rozpoznanie dostępnych simulatorów Apple, XcodeGen, kompilacja Debug `iphonesimulator`, próba instalacji i uruchomienia oryginalnego `com.synixad.asteroidyios` na iPhonie i iPadzie, zrzut ekranu z **prawdziwie uruchomionej aplikacji**, pomiar zróżnicowania pikseli i odczyt logu `ASTEROIDY: real PC Vanguard431 UV/BaseColor active: 194427 vertices`. Wymagany log nie pozwala uznać przypadkowego screenshotu systemu iOS lub starego AS3D za test nowej tekstury.

**Potwierdzone wyniki (stan ostatniej kontroli):** autentyczna para Vanguard431 i detektor PNG `--self-test` **PASS**; rozpoznanie prawdziwych iPhone+iPad runtime'ów Apple **PASS**; XcodeGen **PASS**; **kompilacja gry dla iOS Simulator PASS**. Etap `Boot REAL iPhone and iPad simulators, launch app and capture their genuine frames` **wciąż był in_progress** — NIE udowodniono jeszcze uruchomienia, logu źródłowej tekstury ani niepustych screenów. Dla natywnej fizycznej architektury iPhone+iPad ARM64 wcześniejszy [42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848) nadal **PASS** (zweryfikowane źródłowe zasoby wewnątrz skompilowanego `.app`), ale bez testu na fizycznym urządzeniu.

**Postęp pozostaje 89% zadania nr 2 (+0 pp), historyczny wynik zbiorczy 27%, pozostało 73%**, ponieważ samo uruchomienie testu nie potwierdza jeszcze wyniku obrazu. Pozostałe 17 zadań bez zmian. **Nowego IPA nie tworzono.** Wynik testu simulatorowego musi zostać odczytany z GitHub Actions i dokładnie sklasyfikowany jako PASS, FAIL albo brak danych; dopiero prawdziwy PASS może uzasadniać kolejny wzrost procentu.

## 06.11.2026 — rzeczywisty zrzut ASTEROIDY i nowa weryfikacja wykonania Metal Vanguard431

**Pierwsza udokumentowana klatka z faktycznie uruchomionego programu iOS:** [GitHub Actions 42169972297](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297) skompilował aplikację Swift+Metal na Apple iOS Simulator, uruchomił rzeczywisty `com.synixad.asteroidyios` na symulatorze iPhone 16 i wykonał prawdziwy screenshot `IPHONE_real_app.png` o wymiarach **750×1334**. Niezależny detektor RGB stwierdził **326 zróżnicowanych komórek koloru** i zakres luminancji **0,950** (niepusty obraz). Zrzut dokumentuje prawdziwy przelot orbitalny: planetę, obiekty pasa, teksty interfejsu i statek Vanguard. **Nie** jest to ilustracja koncepcyjna ani ekran cudzej aplikacji.

**Pierwszy test nie przeszedł pełnego gate'u.** W środowisku hostowanego CoreSimulator ujednolicony `log show` nie zwrócił wpisu `NSLog` o aktywacji `Vanguard431 UV/BaseColor`. Sama nieobecność w logach systemowych NIE dowodzi, że źródłowa tekstura się nie wyświetla; screenshot również nie dowodzi jeszcze pełnej zgodności tekstury z oryginałem PC. Test nie dotarł do iPada. Artefakt z oryginalnym zrzutem i logami: [42169972297 / artifacts](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297).

**Drugi test ustalił konkretną przyczynę problemów bootowania:** [42171861687](https://github.com/synixad-png/asteroidy-ios/actions/runs/42171861687) poprawnie wykonał Apple iOS Simulator build, ale zatrzymał się na `simctl bootstatus` z kodem **75 — INCONCLUSIVE ENVIRONMENT**, po 125 sekundach. W poprzednim przebiegu faktyczne uruchomienie symulatora trwało około 7–8 minut; krótszy timeout był niewystarczający. Nie klasyfikować tego wyniku jako błędu shaderów ASTEROIDY.

**Nowe wykonane rozwiązanie:** `MetalRenderer.swift` ma włączaną WYŁĄCZNIE przez `SIMCTL_CHILD_ASTEROIDY_RENDER_VERIFY=1` diagnostykę rzeczywistego wywołania źródłowego GPU `sourceFighterTexturedPipeline431`. Po wywołaniu `drawPrimitives(vertexCount=194427)` i po **zakończeniu bufora komend Metal** z `finished.status==.completed` program zapisuje testowy `Library/Caches/ASTEROIDY_Vanguard431_RenderProof.json` we własnym kontenerze. Zawiera prawdziwą liczbę wierzchołków, rozmiar źródłowej tekstury GPU, znane SHA-256 siatki/JPEG, `bundleID`, faktyczne powodzenie polecenia GPU i nazwę PSO. Nie zależy od globalnego `NSLog` ani od wizualnej interpretacji zdjęcia. Domyślna działająca gra nie zapisuje diagnostyki i ma niezmienione UI oraz mechanikę.

`Tools/run_original_ios_simulator_capture.py` teraz odczytuje dowód bezpośrednio z `simctl get_app_container`, waliduje WSZYSTKIE pola przeciw źródłowym oczekiwaniom i oznacza obraz jako `VERIFIED_ASTEROIDY_source431` wyłącznie po **obu** wynikach: prawdziwe niepuste RGB + `gpuCommandBufferCompleted=true` z oryginalną teksturą. Twarde limity czasu procesów i całych grup chronią przed zawieszeniem CoreSimulator, a `--only IPHONE / IPAD / BOTH` pozwala rozstrzygać każde urządzenie osobno. `Tests/SimulatorSmokeHarnessTests.py` testuje wersje prawdziwych i fałszywych rekordów GPU i kontroluje zgodność plików; `Tests/SourceVanguardTextureContract431.py` chroni kolejność oryginalnego draw → GPU handler → `command.commit`.

**Status bieżącej, niezależnej weryfikacji GPU:** [42173321151](https://github.com/synixad-png/asteroidy-ios/actions/runs/42173321151) jest uruchomiona dla iPhone’a ze źródłowym shaderem i dowodem zakończonego renderowania. Przez poprawioną politykę nie uznajemy symulatorowego GPU za natywny iPhone ani za wizualną zgodność 1:1. **Nie wygenerowano nowego IPA** i nie podmieniono wcześniej działającej wersji. Zadanie nr 2 pozostaje **89% (zmiana 0 pp)** do prawdziwego zaliczenia testu źródłowego GPU; ogólny odniesieniowy wskaźnik **27% / pozostało 73%** i pozostałe 17 zadań bez zmian.

## Kolejność dalszej pracy

1. **Zadanie 7 — zamknięte implementacyjnie (100%)**, zachować wszystkie zweryfikowane mechanizmy i regresje.
2. **Zadanie 8 — zamknięte implementacyjnie (100%)**, nie zmieniać źródłowej fizyki asteroid, `Balance70`, `Action38`, sterowania falami i `AmigaBounce265` bez konkretnej, zweryfikowanej rozbieżności. Audyt: `AUDYT_ZADANIE_8_v556_ASTEROIDY.md`.
3. Następne w harmonogramie jest **zadanie 9 — Wszystkie bronie i efekty trafień (10%)**. Nie wykonywano go w tej sesji.
4. Natywne testy dotykowe, wydajności i obrazu na fizycznym iPhone/iPad pozostają częścią zadania 18; bieżące 100% zadań 7 i 8 odnosi się do kodu oraz przeprowadzonych testów automatycznych, nie do pełnego testu produktu na urządzeniu.

## Weryfikacja zamknięcia zadania 7

- Oryginalne `Physics68.cs:31–45`: odpowiedź kontaktu; `Physics68.cs:50–59`: obroty tylko rock/rock; `Physics68.cs:33–37`: odrzucenie szerokości tylko dla kanonicznych Y.
- `SphereRockContact68`, `CombatSolids68`, `SphereSector556`: poprawiony brak spin po ship/rock, bug/rock i boss/rock; zachowany spin po rock/rock i rzeczywista fizyka sferyczna.
- `CombatVerifiedEncounter556`, `CombatVerifiedHit556`, `CombatRescue65`, `CombatRespawn556`: życie, tarcze, guardian, opancerzenie, kolizje, coop, ratowanie i odrodzenie.
- `PlanetDamageLab556`, `MetalRenderer`, `App.swift`: grywalna ścieżka z obrażeniami, wizualizowanym HUD kadłuba/pancerza/tarczy i momentowym wejściem tarczy.
- `SphereSector556`: podział skał, 18 ostatnich odłamków, punktacja i bezpieczne przebiegi kolizji; funkcje AI/bossów i misji nie są tu fikcyjnie tworzone.
- Testy Swift/Linux: GitHub Actions `42042348199`, **25/25 uruchomionych zestawów PASS**. Natywny kompilator Apple: `42040847979` zawiera `BUILD SUCCEEDED`, ale cały job FAIL wskutek niepoprawnej ścieżki testu istnienia produktu o nazwie `ASTEROIDY iOS.app` — poprawiono. Brak testu fizycznego iPhone'a i brak IPA.

## Weryfikacja zamknięcia zadania 8

- **100% implementacji zadania 8** (96% → 100%, +4 pp): źródłowa fizyka asteroid, zasady napływu fal, sferyczne zdrowie/rozmiar, trzy fale 16-sekundowe i pokaz `AmigaBounce265` sektora 25.
- Nowa integracja `App.swift` + `MetalRenderer.swift`: wybór testowego sektora **1, 9, 17 lub 25**. To wciąż podgląd/test, **nie** oznacza ukończonej kampanii ani misji.
- **25/25 testów Swift/Linux PASS**, GitHub Actions `42049818376`, commit `74fe326e1db29daac94e93a7ef8a906d327adefb`, w tym regresja inicjalizacji 9 i 17 i osobny test 850 kroków fizyki sektora 25.
- Kontrolna kompilacja iOS/Metal przez Xcode dla aktualnego kodu **oczekuje na macOS runner GitHub Actions**. Nie deklarować PASS ani natywnego testu iPhone'a bez wyniku. Test na fizycznym urządzeniu jest w zadaniu 18.
- Źródła i szczegółowe porównanie C#↔Swift: `AUDYT_ZADANIE_8_v556_ASTEROIDY.md`. Nie wykonywano zadania 9, nie generowano IPA.

## Tryb bez IPA — polecenie użytkownika

Do kolejnej wyraźnej zgody użytkownika nie tworzyć, nie pakować ani nie udostępniać IPA. Workflow `.github/workflows/verify-combat-only.yml` przeprowadza testy Swift/Linux i osobną, kontrolną kompilację natywnych źródeł przez Xcode **bez archiwizacji, IPA i przesyłania artefaktów**. Workflow `build-ios.yml` generuje IPA i nie może być uruchamiany bez polecenia użytkownika.

**Aktualizacja dostarczenia 06.11.2026:** nowy zweryfikowany IPA
(14 103 697 B, SHA256
`9b16daf6e045220140505ebbed99cf24befadbea8c0b7b2d8a1080df7b5c98ce`)
jest na [prywatnym Dysku Google jako bezpośredni plik IPA](https://drive.google.com/file/d/1SFMg2sOZFvhL3IAwSu_t8JO-BJU4TX5i/view?usp=drivesdk).
To nie jest tylko ZIP z artefaktu; kopia ZIP z raportami jest
dostępna niezależnie. Plik jest niepodpisany i nieprzetestowany
na fizycznym urządzeniu. Etap A pozostaje otwarty do testów
nawigacji, etap B nierozpoczęty. **Postęp bez zmian: 27%,
pozostało 73%, zadanie nr 14 10% (+0 pp).**
