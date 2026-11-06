# ASTEROIDY iOS v568 — oryginalny boss typu 4, B82S

Data: 2026-11-06. **Bez nowego IPA i bez nowej wersji wydaniowej.**

## Ustalona rzeczywista ścieżka w źródłach PC

`PortingReferenceCode/v568/Windows/src/GpuBossGallery82.cs`
w `GetGallery82` wybiera `alien_scout_173.b82`, gdy `activeCampaignBoss83==4`.
W kompilacji jest osadzony plik:
`PortingResources/v568/Shared/Assets_Boss82_GZ/alien_scout_173.b82.gz`
(SHA256 `2f95d6b1b9631aa0d08a890025e88aaecb8c5429003f47ef5767f15f9bc54385`).

Nie jest to ogólny GLB ani model testowy zastępujący kampanię.
Wariant ma nagłówek `B82S`: 88 niezależnych części, 339240
wierzchołków, 113080 trójkątów, 10 autentycznych klipów i 49
macierzy (klatek) każdego klipu na część. Strumień ma 10 Float32 na
wierzchołek: XYZ + normalna XYZ + RGBA.

## Zrealizowane

- `Tools/convert_v568_alien_scout_b82s.py` dekoduje źródłowy gzip,
  sprawdza bajtową SHA256, numer części i ramki, zachowuje niezmienione
  pakiety 10 Float32/wierzchołek oraz wszystkie matryce 4×4.
- `Tests/V568AlienScoutB82STests.py` weryfikuje zgodność z
  `GpuBossGallery82.cs`, wszystkie offsety części i zakresy ramek,
  sumy kontrolne, pełną zawartość oraz odrzucenie fałszywego pliku.
- `ASTEROIDYiOS/SourceAlienScout173.swift` dodaje natywny czytnik
  podpisanych SHA256 plików wierzchołków i animacji bez założeń o
  niezweryfikowanej hierarchii ruchu.
- `Tests/SourceAlienScout173NativeTests.swift` sprawdza w Swift
  kompletną liczbę części, dostęp do macierzy, indeksowanie klipów
  oraz odrzucenie uszkodzonych plików.
- Nie włączono jeszcze tego bossa do gry; nie zmieniono wyglądu
  dotychczasowych obiektów ani mechaniki kolizji.

## Oryginalne sumy po dekodowaniu

- Raw B82S SHA256: `59169b3bbb8200f985d4efa836ad94cea47f9523bff6e409e599ecbe3133b8c3`
- GPU vertex bytes: 13569600, SHA256
  `21e602b4db46716ef72e447c09e0c2b8faf083c1872c45af537caf20056d81c3`
- Animation bytes: 2759680, SHA256
  `0ca71aeb3751e65ffe1772129ddb39bc29cd193e5d3ad5edefdf5d0565b9c505`

## Testy

- Oryginalne zasoby i parser B82S: **PASS**, GitHub Actions:
  [42190816610](https://github.com/synixad-png/asteroidy-ios/actions/runs/42190816610)
- Mac Apple Swift — dekoder z autentycznym archiwum i pełna
  natywna kompilacja aplikacji iOS: **PASS**:
  [42191075334](https://github.com/synixad-png/asteroidy-ios/actions/runs/42191075334).

## Czego test NIE potwierdza

- Brak jeszcze renderowania bossa w Metal oraz oryginalnego
  `ApplyGalleryPose169` z `GpuBossGallery82.cs`.
- Brak pełnego przeniesienia animowanej hierarchii modułów,
  uszkodzeń, oderwanych części, broni, AI i walki bossa.
- Nie przetestowano tego bossa wizualnie na GPU iPada, iPhone'a
  ani na fizycznych urządzeniach.
- Nie ma podstaw do deklarowania pełnej zgodności kampanii z PC v568.

**Następny krok:** odtworzenie źródłowych macierzy animacji i
`ApplyGalleryPose169` wraz z grupami `BossMeshGroup84`, a dopiero
potem podłączenie oryginalnego koloru/shadera i walki.
