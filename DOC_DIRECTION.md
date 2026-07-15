RPI MENUISERIE

# RPI SAV — Bilan et état du projet

Document de suivi de projet — informatif

*Application de planification des interventions SAV, connectée au Google
Sheet existant et au calendrier de Joël, sans double saisie.*

| | |
|---|---|
| Rédigé par | Assistant technique (Claude) |
| Date | 15/07/2026 |
| Destinataire | Direction RPI Menuiserie |

---

## 1. Contexte et objectif

Avant ce projet, la planification d'une intervention SAV nécessitait de
noter la date/heure/véhicule dans le Google Sheet, puis de créer
manuellement le rendez-vous dans le calendrier de Joël — une double saisie
source d'oublis et d'erreurs de créneau.

**Objectif** : une application accessible depuis un navigateur, sans
installation, qui permet à Joël (ou Cyril/admin) de consulter la liste des
SAV acceptés à planifier, de renseigner durée/véhicule/renfort/date/heure en
un seul geste, avec mise à jour automatique du Google Sheet et du calendrier.

## 2. Ce qui a été livré

- **Application web** accessible à tous les comptes autorisés, sans
  installation : https://rpi-sav-app.web.app
- **Connexion Google restreinte** aux comptes `@rpimenuiserie.com` autorisés
  nommément (pas tout le domaine).
- **Planification en un seul écran** : durée, véhicule, renfort, date, heure
  — avec listes déroulantes reprenant celles déjà configurées dans le Sheet.
- **Synchronisation automatique du calendrier de Joël**, y compris pour les
  RDV pris depuis l'app (contrainte technique Google contournée par un
  script complémentaire, voir doc de passation).
- **Suivi des erreurs et de l'activité** (réservé au compte admin) : tableau
  de bord technique montrant les erreurs survenues, l'activité récente par
  compte, et la dernière connexion de chacun.
- **Mise à jour automatisée** : chaque modification du code est testée puis
  mise en ligne automatiquement (CI/CD), sans étape manuelle et sans risque
  de mettre en ligne du code non testé.

## 3. Bénéfices

- Fin de la double saisie Sheet + Calendar.
- Moins de risque d'erreur de créneau (le système détecte les
  chevauchements et prévient plutôt que d'écraser un rendez-vous existant).
- Accessible depuis n'importe quel poste avec un navigateur, aucune
  installation ni mise à jour manuelle à faire.
- Visibilité technique pour l'admin en cas de souci (sans devoir demander à
  un développeur de consulter des journaux techniques).

## 4. État actuel

**En production** depuis le 15/07/2026, testé avec les comptes réels
(Joël, Cyril, admin) sur des données réelles du Sheet "SAV diffus".

Un test manuel complet reste recommandé avant généralisation totale (voir
`RAPPORT_DE_TEST.md`) — la checklist n'a pas encore été remplie de bout en
bout par un utilisateur final sur toutes les sections.

## 5. Infrastructure et coûts

- **Hébergement** : Firebase Hosting (Google), sur le plan gratuit "Spark" —
  largement suffisant pour l'usage interne prévu (quelques utilisateurs).
- **Code source** : GitHub, dépôt privé, gratuit sur ce volume d'usage.
- **Automatisation des mises à jour (CI/CD)** : GitHub Actions, gratuit
  jusqu'à un volume d'usage bien supérieur à celui de ce projet.
- Aucun coût récurrent identifié à ce stade.

## 6. Risques et limites connues

- Le calendrier de Joël dépend d'un script Google Apps Script (dans le
  Sheet) — si ce script est supprimé ou modifié sans précaution, la
  synchronisation automatique s'arrête (voir doc de passation pour la
  marche à suivre).
- Pas d'écran pour annuler/modifier un RDV déjà planifié depuis l'app (à
  faire directement dans le Sheet ou le calendrier pour l'instant).
- Une ligne colorée en rose ou marquée "Joel" en colonne L, et au statut
  "Accepté", est la condition pour qu'un SAV apparaisse dans l'app — un
  changement de convention dans le Sheet sans en informer le développeur
  casserait ce filtre.

## 7. Suite possible

- Remplir la checklist de test manuel avec Joël (`RAPPORT_DE_TEST.md`).
- Selon les retours d'usage, envisager un écran de modification/annulation
  de RDV directement dans l'app.
- Étendre le même principe de monitoring/CI-CD à `rpi_qualite_app`, déjà en
  place côté SAV.

## 8. Validation

| Rédigé par | Validé par |
|---|---|
| Nom : Assistant technique (Claude) | Nom : |
| Date : 15/07/2026 | Date : |
| | Signature : |
