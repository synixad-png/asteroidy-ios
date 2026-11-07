# ASTEROIDY v568 iOS — zweryfikowany audyt efektów planet i menu (07.11.2026)

**Źródło pierwotne:** rzeczywiste pliki `Windows/src/*.cs` w `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip` dostarczonym we wcześniejszym etapie. Poniższa tabela rozdziela efekty faktycznie wprowadzone do aktualnej gry iOS od oryginalnych funkcji PC, których sceny nie zostały jeszcze przeniesione. Nie zastępujemy brakujących mechanizmów własnymi odpowiednikami.

| Oryginalny efekt | Pliki/identyfikatory źródła v568 | Zastosowanie oryginału | Stan w tym wydaniu iOS |
|---|---|---|---|
| Kolorowy pierścień poświaty przy planecie | `GpuPlanetAnimation.cs:GlowVertex/DrawPlanetGlow`; `GpuPlanet.cs:104`; menu **#2 GLOW** | Podgląd planety | Wdrożony wcześniej w Metal/CARBONIS |
| Półprzezroczysta kopuła atmosfery | `GpuPlanet.cs:DrawAtmosphereFast136/Atmosphere47` | Podgląd i render planety | Wdrożona wcześniej w Metal/CARBONIS |
| Ruchomy terminator dnia/nocy | `GpuToon60.cs:199–204`, `GpuPlanet.cs:108`; menu **#55/#56/#57** | Powierzchnia planety; słońce, prędkość i jasność nocy | Wdrożony wcześniej dla CARBONIS; aktywne suwaki, z częściową zgodnością PBR |
| Emisja wulkaniczna i poświata lawy | `GpuPlanet.cs:CarbonisCombined469 (170–224)`, `GpuToon60.cs:SetHomeLavaShader293 (285–290)`, `GpuNewHome290.cs:34–50`; menu **#45** | Emisja CARBONIS, lava-gLOW NewHome, inne planety z materiałem lawowym | **TERAZ WDROŻONE:** CARBONIS C279 i NewHome290, 0–400% co 5%, domyślne 180%, trwały zapis ustawienia |
| Bazaltowe kratery i świecące kratery | `GpuToon60.cs:SetBasalt110`, `LavaMesh116.cs`, `GpuLava116.cs:9–24` | Tylko planety z generowanym `Basalt110` | Nieprzeniesione — CARBONIS nie używa `LavaMesh116` |
| Lawa w osobnych grupach VULKARIS | `GpuPlanet.cs:DrawVulkaris276` grupa 5 | VULKARIS, dodatkowy addytywny pass na oryginalnej siatce | Nieprzeniesione — brak osobnej grywalnej sceny VULKARIS w iOS |
| Woda i animacja powierzchni | `GpuToon60.cs:BeginWater65`, `GpuPlanet.cs:DrawPlanetSolid` | Planety proceduralne, zależne od materiału | Nieprzeniesione do CARBONIS, który nie ma tej osobnej warstwy wody |
| Animowana pogoda / chmury | `GpuWeather65.cs:DrawWeather65` | Tylko proceduralne bez `Carbonis277`, `Vulkaris276` i zastępczego GLB w podglądzie `GpuPlanet.cs:108` | Nieprzeniesione; nie wolno dodawać ich do CARBONIS |
| Fauna, pełzacze, serpentyny | `GpuPlanetAnimation.cs:DrawPlanetCrawler`, `GpuPlanetSerpents.cs` | Podgląd proceduralnych planet | Nieprzeniesione; oddzielna oryginalna geometria/animacje |
| Wreck/badawcze ruiny misji | `GpuPlanet.cs:DrawLevelResearchWreck210` | Geometryczny dodatek do poziomu | Nieprzeniesione, ponieważ brak ich źródłowych assetów/transformacji w aktualnej scenie |
| Animacje zastępczych planet GLB | `GpuPlanetGltf463.cs:DrawReplacedPlanet463` i `H55Renderer.cs` | Planety z własną geometrią/animacją GLB | Jedynie istniejąca częściowa scena Boreas; brak pełnego portu tych efektów na wszystkie planety |
| GLB / chropowatość i światło otoczenia | `Menu139.cs` **#88/#89**, `H55Renderer.cs:509` | Tylko importowane planety GLB; domyślne **20% / 40%** | Nie wdrażano fikcyjnych suwaków; pełny materiał źródłowy PBR/IBL musi zostać przeniesiony |
| FERROFLUID / jasność, odbicia, kontrast | `Menu139.cs` **#85/#86/#87**, `H55Renderer.cs` | Tylko specjalny materiał FERROFLUID; domyślne **38% / 65% / 65%** | Nie wdrażano fikcyjnych suwaków, brak właściwej sceny FERROFLUID |
| Świetliki nocne | `GpuSphere67.cs:DrawPlanetFireflies438`, `Menu139.cs` **#58/#59** | Nocna półkula | **ŚWIADOMIE WYŁĄCZONE Z ZAKRESU** na polecenie użytkownika |
| Wspólne Bloom/SSAO i inne postprocesy | `Menu139.cs` **#19–39**, `GpuHubPost103.cs` | Wspólna grafika / wybrane sceny, nie indywidualny materiał każdej planety | Nie przypisywać sztucznie do CARBONIS; wymagają portu wspólnego systemu efektów |

## Sprawdzone równania lawy z oryginału

- **C279 CARBONIS:** `heat=max(emissive.r,g,b)`; `mask=smoothstep(.12,.46,heat)`; `strength=clamp(LavaLightBrightness287/100,0,4)`; `irradiation=min(1,strength*.45)`. Ostateczna mieszanka `base + emissive*strength*mask*(1,.8,.5) + irradiance*irradiation*.38` jest obcinana do zakresu 0–1, a następnie przechodzi przez oświetlenie planety. To jedna nieprzezroczysta warstwa, bez migoczących kopii tych samych trójkątów.
- **NewHome290:** dokładny zmapowany wcześniej `GpuToon60.cs` shader lava-glow korzysta teraz z `glowPower=strength` zamiast stałej wartości 1.8.
- **Ustawienia:** prawdziwy numer Menu139 **#45**, nazwa `JASNOŚĆ EMISJI LAWY`, skala 0–400% krok 5, domyślnie 180%, zapisywana niezależnie od wcześniej istniejącego profilu PLANETY, więc aktualizacja nie usuwa wcześniejszych ustawień słońca i poświaty.
- **Nie zmieniano:** geometrii ani tekstur źródłowych, kolizji, fizyki, strzelania, modeli wrogów, pocisków, Explosion524 (poza wcześniejszą zweryfikowaną optymalizacją), muzyki syntetyzowanej przy starcie.

## Dowody i ograniczenia

- PR #1 `https://github.com/synixad-png/asteroidy-ios/pull/1` został po zielonej kompilacji Metal włączony do `main`. Algorytm zachowuje 17 źródłowych kłębów i unika próbek, dla których oryginalny `smoothstep` daje zerową przezroczystość. Nie ma pomiaru FPS na fizycznym iPhonie.
- Jednostkowe testy `SourceLavaLightSettings287Tests.swift` i źródłowy kontrakt `SourceLavaLight287SourceContract.py` wymagane w CI. Kompilacja Apple Metal + Xcode oraz spójność zasobów są weryfikowane przez GitHub Actions.
- Gra nie jest pełnym portem 26 planet PC; rozdział `C279`, `NewHome290`, `VULKARIS`, `FERROFLUID` i proceduralnych planet jest celowy. Brak realistycznego testu wizualnego na fizycznym iPadzie/iPhonie, więc nie deklarujemy identycznego wyglądu.
