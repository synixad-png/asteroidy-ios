# ASTEROIDY v556 — udokumentowany port Gameplay65 / Game.Damage / Coop62

Źródło pierwotne: własne archiwum użytkownika `Asteroidy_v556_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`; SHA-256
`d0f6b83659d080fcd9084a0d1618ef53feb29c51aeea476feb90457030787d08`.
Sprawdzono pliki `Windows/src/Gameplay65.cs`, `Windows/src/Game.cs`, `Windows/src/Talents78.cs`, `Windows/src/Coop62.cs`, `Windows/src/BossTunnelGame.cs`. W repo pozostają wyłącznie odniesienia do źródeł i kod portu, bez dodawania archiwum 150 MB.

## Zweryfikowane reguły oryginału

1. `Gameplay65.cs:26–31` — `TryDown65` daje 12 s wraku i blokadę wejścia przy `rescueDamage65`; `StepRescue65` wymaga 2 s strzelania pomagającego, odległości do 105 i prędkości pomagającego poniżej 160. Zablokowane menu deweloperskie zatrzymuje licznik.
2. `Gameplay65.cs:30` — udana pomoc wywołuje `ResetVitals78()` i daje uratowanemu statkowi 3 s ochrony. W kodzie Swift portu jest to odnowienie odpowiedniego obiektu `CombatTalentVitals78`; gdy oba pola wskazują tę samą instancję, otrzymujemy pierwotny wspólny zasób.
3. `Gameplay65.cs:31` — nieudana pomoc: wyłącza stan wraku, ustawia `rescueDamage65`, wywołuje **bezpośrednio** `Damage()` dla pierwszego rozbitego statku, w przeciwnym razie `WithSecond62(Damage)`. Gdy rozbite oba: tylko jedno `Damage()` pierwszego gracza, potem pozycja drugiego +85, zerowa prędkość i ochrona 3 s.
4. `Game.cs:188–192` — bezpośrednie `Damage()` sprawdza kolejno: `SceneBusy/BossArrival`, `TryGuardian`, nieskończone zdrowie deweloperskie, `TarczaAbsorb145`, `AbsorbDamage78`, `TryDown65`, w końcu stratę życia, zerowanie pasywnych tarcz i `ResetVitals78`, respawn lub GameOver.
5. `Gameplay65.cs:29,31` — podczas FailRescue `rescueDamage65=true`, więc `TryDown65` nie uruchamia kolejnego 12-sekundowego wraku. Ścieżka `HitByBoss` z automatycznym pobraniem pasywnej osłony **nie uczestniczy** w bezpośrednim `Damage()`.
6. `Talents78.cs:49–58` — `AbsorbDamage78` liczy domyślne 27/32/38 (easy/normal/hard), zużywa pancerz przed kadłubem i ustawia ochronę 0,85 s; wartość zero kadłuba oznacza niezaabsorbowane trafienie.
7. `Coop62.cs:7–9` — `WithSecond62` wymienia położenie, prędkość, kierunek, immunitet i ruch statku, lecz **nie** wymienia globalnych `Lives`, `ShieldCharges`, `Hull78`, `Armor78` ani `GuardianCharges`. Oryginalna kooperacja współdzieli te zasoby.

## Odwzorowanie w Swift

- `CombatVerifiedHit556.failedRescueDamage`: bezpośrednia ścieżka `Damage()` z powyższą kolejnością, bez pasywnego przechwytywania `HitByBoss` i bez ponownego `TryDown65`.
- `CombatVerifiedEncounter556`: natychmiastowe rozliczenie `FailRescue65` z opcją bezpiecznego oczekiwania na niezweryfikowaną ochronę; respawn / GameOver przez `CombatRespawn556`; dla obu wraków przestawienie drugiego statku.
- `CombatVerifiedEncounter556.sourceSharedCoopResources`: automatycznie włączony dla każdego spotkania z drugim statkiem. Wspólne życia, zakupione tarcze, opancerzenie, strażnik oraz energia/aktywność `Tarcza145`. Niezależny tryb jest dostępny wyłącznie przez jawny argument `independentDiagnosticCoop:true`, do regresji historycznych fixture'ów. Domyślna kooperacja nie powiela zasobów.
- `Tests/CombatVerifiedEncounter556Tests.swift`: testy utraty 3 żyć, pojedynczego i podwójnego nieudanego ratowania, pasywnej tarczy, wspólnej kooperacji oraz odnowienia zdrowia po udanym ratowaniu.

