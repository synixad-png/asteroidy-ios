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
