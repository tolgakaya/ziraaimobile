import 'package:flutter/material.dart';

class DashboardBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DashboardBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x80FFFFFF), // bg-white/80
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB), // border-gray-200
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavigationItem(
                icon: Icons.home,
                iconSelected: Icons.home,
                label: 'Ana Sayfa',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavigationItem(
                icon: Icons.history,
                iconSelected: Icons.history,
                label: 'Geçmiş',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavigationItem(
                icon: Icons.chat_bubble_outline,
                iconSelected: Icons.chat_bubble,
                label: 'Mesajlar',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavigationItem(
                icon: Icons.person_outline,
                iconSelected: Icons.person,
                label: 'Profil',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final IconData iconSelected;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? const Color(0xFF22C55E) // primary-600
        : const Color(0xFF6B7280); // gray-500

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconSelected : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}