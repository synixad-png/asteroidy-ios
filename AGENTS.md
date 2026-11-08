# AGENTS.md — stałe reguły jakości ASTEROIDY iOS

**Obowiązuje przy każdej następnej zmianie, PR, audycie, optymalizacji i wydaniu.**
Użytkownik wyraźnie zakazał „AI slop / slap code”: kodu pozornego, prowizorycznego,
powielanego, trudnego do poprawiania oraz niezweryfikowanych „optymalizacji”.
Ten dokument jest wymaganiem repozytorium, a nie propozycją.

## Podstawowe zasady

1. **Nie zgaduj oryginalnej gry.** Wierność zachowania ma wynikać z konkretnych
   źródeł ASTEROIDY Windows/SteamOS v568, istniejącego portu lub zweryfikowanego
   testu użytkownika. Nie podmieniaj brakujących danych źródłowych innymi.
   Jeśli mechaniki/zasobu nie da się zweryfikować, wskaż „nie wiem”, nie dopisuj
   hipotetycznej implementacji.
2. **Małe, ograniczone zmiany.** Najpierw odczytaj kod i zależności; ustal
   przyczynę na podstawie logów/testów, potem zmieniaj najmniejszy konieczny
   fragment. Nie dodawaj kolejnego równoległego rozwiązania obok aktywnego.
   Usuń nieużywany wariant po potwierdzeniu, że nie jest potrzebny testom ani
   innym scenom. Nie komplikuj kodu nowymi warstwami bez konkretnego powodu.
3. **Jedna odpowiedzialność.** Renderowanie Metal, symulacja, audio, HUD,
   zasoby, stan zapisu i diagnostyka powinny mieć odrębne API i właścicieli.
   Uogólniaj wyłącznie autentycznie wspólną logikę; powtarzanych bloków
   nie kopiuj w nowe miejsca. Unikaj plików „god objects”. W istniejących
   dużych modułach rozdzielaj odpowiedzialności stopniowo, z testami, zamiast
   przepisywać całość w jednym niezabezpieczonym commicie.
4. **Zero pozornego działania.** Żadnych atrap HUD-u, dźwięków, planet, fizyki,
   misji, liczników, FPS i podmienionych modeli przedstawianych jako oryginał.
   Nie wprowadzaj nieużywanych suwaków, pustych przycisków, tymczasowych
   obejść, martwych flag ani fałszywie zielonych testów.
5. **Obsługuj błędy jawnie.** W krytycznych ścieżkach nie stosuj
   `try!`, `as!`, `fatalError`, pustych `catch`, ukrywania błędów zapisu
   pliku ani dowolnego fallbacku. Oczekiwane braki zasobów mogą dawać
   bezpieczne `nil`, ale stan musi być rozpoznawalny, a test musi odróżniać
   brak od sukcesu. Diagnostyka nie może udawać ukończenia testu.
6. **Nie degraduj klatek.** W ścieżce klatki i `MTKViewDelegate.draw(in:)`
   unikaj odczytów dysku, budowania pipeline'ów i tekstur, synchronicznych
   wywołań audio, pracy blokującej główny wątek oraz nieograniczonych
   kolejek/allocacji. Zmianę wydajności oceniaj pomiarami CPU/GPU/wait i
   rzeczywistymi FPS, nie samą kompilacją ani spekulacją.
7. **Chronione zachowania:** potwierdzone przez użytkownika 60 FPS po
   wyprowadzeniu SFX poza główny wątek; poprawne iPad 4:3 i iPhone 15 Pro Max
   19.5:9; sterowanie lewa/prawa strona (automatyczny ogień przy dotyku prawej),
   pauza, oryginalne SFX i ich odtworzenie po wygaszeniu ekranu; właściwe
   źródłowe elementy HUD-u; sekwencje misji, uszkodzenia, zapis i nagrody.
   Żadnej regresji iPada przy naprawie iPhone'a.
8. **Utrzymuj czyste zależności.** Nie usuwaj źródeł Windows/SteamOS ani
   oryginalnych zasobów używanych do porównania, testów i odtwarzania
   kompilacji. Nie „sprzątaj” ślepo wersjonowanych plików, dopóki nie sprawdzisz
   importów, zasobów runtime i wszystkich testów.
9. **Test przed scaleniem:** test źródłowy + deterministyczny test mechaniki
   + regresja istniejących funkcji + faktyczna kompilacja Swift/Metal iOS.
   Przy zmianach UI uwzględnij bezpieczne obszary 4:3/19.5:9, a przy
   zmianach audio/FX testy FPS, pauzy i wybudzania. CI nie zastępuje
   interaktywnego testu urządzenia. Bez dowodu nie deklaruj zgodności 1:1,
   gotowego IPA, działania 60 FPS ani pełnego ukończenia gry.
10. **Dokumentuj trwałe ustalenia:** PR ma wskazywać konkretną przyczynę
    zmiany, źródło/raport, zakres zmodyfikowanych plików, testy, świadomie
    nietknięte mechanizmy i ograniczenia. Każde uproszczenie kodu ma
    usuwać konkretny problem, nie powiększać repo dla pozoru postępu.

## Stała kontrola jakości

- Uruchamiaj `python3 Tools/code_quality_audit.py --root . --gate` oraz
  `python3 Tests/CodeQualityAuditTests.py`; raport audytu jest artefaktem CI.
- Statyczne ostrzeżenie to **kandydat** do ręcznej oceny, nie automatyczny
  dowód błędu. Nie kasuj funkcji tylko dlatego, że ma wiele linii.
- Nie „naprawiaj” wymagań ani testów tylko po to, aby były zielone. Zmiany
  kontraktu muszą zachować jego pierwotną intencję.
- Priorytet refaktoryzacji: potwierdzony błąd albo ryzyko regresji →
  duplikacja i granice modułów → usprawnienie czytelności, bez zmiany
  funkcjonalności i bez wzrostu kosztu każdej klatki.
- Zapisuj otwarte ryzyka w `Reports/CODE_QUALITY_AUDIT_2026-11-08.md`;
  nie uznawaj ich za rozwiązane bez testu.
