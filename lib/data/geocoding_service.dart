import 'dart:convert';

import 'package:http/http.dart' as http;

/// Coordonnées GPS résolues à partir d'une adresse en texte libre.
class GeocodedAddress {
  const GeocodedAddress({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Géocodage en texte libre via Nominatim (OpenStreetMap) — service public
/// gratuit, sans clé API, contrairement à l'API Geocoding de Google qui
/// nécessite un compte de facturation actif. À utiliser avec parcimonie
/// (une recherche par écran ouvert, jamais en boucle) pour respecter la
/// politique d'usage équitable de Nominatim.
class GeocodingService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  /// Numéros de téléphone français (fixe/mobile, avec ou sans séparateurs) —
  /// à retirer du texte avant géocodage, sinon ils polluent la recherche.
  static final _phoneRegExp = RegExp(
    r'\b0[1-9](?:[ .-]?\d{2}){4}\b',
  );

  /// Retourne `null` si l'adresse n'a pas pu être résolue (adresse trop
  /// vague, service indisponible, etc.) — non bloquant pour le reste de
  /// l'écran, la carte est juste masquée dans ce cas.
  Future<GeocodedAddress?> geocode(String address) async {
    // La colonne source mélange souvent nom du client, adresse et
    // téléphone sur une seule ligne — on retire le téléphone (bruit pur
    // pour la recherche) et on aplatit les retours à la ligne.
    final cleaned = address
        .replaceAll(_phoneRegExp, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': cleaned,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'fr',
    });

    try {
      final response = await http.get(
        uri,
        // Nominatim exige un User-Agent identifiable (pas de valeur par
        // défaut de client HTTP générique) — voir sa politique d'usage.
        headers: const {'User-Agent': 'rpi-sav-app (RPI Menuiserie)'},
      );
      if (response.statusCode != 200) return null;

      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) return null;

      return GeocodedAddress(latitude: lat, longitude: lon);
    } catch (_) {
      return null;
    }
  }
}
