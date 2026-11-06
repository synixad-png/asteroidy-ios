# ASTEROIDY iOS v568 — etap C: oryginalna mapa terenu CARBONIS C279

Data: 2026-11-06. Projekt: synixad-png/asteroidy-ios. Stan: przygotowanie rzeczywistych kolizji, nie grywalna misja.

## Dokładne źródło i zmiana

W archiwum `ASTEROIDY_v568_AUDYT_26_PLANET_STATKOW_BOSSOW_I_ZASOBOW.zip` potwierdzono:
- `PortingReferenceCode/v568/Windows/src/Carbonis277.cs`, wiersze 43–46 i 56–65: oryginalne `HeightMap[512*256]` oraz `SurfaceRadius(x,y,z)`;
- `PortingReferenceCode/v568/Windows/src/PlanetMesh.cs`, wiersz 193: `PlanetMesh.Height` odwołuje się do `Carbonis277.Get().SurfaceRadius`;
- `PortingResources/v568/Shared/assets/carbonis279.mesh.gz`: oryginalna, źródłowa mapa C279.

Źródłowy blok wysokości zawiera 524296 bajtów (nagłówek int32 512/256 i 131072 float32); SHA-256 `3ce9a0456d23a5b88de718e7fd8fe6560cb53cd112a31ecc876e6200a762cb39`.
Zestaw przygotowywany istniejącym `Tools/prepare_v568_carbonis_sector01.py` już zawiera `Sector01CarbonisHeightMap.dat`; nie wymyślono nowych danych terenu ani nie zmieniono mesh/UV/materiałów.

Dodano `ASTEROIDYiOS/CarbonisSurface277.swift`: dekoder oryginalnego bloku i identyczny algorytm biliniowy źródłowego `SurfaceRadius`, z zawijaniem długości geograficznej i domknięciem szerokości na biegunach.

Zmieniono `ASTEROIDYiOS/Sector01CarbonisPreview568.swift`: wejście do sceny musi potwierdzić również oryginalny SHA-256 mapy wysokości (szósty zasób) obok siatki i trzech tekstur.

Zmieniono `ASTEROIDYiOS/Sector01Scene568.swift`: inspektor źródłowej sceny faktycznie wywołuje odczyt mapy i pokazuje promień +X jako próbkę diagnostyczną, bez twierdzenia, że statek ma już działające kolizje.

## Testy i dowody

- Potwierdzony niezależny SHA-256 i geometria źródłowego zasobu z archiwum v568: **PASS**.
- Lokalny Swift/Linux `swiftc CarbonisSurface277.swift CarbonisSurface277Tests.swift` z rzeczywistą mapą 512×256: **27/27 PASS**. Zestaw sprawdza dziesięć punktów kontrolnych, niezmienność przy skalowaniu kierunku, oba bieguny, szew mapy i odrzucanie uszkodzonych danych.
- Źródłowe punkty odniesienia z rzeczywistego C279: +X=1.01041865, -X=1.01289284, +Y=1.01153946, -Y=1.00116193, +Z=1.01198179, -Z=1.01243085.
- Workflow `.github/workflows/verify-combat-only.yml` uzupełniono o przygotowanie dokładnego źródłowego C279, `sha256sum --check`, kompilację i uruchomienie Swift testów oraz kompilację Apple iOS bez IPA. `Tests/V568W3NativeMenuContract.py` pilnuje sha/natywnego podłączenia.
- **Końcowy wynik nowego GitHub Actions oraz interaktywny test iPhone/iPad: niepotwierdzone.** Lokalna kompilacja Swift/Linux nie stanowi potwierdzenia Xcode/Metal.

## Niewykonane i dalsza kolejność

- Oryginalne wykonanie `Game.Wave()` z v568 nie jest zawarte w dostępnym wycinku źródeł; nie zastępowano go wymyśloną falą. Kod `SphereSector556` to osobny istniejący testowy sektor, nie autentyczna grywalna misja CARBONIS.
- Brakuje użycia odczytu wysokości w symulacji ruchu statku/kolizji, prawdziwej grywalnej sceny misji, strzelania, przeciwników, zwycięstwa/przegranej i intro.
- Następny etap: pozyskać pełne `Game.Wave()` i zależności ze źródeł v568, podłączyć właściwą pętlę gry, następnie zastosować `CarbonisSurface277` do ruchu i kontaktu z terenem w tych samych jednostkach co oryginał, bez używania diagnostycznej planety Boreas zamiast Carbonis.
- Nie zmieniano mechanizmów walki/kolizji zadań 7/8, zapisu kampanii ani blokad 26 sektorów.
- Żadnego nowego IPA ani kompilacji IPA nie zlecano.

## Postęp

Całość **29% wykonane, 71% pozostało** (bez zmiany). Zadanie 12 **8% (0 pp)** do czasu potwierdzenia w pełnym runtime; samo próbkowanie nie jest działającą kolizją statku.
