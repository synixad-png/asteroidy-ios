# ASTEROIDY iOS v568 — drugi źródłowy myśliwiec i parametry sześciu klas

Data: 6 listopada 2026. Baza: `synixad-png/asteroidy-ios`, historyczne źródła ASTEROIDY Windows/SteamOS v568. Etap rozwija istniejącą pierwszą misję; nie tworzy zastępczej gry.

## Zmiany

1. `ASTEROIDYiOS/CarbonisShooterMesh71.swift` ma obecnie dwa odrębne generatory `typeZero()` i `typeOne()`. Drugi jest portem `ShipMesh(1,false)` (nie odmienionym GLB gracza) z `Windows/src/ShipMesh.cs:59–108`. Wprowadza własny profil kadłuba, pięciosegmentowe krawędzie skrzydeł, panele tytanowe, pozycje działek i prawdziwy kolor drona `GpuRobot70.cs:5–6` `(255,92,45)`. Istniejący typ 0 nie został zmieniony.
2. `Sector01CarbonisPreview568.swift` wykorzystuje cache MTLBuffer indeksowany typem 0/1. Każdy myśliwiec jest ustawiany według źródłowej pozycji sferycznej i kierunku z symulacji. Rodzaje 2–5 **nie** są podmieniane na inne modele, dopóki nie zostaną przeniesione.
3. Zachowano `GpuRobot70.cs:17` — podczas `Telegraph71>0` rozjaśniane części (materiały 5/6) są skalowane do 1,15. Kadłub i skrzydła nie są powiększane.
4. `ASTEROIDYiOS/ShooterTactics71.swift`: jawne źródłowe parametry `EnemyTactics71.cs:9–30,39,53–74` dla 25 poziomów, 6 typów i 3 trudności: szybkość pocisków, zasięg, orbitowanie, czas ostrzeżenia, blokada kierunku salwy, rozrzut, liczba strzałów, seria, regeneracja i obrażenia z bankierskim zaokrąglaniem `Math.Round` C#.
5. `ASTEROIDYiOS/CarbonisCombat568.swift` odczytuje te parametry dla aktywnego CARBONIS poziomu 1 (typ 0). Dotychczasowe źródłowe wartości zostały zachowane: dystans 158, 245 jednostek/s, ostrzeżenie 0,82 s, jedna kula, odzyskanie 2,8 s, 8 punktów obrażeń. Moduł nie udaje, że pozostałe planety są grywalne.
6. `Tests/CarbonisShooterMesh71Tests.swift` i `Tests/ShooterTactics71Tests.swift` sprawdzają strukturę, odrębność modeli i 450 kombinacji reguł. Regresja iOS obejmuje brak zastępczych obiektów, poprawność przydziału buforów GPU i świetlnych rdzeni podczas ostrzeżenia.

## Wyniki potwierdzone

[GitHub Actions 42260834217](https://github.com/synixad-png/asteroidy-ios/actions/runs/42260834217) — test `verify-combat-no-ipa`: **SUCCESS**.

- `97 301` asercji geometrii: typ0 **5345** trójkątów, typ1 **5521** trójkątów, osiem ciągłych grup materiałów na model.
- `6307` asercji `EnemyTactics71` na 450 profilach — **PASS**.
- Oryginalne testy lotu CARBONIS, wcześniejszych asteroid, kolizji, fizyki, zapisu, 26-pozycyjnego atlasu i shaderowych kontraktów — **PASS**.
- Dodatkowa poprawka skalowania rdzeni o 15% ma własny nowszy przebieg CI; nie należy deklarować jego sukcesu przed sprawdzeniem zakończenia.

[GitHub Actions 42259012837](https://github.com/synixad-png/asteroidy-ios/actions/runs/42259012837) — **SUCCESS Xcode i artefakt niepodpisanego IPA** (26,3 MB), ale oparty na **wcześniejszej rewizji** `a7ebee2f`. Nie zawiera drugiego myśliwca ani całej obecnej implementacji. Kolejna kompilacja aktualnego kodu jest uruchomiona; na tym etapie jej sukces niepotwierdzony.

## Braki, bez fałszywego 100%

- Cała aktywna gra pozostaje ograniczona do CARBONIS 01. Typ 1 nie występuje jeszcze w tej początkowej fali i będzie używany dopiero w kolejnych sektorach.
- Nie przeniesiono proceduralnych siatek typów 2–5 ani pełnych misji od 2 do 25, bossów, wielobroniowego uzbrojenia, kompletnej ścieżki zapisu wyników i audio.
- Nie wykonywano interaktywnych testów iPhone/iPad i porównania renderingu GPU Apple ze źródłowym Windows v568; testy matematyczne nie zastępują kontroli obrazu.
- System etapów A–J i lista 18 zadań pozostają niezmienione.

## Następne działanie

Zweryfikować najnowszy test skalowania świecącego rdzenia myśliwca, ponowić Xcode na obecnej rewizji, a następnie rozpocząć kolejny istniejący typ przeciwnika wyłącznie na podstawie `ShipMesh(2,false)`. Nie używać zastępczych GLB ani wyników testów z nieprawidłowych buildów.

## Końcowa kontrola tego etapu

[Najnowszy test pełnej regresji CARBONIS — 42261182143](https://github.com/synixad-png/asteroidy-ios/actions/runs/42261182143): `verify-combat-no-ipa` **SUCCESS**, obejmuje również efekt skalowania rdzeni 1,15× i aktualny kontrakt UI/Metal. Natywny macOS pozostaje niezależnym testem do potwierdzenia.

Po tym wyniku uruchomiono [nową kompilację IPA 42261831842](https://github.com/synixad-png/asteroidy-ios/actions/runs/42261831842) dla commita `1f2d30bfa465ccc6b63ff858d267de80fed10c6d`, który zawiera źródłowy typ 1, reguły 450 profili i rdzenie ostrzegawcze. W chwili raportowania workflow nadal się wykonuje; nie ma jeszcze potwierdzonego artefaktu dla tej rewizji. Poprzednio zweryfikowany IPA `42259012837` pozostaje osobnym, starszym plikiem.
