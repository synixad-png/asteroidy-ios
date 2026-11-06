# ASTEROIDY iOS — zasady realizacji zatwierdzonego harmonogramu 18 zadań
Data: 2026-11-06. Uzupełnienie, nie zamiana `PORT_STATUS_18_TASKS.md`.

## Nienaruszalny zakres
Zachowujemy 18 oryginalnych zadań, ich nazwy, numery i postępy odniesienia.
Nie dodajemy nowego zadania „import modelu” jako osobnego etapu i nie
zaliczamy badań zasobów za ukończenie mechanik.

| Nr | Nazwa | Postęp odniesienia | Bramka ukończenia |
|---:|---|---:|---|
| 1 | Kompilacja i infrastruktura iOS | 88% | Powtarzalny build Xcode iPhone/iPad, spójność zasobów; IPA tylko na wyraźne polecenie |
| 2 | Silnik graficzny Metal | 89% | Wierny render źródłowych scen, kamery, geometrycznych efektów; test GPU |
| 3 | Materiały PBR, tekstury i oświetlenie | 25% | Materiały, światła, połysk, cienie względem PC v568, GPU |
| 4 | Statki, planety i zasoby 3D | 20% | Modele i proceduralne generatory 26 planet używane przez PC v568, bez zamienników |
| 5 | Animacje modeli GLB | 35% | Oryginalne animacje GLB/B82S i transformacje części, test wizualny |
| 6 | Fizyka lotu i poruszanie po planetach | 35% | C# v568 ↔ Swift, source regression oraz scena iOS |
| 7 | Kolizje, obrażenia i zniszczenia | 100% | ZAMKNIĘTE implementacyjnie; zawsze utrzymywać regresje |
| 8 | Asteroidy i fale walki | 100% | ZAMKNIĘTE implementacyjnie; zawsze utrzymywać regresje |
| 9 | Wszystkie bronie i efekty trafień | 10% | Wszystkie źródłowo używane bronie, efekty, zachowania, testy |
| 10 | Przeciwnicy i sztuczna inteligencja | 0% | Komplet źródłowych AI i zachowań |
| 11 | Bossowie i ich mechaniki | 0% | Wszystkie 6 typów bossów, oryginalne animacje, AI, obrażenia |
| 12 | Komplet misji planetarnych | 5% | Pełne cele, zdarzenia i przejścia |
| 13 | Kampania — 26 sektorów | 30% | 26 źródłowych sektorów z pełnym wykonaniem celów |
| 14 | Menu W3, HUD i ustawienia | 10% | Oryginalny natywny interfejs, brak WebView |
| 15 | Dźwięki i muzyka | 0% | Źródłowy mapping audio |
| 16 | Zapisywanie i wczytywanie gry | 20% | Stany kampanii i odtwarzanie 1:1 |
| 17 | Sterowanie dotykowe i kontrolery | 35% | iPhone/iPad, sterowanie i kontrolery oraz ustawienia |
| 18 | Optymalizacja i testy urządzeń | 10% | Fizyczne iPhone/iPad, FPS, regresje, pełne testy end-to-end |

**Zbiorczy postęp odniesienia: 27%; pozostało 73%.**
Procent zmieniamy dopiero po zweryfikowanej zmianie funkcjonalnej oraz
adekwatnych testach — bez sztucznego przeliczania 18 wartości na średnią.

## Kolejność operacyjna — grywalne i wizualnie weryfikowalne etapy

**Decyzja użytkownika 06.11.2026:** priorytetem nie jest numer najbliższego
zadania, ale **widoczna, spójna droga gracza: uruchomienie → menu →
wybór misji → wejście na planetę → lot i walka → wynik → powrót**.
Wcześniejsze sekwencyjne „najpierw całe 9, później 10 i 11, menu dopiero
na końcu” jest ZASTĄPIONE poniższym wykonawczym porządkiem. Oryginalne
18 zadań, numery, zakresy i procenty w tabeli wyżej pozostają bez zmian.
**Każdy kamień milowy kończy się widocznym wynikiem w tej samej
natywnej aplikacji**, nie samym importem modeli. W danym momencie
wdrażamy jeden pionowy przebieg end-to-end; wcześniej rozpoczęta część
tego przebiegu musi być sprawdzona przed kolejną.

