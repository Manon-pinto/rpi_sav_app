import 'package:flutter/material.dart';

/// Titre d'AppBar avec le logo RPI Menuiserie, pour garder la marque visible
/// sur tous les écrans de l'app (pas seulement la connexion/l'accueil).
class RpiAppBarTitle extends StatelessWidget {
  const RpiAppBarTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/RPI LOGO base line noir.png',
          height: 32,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
