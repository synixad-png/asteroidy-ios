# ASTEROIDY iOS — stały harmonogram portowania

Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To zachowany wynik zbiorczy całego portu, a nie nowy pomiar ważony. **Zadanie 7: 97% (poprzednio 96%, +1 pp)** — źródłowo potwierdzona blokada całej fazy walki przy `DevOpen` (`Windows/src/Game.cs:234`) oraz połączenie oryginalnej przytrzymywanej tarczy `Tarcza145` (`Game.cs:240,248`, `Tarcza145.cs`) z **grywalnym testem obrażeń Boreas** w `PlanetDamageLab556`, `MetalRenderer` i przyciskiem SwiftUI. Testy Swift/Linux oraz parsowanie plików SwiftUI/Metal: **PASS**, run `42037997698`. Nadal **brak natywnego kompilowania Xcode, testu na fizycznym iOS i nowego IPA**, zgodnie z poleceniem użytkownika. Zadanie 8 pozostaje na 96%.

| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 85% |
| 2 | Silnik graficzny Metal | 40% |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% |
| 4 | Statki, planety i zasoby 3D | 20% |
| 5 | Animacje modeli GLB | 35% |
| 6 | Fizyka lotu i poruszanie po planetach | 35% |
| 7 | Kolizje, obrażenia i zniszczenia | 97% |
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

1. Domknąć zadanie 7 wraz z weryfikacją zintegrowanego łańcucha obrażeń i regresji; nie przypisywać niezaimplementowanej AI, broni wrogów lub bossów do działającego portu.
2. Domknąć pozostałe 4% zadania 8 po audycie źródłowego v556 i wykonaniu testów.
3. Dopiero później przechodzić do zadania 9. Każdy raport ma pokazywać wszystkie 18 pozycji, osobny postęp, zmianę pp, postęp globalny i % pozostały.

## Tryb bez IPA — polecenie użytkownika

Do kolejnej wyraźnej zgody użytkownika kontynuować tylko implementację i testy Swift/Linux. Workflow `.github/workflows/verify-combat-only.yml` nie kompiluje Xcode, nie pakuje ani nie przesyła IPA. Nie uruchamiać `build-ios.yml`, które tworzy IPA.
