# ASTEROIDY iOS v568 — CARBONIS 01: pełny przebieg misji (etap funkcjonalny)

**Data:** 6 listopada 2026. **Baza:** oryginalne źródła ASTEROIDY Windows/SteamOS v568. **Zakres:** wyłącznie pierwsza misja, CARBONIS 01 na oryginalnej planecie C279. Bez rozwijania drugiego sektora ani tworzenia zastępczej gry.

## Faktycznie zaimplementowane

1. **Bitwa:** oryginalny `Game.Wave`: 13 asteroid, cztery myśliwce typu 0; fizyka sferyczna `Physics68`, ochrona przy odrodzeniu, zderzenia skał i myśliwców, AI `EnemyTactics71`, realny ostrzał i rozpad asteroid na części oraz odłamki terminalne. W pierwszej misji nie ma bossa.
2. **Oryginalne trafienia:** Pulse rank1 zadaje 1 obrażenie, strzał przeciwnika poziomu1 zadaje 8; zakupione Twin/Scatter, Power III i Rapid zmieniają faktyczne pociski, liczbę luf, prędkość, przebijanie i odstępy między strzałami. Zakupiona osłona fizycznie odbija asteroidę i zużywa ładunek.
3. **Zbieranie żetonów:** `DropLoot` zgodne z `Game.cs:136`, frakcje `lootCarry`, pozycje w `Sphere67`, przyciąganie i kontakty `MovePickup68`, złote pierścienie na planecie i znaczniki na radarze. Żetony zostają doliczone po zebraniu, a na końcu misji zbierane są wszystkie pozostające.
4. **Zwycięstwo:** `FinishLevel()` tylko po pokonaniu rzeczywistych zagrożeń, wygaśnięciu odłamków i zakończeniu dodatkowej fali. Wersja sferyczna wymaga trzymania pustego pola ponad 0,2 sekundy. Powstaje jednorazowy raport `LevelSummary166`: statystyki, punkty, tokeny, premia **12 żetonów** na poziomie 1 i suma zarobku. Raport jest widoczny przez co najmniej 4,2 s przed możliwością wejścia do serwisu.
5. **Zapis ukończenia:** `Sector01MissionSettlement568` zapisuje rzeczywisty bit ukończenia sektora01 poprzez `CampaignStore556`, odblokowuje sektor02, nigdy nie zapisuje wygranej po samym wejściu w planetę lub po porażce. Druga próba rozliczenia nie dodaje żetonów; powtórna misja nie przyznaje kolejnej premii.
6. **Serwis z prawdziwymi zakupami:** osobny natywny ekran `Sector01ShopPanel568` z `Sector01Shop568`, sześć wczesnych opcji i ceny `Game.Price` (45,80,60/150,75/140,12,70+25 za naprawę). Posiadane Twin/Scatter można wyposażyć, maksymalny poziom Power3, Rapid2, osłony3 i życia5. Nie sprzedajemy jeszcze jonów, bomb i późniejszych modułów, bo ich mechanika nie jest wdrożona. Stan ekwipunku, portfela, żyć i osłon jest zapisywany między uruchomieniami.
7. **Porażka:** powrót do atlasu bez zaliczenia misji lub powtórka bitwy po GameOver; odrodzenia z odtworzeniem kierunku, wyzerowaniem prędkości i oryginalną ochroną 4,5 s. Pobliskie skały odsuwane są od miejsca startu.

## Testy zakończone sukcesem

**[GitHub Actions 42269114054](https://github.com/synixad-png/asteroidy-ios/actions/runs/42269114054): `verify-sphere-linux` SUCCESS.**

- `Tests/Sector01FullMission568Tests.swift`: **PASS 18** sprawdzeń integracyjnych po **335 rzeczywistych krokach symulacji 120 Hz**. Operator testowy celowo wstawia deterministyczne pociski bezpośrednio przy rzeczywistych celach, nie ustawia flagi wygranej i nie usuwa list wrogów. Zweryfikowano rozbicie skał, śmierć czterech myśliwców, zniknięcie odłamków, warunek zwycięstwa, raport, premię, odblokowanie sektora02, trwały zapis i brak nagrody za replay. To **test logiki silnika**, nie interaktywny test gry na iPhonie.
- `Tests/Sector01MissionFinish568Tests.swift`: **PASS 41** sprawdzeń portfela, trwałości profilu, rzeczywistych zakupów, limitów, ekwipunku, ochrony przed podwójnym rozliczeniem i powrotu po GameOver.
- `Tests/CarbonisCombat568Tests.swift`, `Tests/CarbonisBodyContact68Tests.swift`, pozostała regresja Swift/Linux: **PASS** w przebiegu `verify-sphere-linux`.
- Natywna kompilacja iOS przez Xcode na commicie `08fef65fb17ba4b6a55b7848bd84606310e50ed0` została uruchomiona po zaliczeniu testów Linux. Jej sukces/artefakt należy sprawdzać oddzielnie: `compile-device` był **queued** przy sporządzeniu raportu.

## Czego jeszcze nie wolno uznawać za zakończone

- Brak rzeczywistego uruchomienia **tej** wersji na iPhonie lub iPadzie i ręcznego przejścia od atlasu do następnego uruchomienia aplikacji; testy Linux nie dowodzą zgodności GPU Metal ani obsługi gestów na iOS.
- Nie ukończono odtworzenia oryginalnych efektów dźwiękowych `CombatSound.cs/Sounds79.cs`, pełnych efektów cząsteczkowych i porównania klatka-po-klatce z Windows v568. Pierwsza misja nie jest więc zweryfikowana wizualnie i dźwiękowo w 100%.
- Kolejne prawdziwe sektory 2–25 nadal pozostają do przeniesienia, mimo że po ukończeniu CARBONIS sektor02 zostaje poprawnie odblokowany w atlasie.
- Generator późniejszych typów myśliwców, zakupione późniejsze bronie i moduły oraz końcowa kampania pozostają częściowe lub niewdrożone. Nie oznaczać całego portu jako gotowego.

## Następne działanie

1. Potwierdzić kompilację Xcode i pojawienie się **nowego** IPA zawierającego obecny kod; ewentualne błędy odczytać z logów i poprawić.
2. Weryfikować na iPhonie rzeczywistą sekwencję: start CARBONIS → wygrana → raport → 4,2 s → serwis → atlas z zielonym ukończonym sektorem01 i odblokowanym02 → ponowne uruchomienie i wczytanie stanu.
3. Uzupełnić brakujące, zweryfikowane ze źródła oryginalne dźwięki i efekty pierwszej misji, następnie porównać rozgrywkę Windows/iOS. Bez wymyślonych assetów i bez regresji menu W3.

**Zasada wydania:** nie deklarować zakończonej misji 100% ani opublikowanego IPA, dopóki test Xcode i test na urządzeniu nie zostaną potwierdzone.
