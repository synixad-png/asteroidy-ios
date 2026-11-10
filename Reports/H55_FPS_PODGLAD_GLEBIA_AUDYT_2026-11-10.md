# ASTEROIDY iOS — H55: podgląd rękawic i broni, migotanie (10.11.2026)

## Zweryfikowane źródła

Archiwum PC v600 (zawierające kod PC v580):
- `Windows/src/GpuGloves417.cs` **RenderGlovesReal424** — rzeczywisty podgląd modelu w zakładce RĘKAWICE, 16:9, samodzielny bufor głębi, włączony `DEPTH`, wszystkie oryginalne trójkąty GLB.
- `Windows/src/GpuWeapon470.cs` **RenderWeaponPreview470** — podgląd EXP-01 w BROŃ, oryginalny transform broni, FOV 64°, neutralne oświetlenie, tryb ruchu; **RenderWeapon470** renderuje po świecie z oddzielnie wyczyszczoną głębią.
- `Windows/src/GpuGlovesProxy421.cs`: oryginalny prostokąt podglądu **352×198**.
- `Windows/src/GlovesSettings417.cs`, `WeaponViewSettings470.cs`: osobne ustawienia obu rąk i broni.
- Prawdziwe `SourceResources/PC586` w GitHub: `gloves_parted.glb` (4 968 356 B, SHA256 `8a494bbd9a3dd6eb70cb5e22a7db4da7ec33b069dc1b0bab36f6a1c5b4c257ca`), `gloves_combined.glb` (4 144 252 B, SHA256 `643bfa2799535852362103fa4d24b84d712637d686e773403214400a31ae4516`), `EXP01_SOURCE_v601.glb` (4 504 600 B, SHA256 `07403302f23cb81ce6c26501ca7361c646550c6f91e0a949ce81566553139762`).

## Potwierdzone rozbieżności starego portu iOS

1. `H55FPSSettingsSection580.swift` miał wybór GLB i suwaki, **nie miał żadnego SceneKit podglądu**; użytkownik nie mógł zobaczyć korekt przed powrotem do hangaru.
2. `H55FPSScene580.protectMaterials` wymuszało `readsFromDepthBuffer=false`, `writesToDepthBuffer=false`, `isDoubleSided=true` **na każdym** materiale. PC renderował viewmodel z `DEPTH` w osobnym przebiegu. W oryginalnym GLB: TRIPO ma 1 dwustronny materiał OPAQUE, MONOLIT 1 jednostronny materiał OPAQUE, EXP-01 19 jednostronnych OPAQUE oraz **6 dwustronnych przezroczystych naklejek BLEND**. Jednolita zmiana właściwości materiałów nie odpowiada oryginałowi i może powodować nieprawidłowe przekrywanie powierzchni.
3. Renderowanie rękawic wewnątrz hangarowej sceny uniemożliwiało równocześnie uzyskanie poprawnej niezależnej głębi viewmodelu i poprawnej głębi świata.

## Wprowadzone zmiany

- `H55FPSOverlayViewport580.swift`: osobna przezroczysta warstwa SceneKit z własną głębią, nad istniejącym renderowaniem świata, pod dotykowym HUD-em; gra i kolizje zachowane.
- `H55ScenePage580.swift`: osobna scena + kamera FPS; prawdziwe modele nie są już podpięte do drzewa świata. Obie ścieżki `close/reload` zwalniają FPS viewmodel i overlay.
- `H55FPSScene580.swift`: przywrócono prawdziwe testowanie głębi, zapisywanie głębi dla nieprzezroczystych części, brak zapisywania dla 6 oryginalnych naklejek EXP-01, bez wymuszania dwustronności. Ten sam importer GLTFKit2, splitter geometrii i oryginalne transformacje wykorzystywane w podglądzie.
- `H55FPSPreview580.swift`: **prawdziwy** `SCNView` wewnątrz USTAWIENIA → RĘKAWICE / BROŃ, oryginalny 352×198/16:9, kalibracja na bieżąco i symulacja postoju/chodu/biegu. Modele i tekstury nie są generowane zastępczo.
- `H55FPSLighting580.swift`: jedno źródło położeń świateł odpowiadające źródłowym trzem pozycjom i relacjom RGB z PC; intensywność dobrana do SceneKit, **nie deklarujemy identyczności z GLSL na PC**.
- `Tests/H55FPSOriginalMaterial580Tests.py` i `Tests/H55FPSPreviewDepth580Contract.py`: rzeczywisty 15-elementowy manifest źródeł, rodzaje materiałów GLB, osobne bufory głębi, prawdziwe okno podglądu, zgodne zakładki, brak geometrii zamiennej.

## Wyniki testów i ograniczenia

- Źródłowa bramka H55 FPS: **PASS** — GitHub Actions `42849699602`.
- Audyt No Slop: **PASS** — GitHub Actions `42850009029`.
- Pełna kompilacja iOS ARM64 z poprawkami jest **w toku / w kolejce**: `42848216424` (wcześniejszy punkt kodu) i `42849227513` (poprawki po weryfikacji źródeł).
- **Nie wykonano interaktywnego testu GPU na iPhonie / iPadzie**: wskazane rozbieżności były rzeczywiste, ale samo ich usunięcie nie dowodzi bez reszty braku migotania w czasie gry.
- Poprzednie IPA v600 **nie zawiera tych poprawek**. Nie należy go przedstawiać jako wydania naprawczego. Nowy IPA wolno udostępnić dopiero po pomyślnym buildzie Xcode i weryfikacji wszystkich zasobów.
