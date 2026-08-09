import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../services/user_service.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/code_input.dart';
import '../../widgets/form_message.dart';
import '../../widgets/primary_button.dart';

/// Two-step email change: request a code for the new address, then confirm it.
///
/// Both steps live in one screen because the second is meaningless without the
/// first, and leaving mid-way would strand a pending change the user cannot
/// resume from anywhere else.
class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

enum _Step { requestCode, confirmCode }

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  static const _codeLength = 6;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _service = UserService(ApiClient.instance);

  _Step _step = _Step.requestCode;
  bool _isLoading = false;
  String? _emailError;
  String? _codeError;
  String? _formError;

  /// The address the code was sent to, kept for the confirmation copy.
  String? _pendingEmail;

  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _emailController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit => !_isLoading && _cooldownSeconds == 0;

  void _onCodeChanged() {
    setState(() => _codeError = null);
    if (_codeController.text.length == _codeLength && !_isLoading) _confirmCode();
  }

  // ---------------------------------------------------------------------------
  // Step 1 — request the code
  // ---------------------------------------------------------------------------

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Ingresa el correo nuevo.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Ingresa un correo válido.');
      return;
    }
    if (email.toLowerCase() == authController.profile?.email.toLowerCase()) {
      setState(() => _emailError = 'Ese ya es tu correo actual.');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
      _formError = null;
    });
    try {
      await _service.changeEmail(email);
      if (!mounted) return;
      setState(() {
        _pendingEmail = email;
        _step = _Step.confirmCode;
      });
      _codeFocus.requestFocus();
    } catch (error) {
      if (!mounted) return;
      _showFailure(ApiClient.mapError(error), onField: (message) => _emailError = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 — confirm the code
  // ---------------------------------------------------------------------------

  Future<void> _confirmCode() async {
    if (_codeController.text.length != _codeLength) {
      setState(() => _codeError = 'Ingresa los $_codeLength dígitos del código.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _codeError = null;
      _formError = null;
    });
    try {
      await _service.verifyEmailChange(_codeController.text);
      // The profile still holds the old address until we re-read it.
      await authController.refreshProfile();
      if (!mounted) return;
      context.pop('Tu correo se actualizó correctamente.');
    } catch (error) {
      if (!mounted) return;
      _showFailure(ApiClient.mapError(error), onField: (message) => _codeError = message);
      _codeController.clear();
      _codeFocus.requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Routes a failure to the field it belongs to, or to the banner otherwise.
  void _showFailure(ApiException failure, {required void Function(String) onField}) {
    switch (failure.kind) {
      case ApiErrorKind.conflict:
      case ApiErrorKind.validation:
        final fieldMessage = failure.fieldErrors['new_email'] ??
            failure.fieldErrors['email'] ??
            failure.fieldErrors['code'] ??
            failure.message;
        setState(() => onField(fieldMessage));
      case ApiErrorKind.unauthorized:
        // For the code step this means "wrong code"; a genuinely dead session
        // is handled by the client, which logs out and redirects.
        setState(() => onField(failure.message));
      case ApiErrorKind.rateLimited:
        setState(() => _formError = failure.message);
        _startCooldown(failure.retryAfter ?? const Duration(seconds: 30));
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

  /// Going back from the code step returns to the address, so a typo in the
  /// email does not mean leaving and starting over.
  void _back() {
    if (_step == _Step.confirmCode) {
      setState(() {
        _step = _Step.requestCode;
        _codeController.clear();
        _codeError = null;
        _formError = null;
      });
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isCodeStep = _step == _Step.confirmCode;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
              ),
              const SizedBox(height: 14),
              Text(
                isCodeStep ? 'Confirma el cambio' : 'Cambiar correo',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                isCodeStep
                    ? 'Ingresa el código de 6 dígitos que enviamos a $_pendingEmail.'
                    : 'Te enviaremos un código al correo nuevo para confirmar que es tuyo. '
                        'Tu correo actual es ${authController.profile?.email ?? '—'}.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              if (isCodeStep)
                CodeInput(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  length: _codeLength,
                  hasError: _codeError != null,
                  onSubmitted: (_) => _confirmCode(),
                )
              else
                AppTextField(
                  label: 'Correo nuevo',
                  hint: 'tu@correo.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _canSubmit ? _requestCode() : null,
                ),
              if (isCodeStep && _codeError != null) ...[
                const SizedBox(height: 18),
                FormMessage(message: _codeError!),
              ],
              if (_formError != null) ...[
                const SizedBox(height: 16),
                FormMessage(message: _formError!),
              ],
              const SizedBox(height: 26),
              PrimaryButton(
                label: _cooldownSeconds > 0
                    ? 'Espera ${_cooldownSeconds}s'
                    : isCodeStep
                        ? 'Confirmar'
                        : 'Enviar código',
                isLoading: _isLoading,
                onPressed: _canSubmit ? (isCodeStep ? _confirmCode : _requestCode) : null,
              ),
              if (isCodeStep) ...[
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _back,
                    child: const Text(
                      'Usar otro correo',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lavender),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
