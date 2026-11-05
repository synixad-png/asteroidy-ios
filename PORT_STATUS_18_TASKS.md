# ASTEROIDY iOS — stały harmonogram portowania

Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** Zachowany wynik zbiorczy, bez zmiany wag innych zadań. **Zadanie 7 — Kolizje, obrażenia i zniszczenia: 100% IMPLEMENTACJI MODUŁU (poprzednio 97%, +3 pp; 0% prac implementacyjnych pozostałych w zakresie modułu)**. Kod porównano z oryginalnym `Windows/src/Physics68.cs`, `Game.cs`, `Gameplay65.cs`, `Coop62.cs`, `Tarcza145.cs`, `Talents78.cs` i `BossTunnelGame.cs` v556. Dokończono poprawki: obroty skał wyłącznie po rock/rock, brak błędnego szybkiego odrzucania niekanonicznych punktów, rozliczenie obrażeń/ratowania i wspólne zasoby kooperacji, zniszczenia i podziały skał, aktywna tarcza w grywalnej ścieżce Boreas. `42042348199`: 25/25 wykonywanych programów testowych Swift/Linux PASS (22 z macierzy + 3 już istniejące zestawy), parsowanie SwiftUI/Metal PASS. Natywny Xcode iPhoneOS **BUILD SUCCEEDED** dla aktualnego kodu Swift w `42040847979`; tamten workflow zwrócił FAIL wyłącznie przez błędną ścieżkę kontrolną `.app`, która została poprawiona w repo. Odrębna ponowna kontrola macOS była jeszcze w kolejce przy aktualizacji dokumentu. **Nie utworzono IPA.** Test interaktywny na fizycznym urządzeniu nie został wykonany i pozostaje w zadaniu 18. Wrogie AI, komplet bossów, broni i misji pozostają własnością zadań 9–13; dostępne API obrażeń przyjmuje ich obiekty, lecz nie należy deklarować implementacji tamtych systemów. **Zadanie 8: 96% bez zmian.**

| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 85% |
| 2 | Silnik graficzny Metal | 40% |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% |
| 4 | Statki, planety i zasoby 3D | 20% |
| 5 | Animacje modeli GLB | 35% |
| 6 | Fizyka lotu i poruszanie po planetach | 35% |
| 7 | Kolizje, obrażenia i zniszczenia | 100% |
| 8 | Asteroidy i fale walki | 96% |
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
- Kompilacja iOS tworzy niepodpisany IPA; nie mylić z testem na fizycznym iPhonie/iPadzie.
- Wydanie testowe IPA z zakończonego przebiegu 42027976783 pochodzi z commita 596767b i nie obejmuje późniejszych zmian.


- Grywalna ścieżka Boreas: `PlanetDamageLab556` steruje oryginalnym `Tarcza145` przez dotykowe przytrzymanie w `App.swift`, `MetalRenderer` podaje stan i raportuje energię. Działanie logiki i składni zweryfikowano w no-IPA workflow `42037997698` PASS. Natywna kompilacja Xcode i interaktywna obsługa dotyku nie są jeszcze zweryfikowane; nie deklarować ukończenia tej integracji na urządzeniu.
- `CombatVerifiedEncounter556`: przy `devOpen` zgodnie z `Game.cs:234` zatrzymuje całą fazę walki i odracza rozliczenie ratowania; test regresji PASS.

## Kolejność dalszej pracy

1. **Zadanie 7 — zamknięte implementacyjnie (100%)**: nie rozpoczynać od nowa; przy nowych zadaniach wykonywać regresję dokładnie tych zamrożonych mechanizmów z oryginalnego v556. Test fizycznego iPhone'a to osobny etap 18, którego brak należy jawnie raportować.
2. Następne do wykonania — **zadanie 8**, aktualnie 96%, wymaga osobnego polecenia do kontynuacji. Nie wykonywano go w tej sesji.
3. Dopiero po zadaniu 8 przejść do zadania 9; nie zmieniać listy 18 zadań ani wartości pozostałych pozycji bez nowych prac i dowodów.

## Weryfikacja zamknięcia zadania 7

- Oryginalne `Physics68.cs:31–45`: odpowiedź kontaktu; `Physics68.cs:50–59`: obroty tylko rock/rock; `Physics68.cs:33–37`: odrzucenie szerokości tylko dla kanonicznych Y.
- `SphereRockContact68`, `CombatSolids68`, `SphereSector556`: poprawiony brak spin po ship/rock, bug/rock i boss/rock; zachowany spin po rock/rock i rzeczywista fizyka sferyczna.
- `CombatVerifiedEncounter556`, `CombatVerifiedHit556`, `CombatRescue65`, `CombatRespawn556`: życie, tarcze, guardian, opancerzenie, kolizje, coop, ratowanie i odrodzenie.
- `PlanetDamageLab556`, `MetalRenderer`, `App.swift`: grywalna ścieżka z obrażeniami, wizualizowanym HUD kadłuba/pancerza/tarczy i momentowym wejściem tarczy.
- `SphereSector556`: podział skał, 18 ostatnich odłamków, punktacja i bezpieczne przebiegi kolizji; funkcje AI/bossów i misji nie są tu fikcyjnie tworzone.
- Testy Swift/Linux: GitHub Actions `42042348199`, **25/25 uruchomionych zestawów PASS**. Natywny kompilator Apple: `42040847979` zawiera `BUILD SUCCEEDED`, ale cały job FAIL wskutek niepoprawnej ścieżki testu istnienia produktu o nazwie `ASTEROIDY iOS.app` — poprawiono. Brak testu fizycznego iPhone'a i brak IPA.

## Tryb bez IPA — polecenie użytkownika

Do kolejnej wyraźnej zgody użytkownika kontynuować tylko implementację i testy Swift/Linux. Workflow `.github/workflows/verify-combat-only.yml` nie kompiluje Xcode, nie pakuje ani nie przesyła IPA. Nie uruchamiać `build-ios.yml`, które tworzy IPA.
