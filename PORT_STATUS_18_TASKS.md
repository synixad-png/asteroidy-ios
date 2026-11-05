# ASTEROIDY iOS — stały harmonogram portowania

Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To historyczny, zatwierdzony wynik raportu, a nie świeży pomiar obliczony z kodu. Zadanie 7 ma nowszą roboczą ocenę implementacji 87%, podlegającą końcowym testom. Zadanie 8 ma 96% według ostatniego harmonogramu.

| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 85% |
| 2 | Silnik graficzny Metal | 40% |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% |
| 4 | Statki, planety i zasoby 3D | 20% |
| 5 | Animacje modeli GLB | 35% |
| 6 | Fizyka lotu i poruszanie po planetach | 35% |
| 7 | Kolizje, obrażenia i zniszczenia | 87% |
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
- Nowe testy zapisane w Tests/CombatVerifiedEncounter556Tests.swift; wynik należy sprawdzić dla aktualnego SHA poprzez GitHub Actions, osobno Linux i macOS.
- Kompilacja iOS tworzy niepodpisany IPA; nie mylić z testem na fizycznym iPhonie/iPadzie.
- Wydanie testowe IPA z zakończonego przebiegu 42027976783 pochodzi z commita 596767b i nie obejmuje późniejszych zmian.

## Kolejność dalszej pracy

1. Domknąć zadanie 7 wraz z weryfikacją zintegrowanego łańcucha obrażeń i regresji; nie przypisywać niezaimplementowanej AI, broni wrogów lub bossów do działającego portu.
2. Domknąć pozostałe 4% zadania 8 po audycie źródłowego v556 i wykonaniu testów.
3. Dopiero później przechodzić do zadania 9. Każdy raport ma pokazywać wszystkie 18 pozycji, osobny postęp, zmianę pp, postęp globalny i % pozostały.
