# ASTEROIDY iOS v568 — iPhone-only ochrona FPS przy strzelaniu

**Data:** 08.11.2026, **baza:** IPA #141 z potwierdzonym przez użytkownika działającym audio; **wydanie:** IPA #142. **Zgłoszenie:** podczas strzelania iPhone spada z 60 do 30 FPS, natomiast na iPadzie wcześniejsze spadki już nie występują. Priorytet: bez regresji iPada.

## Zakres źródeł zweryfikowany przed zmianą
- `ASTEROIDYiOS/Sector01CarbonisPreview568.swift`: natywny `MTKView` w trybie misji 60 FPS, format `.bgra8Unorm`, `.depth32Float`, wygenerowany pełny oryginalny C279, cząstki, smugowe pociski/kolorowe światła, skały oraz podgląd planety.
- `ASTEROIDYiOS/CarbonisProjectileFX69.swift`: istniejący indeksowany pełny strumień źródłowej geodezyjnej geometrii pocisków, pierścieni i poświaty; `CarbonisIOSFXBudget568` posiada osobne istniejące przełączniki jakości. **Nie zmieniono** żadnej geometrii ani ustawienia.
- `SourcePerformance568.swift`: istniejący licznik prawdziwych zakończonych klatek Metal wraz z oddzielnymi CPU/SYM/WAIT/GPU/FX; brak telemetrii fizycznego iPhone'a w tej sesji. Mechanizm nie dowodzi, że przyczyną spadków jest wyłącznie GPU; zmniejszenie liczby pikseli ma pomagać, jeżeli ograniczeniem jest renderowanie.

## Rzeczywista zmiana
Wydzielono do nowego `ASTEROIDYiOS/PhoneCombatResolution568.swift` deterministyczny automat regulujący **wyłącznie rozmiar bufora renderowania Metal na iPhonie**, bez zmian gameplay, HUD SwiftUI i ani jednej próbki SFX. Dołączono go wyłącznie w `Sector01CarbonisPreview568.makeUIView` pod podwójną bramką `gameSession != nil && UIDevice.current.userInterfaceIdiom == .phone`.

- Oryginalne 100% pikseli zawsze na starcie i gdy jest 60 FPS.
- Przy utrzymującym się odstępie między klatkami wskazującym około 30 FPS **podczas aktywnych pocisków** przez >=0,65 s: redukcja do **84% wymiarów** (ok. 29,4% mniej pikseli).
- Gdy spadek utrzymuje się kolejne >=0,65 s: redukcja do **74% wymiarów** (ok. 45,2% mniej pikseli).
- Przy stabilnych ~60 FPS przez 4 s bez aktywnych pocisków: powrót o jeden poziom, aż do pełnej ostrości. Histereza zapobiega przeskakiwaniu rozdzielczości podczas ciągłego strzelania; wielosekundowy lock/unlock zeruje licznik.
- Rozmiar ustalany na podstawie **aktualnych bounds i contentScaleFactor rzeczywistego MTKView**, więc zarówno iPhone 15 Pro Max landscape 2796×1290, jak i obrót korzystają z właściwego aspektu. HUD 2D jest nadal rysowany w pełnej rozdzielczości UI.
- Efekty, pozycje asteroid, pociski, liczby segmentów, światła, zasady trafień, uszkodzenia, wybuchy, shader i audio v141 **nie były modyfikowane**.

**Kompromis:** przy spadku FPS scena 3D na iPhonie może przejściowo wyglądać mniej ostro, ponieważ faktycznie renderowana jest mniejsza liczba pikseli; to nie jest wzrost wydajności udowodniony na iPhonie i nie usuwamy elementów graficznych. iPad nie wchodzi do tej gałęzi i zachowuje oryginalne ustawienia MTKView.

## Kontrole
- [PR #6](https://github.com/synixad-png/asteroidy-ios/pull/6) — zmiany tylko w `Sector01CarbonisPreview568.swift`, nowy `PhoneCombatResolution568.swift`, testy i workflow; scalono jako `df1c59a6f8d1090faba643c96e45cc2cbb5ba892`.
- [PR CI #426](https://github.com/synixad-png/asteroidy-ios/actions/runs/42455917109): **2/2 wymagane PASS**, natywny macOS Swift/Metal oraz regresja fizyki i audio. Pierwszy CI #425 wykrył błąd składni w wyrażeniu dzielenia w nowym teście; skorygowano, a #426 przeszedł.
- [main CI #427](https://github.com/synixad-png/asteroidy-ios/actions/runs/42456161342): **3/3 PASS**.
- [IPA #142](https://github.com/synixad-png/asteroidy-ios/actions/runs/42456161374): **4/4 PASS**, Xcode **BUILD SUCCEEDED**, Apple iPhoneOS/ARM64, oryginalne 43 SFX/voice/intro i 15 runtime synth, `unzip -t` i `Tools/verify_ipa.py` **PASS** (iOS17+, iPhone+iPad, Payload/Info.plist/CRC).
- [Pobierz IPA #142](https://github.com/synixad-png/asteroidy-ios/actions/runs/42456161374/artifacts/13607468171), ZIP GitHub Actions **28 033 312 B**; **SHA256 zewnętrznego ZIP** `3c112a3dc5e8293d99190d3d7327de64021bb52fb86f47efd39692c85ae4b20f`; zawiera `ASTEROIDY_iOS_UNSIGNED.ipa`. Wymaga podpisania przy instalacji Sideloadly.
- `PhoneCombatResolution568Tests.swift` i `PhoneCombatResolution568Contract.py` przeszły: deterministyczne 60→30 FPS, progi, powrót do 60, brak oscylacji, wyliczenie 2796×1290 i portret, wyłącznie iPhone/iOS combat, pełna izolacja iPada, brak zmian do oryginalnych SFX/shot/Explosion524.

## Co pozostało
1. **Test sprzętowy iPhone** podczas ciągłego ostrzału i trafień — czy nowe 84%/74% rzeczywiście pomaga utrzymać 60 FPS.
2. Sprawdzić przy identycznej misji iPad, na którym użytkownik wcześniej potwierdził brak spadków, że poziom 60 FPS pozostaje stabilny i obraz nie uległ zmianie.
3. Jeżeli iPhone nadal spada do 30, odczytać z istniejącego licznika FPS odrębne CPU/SYM/WAIT/GPU i FX CPU P/W: jeśli GPU pozostaje niski, kolejna poprawka powinna dotyczyć CPU, routingu audio/strzałów lub rytmu wyświetlania zamiast dalszego cięcia rozdzielczości.

**Nie wykonano testu na fizycznym iPhone/iPad, nie można deklarować osiągniętych 60 FPS.** Stała lista 18 zadań portu: **38% ukończone / 62% pozostało**; poprawka wydajności nie jest kolejnym ukończonym etapem kampanii.
