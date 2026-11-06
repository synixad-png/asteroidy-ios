# ASTEROIDY iOS v568 — W3 MENU NAV: drugie wydanie IPA (06.11.2026)

## Faktycznie wydany artefakt

- **GitHub Actions SUCCESS:**
  [build 42212773252](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212773252),
  źródła commitu `1ebd88d37bd5cf0bb2b26ce961e067f4764b002c`.
- **GitHub artifact:** [13500341359](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212773252/artifacts/13500341359),
  `ASTEROIDY-v568-W3-MENU-NAV-UNSIGNED-IPA-20261106`.
- **Prawdziwy plik w środku archiwum:**
  `ASTEROIDY_v568_W3_MENU_NAV_iPhone_iPad_UNSIGNED.ipa`
- Rozmiar IPA **14 103 697 bajtów**.
- SHA-256 IPA **`9b16daf6e045220140505ebbed99cf24befadbea8c0b7b2d8a1080df7b5c98ce`**.
- `com.synixad.asteroidyios` — iOS, fizyczny ARM64,
  iPhone + iPad (`UIDeviceFamily=[1,2]`), minimalny iOS 17.
- Natywne Swift/Metal, bez WebView. Zawiera oryginalne
  SHA-pinned tło/logo W3, planetę NewHome290 (172208 trójkątów),
  lawę i model Vanguard431 (194427 wierzchołków).
- **Kontrola pakietu PASS:** oryginalne materiały w `.app`,
  `Tools/verify_ipa.py --require-vanguard-original`,
  CRC ZIP IPA, hash i rozmiar obliczone **ponownie po pobraniu
  artefaktu z GitHub** odpowiadają dokładnie raportowi builda.
- W stosunku do pierwszego IPA W3 dodano przede wszystkim
  dostępność siedmiu pozycji menu oraz ich przewijaną listę
  z minimum 44 pt pola dotyku na poziomym ekranie iPhone.
  Zmian nie nazywa się potwierdzonymi dotykowo bez XCTest.
- Jest to **NIEPODPISANY IPA**. Instalacja przez Sideloadly,
  podpisanie i działanie na fizycznym iPhone/iPad nadal
  **nie zostały przetestowane**.

## Kopia w Dysku Google użytkownika

Zapisano nowy, prywatny plik
[ASTEROIDY_v568_W3_MENU_NAV_IPA_20261106_GITHUB.zip](https://drive.google.com/file/d/1VyqprYPbt6KLGIqwKzgwrHzAGGqrGSyH/view?usp=drivesdk)
o rozmiarze **13 943 090 B** — jest to **artefakt GitHub ZIP**
zawierający pełny, prawidłowy plik IPA oraz raporty SHA/CRC.
Dysk Google po uploadzie potwierdził nazwę i rozmiar. Aby
uzyskać plik IPA, należy rozpakować ZIP i wybrać
`ASTEROIDY_v568_W3_MENU_NAV_iPhone_iPad_UNSIGNED.ipa`.
Na Dysku Google **nie umieszczono** błędnego ZIP-a pod nazwą IPA.
Bezpośredni plik IPA został też przygotowany lokalnie jako
`/mnt/data/ASTEROIDY_v568_W3_MENU_NAV_iPhone_iPad_UNSIGNED.ipa`.

## Dalszy plan (bez zmiany 18 zadań)

- Dla etapu A ukończono nową implementację natywnego menu,
  realny podgląd GPU NewHome290/Vanguard431 oraz
  przebudowę dostępu do siedmiu przycisków.
- **Bramka A jest wciąż otwarta**, ponieważ nowy test
  prawdziwych dotknięć i powrotów iPhone/iPad nie ma jeszcze
  ukończonego wyniku:
  [XCTest 42212331207](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331207).
  Weryfikacja obrazu i źródłowych sum w symulatorach:
  [GPU 42212331152](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331152).
  Nie zakładać PASS dla tych dwóch bez końcowego `success`.
- **Potwierdzone**: kompilacja i regressions
  [42212331058](https://github.com/synixad-png/asteroidy-ios/actions/runs/42212331058)
  zakończone PASS.
- Etap B (rzeczywisty wybór 26 misji) nierozpoczęty;
  nie zastępować loadera źródłowego losową sceną demo.
- **Dotychczasowy postęp**: cały projekt **27% / pozostało 73%**,
  zadanie 14 **10% (+0 pp)**; 7 i 8 chronione przed regresją.
