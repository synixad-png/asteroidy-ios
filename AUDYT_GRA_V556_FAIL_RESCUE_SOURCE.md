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
- `CombatVerifiedEncounter556.sourceSharedCoopResources`: opcjonalny tryb wspólnych żyć, pasywnych tarcz, opancerzenia i strażnika. Stary niezależny tryb diagnostyczny pozostaje dostępny, aby nie wprowadzić regresji do wcześniejszych testów; właściwy kontroler misji powinien użyć trybu współdzielonego.
- `Tests/CombatVerifiedEncounter556Tests.swift`: testy utraty 3 żyć, pojedynczego i podwójnego nieudanego ratowania, pasywnej tarczy, wspólnej kooperacji oraz odnowienia zdrowia po udanym ratowaniu.

## Zakres niepotwierdzony

Nie wykonano testu interaktywnego na fizycznym iPhonie/iPadzie. Testy Swift/Linux nie zastępują GPU Metal ani natywnego Xcode. Wariant diagnostyczny z niezależnymi zasobami pozostaje mechanizmem testowym, nie należy opisywać go jako źródłowej semantyki kooperacji.
