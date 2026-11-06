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

## Kolejność operacyjna i zasada jednej aktywnej funkcji

Zgodnie z końcową sekcją `PORT_STATUS_18_TASKS.md`: 7 i 8 są
zamknięte, a **następny aktywny punkt to ZADANIE 9 — Wszystkie bronie
i efekty trafień (10%)**. Nie rozpoczynać równolegle AI (10), bossów
(11) ani misji (12–13), dopóki nie domkniemy w dostępnym zakresie
zadania 9. Gdy natrafimy na twardą zależność od nieukończonego 1–6,
wykonujemy wyłącznie niezbędną naprawę zależności, odnotowujemy ją
pod jej właściwym numerem, wracamy do 9.

Po 9: 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18.
Pozostałe 1–6 **nie są oznaczone jako ukończone**; mają własne
otwarte bramki i wymagają domknięcia przed deklaracją całości
portu. Nie wolno omijać krytycznej zależności od 1–6.

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

## Najbliższy rzeczywisty zakres: Zadanie 9

Audyt oryginalnych typów broni z v568 i ich wywołań, wybór jednego
pełnego toru: wejście gracza → strzał → pocisk → kolizja → efekt trafienia
→ zgodne obrażenia. Zachować już zamknięte zadania 7/8.
Zadanie 9 kończy się dopiero, gdy **wszystkie** oryginalne bronie i efekty
są implementowane i zweryfikowane, nie po jednym efekcie.
