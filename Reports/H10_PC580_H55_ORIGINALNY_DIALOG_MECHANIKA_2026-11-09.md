# ASTEROIDY iOS — H10: rozmowa z mechanikiem, wierność PC v580
Data: 2026-11-09 | Gałąź: feature/ios-h55-v580-native-entry | PR #28 | H01–H09 chronione.

## Oryginalne, zweryfikowane źródła
- `Windows/src/Hub90.cs` SHA256 `a908a3632d22fab0932798405e0d0faff39334e2f1298d9e2d607d5b42587a4d`, fragment `HubNpcInteract526` wiersze 20–33.
- `Windows/src/HubWalk375.cs` SHA256 `a8a1a4d49dcfada5f56cf345d0a8fbc9ca15e52a44add713cbedc9512fa43980`, `HubWalkInteract375` wiersze 353–364.
- `Windows/src/H55Renderer.cs` SHA256 `6210dd9a63d8b974e5701469aa11059ec47221c409531d8506ca47f2656388eb`, mechanik v526 i `HubNpcConversationFinished526` wiersze ok. 1816–1830.
- Źródłowy PC v580 zawiera **tylko jedną kwestię**: `MECHANIK: WSZYSTKO W PORZADKU. E / ENTER / ESC - ZAKONCZ ROZMOWE.`. Po zakończeniu: `MECHANIK: DO ZOBACZENIA.`. Nie zawiera drzewa dialogów, listy odpowiedzi, zmiennych dialogowych ani innych scenariuszy interakcji dla poruszającego się NPC. Nie wolno ich wymyślać i nazywać zgodnością PC.
- Warunki: aktualny tryb H55, zakończone przybycie 3,25s, włączony tryb chodzenia; start w dystansie **<= 2,7 m od aktualnej pozycji NPC**, zamknięcie przez E/Enter/Esc lub przycisk pada, również bez ponownej kontroli dystansu. Zamknięcie liczy jedno `HubNpcConversationFinished526++`; nawigację uruchamia H08 dopiero po oddaleniu się gracza o >2,5m.

## Implementacja H10
- `ASTEROIDYiOS/H55NpcDialogue580.swift`: osobny deterministyczny sterownik `ignored/opened/closed`, dokładne teksty i zasięg źródła PC, blokada przed przybyciem, kontrola błędnych współrzędnych, licznik zakończonych rozmów i reset przy ponownym wejściu do H55.
- `ASTEROIDYiOS/H55ScenePage580.swift`: podłączenie sterownika do istniejącego przycisku **ROZMAWIAJ po lewej**, oryginalna kwestia bez wymyślonych dodatkowych opcji, przycisk końca, MENU najpierw zamyka dialog jak ESC, podczas dialogu lewy dotyk i skok są blokowane. Po zamknięciu wywołanie **istniejącego, nienaruszonego `mechanic.finishConversation()`** — H08 sam rozstrzyga o rozpoczęciu patrolu po odejściu.
- `Tests/H55NpcDialogue580Tests.swift`: 3,25s blokady, źródłowy dokładny tekst, zasięg graniczny 2,7m, niedostępność przy 2,701m, wielokrotny dialog, licznik, reset, rzeczywista bramka H08: blisko po rozmowie NPC stoi, dopiero po oddaleniu rozpoczyna trasę.
- `.github/workflows/h10-test-ipa.yml`: pełne wcześniejsze testy H01–H09 + osobny test H10 + natywna iPhone/iPad ARM64 IPA, oryginalny przypięty GLTFKit2 0.5.15 z kontrolowanym ponawianiem HTTP 504, CRC i zasoby.

## Zakres i granice
- **Nie wdrożono menu odpowiedzi, rozbudowanych kwestii, handlu, zadań dialogowych ani wyposażenia.** Oryginalny PC v580 ich tutaj nie ma; ewentualna rozbudowa to osobne zlecenie/projekt, nie zgodność H10. Warsztat i wyposażenie należą do H11.
- Bez zmian geometrii GLB, śluz H07, ruchu gracza H06, A* H08, Foot IK H09, oświetlenia i modułów misji.
- Dopiero test CI i kompilacja IPA potwierdzą wydanie; wynik z fizycznego iPhone/iPad nadal należy do H15. Nie deklarować wizualnej zgodności lub zakończenia projektu przed urządzeniem.
## Końcowa kontrola wydania H10 (09.11.2026)
- CI [42577040256](https://github.com/synixad-png/asteroidy-ios/actions/runs/42577040256): oba zadania PASS — cały zestaw H01–H10 Swift i natywna kompilacja iPhone/iPad ARM64 z dokładnie GLTFKit2 0.5.15.
- Niezależne pobranie artefaktu GitHub id 13655648352, ZIP `ASTEROIDY_v580_H10_ROZMOWY_MECHANIK_GITHUB_PAKIET.zip`, 29 316 392 B, archiwum ZIP CRC PASS.
- IPA `ASTEROIDY_v580_H10_ROZMOWY_MECHANIK_TEST_UNSIGNED.ipa`, **29 955 488 B**, SHA256 **`f2bdb078b4b88c8c8ed1a8e77c0e0ebf66598e6e85e759c1083a9aa235afbd75`**, identyczny z `reports/SHA256SUMS.txt` wygenerowanym na macOS. ZIP/IPA CRC PASS, 73 rekordy. Mach-O arm64 CPU 16777228, iOS minimum 17.0, UIDeviceFamily [1,2]. Raport `verify_ipa.py`: PASS original Vanguard431 GPU UV, 194427 wierzchołków, 10802 ścian, para oryginalnych zasobów i SHA256.
- Wersja kodu aplikacji commit `484080de9ef28f1b04b58a79c869414d43eb4be8`; weryfikacja GitHub compare od tego commitu do aktualnej gałęzi wykazała **tylko raport H10 i harmonogram**, bez zmian `ASTEROIDYiOS/*.swift`.
- Skopiowana i odczytana po zapisie kopia ZIP 29 316 392 B: https://drive.google.com/file/d/1Ro3KzhucZ8HnzCahnJn4Q4hkzlLtZepd/view?usp=drivesdk
- Nie wykonano rzeczywistej instalacji IPA ani interaktywnego testu rozmowy na fizycznym iPhone/iPad; H15 pozostaje otwarty. Plik IPA jest niepodpisany. Oryginalny `hangar_h55.glb` nie jest dołączony; dotychczasowy zaimportowany GLB jest wymagany.
- Harmonogram niezmienny H01–H16; H10 85% z powodu braku odbioru sprzętowego, całość szacunkowo około 60%. Nie rozpoczęto H11.