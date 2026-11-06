# ASTEROIDY iOS — PlayerShip367 v568, oryginalny render na iPadzie

Data: 2026-11-06. Źródło: **wyłącznie Windows/SteamOS ASTEROIDY v568**.

## Potwierdzone

- [GitHub Actions run 42189013819](https://github.com/synixad-png/asteroidy-ios/actions/runs/42189013819):
  **completed / success**, kompilacja Xcode i rzeczywisty uruchomiony
  **iPad (10th generation) Simulator (iOS 18.5)**, bez IPA.
- Po kontrolowanym usunięciu starego dowodu aplikacja wykonała faktyczne
  rysowanie **599 997 wierzchołków** oryginalnego PlayerShip367, z
  `sourceGPU_SHA256=932b0a9028404562cfd28db4174f51ded5977e23a90c15580566c69f9c41819a`.
- Oryginalna skóra JPEG 2048×2048:
  `skinSHA256=9ed4fe25c25566f40b0ca401185c6280aa219e2ecb186d160ed3254d14eeb111`.
- Dowód `gpuCommandBufferCompleted=true` z **ukończonego**
  polecenia Metal `sourceFighterTexturedPipeline431`, nie z samego
  rozpoczęcia rysowania.
- Autentyczny obraz `IPAD_VERIFIED_ASTEROIDY_source367.png`,
  **1640 × 2360 px**, test niepustych pikseli zaliczony:
  165 zróżnicowanych skwantyzowanych kolorów, zakres jasności 0,622.
  Nie należy używać grafiki z innej aplikacji jako dowodu.
- GitHub Actions artifact: `13489416022`,
  `ASTEROIDY-original-v568-PlayerShip367-real-iPad-GPU-proof-NO-IPA`.
  Oryginalny ZIP artefaktu przeszedł kontrolę CRC.
- [iPhone Simulator run 42187435379](https://github.com/synixad-png/asteroidy-ios/actions/runs/42187435379)
  wcześniej również zakończony sukcesem, z prawdziwym obrazem i GPU proof.
- [Spatial v568 test 42189350958](https://github.com/synixad-png/asteroidy-ios/actions/runs/42189350958):
  PASS, porównuje źródłowy `PlayerShip363.cs`, `GpuSphere67.cs`,
  oryginalny mnożnik 0,714, położenie i trzy zakresy osi współrzędnych
  siatki oraz domyślną skalę misji 100%.

## Ograniczenia

**PASS nie oznacza zgodności 1:1 z grafiką Windows v568.** Na obrazie
rzeczywiście jest model statku, ale fragmenty planety są wciąż elementami
sceny diagnostycznej starszego portu; weryfikacja nie obejmuje pełnej
misji ani 26 sektorów. Nie wykazano jeszcze zgodności cieni,
oświetlenia, rozmiaru ekranowego, szczegółów obiektów i animacji
w bezpośrednim porównaniu pikselowym z PC.

Test wykonano na **symulatorach**, nie na fizycznym iPadzie/iPhonie.
Zapis PNG ma bufor o orientacji pionowej, choć treść gry jest obrócona
do poziomego interfejsu; wymaga osobnej oceny UX na urządzeniu.

Nie zmieniono domyślnej sceny iPhone/iPad; weryfikacja PlayerShip367
jest wyłącznie jawnym trybem diagnostycznym
(`ASTEROIDY_SHIP367_VERIFY=1`). Oryginalne modele oraz kod pozostają
weryfikowane po SHA-256, bez zamienników.

## Następne zadanie

Na tej zweryfikowanej bazie przenieść następny **rzeczywiście używany**
model oraz jego odpowiedni format źródłowy z v568. Weryfikować obraz
na obu symulatorach, bez deklarowania pełnej parytetowości Windows.
IPA nie było generowane.
