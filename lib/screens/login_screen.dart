import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    setState(() => _isLoading = true);
    // TODO: connect to the real auth endpoint.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/chats');
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
              AppTextField(label: 'Correo electrónico', hint: 'tu@correo.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              AppTextField(label: 'Contraseña', hint: '••••••••', controller: _passwordController, obscureText: true),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Iniciar sesión', isLoading: _isLoading, onPressed: _login),
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
