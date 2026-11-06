# ASTEROIDY iOS — oryginalne zasoby Vanguard431

> **Aktualizacja 06.11.2026 — INTEGRACJA POTWIERDZONA.** Użytkownik przesłał obie dokładne binarki bezpośrednio do `ASTEROIDYiOS/Assets/`, a ich rzeczywista zawartość w skompilowanej na Apple aplikacji ARM64 przeszła kontrolę SHA-256 i struktury. **Poniższe stwierdzenia z 05.11 o braku plików w GitHubie są już wyłącznie historycznym raportem poprzedniego etapu.**


## Co jest w kodzie GitHub
- `ASTEROIDYiOS/SourceVanguardMesh431.swift` odczytuje format 4311 oryginalnego `Windows/src/Vanguard431.cs` — dwa silniki, osobne trójkąty, 12 floatów na wierzchołek (**pozycja 3, normalna 3, RGBA 4, UV 2**) i oryginalny CPU trailer.
- `Ship.metal`: `sourceVanguardVertex431` odczytuje wprost źródłowy strumień 194 427 wierzchołków w pamięci GPU `device`, a `sourceVanguardTexturedToonFragment431` pobiera prawdziwy glTF BaseColor JPEG z oryginalnych UV, bez przebudowy siatki i bez V-flip. Stosuje zweryfikowane światło i pasma `GpuToon60`.
- `MetalRenderer.swift` wybiera tę ścieżkę **tylko jeśli istnieją obie autentyczne binarki**, sprawdza ich SHA256 przez CryptoKit i zachowuje poprzedni `Vanguard556.as3d` fallback bez modyfikacji trybu walki i planety.
- `Tools/import_original_vanguard431.py` bez internetu wyodrębnia obie binarki z rzeczywistego ZIP kodu ASTEROIDY PC v568 i sprawdza je porównując oryginalny GLB, runtime skin, metadata i SHA256.
- `Tests/SourceVanguardMesh431Tests.swift` i `Tests/SourceVanguardTextureContract431.py` kontrolują format, skalę, teksturowanie i zachowanie wcześniejszej ścieżki.

## Źródło prawdziwych danych
Własne źródła użytkownika: `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`.
Rozpakowana siatka `Shared/assets/vanguard431/vanguard431.mesh.gz` (po gzip) ma **9 721 408 bajtów**, 194 427 trójkątnych wierzchołków / 64 809 trójkątów. `Shared/assets/vanguard431/vanguard431.base.jpg` ma **1 275 318 bajtów** i **2048×2048 pikseli**. Plik JPEG jest bajtowo identyczny z mapą BaseColor osadzoną w tym samym oryginalnym `Vanguard_551_SOURCE.glb`.

Oczekiwane ścieżki do późniejszej kompilacji:
```
ASTEROIDYiOS/Assets/Vanguard431Source.mesh
ASTEROIDYiOS/Assets/Vanguard431Base.jpg
```

`Vanguard431Source.mesh` — SHA256 `f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a`

`Vanguard431Base.jpg` — SHA256 `2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95`

Źródła można odtworzyć w czystym katalogu:
```bash
python3 Tools/import_original_vanguard431.py   Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip   ASTEROIDYiOS/Assets
```

