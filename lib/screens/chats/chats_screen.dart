import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/friend.dart';
import '../../state/friends_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_list_tile.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    friendsController.addListener(_onFriendsChanged);
    // Deferred a frame so the first build is not fighting a notifyListeners.
    WidgetsBinding.instance.addPostFrameCallback((_) => friendsController.load());
  }

  @override
  void dispose() {
    friendsController.removeListener(_onFriendsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFriendsChanged() {
    if (mounted) setState(() {});
  }

  /// Local filter over the loaded list — the API has no search parameter.
  List<Friend> get _visibleFriends {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return friendsController.friends;
    return friendsController.friends
        .where((friend) =>
            friend.username.toLowerCase().contains(query) ||
            (friend.lastMessage?.content.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chats', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                      InkWell(
                        borderRadius: BorderRadius.circular(23),
                        onTap: () {
                          // TODO: start a new chat once the endpoint exists.
                        },
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                          child: const Icon(Icons.add, color: AppColors.panel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
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
                              hintText: 'Buscar',
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
                ],
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    // Only block the screen on the very first load; later refreshes keep the
    // current list visible under the pull-to-refresh indicator.
    if (!friendsController.hasLoadedOnce && friendsController.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lavender));
    }

    final error = friendsController.error;
    if (error != null && friendsController.friends.isEmpty) {
      return _CenteredState(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar tus chats',
        subtitle: error,
        actionLabel: 'Reintentar',
        onAction: friendsController.load,
      );
    }

    final friends = _visibleFriends;
    if (friends.isEmpty) {
      final searching = _searchController.text.trim().isNotEmpty;
      return RefreshIndicator(
        color: AppColors.lavender,
        backgroundColor: AppColors.card,
        onRefresh: friendsController.load,
        child: ListView(
          // Needs to scroll for pull-to-refresh to work while empty.
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
            _CenteredState(
              icon: searching ? Icons.search_off : Icons.forum_outlined,
              title: searching ? 'Sin resultados' : 'Aún no tienes chats',
              subtitle: searching
                  ? 'No encontramos a nadie que coincida con tu búsqueda.'
                  : 'Cuando aceptes una solicitud de amistad, la conversación aparecerá aquí.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.lavender,
      backgroundColor: AppColors.card,
      onRefresh: friendsController.load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return ChatListTile(
            friend: friend,
            onTap: () => context.push('/chats/${friend.id}'),
          );
        },
      ),
    );
  }
}

/// Empty / error placeholder shared by the list states.
class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
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
