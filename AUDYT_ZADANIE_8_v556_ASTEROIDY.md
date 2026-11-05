# ASTEROIDY iOS — audyt domknięcia zadania 8 (v556)

**Zadanie:** 8. Asteroidy i fale walki (nie jest to zadanie 9 — wszystkie bronie — ani 10–13: wrogowie, bossowie, misje).

**Źródło nadrzędne:** rzeczywiste archiwum `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`, SHA256 `d0f6b83659d080fcd9084a0d1618ef53feb29c51aeea476feb90457030787d08`, oryginalny `Windows/src`. Nie zastępuje się zasad z C# pomysłami ani testowymi wartościami z płaskiej areny.

## Ustalenia bezpośrednio z kodu źródłowego

1. `Game.cs:90–100`: `Wave()` ustala liczbę asteroid `SectorRockCount`, ich poziomy pancerza i kierunek; początkowa odległość geodezyjna od statku wynosi co najmniej 260, prędkość wejściowa 48–78 plus `min(Level-1,18)*3.2`, spowolnienie gęstych `.88`, dla sfery `.55*DangerSpeed`. `PrepareRock70` wywołuje się na każdej sferycznej skale.
2. `Balance70.cs:5–6`: prawdziwe `RockHealth70` jest **inne** od `Rock.OriginalHP70`. Na sferze duże skały mają bazowe 4/6/8 HP (łatwy/normalny/trudny), średnie 3/4/5, małe 2/2/3. Dodaje się `ArmorTier`, +1 od Level≥13 i +1 w coop dla rozmiaru≥2. Normalna skala dużej skały na sferze wynosi `.52`, mniejszych `.75`. Po podziale `AddFragment77` nadpisuje skalę `.49` lub `.39`. Oryginalna punktacja `Split()` opiera się na `OriginalHP70`, **nie** na zwiększonym `MaxHealth`.
3. `Action38.cs:7,9–10`: kwoty posiłków zależą od rodzaju celu, zaokrąglone do 80%. W `Waves` pojawiają się do dwóch asteroid co 16 sekund, w pozostałych celach co 11 sekund lub wcześniej, gdy skał pozostało do 4. Para nadlatuje z przeciwległych brzegów (X=20 oraz X=1260), na Y od 140 do 660; musi zachować dystans 260 od statku (awaryjne odsunięcie o 340). Zapowiedź `NOWE ASTEROIDY NA ORBICIE` trwa `1.6` s.
4. `Gameplay65.cs:6–11`: cel `Waves` występuje w sektorach 9 i 17, trwa 48 sekund, trzy etapy co 16 sekund. Sama upływająca minuta nie oznacza ukończenia misji; trzeba też spełnić źródłowe warunki pozostałych asteroid, nadchodzących skał, przeciwników i bossa.
5. `Game.cs:232–252`: kolejność klatki to wygaśnięcie `ShardLife187`, ruch skał, `StepAction` (nadciągające skały), `StepSolids68` (kontakty), a dopiero potem kolizje pocisków. Nowa skała jest zatem **widoczna dla strzałów w klatce pojawienia się**, a właśnie wygasły odłamek nie powinien przejąć strzału.
6. `Physics68.cs:77–80`, `Game.cs:204–230`: impuls pocisku i zmiana spinu przy uderzeniu, fizyczny podział większej skały na dwie, przeniesienie prędkości po sferze, 18 tymczasowych odłamków po najmniejszej skale; geometria i spiny pozostają rozdzielone per rock.
7. **Sektor 25 — specjalny przypadek:** `AmigaBounce265.cs:4–60`, `Balance70.cs:6`, `Amiga266Tests.cs`, `Dev265Tests.cs`. `AmigaOnly266` wyłącza posiłki i przeciwników; skały nie umierają, trafienie zmienia prędkość i uruchamia podskok, przyznaje +10 punktów oraz zwiększa `AmigaHits266`; cel 20 trafień jest tylko informacją, a pokaz nie kończy się. Różne kule mają własne rytmy zależne od `Shape`, `gravity=480`, limit podskoku 55, krok maksymalny `.05` s, próg prędkości i limit 285 przy trafieniu. Skala dużej skały to `.41`, inicjalny radialny podskok to `4+17*abs(sin(...))`. Inne sektory nie dziedziczą tej mechaniki.

