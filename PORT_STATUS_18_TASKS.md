# ASTEROIDY iOS — stały harmonogram portowania

## UZUPEŁNIENIE 06.11.2026 — bezpieczeństwo wejścia do CARBONIS (bez zmiany postępu)

W commitach `7438a823` i `9f769824` uszczelniono wejście do oryginalnej sceny C279: `Sector01CarbonisPreview568.isAvailable` sprawdza teraz nie tylko istnienie, ale również SHA-256 wszystkich pięciu źródłowych plików jeszcze przed wyborem sceny. Weryfikacja w rendererze Metal pozostaje niezależnie aktywna. Rozszerzono kontrakt `Tests/V568W3NativeMenuContract.py` o asercje tej bramki.

**Postęp bez zmian: 29% wykonane / 71% pozostało.** To naprawa ochronna etapu C, a nie implementacja `StartHubMission261`, fal, lotu czy wygranej. Natywna kompilacja po tych commitach i test na fizycznym iOS nie zostały jeszcze potwierdzone; poprzedni PASS `42225858732` dotyczy wcześniejszego snapshotu. Następne zadanie: rzeczywista logika startu misji na podstawie Windows v568, nie powtarzanie testów menu. Nowego IPA nie wydano.

## BIEŻĄCY STAN — etap C: wejście w rzeczywistą scenę CARBONIS, 06.11.2026

**Ocena projektu 29% wykonane (+1 pp) / 71% pozostało.**
Nowy przyrost jest oszacowaniem wdrożonej na iOS, skompilowanej
funkcjonalności przejścia do źródłowego sektora 01, a nie
deklaracją, że ten sektor jest już grywalny.
Poniższy harmonogram jest bieżący; starsze wartości poniżej
pozostają archiwalnymi raportami.

**Nowa funkcja:** `W3MainMenu568` → wybór z prawdziwego
26-sektorowego `CampaignAtlas556` → przycisk
`WEJDŹ NA CARBONIS 01 / ŹRÓDŁOWA SCENA 3D` →
`Sector01Scene568` z oryginalnym C279 Metal
(270249 trójkątów) → **WRÓĆ DO MAPY** przywraca
właściwy atlas. Jest obsługa obrotu planety palcem;
brak fikcyjnych nagród, włączania zablokowanych misji,
podmiany Carbonis na Boreas i fałszywego ukończenia.
Wszystkie 25 pozostałych sektorów mają zabezpieczoną
bramkę wejścia — nie są kierowane do Carbonis.
Źródłowe indeksy/UV/tekstury nadal nienaruszone.