| Kolejność | Kamień milowy / widoczny stan gry | Numery oryginalnych zadań | Bramka zaliczenia |
|---:|---|---|---|
| A | **Ekran startowy i oryginalne menu** W3, w pełni natywne Metal/Swift, na iPhone i iPad | 14 + zależności 1–3,17 | Uruchomienie → rzeczywiste menu, obsługa dotyku, nawigacja i powrót; autentyczny screenshot + test stanu na obu symulatorach |
| B | **Wybór misji**: ekran kampanii, 26 sektorów z oryginalnymi nazwami/zasadami dostępności (bez sztucznego odblokowania) | 13,14,16 + 1 | Menu → wybór → podgląd/wybór dozwolonej misji → Wstecz; zapis ustawień zgodny z bazą v568; test UI |
| C | **Wejście do pierwszej misji**: ekran ładowania, właściwa planeta/sektor i statek, kamera, oryginalne zasoby | 2–6,12–14 + 17 | Wybór sektora 01 → autentyczna scena Metal → interaktywny lot, pauza i powrót; NIE oznaczać demo jako kompletnej misji |
| D | **Pełna rozgrywka pierwszej misji**: wszystkie jej wymagane obiekty, fale, bronie, kolizje, cele, zakończenie | 6–10,12,14,17 (7–8 tylko regresje) | Scena 01 → gra → osiągnięcie autentycznego celu → wynik → menu; test end-to-end, bez fałszywego komunikatu ukończenia |
| E | **Widoczna rozbudowa świata**: wszystkie pozostałe typy planet i statków, animacje, światło, tekstury | 2–5,13 | Odwiedzenie kolejnych prawdziwych planet i porównanie ich źródłowej geometrii/efektów v568; widoczne różnice, testy GPU |
| F | **Przeciwnicy i 6 bossów**: autentyczne modele, osobne AI, animacje, ataki, zniszczenia | 5,7,9–12 | Grywalny pojedynek z przeciwnikiem/bossem i poprawne zakończenie; nie wystarczy test parsera B82S |
| G | **Kampania 26/26**: pełne cele misji, przejścia, blokady, wynik i postęp kampanii | 12,13,16 | Test przejścia całej kampanii; wszystkie 26 sektorów rzeczywiście uruchamiają się i mają poprawne stany |
| H | **Pełny interfejs i ustawienia**, sterowanie dotykowe i pady, ustawienia obrazu i dźwięku | 14,15,17 | Wszystkie ustawienia działają w misji i poza nią; testy iPhone/iPad i kontrolerów |
| I | **Oryginalne audio i trwałe zapisy** | 15,16 | Muzyka/efekty zgodne z oryginałem, zapis/odczyt po restarcie bez utraty postępu |
| J | **Wydajność, regresje i przygotowanie wydania** | 1–18, ze szczególnym 18 | Kompilacja, testy GPU, pamięci, FPS i end-to-end na urządzeniach; nie deklarować 100% bez ich wykonania |

**Najbliższy aktywny kamień milowy: A — prawdziwe menu.**
Na etapie A nie portować nowych bossów lub kolejnych statków, chyba że
są bezpośrednio wymagane przez ekran menu. Dopiero po zaliczeniu A
przejść do B, następnie C. Zadania 7 i 8 pozostają zamknięte
implementacyjnie i obowiązkowo objęte regresją przy każdym relewantnym
wydaniu. Otwarte zadanie 9 pozostaje otwarte, lecz jego funkcje
wdrażane są w **grywalnym przebiegu D**, gdy menu i wejście do misji już
działają. Nie zwiększać żadnego procentu bez realnych testów.

