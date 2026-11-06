# ASTEROIDY v568 — zweryfikowane zasoby oryginału, iOS

**Baza referencyjna: wyłącznie Windows/SteamOS v568.** Nie należy podmieniać
modeli po nazwie na GLB z Biblioteki ani deklarować 100% zgodności wizualnej.

## Stan wykonania

- Na `main` są cztery pliki `ASTEROIDY_v568_ZASOBY_DO_GITHUB_CZESC_01_z_04.zip` ... `04_z_04.zip`.
- `Tools/stage_v568_resources.py` potwierdza SHA-256 KAŻDEGO ZIP-a przed otwarciem,
  następnie wymaga dokładnie 90 unikalnych ścieżek, w tym 89 plików ujętych
  w `MANIFEST_SHA256_ALL_FILES.txt`. Sam manifest to plik dziewięćdziesiąty,
  nie może zawierać własnego samohashowania.
- Sprawdza SHA-256 wszystkich 89 plików manifestu, odrzuca duplikaty,
  symlinki, wyjścia poza katalog i nieoczekiwane nazwy. Rozpakowuje w nowym
  katalogu tymczasowym i dopiero po zakończeniu przenosi go atomowo.
- **Potwierdzone na GitHub Actions:** `verify-v568-assets.yml`,
  [run 42182816197](https://github.com/synixad-png/asteroidy-ios/actions/runs/42182816197)
  zakończył się sukcesem (bez IPA).
- Archiwa nie są rozpakowywane do `ASTEROIDYiOS/Assets` podczas zwykłej
  kompilacji. Żaden nieprzypisany obiekt nie trafia do programu przypadkiem.

## Użycie lokalne / CI

```sh
python3 Tools/stage_v568_resources.py --root . --verify-only
python3 Tools/stage_v568_resources.py --root . --destination /tmp/asteroidy-v568-verified
```

Druga komenda wymaga **nieistniejącego** katalogu docelowego. Rozpakowanie
jest rozdzielone od budowania programu; ZIP-y nie są zastępstwem działającego
importera/rendererów siatki i materiałów w Metal.

## Prawidłowa interpretacja 26 planet

Według dostarczonych oryginalnych źródeł `PlanetBiomes.cs`,
`PlanetMesh.cs`, `GpuPlanetGltf463.cs` i `Orbit50.cs`, 26 pozycji
atlasu nie jest 26 niezależnymi plikami GLB. Geometria wielu planet jest
generowana w C#, a specjalne planety wykorzystują osobne siatki, dane lub
animacje. Przy portowaniu należy odwzorować **ten sam kod** zamiast
wymyślać zamienniki. Również statki 0/2/4/5 i warianty wsparcia korzystają
z generatorów `ShipMesh.cs`, a typy 1/3 korzystają z autentycznych danych
`.mesh.gz` z odrębnymi wersjami i korektami źródłowymi.

## Dalsze prace, których nie ukończono

1. Dla każdego obiektu używanego w grze ustalić ścieżkę runtime:
   siatka binarna + materiał, GLB/morph, bądź generator proceduralny.
2. Portować i porównywać poszczególne formaty z bazą **v568** bez
   zmieniania zamrożonych mechanik gry iOS.
3. Przeprowadzić rzeczywiste testy renderowania i odtwarzania misji
   w symulatorach Apple, a na końcu na iPhone i iPad.
4. `hangar_h55.glb` nie został dostarczony w źródłowej paczce
   `BEZ_HANGARU`. Nie podmieniać go na inny model bez potwierdzenia.
5. Nie tworzyć IPA bez wyraźnego zlecenia.

**Zakres potwierdzenia:** integralność i izolowane rozpakowanie v568 —
TAK. Integracja wszystkich modeli w rendererze Metal — NIE.
Zgodność wszystkich 26 misji — NIEPOTWIERDZONA.
