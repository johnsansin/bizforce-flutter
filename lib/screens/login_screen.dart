import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_config.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import 'register_screen.dart';

/// Login screen: branded gradient header with the BizForce CRM logo, a clean
/// email/password card and a Register link. Walks the real backend at
/// Authenticates only against the application backend. No social, OTP, SAML,
/// demo, or offline authentication is exposed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _keepSignedIn = true;
  final bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your work email address');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Please enter your password');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      final user =
          await appState.api.login(email: email, password: _password.text);
      if (!mounted) return;
      setState(() => _busy = false);
      await appState.signIn(
          user: user, email: email, keepSignedIn: _keepSignedIn);
      await appState.refreshProfile();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message.isEmpty ? 'Unable to sign in' : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Unable to reach the server. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3E79), AppColors.primary, Color(0xFF2D7BD8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/bizforce_icon.png',
                      width: 96,
                      height: 96,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'BizForce CRM',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Manage your customers, deals and team — from anywhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5, color: Colors.white70, height: 1.4),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Work email address',
                          labelStyle: const TextStyle(fontSize: 15),
                          filled: true,
                          fillColor: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.6),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(fontSize: 15),
                          filled: true,
                          fillColor: Theme.of(context)
                              .scaffoldBackgroundColor
                              .withOpacity(0.6),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.6),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.danger, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Checkbox(
                            value: _keepSignedIn,
                            activeColor: AppColors.primary,
                            onChanged: (v) =>
                                setState(() => _keepSignedIn = v ?? true),
                          ),
                          const Expanded(
                              child: Text('Keep me signed in',
                                  style: TextStyle(fontSize: 14))),
                          TextButton(
                            onPressed: () async {
                              final appState = context.read<AppState>();
                              try {
                                setState(() => _busy = true);
                                await appState.api.request(
                                    '/auth/forgot-password',
                                    method: ApiMethod.post,
                                    auth: false,
                                    body: {'email': _email.text.trim()});
                                if (!mounted) return;
                                setState(() {
                                  _busy = false;
                                  _error =
                                      'If this account exists, a password reset link was sent.';
                                });
                              } catch (e) {
                                if (!mounted) return;
                                setState(() {
                                  _busy = false;
                                  _error = e is ApiException
                                      ? e.message
                                      : 'Could not send reset link.';
                                });
                              }
                            },
                            child: const Text('Forgot Password?',
                                style: TextStyle(
                                    fontSize: 14, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _busy
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : FilledButton(
                              onPressed: _signIn,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Sign in',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                          fontSize: 14, color: Colors.white.withOpacity(0.85)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()));
                      },
                      child: const Text(
                        'Register',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'BizForce CRM v${AppConfig.appVersion}',
                    style: TextStyle(fontSize: 11.5, color: Colors.white54),
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
