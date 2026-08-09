import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../models/user_summary.dart';
import '../../services/friend_requests_service.dart';
import '../../services/people_service.dart';
import '../../state/requests_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/remote_avatar.dart';

/// `GET /users` — people you can still befriend, with a send-request action.
///
/// Paging state lives here rather than in a controller: nothing outside this
/// screen needs the stranger list, and it should start fresh on every visit.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _people = PeopleService(ApiClient.instance);
  final _requests = FriendRequestsService(ApiClient.instance);
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final List<UserSummary> _users = [];

  /// Ids already requested in this session, so the row shows "Enviada" without
  /// waiting for a refetch that would drop them from the list anyway.
  final Set<String> _sentTo = {};
  final Set<String> _sending = {};

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() => setState(() {}));
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Prefetch a screen ahead so scrolling does not visibly stall.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _people.fetchUsers(offset: _users.length);
      if (!mounted) return;
      setState(() {
        _users.addAll(page.users);
        // A short page means the server has nothing left to give.
        _hasMore = page.users.length >= page.limit;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiClient.mapError(error).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _users.clear();
      _sentTo.clear();
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _send(UserSummary user) async {
    setState(() => _sending.add(user.id));
    try {
      final message = await _requests.sendTo(user.id);
      if (!mounted) return;
      setState(() => _sentTo.add(user.id));
      // Keep the "Enviadas" tab honest without forcing a full reload there.
      requestsController.refreshSent();
      _showSnack(message, isError: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack(ApiClient.mapError(error).message, isError: true);
    } finally {
      if (mounted) setState(() => _sending.remove(user.id));
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            message,
            style: TextStyle(
              color: isError ? AppColors.rose : AppColors.mint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  /// Local filter over what is already loaded — `/users` has no search param,
  /// so this deliberately does not hit the network.
  List<UserSummary> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users.where((user) => user.username.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.lavender),
                  ),
                  const Text(
                    'Buscar personas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Filtrar por nombre de usuario',
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: _searchController.clear,
                        child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody(visible)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<UserSummary> visible) {
    if (_users.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lavender));
    }

    if (_users.isEmpty && _error != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar la lista',
        subtitle: _error!,
        actionLabel: 'Reintentar',
        onAction: _loadMore,
      );
    }

    if (visible.isEmpty) {
      final searching = _searchController.text.trim().isNotEmpty;
      return _Message(
        icon: searching ? Icons.search_off : Icons.groups_outlined,
        title: searching ? 'Sin resultados' : 'No hay nadie por agregar',
        subtitle: searching
            ? 'Nadie de la lista cargada coincide con tu búsqueda.'
            : 'Ya estás conectado con todas las personas disponibles.',
      );
    }

    return RefreshIndicator(
      color: AppColors.lavender,
      backgroundColor: AppColors.card,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        // One extra row for the paging spinner / end-of-list footer.
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == visible.length) return _buildFooter();
          final user = visible[index];
          return _PersonCard(
            user: user,
            isSending: _sending.contains(user.id),
            isSent: _sentTo.contains(user.id),
            onSend: () => _send(user),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(color: AppColors.lavender)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: TextButton(
            onPressed: _loadMore,
            child: const Text('Reintentar', style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.user,
    required this.isSending,
    required this.isSent,
    required this.onSend,
  });

  final UserSummary user;
  final bool isSending;
  final bool isSent;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          RemoteAvatar(
            initials: user.initials,
            imageUrl: user.absoluteProfilePictureUrl,
            size: 48,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              user.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          if (isSent)
            const Row(
              children: [
                Icon(Icons.check, size: 16, color: AppColors.mint),
                SizedBox(width: 5),
                Text('Enviada', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.mint)),
              ],
            )
          else
            FilledButton(
              onPressed: isSending ? null : onSend,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lavender,
                disabledBackgroundColor: AppColors.lavender.withValues(alpha: 0.4),
                foregroundColor: AppColors.panel,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: Size.zero,
              ),
              child: isSending
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.panel),
                    )
                  : const Text('Agregar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: AppColors.panel,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
