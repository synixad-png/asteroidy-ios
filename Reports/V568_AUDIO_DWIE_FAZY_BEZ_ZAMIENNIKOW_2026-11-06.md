# ASTEROIDY v568 iOS — Audio 2 etapy, źródłowy generator i blokada brakujących danych
Data: 2026-11-06. **Nie jest to wydanie działającej oryginalnej ścieżki dźwiękowej. Bez IPA.**

## 1. Audyt dostępnych źródeł
- Oryginalny pakiet użytkownika: Asteroidy_v568_ZRODLA_Windows_SteamOS_BEZ_EXE_BEZ_HANGARU.zip (pełne źródła Windows/SteamOS); pełna paczka nie jest obecnie dostępna w repozytorium iOS ani dostępnych bieżących plikach roboczych.
- Przeprowadzony rzeczywisty audyt 4 paczek częściowych (GitHub Actions [42293009917](https://github.com/synixad-png/asteroidy-ios/actions/runs/42293009917)): łącznie 90 wpisów, tylko 32 referencyjne pliki C#, żadnego generatora muzyki czy dźwięków, z katalogu Shared/music jedynie **planet53.jpg** będący obrazem, nie plikiem audio.
- Inwentarz oryginalnego builda v568 (KATALOG_SHARED_KLASYFIKACJA.csv) potwierdza **Shared/music/intro43.pcm.gz** (2 585 858 B, SHA256 372d78e964c2d43b6c476488226d403547af4f2cfaafb650bc11fdedd9dc8b25) oraz **Shared/music/SYNTH_LICENSES.txt** (6174 B, SHA256 8d790c6967996cb4903651087a73e961d846106c7eebcfdd1a1ef7d782f25a15), ale ich oryginalne bajty nie zostały przekazane do portu.
- Wcześniejszy harmonogram wskazuje źródłowe wywołania CombatSound/Sounds79. Nie są dostępne ich rzeczywiste implementacje, tabelki nut, parametry ani mapy zdarzeń. **Nie wiem**, jakie dokładnie utwory, wyzwalacze i suwaki efektów zawiera pełny oryginalny generator, dopóki nie można go przeczytać.

## 2. Faktycznie zaimplementowane
- **OriginalAudioLifecycle568.swift**: jedno źródłowe wejście prepareAtStartup/openMenu na kolejce serialnej, tylko jednokrotne generowanie muzyki menu, następnie osobna faza openMission(sector:), generowanie SFX i muzyki *dopiero* przy wejściu do misji; wynik menu i bank sektora buforowany. Wersjonowane żądania zapobiegają odtwarzaniu spóźnionej muzyki menu po wejściu w misję. Wymaga prawdziwego dostawcy OriginalAudioGenerator568.
- **OriginalAudioAV568.swift**: rzeczywisty tor AVAudioEngine / AVAudioPlayerNode, PCM float32 mono/stereo z prawdziwego generatora, osobne odtwarzanie muzyki i zdarzeń efektów według **oryginalnych** identyfikatorów, zatrzymanie przy wyjściu z misji, wejściu do diagnostyki, zmianie sceny, przejściu do tła. Nie używa wymyślonych nut, próbek ani zamienników.
- **App.swift**: inicjalizacja audio na starcie GameView, powiązanie z W3 menu, wejściem w CARBONIS 01, powrotem do atlasu/menu oraz scenePhase (wstrzymanie/wznowienie).
- **OriginalAudioManifest568**: SHA-256 wymaganej źródłowej pamięci Intro43 i licencji syntezatora z oryginalnego inwentarza.
- **Tests/OriginalAudioLifecycle568Tests.swift**: kolejność menu → misja1 → misja2, jeden raz menu, buforowanie sektora i powrót do menu, odrzucanie fikcyjnych zamienników i błędnego PCM. Testowe ciche próbki są **wyłącznie w kodzie testu** i nie są plikami dźwiękowymi aplikacji.
- **.github/workflows/verify-combat-only.yml**: testy Swift/Linux i osobna kompilacja Apple Swift/Metal, zawsze **bez IPA**.

## 3. Weryfikacja i nierozwiązane elementy
- Lokalne Swift/Linux: **PASS** fazy i cache; [źródłowy macOS Xcode build 42294207365](https://github.com/synixad-png/asteroidy-ios/actions/runs/42294207365): **PASS**, ale odnosi się do rewizji przed dopisaniem manifestu SHA i aktualizacją testu. Nowsza weryfikacja w GitHub Actions wykonywana niezależnie.
- **Nie przeniesiono oryginalnej muzyki, syntezatora, wyzwalaczy walki, efektów broni, kolizji, silników, UI ani ich wartości ustawień**, ponieważ pełny odpowiedni kod źródłowy i intro43.pcm.gz są niedostępne. Aktualna aplikacja pozostaje bez nowej ścieżki dźwiękowej; przygotowana warstwa odmawia odtwarzania zamienników.
- Nie wykonano testu odsłuchowego, pomiaru opóźnienia audio ani testów fizycznego iPhone'a/iPada.
- **Następne konieczne działanie:** odzyskać pełny oryginalny ZIP v568, odczytać wywołania od startu/Menu/Intro43/Synth przez Sounds79/CombatSound i mapy SFX; zweryfikować oryginalne PCM, licencje i oryginalne parametry ustawień, zaimplementować tylko rzeczywiste algorytmy oraz tabele, podłączyć źródłowe zdarzenia z CARBONIS 01 i dopiero wykonać test odsłuchowy.
- **Wskaźnik etapu 15: 10% techniczna infrastruktura (+10 pp), 0% rzeczywistego oryginalnego brzmienia przeniesionego. Globalny port: 38% / 62% pozostało (+0 pp).** Pozostałe etapy bez zmiany.
