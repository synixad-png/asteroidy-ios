# ASTEROIDY iOS HUD v600 — naprawa niekompletnego IPA (10.11.2026)

## Potwierdzony błąd
Pierwsze IPA HUD v600 (`ASTEROIDY_iOS_HUD_v600_iPhone_iPad_UNSIGNED.ipa`,
10 029 657 B) kompilowało się poprawnie dla iOS ARM64, ale nowy jednorazowy workflow
`build-ios-hud-v600-ipa-20261110.yml` **nie uruchomił istniejących kroków
odtwarzania oryginalnych plików gry**. Wydanie nie zawierało danych planety
CARBONIS, planety W3, źródłowego statku gracza, grafiki menu ani 15
oryginalnych plików PC586 (4 GLB, 4 Metal mesh, 4 JPEG i 3 oryginalne
modele widoku FPP). Rozmiar IPA 11 MB nie był sam w sobie dowodem błędu,
ale kontrola listy zasobów wykazała jego rzeczywistą niekompletność.

## Naprawa i dowody
- `Tools/repair_ios_hud_v600_full_assets.py` odzyskuje **31** oryginalnych,
  zweryfikowanych plików. Nie kompiluje ponownie aplikacji, nie zmienia jej
  binarnego ARM64 ani żadnego wcześniejszego pliku.
- `.github/workflows/repair-ios-hud-v600-full-ipa.yml`: pobiera dokładny
  już skompilowany iOS ARM64 Release z run `42840039874`, weryfikuje
  SHA256 wcześniejszego IPA, wszystkie cztery oryginalne archiwa v568
  oraz 15 elementów `SourceResources/PC586`. Odtwarza
  źródłowy CARBONIS, W3 home, PlayerShip367, oryginalne menu W3 i
  modele PC586. Weryfikuje CRC, Mach-O, UIDeviceFamily 1/2 oraz sumy SHA256.
- GitHub Actions run `42844422200`: **PASS**. Zbudowany artefakt
  `ASTEROIDY_iOS_HUD_v600_PELNE_ZASOBY_UNSIGNED.ipa`:
  **53 959 078 B**, SHA256
  `e2ecd42b8c2a63aa52ec0d36a2a9eb0c174ff117587c212d07a61a114ff89d73`.
  57 dotychczasowych plików skompilowanego IPA i wszystkie 31 nowych
  zweryfikowane bajtowo. 15/15 modeli PC586 PASS w istniejącym
  `Tools/verify_pc586_complete_ipa.py`.
- Lokalnie do kompletnego już IPA dołączono dodatkowo jedyny brakujący
  zasób HUD `planetarium.glb` z oryginalnego ZIP PC v600:
  **3 228 900 B**, SHA256
  `71ca9ff24e044a831a5c7197e343594dd1fd801284af6231870570b35ad43860`.
  Sprawdzono zgodność z wcześniejszym oryginalnym GLB, CRC ZIP i bajtową
  identyczność wszystkich dotychczasowych pozycji.
- **Końcowe naprawione IPA dla użytkownika**:
  `ASTEROIDY_iOS_HUD_v600_PELNE_ZASOBY_PLANETARIUM_UNSIGNED.ipa`,
  **54 946 217 B**, SHA256
  `2f5fabcb2e05c474e9043dc36ce3eb0e6c6fe1fa80dfc7537e5fc2e7433b31a4`.
  **89 plików w aplikacji, CRC PASS**. Weryfikacja końcowa w kontenerze
  ChatGPT: wszystkie 57 oryginalnych elementów zachowane, 31 odtworzonych,
  dokładnie jeden dodatkowy oryginalny GLB planetarium.

## Ograniczenie niezależne od wykrytego błędu
Oryginalny `hangar_h55.glb` ma 126 419 336 B i pozostaje **oddzielnym,
już wcześniej uzgodnionym importem przez Pliki iOS**. Nie ma go
w GitHub `SourceResources/PC586`, więc nie wolno udawać, że został
wbudowany. Nie należy mylić go z trzema oryginalnymi modelami
`gloves_parted.glb`, `gloves_combined.glb` i `EXP01_SOURCE_v601.glb`,
które są już w naprawionym IPA.

IPA nadal jest niepodpisane i nie przeprowadzono testu wizualnego ani
interaktywnego na fizycznym iPhonie/iPadzie. Postęp implementacji HUD
nie rośnie automatycznie z powodu naprawy kompletności zasobów.
