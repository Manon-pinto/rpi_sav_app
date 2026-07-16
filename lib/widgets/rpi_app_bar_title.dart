import 'package:flutter/material.dart';

/// Titre d'AppBar avec le logo RPI Menuiserie, pour garder la marque visible
/// sur tous les écrans de l'app (pas seulement la connexion/l'accueil).
class RpiAppBarTitle extends StatelessWidget {
  const RpiAppBarTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    // Le fichier source fait ~2500px et n'est affiché qu'à 32px de haut :
    // sans cacheHeight, le moteur de rendu web laisse le navigateur mettre
    // à l'échelle l'image déjà décodée en pleine résolution, ce qui rend
    // les traits fins du logo flous. En forçant le décodage à la taille
    // d'affichage réelle (en tenant compte du devicePixelRatio), le
    // rendu reste net.
    const displayHeight = 32.0;
    final cacheHeight =
        (displayHeight * MediaQuery.devicePixelRatioOf(context)).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fond clair derrière le logo : le trait du logo est noir, il
        // serait invisible directement sur la barre du haut désormais noire.
        ClipOval(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/RPI LOGO base line noir.png',
              height: displayHeight,
              cacheHeight: cacheHeight,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