## Implementacja w porcie iOS

- `CombatBalance556.swift`: źródłowe wytrzymałości i skale sferycznych skał, w tym modyfikator poziomu/difficulty/coop.
- `SphereAsteroid556.swift`: rozdzielone `health`, `maxHealth`, `originalHealth`, autentyczny `shapeSeed` i stan `AmigaBounce265`. Helper jest współlokowany dla zgodności z istniejącymi kompilacjami testów; nie zmieniano `build-ios.yml`.
- `SphereSector556.swift`: pierwotny rozkład asteroid, napływ par, trzy fale, informacja HUD 1.6s, źródłowa kolejność klatki, wytrzymałość i skalowanie skał oraz odłamków, specjalny niekończący się pokaz sektora 25. Explicit diagnostic fixtures retain supplied HP where requested.
- `MetalRenderer.swift`, `App.swift`: dane fal i ostrzeżenia oraz źródłowy HUD `AMIGA / PIŁKI ODBIJANE`, licznik trafień. Wysokość radialna jest przeliczana przez `Sphere67.radius = H/π` na normalizowaną planetę w rendererze Metal.
- `Tests/Action38FrameOrder556Tests.swift`, `Tests/AmigaBalance70Sphere556Tests.swift` i wcześniejsze testy `SphereCombatBatch556Tests`, `Action38SphereQuota556Tests`, `SpherePhysicsAndMissionGate556Tests`, `SectorSpawn556Tests` — kwoty, fizyka, destrukcja, zdrowie, wypadające fragmenty, 78 profili i fizyka radiaalna.
- Testy regresyjne `verify-combat-only.yml`: Swift/Linux oraz osobna kontrolna kompilacja przez Apple SDK; **bez IPA**.

## Granice zgodności

To domknięcie logiki asteroid i fal walki. Nie deklaruje ukończenia broni wszystkich typów, sztucznej inteligencji przeciwników, bossów, misji ani pełnej kampanii (zadania 9–13). Symulator UI/Metal nie potwierdza jeszcze działania na fizycznym iPhonie (zadanie 18). **Nie utworzono IPA**, zgodnie z poleceniem.

## Wynik końcowy implementacji — 05.11.2026

- **100% zakresu implementacyjnego zadania 8** w istniejącym porcie Swift, bez dodawania funkcji zadania 9 (wszystkie bronie), 10–11 (AI/bossowie), 12–13 (misje/kampania) ani naruszania wykonanej logiki zadania 7.
- **25/25 zestawów automatycznych PASS** w GitHub Actions `42048306311`, commit `07afc65a61a1fcb4efe4a2e983f2a9131a1d8f63`. Ostatnie przypadki potwierdziły właściwą kolejność zdarzeń `Game.Step`, narastanie zdrowia i wielkości asteroid we wszystkich 78 profilach, tryb coop, fizykę odbić przez 850 kroków, niezniszczalność piłek w sektorze 25 i wynik +10 za trafienie.
- Dodatkowo przechodzi dotychczasowa regresja kolizji/obrażeń/odrodzenia i podziałów asteroid, co ogranicza ryzyko regresji zadania 7.
- **Kompilacja kontrolna Apple iOS/Xcode bez IPA była nadal w kolejce** podczas publikacji tego wyniku; nie przedstawiać jej jako zakończonej. Wcześniejsza kompilacja `42040847979` zgłosiła `BUILD SUCCEEDED`, ale poprzedzała zmiany zadania 8; jej wynik nie dowodzi kompilacji nowej rewizji. Test na fizycznym iPhonie nie został wykonany (zadanie 18).
- Zmieniono źródła wyłącznie osobnego repozytorium `synixad-png/asteroidy-ios`. Nie zmieniano Windows/SteamOS ani nie uruchamiano workflow generującego IPA.
