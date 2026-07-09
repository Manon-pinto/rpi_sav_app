# RPI SAV

Application Flutter pour Joël : planification des interventions SAV déjà
acceptées par Cyril, et création automatique du rendez-vous sur son Google
Calendar. Voir `Doc_lancement_SAV_Joel.pdf` pour le cadrage complet.

## Architecture

- Source de données : Google Sheet "SAV diffus", lu/écrit **directement**
  depuis l'app via l'API Google Sheets (pas de backend Apps Script).
- Écriture des colonnes AC:AG (planification) et W (Etat SAV) via
  `lib/data/google_sheets_service.dart`.
- Création d'événement sur `lib/data/google_calendar_service.dart` (API
  Google Calendar, calendrier `primary` du compte connecté).
- Authentification : Firebase Auth + Google Sign-In, domaine
  `@rpimenuiserie.com`, scopes `spreadsheets` et `calendar.events` (voir
  `lib/data/firebase_auth_service.dart`).

## Configuration effectuée

1. **ID du classeur "SAV diffus"** : `1HRn7SEUkqnHbJgsdmNZp2yOsoK6P5SikJZ5PGgr6fUI`,
   configuré dans `lib/data/app_config.dart` (`kSavSpreadsheetId`). Peut être
   surchargé via `--dart-define=SAV_SPREADSHEET_ID=...`.
2. **Firebase** : projet dédié `rpi-sav-app` (le compte `admin@rpimenuiserie.com`
   n'avait pas les droits sur `rpi-production-98ce4`, d'où la création d'un
   nouveau projet). `lib/firebase_options.dart` a été généré via
   `flutterfire configure --project=rpi-sav-app` avec les apps
   Android/iOS/macOS/Web/Windows déjà enregistrées.

## Reste à faire avant le premier test réel avec Joël

1. **Activer Google comme méthode de connexion** dans la console Firebase :
   https://console.firebase.google.com/project/rpi-sav-app/authentication/providers
   → Authentication → Sign-in method → activer "Google".
2. **Droits sur le Sheet** : le compte Google utilisé par Joël doit avoir les
   droits d'édition sur le classeur "SAV diffus" (partage Google Sheets
   standard, pas de config supplémentaire côté app).
3. Sur iOS/macOS, `GoogleService-Info.plist` a été généré automatiquement par
   `flutterfire configure` — rien à faire de plus pour lancer sur simulateur.

## Lancement local

```bash
flutter pub get
flutter run -d "iPhone" # ou -d chrome / -d macos
```

## Validation

```bash
flutter analyze
flutter test
```

## Limites connues (V1, voir section 10 du doc)

- Pas d'écran d'annulation/modification d'un RDV déjà planifié.
- Durée par défaut de 60 minutes appliquée si la "durée prévue" saisie n'est
  pas dans un format reconnu (`1h30`, `1h`, `1:30`, ou un nombre de minutes).
