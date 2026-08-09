import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_input.dart';
import '../widgets/form_message.dart';
import '../widgets/primary_button.dart';

/// Step two of registration: the 6-digit code emailed by `/user/register`.
///
/// No session exists yet at this point, so this screen is public and sends the
/// user to /login once the account is active.
class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({super.key, this.email});

  /// Shown so the user knows which inbox to check. Optional: the screen works
  /// even when opened without it (e.g. a deep link).
  final String? email;

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  static const _codeLength = 6;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _service = UserService(ApiClient.instance);

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCodeChanged);
    // The code boxes are a painted view over one hidden field, so the keyboard
    // has to come up on its own for the screen to feel usable.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.removeListener(_onCodeChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _code => _controller.text;

  void _onCodeChanged() {
    setState(() => _error = null);
    if (_code.length == _codeLength && !_isLoading) _verify();
  }

  Future<void> _verify() async {
    if (_code.length != _codeLength) {
      setState(() => _error = 'Ingresa los $_codeLength dígitos del código.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await _service.verifyAccount(_code);
      if (!mounted) return;
      // The account is active but there is still no session: send them to log in.
      context.go('/login', extra: 'Cuenta verificada. Ya puedes iniciar sesión.');
    } catch (error) {
      if (!mounted) return;
      final failure = ApiClient.mapError(error);
      setState(() {
        _error = failure.kind == ApiErrorKind.validation && failure.fieldErrors.containsKey('code')
            ? failure.fieldErrors['code']
            : failure.message;
      });
      _controller.clear();
      _focusNode.requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
              ),
              const SizedBox(height: 14),
              const Text(
                'Verifica tu cuenta',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email == null
                    ? 'Ingresa el código de 6 dígitos que enviamos a tu correo.'
                    : 'Ingresa el código de 6 dígitos que enviamos a ${widget.email}.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              CodeInput(
                controller: _controller,
                focusNode: _focusNode,
                length: _codeLength,
                hasError: _error != null,
                onSubmitted: (_) => _verify(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                FormMessage(message: _error!),
              ],
              const SizedBox(height: 26),
              PrimaryButton(
                label: 'Verificar',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _verify,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'El código expira en unos minutos. Si no llega, revisa tu carpeta de spam.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
