import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/form_message.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = UserService(ApiClient.instance);

  bool _isLoading = false;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isLoading && _cooldownSeconds == 0;

  /// Mirrors the documented server rules so a bad payload never costs a
  /// request (registration is rate limited).
  bool _validate() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? usernameError;
    if (username.isEmpty) {
      usernameError = 'Elige un nombre de usuario.';
    } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(username)) {
      usernameError = 'Solo se permiten letras y números, sin espacios ni símbolos.';
    }

    String? emailError;
    if (email.isEmpty) {
      emailError = 'Ingresa tu correo electrónico.';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emailError = 'Ingresa un correo válido.';
    }

    setState(() {
      _usernameError = usernameError;
      _emailError = emailError;
      _passwordError = password.isEmpty ? 'Elige una contraseña.' : null;
      _formError = null;
    });

    return usernameError == null && emailError == null && _passwordError == null;
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    try {
      await _service.register(
        username: _usernameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );
      if (!mounted) return;
      // The account exists but is inactive until the emailed code is entered.
      context.go('/verify-account', extra: email);
    } catch (error) {
      if (!mounted) return;
      _showError(ApiClient.mapError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(ApiException failure) {
    final username = failure.fieldErrors['username'];
    final email = failure.fieldErrors['email'];
    final password = failure.fieldErrors['password'];

    switch (failure.kind) {
      case ApiErrorKind.conflict:
        // 409 does not say which one collided, so flag both fields and let the
        // banner carry the explanation.
        setState(() {
          _usernameError = username;
          _emailError = email;
          _formError = username == null && email == null ? failure.message : null;
        });
      case ApiErrorKind.validation:
        setState(() {
          _usernameError = username;
          _emailError = email;
          _passwordError = password;
          _formError = username == null && email == null && password == null ? failure.message : null;
        });
      case ApiErrorKind.rateLimited:
        setState(() => _formError = failure.message);
        _startCooldown(failure.retryAfter ?? const Duration(seconds: 30));
      case ApiErrorKind.unauthorized:
      case ApiErrorKind.notFound:
      case ApiErrorKind.forbidden:
      case ApiErrorKind.server:
      case ApiErrorKind.network:
      case ApiErrorKind.unknown:
        setState(() => _formError = failure.message);
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
          padding: const EdgeInsets.fromLTRB(30, 12, 30, 20),
          // Everything shares one centred axis, the way the login screen does.
          // The previous layout mixed a left-aligned header with a centred
          // footer, which left the shrink-wrapped button stranded on the left.
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
                ),
              ),
              // A smaller echo of the login mark, so the two screens read as
              // one flow instead of two unrelated forms.
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(top: 4, bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: const LinearGradient(
                    colors: [AppColors.lavender, AppColors.mint],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.panel, size: 32),
              ),
              const Text(
                'Crear cuenta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 7),
              const Text(
                'Únete a Whisper',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 34),
              AppTextField(
                label: 'Nombre de usuario',
                hint: 'camilatorres',
                controller: _usernameController,
                errorText: _usernameError,
                // The server only accepts alphanumerics and lowercases them,
                // so reject the rest at the keyboard instead of after a 422.
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Contraseña',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: true,
                errorText: _passwordError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _canSubmit ? _register() : null,
              ),
              if (_formError != null) ...[
                const SizedBox(height: 16),
                FormMessage(message: _formError!),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: _cooldownSeconds > 0 ? 'Espera ${_cooldownSeconds}s' : 'Crear cuenta',
                isLoading: _isLoading,
                onPressed: _canSubmit ? _register : null,
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.6),
                    children: [
                      TextSpan(text: 'Al registrarte aceptas los '),
                      TextSpan(text: 'Términos', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w600)),
                      TextSpan(text: ' y la '),
                      TextSpan(text: 'Política de privacidad', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w600)),
                      TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 34),
              GestureDetector(
                onTap: () => context.pop(),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    children: [
                      TextSpan(text: '¿Ya tienes cuenta? '),
                      TextSpan(text: 'Inicia sesión', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700)),
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
