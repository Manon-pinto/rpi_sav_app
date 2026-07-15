# Rapport de test — RPI SAV

Ce document sert à guider les tests manuels de l'application avant mise en
service, et à garder une trace écrite de ce qui a été testé, par qui, et
avec quel résultat.

Complète le tableau "Résultats" en bas après chaque session de test.

**Dernière mise à jour** : 15/07/2026, après correctifs sur l'écriture
Google Sheets, le déplacement de la création du calendrier vers Apps
Script, la mise en cache du jeton de connexion et l'ajout du monitoring
admin. Appli déployée sur https://rpi-sav-app.web.app.

## Prérequis avant de commencer

- [ ] Le fournisseur "Google" est activé dans Firebase Authentication
      (console Firebase du projet `rpi-sav-app`).
- [ ] Tu es connecté avec un des 3 comptes autorisés :
      `cyril.chaumeil@rpimenuiserie.com`, `joel.pouvereau@rpimenuiserie.com`
      ou `admin@rpimenuiserie.com`.
- [ ] Le compte utilisé a les droits d'édition sur le Google Sheet "SAV diffus".
- [ ] Tu as sous les yeux le Google Sheet "SAV diffus" ouvert dans un onglet,
      pour comparer avec ce que l'app affiche.
- [ ] Le script Apps Script du Sheet contient bien le fichier `SyncAgendaAuto`
      (déclencheur temporel `syncPendingAgendaEvents`), sans quoi les RDV
      pris depuis l'app ne créeront pas d'événement calendrier.
- [ ] Test fait en navigation privée/incognito si un test précédent a laissé
      une session en cache (évite les faux positifs liés au service worker).

## Repères des colonnes actuelles du Sheet "SAV diffus"

| Donnée | Colonne |
|---|---|
| Statut SAV | O |
| Etat SAV | U (protégée — l'app ne l'écrit plus, voir section 5) |
| Durée d'intervention prévue | AA |
| Véhicule | AB |
| Renfort | AC |
| Date d'intervention | AD |
| Heure d'intervention | AE |
| Client final / adresse / téléphone | AF |
| ID_GOOGLE (identifiant RDV calendrier) | colonne portant l'en-tête `ID_GOOGLE` |

## 1. Connexion

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 1.1 | Ouvrir l'app, cliquer sur "Se connecter avec Google" | La fenêtre de connexion Google s'ouvre |
| 1.2 | Se connecter avec un compte **non autorisé** (ex. une adresse personnelle) | L'app refuse la connexion avec un message d'erreur clair |
| 1.3 | Se connecter avec `cyril.chaumeil@rpimenuiserie.com`, `joel.pouvereau@rpimenuiserie.com` ou `admin@rpimenuiserie.com` | La connexion réussit, le tableau de bord s'affiche |
| 1.4 | Enchaîner plusieurs actions (ouvrir un SAV, planifier, revenir à la liste, rouvrir un autre SAV) sans se déconnecter | **Aucune popup de reconnexion ne doit réapparaître** pendant ~50 minutes (le jeton est mis en cache) |
| 1.5 | Cliquer sur l'icône de déconnexion (en haut à droite) | Retour à l'écran de connexion, et une reconnexion redemande bien la popup |

## 2. Tableau de bord

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 2.1 | Regarder la carte "À planifier" | Le nombre correspond au nombre de lignes du Sheet qui sont **à la fois** : Statut SAV (col. O) = Accepté, ligne colorée en rose **ou** colonne L contenant "Joel", Etat SAV (col. U) ≠ Cloturé, et sans date/heure d'intervention déjà remplies |
| 2.2 | Regarder la carte "Chantiers concernés" | Le nombre de chantiers distincts (colonne Ref. Chantier) parmi les SAV à planifier |
| 2.3 | Regarder la section "À planifier" (aperçu) | Les 3 premiers SAV de la liste s'affichent avec numéro SAV et nom client |
| 2.4 | Cliquer sur "Voir tout" | Ouvre la liste complète, avec le même total que la carte "À planifier" |
| 2.5 | Tirer vers le bas pour rafraîchir (pull-to-refresh) | Les données se rechargent depuis le Sheet, sans erreur/plantage |

## 3. Liste des SAV à planifier

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 3.1 | Comparer le total affiché avec un comptage manuel dans le Sheet (Statut=Accepté + rose/Joel + non clôturé + AD/AE vides) | Les deux chiffres correspondent |
| 3.2 | Vérifier qu'aucun SAV clôturé n'apparaît | Aucune ligne avec Etat SAV = Cloturé ne doit être visible |
| 3.3 | Vérifier qu'aucun SAV déjà planifié (AD/AE déjà remplis) n'apparaît | Absent de la liste |
| 3.4 | Cliquer sur un SAV de la liste | Ouvre l'écran de planification pour ce SAV |

