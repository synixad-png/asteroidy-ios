# CARBONIS 01 — korekta kadrowania planety i poświaty na iPadzie (07.11.2026)

## Zgłoszenie
Na iPhonie w misjach CARBONIS planeta wyświetla się poprawnie. Na iPadzie 4:3 zajmuje za dużo miejsca, a poświata jest obcięta. Zgłoszenie dotyczy wyłącznie kadrowania gry na dwóch proporcjach ekranu.

## Zweryfikowana przyczyna i źródła
- Oryginał Windows v568: `Windows/src/GpuIntro41.cs:455` stosuje `frustum(-.35555556,.35555556,-.2,.2,.4,1600)` w obrazie 1280×720 (16:9).
- `Windows/src/GpuSphere67.cs:420` korzysta z tej samej funkcji `IntroProjection()` podczas aktywnej misji sferycznej. Kamera ma źródłowe 310 jednostek (`GpuSphere67.cs:414`).
- W porcie iOS `Sector01CarbonisPreview568.swift:viewProjection` dotąd było `x=2/aspect, y=2`; na iPadzie 4:3 dawało to `x=1.5` zamiast źródłowego `x=1.125`, czyli o 33% większy obraz poziomo przy tym samym rozmiarze viewportu.
- Poświata `SourcePlanetAtmosphere568.atmosphere` korzysta w gameplay z tej samej `viewProjection` co źródłowa powierzchnia planety; nie wolno korygować jej oddzielnym, arbitralnym skalowaniem.

## Wdrożenie
- `ASTEROIDYiOS/MissionViewportFraming568.swift`: źródłowy aspekt 1280/720 i projekcja `vertical=sourceVerticalFocal*min(1,currentAspect/sourceAspect)`, `horizontal=vertical/currentAspect`.
- `ASTEROIDYiOS/Sector01CarbonisPreview568.swift`: metoda `viewProjection` używa tych dwóch współczynników z aktualnego `MTKView.drawableSize`. Dotychczasowa projekcja `previewMVP` pozostaje nietknięta.
- iPhone ≥16:9: `vertical=2.0` (bez zmiany dotychczasowego FOV), `horizontal=2/aspect`.
- iPad 4:3: `vertical=1.5` zamiast 2.0, `horizontal=1.125` zamiast 1.5. Poświata Atmosphere47 i teren C279 podlegają jednakowej projekcji.
- Zachowano pierwotną kamerę, world scale `MissionPlanetScale523`, źródłową geometrię, materiały, UV, fizykę, eksplozje, hitboxy i sterowanie.

## Testy i wydanie
- `Tests/MissionViewportFraming568Tests.swift`: aspekt 16:9/4:3/19.5:9, granice projekcji, porównanie widocznej części poświaty z rzeczywistą odległością kamery, przypadki graniczne.
- `Tests/MissionViewportFraming568Contract.py`: wspólna projekcja planety i poświaty, niezmieniony atlas, brak modyfikacji geometrycznej.
- [GitHub Actions 42360663465](https://github.com/synixad-png/asteroidy-ios/actions/runs/42360663465): wszystkie cztery zadania SUCCESS, w tym Swift/Linux testy, źródłowe regresje, kompilacja Apple Xcode 16.4 i ARM64 iPhone/iPad.
- Commit wydania: `c3627bc03014677fb8e37ae259d758fe7bec4e42`.
- [IPA artefakt 13569324989](https://github.com/synixad-png/asteroidy-ios/actions/runs/42360663465/artifacts/13569324989): `ASTEROIDY_iOS_UNSIGNED.ipa`, 28 341 137 bajtów, SHA256 `1cffc3a63199e72bf75fe2edb3ad3d617cef967b40d6e65121ea7ef1b44450bd`; CRC obu ZIP-ów PASS, Info.plist `UIDeviceFamily=[1,2]`, min iOS17, ARM64 Mach-O, com.synixad.asteroidyios.

## Ograniczenia
Nie testowano wizualnie nowego obrazu na fizycznym iPadzie; matematyczne weryfikacje i kompilacja nie są potwierdzeniem wyglądu na urządzeniu. IPA jest niepodpisane i wymaga podpisania przed instalacją. Test potwierdzający zgłoszoną poprawkę i ewentualne dalsze dostosowanie wymaga autentycznego zrzutu bądź testu użytkownika z nowej wersji.

Harmonogram 18 zadań pozostaje bez zmiany; 38% portu, 62% do końca, zadanie 14 24% (zmiana 0 pp).
