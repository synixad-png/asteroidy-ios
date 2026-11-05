# ASTEROIDY iOS v18 — przekazanie źródeł do kompilacji

Data: 2026-11-05

Status: źródła przygotowane w repozytorium; kompilacji Xcode i IPA nie wykonano.

## Przesłany projekt

Repozytorium: https://github.com/synixad-png/asteroidy-ios, publiczne, gałąź `main`.

Przeniesiono pełną zawartość `ASTEROIDY_iOS_v18_GITHUB_HANDOFF.zip`: 60 plików z katalogu `ASTEROIDY_iOS_v18_PROFILE_WORK`. Projekt znajduje się w korzeniu repozytorium. Zawiera 13 plików Swift aplikacji, shader Metal, cztery zasoby, testy, narzędzia, `project.yml` i `.github/workflows/build-ios.yml`.

Kod gry, testy, narzędzia, konfigurację i zasoby zachowano bajt w bajt z paczki przekazania. Zaktualizowano README i instrukcję drugiego czatu, zastąpiono nieaktualny raport o braku źródeł. `SOURCES_SHA256SUMS.txt` dokumentuje sumy kontrolne wszystkich plików paczki poza dwiema zaktualizowanymi instrukcjami.

## Sprawdzenia przygotowania

- Porównano kompletność i bajty skopiowanych plików ze wskazaną paczką ZIP.
- Sprawdzono składnię YAML konfiguracji projektu i workflow.
- Workflow ma wyłącznie `workflow_dispatch`; samo wgranie kodu nie uruchamia kompilacji.
- Job wymaga publicznego repozytorium, standardowego `macos-15` i ma limit 45 minut.
- Konfiguracja obejmuje iPhone i iPad, iOS 17.0, build urządzenia `iphoneos`, architekturę arm64 i wyłączone podpisywanie w poleceniu Xcode.
- Zasoby Vanguard i Boreas są binarnymi plikami projektu, nie odsyłaczami ani plikami zastępczymi. Ich sumy znajdują się w wykazie SHA-256.

Są to sprawdzenia przygotowania i integralności. Nie dowodzą poprawnej kompilacji ani działania gry.

## Dalszy etap

Drugi czat może pobrać repozytorium i wykonać instrukcję `START_DRUGI_CZAT.md`: ręcznie uruchomić workflow, przeanalizować logi, naprawić ujawnione błędy, pobrać IPA i zweryfikować je za pomocą `Tools/verify_ipa.py`.

W tym etapie nie uruchamiano workflow, Xcode ani testów Swift. Nie utworzono IPA, nie sprawdzono podpisywania Sideloadly ani działania na fizycznym urządzeniu. Historyczne raporty testów zachowano jako dokumentację wcześniejszych prac.

Nie zmieniano `iphone-ipa-test` ani projektów Windows/SteamOS. Nie uruchamiano płatnych usług ani runnerów.
