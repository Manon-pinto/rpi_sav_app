import 'package:flutter/material.dart';

import '../data/firebase_auth_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});

  final FirebaseAuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authService.signInWithGoogleWorkspace();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo premiere page.png',
                  height: 96,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 96,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'RPI SAV',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Planification des interventions SAV',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _loading ? 'Connexion en cours…' : 'Se connecter avec Google',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