## Zakres niepotwierdzony

Nie wykonano testu interaktywnego na fizycznym iPhonie/iPadzie. Testy Swift/Linux nie zastępują GPU Metal ani natywnego Xcode. Wariant diagnostyczny z niezależnymi zasobami pozostaje mechanizmem testowym, nie należy opisywać go jako źródłowej semantyki kooperacji.

## Uzupełnienie audytu: globalna tarcza Tarcza145 i domyślny Coop62

- `Windows/src/Tarcza145.cs:5–20` deklaruje **jeden** `TarczaEnergy145`, `TarczaActive145` i `TarczaFlash145` w klasie `Game`; aktywacja zależy od `StepTarcza145(dt, hold)`.
- `Windows/src/Game.cs`, `Step(dt, first)`, wywołuje `StepTarcza145(dt,input.Tarcza145)` raz. `Windows/src/Coop62.cs:9` w `WithSecond62` wymienia parametry statków, ale **nie** wymienia energii ani aktywności `Tarcza145`. `Coop62.cs:17` wywołuje `Step(dt,first)`. Zatem drugi gracz nie ma niezależnej energii kopuły ani osobnego wejścia do jej aktywacji w tej ścieżce.
- Port Swift: w źródłowym trybie kooperacji `domeFirst` jest jedyną zmienianą pulą, `domeSecond` jest wyłącznie lustrzanym widokiem wspólnego stanu. Trafienie P2 i `FailRescue65` P2 zmieniają ten sam stan, co trafienie P1. Historyczne testy z niezależnymi zasobami zostały utrzymane po jawnym `independentDiagnosticCoop:true`.
- Test regresji: `Tests/CombatVerifiedEncounter556Tests.swift`, wejście P2 nie uruchamia osobnej kopuły, trafienie P2 zużywa kopułę P1, dwa równoczesne kontakty razem zużywają nie więcej niż 60 jednostek, `FailRescue65` P2 korzysta z tej samej energii.
- Wynik: Swift/Linux GitHub Actions `42035502390`, **PASS**, brak artefaktów IPA. Nie przeprowadzono testu natywnego iOS/Metal.

## 2026-11-05 — integracja do grywalnego testu Boreas (bez IPA)

**Ściśle sprawdzone podstawy w oryginalnym archiwum Windows v556:**
- `Windows/src/Game.cs:234` — `if(DevOpen)return;` następuje przed tyknięciem tarczy i kolizjami. `Gameplay65.cs:30` zatrzymuje również fazę ratowania przy `DevOpen`.
- `Windows/src/Game.cs:240,248` — `StepTarcza145(dt,input.Tarcza145)` przed `StepSolids68(dt)`; dotychczasowa gra na iOS nie przekazywała wejścia tarczy do grywalnego testu Boreas.
- `Windows/src/Tarcza145.cs:5–21` — jedna ręcznie przytrzymywana tarcza, początkowo energia 60, zużycie 12/s przy aktywności, 35 na przechwycone trafienie, brak automatycznego doładowania.

