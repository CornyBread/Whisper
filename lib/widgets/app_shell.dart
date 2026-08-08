import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Bottom navigation scaffold shared by the Chats / Solicitudes / Perfil tabs,
/// mounted via go_router's StatefulShellRoute.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.requestsBadgeCount = 0,
  });

  final StatefulNavigationShell navigationShell;
  final int requestsBadgeCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(30, 12, 30, 14),
        decoration: const BoxDecoration(
          color: AppColors.bar,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: 'Chats',
              selected: navigationShell.currentIndex == 0,
              onTap: () => navigationShell.goBranch(0),
            ),
            _NavItem(
              icon: Icons.people_outline,
              activeIcon: Icons.people_outline,
              label: 'Solicitudes',
              selected: navigationShell.currentIndex == 1,
              badgeCount: requestsBadgeCount,
              onTap: () => navigationShell.goBranch(1),
            ),
            _NavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Perfil',
              selected: navigationShell.currentIndex == 2,
              onTap: () => navigationShell.goBranch(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.lavender : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, size: 25, color: color),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: const BoxDecoration(color: AppColors.rose, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.panel),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
