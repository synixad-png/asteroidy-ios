# O03 — Strzelnica H290 i uzbrojenie VANGUARDA: aktualny etap

**Harmonogram niezmienny:** Reports/PC602_IOS_H290_STALY_HARMONOGRAM_2026-11-12.md, O03. Użytkownik zezwolił rozpocząć O03 zanim GitHub ukończy wszystkie kontrole O02; O02 pozostaje otwarty. **Bez zmian O04–O12.**

## Oryginalna rozbieżność, naprawiona w kodzie

§Windows/src/Game.cs:124–135§: §Fire()§ wywołuje §ConsumeIon()§ (implementacja §BossTunnelGame.cs:123§), które przy §IonAmmo > 0§ zwraca 1 i dekrementuje licznik **raz na salwę**. Każdy wygenerowany pocisk otrzymuje §bullet.Damage += ion§. Dla Rail §4 → 5§, dla Pulse Upgrade III §2 → 3§, a pozostałe bronie §1 → 2§.

§Windows/src/HomeFlight291.cs:55–62§: §StepHomeWeaponTest292§ wykonuje §originalShots=Shots,originalIon=IonAmmo;Fire();Shots=originalShots;IonAmmo=originalIon;§ — na H290 zachowana jest moc pocisków jonowych, lecz nie zużywa się amunicji i nie nalicza oddanych strzałów. Nie ma trafień, uszkodzeń, kredytów ani postępu misji.

**Przed:** §PC602HomeWeaponTest292.Settings§ nie przenosił §ionAmmo§ z kanonicznego profilu §Sector01Shop568.State§; §Bullet.damage§ zawsze pomijał źródłowe §+ion§.

**Po:** §Settings.ionAmmo§ przechowuje tylko zweryfikowany zakres 0–300. Port przekazuje §shop.ionAmmo§ przy tworzeniu H290, wczytaniu slotu i synchronizacji po H55/misji. Przy emisji salwy §let ion=settings.ionAmmo>0 ? 1:0§ zwiększa obrażenia **wszystkich** pocisków salwy bez mutowania amunicji. Nie dodano drugiego magazynu amunicji, nie ingerowano w funkcję bojową Carbonis 01. Warunek §Bullets.Count>140§ i geodezyjny ruch pozostają bez zmian.

**Źródła:** §HomeFlight291.cs§ (SHA256 7c26c62fc8010064f419512e83ce7b61e94cff8764d92cf595675c39d02a61d5), §Game.cs§ (34fd8b2877f5784a68ad7b2a7d31d59f506d3254a499c9124e720958f6e651ea), §BossTunnelGame.cs§ §ConsumeIon()§.

## Kontrole

Test §PC602HomeWeapons292Tests.swift§ rozszerzono o 5 rodzajów broni × 3 stopnie × 3 stany amunicji (0, 1, 300), weryfikację obrażeń, przebijania, kolejnych trzech salw i nieubywania jonów; źródłowe kolory, fizyka i render pocisków pozostają bez zmian. Rzeczywiste wykonanie testu i kompilacji iOS wymaga potwierdzenia w CI — **nie deklarować PASS przed wynikiem**. Pełne deterministyczne porównanie geodezyjnych pocisków z uruchomionym oryginalnym C# nadal jest wymagane do formalnego odbioru O03.

**Stan O03: W TOKU, kod częściowo poprawiony, brak pełnego odbioru.**

## Dodatkowa weryfikacja O03 — test 810 kombinacji

Rozbudowano `Tests/PC602HomeWeapons292Tests.swift` o niezależne oczekiwane wartości z dokładnych równań oryginalnego `Game.cs:123–133`, `HomeFlight291.cs:55–62`, `Modules97.cs:15` oraz `Talents78.cs:23` PC v602 (zweryfikowane oryginalne źródła). Test obejmuje 5 rodzajów broni × 3 stopnie mocy × 3 poziomy szybkostrzelności × 3 chłodzenia × 3 talenty tempa × stany jonów 0/1, razem 810 przypadków. Sprawdza interwał, liczbę pocisków, obrażenia i przebijanie, czas życia, prędkość oraz zachowanie liczby jonów. **Uwaga:** to źródłowy numeryczny test równań zaimplementowany w Swift, a nie osobne wykonanie kodu C# oryginału. Do pełnego odbioru O03 pozostają niezależne porównanie C# ↔ Swift oraz testy interaktywne na urządzeniu. 
