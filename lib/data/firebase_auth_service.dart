import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import 'allowed_accounts_service.dart';
import 'app_config.dart';

/// Authentification Google Workspace pour Joël, avec les scopes Sheets et
/// Calendar nécessaires à la planification des interventions SAV.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInit;

  // Les jetons d'accès Google (Sheets/Calendar) sont valables environ 1h.
  // Sans ce cache, chaque appel à requestDataAccessToken() rouvrait une
  // popup de connexion complète — l'équipe devait se reconnecter à chaque
  // action dans l'app.
  String? _cachedAccessToken;
  DateTime? _cachedAccessTokenExpiry;

  /// Scopes nécessaires pour lire/écrire le Sheet "SAV diffus" et créer des
  /// événements sur le Google Calendar de Joël.
  static const workspaceDataScopes = <String>[
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/calendar.events',
  ];

  static const _workspaceSignInScopes = <String>['email'];

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogleWorkspace() async {
    if (kIsWeb) {
      final provider = _workspaceProvider(includeDataScopes: true);
      final credential = await _auth.signInWithPopup(provider);
      await _ensureWorkspaceAccount(credential.user?.email);
      return;
    }

    try {
      await _ensureGoogleSignInInitialized();
      var account = await _googleSignIn.attemptLightweightAuthentication();
      if (account == null && !_googleSignIn.supportsAuthenticate()) {
        throw FirebaseAuthException(
          code: 'google-sign-in-unsupported',
          message: "Google Sign-In interactif n'est pas disponible ici.",
        );
      }

      account ??= await _googleSignIn.authenticate(
        scopeHint: _workspaceSignInScopes,
      );
      final email = account.email.trim().toLowerCase();
      if (!await _isAllowedEmail(email)) {
        await _googleSignIn.signOut();
        throw FirebaseAuthException(
          code: 'unauthorized-account',
          message: 'Ce compte Google n\'est pas autorisé sur cette application.',
        );
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-token',
          message: 'Google ne renvoie pas de jeton de connexion valide.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      await _ensureWorkspaceAccount(email);

      // Demande immédiatement les scopes Sheets/Calendar (nécessaires dès le
      // premier écran) pour éviter un aller-retour de consentement plus tard.
      await account.authorizationClient.authorizationHeaders(
        workspaceDataScopes,
        promptIfNecessary: true,
      );
    } on GoogleSignInException catch (error) {
      throw FirebaseAuthException(
        code: error.code.name,
        message: error.description ?? error.toString(),
      );
    } on PlatformException catch (error) {
      throw FirebaseAuthException(
        code: error.code,
        message: error.message ?? error.toString(),
      );
    }
  }

  /// Access token OAuth avec les scopes Sheets + Calendar, utilisé pour
  /// appeler directement les API Google depuis [GoogleSheetsService] et
  /// [GoogleCalendarService]. Mis en cache ~50 min (durée de vie réelle
  /// ~1h) pour éviter de redemander une connexion à chaque action.
  Future<String> requestDataAccessToken() async {
    final cachedToken = _cachedAccessToken;
    final cachedExpiry = _cachedAccessTokenExpiry;
    if (cachedToken != null &&
        cachedExpiry != null &&
        DateTime.now().isBefore(cachedExpiry)) {
      return cachedToken;
    }

    final token = await _fetchFreshDataAccessToken();
    _cachedAccessToken = token;
    _cachedAccessTokenExpiry = DateTime.now().add(const Duration(minutes: 50));
    return token;
  }

  Future<String> _fetchFreshDataAccessToken() async {
    if (kIsWeb) {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-signed-in',
          message: "Connectez-vous d'abord avec Google Workspace.",
        );
      }
      final credential = await user.reauthenticateWithPopup(
        _workspaceProvider(includeDataScopes: true),
      );
      final token = credential.credential is OAuthCredential
          ? (credential.credential as OAuthCredential).accessToken
          : null;
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-access-token',
          message: "Google n'a pas renvoyé de jeton d'accès Sheets/Calendar.",
        );
      }
      return token;
    }

    await _ensureGoogleSignInInitialized();
    var account = await _googleSignIn.attemptLightweightAuthentication();
    account ??= await _googleSignIn.authenticate(
      scopeHint: _workspaceSignInScopes,
    );
    final headers = await account.authorizationClient.authorizationHeaders(
      workspaceDataScopes,
      promptIfNecessary: true,
    );
    final authorization = headers?['Authorization'];
    if (authorization == null || authorization.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-access-token',
        message: "Google n'a pas accordé les droits Sheets/Calendar.",
      );
    }
    return authorization.replaceFirst('Bearer ', '');
  }

  Future<void> signOut() async {
    _cachedAccessToken = null;
    _cachedAccessTokenExpiry = null;
    if (!kIsWeb) {
      try {
        await _ensureGoogleSignInInitialized();
        await _googleSignIn.signOut();
      } catch (_) {
        // Le nettoyage natif peut échouer sans bloquer la déconnexion Firebase.
      }
    }
    await _auth.signOut();
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInit ??= _googleSignIn.initialize(
      clientId: _googleClientId(),
    );
  }

  GoogleAuthProvider _workspaceProvider({bool includeDataScopes = false}) {
    final provider = GoogleAuthProvider();
    for (final scope in _workspaceSignInScopes) {
      provider.addScope(scope);
    }
    if (includeDataScopes) {
      for (final scope in workspaceDataScopes) {
        provider.addScope(scope);
      }
    }
    return provider;
  }

  Future<void> _ensureWorkspaceAccount(String? rawEmail) async {
    final email = rawEmail?.trim().toLowerCase() ?? '';
    if (await _isAllowedEmail(email)) return;
    await _auth.signOut();
    throw FirebaseAuthException(
      code: 'unauthorized-account',
      message: 'Ce compte Google n\'est pas autorisé sur cette application.',
    );
  }

  /// Autorisé si le compte fait partie des 3 comptes de base ([kAllowedEmails],
  /// fixés dans le code) ou de la liste additionnelle gérée depuis l'écran
  /// admin ([AllowedAccountsService]). Le second appel Firestore n'a lieu
  /// que si le compte n'est pas déjà dans la liste de base, pour ne pas
  /// ralentir la connexion des comptes usuels.
  Future<bool> _isAllowedEmail(String email) async {
    if (kAllowedEmails.contains(email)) return true;
    try {
      final extra = await AllowedAccountsService.fetchExtraEmails();
      return extra.contains(email);
    } catch (_) {
      // Si Firestore est injoignable, on ne bloque pas les comptes de base
      // mais on refuse les comptes additionnels par prudence.
      return false;
    }
  }

  String? _googleClientId() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return DefaultFirebaseOptions.currentPlatform.iosClientId;
    }
    return null;
  }
}
