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

  /// Retourne `null` si l'adresse n'a pas pu être résolue (adresse trop
  /// vague, service indisponible, etc.) — non bloquant pour le reste de
  /// l'écran, la carte est juste masquée dans ce cas.
  Future<GeocodedAddress?> geocode(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': trimmed,
      'format': 'json',
      'limit': '1',
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
