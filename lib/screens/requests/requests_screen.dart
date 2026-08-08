import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../data/mock_data.dart';
import '../../models/friend_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _tab = 0; // 0 = recibidas, 1 = enviadas
  final List<FriendRequest> _received = List.of(mockReceivedRequests);
  final List<FriendRequest> _sent = List.of(mockSentRequests);

  void _accept(FriendRequest request) {
    setState(() => _received.removeWhere((r) => r.id == request.id));
    // TODO: call the accept-friend-request endpoint.
  }

  void _reject(FriendRequest request) {
    setState(() => _received.removeWhere((r) => r.id == request.id));
    // TODO: call the reject-friend-request endpoint.
  }

  @override
  Widget build(BuildContext context) {
    final showingReceived = _tab == 0;
    final list = showingReceived ? _received : _sent;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Solicitudes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(child: _TabButton(label: 'Recibidas · ${_received.length}', selected: showingReceived, onTap: () => setState(() => _tab = 0))),
                    Expanded(child: _TabButton(label: 'Enviadas · ${_sent.length}', selected: !showingReceived, onTap: () => setState(() => _tab = 1))),
                  ],
                ),
              ),
              if (showingReceived) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.chevron_left, size: 15, color: AppColors.rose),
                    SizedBox(width: 4),
                    Text('Desliza para rechazar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.rose)),
                    SizedBox(width: 16),
                    Text('Aceptar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mint)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 15, color: AppColors.mint),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Expanded(
                child: list.isEmpty
                    ? const Center(
                        child: Text('Sin solicitudes pendientes', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final request = list[index];
                          return showingReceived
                              ? _SwipeableRequestCard(
                                  request: request,
                                  onAccept: () => _accept(request),
                                  onReject: () => _reject(request),
                                )
                              : _RequestCard(request: request);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavender : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.panel : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final FriendRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          UserAvatar(user: request.user, size: 52),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(request.user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${request.mutualFriends} amigos en común', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableRequestCard extends StatelessWidget {
  const _SwipeableRequestCard({required this.request, required this.onAccept, required this.onReject});

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Slidable(
        key: ValueKey(request.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => onAccept(),
              backgroundColor: const Color(0xFF1F4A3A),
              foregroundColor: AppColors.mint,
              icon: Icons.check,
              label: 'Aceptar',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.4,
          children: [
            SlidableAction(
              onPressed: (_) => onReject(),
              backgroundColor: const Color(0xFF4A2230),
              foregroundColor: AppColors.rose,
              icon: Icons.close,
              label: 'Rechazar',
            ),
          ],
        ),
        child: _RequestCard(request: request),
      ),
    );
  }
}
