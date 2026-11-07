# W3 NOWA GRA — raport wdrożenia iOS 07.11.2026

Źródła odniesienia: Windows v568 ProgramW3Native315.cs, Campaign37.cs, SaveManager61.cs oraz StoryPrologue359.cs.

Implementacja: commit 7eb3b99cbe1384ec5d2b37ca4baf7ffe39082fcf.
- Natywne wybory 1/2 graczy oraz trudności 0/1/2. Dwa statki w koop nie są przeniesione i przycisk startu dla 2 osób jest świadomie wyłączony.
- Dla 1 gracza nowe dane trafiają do rzeczywistej misji CARBONIS 01. Poziom trudności dociera do oryginalnego Wave, EnemyTactics71 i skalowania zdrowia rozbijanych asteroid.
- Wymagane potwierdzenie przed zmianą starego profilu. Kopia bezpieczeństwa w Application Support/ASTEROIDY/backups61 musi się udać przed resetem. Ustawienia grafiki/audio i zapisy ręczne pozostają nietknięte.
- Brak portu pełnego oryginalnego prologu Story359 (62 s): pierwszy sektor rusza bez niego. Nie udawano go animacją zastępczą.

TESTY: GitHub Actions https://github.com/synixad-png/asteroidy-ios/actions/runs/42359364204 — verify-sphere-linux, verify-new-game-source, expose-build-run i compile-device: wszystkie SUCCESS.
IPA: https://github.com/synixad-png/asteroidy-ios/actions/runs/42359364204/artifacts/13568504263
Faktyczny IPA: 28 340 966 bajtów, SHA-256 c998c4e96bbb143a7bb6f4bc5bf3b3e10f932bb1abf5e1e691baa9e07c6e104b.
CRC, ARM64, iOS 17+, iPhone+iPad (UIDeviceFamily 1,2) i identyczność SHA z raportem kompilacji potwierdzone.
IPA niepodpisane; podpisanie i test na fizycznym iPhone/iPad nadal nieprzeprowadzone. iPhone UI test nie wystartował z powodu timeout 60 s xcrun simctl na runnerze, a nie wykrytej w aplikacji usterki.

Zachowany harmonogram: 18 tych samych zadań, postęp całego portu 38%, pozostało 62%; zadanie 14 menu W3 nadal 24%. Nie zaliczać pełnej obsługi 2P, Story359 ani 44 ekranów.
