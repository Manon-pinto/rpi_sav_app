RPI MENUISERIE

# RPI SAV — Documentation de passation

*Tout ce qu'il faut savoir pour reprendre, maintenir ou faire évoluer ce
projet sans repartir de zéro.*

| | |
|---|---|
| Rédigé par | Manon Pinto |
| Date | 15/07/2026 |
| Dépôt | https://github.com/Manon-pinto/rpi_sav_app (privé) |
| App en ligne | https://rpi-sav-app.web.app |

---

## 1. Vue d'ensemble

Application Flutter (web) qui lit/écrit directement le Google Sheet "SAV
diffus" via l'API Google Sheets, sans backend applicatif dédié. La création
des rendez-vous calendrier est déléguée à un script Google Apps Script lié
au Sheet (pas à l'application elle-même). Voir `README.md` pour le détail
architecture, ce document couvre les **accès**, **la façon de reprendre la
main**, et **les pièges déjà rencontrés**.

## 2. Comptes et accès nécessaires

Pour intervenir sur ce projet, il faut avoir accès à :

| Ressource | Où | Qui y a accès aujourd'hui |
|---|---|---|
| Dépôt GitHub | https://github.com/Manon-pinto/rpi_sav_app | Manon-pinto (propriétaire) |
| Projet Firebase `rpi-sav-app` | https://console.firebase.google.com/project/rpi-sav-app | `admin@rpimenuiserie.com` (Owner GCP) |
| Google Sheet "SAV diffus" | (lien dans le Sheet lui-même) | Cyril, Joël, admin + droits d'édition |
| Script Apps Script du Sheet | Extensions → Apps Script depuis le Sheet | Mêmes droits que le Sheet |
| Calendrier Google de Joël | `joel.pouvereau@rpimenuiserie.com` | Joël (propriétaire du calendrier) |

**Pas de mot de passe/clé stockée dans le dépôt** — tout passe par
authentification Google (OAuth) ou par la Workload Identity Federation
(section 5) qui ne nécessite aucune clé.

## 3. Où trouver quoi (fichiers clés)

```
lib/
  data/
    app_config.dart          → comptes autorisés, mapping des colonnes du Sheet
    google_sheets_service.dart → lecture/écriture du Sheet
    firebase_auth_service.dart → connexion Google, cache du jeton d'accès
    error_logger.dart          → remontée des erreurs vers Firestore
    activity_logger.dart       → heartbeat de connexion + évènements
  screens/
    dashboard_screen.dart      → tableau de bord
    sav_planning_screen.dart   → écran de planification
    errors_screen.dart         → monitoring admin (Erreurs/Activité/Comptes)
firestore.rules                → dans le dépôt rpi_qualite_app (projet Firebase partagé)
.github/workflows/ci-cd.yml    → pipeline de test + déploiement automatique
firebase.json / .firebaserc    → config de l'hébergement Firebase
```

Le script Apps Script (calendrier) est **dans le Google Sheet lui-même**,
pas dans ce dépôt Git — Extensions → Apps Script. Deux fichiers à connaître :
- Le script principal (déjà existant avant ce projet, gère aussi BL, mails,
  etc.) — fonction clé : `handleAgendaEvent_V11_`.
- `SyncAgendaAuto.gs`, ajouté pour ce projet : contient `syncPendingAgendaEvents`
  (déclencheur temporel, toutes les 5-10 min) qui crée les RDV pour les
  lignes modifiées par l'app (l'API Sheets ne déclenche jamais `onEdit`,
  d'où ce script complémentaire — **ne pas le supprimer**). Contient aussi
  `notifyConflict_`, qui envoie un mail à `cyril.chaumeil@rpimenuiserie.com`
  en cas de conflit de créneau détecté (dédupliqué via une note posée sur
  la cellule DATE_INTER, pour ne pas spammer à chaque passage du
  déclencheur).

## 4. Colonnes du Sheet "SAV diffus" (mapping actuel)

Voir `lib/data/app_config.dart`, classe `SavColumns`, pour la source de
vérité — copie ici pour référence rapide :

| Donnée | Colonne |
|---|---|
| Statut SAV | O |
| Etat SAV (protégée, l'app ne l'écrit plus) | U |
| Durée d'intervention | AA |
| Véhicule | AB |
| Renfort | AC |
| Date d'intervention | AD |
| Heure d'intervention | AE |
| ID_GOOGLE (id de l'évènement calendrier) | colonne portant l'en-tête `ID_GOOGLE` |

**Piège déjà rencontré** : ce mapping a déjà changé une fois en cours de
projet (le Sheet a été réorganisé). Si l'app affiche 0 SAV ou écrit sur de
mauvaises colonnes, **vérifier en premier que ce mapping correspond encore
à la structure réelle du Sheet**.

## 5. Déploiement / CI-CD

Chaque push sur `master` déclenche `.github/workflows/ci-cd.yml` :
1. `flutter analyze` + `flutter test`
2. Si succès : build web + déploiement sur Firebase Hosting

**Authentification du déploiement** : Workload Identity Federation (OIDC),
pas de clé de service account (l'organisation `rpimenuiserie.com` interdit
la création de clés — politique de sécurité qui a bloqué la méthode
standard `firebase init hosting:github`). Configuration IAM déjà en place :

- Pool d'identité : `github-pool` (projet `rpi-sav-app`)
- Fournisseur OIDC : `github-provider`, restreint au dépôt
  `Manon-pinto/rpi_sav_app`
- Compte de service : `github-deploy@rpi-sav-app.iam.gserviceaccount.com`,
  rôle `roles/firebasehosting.admin`

Si le déploiement CI échoue avec une erreur d'authentification, vérifier
d'abord que ce compte de service et ce binding IAM existent toujours
(`gcloud iam service-accounts list --project rpi-sav-app`).

**Déploiement manuel** (si besoin, hors CI) :
```bash
flutter build web --release
firebase deploy --only hosting --project rpi-sav-app
```
Nécessite d'être connecté via `firebase login` (compte
`admin@rpimenuiserie.com` recommandé).

## 6. Comment déboguer un problème signalé

1. **Écran de monitoring admin** (dans l'app, connecté en
   `admin@rpimenuiserie.com`, icône 🐛) : erreurs Flutter/Sheets non
   gérées, activité récente, dernière connexion par compte. Premier réflexe.
2. **Journal d'exécution Apps Script** : dans le Sheet → Extensions → Apps
   Script → icône ⏰ → onglet "Exécutions". Filtrer sur `syncPendingAgendaEvents`
   pour les soucis de synchronisation calendrier, ou `processEdit_SAV` pour
   les automatisations déclenchées par une édition manuelle.
3. **GitHub Actions** : https://github.com/Manon-pinto/rpi_sav_app/actions
   pour les échecs de build/déploiement.
4. **Firestore Console** (`error_logs`, `activity_events`, `user_activity`) :
   https://console.firebase.google.com/project/rpi-sav-app/firestore — vue
   brute des mêmes données que l'écran de monitoring, utile si l'app
   elle-même est inaccessible.

## 7. Pièges déjà rencontrés (pour ne pas les refaire)

- **`firebase login:ci`** (jeton CI classique) est cassé pour les
  déploiements Hosting depuis 2024+ (401 systématique) — ne pas y revenir,
  utiliser la Workload Identity Federation en place.
- **Création de clé de service account** : bloquée par une politique
  d'organisation Google Workspace — inutile de réessayer sans l'accord
  d'un admin GCP de l'organisation.
- **`firebase deploy` échoue avec "no site name or target name"** : vérifier
  que `.firebaserc` (projet par défaut) **et** `firebase.json` →
  `hosting.site` sont bien renseignés explicitement — un déploiement local
  réussi peut masquer ce problème via un cache local (`.firebase/`,
  gitignoré) qui n'existe pas en CI.
- **Colonnes Google Sheet protégées** : la colonne "Etat SAV" a des
  protections qui bloquent l'écriture pour certains comptes — l'app ne
  l'écrit plus du tout pour cette raison. Si une future fonctionnalité doit
  écrire ailleurs dans le Sheet, vérifier d'abord si la plage cible est
  protégée pour le compte utilisé.
- **Déclencheur Apps Script à 1 minute au lieu de 5-10** : si mal configuré,
  les exécutions se chevauchent et provoquent des échecs et doublons de
  RDV. `syncPendingAgendaEvents` a un verrou (`LockService`) et une
  vérification anti-doublon par titre d'évènement pour limiter la casse,
  mais l'intervalle du déclencheur doit rester raisonnable (5-10 min).
- **Logo flou** : une image source haute résolution affichée à une petite
  taille peut paraître floue si elle n'est pas redécodée à la taille
  d'affichage réelle (`cacheHeight` + `filterQuality.high` sur
  `Image.asset`) — piège classique Flutter Web.

## 8. Limites connues / dette technique

- Pas d'écran d'annulation/modification d'un RDV déjà planifié depuis
  l'app.
- Pas de tests automatisés sur le script Apps Script (JavaScript,
  hors de ce dépôt Git — testé manuellement uniquement).
- `rpi_qualite_app` (projet séparé, même Firebase) n'a pas encore le même
  niveau de CI/CD — à envisager en cohérence si ce projet évolue.

## 9. Contact

Pour toute question sur l'historique des décisions prises pendant ce
projet, se référer à l'historique des commits Git (messages détaillés) et
à ce document. Pas de contact humain spécifique désigné à ce stade au-delà
de l'équipe RPI Menuiserie elle-même (`admin@rpimenuiserie.com`).
