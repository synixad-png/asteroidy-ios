# ASTEROIDY v568 iOS — plazma silników i skala planety CARBONIS 01 (06.11.2026)

## Źródło
Oryginalne Windows v568: `GpuShip.cs` (v491, źródłowy strumień dwóch silników), `GpuSphere67.cs:368` (dla rzeczywistej walki `DrawFighterMesh(g.Time,Math.Max(.12, VisualPower298),0,false)`), `GpuSphere67.cs:420` (planeta misji `MissionPlanetScale523(100f)`), `GpuPlanetGltf463.cs:37-69` (rzeczywisty promień wierzchołków i niezależność planety głównej), `carbonis279.mesh.gz` (137067 unikatowych wierzchołków).
Obliczone bezpośrednio z oryginalnej siatki C279: promień maksymalny 1.09607509146; mission scale 100*1.4419674/1.09607509146 = 131.55735508 w jednostkach PC; iOS already divides world by 144.19674, so effective mesh-only scale = 1/1.09607509146 = 0.91234625053.

## Wdrożenie
`Sector01CarbonisPreview568.swift`: normalizuj tylko siatkę terenu w rzeczywistym gameplay CARBONIS 01; pozostaw NewHome290 i statki/asteroidy nietknięte. Powiąż pipeline additive Metal Ship.metal v491 z oryginalnym modelem Vanguard431, oryginalnymi punktami montażu, tą samą macierzą modelu, animacją oraz płynnie wyznaczoną mocą 0.12..1.
`CarbonisMissionPlanet523.swift`: raz wyznacz promień z dokładnie tych samych weryfikowanych SHA256 źródłowych pozycji XYZ, które trafiają do GPU.
Nie dodano żadnych arbitralnych ustawień silników — w zweryfikowanej części oryginalnego kodu brak osobnego potwierdzonego suwaka.

## Testy / pozostałe
Linux Swift source radius/negative cases PASS. Dalsze bramki: pełna regresja Swift, kompilacja natywna Xcode/Metal na Apple runnerze, oryginalne zasoby w .app, konstrukcja i integralność unsigned IPA, rzeczywisty wizualny test na fizycznym urządzeniu NIE przeprowadzony. `PORT_STATUS_18_TASKS.md` utrzymuje 18 zadań i 38% bez zmiany.

## Wynik wydania

- GitHub Actions: [42289576566](https://github.com/synixad-png/asteroidy-ios/actions/runs/42289576566) — SUCCESS (Linux regresja + macOS Xcode Swift/Metal Release, arm64).
- Artefakt: [13539047406](https://github.com/synixad-png/asteroidy-ios/actions/runs/42289576566/artifacts/13539047406); IPA 27 059 072 B, SHA-256 `b870ee6ef43c3c5e719fcd176d23fc0990f227aa07a5a059649faf662a91fad4`.
- Sprawdzenia lokalne po pobraniu: ZIP artefaktu CRC PASS; ZIP wewnętrznego IPA CRC PASS; `CFBundleExecutable=ASTEROIDY iOS` (Mach-O arm64); UIDeviceFamily [1,2], `iPhoneOS`; `default.metallib`, oryginalne siatki Vanguard/C279 obecne. W oryginalnym C279 137 067 pozycji z `carbonis279.mesh.gz` test promienia/normalizacji PASS.
- Nadal NIE przeprowadzono instalacji, uruchomienia ani wizualnej weryfikacji na fizycznym iPhone/iPad. IPA niepodpisany.