### Sposób raportowania na każdym etapie

Raport zawsze zawiera jedną stałą tabelę **18 zadań**, z postępem,
zmianą w punktach procentowych i osobnym paskiem dla każdej pozycji;
nad nią postęp zbiorczy 27% / pozostało 73% dopóki dowody nie pozwolą
go zmienić. Ponadto pokazujemy: aktualny etap A–J, wykonane
funkcje widoczne dla gracza, wyniki autentycznych screenshotów lub
testów, czego dokładnie brakuje do zaliczenia etapu, i następny
kamień milowy. Nie podmieniać screenshotów na koncepcje lub cudze gry.

### Rozliczenie dotychczas wykonanych prac spoza aktualnego punktu

- `PlayerShip367`, Vanguard431 i Boreas → techniczna baza zadań 2–4.
  Rzeczywisty GPU PASS na symulatorach iPhone+iPad nie oznacza końca 2–4.
- `alien_scout_173.b82.gz`, jego 88 części i 10×49
  źródłowych klatek → przygotowanie zasobu pod zadania 4–5 oraz 11;
  boss **nadal 0%**, bo nie ma jego renderowania animowanego i walki.
- Nie dokładać kolejnych importerów bossów tylko dla samego liczenia
  plików. Wykorzystać je dopiero, gdy harmonogram wymaga 4/5/11.
- Używać **wyłącznie** źródeł i assetów Windows/SteamOS **v568**
  znajdujących się w czterech SHA-verified ZIP-ach GitHub.
  Nie podstawiać GLB z biblioteki tylko dlatego, że nazwa pasuje.
- `BEZ_HANGARU` nie zawiera `hangar_h55.glb`: zachować ten brak
  w audycie zamiast wymyślać zamiennik.

### Każde zadanie kończyć na mierzalnej bramce

1. Potwierdzić konkretny kod C# i używane pliki w v568; zapisać
   dokładne odwołania i format. Nie zaczynać od ilustracji lub nazwy.
2. Wykonać **jedną spójną funkcję** we właściwym numerze harmonogramu.
3. Uruchomić kontrakt źródłowy i test jednostkowy, następnie CI na
   GitHubie (Swift, Xcode/Metal), test symulatora tylko tam, gdzie
   GPU/obraz to istotna bramka.
4. Naprawić znalezione regresje przed kolejną funkcją; utrzymywać
   PASS zakończonych 7/8.
5. Dopisać raport: co wykonano, co pozostało, następny krok, testy
   niedostępne (fizyczny iOS), postęp zadania i zmiana w pp.
6. Dopiero po spełnieniu bramki przechodzić do następnego punktu.
   Zablokowaną funkcję oznaczyć jawnie jako zablokowaną, bez
   fałszywego 100%.

Nie uruchamiać `build-ios.yml` ani nie tworzyć nowego IPA bez
wyraźnego polecenia. Zachować dotychczas działający kod iOS.

## Najbliższy rzeczywisty zakres: kamień milowy A — menu

Najpierw zweryfikować źródłowy interfejs W3 w aktualnym Windows v568
oraz istniejące widoki i routing `App.swift`. Nie tworzyć nowej
estetyki ani zastępników. Wdrożyć natywny ekran startowy,
menu główne i nawigację iPhone/iPad, przy zachowaniu istniejącego
intro, diagnostycznych widoków i gameplayu (jako osobnych
niedomyślnych ścieżek). Następnie dwa autentyczne screenshoty
symulatorów oraz testy działania przycisków. Dopiero **po teście menu**
rozpocząć etap B — rzeczywistą listę 26 misji i wybór sektora.

Dla kamieni milowych A i B przed kompilacją sprawdzić źródłowo,
czy menu i selektor misji mają rzeczywistą logikę (a nie tylko
grafikę). Nie tworzyć IPA bez osobnego polecenia użytkownika.

## 06.11.2026 — wykonanie kamienia A, pierwsza rzeczywista implementacja

