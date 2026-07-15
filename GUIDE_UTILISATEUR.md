RPI MENUISERIE

# RPI SAV — Guide d'utilisation

*Comment planifier une intervention SAV depuis l'application, sans double
saisie dans le Sheet et le calendrier.*

**Adresse de l'application** : https://rpi-sav-app.web.app
(à mettre en favori dans ton navigateur, ou à "ajouter à l'écran d'accueil"
sur téléphone)

---

## 1. Qui peut utiliser l'application ?

Uniquement les comptes Google autorisés nommément :
- `cyril.chaumeil@rpimenuiserie.com`
- `joel.pouvereau@rpimenuiserie.com`
- `admin@rpimenuiserie.com`

Si tu te connectes avec un autre compte, l'application refuse l'accès avec
un message d'erreur.

## 2. Se connecter

1. Ouvre https://rpi-sav-app.web.app
2. Clique sur **"Se connecter avec Google"**
3. Choisis ton compte `@rpimenuiserie.com` autorisé
4. Tu arrives sur le **tableau de bord**

Une fois connecté, tu n'as pas besoin de te reconnecter à chaque action —
la session reste active environ 50 minutes en continu.

## 3. Le tableau de bord

Il affiche :
- Le nombre de SAV **à planifier** (acceptés par Cyril, assignés à Joël,
  pas encore clôturés, sans date/heure déjà fixée)
- Le nombre de chantiers concernés
- Un aperçu des 3 premiers SAV à planifier

Clique sur **"Voir tout"** pour la liste complète, ou tire vers le bas pour
rafraîchir les données depuis le Sheet.

## 4. Planifier une intervention

1. Depuis la liste, clique sur le SAV à planifier
2. Tu vois en lecture seule : l'intervention à réaliser, les fournitures à
   livrer, les infos du client final
3. Remplis :
   - **Durée prévue** (liste déroulante ou texte libre selon le Sheet)
   - **Véhicule**
   - **Renfort** (nombre de personnes, si besoin)
   - **Date** et **Heure** du rendez-vous
4. Clique sur **"Confirmer"**

➡️ Le Google Sheet est mis à jour immédiatement.
➡️ Le rendez-vous apparaît dans le calendrier de Joël **automatiquement**,
sous quelques minutes (pas besoin de le créer soi-même).

### Si tu ne connais pas encore la date/l'heure

Tu peux enregistrer uniquement la durée/le véhicule/le renfort, **sans**
choisir de date ni d'heure : le bouton devient **"Enregistrer sans
rendez-vous"**. Le SAV reste dans la liste "à planifier" jusqu'à ce qu'une
date soit fixée plus tard.

Tu peux aussi renseigner la date **seule** un jour, puis revenir compléter
l'heure plus tard (ou l'inverse) — rien n'est effacé entre les deux étapes.

## 5. Créneaux qui se chevauchent

Si le créneau choisi entre en conflit avec un rendez-vous déjà existant
dans le calendrier de Joël, le rendez-vous **n'est pas créé
automatiquement** pour éviter d'écraser l'existant. Dans ce cas, il faut
choisir un autre créneau ou vérifier directement dans le calendrier.

## 6. Se déconnecter

Icône de déconnexion en haut à droite de l'écran.

## 7. Problèmes fréquents

| Symptôme | Que faire |
|---|---|
| "Ce compte Google n'est pas autorisé" | Vérifie que tu utilises bien un des 3 comptes listés en section 1 |
| Un SAV planifié n'apparaît pas dans le calendrier | Attends jusqu'à 10 minutes (synchronisation automatique) ; si toujours rien après, contacte l'admin |
| La page semble bloquée ou affiche une erreur | Recharge la page (Cmd+Maj+R sur Mac) ; si ça persiste, contacte l'admin |
| Un SAV que tu attends n'apparaît pas dans la liste | Vérifie dans le Sheet qu'il est bien au statut "Accepté", assigné à Joël (ligne rose ou "Joel" en colonne L), et pas déjà clôturé ou déjà planifié |

## 8. Contact

En cas de problème persistant, contacte l'admin — un écran de suivi des
erreurs techniques est disponible pour lui (icône 🐛 visible uniquement sur
son compte), qui l'aide à diagnostiquer sans devoir te redemander les
détails.
