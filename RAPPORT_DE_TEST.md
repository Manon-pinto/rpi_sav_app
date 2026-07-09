# Rapport de test — RPI SAV

Ce document sert à guider les tests manuels de l'application avant mise en
service, et à garder une trace écrite de ce qui a été testé, par qui, et
avec quel résultat.

Complète le tableau "Résultats" en bas après chaque session de test.

## Prérequis avant de commencer

- [ ] Le fournisseur "Google" est activé dans Firebase Authentication
      (console Firebase du projet `rpi-sav-app`).
- [ ] Tu es connecté avec un des 3 comptes autorisés :
      `cyril.chaumeil@rpimenuiserie.com`, `joel.pouvereau@rpimenuiserie.com`
      ou `admin@rpimenuiserie.com`.
- [ ] Le compte utilisé a les droits d'édition sur le Google Sheet "SAV diffus".
- [ ] Tu as sous les yeux le Google Sheet "SAV diffus" ouvert dans un onglet,
      pour comparer avec ce que l'app affiche.

## 1. Connexion

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 1.1 | Ouvrir l'app, cliquer sur "Se connecter avec Google" | La fenêtre de connexion Google s'ouvre |
| 1.2 | Se connecter avec un compte **non autorisé** (ex. une adresse personnelle) | L'app refuse la connexion avec un message d'erreur clair |
| 1.3 | Se connecter avec `cyril.chaumeil@rpimenuiserie.com`, `joel.pouvereau@rpimenuiserie.com` ou `admin@rpimenuiserie.com` | La connexion réussit, le tableau de bord s'affiche |
| 1.4 | Cliquer sur l'icône de déconnexion (en haut à droite) | Retour à l'écran de connexion |

## 2. Tableau de bord

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 2.1 | Regarder la carte "À planifier" | Le nombre correspond au nombre de lignes du Sheet qui sont **à la fois** : Statut SAV = Accepté, ligne colorée en rose (#d5a6bd), Etat SAV ≠ Cloturé, et sans date/heure d'intervention déjà remplies |
| 2.2 | Regarder la carte "Chantiers concernés" | Le nombre de chantiers distincts (colonne Ref. Chantier) parmi les SAV à planifier |
| 2.3 | Regarder la section "À planifier" (aperçu) | Les 3 premiers SAV de la liste s'affichent avec numéro SAV et nom client |
| 2.4 | Cliquer sur "Voir tout" | Ouvre la liste complète, avec le même total que la carte "À planifier" |
| 2.5 | Tirer vers le bas pour rafraîchir (pull-to-refresh) | Les données se rechargent depuis le Sheet |

## 3. Liste des SAV à planifier

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 3.1 | Comparer le total affiché avec un comptage manuel dans le Sheet (filtrer Statut=Accepté + couleur rose + non clôturé + AF/AG vides) | Les deux chiffres correspondent |
| 3.2 | Vérifier qu'aucun SAV clôturé n'apparaît | Aucune ligne avec Etat SAV = Cloturé ne doit être visible |
| 3.3 | Vérifier qu'aucun SAV déjà planifié (AF/AG déjà remplis) n'apparaît | Absent de la liste |
| 3.4 | Cliquer sur un SAV de la liste | Ouvre l'écran de planification pour ce SAV |

## 4. Planification d'une intervention

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 4.1 | Ouvrir un SAV, vérifier les infos en lecture seule (Intervention à réaliser, Fournitures à livrer, Client final) | Correspondent aux colonnes AB, S, AH/AI/AJ du Sheet pour cette ligne |
| 4.2 | Vérifier le champ "Durée prévue" | Si la colonne AC a une liste déroulante dans le Sheet, l'app propose un menu déroulant avec les mêmes choix ; sinon un champ texte libre |
| 4.3 | Vérifier le champ "Véhicule" | Idem (liste déroulante si colonne AD en a une) |
| 4.4 | Vérifier le champ "Renfort" | Idem (liste déroulante si colonne AE en a une) |
| 4.5 | Choisir une date et une heure, remplir les champs, cliquer "Confirmer et ajouter au calendrier" | Passage à l'écran de confirmation |
| 4.6 | Retourner sur le Google Sheet et vérifier la ligne modifiée | Colonnes AC, AD, AE, AF, AG remplies avec les valeurs saisies ; colonne W (Etat SAV) passée à "Prêt pour intervention" |
| 4.7 | Vérifier le Google Calendar du compte utilisé | Un événement est créé avec le bon titre (N° SAV — Client), lieu, description et horaire |
| 4.8 | Retourner à la liste | Le SAV planifié a disparu de la liste "à planifier" |

### 4bis. Enregistrer sans date (durée/véhicule/renfort seuls)

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 4b.1 | Ouvrir un SAV, remplir Durée/Véhicule/Renfort **sans** choisir de date ni d'heure | Le bouton affiche "Enregistrer sans rendez-vous" (pas "Confirmer et ajouter au calendrier") |
| 4b.2 | Cliquer sur "Enregistrer sans rendez-vous" | Un message s'affiche : "Durée, véhicule et renfort ont été enregistrés. Aucun rendez-vous n'a été ajouté au calendrier..." |
| 4b.3 | Retourner sur le Google Sheet | Colonnes AC/AD/AE remplies, mais AF/AG (date/heure) restent vides et la colonne W (Etat SAV) **n'est pas** modifiée |
| 4b.4 | Vérifier le Google Calendar | Aucun nouvel événement créé |
| 4b.5 | Retourner à la liste "à planifier" | Le SAV est toujours visible (puisqu'aucune date n'a été fixée) |
| 4b.6 | Rouvrir ce même SAV plus tard et cette fois choisir une date/heure | Le bouton redevient "Confirmer et ajouter au calendrier" et le comportement normal (section 4) s'applique |

## 5. Cas limites

| # | Étape | Résultat attendu |
|---|-------|-------------------|
| 5.1 | Tester avec un SAV dont la durée saisie n'est pas reconnue (ex. texte libre inhabituel) | L'événement Calendar utilise une durée par défaut de 60 minutes sans planter |
| 5.2 | Couper la connexion internet puis ouvrir l'app | Un message d'erreur de chargement s'affiche, pas de plantage |
| 5.3 | Se connecter puis attendre longtemps sans rien faire, puis planifier un SAV | La session reste valide ou redemande une connexion proprement (pas d'erreur silencieuse) |

## Résultats des sessions de test

Remplis ce tableau après chaque test réel avec Joël/Cyril/l'admin.

| Date | Testeur | Sections testées | Résultat (OK / KO) | Remarques / bugs trouvés |
|------|---------|-------------------|---------------------|--------------------------|
|      |         |                   |                     |                          |
|      |         |                   |                     |                          |
|      |         |                   |                     |                          |
