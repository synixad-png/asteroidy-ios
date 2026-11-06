# ASTEROIDY iOS v568 — CARBONIS 01: źródłowe myśliwce, fizyka i trafienia

Data: 6 listopada 2026. Zakres: natywny Swift/Metal. Baza: oryginalne źródła Windows/SteamOS v568, a nie zastępczy projekt gry.

## Rzeczywiście zaimplementowane

**Myśliwiec typu 0:** `CarbonisShooterMesh71.swift` przenosi proceduralną geometrię `Windows/src/ShipMesh.cs` używaną przez `BossMesh65(0,"drone")` w `GpuRobot70.cs`: kadłub, profilowane skrzydła, silniki, działka, stateczniki, osłonę kabiny i dodatkowe detale. Osiem oryginalnych grup materiałowych, normalne i zakresy trójkątów trafiają do jednego współdzielonego bufora Metal. `Sector01Carbonis568.metal` dodaje shader materiałów myśliwca; `Sector01CarbonisPreview568.swift` rozmieszcza **cztery jednostki** zgodnie z pozycją i kierunkiem rzeczywistej symulacji, nie z wymyślonych danych. Nie jest to jeszcze dowód zgodności wizualnej 1:1, bo nie porównano wynikowych obrazów na GPU Apple.

**Zachowanie przeciwników:** `CarbonisCombat568.swift` odtwarza `EnemyTactics71.cs` dla początkowego typu 0 — orbitę w odległości 158 jednostek, stałą stronę okrążania, śledzenie i wyprzedzanie celu, limit obrotu 6,5 rad/s, dystans ostrzału 200, ostrzeżenie 0,82 s i odnowienie 2,8 s. Na sferze pojawiają się proceduralne pierścienie i linie ostrzegające o przygotowanym ostrzale.

**Rzeczywista fizyka:** nowy `CarbonisBodyContact68.swift` przenosi `Physics68.cs:31–45`: masy, pęd i tarcie zderzenia oraz korektę położenia w przestrzeni stycznej do sfery, także w pobliżu bieguna i szwu długości geograficznej. Jest używany dla statku z asteroidami i myśliwcami, bez zmian zamrożonego `SphereRockContact68.swift`. Dodano fizyczny odrzut skał po trafieniu (`ImpactRock68`), wybór najwcześniejszego trafienia i zasłanianie myśliwców przez asteroidy (`HitBug`), rzeczywistą punktację `Game.Split` oraz 18 nietrwałych odłamków po zniszczeniu małej skały (`SpawnTerminalShards187`). Zwycięstwo następuje dopiero po zniknięciu wszystkich odłamków i okresie czyszczenia 0,20 s.

**Regresje:** nowe `Tests/CarbonisShooterMesh71Tests.swift`, `Tests/CarbonisBodyContact68Tests.swift` i rozbudowane `Tests/CarbonisCombat568Tests.swift`; GitHub workflow sprawdza też wcześniejsze mechanizmy.

## Potwierdzenie testów

[GitHub Actions 42256245496](https://github.com/synixad-png/asteroidy-ios/actions/runs/42256245496), commit `426a7575e1a8bad85f8eca870b0ce097db081a49`:
- `verify-combat-no-ipa`: **SUCCESS** — pełny zestaw Swift/Linux, z nowymi testami; przed sukcesem odczytano i usunięto konkretne błędy Swift z logów GitHub Actions.
- `publish-combat-verify-run`: **SUCCESS**.
- `Compile iOS source only`: **queued** (runner macOS nie został przydzielony), nie ma natywnego potwierdzenia kompilacji iPhone.
- Nie wykonano interaktywnego testu na iOS ani rzeczywistej kontroli GPU Apple. Nie powstał nowy zweryfikowany IPA. Nie przedstawiono cudzych screenshotów jako efektów własnej aplikacji.

## Granice funkcji

Zakres obejmuje aktywnego, proceduralnego myśliwca typu 0 i mechaniki pierwszej misji. Brakuje wiernych modeli kolejnych klas przeciwników, bossów, wszystkich pozostałych misji, pełnego uzbrojenia, dźwięku, zapisu ukończenia kampanii, animacji i przekrojowego testu end-to-end iOS. Nie zgłaszać gotowości całej gry.

## Następny krok

Po potwierdzonym przejściu źródłowych testów rozwijać kolejno kolejne typy przeciwników i logikę pełnej kampanii, niezależnie od kolejki runnerów macOS. W razie dostępności Xcode sprawdzić render prawdziwego C279, zgodność Metal i dotyku; dopiero potem potwierdzać IPA.

## Uzupełnienie: natywna kompilacja iPhone/iPad

W przebiegu [42247840690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42247840690) runner macOS ostatecznie wykonał `xcodebuild` i wykazał błąd (nie był to tylko brak przydziału runnera): `CarbonisRockGeometry568.swift` (składnia operatorów, obecnie poprawiona) oraz `Sector01CarbonisPreview568.swift` (jawny `self` wymagany w zamknięciu `addCompletedHandler`). Poprawki są zatwierdzone w repozytorium, a najnowszy przebieg `verify-combat-no-ipa` dla wcześniejszych zmian osiągnął PASS.

Uruchomiono ponowny [build IPA 42259012837](https://github.com/synixad-png/asteroidy-ios/actions/runs/42259012837) na commicie `a7ebee2f2d98a2ce93a891b1c92365237003e1de`, zawierającym komplet zmian tego etapu i naprawę błędu Xcode. Przy sporządzeniu uzupełnienia: zadania workflow nadal trwają; **IPA niezweryfikowany**. Dopiero sukces `compile-device` i pojawienie się `ASTEROIDY-iOS-device-unsigned-ipa` potwierdzi nowe wydanie. Nie deklarować zweryfikowanego testu GPU Apple lub sterowania iOS.

