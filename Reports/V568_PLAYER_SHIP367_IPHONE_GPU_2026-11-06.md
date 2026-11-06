# ASTEROIDY iOS — rzeczywisty PlayerShip367, v568, symulator iPhone

Data: 2026-11-06. Baza oryginału: `Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip`.

## Zakończony test

[GitHub Actions / run 42187435379](https://github.com/synixad-png/asteroidy-ios/actions/runs/42187435379)
— **PASS**, Apple **iPhone 16 Simulator**, bez IPA.

Artefakt: `ASTEROIDY-original-v568-PlayerShip367-real-iPhone-GPU-proof-NO-IPA`
(ID `13487988131`, zapisany przez GitHub Actions). Zawiera
`IPHONE_VERIFIED_ASTEROIDY_source367.png`, `IPHONE_GPU_source367_proof.json`,
wyniki sprawdzenia faktycznych pikseli i dziennik Xcode. **Nie zastępować
autentycznego zrzutu zdjęciem obcej gry lub wizualizacją koncepcyjną.**

```json
{
  "evidence": "actual-source-playership367-metal-command-buffer",
  "gpuCommandBufferCompleted": true,
  "pipeline": "sourceFighterTexturedPipeline431",
  "vertexCount": 599997,
  "textureWidth": 2048,
  "textureHeight": 2048,
  "sourceGPU_SHA256": "932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a",
  "skinSHA256": "9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111",
  "bundleID": "com.synixad.asteroidyios",
  "simulatorTestOnly": true
}
```

Dowód powstał w `MetalRenderer.swift` *po zgłoszeniu faktycznej komendy
drawPrimitives*, w ukończonym buforze Metal. Test usunął stare potwierdzenia
i poprzednie obrazy przed uruchomieniem, zweryfikował zawartość bieżącego
pliku JSON, rzeczywisty obraz `simctl io ... screenshot` i jego piksele.
Obraz miał rozmiar **1179×2556 pikseli**, 308 różnych skwantyzowanych
kolorów w sprawdzanym regionie centralnym. Oryginalny czerwony model
jest widoczny w pobranym zrzucie.

## Ważne ograniczenia

- To prawdziwe rysowanie na **symulatorze iPhone**, nie test na fizycznym
  urządzeniu ani w symulatorze iPad.
- Dowód wykonania GPU i niepustego obrazu **nie potwierdza** dokładnego
  wymiarowania, cieni, pełnego PBR, animacji lub zgodności 1:1 z Windows v568.
- Scena Boreas jest nadal diagnostyczna i oparta częściowo na starszym
  porcie v556; nie jest to pełna misja v568.
- Wybrany model nie podmienia domyślnego Vanguard. Włączenie wymaga
  przycisku w teście Boreas albo jawnej zmiennej środowiskowej
  `ASTEROIDY_SHIP367_VERIFY=1` tylko dla diagnostyki.
- Nie ma jeszcze portu wszystkich statków, 26 w pełni grywalnych sektorów,
  ani oryginalnego hangaru H55 (źródłowa paczka oznaczona `BEZ_HANGARU`).
- Obraz PNG zawiera pionowy zapis bufora ekranu symulatora z treścią
  aplikacji obróconą do orientacji gry; należy osobno sprawdzić układ UI
  na realnym iPhonie/iPadzie.

## Regresje CI

Po dodaniu diagnostycznej zmiennej środowiskowej trzy testy kontraktowe
oczekiwały dosłownej linii `introPreview41 = true` albo
`sourceShip367Preview = false`. Zaktualizowano je, by potwierdzały
**zachowanie** domyślnego intro i wyłączonej diagnostyki, a nie stary
zapis kodu. Natywny build iOS i testy mechanik przeszły PASS; osobny
preflight źródeł również PASS. Stare czerwone przebiegi sprzed poprawki
nie są dowodem niesprawności symulatora lub oryginalnego modelu.

## Następny zakres

1. Porównać widoczny PlayerShip367 z ujęciem oryginalnej gry v568
   i potwierdzić rozmiar / kierunki osi kamery i renderowania.
2. Wprowadzić kolejne oryginalne modele na podstawie rzeczywistych
   odwołań C# i zasobów z czterech SHA-pinned ZIP-ów.
3. Rozszerzyć prawdziwe testy GPU o iPad, bez przerywania rozwoju iOS.
4. Oddzielnie przenosić proceduralne generatory 26 planet z v568,
   nie zastępować ich dowolnymi plikami GLB.

**Do tej pory NIE generowano nowego IPA.**