**Zmiany:**
- `CombatVerifiedEncounter556.step` zatrzymuje całą fazę przy `devOpen=true`, również rozliczanie oczekującego nieudanego ratowania — nie tylko licznik ratowania.
- `PlanetDamageLab556.advance` przyjmuje `tarczaHeld` (domyślnie `false`, aby nie zmieniać starych wywołań), steruje rzeczywistym `CombatTarcza145` i ujawnia wartości energii oraz aktywności.
- `MetalRenderer.draw` przekazuje rzeczywisty stan dotykowy `input.tarczaHeld` i aktualizuje HUD energii tarczy.
- `App.swift` ma przytrzymywany przycisk `TARCZA` w grywalnym **teście obrażeń v556 na Boreas**, bez zmian w innych trybach i bez ogłaszania pełnej misji jako gotowej. Zwolnienie palca natychmiast wyłącza wejście tarczy; zmiana trybu resetuje stan przycisku.
- Testy: `CombatVerifiedEncounter556Tests.swift` dla blokady `DevOpen` i `PlanetDamageLab556Tests.swift` dla aktywacji, zużycia energii, przechwycenia trafienia, wyczerpania i powrotu do uszkodzeń pancerza/kadłuba.

**Weryfikacja:** GitHub Actions `42037997698` — wszystkie etapy **PASS** (Swift/Linux testy i składniowe parsowanie `App.swift`, `MetalRenderer.swift`); **bez budowania iOS, bez IPA, bez testu na fizycznym iPhonie**. Parsowanie plików SwiftUI/Metal nie jest równoważne z natywnym sprawdzeniem typów przez Xcode.

## Domknięcie zadania 7 — fizyczne kontakty i zniszczenia, 05.11.2026

**Źródło prawdy:** `Windows/src/Physics68.cs:31–45,50–59,62–75` oraz `Windows/src/Game.cs:188–193,224–230` z oryginalnego archiwum v556.

- `Contact68` oblicza liniowy impuls, tarcie styczne oraz korektę pozycji. **Nie dodaje obrotu** skałom. W oryginale `RockContacts68` osobno dodaje `contactFriction68` do `Spin` przy **kontakcie dwóch skał** (Physics68.cs:57). Poprzedni port `SphereRockContact68.resolve` stosował obrót także przy ship/rock, bug/rock i boss/rock. Poprawiono poprzez `applyRockSpin:false` w `CombatSolids68` i grywalnym `SphereSector556`, zachowując `true` dla rock/rock. Dodano regresje z niezerową styczną prędkością i zachowaniem początkowego `Spin` skały.
- W `Physics68.cs:33–37` wczesne odrzucenie na podstawie różnicy szerokości działa tylko dla **kanonicznych** współrzędnych `0≤Y≤H`. Port bezwarunkowo odrzucał różne wartości Y. Poprawiono warunek i dodano test równoważnych po odbiciu biegunowym współrzędnych.
- Oryginalne `Game.cs:224–230` i `Physics68.cs:77–80`: zniszczenie skały respektuje punkty życia, pancerz, wielkość, przyznaje punkty, dzieli większą skałę fizycznie i emituje 18 nietrwałych odłamków przy ostatnim rozmiarze. W istniejącym porcie odpowiadają za to `CombatDamage556` i `SphereSector556`. Kontrolę zniszczeń, fal i 78 konfiguracji planet dodano do pełnej macierzy testów.
- Obrażenia, pasywne tarcze, aktywne `Tarcza145`, `Guardian37`, `Talents78`, utrata żyć i ratowanie kooperacyjne są testowane razem w `CombatVerifiedEncounter556Tests` oraz grywalnym teście `PlanetDamageLab556Tests`.
- CI `.github/workflows/verify-combat-only.yml` ma także osobną kompilację natywnych źródeł iOS za pomocą Xcode, **bez** przygotowania i przesyłania IPA. Sprawdzenie uruchomienia na fizycznym iPhonie wymaga późniejszego testu urządzenia; samo `BUILD SUCCEEDED` nie jest testem interaktywnym.

**Granice odpowiedzialności:** Zadanie 7 obejmuje gotowe procedury fizyki, kontaktów i zniszczeń oraz ich połączenie z aktualnie grywalnym Boreas. Przeciwnicy, komplet bossów, wszystkie bronie i pełne misje mają własne etapy 9–13; nie należy deklarować ich jako gotowych tylko z powodu działania API kolizji. Rzeczywisty test iPhone/SteamOS nie jest częścią automatycznego testu Swift/Linux.