[GitHub Actions 42225858732](https://github.com/synixad-png/asteroidy-ios/actions/runs/42225858732)
**PASS / PASS** — natywna kompilacja iOS Swift/Metal
oraz źródłowe testy wejścia, selekcji, kolizji i walki.
**Brak testu dotyku tej nowej trasy na fizycznym iOS**,
nie deklarować interaktywnego PASS na urządzeniu.

**Nadal do wykonania w C:** właściwy
`Game.StartHubMission261`, uruchomienie fal `Wave()`,
statek i kamera w realnym świecie Carbonis, kolizja
z mapą wysokości, broń, przeciwnicy, wynik
i zakończenie misji. To ma być kolejny zakres wdrożenia;
testy menu nie mogą ponownie zastąpić rozwoju gry.

**Stałe 18 zadań; wartości poprzednie i obecne:**

| Nr | Zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 22% | 22% | 0 pp |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 7% | 8% | +1 pp |
| 13 | Kampania — 26 sektorów | 34% | 35% | +1 pp |
| 14 | Menu W3, HUD i ustawienia | 14% | 15% | +1 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Raport techniczny:**
[Reports/V568_STAGE_C_CARBONIS_ENTRY_2026-11-06.md](Reports/V568_STAGE_C_CARBONIS_ENTRY_2026-11-06.md).

**IPA:** nowe wydanie nie było zlecone; wcześniejszy plik
na Dysku Google pozostaje starszym snapshotem.
Nie wydano nowego IPA.


## BIEŻĄCY STAN — REALNY POSTĘP, 06.11.2026 (obowiązuje przed starszymi wpisami)

**Ocena całego projektu: 28% wykonane (+1 pp), 72% pozostało.**
Procenty poniżej są ostrożną oceną realnego zakresu implementacji
i testów; wcześniejsze wpisy zachowano jako historię, a nie bieżący stan.

**Wykonano nowe funkcje, a nie kolejne powtórzenie testów menu:**

- **B. Wybór misji:** prawdziwe klikalne 26 pól kampanii w
  `App.swift` i `W3MainMenu568.swift`, autentyczne nazwy planet
  z audytu PC v568 (`MissionCatalog568.swift`), blokowanie
  niedostępnych sektorów zgodnie z `Orbit50.MissionUnlocked50`,
  podświetlenie wybranego sektora i zapis `selectedSector`
  w UserDefaults **osobno od bitów ukończonych misji**.
  Przypadkowe dotknięcie nie zalicza misji. Natywna kompilacja
  i testy czystej logiki **PASS**:
  [GitHub Actions 42220854317](https://github.com/synixad-png/asteroidy-ios/actions/runs/42220854317).
  Test interaktywny tej nowej funkcji na fizycznym iPhonie/iPadzie
  nie został wykonany; nie deklarować 100% gotowości B.
- **C. Pierwszy sektor CARBONIS:** oryginalna siatka C279,
  **270249 trójkątów, 137067 unikatowych wierzchołków,
  810747 oryginalnych indeksów, UV, 2 grupy materiałów i
  mapa wysokości 512×256**. Bez rekonstrukcji z OBB lub
  generowania zastępczej kuli. Oryginalne trzy tekstury są
  chronione SHA-256. Zamiast rozwijać geometrię do ~38,9 MB,
  zachowano GPU indexed mesh **9 822 204 B** bez zmiany
  źródłowej geometrii. Wdrożono źródłowy podgląd Carbonis
  po wybraniu sektora 01, nowy shader i renderer Metal.
  Test autentyczności [42222217173](https://github.com/synixad-png/asteroidy-ios/actions/runs/42222217173)
  **PASS**. Natywna kompilacja iOS wraz z regresjami
  [42223077726](https://github.com/synixad-png/asteroidy-ios/actions/runs/42223077726)
  **PASS** dla obu jobów. Zgodność PBR obrazu 1:1 z Windows,
  fizyczny render i prawdziwy start rozgrywki są jeszcze
  do wdrożenia/zweryfikowania.
- **A. Menu W3:** pozostają do zamknięcia ograniczenia testu
  interaktywnego iPada oraz pełna zgodność graficzna; nie
  blokują już przygotowania kolejnych elementów gry.
- **Czego NIE wykonano:** rzeczywistego `StartHubMission261`
  na wybranym sektorze, walki w źródłowej misji CARBONIS,
  śledzenia zwycięstwa/przegranej i 25 pozostałych grywalnych
  planet. **Nowego IPA nie wydano**. Poprzedni plik z Dysku
  Google nie zawiera tych nowych zmian.

**Stała lista 18 zadań — aktualne procenty i zmiany względem
poprzedniego raportu:**

| Nr | Stałe zadanie | Było | Jest | Zmiana |
|---:|---|---:|---:|---:|
| 1 | Infrastruktura iOS | 88% | 88% | 0 pp |
| 2 | Silnik Metal | 89% | 89% | 0 pp |
| 3 | Materiały i oświetlenie | 25% | 25% | 0 pp |
| 4 | Statki i planety 3D | 20% | 22% | +2 pp |
| 5 | Animacje GLB | 35% | 35% | 0 pp |
| 6 | Fizyka lotu | 35% | 35% | 0 pp |
| 7 | Kolizje i obrażenia | 100% | 100% | 0 pp |
| 8 | Asteroidy i fale | 100% | 100% | 0 pp |
| 9 | Bronie i trafienia | 10% | 10% | 0 pp |
| 10 | AI przeciwników | 0% | 0% | 0 pp |
| 11 | Bossowie | 0% | 0% | 0 pp |
| 12 | Misje planetarne | 5% | 7% | +2 pp |
| 13 | Kampania — 26 sektorów | 30% | 34% | +4 pp |
| 14 | Menu W3, HUD i ustawienia | 10% | 14% | +4 pp |
| 15 | Muzyka i dźwięki | 0% | 0% | 0 pp |
| 16 | Zapisywanie gry | 20% | 20% | 0 pp |
| 17 | Sterowanie | 35% | 35% | 0 pp |
| 18 | Optymalizacja i testy | 10% | 10% | 0 pp |

**Następny krok wykonawczy:** faktyczne wejście z wyboru sektora
01 do źródłowej misji CARBONIS z prawdziwym trybem gry,
kamerą, kolizjami, falami i wynikiem. Dalsze testy menu
prowadzić jako rozwiązywanie konkretnych usterek, nie
nieskończoną blokadę rozwoju.

Dokładne dowody:
[Raport B/C CARBONIS](Reports/V568_STAGE_B_SELECTION_C_CARBONIS_SOURCE_2026-11-06.md).


## AKTUALIZACJA 06.11.2026 — realizacja A, faktyczne Apple GPU i XCTest

**ETAP A (MENU W3) W TRAKCIE; B JESZCZE NIEROZPOCZĘTY.**
Stały harmonogram 18 zadań: **27% wykonane / 73% pozostało**.
Zadanie 14 **10% (+0 pp)** — nie podwyższać bez ukończenia testów UI.

**Aktualna praca:** poprzednie sesje Apple Actions
[42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
i
[42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
zakończyły się niepowodzeniem, a zadania symulatorów anulowano;
nie dostarczyły pełnego wyniku nowej nawigacji.
Oba przepływy uruchomiono ponownie na **macos-15-intel**,
który wcześniej skutecznie kompilował i uruchamiał ASTEROIDY iOS.

- [GitHub Actions 42217818216 — oryginalne menu/planeta/okręt W3 GPU](https://github.com/synixad-png/asteroidy-ios/actions/runs/42217818216):
  **IPHONE SUCCESS** — rzeczywiste uruchomienie ekranu,
  oryginalne obrazy W3, planetarny model NewHome290 i ukończone
  komendy Metal oraz autentyczny zrzut ekranu.
  IPAD w momencie aktualizacji nadal uruchamiał rzeczywisty
  ekran i walidację GPU; nie zaliczono go bez wyniku końcowego.
- [GitHub Actions 42217810810 — siedem prawdziwych dotknięć W3](https://github.com/synixad-png/asteroidy-ios/actions/runs/42217810810):
  oba joby **IPHONE i IPAD wykonują rzeczywiste XCTest**,
  czyli dotknięcia 7 pozycji, wejścia do paneli, powroty i
  przejście do diagnostyki 3D. Nie deklarować PASS bez
  zakończonego testu; nie przedstawiać uruchomienia jako wyniku.
  W razie niepowodzenia pobrać zachowane `.xcresult`
  z drzewem dostępności i autentycznym zrzutem ekranu.
- Nie dokonano zmian w źródłowej geometrii, zapisach, kolizjach
  ani falach walki. **Nowego IPA nie generowano**; wcześniejszy
  zweryfikowany `W3_MENU_NAV` jest już na Dysku Google.

**Dalsza bramka:** bezpośrednie potwierdzenie siedmiu przycisków,
końcowy wynik obu GPU i ocena zgodności W3 z Windows.
Dopiero po zamknięciu A rozpoczyna się etap B — realny wybór misji.


## 06.11.2026 — POTWIERDZONE NOWE WYDANIE IPA W3 MENU NAV

**GitHub Actions 42212773252 — SUCCESS**. Nowy rzeczywisty,
**NIEPODPISANY** IPA do fizycznego iPhone/iPada:
`ASTEROIDY_v568_W3_MENU_NAV_iPhone_iPad_UNSIGNED.ipa`,
**14 103 697 B**; SHA256
`9b16daf6e045220140505ebbed99cf24befadbea8c0b7b2d8a1080df7b5c98ce`.
ZIP, iOS ARM64, oryginalne materiały W3/H290/Vanguard431
i wyniki `Tools/verify_ipa.py` — PASS, potwierdzone po
pobraniu pliku z GitHub. Snapshot wydania:
`1ebd88d37bd5cf0bb2b26ce961e067f4764b002c`.
[Artefakt GitHub 13500341359](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212773252/artifacts/13500341359).

Na **prywatnym Dysku Google użytkownika** potwierdzono
[ZIP z nowym IPA i raportami SHA/CRC](https://drive.google.com/file/d/1VyqprYPbt6KLGIqwKzgwrHzAGGqrGSyH/view?usp=drivesdk)
(13 943 090 B). ZIP trzeba rozpakować, by otrzymać plik
IPA. Jest to kopia całego artefaktu GitHub, nie błędnie nazwany ZIP
udający IPA. Raport:
[Reports/V568_W3_MENU_NAV_IPA_RELEASE_2026-11-06.md](Reports/V568_W3_MENU_NAV_IPA_RELEASE_2026-11-06.md).

**Postęp harmonogramu nie został sztucznie podwyższony:**
cały projekt **27% wykonane / 73% pozostało**,
zadanie 14 **10% (+0 pp)**. Etap A otwarty, ponieważ
[XCTest 42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
i [GPU 42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
nie mają jeszcze końcowego wyniku. Etapu B (wybór misji)
nie rozpoczęto. Fizyczna instalacja nie została przetestowana.


## OSTATNI RAPORT — 06.11.2026, nowe IPA W3 na życzenie

**ETAP A: W TRAKCIE. ETAP B: nierozpoczęty.** Pełna lista 18 zadań
i ich procenty pozostają niezmienione: **27% projektu wykonano,
73% pozostało**, zadanie 14 **10%, zmiana +0 pp**.

- Naprawiono osiągalność wszystkich siedmiu źródłowych pozycji
  W3 w poziomym widoku iPhone'a: `W3MainMenu568.swift`
  korzysta teraz z pionowo przewijanej nawigacji oraz
  minimalnych obszarów dotykowych **44 pt**. Zachowano
  oryginalną geometrię NewHome290, podgląd Vanguard431,
  sterowanie planetą, siedem polskich nazw oraz przejścia
  do istniejących paneli. Nie modyfikowano misji, broni
  ani zamrożonych mechanik 7/8.
- Rozszerzono `Tests/V568W3NativeMenuContract.py` o wymuszenie
  przewijania, 44-pt przycisków, identyfikatorów dostępności
  i zachowania rozdziału menu od sceny diagnostycznej.
- **Kompilacja źródłowa Swift/Metal na iOS: PASS**
  [42212331058](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331058)
  (job `Compile iOS source only`, wynik `success`).
  Pozostałe testy regresyjne iOS i Xbox/asteroid nie muszą
  być uznawane za zakończone przed ich faktycznym wynikiem.
- **Nowe, jednorazowe IPA użytkownika** (niepodpisane
  arm64 dla fizycznych iPhone/iPad) uruchomiono z
  rewizji `0873cae65b99c41d020f6e841407e468e077e2e8`:
  [42212392679](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212392679).
  Wydanie należy uznać za gotowe **wyłącznie** po
  zweryfikowanym `success`, kontroli SHA/CRC/7
  oryginalnych zasobów i pobraniu pliku IPA. W przypadku
  niepowodzenia nie podawać linku do nieistniejącego pliku.
- Osobne, niedokończone testy nawigacji
  [42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207)
  oraz grafiki GPU
  [42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152)
  pozostają odrębnymi bramkami zaliczenia A. NIE zaliczać
  ich na podstawie kompilacji IPA ani starego zrzutu.

**Następne:** zakończyć XCTest siedmiu rzeczywistych
dotknięć oraz powrotu ze sceny 3D i zamknąć etap A; dopiero
potem B — wybór misji. Wydany wcześniej IPA z rewizji
`5242e4f` na Dysku Google jest odrębną starszą wersją.


## AKTUALIZACJA ETAPU A — natywna nawigacja W3, ostatni stan 06.11.2026

**Stan A: OTWARTY; B nie rozpoczęty.** Cały projekt **27%**,
pozostało **73%**, zadanie nr 14 **10%, +0 pp**. Nie zmieniono
zakresu ani postępów pozostałych 17 zadań. Nie wydano nowego IPA.

Rzeczywiste XCTest
[42204712384](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712384)
wykazały niedostępność `w3-home-0` dla automatycznego
wyszukiwania obu urządzeń. Poprawiono semantykę
`accessibilityElement(children: .contain)`, nazwy/cechy
i stabilne identyfikatory siedmiu natywnych przycisków;
w XCTest poprawiono interpolację, ustawiono krajobrazowe
uruchamianie i zapisano pełny `.xcresult` z obrazem/hierarchią
w razie błędu. Środowiskowy timeout `simctl launch`
iPada wydłużono z 50 do wciąż ograniczonych 150 s.
Testy iPhone/iPad przeniesiono na standardowe `macos-15`
bez zmiany prawdziwych kontroli GPU i dotyku.

**Potwierdzone:** rzeczywista kompilacja iOS + testy regresji
[42210096215](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210096215)
PASS. **Oczekują na wykonanie** dwa nowe przebiegi:
[dotyk 42211323604](https://github.com/synixad-png/asteroidy-ios/actions/runs/42211323604)
oraz
[GPU 42211331700](https://github.com/synixad-png/asteroidy-ios/actions/runs/42211331700).
Tego wyniku NIE nazywać PASS, zanim GitHub Actions nie
potwierdzi wszystkich jobów. Dalsza bramka A:
rzeczywiste tapnięcia wszystkich 7 pozycji, powroty i
weryfikacja zgodności wizualnej z PC v568.


## BIEŻĄCY STAN — etap A / menu W3, 06.11.2026

**Kolejność A → B → C → D... bez zmian. Zadanie 14: 10% (+0 pp).
Postęp całego projektu: 27% wykonane / 73% pozostało.**

- **Potwierdzone:** dwie rzeczywiste symulacje GPU oryginalnego menu
  W3, NewHome290 i Vanguard431: [42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165)
  — oba joby PASS. Natywna kompilacja Swift/Metal oraz testy
  kolizji/asteroid po najnowszej zmianie dostępności:
  [42210096215](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210096215)
  — oba joby PASS.
- **Niepowodzenia wykryte faktycznymi testami:** poprzednie
  [XCTest 42204712384](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712384)
  nie znajdowały identyfikatorów przycisków `w3-home-0` na
  obu symulatorach; [GPU 42204712407](https://github.com/synixad-png/asteroidy-ios/actions/runs/42204712407)
  miał PASS iPhone i timeout 50 s na `simctl launch` iPada.
  **Nie zaliczono** tych prób.
- **Wdrożone naprawy:** SwiftUI udostępnia każdą z siedmiu
  akcji jako natywny element dostępności z nazwą i stabilnym
  identyfikatorem; XCTest sprawdza kontrolki w orientacji
  poziomej, naprawiono interpolację indeksu oraz włączono
  zrzut rzeczywistej hierarchii dostępności po niepowodzeniu.
  Czas operacji `simctl launch` ograniczono do 150 s (zamiast 50 s)
  bez osłabiania kontroli prawdziwego obrazu i ukończonych
  komend Metal.
- **Bieżące testy:** [XCTest siedmiu przycisków
  42210375096](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210375096)
  oraz [GPU iPhone/iPad
  42210271128](https://github.com/synixad-png/asteroidy-ios/actions/runs/42210271128).
  Ich końcowy wynik **nie jest jeszcze potwierdzony**.
- **Etap A otwarty**, ponieważ nawigacja i pełna zgodność
  oświetlenia z Windows v568 nie są zaliczone. **Etap B
  jeszcze nierozpoczęty.** Wcześniej wydane, niepodpisane IPA
  pozostaje nienaruszone i jest na Dysku Google użytkownika.
  Nowego IPA nie generowano.


> **AKTUALNA KOLEJNOŚĆ WYKONAWCZA (06.11.2026):** na życzenie użytkownika
> priorytetem jest **widoczny przepływ gry**, nie pierwotna kolejność
> numerów: **A. natywne menu → B. wybór misji → C. wejście na planetę →
> D. pełna grywalna misja i wynik → E. kolejne planety/statki → F. AI i
> bossowie → G. kampania 26/26 → H. ustawienia/sterowanie → I. audio
> i zapis → J. optymalizacja i testy**. Szczegóły, bramki i zasady:
> [ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md](ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md).
> Późniejsza decyzja **zastępuje jedynie wykonawczą kolejność** („zadanie 9
> następne”) opisaną niżej jako historia. **Wszystkie 18 zadań, ich
> numery, zakresy i dotychczasowe procenty pozostają niezmienione.**
> Najbliższe do wykonania: **A. Menu, potem B. Wybór misji**.
> **06.11.2026 — IPA NA ŻĄDANIE WYDANE I SPRAWDZONE:**
> [GitHub Actions 42203939074](https://github.com/synixad-png/asteroidy-ios/actions/runs/42203939074)
> zakończony `success`, `ASTEROIDY_v568_W3_iPhone_iPad_UNSIGNED.ipa`
> (14 097 407 B, SHA256
> `ba0ab998837d6b769bb5ddfd2b027d712351dc6833390b80d12ab9a96b90ff2a`).
> Kompilacja fizycznego iOS ARM64, iPhone/iPad, 7 oryginalnych
> zasobów W3/Vanguard/H290 i CRC IPA — PASS.
> Potwierdzono hash ponownie po pobraniu pliku z GitHuba.
> **NIEPODPISANY:** niepotwierdzona instalacja na fizycznym iOS.
> Zobacz [raport wydania](Reports/V568_W3_IPA_RELEASE_2026-11-06.md).
> Snapshot wydania = `5242e4f`; dalsze commity nie znajdują się w IPA.
>
> **Etap A — GPU potwierdzone na iPhonie i iPadzie:**
> [GitHub Actions 42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165)
> oba joby `success`; NewHome290 516624 wierzchołków,
> oryginalny Vanguard431 194427 wierzchołków na iPadzie,
> zakończone komendy Metal i prawdziwe zrzuty. Po wydaniu IPA
> poszerzono *wyłącznie viewport* prawego podglądu statku
> ze 110 do 164 pt, nie zmieniając skali/siatki/animacji.
> Jest to kolejna wersja robocza, nie część wydanego IPA.
> Dotykowe 7 przycisków XCTest i porównanie oświetlenia
> 1:1 z Windows v568 nie są jeszcze zaliczone.
> Etap A **W TRAKCIE**, etap B jeszcze nierozpoczęty.
> **Zadanie 14: 10%, zmiana +0 pp; projekt 27%, pozostało 73%.**
>
> **Etap A, kolejny widoczny element (06.11.2026):** na podstawie
> źródłowego `GpuW3HomeReal333.cs` dodano do panelu HOME
> na iPadzie **oryginalny obracany statek Vanguard431**,
> zgodnie z domyślnym `Game.ShipType=1`. Nowy moduł
> `W3HomeShipPreview568.swift` korzysta z autentycznej
> siatki i tekstury w istniejącej paczce iOS, chronionych SHA256.
> Oddzielny shader W3 wykorzystuje źródłowy gładki
> Toon60, kamerę i rotację modelu. **Kompilacja iOS PASS**
> ([42202600804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202600804)).
> Realny test GPU podglądu statku i poprawionego światła planety:
> [42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165).
> Dotykowa nawigacja siedmiu przycisków:
> [42202807377](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202807377).
> **Wyniki obu wymagają potwierdzenia — nie uznawać ich za PASS
> dopóki nie zakończą się poprawnie**. Nie zmieniono
> zamkniętych mechanik 7/8 ani menu misji. **A nadal w trakcie,
> B nierozpoczęte; 14 = 10% (+0 pp), całe 27% / pozostaje 73%.**
> Bez IPA.
>
> **Kontynuacja testów W3 — najnowsza rewizja:** po dodaniu źródłowego
> podglądu statku Vanguard431 w menu testy interakcji zostały
> powiązane również z plikami podglądu statku, planety i
> kontraktu menu; zmiana tych plików wymusza XCTest iPhone/iPad.
> [Najnowszy test dotyku 42202753554](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202753554).
> [Test GPU 42202733165](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202733165).
> Nie zaliczać ich przed wynikami. Poprzedni test
> [42202329563](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202329563)
> zatrzymał się na preflight źródłowym, **nie na rzeczywistym dotyku**.
> Potwierdzona kompilacja iOS: job SUCCESS
> [42202600804](https://github.com/synixad-png/asteroidy-ios/actions/runs/42202600804).
> **A otwarte, B nierozpoczęte; zadanie 14: 10%, +0 pp;
> cały projekt: 27% / pozostało 73%. IPA nie generowano.**
>
> **Potwierdzony wynik etapu A — iPhone i iPad GPU PASS:**
> [workflow 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> zakończył oba symulatory wynikiem `success`.
> Natywna gra wyświetliła oryginalne logo i tło W3 oraz
> oryginalną planetę NewHome290 (172208 trójkątów), a Metal
> potwierdził wykonanie renderowania. Autentyczne obrazy:
> [iPhone](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493952002)
> i [iPad](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753/artifacts/13493651804).
> Oddzielne **testy siedmiu rzeczywistych dotknięć i powrotu**
> uruchomione w [workflow
> 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528).
> Nadal nie zaliczać etapu A przed wynikiem XCTest, porównaniem
> oświetlenia i potwierdzeniem pozostałych braków.
> **Nr 14: 10%, +0 pp. Projekt 27%, pozostało 73%. B jeszcze
> nierozpoczęte. Bez IPA.**
>
> **W3 — testy nawigacji (06.11.2026):** dodano natywny target
> `ASTEROIDYW3UITests` i dwie rzeczywiste próby XCTest
> na symulatorach iPhone/iPad: siedem dotykowych akcji W3 wraz z
> otwieraniem/zamykaniem paneli oraz wejście do diagnostycznej
> sceny 3D i powrót przez `MENU W3`.
> [Workflow 42200004528](https://github.com/synixad-png/asteroidy-ios/actions/runs/42200004528).
> Wyniki XCTest wymagają weryfikacji; nie oznaczać ich PASS,
> dopóki oba joby nie zakończą się sukcesem. Osobny
> [GPU/iPad 42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> ma PASS na iPadzie, iPhone pozostawał w trakcie archiwizacji
> raportu. **A nadal w trakcie, B nierozpoczęte;
> zadanie 14: 10%, +0 pp; całość 27%, 73% pozostało.** Bez IPA.
>
> **Ostatni wynik kompilacji (06.11.2026):**
> [42198113777](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113777)
> potwierdził `Compile iOS source only — SUCCESS` dla
> wprowadzonej oryginalnej planety NewHome290 po naprawie
> macierzy normalnych w shaderze. Test faktycznego obrazu
> [42198113753](https://github.com/synixad-png/asteroidy-ios/actions/runs/42198113753)
> sprawdza oba symulatory Apple, oryginalne 5 zasobów W3/H290
> i dowód GPU. Nie zaliczać go przed zakończeniem. **A w trakcie;
> 14 nadal 10%, +0 pp; projekt 27% / pozostało 73%, bez IPA.**
>
> **Nowa implementacja etapu A (06.11.2026):** oryginalny model
> centralnej planety `NewHome290` v568, H290, **172208 trójkątów**,
> 516624 wierzchołków, dwie grupy materiałów i źródłowa mapa
> lawy zostały zaimplementowane w oddzielnym podglądzie Metal
> `W3HomePlanetMetal568.swift` / `W3HomePlanet290.metal`.
> Dodatkowo wdrożono obrót palcem i oryginalne wspólne tło/logo W3
> bez zmiany bajtów zasobów. Testy kompletnej grafiki Apple GPU i
> dotykowej nawigacji wciąż trwają, zatem **A niezamknięte**.
> Najnowszy [test iPhone+iPad
> 42197653964](https://github.com/synixad-png/asteroidy-ios/actions/runs/42197653964).
> Oświetlenie jest częściowym portem, a zgodność wizualna PC
> v568 nie została jeszcze wykazana. **Projekt 27%, pozostaje 73%,
> zadanie 14: 10%, +0 pp.** Bez IPA.
>
>
> **Aktualizacja implementacji 06.11.2026:** etap **A w trakcie**.
> Dodano natywny, obsługiwany dotykiem ekran W3 jako domyślne
> uruchomienie, 7 autentycznych etykiet z `RendererW3Home328.cs`,
> aktywne panele komunikujące rzeczywisty status funkcji,
> bezpieczny powrót do istniejącej sceny diagnostycznej i
> przycisk `MENU W3` w tej scenie. Kompilacja iOS dla wersji z menu
> w GitHub Actions **PASS** (`42193391940` oraz `42193674926`).
> Pierwszy autentyczny zrzut z obu symulatorów: workflow
> [42193792251](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
> — wynik należy sprawdzić osobno, nie uznawać oczekującego za PASS.
> Oryginalne tło/logo W3 i proceduralna planeta w menu są
> nadal brakujące; dotykowe przejścia end-to-end nieprzetestowane.
> **Postęp zadania 14: 10%, zmiana 0 pp, cały projekt 27%.**
> **Dalsza realizacja A:** dostępny oryginalny ZIP JPEG/PNG v568
> `ASTEROIDY_v568_W3_ORIGINAL_MENU_ASSETS.zip` (857501 bajtów)
> nie został jeszcze wgrany na GitHub; po wgraniu narzędzie
> `Tools/prepare_v568_w3_original_assets.py` automatycznie
> sprawdza SHA256 i dołącza dwa współdzielone obrazy W3 do aplikacji.
> Natywny SwiftUI `SourceW3Images568` już obsługuje prawdziwe
> obrazy i odrzuca zamienniki. Pierwsza próba screenshotu menu
> [42193792251](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
> nie zaliczyła instalacji iPhone przez timeout środowiska
> `simctl install` 85 s. Limit podniesiono do 300 s, a nowy
> [test obu symulatorów 42194736690](https://github.com/synixad-png/asteroidy-ios/actions/runs/42194736690)
> został uruchomiony. Etap A nadal W TRAKCIE; procentów
> nie zwiększać przed dowodem rzeczywistych ekranów i nawigacji.

> Szczegółowe dowody i warunki zaliczenia:
> [ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md](ROADMAP_EXECUTION_RULES_18_TASKS_2026-11-06.md).


Źródło kolejności/nazw: zatwierdzony przez użytkownika zrzut harmonogramu 18 zadań z 2026-11-05. Nie zmieniać nazw ani zakresów bez decyzji użytkownika.

**Łączny postęp odniesienia: 27%; pozostało 73%.** To zachowany wynik zbiorczy, bez ponownego ważenia 18 zadań. **Zadanie 7 — Kolizje, obrażenia i zniszczenia: 100% implementacji modułu, bez zmian. Zadanie 8 — Asteroidy i fale walki: 100% implementacji modułu (poprzednio 96%, +4 pp).** W oryginalnym kodzie C# v556 zweryfikowano `Game.Wave`, `Action38`, `Balance70`, `Physics68`, `AmigaBounce265` i `Game.Step`. Przeniesiono wytrzymałość i skalę skał, w tym +1 HP dla Coop62, kolejność wygasania odłamków/ruchu/posiłków/kolizji/strzałów, ostrzeżenie o posiłkach 1.6 s, 3 fale 16-sekundowe i specyficzną niezniszczalną mechanikę odbijanych kul sektora 25. **Swift/Linux: 25/25 zestawów PASS w GitHub Actions `42049818376`, commit `74fe326e1db29daac94e93a7ef8a906d327adefb`; uwzględniono regresję sektorów 9 i 17.** Osobna kontrola natywnej kompilacji Apple w tym przebiegu **czekała w kolejce** podczas raportowania — nie wolno twierdzić, że jej wynik PASS jest znany. iOS/Metal nie zostały interaktywnie sprawdzone na rzeczywistym urządzeniu (etap 18). **Nie utworzono IPA.** Zrealizowane zadania 7 i 8 podlegają regresji, nie rozpoczynać ich od nowa. Ponadto podłączono do interfejsu testowego iPhone'a sektory 1/9/17/25 przez `App.swift` i `MetalRenderer.swift`; ich wybór resetuje odrębny sektor, lot i diagnostyczny stan obrażeń bez ingerencji w kampanię. Natywne typowanie tej rewizji przez Xcode jeszcze oczekiwało na runner macOS. AI, bossowie, wszystkie bronie, komplet misji oraz kampania nadal należą do osobnych zadań 9–13.

**Aktualizacja zadania 1 — GitHub IPA:** użytkownik zlecił wygenerowanie niepodpisanego IPA. Workflow `build-ios.yml` uruchomiono poprzez commit `18e18797046dd37807650313990913dce38ab522`, [run 42051262545](https://github.com/synixad-png/asteroidy-ios/actions/runs/42051262545). Faza Swift/Linux **PASS**, natywne `compile-device` w kolejce na macOS przy ostatnim sprawdzeniu. Bez sukcesu kompilacji i opublikowanego artefaktu nie należy deklarować dostępności IPA ani podwyższać zadania 1 do 100%. Po wdrożeniu i pomyślnym teście walidacji oryginalnych zasobów iOS stan zadania 1 wynosi **88% (poprzednio 85%, +3 pp)**; natywna kompilacja iOS oraz wynik IPA nadal pozostają do potwierdzenia.

**Aktualizacja zadania 2 — silnik Metal: 45% (poprzednio 40%, +5 pp).** Naprawiono źródłowo potwierdzoną rozbieżność z `SphereCombat67.cs:62` i `GpuSphere67.cs:414`: kamera sferyczna była obliczana, ale `MetalRenderer` rysował ze stałej kamery. `SphereCameraView556` przenosi wektory `SphereFocus67/Right67/Up67` i źródłową odległość oka `310/144.19674` w znormalizowanej skali; `MetalRenderer` wybiera dynamiczny widok tylko dla planety, `Ship.metal` liczy wektor BRDF od rzeczywistego oka. Arena płaska bez zmian. [Run 42052748443](https://github.com/synixad-png/asteroidy-ios/actions/runs/42052748443) — test 8 pozycji i 240 kroków oraz parsing Swift **PASS**. Natywna kompilacja Xcode/Metal nowych zmian i wizualny test na urządzeniu nie zostały jeszcze wykonane. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Oddzielnie budowane IPA z `18e187970` nie zawiera tej późniejszej poprawki.


| Nr | Zadanie (stała nazwa) | Postęp odniesienia |
|---:|---|---:|
| 1 | Kompilacja i infrastruktura iOS | 88% |
| 2 | Silnik graficzny Metal | 89% |
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

## Kontrola bieżąca — 05.11.2026

**Zadanie 1: 88% (bez zmiany).** Workflow publikacji niepodpisanego IPA `42051262545` przeszedł testy Swift/Linux, lecz pierwsza próba `compile-device` została **anulowana przed przydzieleniem runnera macOS**, bez kroków i bez logów kompilatora. Nie ma dowodów na błąd kodu; przyczyna anulowania nie jest potwierdzona. Ponowiono **wyłącznie anulowany job** przez GitHub Actions, co utworzyło próbę `run_attempt=2` tego samego przebiegu. Podczas ostatniego sprawdzenia `compile-device` nadal **queued**; opublikowane artefakty: **0**, IPA **niegotowe**. Nie uruchomiono nowego `build-ios.yml` na późniejszych commitach.

**Zadanie 2: 45% (bez zmiany postępu do czasu weryfikacji Apple Metal).** Po audycie oryginalnych `Orbit50.cs:32`, `GpuSphere67.cs:420` i `GpuIntro41.cs:455` wyeliminowano drugi problem renderera: duplikat macierzy widoku oraz błędne pionowe FOV `36°` w widoku planety zamiast źródłowych `53.1301°`. `SphereCameraView556.viewColumnMajor` jest wspólnym źródłem macierzy dla Swift/Linux i Metal; `SphereProjection556` wyznacza źródłowe pionowe FOV dla planety, bez zmiany płaskiej areny. [Run 42055630937](https://github.com/synixad-png/asteroidy-ios/actions/runs/42055630937): test macierzy, perspektywy i parsing Swift **PASS**. Xcode/Metal GPU po tych poprawkach nadal **niezweryfikowane**; nie deklarować kompletu iOS ani zwiększenia zadania 2 bez takiego testu. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.

**Kontrola IPA tylko na polecenie użytkownika:** użytkownik odwołał automatyczne sprawdzanie; harmonogram monitorowania IPA został **wyłączony**. Stan GitHub Actions i dostępność pliku należy sprawdzać wyłącznie po jego nowym, wyraźnym poleceniu. Nie ingeruje to w trwające zadania GitHub ani w sam projekt.

**Dalszy rozwój zadania 2 (45%, bez zawyżania):** w oparciu o bezpośrednie porównanie oryginalnego `Windows/src/GpuSphere67.cs:4,63,133–134,368` poprawiono modelowe osie statku i asteroid w `MetalRenderer`. `SphereSurfaceStamp556` odwzorowuje prawa/przód/normalna, przesunięcie `Shell67=HomeWorldOuterRadius523+15`, współczynnik `Scale67=Shell67/Sphere67.Radius`; modele dostają źródłowy `angle`, przechył i pochylenie, a sektor 25 radialny podskok. **PASS**: [GitHub Actions 42057687378](https://github.com/synixad-png/asteroidy-ios/actions/runs/42057687378), testy stempla w 8 punktach × 4 kierunkach, razem z kamerą i parsowaniem Swift. Nie twierdzić, że zmiana była już testowana w prawdziwym rendererze iPhone/Apple GPU. Wszystkie dane modeli, fizyka, kooperacja i kampania są nietknięte. Szczegóły: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. `Zadanie 1: 88%` i `zadanie 2: 45%` pozostają bez zwiększenia do czasu kolejnego potwierdzonego etapu.

**Aktualizacja najnowsza zadania 2 — niebo źródłowe, 05.11.2026:** **47% (poprzednio 45%, +2 pp)**. Na podstawie rzeczywistych `Windows/src/GpuAmbient37.cs:6–7` i `GpuIntro41.cs:25–26,452` odtworzono deterministyczny `SpaceHash207/SpaceRand207`, 1500 kierunków, wielkości i barw gwiazd oraz niebo związane z pozycją kamery w `MetalRenderer`; jeden statyczny bufor GPU zastępuje 1500 pojedynczych zgłoszeń. Odtworzono źródłowy `GpuSphere67.cs:420` kolor czyszczenia planety `(.012,.021,.04)`; płaska arena i jej wcześniejsze 130 gwiazd nie zostały zmienione. `Tests/SphereCameraView556Tests.swift` sprawdza niezależne, obliczone z oryginalnego uint-hash wartości i 1500 unormowanych kierunków. [GitHub Actions 42060152260](https://github.com/synixad-png/asteroidy-ios/actions/runs/42060152260) — **PASS** (Swift/Linux, parsing SwiftUI/Metal). Oryginalny `IntroHalo` z teksturowaną i przezroczystą poświatą, mgławice i promienie **NIE są jeszcze odtworzone**; GPU iPhone/Xcode nowych zmian **NIE testowano**. 47% jest oceną częściowej implementacji zgodnej z danymi źródłowymi, **nie** potwierdzeniem jakości grafiki na urządzeniu. Audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`.

**Aktualizacja zadania 2 — nieprzezroczyste trójkąty zastąpione przez gwiazdy RGBA:** **48% (poprzednio 47%, +1 pp)**. W `MetalRenderer.swift` poprzednie 4500 wierzchołków trójkątów sky zamieniono na **1500 punktów GPU** z oryginalnymi z `GpuIntro41.cs` rozmiarami 0.7/1.4/2.8 px, paletą i przezroczystością. `Ship.metal` ma niezależne `skyPointVertex` i `skyPointFragment`, rozdzielone zgodnie z Metal Shading Language: `point_size` tylko w wyjściu vertex, `point_coord` z rasteryzatora. Nowy pipeline ma `sourceAlpha`/`oneMinusSourceAlpha` i **nie zapisuje głębi**, po narysowaniu nieba przywraca normalny pipeline PBR i depth test; płaska arena nietknięta. [GitHub Actions 42062234192](https://github.com/synixad-png/asteroidy-ios/actions/runs/42062234192) **PASS**: źródłowe testy Swift/Linux, odrębne statyczne testy kontraktu shaderów i parsowanie plików SwiftUI/Metal. Test statyczny **nie zastępuje kompilacji shaderów Apple Metal ani oględzin obrazu na iPhonie**. Autentyczny teksturowany `IntroHalo`, mgławice i promienie nadal **nie są odtworzone**. Wzrost o 1 pp wynika z wdrożenia przekazywania źródłowej alfy/rozmiaru i przetestowanego okablowania, nie z potwierdzonego wyglądu na GPU. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zawiera ograniczenia. **Nie sprawdzano IPA ani nie zmieniano automatyzacji** zgodnie z instrukcją użytkownika.

**Dokończenie skalowania gwiazd dla Retina (zadanie 2 bez zmiany 48%):** `GpuIntro41.cs:25–26` używa wzorca 720 px; w `SphereSky207.drawableScale`, `MetalRenderer` i `skyPointVertex` podano `height/720` z rzeczywistego `MTKView.drawableSize`. Efekt nie wymaga nowych buforów ani draw call. Testy 360/720/1440 px i przypadków nieprawidłowych oraz kontrakt danych GPU: [GitHub Actions 42062785842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42062785842) **PASS** (Swift/Linux, parsowanie Swift, kontrola statyczna MSL). 48% pozostaje, ponieważ nie przeprowadzono jeszcze właściwej kompilacji Metal ani testu obrazu na iPhonie. Rozmiary i alfa 1500 gwiazd zachowują dane oryginalnego `GpuIntro41.cs`; pełne źródłowe `IntroHalo` nadal nie jest przeniesione. Szczegóły w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Statusu IPA nie sprawdzano.

**Aktualizacja źródłowa zadania 2 — 52% (poprzednio 48%, +4 pp):** odnaleziono rzeczywisty ZIP oryginalnego ASTEROIDY v556 i sprawdzono `Windows/src/GpuAmbient37.cs:5–7`, `Gpu2DRenderer.cs:68,70,74`, `GpuIntro41.cs:23,451–452` i `GpuSphere67.cs:420`. W miejsce wcześniejszej przybliżonej maski punktowej `smoothstep` wprowadzono **dokładną generację tekstury 64×64 BGRA premultiplied StarTexture** z oryginalnego kodu, liniowe próbkowanie, źródłowe mieszanie `ONE/ONE_MINUS_SRC_ALPHA`, podstawowe średnice 2,8/5,6/11,2 px oraz dla gwiazd `rz>.87/.98` dodatkowe halo o średnicy 20/42 px z alfą 125/255. W jednym rysowaniu jest **1706 warstw dla 1500 źródłowych gwiazd** (1294 małe, 172 jasne, 34 bardzo jasne; 161 ciepłych). Osobna tekstura jest współdzielona; płaska arena i jej stary shader PBR są nietknięte. [GitHub Actions 42065903420](https://github.com/synixad-png/asteroidy-ios/actions/runs/42065903420): Swift/Linux + kontrakt shaderów **PASS**. Natywny `Xcode Metal/Swift compile-only` na macOS **czeka**; shader Metal nie jest jeszcze potwierdzony przez kompilator Apple ani testowany obrazowo na iPhonie. Ta zmiana zamyka **źródłowy port tekstury gwiezdnej i gwiezdnych IntroHalo**, ale **nie** cały `IntroSky` (mgławice, promienie, inne obiekty 2D) i nie zadanie 2 jako całość. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zawiera dokładne uzasadnienie, a stare opisy uproszczonych trójkątów są oznaczone jako stan historyczny. Procent 52% dotyczy prac implementacyjnych zweryfikowanych testami Swift/Linux, nie testów Apple GPU. **IPA nie sprawdzano**.

**Aktualizacja zadania 2 — Promienie słońca v556: 55% (poprzednio 52%, +3 pp).** Na podstawie realnych `Windows/src/GpuIntro41.cs:25,454` i `Windows/src/GpuCosmos39.cs:8–10` połączono z `MetalRenderer` poświaty słońca o promieniach 130/55/15 i pięć oryginalnych wachlarzy promieni (4×6 komórek, po 6 wierzchołków na komórkę), razem **738 wierzchołków**, bez animacji/losowych parametrów. `SphereSolarOverlay556` projektuje źródłowy kierunek `(0.6,0.8,0.32)*900` na ekran przez `SkyProject55` bez translacji oka, a renderer zmienia wyłącznie jednolity 16-bajtowy uniform, współdzieli teksturę `StarTexture` i wykonuje jedno rysowanie 2D przed planetą z premultiplikowaną alfą. Utrzymano dotychczasowy PBR i oddzielną płaską arenę. **PASS**: [GitHub Actions 42068464591](https://github.com/synixad-png/asteroidy-ios/actions/runs/42068464591), testy Swift/Linux geometrii i projekcji, statyczne testy shaderów, testy starszych mechanizmów kamery/gwiazd, parsowanie Swift. **Nie zaliczono jeszcze** natywnego Xcode/Apple Metal ani testów wizualnych GPU; zadanie `Xcode Metal/Swift compile verification ONLY (NO IPA)` było w kolejce, więc brak potwierdzenia kompilacji. W dalszym ciągu do przeniesienia zostały `DrawDeepSpace55/CloudLayer` (mgławice, planety tła, czarna dziura), opcje renderera i szersze efekty; brak udawania pełnego `IntroSky`. Szczegółowy audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Nie sprawdzano IPA.

**Aktualizacja zadania 2 — mgławice oryginalnego v556: 58% (poprzednio 55%, +3 pp).** Na podstawie rzeczywistych `Windows/src/GpuCosmos39.cs:4–7` oraz `GpuIntro41.cs:122,451` dodano `SphereNebula556` z dokładnym hashem 32-bit `CloudHash`, pięcioma oktawami `CloudNoise` i generacją premultiplikowanych tekstur **256×256**. W widoku planetarnym oryginał wykorzystuje dwie palety 0/1, współdzielone przez **24 dalekie + 12 bliższych warstw**, dlatego `MetalRenderer` tworzy tylko jedną 2-warstwową teksturę `MTLTextureType2DArray`, jedną niezmienną siatkę **216 wierzchołków** i jeden draw call GPU dla chmur przed gwiazdami/poświatami. `nebulaOverlayVertex` wykonuje `SkyProject55` w czasie renderowania, bez aktualizowania siatki i duplikowania pamięci. **PASS:** [GitHub Actions 42071274522](https://github.com/synixad-png/asteroidy-ios/actions/runs/42071274522) — testy Swift/Linux oryginalnych wyników hasha i pikseli BGRA, 36 warstw/projekcji, dotychczasowe testy kamery i słońca, kontrola statyczna połączeń shaderów oraz parsowanie Swift. **Wciąż brak** natywnego testu kompilatora Apple Metal, fizycznego iPhone'a oraz źródłowych planet głębokiego kosmosu i czarnej dziury z `DrawDeepSpace55`; poświaty nie gwarantują wierności obrazu 1:1. Nie zwiększono zadania 1 ani innych zadań. Kolejne prace pozostają w zadaniu 2; szczegółowy audyt: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. Status IPA zgodnie z poleceniem użytkownika **nie był sprawdzany**.

**Aktualizacja zadania 2 — czarna dziura v556: 61% (poprzednio 58%, +3 pp).** Bezpośrednio z oryginalnego `Windows/src/GpuIntro41.cs:62–127` przeniesiono trzy niezależne, generowane proceduralnie tekstury `BuildBlackHoleDisk55(false)`, `BuildBlackHoleCore55()`, `BuildBlackHoleDisk55(true)` po **640×640 BGRA/PArgb** każda. `BlackHoleSky55` zachowuje źródłowy obrót dysku 25°, oddzielny prześwit za rdzeniem, soczewkowanie oraz przedni pierścień; w jednym współdzielonym buforze tekstur Metal są **3 obrazy GPU**, generowane tylko raz. Jednym rysowaniem 60 wierzchołków rysuje **3 dodatkowe poświaty + 4 animowane promienie + 3 warstwy dysk/rdzeń/przód** w źródłowej kolejności. Poprawiono też wcześniejszą niezgodność `DrawDeepSpace55`: chmury są rysowane jako **24 dalekie → czarna dziura → 12 bliskich**, z tego samego współdzielonego bufora i 2 tekstur mgławic, bez nowych uploadów per klatka. Nadal **brakuje 3 planet tła**, więc obecna kolejność nie jest jeszcze pełnym oryginałem. **PASS**: [GitHub Actions 42074436010](https://github.com/synixad-png/asteroidy-ios/actions/runs/42074436010), `source-camera-linux` — wszystkie trzy wygenerowane tekstury i niezależne wartości pikseli, 10 warstw/projekcja, poprawne powiązania kodu Metal, regresje kamery/gwiazd/słońca/mgławic, parser Swift. **Nie wykonano jeszcze** natywnego testu Apple Metal/Xcode ani testu obrazu na fizycznym iPhonie; osobny `Xcode Metal/Swift compile verification ONLY (NO IPA)` oczekiwał na runner macOS. Zakres jest implementacyjny, bez deklaracji 100% zgodności wizualnej lub sprawdzenia wydajności; pozostałe 17 zadań i wynik zbiorczy 27% pozostają bez zmian. Szczegóły w `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. **Nie sprawdzano IPA**.

**Aktualizacja zadania 2 — wszystkie trzy planety głębokiego kosmosu: 64% (poprzednio 61%, +3 pp).** Z rzeczywistych `Windows/src/GpuIntro41.cs:27–63,122–127` odtworzono `BuildDeepPlanet55(0,1,2)`: trzy różne obrazy **320×220**, dokładne wzory powierzchni `PlanetShade55`, źródłowe światła/pasma/chmury/blizny oraz oryginalne parametry pierścieni i refleksów GDI+. Każdy świat ma własną animację `AnimatedSkyDirection55`, ograniczenia projekcji `SkyProject55`, wymiary, maksymalną skalę i poświatę. `MetalRenderer` generuje trzy tekstury **tylko przy inicjalizacji**, przechowuje je we wspólnym `MTLTexture` trzywarstwowym i **ponownie wykorzystuje** istniejący premultiplikowany shader/pipeline czarnej dziury; trzy planety są rysowane **po 24 dalekich chmurach i przed czarną dziurą**, a 12 bliskich warstw zostaje po tych obiektach. **PASS:** [GitHub Actions 42077736535](https://github.com/synixad-png/asteroidy-ios/actions/runs/42077736535), `source-camera-linux` — 12 niezależnych kolorów referencyjnych, trzy pełne tekstury 320×220, PArgb, rzutowanie/animacja, kolejność rysowania i regresje kamery/gwiazd/słońca/mgławic/czarnej dziury. **Jawne ograniczenie:** GDI+ stosuje specyficzny antyaliasing elips i łuków — algorytm Swift odtwarza geometrię, ale wygładzenie pikseli pierścieni jest **przybliżeniem**, a nie kopią 1:1. Natywna kompilacja Xcode/Apple Metal i test na GPU iPhone'a dla bieżącego kodu nadal **niepotwierdzone**; procent 64% dotyczy sprawdzonej logiki źródłowej i połączeń, nie działającej gry na urządzeniu. Nie rozpoczynano zadania 3, zachowano pozostałych 17 procentów bez zmian; postęp zbiorczy **27% jest historycznym punktem odniesienia, nie nowym obliczeniem**. Szczegóły: `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md`. **Statusu IPA nie sprawdzano.**

**Aktualizacja zadania 2 — odroczone tekstury v556: 65% (poprzednio 64%, +1 pp).** Oryginalne `GpuIntro41.DrawSkyPlanet55/DrawSkyBlackHole55` tworzą obrazy dopiero po pozytywnym `SkyProject55`, a `GpuCosmos39.CloudLayer` utrzymuje cache. Port iOS wcześniej tworzył trzy duże zasoby tekstur w `MetalRenderer.init`, nawet gdy działała tylko płaska arena. Dodano `SkyTextureGate55` i trzy cache opcjonalnych `MTLTexture` w `MetalRenderer`: **0 dużych alokacji w trybie płaskim**, planetę i czarną dziurę po raz pierwszy tworzy się wyłącznie po pozytywnym teście widoczności, chmury dopiero po źródłowym `SkyProject55` potwierdzającym widoczność przynajmniej jednej z 36 warstw podglądu sfery; wszystkie pozostają współdzielone i nie są wielokrotnie regenerowane. Przy błędzie alokacji jest czytelny `NSLog` i brak nieograniczonych ponownych prób. Odroczono tworzenie **6 284 288 B** nieskompresowanych danych BGRA8 (4 915 200 B czarna dziura + 844 800 B trzy planety + 524 288 B dwa motywy mgławic). **To nie jest pomiar VRAM ani FPS.** Zachowano źródłową kolejność renderowania, geometrię, wzory barw, kamery, shader PBR i moduły zadań 7/8. **PASS:** [GitHub Actions 42081362292](https://github.com/synixad-png/asteroidy-ios/actions/runs/42081362292), `source-camera-linux`: nowy test jednokrotnej alokacji, wszystkie poprzednie regresje oryginalnego nieba i kontrola statyczna wiązań Metal; natywna kompilacja Apple/Xcode i test fizycznego GPU nadal **niepotwierdzone**. `AUDYT_ZADANIE_2_v556_METAL_CAMERA.md` zaktualizowano. **Jednorazowy build IPA** zlecony przez użytkownika uruchomiono osobnym przebiegiem [42078976090](https://github.com/synixad-png/asteroidy-ios/actions/runs/42078976090) z commita `d475b114`, który według jedynej kontroli został przyjęty do kolejki. **Nie ma potwierdzenia gotowego IPA**; następnie kontynuowano implementację, więc nowe optymalizacje po tym commicie NIE znajdują się w jego snapshotcie. Nie uruchamiano drugiej kompilacji ani nie monitorowano dalej IPA. Łączny raportowany postęp 27% pozostaje punktem odniesienia, a pozostałe 17 zadań zachowuje poprzednie wartości.

## Aktualizacja zadania 2 — indywidualne ładowanie bitmap źródłowych, 05.11.2026

**Zadanie 2: 67% (poprzednio 65%, +2 pp).** Audyt bezpośrednio wskazuje, że oryginalne `GpuIntro41.DrawSkyPlanet55/BuildDeepPlanet55` i `GpuCosmos39.CloudLayer/NebulaTexture(theme)` inicjują **każdy** obraz oddzielnie przy pierwszej widoczności. Poprzedni port iOS co prawda odkładał utworzenie całej tablicy Metal do pierwszej widoczności, ale wtedy generował wszystkie trzy planety 320×220 i oba motywy mgławic 256×256, również niewidoczne.

- **Wdrożono:** `SkyTextureSliceCache55`, osobny stan gotowości każdego ze stylów 0/1/2 i motywów mgławic 0/1. `MetalRenderer.ensureDeepPlanetTextures55(style:)` generuje i przesyła pojedynczy obraz planety dopiero po źródłowym `DeepSkyPlanets55.project`. `ensureCloudTextures55(camera:)` sprawdza 36 kierunków `SphereNebula556.Layer.projected` i generuje wyłącznie widoczne motywy. Dane są przechowywane do końca życia renderera; nie ma wielokrotnego generowania dla widzianych wcześniej stylów.
- **Bez regresji architektury:** zachowano jedną teksturę tablicową Metal 3×320×220 i jedną 2×256×256, gotowe procedury generowania pikseli z v556, shadery `Ship.metal`, 24 dalekie chmury → trzy planety → czarna dziura → 12 bliskich chmur → gwiazdy/słońce, płaską arenę, etapy 7/8 i zasoby Windows/SteamOS. Nie zgłaszamy dodatkowej oszczędności VRAM: tablica GPU nadal rezerwuje rozmiar wszystkich warstw. Zysk dotyczy odroczenia **obliczeń i przesyłania bitmap** niewidocznych obiektów; nie ma pomiarów czasu klatki.
- **Testy:** lokalna kontrola izolowanej logiki Swift/Linux przeszła dla 6 permutacji widoczności planet i obu kolejności tematów mgławic, 240/720 ponownych odczytów oraz 14/14 kontroli kontraktu źródeł wykonanych na aktualnych plikach GitHub. Repozytoryjne testy `SkyTextureGate55Tests.swift`, `SkyTextureGateSourceContract55.py`, `DeepSkyPlanetsSourceContract556.py` i `NebulaSourceContract556.py` zostały rozszerzone.
- **Niepotwierdzone:** GitHub Actions `source-camera-linux` dla najnowszego commita oczekuje na runner; nie wolno przedstawiać go jako PASS. Natywna kompilacja Apple/Xcode/Metal, prawdziwe GPU, wizualna zgodność 1:1, FPS, VRAM oraz test na iPhone 15 Pro Max/iPad Pro M2 są nadal do wykonania. Nie uruchomiono kolejnego builda IPA ani nie sprawdzano jego wyniku.

**Łączny port: 27% (historyczny niezmieniony wskaźnik), pozostało 73%.** Zadanie 1: 88%, zadania 7 i 8: 100% implementacji każdego modułu, pozostałe zadania i stała lista 18 pozycji bez zmian. Następny zakres w otwartym zadaniu 2: doprowadzenie źródeł do natywnej kompilacji Apple, weryfikacja prawdziwego renderingu i pomiar GPU oraz naprawa wyłącznie potwierdzonych rozbieżności z v556.

## Aktualizacja zadania 2 — oryginalne near/far kamery Metal, 05.11.2026

**Zadanie 2: 68% (poprzednio 67%, +1 pp).** Kolejna bezpośrednio potwierdzona rozbieżność z kodem v556: `Windows/src/GpuIntro41.cs:455` i `GpuSphere67.cs:420` używają frustum `near=0.4`, `far=1600` w źródłowych jednostkach, a `Windows/src/GpuPlanetGltf463.cs` definiuje znormalizowaną skalę planety `100*1.4419674`. Poprzedni `MetalRenderer.perspective` używał dla **obu** kamer wartości `near=0.1,far=20` (ustawienie istniejącej płaskiej areny). To nie był oryginalny zakres depth clip dla sfery.

**Wdrożono wyłącznie w zadaniu 2:**
- `SphereProjection556.sourceFar=1600`, `normalizedNear=0.4/(100*1.4419674)`, `normalizedFar=1600/(100*1.4419674)` i `clipPlanes(spherical:)`. `MetalRenderer.perspective` pobiera obie płaszczyzny z tego samego źródła co znormalizowane modele i oko. Oryginalne 53.1301° FOV pozostaje, a płaska arena zachowuje **dokładnie** swoje dotychczasowe 0.1/20.
- `Tests/SphereCameraView556Tests.swift` sprawdza obie normalizacje, niezależny flat fallback, poprawne NDC z=0 na near i z=1 na far. Dodano `Tests/SphereProjectionSourceContract556.py` i test w workflow `verify-metal-camera.yml` **bez IPA**.
- Naprawiono wykryty błąd testu `Tests/SkyTextureGateSourceContract55.py`: kontrola porządku `project` przed `ensureDeepPlanetTextures55` wskazywała starą sygnaturę bez `style:`, mimo poprawnie zaktualizowanej implementacji. Dzięki temu test może realnie sprawdzać nową funkcję.

**Weryfikacja dostępna:** skompilowano i uruchomiono izolowany wycinek rzeczywistego nowego wzoru na Swift/Linux: znormalizowana sfera `near=0.002773988, far=11.095952`, płaska arena `near=0.1, far=20.0`, cztery granice NDC — **PASS**. Dodatkowe warunki źródłowe sprawdzono przez bezpośredni odczyt aktualnych plików GitHub. Natywna kompilacja Xcode/Metal, render na Apple GPU oraz test urządzeniowy **nie zostały potwierdzone**; nowe GitHub Actions mogą czekać w kolejce. Nie przedstawiać wycinka jako pełnego testu projektu.

**Granica zadania:** nie zmieniono żadnego C# Windows/SteamOS, zasad walki, mechanik zadań 7/8, formatów GLB, źródeł planet ani oddzielnego iPhone-only workflow. Łączny 27%/73% to nadal nieprzeliczany historyczny wskaźnik portu; pozostałe 17 wartości i pełna zatwierdzona lista nie ulegają zmianie. Zadanie 2 pozostaje **otwarte**; następny etap to natywna kompilacja Apple i przegląd rzeczywistego renderingu, bez udawania testów na fizycznym iPhonie.

## 05.11.2026 — iPhone + iPad, uruchamianie źródłowej sceny, audyt prawdziwej gry

- **Co wykonano:** `project.yml` zachowuje oryginalne `TARGETED_DEVICE_FAMILY: '1,2'`; dodano niezależny `build-ios-iphone-ipad-manual.yml` używający macOS Intel i walidacji IPA dla obu rodzin, uruchamiany **tylko ręcznie**. Nie odpalono nowego IPA. Przejściowy iPhone-only z run `42090319849` pozostaje wyłącznie poprzednim artefaktem iPhone.
- **Bieżące zadanie 2:** `App.swift` domyślnie kieruje do istniejącej oryginalnej sceny Boreas 3D zamiast 9-asteroidowej płaskiej areny testowej. Arena, testowe sektory 1/9/17/25, narzędzia diagnostyczne i atlas kampanii zachowano. Dwie zwarte linie przycisków ułatwiają przełączanie na obu urządzeniach. **To nadal testowa scena, a nie oryginalna pierwsza misja**.
- **Zweryfikowano:** GitHub run [42093245632](https://github.com/synixad-png/asteroidy-ios/actions/runs/42093245632) `original-assets` PASS: oryginalne zasoby i kontrakt domyślnej sceny/obu rodzin. Po zmianie workflow Xcode uruchomiono osobną weryfikację Apple `42093300828` **bez IPA**; wynik natywnego kompilatora i renderu urządzeniowego nie był jeszcze znany.
- **Źródła pełnej gry:** potwierdzono 150 MB archiwum użytkownika ASTEROIDY PC v568 (Windows+SteamOS). Właściwy `Game.Mode.Menu`, siedem przycisków W3 HOME, oryginalny 820-kamienny intro belt, wejście `StartCampaign/EnterOrbit50/LaunchOrbitMission50` są w C#. Repozytorium iOS ma jednak port wybranych mechanik v556; **nie utożsamiać go ze skończoną grą i nie zgadywać brakującego kontrolera misji**. Szczegóły w `AUDYT_RZECZYWISTEJ_GRY_IOS_V556_WOBEC_WINDOWS_V568.md`.
- **Następny krok:** domknięcie trwającego zadania 2: sprawdzenie rzeczywistej geometrii i sekwencji renderingu Metal oraz stopniowe wiązanie z oryginalnym rendererem i stanami gry. Nie rozpoczynać nowego zadania 14 ani nie deklarować uruchomienia misji przed integracją wymaganych modułów.
- **Zmiana postępu:** zadanie 1 **88% (0 pp)**, zadanie 2 **68% (0 pp)**, całość **27% (0 pp), pozostało 73%** — konfiguracja manualna i wstępny wybór sceny nie potwierdzają gotowości pełnej gry lub testu iPhone/iPad.

## 05.11.2026 — zadanie 2, NOWA SCENA: źródłowy przelot orbitalny 3D

**Postęp implementacyjny zadania 2: 70% (+2 pp wobec 68%).** Łączny wskaźnik odniesienia 27% (pozostało 73%) pozostaje bez zmian, ponieważ brak ponownego ważenia wszystkich zadań. Wszystkie pozostałe pozycje harmonogramu są bez zmian. Nowa scena nie oznacza ukończenia zadania 2 ani kompletnych misji.

**Wykonano rzeczywisty kod:**
- Nowy czysty Swift `ASTEROIDYiOS/IntroOrbit41.swift`: original `Windows/src/Intro41.cs:50–81`, 16 s, dokładny przebieg `Ship(t)`, `Camera(t)`, `CraftOrientation(t)`, `View`, oryginalny obrót planety 29+time*2.2°, źródłowa skala `MissionPlanetScale523(24)` normalizowana do 0,24.
- `OrbitWorld51.cs`: deterministyczny generator źródłowych **820 pozycji pasa asteroid**, seeded `Random(4109)`, wielkości, seed, kontrole wolnego korytarza kamery (4×81 próbek), reguły source cull. Uwzględniono **legacy** wariant pasa; gałąź `NewHome290.Enabled` w v568 zmienia położenia zgodnie z faktyczną geometrią terenu i nadal wymaga osobnego, zweryfikowanego portu. Nie udawać, że stary wariant = nowy teren.
- `MetalRenderer.swift` pokazuje inną, rozłączną scenę: źródłowy ruch kamery, 1 500 już przeniesionych gwiazd, oryginalny mesh Vanguard, prawdziwy model Boreas GLB w rozmiarze oryginalnego intro (a nie nowa kula), orbitalny pas 820 pozycji z frustum-cullingiem. W tej fazie siatki asteroid są tymczasowymi **oktaedrami** z portu, a wizualna skala statku oparta jest na sprawdzonym promieniu rzemiosła z walki; **oryginalne seed-specific `IntroStone`, `StoneNormal56`, pełne tło i efekty, oryginalny terrain-enabled belt wymagają jeszcze portu**.
- `App.swift` domyślnie pokazuje "PRZELOT ORBITALNY / ŹRÓDŁOWA KAMERA" z etykietą "SCENA ROBOCZA • NIE JEST PEŁNĄ MISJĄ", zegarem 0–16 s i przełącznikiem "BOREAS 3D"/"PRZELOT 3D". Istniejące testy sferyczne, osobna płaska arena, atlas 26 misji, zapis maski, mechaniki 7/8 zostały pozostawione; przelot **nie zalicza misji** i nie uruchamia sztucznej kampanii. Ponieważ prawdziwy kontroler misji nie istnieje, po 16 s przelot zapętla się jako podgląd.
- Konfiguracja `project.yml` i ręczny workflow `build-ios-iphone-ipad-manual.yml` nadal obsługują **oba urządzenia**, ARM64, iOS 17+, bez uruchamiania nowego IPA.

**Weryfikacja:** [GitHub Actions 42097505146](https://github.com/synixad-png/asteroidy-ios/actions/runs/42097505146), `source-camera-linux` PASS na źródłowej osi IntroScene41, 820 Belt51, kontraktach astronomii, kalibracji projekcji i kontroli regressions. [GitHub Actions 42097618493](https://github.com/synixad-png/asteroidy-ios/actions/runs/42097618493) PASS weryfikacji autentycznych zasobów, konfiguracji i parsowania zmienionego Swifta. `Xcode Metal/Swift compile verification ONLY (NO IPA)` dla najnowszego commita **nie zakończył się podczas raportowania**; nie ma dowodu pełnej kompilacji iOS ani testu Apple GPU. **Nowego IPA nie wygenerowano.**

**Następnie w zadaniu 2:** port oryginalnych `IntroStone` i `StoneNormal56` dla pasa, świateł/głębi/efektów intro z rzeczywistych źródeł, zgodność nowego `NewHome290` tam, gdzie ma zastosowanie; następnie kompilacja Xcode bez IPA. Dopiero po udanym buildzie można zgłosić użytkownikowi gotowość do *zlecenia* nowego unsigned IPA iPhone+iPad. Nie twierdzić, że scena jest 1:1 ani sprawdzona na urządzeniu.

## 05.11.2026 — kontynuacja zadania 2: źródłowe siatki IntroStone

Do nowej sceny `IntroOrbit41` dołączono `IntroRockGeometry41.swift` z oryginalnymi funkcjami `GpuIntro41.IntroStone`, `StoneNormal56`, `StoneFace` i `StoneSubdivide56` (20 ścian ikosaedru, 320/1280 trójkątów w zależności od rozmiaru, trzy kratery i odrębne seedy, kolory i normalne źródłowe). `MetalRenderer` tworzy szczegółowy model maksymalnie **jednej nowej widocznej skały na klatkę**, zachowuje do 256 modeli GPU i używa tymczasowego oktaedru wyłącznie do momentu utworzenia danego modelu. Celem jest uniknięcie jednorazowego obciążenia CPU/RAM przez 820 pełnych modeli, lecz **faktyczny koszt FPS i pamięci nie został zmierzony**.

`Tests/IntroRockGeometry41Tests.swift` sprawdza liczby wierzchołków, normalne i kolory. `Tests/IntroOrbitSourceContract41.py` pilnuje, czy renderer rzeczywiście korzysta z oryginalnej procedury i ma limit cache. Odrębny szybki preflight kodu Swift w [GitHub Actions 42098254707](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098254707) zakończył się PASS, natomiast pełna weryfikacja nowego generatora `42098229568` i kompilacja Xcode/Metal **nie były zakończone podczas ostatniego sprawdzenia**. Nie wpisywać PASS w testach geometrii na podstawie wyników starszych commitów. **Nie ma nowego IPA ani testu na prawdziwym iPhonie/iPadzie.**

Zmiana harmonogramu pozostaje **wyłącznie w zadaniu 2: 70% (+2 pp względem wcześniejszego 68%)**, projekt całościowo 27% (pozostało 73%). Wynik nie jest podnoszony za prace bez udanego testu geometrii. Następny krok: dokończyć aktualne testy i kompilację Xcode bez IPA, zachować oryginalne siatki oraz uzupełnić wymagane elementy wierności sceny. Powiadomienie o gotowości do zlecenia IPA jest monitorowane oddzielnie — dopiero po potwierdzonym sukcesie obu zadań CI.

## 05.11.2026 — wynik pełnego testu geometrii przelotu

W [GitHub Actions 42098229568](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098229568) zadanie `source-camera-linux` zakończyło się **PASS** po dodaniu szczegółowych asteroid: oryginalna geometria `IntroRockGeometry41` (320/1280 trójkątów), normalne, seedy, projekcja kamery, pas 820 skał oraz regresje dotychczasowych shaderów i geometrii. To weryfikacja wykonania kodu Swift na Linux, **nie** na GPU Apple. Drugi job `Xcode Metal/Swift compile verification ONLY (NO IPA)` w tym samym przebiegu nadal czekał na runner macOS. Szybki parser plików Swift i kontrola oryginalnych zasobów [42098254707](https://github.com/synixad-png/asteroidy-ios/actions/runs/42098254707) również PASS. Brak testu iPhone/iPad oraz nowego IPA.

Za konkretną, wykonaną i przetestowaną geometrię indywidualnych skał postęp **zadania nr 2 wzrósł z 70% do 72% (+2 pp)**; od poprzedniej sesji raportowanej użytkownikowi 68% to łącznie **+4 pp**. Łączny historyczny postęp projektu nadal 27% (pozostało 73%), ponieważ nie przeważano zatwierdzonej listy zadań. Następna zależność: ukończenie kompilacji Apple Metal i weryfikacja pełnego 3D iOS przed świadomą próbą nowego IPA iPhone+iPad; stare IPA nie zawiera tej sceny.

## 05.11.2026 — kolejne funkcje i testy Metal, zadanie nr 2

**Zmiana zadania 2: 72% → 74% (+2 pp).** Wykonano i potwierdzono testami źródłowymi dwa konkretne elementy oryginalnego przelotu:
1. `GpuIntro41.CinematicIntro41`: pierścień 820 asteroid obraca się z dokładnym źródłowym `time*0.2°` wokół `IntroScene41.PlanetCenter`. Odcinanie niewidocznych skał używa pozycji **po** obrocie, zgodnej z macierzą Metal `T(center)*Ry(angle)*T(local)`. Nie zmieniono geometrii/kolizji trybu Boreas ani płaskiej areny.
2. Kompozycja źródłowego `GpuIntro41.IntroSky` w scenie orbitalnej: 24 dalekie chmury, 3 teksturowane planety, oryginalne dyski czarnej dziury, 12 bliskich chmur, 1500 gwiazd i 5 promieni słonecznych, w poprawnej kolejności. Wykorzystano istniejące zasoby/PSO i lazy texture cache z oryginalnego trybu sferycznego, lecz projekcję podłączono do `IntroScene41.View`, nie kamery walki.

**Potwierdzone testy:** [GitHub Actions 42100560721](https://github.com/synixad-png/asteroidy-ios/actions/runs/42100560721), `source-camera-linux` **SUCCESS** dla aktualnych plików kodu: matematyka kamery i obrotu, 820 pozycji, oryginalne siatki IntroStone, ochrona kolejności efektów i dotychczasowe mechanizmy sky. [GitHub Actions 42100472060](https://github.com/synixad-png/asteroidy-ios/actions/runs/42100472060) **SUCCESS**: parser Swift, autentyczne zasoby i preflight iPhone/iPad. `Xcode Metal/Swift compile verification ONLY (NO IPA)` w przebiegu 42100560721 **pozostawał w kolejce**, więc nie deklarować gotowego IPA ani testu GPU.

**Pozostało w zadaniu 2:** test natywnego Xcode na aktualnym źródle, rzeczywiste efekty światła i pogody/planety, materiały/tekstury wymagające odrębnych zadań 3–5, zgodność wersji z `NewHome290.Enabled` oraz weryfikacja jakości i FPS na prawdziwych urządzeniach (zadanie 18). Niezależna scena nadal jest podglądem, nie autentyczną pełną misją. Projekt według dotychczasowego zbiorczego wskaźnika odniesienia **27%**, pozostało **73%** — bez nowego ważenia stałej listy 18 zadań. Nie uruchamiano kompilacji IPA.

## 05.11.2026 — kolejna domknięta część zadania nr 2 (Metal 74→76%)

**Co wykonano:** Odtworzono brakującą animację oryginalnego modelu planety w scenie `IntroOrbit41` — `GpuIntro41.CinematicIntro41` wywołuje `DrawPlanetSolid` po ustawieniu `weatherTime65=IntroTime`, a `GpuPlanetGltf463` animuje glTF. Port `MetalRenderer.swift` teraz korzysta z jednego źródłowego `BoreasMorphRenderer556` dla obu kamer (intro: `IntroTime`, walka: dotychczasowy `planetAnimationTime`), zachowując zamrożone `MorphBufferSlots`, dynamiczny zakres siatki, częstotliwość 30 Hz i nienaruszone statyczne wierzchołki. Zmiana trybu i 16-sekundowe zawinięcie zegara wymuszają właściwą klatkę morfu, bez zamrażania po wyjściu z intro. Dodatkowo niezmienne 81 segmentów kamery/lotu z `OrbitWorld51.BuildBelt51` liczone jest raz i ponownie używane przy tworzeniu 820 źródłowych pozycji skał; seedy i algorytm pozostają bez zmian.

**Testy:** `source-camera-linux` [GitHub Actions 42102273792](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273792) **PASS**, w tym dodany kontrakt `Tests/IntroBoreasMorphSourceContract556.py`, test przebiegu 81 próbek i dotychczasowe testy źródłowe animacji/asteroid/rendererów; [preflight 42102273356](https://github.com/synixad-png/asteroidy-ios/actions/runs/42102273356) **PASS** dla pełnej składni Swift i zasobów. **Kompilacja Xcode/Metal nadal niepotwierdzona** — jej job w run 42102273792 pozostawał `queued`; bez IPA, bez interaktywnego testu Apple GPU i obu urządzeń.

**Postęp:** zadanie 2 — **76% (+2 pp względem poprzedniego raportu 74%)** za faktyczną implementację i testy regresji; zadania 1 i 3–18 bez zmian. Łączny dotychczasowy wskaźnik odniesienia **27%, pozostało 73%**, bez sztucznego zmieniania wag. Kod nie jest jeszcze pełną oryginalną misją, a v556 Boreas nie oznacza obsługi wszystkich planet v568.

**Co pozostało:** ukończenie natywnej kompilacji źródeł Xcode/Metal; następnie dalsza weryfikacja autentycznych efektów planety/atmosfery oraz skali i oświetlenia statku w cinematic, a później fizyczne testy sceny na iPhone i iPad. **Nie generować nowego IPA automatycznie** — tylko po poleceniu użytkownika i potwierdzeniu gotowości źródeł.

## 05.11.2026 — zadanie 2: oryginalna atmosfera 3D Boreas (76→78%)

**Wykonano i potwierdzono testami:**
- Port `Windows/src/GpuPlanet.cs:9–36`, źródłowa funkcja `AtmosphereVertex` i `DrawAtmosphere47`: **24 pierścienie × 96 segmentów × 2 trójkąty = 4608 trójkątów / 13824 wierzchołków**. Zachowano radialny profil `.058+.33*exp(-((r-1.055)/.125)^2)`, stopniowe wygaszenie przy promieniu 1,34, łuk 3D, skierowanie do prawdziwej kamery `IntroScene41` i kolory RGBA. Dla rzeczywistej `PlanetBoreas463` poziomu 5 użyto autentycznego `PlanetBiomes.cs:12` `Glow=0x95DBFF`; nie stosować tego koloru bez weryfikacji dla innych planet.
- `MetalRenderer.swift` rysuje teraz `IntroAtmosphere47.geometry()` **po GLB planety i po statku**, zgodnie z `Windows/src/GpuIntro41.cs:494`. Osobna konfiguracja blend `SRC_ALPHA,ONE_MINUS_SRC_ALPHA`, depth-test `.less`, **depth writes OFF**, brak PBR na tej półprzezroczystej powłoce. Nie zmieniono istniejącego opaque PBR, shaderów, animacji planety, pasa 820 asteroid ani trybów sferycznej i płaskiej walki.
- `Tests/IntroAtmosphere47Tests.swift` numerycznie sprawdza siatkę 13 824 wierzchołków, punkty kopuły, poziom alfa, profil jasności oraz bazę ortonormalną kamery (również bieguny). `Tests/IntroAtmosphereSourceContract47.py` pilnuje połączenia z prawdziwym Metal, kolejności planet→statek→atmosfera i stanu blend/depth.
- [GitHub Actions 42105492701](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105492701) `source-camera-linux` **SUCCESS**, w tym dwa nowe testy oraz wcześniejsza matematyka przelotu, siatki skał i animacja morfów. [GitHub Actions 42105503401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105503401) `original-assets` **SUCCESS** (zasoby, Swift frontend, kontrakty). Wyniki obowiązują tylko dla kodu, nie są potwierdzeniem wyglądu na iPhonie.
- **Aktualizacja zadania 2: 78% (+2 pp wobec 76%).** Pozostałe 17 zadań bez zmian; łączny dotychczasowy wskaźnik odniesienia **27%, pozostało 73%** (bez ponownego ważenia wszystkich zadań).

**Nadal pozostało:** natywna kompilacja Xcode/Metal na Apple, wierny dobór i dopasowanie geometrii/skali/tekstur statku i pozostałych światów z oryginału, pomiary wydajności GPU oraz testy interaktywne na iPhonie i iPadzie. Dla nowszych map nie udawać zgodności samej Boreas. Nowe IPA nie było budowane, a poprzedni artefakt iPhone-only nie zawiera najnowszej sceny.

## 05.11.2026 — testy i uporządkowanie kompilacji Apple, bez nowego IPA

Po zamknięciu implementacji atmosfery potwierdzono pełny `source-camera-linux` **SUCCESS** w [GitHub Actions 42105841484](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105841484) oraz `original-assets` **SUCCESS** w [42105503401](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105503401); oba testują aktualną scenę orbitalną i mają źródłowe kontrakty `IntroAtmosphere47`. Poprzednio każdy commit weryfikacji `verify-metal-camera.yml` z `cancel-in-progress=true` anulował oczekujący w tym samym workflow job macOS. Oddzielono automatyczne source-only testy Linux od ręcznego Apple job, zachowując oryginalny `workflow_dispatch`. Aby realnie sprawdzić najnowszą źródłową scenę na kompilatorze Apple bez generowania IPA, uruchomiono jednorazowy niezależny workflow [42105890080](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105890080) dla `iPhone+iPad ARM64`, wyłącznie Swift/Metal. Ten job **nadal był queued** podczas ostatniego odczytu. Nie deklarować PASS Xcode, gotowego IPA ani testu na Apple GPU.

Stała lista 18 zadań i ich procenty bez zmian: zadanie 2 **78%**, łączny historyczny postęp **27%, pozostało 73%**. Następnie: wynik trwałego joba Xcode, audyt geometrii/tekstur/światła oryginalnego statku GLB z osobnym eksportem `Tools/export_vanguard.py` (ta konwersja nie jest wiernością materiałów PBR), sprawdzenie obrazów fizycznych urządzeń, a potem dalszy brakujący renderer bez przechodzenia do zadania 3 przed domknięciem 2. Nie generować IPA bez polecenia użytkownika.

## 05.11.2026 — kontynuacja zadania 2: Vanguard v4311 i źródłowa rotacja planety poziomu 5

**Realne wdrożenie:** `IntroVanguard431.swift` odtwarza lokalną skalę i środek modelu Vanguard na podstawie faktycznie wbudowanego w oryginalną grę PC `vanguard431.mesh.gz` (nagłówek `4311`, 194427 GPU wierzchołków) oraz `BakeInfo.json` i źródłowego GLB. Współczynniki *faktycznie używanego* modelu wynoszą `scale=3.265866381849069`, `center_glb.y=.18199390172958374`, podczas gdy zachowany `Vanguard556.as3d` eksportowano ze współczynnikiem `.32` i `centerY=.18`; dlatego przelot wykonuje `scale=(3.265866381849069/.32)/144.19674` oraz lokalne przesunięcie osi Z `(.18-.18199390172958374)*3.265866381849069/144.19674`. **Nie wymyślano nowego modelu i nie zmieniano źródłowego AS3D ani rozmiaru kolizji statku w trybie walki.** Zapis `Tools/bake_vanguard431.py` ma starszy współczynnik 2.88/0.12 i jest rozbieżny z *rzeczywistym* zasobem v568 — szczegóły w audycie.

**Druga źródłowa poprawka:** komputerowy `GpuPlanetGltf463.PlanetAssetBytes463` wczytuje Boreas wyłącznie przy `game.Level==5`. Wcześniejszy iOS obracał ten konkretny GLB według `PlanetRotation(level=1,t)`. Nowy `IntroOrbit41.boreasSourceLevel=5`, czyli rotacja `145+2.2*t` stopni, przy niezmienionych animacjach morfu i reszcie renderera.

**Weryfikacja:** [GitHub Actions 42108063917](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108063917) `source-camera-linux` zakończył się **SUCCESS** dla najnowszych testów numerycznych autentycznej geometrii/rozmiaru Vanguard, testów `Boreas level5` i wszystkich wcześniejszych testów skał, atmosfery, animacji, sky/PBR. [GitHub Actions 42108063893](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108063893) `original-assets` **SUCCESS**; dodatkowo wcześniejsza kompletna natywna kompilacja Apple [42105890080](https://github.com/synixad-png/asteroidy-ios/actions/runs/42105890080) **SUCCESS** dotyczyła poprzedniej rewizji, a **nie** tych zmian. Dla obecnego kodu wykonano **nieanulowalne jednorazowe uruchomienie** [GitHub Actions 42108222094](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108222094), które testuje Xcode/Metal iPhone+iPad ARM64 bez IPA — `queued` podczas zapisu raportu. Nie deklarować natywnego PASS bieżącej rewizji przed jego rzeczywistym zakończeniem.

**Postęp zadania 2: 78% → 80% (+2 pp)** za konkretną korektę autentycznego modelu i prawidłowy obrót GLB z testami źródłowymi. Pozostałe 17 zadań i ich procenty niezmienione; historyczny wskaźnik całego projektu nadal **27%**, pozostało **73%** (wagi nie są przeliczane). **Braki wciąż istotne:** oryginalne UV/BaseColor/PBR modelu i źródłowe oświetlenie `FighterLight`, rzeczywisty wygląd na fizycznym iPhonie/iPadzie, optymalizacja pamięci/klatek, pełny kontroler misji/kampanii. IPA nadal nie zbudowano; status iOS powinien być potwierdzany z nowego przebiegu Xcode.

## 05.11.2026 — zadanie nr 2: plazma obu silników Vanguard v491 (80→82%)

**Co wdrożono:** prawdziwy `GpuShip.cs:19–63` z oryginalnej gry PC v568, dwie dysze ze źródłowego `vanguard431.mesh.gz` (wersja 4311), 3 warstwy × 3 płaszczyzny × 16 segmentów × 6 wierzchołków × 2 dysze = **1728 wierzchołków / 576 trójkątów**; oryginalne barwy biały–pomarańczowy–czerwony, okresowe fale, długość zależna od mocy silnika i przenikanie zgodne z `SRC_ALPHA,ONE`. Efekt liczony jest w osobnym shaderze `fighterPlasmaVertex491` przez `vertex_id`, bez nowego bufora geometrii per-frame. `MetalRenderer.swift`: statek GLB → 3D plazma obu dysz → źródłowa atmosfera 3D; zachowane oddzielne tryby gry, kolizje i trwałość buforów Boreas. Bez zgadywania położenia dysz.

**Testy źródłowe:** [42110230250](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110230250) `source-camera-linux` **PASS** oraz [42110230316](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110230316) preflight Swift/oryginalne zasoby **PASS**. `Tests/IntroEnginePlasma491Tests.swift` sprawdza 1728 wierzchołków, numeryczne stany czasu i mocy, oba rzeczywiste wyloty; `Tests/IntroEnginePlasmaSourceContract491.py` wiąże wszystkie wzory z shaderem i źródłową kolejnością rysowania. Starsze kontrakty nie mylą się już na współdzielonym depth state i wcześniejszych źródłowych overlayach Sky. 

**Natywny Apple:** dla dokładnego kodu z plazmą uruchomiono niezależny Xcode iPhone+iPad arm64 [42110465213](https://github.com/synixad-png/asteroidy-ios/actions/runs/42110465213); ostatnio **queued**, brak kompletnej kompilacji w chwili zapisu raportu. Poprzedni PASS Xcode [42108222094](https://github.com/synixad-png/asteroidy-ios/actions/runs/42108222094) obejmuje starszą rewizję BEZ tego nowego shadera — nie przedstawiać go jako potwierdzenia najnowszych zmian. Nowego IPA nie tworzono.

**Postęp:** zadanie 2 **82% (+2 pp)**; zadania pozostałe bez zmian, poprzedni historyczny całościowy wskaźnik **27%, pozostało 73%**, bez nieuzasadnionego przeważania. **Co pozostaje:** natywny PASS shadera Metal, źródłowe UV/tekstury/baseColor i `FighterLight(false)` Vanguard, następnie rzeczywisty test wyglądu i wydajności na iPhone + iPad, a później odtwarzanie całej misji. Nie deklarować ukończonej gry ani 100% zgodności.

## 05.11.2026 — kolejny zweryfikowany etap: źródłowe oświetlenie GpuToon60 (82→84%)

**Wykonano:** z bezpośredniego porównania `Windows/src/GpuShip.cs:10–16` i `Windows/src/GpuToon60.cs:29,34,64,279` w oryginalnym PC v568 ustalono, że Vanguard431 domyślnie korzysta z trzystopniowego shaderowego oświetlenia `BeginToon60(true,true)` przy `ToonEnabled60=true`, a nie z uproszczonego jednokierunkowego Cook–Torrance ani z dwuświatełkowego fixed-function fallback. Kierunek głównej lampy z `FighterLight(false)` to `(-.6,.8,1.4,w=0)` w eye-space. Dokładne źródłowe progi `0.25+0.33*smoothstep(.30,.32,d)+0.40*smoothstep(.70,.72,d)` i rim `.10*smoothstep(.72,.86,1-max(0,dot(N,V)))*smoothstep(.10,.30,d)` przeniesiono w `SourceFighterToon60.swift` i dedykowanym `sourceFighterToonFragment60` w `Ship.metal`. `MetalRenderer.swift` podaje rzeczywistą macierz `IntroScene41.View`, włącza ten PSO **tylko przy rysowaniu Vanguard**, a przed plazmą przywraca oryginalny pipeline. Bez ingerencji w planetę PBR, atmosferę, obie areny testowe i kolizje.

**Testy:** Swift/Linux `source-camera-linux` [42113405688](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113405688) **PASS**, preflight zasobów i składni [42113405405](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113405405) **PASS**. Testy obejmują numeryczne wartości progów i rim, eye-space `FighterLight`, ograniczenie PSO do statku i zachowanie pierwotnego PBR. Odrębna autentyczna kompilacja Apple [42113629084](https://github.com/synixad-png/asteroidy-ios/actions/runs/42113629084) **SUCCESS**: Xcode Swift+Metal dla ARM64, `UIDeviceFamily={1,2}`, obecna domyślna scena przelotu z nowym shaderem i autentycznymi zasobami, `default.metallib` jest zbudowane. **Nie** wykonano fizycznego interaktywnego testu iPhone/iPad ani pomiaru GPU/FPS. **Nie tworzono IPA.**

**Uczciwy stan:** zadanie nr 2 **84% (+2 pp)**; inne 17 zadań bez zmian. Łączny dotychczasowy wskaźnik referencyjny **27%, pozostało 73%** (bez sztucznego przeliczania wag). Ponieważ kompilacja aktualnego źródła zakończyła się PASS, można na osobne polecenie uruchomić próbę ręcznego **unsigned IPA iPhone+iPad**, które wreszcie zawrze inną scenę niż płaska arena 9 asteroid. NIE nazywać jej skończoną pierwszą misją ani pełną grą.

**Wciąż brakuje** oryginalnych UV, tekstury `BaseColor` i pełnego materiału PC Vanguard. Obecne AS3D v1 zachowuje przybliżone kolory wierzchołków z wcześniejszym oświetleniem bake; nowe źródłowe pasma i rim są zgodne, ale obraz kadłuba nie jest 1:1. Konieczne są dalszy port realnych zasobów i weryfikacja na urządzeniach, później domknięcie zadania 2 przed przechodzeniem do 3–18.

## 05.11.2026 — zadanie nr 2: oryginalne UV i JPEG Vanguard, etap infrastruktury 84→85%

**Wykonano:** nowy parser `SourceVanguardMesh431.swift` dla autentycznego binarnego strumienia wersji 4311 `(x,y,z,nx,ny,nz,r,g,b,a,u,v)`; oryginalna siatka 194427 wierzchołków/64809 trójkątów w źródłowym układzie współrzędnych oraz rzeczywista mapa BaseColor 2048×2048 JPEG. Dodatkowy shader `sourceVanguardVertex431` + `sourceVanguardTexturedToonFragment431` w `Ship.metal` używa autentycznych UV bez V-flip, oryginalnego key light/GpuToon60, liniowej filtracji, mipmap i większej pamięci GPU `device`. `MetalRenderer.swift` wykrywa parę plików `Vanguard431Source.mesh` + `Vanguard431Base.jpg`, sprawdza ich SHA256 CryptoKit i rysuje źródłową, teksturowaną siatkę; **gdy binarek nie ma, dokładnie zachowuje poprzednią ścieżkę AS3D**. Zmiany nie dotykają kolizji, planet, plazmy, atmosfery i sterowania.

**Zasoby:** rzeczywiste dwa pliki binarne wyodrębniono z własnego ZIP PC v568 użytkownika, zweryfikowano sumy SHA256, oryginalną strukturę 4311, 194427 wierzchołków i fakt, że JPEG z runtime jest bajtowo identyczny z oryginalnym GLB. Udostępniono w rozmowie osobny ZIP zawierający dokładne bajty do `ASTEROIDYiOS/Assets`. Repozytorium GitHub **nie zawiera jeszcze tych dużych binarek** — funkcja materiałów jest więc gotowa w kodzie, lecz **nie będzie aktywna w nowym IPA bez dołączenia źródeł**. Pełne wymagania i importer `Tools/import_original_vanguard431.py`: [VANGUARD431_ORYGINALNE_ZASOBY_IOS.md](VANGUARD431_ORYGINALNE_ZASOBY_IOS.md). Nie udawać pełnej integracji.

**Testy:** [GitHub Actions 42120727178](https://github.com/synixad-png/asteroidy-ios/actions/runs/42120727178) Swift/Linux **SUCCESS** (parser i źródłowe kontrakty), [42120727204](https://github.com/synixad-png/asteroidy-ios/actions/runs/42120727204) preflight Swift/źródeł **SUCCESS**. Oddzielna, niezależna kompilacja natywna Apple [42121018526](https://github.com/synixad-png/asteroidy-ios/actions/runs/42121018526) **SUCCESS**, iPhone+iPad ARM64 i rzeczywiste shadery Metal; **bez nowego IPA, bez testu GPU na sprzęcie i bez zasobów źródłowych w repo**.

**Uzasadnienie wyniku:** zadanie 2 wzrosło **84%→85% (+1 pp)** wyłącznie za rzeczywistą kodową obsługę pierwotnej siatki i testy parsera/kompilacji; nie zaliczono importu tekstury w wydanej aplikacji. Pozostałe zadania 1 i 3–18 bez zmian; historyczny łączny wskaźnik odniesienia **27%, pozostało 73%**, bez przeważania listy. Dalej: rzeczywiste dodanie zweryfikowanych binarek do repo i ich runtime validation, porównanie GPU/JPEG na iPhonie/iPadzie, następnie brakujące efekty i dokończenie zadania 2, bez budowania niezmienionego IPA.

## 05.11.2026 — zadanie nr 2: potwierdzenie samplera źródłowego i bramka przyszłego wydania (85→86%)

**Co wykonano:** bezpośrednio porównano `Windows/src/GpuRenderer.cs:144–146` oryginalnego PC v568 z iOS. Potwierdzono `GL_RGBA8/GL_BGRA` (surowe UNORM, bez sprzętowego sRGB decode), `GL_CLAMP_TO_EDGE` i oba filtry `GL_LINEAR`, bez mipmap. W `Ship.metal` oraz `MetalRenderer.swift` poprawiono błędne `address::repeat`, `.SRGB:true` i `.generateMipmaps:true`; oryginalne UV bez V-flip pozostają. Odpowiada to źródłowemu samplingowi, nie obietnicy wizualnego 1:1.

**Przygotowano autentyczną paczkę aktywacji:** `Tools/prepare_vanguard431_assets.py` zna dokładną kompaktową paczkę `AssetsCompressed/Vanguard431_ORYGINALNE_UV_TEKSTURA_ZASOBY.zip` z tej rozmowy, a także odrzuca niekompletne/podmienione źródła, zanim zapisze jakąkolwiek binarkę aplikacji. Oryginalny ZIP użytkownika przechodzi CRC, SHA256, kontrolę formatu v4311 (194427 wierzchołków), 10802 trójkątów CPU i JPEG 2048² w lokalnym środowisku. `Tools/verify_original_vanguard_resources.py` wymusza te same prawdziwe dane przy standardowym przyszłym wydaniu. `Tools/verify_ipa.py` ma opcjonalną kontrolę rzeczywistej zawartości IPA `--require-vanguard-original`. Ręczny workflow `build-ios-iphone-ipad-manual.yml` wykonuje import i obie kontrole, domyślnie **odrzuca** nowe IPA pozbawione oryginalnego Vanguard. Starszy `AS3D` jest dostępny wyłącznie jako jawny wariant `compatibility_old_ship=true`. Poprzedni działający IPA pozostaje niezmieniony.

**Testy:** [42125357275](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125357275) Swift/Linux wszystkie testy źródłowe, w tym odrzucenie podmienionej/niepełnej paczki, **SUCCESS**; [42125348782](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125348782) Swift source/asset preflight **SUCCESS**; [42124960734](https://github.com/synixad-png/asteroidy-ios/actions/runs/42124960734) natywny Xcode Swift+Metal iPhone+iPad ARM64 z nowym samplerem **SUCCESS**. **Nie** przeprowadzono natywnego interaktywnego testu GPU/tekstury na fizycznych urządzeniach.

**Nierozwiązana zależność:** paczka binarna jest rzeczywiście w tej rozmowie, **ale nie jest obecna w publicznym repozytorium GitHub**. Testy źródłowe i Xcode kompilowały więc opcjonalną ścieżkę, lecz nie rysowały jeszcze rzeczywistej tekstury na iPhonie. Nie wolno deklarować pełnej funkcji ani budować nowego 'teksturami' IPA bez bezpośredniej integracji obu zweryfikowanych binarek. Dalszy krok: dodać kompaktową 3,53MB paczkę do `AssetsCompressed/` lub parę oryginalnych binarek do `ASTEROIDYiOS/Assets`, uruchomić realny build, zweryfikować zawartość IPA i potem test wyglądu i FPS.

**Postęp zadania 2:** **85% → 86% (+1 pp)** tylko za źródłową poprawkę i rygorystyczny, przetestowany proces wydawania; pozostałe pozycje 1 i 3–18 bez zmian. Łączny historyczny wskaźnik projektu **27%, pozostało 73%**, bez zmiany wag i bez naciągania gotowości.

## 06.11.2026 — domknięcie importu oryginalnego Vanguard431 w skompilowanej aplikacji (86→89%)

**Co zostało rzeczywiście wdrożone:**
- Użytkownik wgrał do `ASTEROIDYiOS/Assets` na `main` dwa oryginalne pliki PC v568: `Vanguard431Source.mesh` (**9 721 408 bajtów**) oraz `Vanguard431Base.jpg` (**1 275 318 bajtów**, 2048×2048). Oba pliki zweryfikowano według SHA-256 i Git blob SHA-1 wobec lokalnych źródeł, bez zamienników i pointerów LFS.
- `Tests/OriginalVanguard431InstalledAssetsTests.py` skanuje prawdziwy strumień **194 427** wierzchołków, ich normalne, RGBA i współrzędne UV oraz obie oryginalne dysze; nie jest to syntetyczna demonstracja modelu.
- `Tools/prepare_vanguard431_assets.py` obsługuje teraz **bezpośrednie umieszczenie zweryfikowanej pary w GitHubie** bez ponownego rozpakowywania ZIP. Uszkodzony lub częściowy upload odrzucany jest bez fallbacku niezgodnego z wydaniem teksturowanym. Test `Tests/PrepareVanguardPackTests.py` pokrywa ścieżkę pozytywną i negatywną.
- `Tools/verify_compiled_vanguard431_app.py` sprawdza już **rzeczywisty wynik kompilacji Apple**, a nie tylko źródłową listę plików: oryginalny mesh/JPEG wewnątrz `.app`, SHA-256, Info.plist `UIDeviceFamily=[1,2]`, fizyczny iOS arm64 Mach-O, iOS 17+ i `default.metallib`. Istniejący `MetalRenderer.swift` wybiera dokładną siatkę/UV i bazowy JPEG z oryginalnego modelu po przejściu własnego testu CryptoKit, zachowując dotychczasową ścieżkę AS3D jako fallback.

**Wykonane testy i wyniki:** [Source kamera i regresje 42168920268](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920268) **SUCCESS**; [preflight 42168920269](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920269) **SUCCESS**; [pełna natywna kompilacja Release z weryfikacją zasobów wewnątrz `.app` 42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848) **SUCCESS**. Logi kompilacji potwierdzają obecność obydwu oryginalnych binarek w gotowym `.app` i brak błędów SHA256. Żadnego IPA ani testu na fizycznym urządzeniu w tym etapie nie wykonywano.

**Uzasadniony postęp:** zadanie 2 **89% (+3 pp)** za ukończone faktyczne dostarczenie materiału i kontrolę natywnego `.app`; 17 pozostałych pozycji niezmienionych, łącznie historycznie **27%**, pozostało **73%** bez przeliczania wag. *Nie* stwierdzamy 100% renderer parity: brak interaktywnej kontroli koloru/UV/GPU/FPS na urządzeniu, źródłowego shaderowania całej gry i pełnych misji.

**Następny krok:** dokończyć zadanie 2 w zakresie rzeczywistych efektów i optymalizacji, a przy osobnym poleceniu wygenerowania IPA przygotować nowe niepodpisane wydanie iPhone+iPad już z rzeczywistym Vanguard431 oraz sprawdzić pliki wewnątrz IPA przed udostępnieniem. Nie zastępować wcześniej działającego IPA bez testu.

**Końcowa kontrola po zabezpieczeniu wydania:** nowa domyślna ścieżka iPhone+iPad wymaga oryginalnej siatki/tekstury, a ręczny `compatibility_old_ship=true` usuwa oba pliki **wyłącznie z tymczasowego checkoutu Github Actions** przed XcodeGen, dzięki czemu stary AS3D jest rzeczywiście używany tylko na wyraźny wybór. Test `ReleaseGateVanguard431Tests.py` zabezpiecza to zachowanie. Ostatni [preflight 42169385020](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169385020) **SUCCESS** oraz [pełne źródłowe testy regresji 42169384956](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169384956) **SUCCESS**. Natywna kontrola `.app` pozostaje **SUCCESS** z [42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848); po niej zmieniano wyłącznie skrypty i raporty, nie rendering. Nie uruchamiano nowego IPA.

## 06.11.2026 — zadanie 2: rzeczywisty smoke test grafiki ASTEROIDY w symulatorach iOS

**Wykonano:** dodano `Tools/verify_simulator_render_snapshot.swift` — natywny na macOS, rozpoznający rzeczywisty PNG z `xcrun simctl io screenshot`. Algorytm próbuje środkowej części własnego renderu, wymaga wielu różnych komórek RGB, wyraźnego zakresu jasności i odrzuca pusty/monochromatyczny obraz. Jego `--self-test` weryfikuje zarówno celowe odrzucenie jednolitego obrazu, jak i akceptację zmiennego wzorca testowego; wzorzec służy wyłącznie do testu detektora, **nie** jest przedstawiany jako ekran gry.

Dodano jednorazowy niezależny workflow [ASTEROIDY iOS genuine simulator 42169972297](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297). Uruchamia tylko **rzeczywistą aplikację ASTEROIDY z repozytorium użytkownika** i przygotowanymi wcześniej, potwierdzonymi oryginalnymi zasobami Vanguard431, w kolejności: sprawdzenie obu rzeczywistych zasobów, test detektora ekranu, rozpoznanie dostępnych simulatorów Apple, XcodeGen, kompilacja Debug `iphonesimulator`, próba instalacji i uruchomienia oryginalnego `com.synixad.asteroidyios` na iPhonie i iPadzie, zrzut ekranu z **prawdziwie uruchomionej aplikacji**, pomiar zróżnicowania pikseli i odczyt logu `ASTEROIDY: real PC Vanguard431 UV/BaseColor active: 194427 vertices`. Wymagany log nie pozwala uznać przypadkowego screenshotu systemu iOS lub starego AS3D za test nowej tekstury.

**Potwierdzone wyniki (stan ostatniej kontroli):** autentyczna para Vanguard431 i detektor PNG `--self-test` **PASS**; rozpoznanie prawdziwych iPhone+iPad runtime'ów Apple **PASS**; XcodeGen **PASS**; **kompilacja gry dla iOS Simulator PASS**. Etap `Boot REAL iPhone and iPad simulators, launch app and capture their genuine frames` **wciąż był in_progress** — NIE udowodniono jeszcze uruchomienia, logu źródłowej tekstury ani niepustych screenów. Dla natywnej fizycznej architektury iPhone+iPad ARM64 wcześniejszy [42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848) nadal **PASS** (zweryfikowane źródłowe zasoby wewnątrz skompilowanego `.app`), ale bez testu na fizycznym urządzeniu.

**Postęp pozostaje 89% zadania nr 2 (+0 pp), historyczny wynik zbiorczy 27%, pozostało 73%**, ponieważ samo uruchomienie testu nie potwierdza jeszcze wyniku obrazu. Pozostałe 17 zadań bez zmian. **Nowego IPA nie tworzono.** Wynik testu simulatorowego musi zostać odczytany z GitHub Actions i dokładnie sklasyfikowany jako PASS, FAIL albo brak danych; dopiero prawdziwy PASS może uzasadniać kolejny wzrost procentu.

## 06.11.2026 — rzeczywisty zrzut ASTEROIDY i nowa weryfikacja wykonania Metal Vanguard431

**Pierwsza udokumentowana klatka z faktycznie uruchomionego programu iOS:** [GitHub Actions 42169972297](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297) skompilował aplikację Swift+Metal na Apple iOS Simulator, uruchomił rzeczywisty `com.synixad.asteroidyios` na symulatorze iPhone 16 i wykonał prawdziwy screenshot `IPHONE_real_app.png` o wymiarach **750×1334**. Niezależny detektor RGB stwierdził **326 zróżnicowanych komórek koloru** i zakres luminancji **0,950** (niepusty obraz). Zrzut dokumentuje prawdziwy przelot orbitalny: planetę, obiekty pasa, teksty interfejsu i statek Vanguard. **Nie** jest to ilustracja koncepcyjna ani ekran cudzej aplikacji.

**Pierwszy test nie przeszedł pełnego gate'u.** W środowisku hostowanego CoreSimulator ujednolicony `log show` nie zwrócił wpisu `NSLog` o aktywacji `Vanguard431 UV/BaseColor`. Sama nieobecność w logach systemowych NIE dowodzi, że źródłowa tekstura się nie wyświetla; screenshot również nie dowodzi jeszcze pełnej zgodności tekstury z oryginałem PC. Test nie dotarł do iPada. Artefakt z oryginalnym zrzutem i logami: [42169972297 / artifacts](https://github.com/synixad-png/asteroidy-ios/actions/runs/42169972297).

**Drugi test ustalił konkretną przyczynę problemów bootowania:** [42171861687](https://github.com/synixad-png/asteroidy-ios/actions/runs/42171861687) poprawnie wykonał Apple iOS Simulator build, ale zatrzymał się na `simctl bootstatus` z kodem **75 — INCONCLUSIVE ENVIRONMENT**, po 125 sekundach. W poprzednim przebiegu faktyczne uruchomienie symulatora trwało około 7–8 minut; krótszy timeout był niewystarczający. Nie klasyfikować tego wyniku jako błędu shaderów ASTEROIDY.

**Nowe wykonane rozwiązanie:** `MetalRenderer.swift` ma włączaną WYŁĄCZNIE przez `SIMCTL_CHILD_ASTEROIDY_RENDER_VERIFY=1` diagnostykę rzeczywistego wywołania źródłowego GPU `sourceFighterTexturedPipeline431`. Po wywołaniu `drawPrimitives(vertexCount=194427)` i po **zakończeniu bufora komend Metal** z `finished.status==.completed` program zapisuje testowy `Library/Caches/ASTEROIDY_Vanguard431_RenderProof.json` we własnym kontenerze. Zawiera prawdziwą liczbę wierzchołków, rozmiar źródłowej tekstury GPU, znane SHA-256 siatki/JPEG, `bundleID`, faktyczne powodzenie polecenia GPU i nazwę PSO. Nie zależy od globalnego `NSLog` ani od wizualnej interpretacji zdjęcia. Domyślna działająca gra nie zapisuje diagnostyki i ma niezmienione UI oraz mechanikę.

`Tools/run_original_ios_simulator_capture.py` teraz odczytuje dowód bezpośrednio z `simctl get_app_container`, waliduje WSZYSTKIE pola przeciw źródłowym oczekiwaniom i oznacza obraz jako `VERIFIED_ASTEROIDY_source431` wyłącznie po **obu** wynikach: prawdziwe niepuste RGB + `gpuCommandBufferCompleted=true` z oryginalną teksturą. Twarde limity czasu procesów i całych grup chronią przed zawieszeniem CoreSimulator, a `--only IPHONE / IPAD / BOTH` pozwala rozstrzygać każde urządzenie osobno. `Tests/SimulatorSmokeHarnessTests.py` testuje wersje prawdziwych i fałszywych rekordów GPU i kontroluje zgodność plików; `Tests/SourceVanguardTextureContract431.py` chroni kolejność oryginalnego draw → GPU handler → `command.commit`.

**Status bieżącej, niezależnej weryfikacji GPU:** [42173321151](https://github.com/synixad-png/asteroidy-ios/actions/runs/42173321151) jest uruchomiona dla iPhone’a ze źródłowym shaderem i dowodem zakończonego renderowania. Przez poprawioną politykę nie uznajemy symulatorowego GPU za natywny iPhone ani za wizualną zgodność 1:1. **Nie wygenerowano nowego IPA** i nie podmieniono wcześniej działającej wersji. Zadanie nr 2 pozostaje **89% (zmiana 0 pp)** do prawdziwego zaliczenia testu źródłowego GPU; ogólny odniesieniowy wskaźnik **27% / pozostało 73%** i pozostałe 17 zadań bez zmian.

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

**Aktualizacja dostarczenia 06.11.2026:** nowy zweryfikowany IPA
(14 103 697 B, SHA256
`9b16daf6e045220140505ebbed99cf24befadbea8c0b7b2d8a1080df7b5c98ce`)
jest na [prywatnym Dysku Google jako bezpośredni plik IPA](https://drive.google.com/file/d/1SFMg2sOZFvhL3IAwSu_t8JO-BJU4TX5i/view?usp=drivesdk).
To nie jest tylko ZIP z artefaktu; kopia ZIP z raportami jest
dostępna niezależnie. Plik jest niepodpisany i nieprzetestowany
na fizycznym urządzeniu. Etap A pozostaje otwarty do testów
nawigacji, etap B nierozpoczęty. **Postęp bez zmian: 27%,
pozostało 73%, zadanie nr 14 10% (+0 pp).**
