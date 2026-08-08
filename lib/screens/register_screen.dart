import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    setState(() => _isLoading = true);
    // TODO: connect to the real registration endpoint.
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
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
                  ),
                  const SizedBox(width: 2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Crear cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                      SizedBox(height: 3),
                      Text('Únete a Whisper', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              AppTextField(label: 'Nombre completo', hint: 'Camila Torres', controller: _nameController),
              const SizedBox(height: 14),
              AppTextField(label: 'Nombre de usuario', hint: '@camila.t', controller: _usernameController),
              const SizedBox(height: 14),
              AppTextField(label: 'Correo electrónico', hint: 'tu@correo.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              AppTextField(label: 'Contraseña', hint: '••••••••', controller: _passwordController, obscureText: true),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Crear cuenta', isLoading: _isLoading, onPressed: _register),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
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
              const SizedBox(height: 30),
              Center(
                child: GestureDetector(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
