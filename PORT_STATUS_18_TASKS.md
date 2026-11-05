# ASTEROIDY iOS — stały harmonogram portowania

Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To zachowany wynik zbiorczy, bez ponownego ważenia 18 zadań. **Zadanie 7 — Kolizje, obrażenia i zniszczenia: 100% implementacji modułu, bez zmian. Zadanie 8 — Asteroidy i fale walki: 100% implementacji modułu (poprzednio 96%, +4 pp).** W oryginalnym kodzie C# v556 zweryfikowano `Game.Wave`, `Action38`, `Balance70`, `Physics68`, `AmigaBounce265` i `Game.Step`. Przeniesiono wytrzymałość i skalę skał, w tym +1 HP dla Coop62, kolejność wygasania odłamków/ruchu/posiłków/kolizji/strzałów, ostrzeżenie o posiłkach 1.6 s, 3 fale 16-sekundowe i specyficzną niezniszczalną mechanikę odbijanych kul sektora 25. **Swift/Linux: 25/25 zestawów PASS w GitHub Actions `42049818376`, commit `74fe326e1db29daac94e93a7ef8a906d327adefb`; uwzględniono regresję sektorów 9 i 17.** Osobna kontrola natywnej kompilacji Apple w tym przebiegu **czekała w kolejce** podczas raportowania — nie wolno twierdzić, że jej wynik PASS jest znany. iOS/Metal nie zostały interaktywnie sprawdzone na rzeczywistym urządzeniu (etap 18). **Nie utworzono IPA.** Zrealizowane zadania 7 i 8 podlegają regresji, nie rozpoczynać ich od nowa. Ponadto podłączono do interfejsu testowego iPhone'a sektory 1/9/17/25 przez `App.swift` i `MetalRenderer.swift`; ich wybór resetuje odrębny sektor, lot i diagnostyczny stan obrażeń bez ingerencji w kampanię. Natywne typowanie tej rewizji przez Xcode jeszcze oczekiwało na runner macOS. AI, bossowie, wszystkie bronie, komplet misji oraz kampania nadal należą do osobnych zadań 9–13.

**Aktualizacja zadania 1 — GitHub IPA:** użytkownik zlecił wygenerowanie niepodpisanego IPA. Workflow `build-ios.yml` uruchomiono poprzez commit `18e18797046dd37807650313990913dce38ab522`, [run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545). Faza Swift/Linux **PASS**, natywne `compile-device` w kolejce na macOS przy ostatnim sprawdzeniu. Bez sukcesu kompilacji i opublikowanego artefaktu nie należy deklarować dostępności IPA ani podwyższać zadania 1 do 100%. Po wdrożeniu i pomyślnym teście walidacji oryginalnych zasobów iOS stan zadania 1 wynosi **88% (poprzednio 85%, +3 pp)**; natywna kompilacja iOS oraz wynik IPA nadal pozostają do potwierdzenia.

**Aktualizacja zadania 2 — silnik Metal: 45% (poprzednio 40%, +5 pp).** Naprawiono źródłowo potwierdzoną rozbieżność z `SphereCombat67.cs:62` i `GpuSphere67.cs:414`: kamera sferyczna była obliczana, ale `MetalRenderer` rysował ze stałej kamery. `SphereCameraView556` przenosi wektory `SphereFocus67/Right67/Up67` i źródłową odległość oka `310/144.19674` w znormalizowanej skali; `MetalRenderer` wybiera dynamiczny widok tylko dla planety, `Ship.metal` liczy wektor BRDF od rzeczywistego oka. Arena płaska bez zmian. [Run 42052748443](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443) — test 8 pozycji i 240 kroków oraz parsing Swift **PASS**. Natywna kompilacja Xcode/Metal nowych zmian i wizualny test na urządzeniu nie zostały jeszcze wykonane. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Oddzielnie budowane IPA z `18e187970` nie zawiera tej późniejszej poprawki.


| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% |
| 2 | Silnik graficzny Metal | 48% |
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
