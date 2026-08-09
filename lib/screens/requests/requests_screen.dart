import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/uploads.dart';
import '../../models/friend_request.dart';
import '../../state/requests_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/remote_avatar.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  int _tab = 0; // 0 = recibidas, 1 = enviadas

  @override
  void initState() {
    super.initState();
    requestsController.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => requestsController.load());
  }

  @override
  void dispose() {
    requestsController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _accept(FriendRequest request) async {
    await _run(() => requestsController.accept(request));
  }

  Future<void> _reject(FriendRequest request) async {
    await _run(() => requestsController.reject(request));
  }

  /// Both actions report the same way: a snackbar with the server's message,
  /// or with the failure if it did not go through.
  Future<void> _run(Future<String> Function() action) async {
    try {
      final message = await action();
      if (!mounted) return;
      _showSnack(message, isError: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack(ApiClient.mapError(error).message, isError: true);
      // The row may have been resolved elsewhere; resync rather than guess.
      requestsController.load();
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

  @override
  Widget build(BuildContext context) {
    final showingReceived = _tab == 0;
    final received = requestsController.received;
    final sent = requestsController.sent;
    final list = showingReceived ? received : sent;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Solicitudes', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                  InkWell(
                    borderRadius: BorderRadius.circular(23),
                    onTap: () => context.push('/discover'),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(color: AppColors.lavender, shape: BoxShape.circle),
                      child: const Icon(Icons.person_add_alt_1, color: AppColors.panel, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        label: 'Recibidas · ${received.length}',
                        selected: showingReceived,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        label: 'Enviadas · ${sent.length}',
                        selected: !showingReceived,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              if (showingReceived && received.isNotEmpty) ...[
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
              Expanded(child: _buildBody(list, showingReceived)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<FriendRequest> list, bool showingReceived) {
    if (!requestsController.hasLoadedOnce && requestsController.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.lavender));
    }

    final error = requestsController.error;
    if (error != null && list.isEmpty) {
      return _EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar tus solicitudes',
        subtitle: error,
        actionLabel: 'Reintentar',
        onAction: requestsController.load,
      );
    }

    return RefreshIndicator(
      color: AppColors.lavender,
      backgroundColor: AppColors.card,
      onRefresh: requestsController.load,
      child: list.isEmpty
          ? ListView(
              // Must scroll for pull-to-refresh to work while empty.
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                _EmptyState(
                  icon: showingReceived ? Icons.inbox_outlined : Icons.outbox_outlined,
                  title: showingReceived ? 'Sin solicitudes pendientes' : 'No has enviado solicitudes',
                  subtitle: showingReceived
                      ? 'Cuando alguien quiera conectar contigo, aparecerá aquí.'
                      : 'Busca personas con el botón de arriba para enviar tu primera solicitud.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final request = list[index];
                final busy = requestsController.isBusy(request.id);
                return showingReceived
                    ? _SwipeableRequestCard(
                        request: request,
                        isBusy: busy,
                        onAccept: () => _accept(request),
                        onReject: () => _reject(request),
                      )
                    : _RequestCard(request: request, isBusy: busy);
              },
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
  const _RequestCard({required this.request, this.isBusy = false});

  final FriendRequest request;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final createdAt = request.createdAt;

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
          // Friend-request payloads carry no picture, so this is always initials.
          RemoteAvatar(initials: request.initials, size: 52),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request.otherUsername,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  createdAt == null ? 'Solicitud pendiente' : formatRelativeTime(createdAt),
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.lavender),
            ),
        ],
      ),
    );
  }
}

class _SwipeableRequestCard extends StatelessWidget {
  const _SwipeableRequestCard({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequest request;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Slidable(
        key: ValueKey(request.id),
        // Swiping while a call is in flight would queue a second one.
        enabled: !isBusy,
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
        child: _RequestCard(request: request, isBusy: isBusy),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