## Uczciwy status
Kody nowego renderera, parsera i testów są w GitHub. Dla tej rewizji wykonano źródłowy CI PASS oraz natywną kompilację Xcode + Metal **PASS** dla iPhone/iPad ARM64 [GitHub Actions 42121018526](https://github.com/synixad-png/asteroidy-ios/actions/runs/42121018526).

**Dwie duże binarki nie zostały zapisane do repozytorium GitHub.** Ich dokładne oryginalne bajty są przygotowane w oddzielnej paczce zasobów w bieżącej rozmowie, ale dopóki binarki nie zostaną dodane do `ASTEROIDYiOS/Assets`, kolejny build użyje starej ścieżki AS3D. Nie wolno mówić, że nowy IPA ma oryginalną teksturę, ani generować IPA dla samych zmian kodu, które pozostają niewidoczne.

Nadal brak: interaktywnych testów GPU na prawdziwym iPhonie/iPadzie, porównania obrazu 1:1, pełnych oryginalnych ustawień materiałów (m.in. normal map i metallic/roughness) oraz kompletnej kampanii. Kolejnym krokiem zadania 2 jest dostarczenie autentycznych binarek do repozytorium, a dopiero potem zbudowanie i zweryfikowanie teksturowanego wydania.

## Aktualizacja 05.11.2026 — zgodność rzeczywistego samplera OpenGL i bezpieczna publikacja

Na podstawie rzeczywistego `Windows/src/GpuRenderer.cs:144–146` oryginał używa `glTexParameteri(GL_TEXTURE_WRAP_S/T, GL_CLAMP_TO_EDGE)`, `GL_TEXTURE_MIN_FILTER=GL_LINEAR`, `GL_TEXTURE_MAG_FILTER=GL_LINEAR`, obrazu `GL_RGBA8` przesyłanego z bajtów `GL_BGRA`. **Nie** włącza mipmap ani automatycznego dekodowania sRGB do liniowej przestrzeni shaderów. Poprzednia próba iOS z `address::repeat`, `.SRGB:true` i `.generateMipmaps:true` stanowiła realną rozbieżność; poprawiono ją na:

- `Ship.metal`: `constexpr sampler sourceUV(address::clamp_to_edge,filter::linear)` — bez mip-filter;
- `MetalRenderer.swift`: `.SRGB:false`, `.generateMipmaps:false`, `.origin:MTKTextureLoader.Origin.topLeft` — bez odwracania UV.

Nie zmieniono oryginalnych bajtów modelu ani JPEG.

**Nowy tryb wydania:** zwykły `.github/workflows/build-ios-iphone-ipad-manual.yml` automatycznie sprawdza, czy w repozytorium znajduje się kompaktowa autentyczna paczka `AssetsCompressed/Vanguard431_ORYGINALNE_UV_TEKSTURA_ZASOBY.zip`; jeżeli tak, `Tools/prepare_vanguard431_assets.py` wyodrębnia **tylko dwa dokładnie nazwane oryginalne pliki**. `Tools/verify_original_vanguard_resources.py` weryfikuje pełne SHA256, 4311/194427 GPU wierzchołków, 10802 CPU trójkątów oraz 2048×2048 JPEG **przed budową**. Po spakowaniu aplikacji `Tools/verify_ipa.py ... --require-vanguard-original` ponawia kontrolę rzeczywistej zawartości IPA. Nie da się przypadkowo wydać nowego teksturowanego IPA opartego wyłącznie na starym AS3D. Wyjątek `compatibility_old_ship=true` w ręcznym workflow musi być wybrany świadomie i jest opisany jako wydanie ze starym modelem.

**Przetestowano:** oryginalny ZIP z tej rozmowy rzeczywiście przechodzi CRC, SHA256 obu plików, strukturę GPU/CPU i ekstrakcję do tymczasowego katalogu bez modyfikacji bajtów. W GitHub Actions [42125357275](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125357275) Swift/Linux + nowe testy odrzucania uszkodzonych/podmienionych zasobów **SUCCESS**; [42125348782](https://github.com/synixad-png/asteroidy-ios/actions/runs/42125348782) kontrola źródeł i składni **SUCCESS**. Natywny Apple Swift+Metal [42124960734](https://github.com/synixad-png/asteroidy-ios/actions/runs/42124960734) **SUCCESS** dla zmienionego samplera i obu urządzeń ARM64; kolejne zmiany dotyczą wyłącznie skryptów i procesu wydawania.

**Granica wdrożenia:** nadal **nie** przeniesiono tej 3,53 MB paczki binarnej do repozytorium GitHub — sprawdzone pliki pozostają w rozmowie, a GitHub ma importer i zabezpieczenie wydania. Dopóki paczka nie znajdzie się w `AssetsCompressed` albo para oryginalnych plików bezpośrednio w `ASTEROIDYiOS/Assets`, nowy standardowy build teksturowanego IPA ma **zakończyć się błędem świadomie**, zamiast wygenerować aplikację bez obiecanej tekstury. Nie wygenerowano IPA i nie testowano tych zasobów na fizycznym iPhonie/iPadzie.

## 06.11.2026 — obie oryginalne binarki są w GitHubie i w rzeczywistym pliku .app

**Aktualny stan, nadpisujący historyczną informację z 05.11:**
- `ASTEROIDYiOS/Assets/Vanguard431Source.mesh` — **9 721 408 bajtów**, Git SHA-1 `4f56d1b6d08f8974407eff75eae93360ff1e8e7d`, SHA-256 `f5d6d0107437fa54c3e8505f9adfbf6143cc877cb970eef687603609e26f9f4a`;
- `ASTEROIDYiOS/Assets/Vanguard431Base.jpg` — **1 275 318 bajtów**, Git SHA-1 `4675b12c4d9c1d3f4e233488c1f97318e2c937ee`, SHA-256 `2945f711a6b559bfb5fdfb79750a2f2f77e2071aa5f3f4173eb450bce81b8b95`;
- Git SHA-1 obu blobów w bieżącym drzewie `main` dokładnie zgadza się z niezależnie sprawdzonymi oryginalnymi plikami użytkownika, bez podmiany na Git LFS/pointer;
- `Tests/OriginalVanguard431InstalledAssetsTests.py` testuje źródłowe binaria i 194 427 prawdziwych pozycji, normalnych, RGBA oraz UV, oryginalny zakres modelu i lokalizację obu dysz;
- `Tools/prepare_vanguard431_assets.py` sprawdza teraz istniejącą parę w `Assets` i **nie wymaga dodatkowego ZIP**; gdy jest tylko jeden plik — kończy się błędem, zamiast ukrywać brak i włączać stary model;
- `Tools/verify_compiled_vanguard431_app.py` sprawdza zasoby wewnątrz rzeczywistej skompilowanej aplikacji, docelową architekturę iPhone+iPad ARM64, iOS 17+ oraz `default.metallib`.

**Wyniki bieżących testów:**
- [GitHub Actions 42168920268](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920268) — **SUCCESS** Swift/Linux, w tym zabezpieczenia starego modelu oraz nowy pozytywny test prawdziwych zasobów;
- [GitHub Actions 42168920269](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168920269) — **SUCCESS** preflight zasobów i źródeł iOS;
- [GitHub Actions 42168975848](https://github.com/synixad-png/asteroidy-ios/actions/runs/42168975848) — **SUCCESS** natywna kompilacja `Release` Swift+Metal pod iPhone+iPad ARM64. W końcowej kontroli **obydwa oryginalne zasoby zostały znalezione w rzeczywistym `.app`**, ponownie odczytane i zweryfikowane bajtowo. Wykryto także natywny Mach-O ARM64, `UIDeviceFamily={1,2}` i zbudowane `default.metallib`. Build nie wytworzył IPA.

**Granica weryfikacji:** skoro źródła są dołączone do `.app`, a dotychczasowy `MetalRenderer.swift` wybiera oryginalną teksturowaną siatkę, gdy oba pliki przejdą wewnętrzny test CryptoKit SHA-256, to nowy renderer jest przygotowany do użycia **prawdziwego modelu**. **Nie przeprowadzono testu uruchomienia na fizycznym iPhonie ani iPadzie**, nie porównano klatka po klatce wyglądu GPU z wersją Windows/SteamOS. Ostatni udostępniony IPA powstał przed tym uploadem i nadal pozostaje starszą wersją. Nowego IPA nie przygotowano bez polecenia użytkownika.
