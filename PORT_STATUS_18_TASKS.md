# ASTEROIDY iOS — stały harmonogram portowania

Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To zachowany wynik zbiorczy, bez ponownego ważenia 18 zadań. **Zadanie 7 — Kolizje, obrażenia i zniszczenia: 100% implementacji modułu, bez zmian. Zadanie 8 — Asteroidy i fale walki: 100% implementacji modułu (poprzednio 96%, +4 pp).** W oryginalnym kodzie C# v556 zweryfikowano `Game.Wave`, `Action38`, `Balance70`, `Physics68`, `AmigaBounce265` i `Game.Step`. Przeniesiono wytrzymałość i skalę skał, w tym +1 HP dla Coop62, kolejność wygasania odłamków/ruchu/posiłków/kolizji/strzałów, ostrzeżenie o posiłkach 1.6 s, 3 fale 16-sekundowe i specyficzną niezniszczalną mechanikę odbijanych kul sektora 25. **Swift/Linux: 25/25 zestawów PASS w GitHub Actions `42049818376`, commit `74fe326e1db29daac94e93a7ef8a906d327adefb`; uwzględniono regresję sektorów 9 i 17.** Osobna kontrola natywnej kompilacji Apple w tym przebiegu **czekała w kolejce** podczas raportowania — nie wolno twierdzić, że jej wynik PASS jest znany. iOS/Metal nie zostały interaktywnie sprawdzone na rzeczywistym urządzeniu (etap 18). **Nie utworzono IPA.** Zrealizowane zadania 7 i 8 podlegają regresji, nie rozpoczynać ich od nowa. Ponadto podłączono do interfejsu testowego iPhone'a sektory 1/9/17/25 przez `App.swift` i `MetalRenderer.swift`; ich wybór resetuje odrębny sektor, lot i diagnostyczny stan obrażeń bez ingerencji w kampanię. Natywne typowanie tej rewizji przez Xcode jeszcze oczekiwało na runner macOS. AI, bossowie, wszystkie bronie, komplet misji oraz kampania nadal należą do osobnych zadań 9–13.

**Aktualizacja zadania 1 — GitHub IPA:** użytkownik zlecił wygenerowanie niepodpisanego IPA. Workflow `build-ios.yml` uruchomiono poprzez commit `18e18797046dd37807650313990913dce38ab522`, [run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545). Faza Swift/Linux **PASS**, natywne `compile-device` w kolejce na macOS przy ostatnim sprawdzeniu. Bez sukcesu kompilacji i opublikowanego artefaktu nie należy deklarować dostępności IPA ani podwyższać zadania 1 do 100%. Po wdrożeniu i pomyślnym teście walidacji oryginalnych zasobów iOS stan zadania 1 wynosi **88% (poprzednio 85%, +3 pp)**; natywna kompilacja iOS oraz wynik IPA nadal pozostają do potwierdzenia.

**Aktualizacja zadania 2 — silnik Metal: 45% (poprzednio 40%, +5 pp).** Naprawiono źródłowo potwierdzoną rozbieżność z `SphereCombat67.cs:62` i `GpuSphere67.cs:414`: kamera sferyczna była obliczana, ale `MetalRenderer` rysował ze stałej kamery. `SphereCameraView556` przenosi wektory `SphereFocus67/Right67/Up67` i źródłową odległość oka `310/144.19674` w znormalizowanej skali; `MetalRenderer` wybiera dynamiczny widok tylko dla planety, `Ship.metal` liczy wektor BRDF od rzeczywistego oka. Arena płaska bez zmian. [Run 42052748443](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443) — test 8 pozycji i 240 kroków oraz parsing Swift **PASS**. Natywna kompilacja Xcode/Metal nowych zmian i wizualny test na urządzeniu nie zostały jeszcze wykonane. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Oddzielnie budowane IPA z `18e187970` nie zawiera tej późniejszej poprawki.


| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% |
| 2 | Silnik graficzny Metal | 45% |
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
