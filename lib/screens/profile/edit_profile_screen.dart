import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final _nameController = TextEditingController(text: currentUser.name);
  late final _usernameController = TextEditingController(text: currentUser.username);
  late final _emailController = TextEditingController(text: currentUser.email);
  late final _bioController = TextEditingController(text: currentUser.bio);

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Cerrar sesión', style: TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Editar perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                  FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      foregroundColor: AppColors.panel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        UserAvatar(user: currentUser, size: 96),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.lavender,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 3),
                            ),
                            child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.panel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Cambiar foto', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lavender)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(label: 'Nombre', controller: _nameController),
              const SizedBox(height: 14),
              AppTextField(label: 'Nombre de usuario', controller: _usernameController),
              const SizedBox(height: 14),
              AppTextField(label: 'Correo electrónico', controller: _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              AppTextField(label: 'Descripción', controller: _bioController, maxLines: 4, minLines: 3),
              const SizedBox(height: 22),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _confirmLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, size: 18, color: AppColors.rose),
                      SizedBox(width: 9),
                      Text('Cerrar sesión', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.rose)),
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
