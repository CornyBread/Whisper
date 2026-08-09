import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../state/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_message.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.notice});

  /// One-off confirmation to show on arrival, e.g. after verifying an account.
  /// Cleared as soon as the user starts typing.
  final String? notice;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;

  /// Inline errors under each field (client-side rules + server 422).
  String? _identityError;
  String? _passwordError;

  /// Banner shown above the button for whole-form failures (401 / 429 / 5xx).
  String? _formError;

  late String? _notice = widget.notice;

  /// Seconds left of a 429 cool-down; the button stays disabled meanwhile.
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _identityController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isLoading && _cooldownSeconds == 0;

  /// Cheap local checks so we don't spend a request (or a rate-limit slot) on
  /// a payload the server would reject with 422 anyway.
  bool _validate() {
    final identity = _identityController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _identityError = identity.isEmpty ? 'Ingresa tu usuario o correo.' : null;
      _passwordError = password.isEmpty ? 'Ingresa tu contraseña.' : null;
      _formError = null;
      _notice = null;
    });

    return _identityError == null && _passwordError == null;
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    try {
      await authController.login(
        identity: _identityController.text.trim(),
        password: _passwordController.text,
      );
      // Success: the router's redirect sends us to /chats on its own.
    } catch (error) {
      if (!mounted) return;
      _showError(ApiClient.mapError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(ApiException error) {
    switch (error.kind) {
      case ApiErrorKind.validation:
        // 422: attach whatever the server flagged to its field, and keep any
        // leftover message as the form-level banner.
        final identityError = error.fieldErrors['identity'] ?? error.fieldErrors['email'];
        final passwordError = error.fieldErrors['password'];
        setState(() {
          _identityError = identityError;
          _passwordError = passwordError;
          _formError = identityError == null && passwordError == null ? error.message : null;
        });
      case ApiErrorKind.unauthorized:
        // Never reveal which of the two was wrong.
        setState(() {
          _identityError = null;
          _passwordError = null;
          _formError = error.message;
        });
        _passwordController.clear();
        _passwordFocus.requestFocus();
      case ApiErrorKind.rateLimited:
        setState(() => _formError = error.message);
        _startCooldown(error.retryAfter ?? const Duration(seconds: 30));
      case ApiErrorKind.conflict:
      case ApiErrorKind.notFound:
      case ApiErrorKind.forbidden:
      case ApiErrorKind.server:
      case ApiErrorKind.network:
      case ApiErrorKind.unknown:
        setState(() => _formError = error.message);
    }
  }

  void _startCooldown(Duration duration) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = duration.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 36, 30, 20),
          child: Column(
            children: [
              Container(
                width: 82,
                height: 82,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [AppColors.lavender, AppColors.mint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.panel, size: 44),
              ),
              const Text('Whisper', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 8),
              const Text('Conversaciones que fluyen', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 40),
              AppTextField(
                label: 'Usuario o correo',
                hint: 'alicesmith o tu@correo.com',
                controller: _identityController,
                keyboardType: TextInputType.emailAddress,
                errorText: _identityError,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Contraseña',
                hint: '••••••••',
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _canSubmit ? _login() : null,
              ),
              if (_notice != null) ...[
                const SizedBox(height: 16),
                FormMessage(message: _notice!, isError: false),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 16),
                FormMessage(message: _formError!),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: _cooldownSeconds > 0 ? 'Espera ${_cooldownSeconds}s' : 'Iniciar sesión',
                isLoading: _isLoading,
                onPressed: _canSubmit ? _login : null,
              ),
              const SizedBox(height: 26),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('o continúa con', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  // TODO: wire up the /auth/google and /auth/github flows.
                  Expanded(child: _OAuthButton(label: 'Google', icon: Icons.g_mobiledata, onPressed: () {})),
                  const SizedBox(width: 12),
                  Expanded(child: _OAuthButton(label: 'GitHub', icon: Icons.code, onPressed: () {})),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: '¿No tienes cuenta? '),
                      TextSpan(text: 'Regístrate', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
        ),
        icon: Icon(icon, size: 18, color: AppColors.textPrimary),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    );
  }
}
