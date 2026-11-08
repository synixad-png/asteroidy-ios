## Cel i konkretna przyczyna zmiany

Opisz problem, który wystąpił, i potwierdzone źródło jego przyczyny (plik, funkcja, profil, zrzut lub log). Nie zgaduj przyczyny.

## Powiązanie z oryginałem ASTEROIDY

Wskaż pliki Windows/SteamOS v568 i/lub zweryfikowane zachowanie gry. Jeśli porównanie nie było możliwe, zapisz „nie wiem”.

## Zakres i brak regresji

- [ ] Wprowadzono najmniejszą konieczną zmianę; nie dodano równoległego obejścia, duplikacji ani fikcyjnych danych.
- [ ] Weryfikacja mechaniki, dotyku, HUD-u, obrazu i zapisu; niezwiązane moduły pozostają bez zmian.
- [ ] Chronione audio SFX poza głównym wątkiem, wznowienie po blokadzie, iPad 4:3 oraz iPhone 15 Pro Max.
- [ ] Nie wprowadzono operacji dyskowych, synchronicznego audio ani zbędnych alokacji w ścieżce każdej klatki.
- [ ] Przebieg `python3 Tools/code_quality_audit.py --root . --gate` zaliczony.

## Testy i dowody

Podaj rzeczywiste przebiegi GitHub Actions, testy funkcjonalne i regresyjne oraz status kompilacji Swift/Metal. Nie nazywaj testu statycznego testem GPU.

**Test na fizycznym iPhonie/iPadzie:** nieprzeprowadzony / przeprowadzony (model, wynik).

**Zmiana FPS względem bazy:** brak pomiaru / wartości CPU, GPU, WAIT, FPS z tego samego scenariusza.

## Ryzyko i cofnięcie

Co dokładnie może ulec regresji? Jaki jest warunek uznania naprawy za ukończoną i bezpieczny sposób wycofania?
