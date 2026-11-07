# ASTEROIDY iOS v568 — natywny W3 4:3 i rzeczywisty licznik FPS
Data: 2026-11-07

## Dlaczego poprzedni ekran iPada był niespójny
W `ASTEROIDYiOS/W3StartupSplash568.swift` źródłowe W3 było rysowane jako sztywna plansza 1280×720 i składane do środka przez `fit=min(width/1280,height/720)`. iPad 4:3 pozostawiał pionowe marginesy: górny pasek zsuwał się poniżej fizycznej krawędzi. To była usterka layoutu natywnego portu, a nie element gry Windows.

## Poprawka geometrii interfejsu
- Nowy czysty komponent `W3AdaptiveViewport568.swift`, zachowujący oryginalny nagłówek 74px i stopkę 68px na pełnym ekranie, odpowiednio 52/37px na iPhonie w kompaktowym krajobrazie.
- W `W3StartupSplash568.swift` usunięto `sourcePage.scaleEffect(fit)`; zamiast tego `sourceHeader(layout)` zajmuje rzeczywiste y=0, `sourceFooter(layout)` kończy się w rzeczywistym y=height, a logo/napis/prompty są umieszczone w środkowej części bez zniekształcania proporcji.
- Na iPadzie 1024×768: header y=0..74, stopka y=700..768; zamiast centrowanej planszy z pustym pasem 96 px w pionie. Obszar pod spodem jest rysowany oryginalnym współdzielonym tłem W3.
- `W3MainMenu568.swift`: `.ignoresSafeArea()`, prawidłowa stopka 68px w szerokim układzie, zasłona źródłowego przejścia wyliczana w odniesieniu do tych samych krawędzi.
- Bez zmiany źródłowych obrazów/logo, GPU siatki planety NewHome290, kontrolera dotykowego, CARBONIS, audio i zapisów.
- Testy `Tests/W3AdaptiveViewport568Tests.swift` sprawdzają 1280×720, 1024×768, 1194×834, 844×390, 932×430; `Tests/W3AdaptiveViewportContract568.py` sprawdza źródłowe podpięcie.

## Licznik FPS na podstawie Windows v568
Oryginalne potwierdzone miejsca:
- `Windows/src/Menu139.cs:33`: `OptionLabels228[6] = "Licznik wydajności"`.
- `Windows/src/Menu139.cs:323`: `ShowPerformance=false` przy ustawieniach domyślnych.
- `Windows/src/Controls.cs:12,16`: `POMIAR FPS`, domyślny kod klawisza 114 = R.
- `Windows/src/GpuRenderer.cs:202` i `Renderer.cs:200`: FPS jest obliczany w oknach **0,5 sekundy**, wyświetlany razem z milisekundami klatki.
- `Renderer.cs:200`: ukryty na zwykłym ekranie W3 MENU i SHOP, podczas grania ma widoczny odczyt.
W iOS:
- `SourceFPSAccumulator568.swift`: liczba faktycznie zakończonych klatek podzielona przez rzeczywisty monotoniczny przedział, aktualizacja co ≥0,5 s; średnie GPU-ms z `MTLCommandBuffer.gpuStartTime/gpuEndTime` jeśli dostępne, inaczej czas interwału/klatkę.
- `SourcePerformance568.swift`: współdzielony obiekt stanu, persist `UserDefaults`, włączenie/wyłączenie, natywny overlay `Metal GPU · N FPS · X ms`; `addCompletedHandler` tylko przy włączonym pomiarze; tylko bufor ukończony `.completed`.
- `Sector01CarbonisPreview568.swift` i `MetalRenderer.swift`: pomiar rzeczywistych `MTLCommandBuffer`; bez zmiany kolejności draw-call, fizyki czy klatkażu gry.
- `Sector01Scene568.swift`: wyświetlanie tylko podczas fazy `.playing`, nie na ekranach raportów.
- `App.swift`: pomiar w scenie diagnostycznej; nigdy w W3 HOME i startupie.
- `CarbonisVisualSettingsPanel568.swift`: przełącznik w oryginalnej kategorii `GRAFIKA` jako ID 6; default off; zapis automatyczny.
- Oryginalny skrót R na sprzętowej klawiaturze jest udokumentowany, lecz nie wdrożony do portu. Wymaga osobnego źródłowego odwzorowania wejścia klawiatury.

## Potwierdzenie IPA
- [GitHub Actions 42366042540](https://github.com/synixad-png/asteroidy-ios/actions/runs/42366042540): wszystkie jobs SUCCESS, w tym Xcode 16.4 iPhoneOS ARM64, źródłowe testy viewport/FPS i pełna regresja.
- Dokładny commit kompilacji `37bfaa58737401b0f21d6edf288b1a0145166269`.
- [Artefakt 13571697864](https://github.com/synixad-png/asteroidy-ios/actions/runs/42366042540/artifacts/13571697864).
- `ASTEROIDY_iOS_UNSIGNED.ipa`: 28 405 298 bajtów, SHA-256 `2237a68516ea458bf63dda230be7c6d116717542df11c3efc8979d6e357bec33`, zgodne z `reports/SHA256SUMS.txt`; integralność CRC ZIP i wewnętrznego IPA PASS.
- `Info.plist`: `com.synixad.asteroidyios`, `UIDeviceFamily [1,2]`, iOS 17.0, Mach-O ARM64.
- IPA jest niepodpisane. Instalacja, zrzut ekranu i ręczne porównanie na fizycznym iPadzie/iPhonie nie zostały przeprowadzone. Nie należy twierdzić, że układ fizycznego iPada został potwierdzony zdjęciem.
- Oddzielny simctl screenshot na starym commicie: [run 42365812537](https://github.com/synixad-png/asteroidy-ios/actions/runs/42365812537). Nie zastępuje rzeczywistego ręcznego testu.

## Nienaruszone mechanizmy i dalszy zakres
Pierwszy CARBONIS C279, oryginalne zasoby W3, poprawka przezroczystej planety, źródłowe sterowanie dotykiem, atmosfera/poświata, źródłowy generator muzyki, zapis profilu i 18-zadaniowy harmonogram pozostają. Cały port nadal ma 38% / 62% pozostało; zadanie 14 ma 26% (+1 pp). Następny krok: potwierdzić na iPadzie 4:3 paski, logo, dotknięcie Enter i wskazanie FPS po włączeniu GRAFIKA; bez wymyślania niezaimplementowanych ekranów ani funkcji.