**Stan: W TRAKCIE.** Bez zmiany 18 zadań i bez podnoszenia procentów
odniesienia (27% ukończone, 73% pozostało; nr 14 nadal 10%).

W commitach `9681d18`, `ce74f4a`, `0b70633`, `2c9334a` wykonano
`ASTEROIDYiOS/W3MainMenu568.swift`: natywny SwiftUI/Metal ekran
domyślny z siedmioma rzeczywistymi etykietami v568
(`NOWA GRA`, `KONTYNUUJ`, `KAMPANIA`, `HANGAR`,
`USTAWIENIA`, `AUTORZY`, `WYJŚCIE`), paletą i panelem
radarowym opartym na `RendererW3Home328.cs`, układem adaptacyjnym
iPhone/iPad i ekranami stanu funkcji. Zmieniono punkt wejścia
`App.swift`: zwykłe uruchomienie pokazuje menu, a istniejące
podglądy 3D są dostępne dopiero przez `SCENA TESTOWA`.
`MENU W3` wraca z testu do menu, kasując przytrzymane wejścia.
Tryby simulatorowego dowodu GPU Vanguard431/PlayerShip367
są zachowane jako jawne wyjątki. Oryginalne mechanizmy
kolizji/asteroid nie zostały zmienione.

**Zasada bez pozorowania ukończenia:** oryginalne
`Shared/assets/ui_w3_background.jpg` (806519 bajtów; SHA256
`a8aa28883084657f0c38900dbb011de09e2b0fd461704d370a68858be0178145`)
i `Shared/assets/ui_w3_logo.png` (50257 bajtów; SHA256
`cab4198b953640c787975c5a8436a0fdeaa82502b40e000077ff055cc0709e09`)
są w pełnym ZIP v568, ale **nie** zostały dołączone do wcześniejszego
czteroczęściowego archiwum modeli. Są nadal do przeniesienia do
repozytorium i bundla iOS. Centralna planetarna animacja/proceduralna
geometria z `RendererW3Home328.cs` NIE została jeszcze portowana.
Obecny radar jest jawnym płaskim elementem nawigacyjnym, nie
symulacją oryginalnej planety. Opcje zapisu, hangaru i misji
pokazują stany „brak / podgląd” zamiast fałszywie działać.
`KAMPANIA` i `NOWA GRA` otwierają wyłącznie istniejący,
tylko-do-odczytu atlas 26 sektorów z bazy v556;
przeniesienie realnego wyboru v568 jest kamieniem B.

**Zapisane testy:** `Tests/V568W3NativeMenuContract.py` sprawdza
7 źródłowych etykiet, sposób uruchamiania, bezpieczne przejście do
testu i powrót oraz brak WebView. Natywna kompilacja iOS
`42193391940`: job **Compile iOS source only — SUCCESS**;
pełna ścieżka testów nadal podlega regresjom, a błędne dosłowne
asercje źródłowych testów dopasowano do nowego stanu menu.
Do bieżącej walidacji są uruchomione:
[GitHub Actions W3 iPhone+iPad](https://github.com/synixad-png/asteroidy-ios/actions/runs/42193792251)
— rzeczywiste screenshoty simulatów, oddzielny marker wyświetlenia
widoku i detektor niepustych pikseli (bez IPA).
**Nie oznaczać obu za PASS, dopóki nie zakończą się wynikiem success.**
Test aktywacji i wstecz wszystkich 7 akcji dotykiem w rzeczywistym
symulatorze nadal nie został wykonany.

**Bramka zamknięcia A:** zweryfikowane oryginalne tło i logo
w aplikacji, źródłowa planeta/animacja w centrum, test
przejścia po wszystkich pozycjach, autentyczne screenshoty
iPhone+iPad, regresje 7/8, zgodność z W3 v568
(bez twierdzenia „identyczny pikselowo”, zanim istnieje dowód).
Dopiero po tej bramce etap B — w pełni funkcjonalny wybór misji.

**Nie tworzono IPA.**
