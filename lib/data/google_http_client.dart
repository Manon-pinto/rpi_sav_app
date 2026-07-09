import 'package:http/http.dart' as http;

/// Client HTTP minimal qui ajoute le jeton OAuth de Joël à chaque requête,
/// pour être passé aux clients `googleapis` (Sheets, Calendar).
class GoogleAuthorizedClient extends http.BaseClient {
  GoogleAuthorizedClient(this._accessToken, [http.Client? inner])
    : _inner = inner ?? http.Client();

  final String _accessToken;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
