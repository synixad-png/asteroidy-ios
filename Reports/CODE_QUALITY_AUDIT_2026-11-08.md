# ASTEROIDY iOS — audyt utrzymywalności i „AI slop”

**Data:** 08.11.2026  
**Gałąź kontrolowana:** `refactor/quality-audit-clean-code-policy-20261108`  
**Zakres:** cały dostępny kod i konfiguracja repozytorium oraz pogłębiony przegląd identycznych bloków rendererów, diagnostyki GPU i oryginalnego DSP.  
**Automatyczny przebieg audytu:** [GitHub Actions #42482814731](https://github.com/synixad-png/asteroidy-ios/actions/runs/42482814731), artefakt MD + JSON.  
**Kryterium:** nie zgadywać; potwierdzić przyczynę, zachować działające mechanizmy i wprowadzać tylko zmiany z weryfikowalnym zyskiem utrzymaniowym.

## 1. Zweryfikowany stan

- Przeskanowano **350 śledzonych plików kodu/konfiguracji**, w tym **111 produkcyjnych plików Swift**, wraz z kodem Metal, narzędziami Python i workflowami GitHub. Nie jest to analiza obrazów, modeli ani binarnych zasobów.
- **0 krytycznych** naruszeń wykrytych przez ograniczony zestaw reguł automatycznych (np. `try!`, `as!`, puste `catch`, `DispatchQueue.main.sync`, nieuzasadniony trap). **Nie oznacza to 0 błędów ani 100% czystego kodu.**
- Pozycje wymagające dalszego ręcznego przeglądu: **20** kandydatów wymuszonych subskryptów opcji, **33** `try?`, **23** przekazania na main queue, **60** wywołań tworzących zasoby GPU, **26** logowań oraz **2** świadomie pozostawione strażniki wewnętrznych filtrów DSP.
- Wykryto **165 identycznych 10-liniowych okien** między `MetalRenderer.swift` i `SourceCombatSky568.swift`. Zliczenie okien nakładających się na siebie nie jest liczbą 165 oddzielnych błędów/funkcji.
- Przykładowe duże moduły: `MetalRenderer.swift` **1769 linii**, `Sector01CarbonisPreview568.swift` **1384**, `CarbonisCombat568.swift` **863**, `OriginalAudioAV568.swift` **820**. Sam rozmiar pliku nie dowodzi złej jakości.

## 2. Naprawy wykonane w tym PR

1. **Jedna wspólna implementacja zasobów oryginalnego nieba:** `SourceSkyAssetFactory568.swift` zastępuje trzy zweryfikowane, co do instrukcji i formuł, kopie `makeSphereHaloTexture`, `sphereSky207` i `solarOverlaySource556` w dwóch rendererach. Bez zmiany geometrii, kolorów, kolejności halo/gwiazda, danych BGRA 64×64 czy liczby wywołań na klatkę. Kontrakty oryginalnego źródła utrzymano i rozszerzono.
2. **Jedna obsługa diagnostyki GPU:** `OriginalRenderProofWriter568.swift` zastępuje dwa powielone zapisy JSON z `MetalRenderer.swift`. Nazwy plików i atomowość zachowane. Wyjątki zapisu są jawnie logowane, zamiast po cichu ignorowane. Ścieżka normalnego renderowania nie wykonuje tej diagnostyki; działa ona po włączeniu istniejących testów dowodowych GPU.
3. **Zabezpieczenie DSP bez podmiany dźwięku:** dwa `preconditionFailure` dotyczą wyłącznie brakującego klucza stałej tablicy oryginalnych współczynników SOS. Test `OriginalMusicFilterKeys568Contract.py` sprawdza **25 wymaganych kluczy** i obie postacie strażników; nie wprowadzono syntetycznych filtrów zastępczych ani zmian sampli muzyki.
4. **Trwałe wymagania dla następnych zmian:** `AGENTS.md` zawiera zakaz sztucznych obejść, dublowania mechanizmów, atrap, nieudowodnionych optymalizacji i twierdzeń o działaniu bez testu. `Tools/code_quality_audit.py` oraz workflow `.github/workflows/code-quality.yml` uruchamiają przegląd na kolejnych PR i zapisują czytelny raport JSON/MD.
5. **Higiena repozytorium:** `.gitignore` zapobiega przypadkowemu dodawaniu buforów kompilacji, cache Pythona i lokalnych plików IDE, bez usuwania oryginalnych źródeł lub zasobów.

## 3. Otwarta lista ryzyk — nie uznawać za zakończone

| Priorytet | Zakres | Co wymaga dowodu i pracy |
|---|---|---|
| P1 | Pozostała duplikacja rendererów nieba | Rozróżnić części rzeczywiście identyczne od świadomie niezależnych ścieżek intro i misji; refaktoryzować pojedynczy blok naraz z testami obu scen oraz Apple GPU |
| P1 | `Sector01CarbonisPreview568.swift` | Ocenić właścicieli zasobów, tworzenie buforów i pipeline'ów na zimnym starcie względem pętli rysowania; nie zmieniać FPS bez profilu urządzenia |
| P1 | `MetalRenderer.swift` | Stopniowo wydzielać budowanie zasobów, sceny i diagnostykę, chronić kolejność renderowania i source geometry; nie przepisywać całej klasy na raz |
| P2 | 20 miejsc z `[key]!` | Ustalić, które mają dowiedzioną niezmienniczość, a które wymagają bezpiecznego dostępu i testu błędu |
| P2 | 33 `try?` | Oddzielić oczekiwane, bezpieczne brakujące dane od błędów maskowanych w krytycznych operacjach I/O |
| P2 | 60 wywołań `makeBuffer/Texture/Pipeline` | Sprawdzić wywołania i lifecycle; **nie** twierdzić, że 60 alokacji występuje co klatkę |
| P2 | 31 workflowów GitHub | Przejrzeć powielone bloki testów i zależności, ale nie usuwać używanych specjalistycznych testów dla źródeł Windows v568 |
| P3 | Nazewnictwo z numerami wydań | Zachować nazwy powiązane z oryginalnymi procedurami Windows; w nowych abstrahowaniach preferować nazwy funkcjonalne, nie mnożyć nazw `vNNN` bez potrzeby |

## 4. Mechanizmy zamrożone

- Potwierdzone przez użytkownika **60 FPS po przeniesieniu efektów SFX poza główny wątek**.
- Oryginalne audio, wznowienie po blokadzie ekranu, pauza.
- Sterowanie dotykiem: lewa strona lot, prawa skręt i jednoczesny ostrzał.
- Zweryfikowany wizualnie przez użytkownika iPad 4:3; iPhone 15 Pro Max wymaga oddzielnych testów po kolejnych zmianach.
- Source-exact parametry i geodezja oryginalnej gry; fizyka, kolizje, ścieżka nagród/zapisu; brak atrap.

## 5. Co oznacza wynik PASS

**Zaliczone:** walidacja statyczna, integralność źródłowych formuł objętych testami, testy skanera, kontrola wymaganych filtrów SOS i reguły jakości repozytorium. Natywna kompilacja Swift/Metal i pełna regresja bojowa mają oddzielne statusy w [przebiegu testów PR](https://github.com/synixad-png/asteroidy-ios/pull/15/checks).

**Niepotwierdzone:** interaktywny test iPhone/iPad po tym PR, bitowa lub pikselowa identyczność rendererów przy rzeczywistym GPU, zerowa liczba wszystkich błędów oraz automatyczne usunięcie wszystkich problemów architektury. Twierdzenie „cały kod idealny” byłoby nieprawdziwe.

## 6. Procedura każdej następnej poprawki

Następne PR musi podać konkretny problem, powiązanie ze źródłami v568, niezmienione obszary, dowód testowy, status urządzeń i ewentualny pomiar FPS. Zmiany powodujące regresję wycofać, zamiast dokładać warstwy łatek. **Nie zwiększać numeru wydania tylko dlatego, że przeprowadzono audyt lub poprawiono samą dokumentację.**