## 4. Planification d'une intervention

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 4.1 | Ouvrir un SAV, vérifier les infos en lecture seule | Correspondent aux colonnes du Sheet pour cette ligne |
| 4.2 | Vérifier le champ "Durée prévue" | Si la colonne AA a une liste déroulante dans le Sheet, l'app propose un menu déroulant avec les mêmes choix ; sinon un champ texte libre |
| 4.3 | Vérifier le champ "Véhicule" | Idem (liste déroulante si colonne AB en a une) |
| 4.4 | Vérifier le champ "Renfort" | Idem (liste déroulante si colonne AC en a une) |
| 4.5 | Choisir une date et une heure, remplir les champs, cliquer "Confirmer" | Passage à l'écran de confirmation, mention que le calendrier sera mis à jour automatiquement depuis le Sheet |
| 4.6 | Retourner sur le Google Sheet et vérifier la ligne modifiée | Colonnes AA, AB, AC, AD, AE remplies avec les valeurs saisies ; l'heure au format `09h30` (pas `09:30`) |
| 4.7 | Attendre jusqu'à 10 minutes, puis vérifier le Google Calendar de Joël | Un événement est créé automatiquement (via le déclencheur `syncPendingAgendaEvents`), avec le bon titre (N° SAV — Client), lieu, description et horaire |
| 4.8 | Vérifier la colonne `ID_GOOGLE` sur cette ligne | Remplie avec l'identifiant de l'événement calendrier créé |
| 4.9 | Retourner à la liste | Le SAV planifié a disparu de la liste "à planifier" |

### 4bis. Enregistrer sans date (durée/véhicule/renfort seuls)

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 4b.1 | Ouvrir un SAV, remplir Durée/Véhicule/Renfort **sans** choisir de date ni d'heure | Le bouton affiche "Enregistrer sans rendez-vous" |
| 4b.2 | Cliquer sur "Enregistrer sans rendez-vous" | Un message s'affiche confirmant que durée/véhicule/renfort sont enregistrés et que le SAV reste "à planifier" |
| 4b.3 | Retourner sur le Google Sheet | Colonnes AA/AB/AC remplies, mais AD/AE (date/heure) restent vides |
| 4b.4 | Vérifier le Google Calendar | Aucun nouvel événement créé |
| 4b.5 | Retourner à la liste "à planifier" | Le SAV est toujours visible |
| 4b.6 | Rouvrir ce même SAV plus tard et choisir une date **seule** (sans heure), valider | La date s'enregistre sur la ligne sans effacer une éventuelle heure déjà présente, et réciproquement |
| 4b.7 | Compléter ensuite l'heure manquante et valider | Le bouton redevient "Confirmer", le RDV est créé (section 4) |

## 5. Cas limites et non-régression

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 5.1 | Tester avec un SAV dont la durée saisie n'est pas reconnue (texte libre inhabituel) | L'événement Calendar (créé côté Apps Script) utilise une durée par défaut de 60 minutes sans planter |
| 5.2 | Couper la connexion internet puis ouvrir l'app | Un message d'erreur de chargement s'affiche, pas de plantage |
| 5.3 | Planifier un SAV dont la ligne a une cellule protégée dans une colonne annexe | L'enregistrement de durée/véhicule/renfort/date/heure réussit quand même (l'app n'écrit plus la colonne "Etat SAV" protégée) |
| 5.4 | Planifier deux SAV sur des créneaux qui se chevauchent avec un RDV déjà existant dans le calendrier de Joël | Le RDV en conflit n'écrase pas l'existant ; il apparaît en erreur dans le journal Apps Script (Exécutions), pas de doublon créé |

## 6. Monitoring admin

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 6.1 | Se connecter avec `admin@rpimenuiserie.com` | Une icône 🐛 "Erreurs techniques" apparaît dans la barre du haut, absente pour les autres comptes |
| 6.2 | Ouvrir cet écran | 3 onglets : Erreurs / Activité / Comptes |
| 6.3 | Onglet Erreurs | Liste les erreurs Flutter/Sheets non gérées, les plus récentes en premier, avec contexte et stack trace dépliable |
| 6.4 | Onglet Activité | Compteurs des 7 derniers jours (`sav_planned`, `controle_qualite`) + historique |
| 6.5 | Onglet Comptes | Dernière connexion par compte, avec version de l'app utilisée |
| 6.6 | Provoquer une erreur (ex. couper le réseau puis planifier un SAV) | L'erreur apparaît dans l'onglet Erreurs après reconnexion |

## Résultats des vérifications automatiques

Exécutées le 15/07/2026 par Claude, avant la session de test manuel.

| Vérification | Commande | Résultat |
|---|---|---|
| Analyse statique | `flutter analyze` | ✅ Aucun problème détecté |
| Tests unitaires | `flutter test` | ✅ 1/1 test passé (`SavColumns.indexOf convertit les lettres de colonnes`) |
| Build web release | `flutter build web --release` | ✅ Compile sans erreur |
| Déploiement Firebase Hosting | `firebase deploy --only hosting` | ✅ En ligne sur https://rpi-sav-app.web.app |

Ces vérifications couvrent la compilation et la logique unitaire testée,
**pas** le comportement réel dans un navigateur (connexion Google, écriture
Sheets, création calendrier) — les sections 1 à 6 ci-dessus doivent être
testées manuellement par un humain connecté avec un vrai compte.

## Résultats des sessions de test manuel

Remplis ce tableau après chaque test réel avec Joël/Cyril/l'admin.

| Date | Testeur | Sections testées | Résultat (OK / KO) | Remarques / bugs trouvés |
|------|---------|-------------------|---------------------|--------------------------|
|      |         |                   |                     |                          |
|      |         |                   |                     |                          |
|      |         |                   |                     |                          |
