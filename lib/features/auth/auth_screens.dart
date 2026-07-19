import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/auth_service.dart';
import '../../theme/cozy_colors.dart';
import '../../theme/cozy_spacing.dart';
import '../../theme/cozy_typography.dart';
import '../../widgets/gradient_button.dart';

/// Pantalla de login (email + password). Al éxito, `authStateChanges` de
/// Firebase dispara el rebuild del [AuthGate] y navega a la siguiente
/// pantalla (Pair o HomeShell según el estado del perfil).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  String? _errorText;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await _auth.signInWithEmail(
        email: _emailCtl.text,
        password: _passwordCtl.text,
      );
      // No hacemos push — el AuthGate detecta el cambio de sesión.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _mapAuthError(e.code, context.l10n));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = context.l10n.authGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReset() async {
    final l = context.l10n;
    final email = _emailCtl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorText = l.authInvalidEmail);
      return;
    }
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.authResetSent)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _mapAuthError(e.code, l));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: CozyColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CozySpacing.stackGapMd),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthHeader(subtitle: l.authWelcomeBody),
                  const SizedBox(height: CozySpacing.stackGapLg),
                  Text(l.authLoginTitle, style: CozyTypography.headlineMd),
                  const SizedBox(height: CozySpacing.stackGapMd),
                  TextFormField(
                    controller: _emailCtl,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.authRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtl,
                    autofillHints: const [AutofillHints.password],
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l.authPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? l.authRequired : null,
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: CozyTypography.labelMd.copyWith(
                        color: CozyColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(
                    label: l.authLoginBtn,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : _sendReset,
                    child: Text(l.authForgotPassword),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.authNoAccount,
                        style: CozyTypography.bodyMd.copyWith(
                          color: CozyColors.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SignUpScreen(),
                                ),
                              ),
                        child: Text(l.authGoToSignUp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla de creación de cuenta. Al éxito, se crea el user en Auth +
/// el doc `users/{uid}` en Firestore y el [AuthGate] avanza a la
/// pantalla de emparejamiento.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _auth = AuthService();
  bool _busy = false;
  String? _errorText;
  bool _showPassword = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      await _auth.signUpWithEmail(
        email: _emailCtl.text,
        password: _passwordCtl.text,
        displayName: _nameCtl.text,
      );
      // Firebase Auth ya emitió el nuevo usuario → AuthGate cambió a
      // PairCoupleScreen. Necesitamos pop-ear SignUpScreen del Navigator
      // para que se vea el nuevo widget subyacente. Si el widget ya no
      // está en el árbol (más de una route pop-eada), Navigator.pop es
      // no-op cuando `canPop() == false`.
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (nav.canPop()) nav.pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = _mapAuthError(e.code, context.l10n));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = context.l10n.authGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: CozyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: CozyColors.onSurface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(CozySpacing.stackGapMd),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AuthHeader(subtitle: l.authWelcomeBody),
                  const SizedBox(height: CozySpacing.stackGapLg),
                  Text(l.authSignUpTitle, style: CozyTypography.headlineMd),
                  const SizedBox(height: CozySpacing.stackGapMd),
                  TextFormField(
                    controller: _nameCtl,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                    decoration: InputDecoration(
                      labelText: l.authDisplayName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.authRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l.authEmail,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l.authRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtl,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l.authPassword,
                      helperText: l.authPasswordShort,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return l.authRequired;
                      if (v.length < 6) return l.authPasswordShort;
                      return null;
                    },
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: CozyTypography.labelMd.copyWith(
                        color: CozyColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  GradientButton(
                    label: l.authSignUpBtn,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.authHasAccount,
                        style: CozyTypography.bodyMd.copyWith(
                          color: CozyColors.onSurfaceVariant,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l.authGoToLogin),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header con logo + tagline reutilizado por Login y SignUp.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CozyColors.primaryContainer,
                CozyColors.secondaryContainer,
              ],
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.favorite,
            color: CozyColors.primary,
            size: 42,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.appName,
          style: CozyTypography.headlineLgMobile.copyWith(
            color: CozyColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: CozyTypography.bodyMd.copyWith(
            color: CozyColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Traduce el `code` de un [FirebaseAuthException] al string localizado.
String _mapAuthError(String code, AppStrings l) {
  switch (code) {
    case 'invalid-email':
      return l.authInvalidEmail;
    case 'user-disabled':
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return l.authInvalidCredentials;
    case 'email-already-in-use':
      return l.authEmailInUse;
    case 'weak-password':
      return l.authWeakPassword;
    default:
      return l.authGenericError;
  }
}
