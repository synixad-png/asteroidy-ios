# ASTEROIDY iOS — źródłowe zasoby Vanguard431, stan 05.11.2026

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
