# RPI SAV

Application Flutter pour Joël/Cyril/admin : planification des interventions
SAV déjà acceptées, avec création automatique du rendez-vous sur le Google
Calendar de Joël. Voir `Doc_lancement_SAV_Joel.pdf` pour le cadrage complet.

**En ligne** : https://rpi-sav-app.web.app

## Architecture

- **Source de données** : Google Sheet "SAV diffus", lu/écrit **directement**
  depuis l'app via l'API Google Sheets (`lib/data/google_sheets_service.dart`),
  pas de backend applicatif dédié à cette partie.
- **Écriture** des colonnes de planification (durée, véhicule, renfort, date,
  heure — voir le mapping dans `lib/data/app_config.dart`, classe
  `SavColumns`). La colonne "Etat SAV" est protégée côté Sheet et n'est **pas**
  écrite par l'app.
- **Création du rendez-vous calendrier** : gérée entièrement côté **Google
  Apps Script** lié au Sheet (pas par l'app) :
  - `handleAgendaEvent_V11_` (dans le script principal du Sheet) crée/maj le
    RDV lors d'une édition manuelle (déclencheur `onEdit`).
  - Un fichier séparé `SyncAgendaAuto.gs` (déclencheur temporel, toutes les
    5-10 min) comble une limite de Google Apps Script : les déclencheurs
    `onEdit` ne se déclenchent jamais pour des écritures faites via l'API
    Sheets (donc jamais pour les RDV pris depuis cette app). Ce fichier
    scanne les lignes planifiées sans RDV encore créé et le crée, avec verrou
    anti-chevauchement (`LockService`) et anti-doublon (recherche d'un
    événement existant par numéro de SAV avant d'en créer un nouveau).
- **Authentification** : Firebase Auth + Google Sign-In, comptes autorisés
  listés dans `kAllowedEmails` (`lib/data/app_config.dart`), scopes
  `spreadsheets` et `calendar.events` (voir `lib/data/firebase_auth_service.dart`).
  Le jeton d'accès Google est mis en cache ~50 min pour éviter de redemander
  une connexion à chaque action.
- **Monitoring admin** : `lib/screens/errors_screen.dart`, visible uniquement
  par `admin@rpimenuiserie.com` (icône 🐛 dans la barre du haut) — 3 onglets :
  - **Erreurs** : erreurs Flutter/Sheets non gérées, remontées automatiquement
    dans Firestore (`error_logs`) via `lib/data/error_logger.dart`.
  - **Activité** : évènements métier (`activity_events`) — SAV planifiés,
    compteurs sur 7 jours.
  - **Comptes** : dernière connexion par compte (`user_activity`) et version
    de l'app utilisée.
  - Ces 3 collections Firestore sont **partagées** avec `rpi_qualite_app`
    (même projet Firebase `rpi-sav-app`), voir `firestore.rules` dans le
    dépôt `rpi_qualite_app`.

## Configuration effectuée

1. **ID du classeur "SAV diffus"** : configuré dans `lib/data/app_config.dart`
   (`kSavSpreadsheetId`). Peut être surchargé via
   `--dart-define=SAV_SPREADSHEET_ID=...`.
2. **Firebase** : projet `rpi-sav-app`, `lib/firebase_options.dart` généré via
   `flutterfire configure --project=rpi-sav-app`.
3. **Google** activé comme méthode de connexion dans Firebase Authentication.
4. **Hébergement** : Firebase Hosting, site `rpi-sav-app`
   (`firebase.json` → `hosting.site`).

## CI/CD

`.github/workflows/ci-cd.yml` — à chaque push sur `master` :
1. `flutter analyze` + `flutter test`.
2. Si les tests passent : `flutter build web --release` puis déploiement
   automatique sur Firebase Hosting.

L'authentification du déploiement utilise la **Workload Identity Federation**
(OIDC GitHub Actions → GCP, sans clé de compte de service téléchargeable —
requis car l'organisation `rpimenuiserie.com` interdit la création de clés
de service account). Config IAM :
- Pool `github-pool` + fournisseur OIDC `github-provider`, restreint au
  dépôt `Manon-pinto/rpi_sav_app`.
- Compte de service `github-deploy@rpi-sav-app.iam.gserviceaccount.com`,
  rôle `roles/firebasehosting.admin`.

Pour déployer manuellement en local (rare, la CI le fait automatiquement) :

```bash
flutter build web --release
firebase deploy --only hosting --project rpi-sav-app
```

## Lancement local

```bash
flutter pub get
flutter run -d chrome   # ou -d macos / un simulateur iOS-Android
```

## Validation

```bash
flutter analyze
flutter test
```

Voir aussi `RAPPORT_DE_TEST.md` pour la checklist de test manuel (connexion,
planification, calendrier, monitoring) — les tests automatisés ne couvrent
que la logique métier pure, pas l'intégration réelle avec Google/Firebase.

## Icône de l'app

Générée depuis `assets/RPI LOGO base line noir.png` via le package
`flutter_launcher_icons` (config dans `pubspec.yaml`). Pour régénérer après
un changement de logo :

```bash
dart run flutter_launcher_icons
```

Le favicon web (`web/favicon.png`) est généré séparément à une résolution
plus élevée (64×64, via `sips`) que ce que produit `flutter_launcher_icons`
par défaut (16×16), pour rester lisible dans l'onglet du navigateur.

## Limites connues

- Pas d'écran d'annulation/modification d'un RDV déjà planifié depuis l'app
  (à faire directement dans le Sheet ou le calendrier).
- Durée par défaut de 60 minutes appliquée si la "durée prévue" saisie n'est
  pas dans un format reconnu (`1h30`, `1h`, `1:30`, ou un nombre de minutes).
- Les RDV en conflit de créneau ne sont pas créés automatiquement par
  `SyncAgendaAuto.gs` (loggés en erreur dans Apps Script, à traiter
  manuellement).
