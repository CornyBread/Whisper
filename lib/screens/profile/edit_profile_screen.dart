import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../models/user_profile.dart';
import '../../state/auth_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_message.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();

  /// Picked locally but not uploaded yet — shown as a preview until saved.
  File? _pickedImage;

  bool _isSaving = false;
  bool _isDeleting = false;
  String? _usernameError;
  String? _message;
  bool _messageIsError = true;

  @override
  void initState() {
    super.initState();
    _usernameController.text = authController.profile?.username ?? '';
    authController.addListener(_onProfileChanged);
    // The profile may be stale (or missing, if the fetch failed at startup).
    authController.refreshProfile().ignore();
  }

  @override
  void dispose() {
    authController.removeListener(_onProfileChanged);
    _usernameController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (!mounted) return;
    final username = authController.profile?.username;
    // Only adopt the server value while the user is not mid-edit, so a
    // background refresh never overwrites what they are typing.
    if (username != null && !_isSaving && _usernameController.text.isEmpty) {
      _usernameController.text = username;
    }
    setState(() {});
  }

  bool get _hasChanges {
    final profile = authController.profile;
    final typed = _usernameController.text.trim().toLowerCase();
    final usernameChanged = profile != null && typed.isNotEmpty && typed != profile.username;
    return usernameChanged || _pickedImage != null;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.lavender),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.lavender),
              title: const Text('Tomar una foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Downscaled before upload: full-resolution phone photos are several MB
      // and the server may reject them outright.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pickedImage = File(picked.path);
        _message = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = error.code == 'camera_access_denied' || error.code == 'photo_access_denied'
            ? 'Necesitamos permiso para acceder a tus fotos o cámara.'
            : 'No pudimos abrir el selector de imágenes.';
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final profile = authController.profile;
    if (profile == null) return;

    final typed = _usernameController.text.trim();
    if (typed.isEmpty) {
      setState(() => _usernameError = 'El nombre de usuario no puede quedar vacío.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(typed)) {
      setState(() => _usernameError = 'Solo se permiten letras y números.');
      return;
    }
    if (!_hasChanges) {
      setState(() {
        _messageIsError = false;
        _message = 'No hay cambios que guardar.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _usernameError = null;
      _message = null;
    });
    try {
      await authController.updateProfile(
        // Omitted when unchanged, so we never collide with our own username.
        newUsername: typed.toLowerCase() == profile.username ? null : typed,
        image: _pickedImage,
      );
      if (!mounted) return;
      setState(() {
        _pickedImage = null;
        _messageIsError = false;
        _message = 'Perfil actualizado.';
      });
    } catch (error) {
      if (!mounted) return;
      final failure = ApiClient.mapError(error);
      setState(() {
        if (failure.kind == ApiErrorKind.conflict) {
          _usernameError = failure.message;
        } else {
          _usernameError = failure.fieldErrors['new_username'] ?? failure.fieldErrors['username'];
          if (_usernameError == null) {
            _messageIsError = true;
            _message = failure.message;
          }
        }
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openChangeEmail() async {
    final result = await context.push<String>('/change-email');
    if (!mounted || result == null) return;
    setState(() {
      _messageIsError = false;
      _message = result;
    });
  }

  Future<void> _confirmLogout() async {
    final confirmed = await _confirm(
      title: 'Cerrar sesión',
      body: '¿Seguro que quieres cerrar sesión?',
      action: 'Cerrar sesión',
    );
    if (confirmed != true) return;
    // `logout` clears the local cookies even if the call fails, and the
    // router's redirect takes us back to /login once the status flips.
    await authController.logout();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await _confirm(
      title: 'Eliminar cuenta',
      body: 'Esta acción es permanente: se borrará tu cuenta y se cerrará tu sesión. '
          'No podrás recuperarla.',
      action: 'Eliminar cuenta',
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await authController.deleteAccount();
      // Success takes us to /login via the router; nothing to show here.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = ApiClient.mapError(error).message;
      });
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<bool?> _confirm({required String title, required String body, required String action}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title),
        content: Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action, style: const TextStyle(color: AppColors.rose)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = authController.profile;

    return Scaffold(
      body: SafeArea(
        child: profile == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.lavender))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Editar perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                        FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.lavender,
                            disabledBackgroundColor: AppColors.lavender.withValues(alpha: 0.4),
                            foregroundColor: AppColors.panel,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.panel),
                                )
                              : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                _ProfilePicture(profile: profile, pickedImage: _pickedImage, size: 96),
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
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Text(
                              _pickedImage == null ? 'Cambiar foto' : 'Foto lista, pulsa Guardar',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lavender),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Nombre de usuario',
                      controller: _usernameController,
                      errorText: _usernameError,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                    ),
                    const SizedBox(height: 14),
                    // Not editable in place: changing an email needs the
                    // two-step verification flow on its own screen.
                    _EmailRow(email: profile.email, onChange: _openChangeEmail),
                    if (!profile.isActive) ...[
                      const SizedBox(height: 16),
                      const FormMessage(
                        message: 'Tu cuenta aún no está verificada. Revisa el código que enviamos a tu correo.',
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      FormMessage(message: _message!, isError: _messageIsError),
                    ],
                    const SizedBox(height: 22),
                    _DangerTile(
                      icon: Icons.logout,
                      label: 'Cerrar sesión',
                      onTap: _confirmLogout,
                    ),
                    const SizedBox(height: 12),
                    _DangerTile(
                      icon: Icons.delete_outline,
                      label: 'Eliminar cuenta',
                      isLoading: _isDeleting,
                      onTap: _confirmDelete,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The uploaded picture, the locally picked one, or initials as a fallback.
class _ProfilePicture extends StatelessWidget {
  const _ProfilePicture({required this.profile, required this.pickedImage, required this.size});

  final UserProfile profile;
  final File? pickedImage;
  final double size;

  @override
  Widget build(BuildContext context) {
    final remoteUrl = profile.absoluteProfilePictureUrl;

    Widget child;
    if (pickedImage != null) {
      child = Image.file(pickedImage!, width: size, height: size, fit: BoxFit.cover);
    } else if (remoteUrl != null) {
      child = Image.network(
        remoteUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A broken or unreachable upload must not blow up the whole screen.
        errorBuilder: (context, error, stackTrace) => _Initials(profile: profile, size: size),
      );
    } else {
      child = _Initials(profile: profile, size: size);
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.profile, required this.size});

  final UserProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.lavender,
      alignment: Alignment.center,
      child: Text(
        profile.initials,
        style: TextStyle(color: AppColors.panel, fontWeight: FontWeight.w700, fontSize: size * 0.34),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isLoading
              ? const [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rose)),
                ]
              : [
                  Icon(icon, size: 18, color: AppColors.rose),
                  const SizedBox(width: 9),
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.rose)),
                ],
        ),
      ),
    );
  }
}

/// The current email plus the entry point to the two-step change flow.
class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email, required this.onChange});

  final String email;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 7),
          child: Text(
            'Correo electrónico',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.fromLTRB(18, 4, 8, 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              TextButton(
                onPressed: onChange,
                child: const Text(
                  'Cambiar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lavender),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
