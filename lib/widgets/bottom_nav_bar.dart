import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5.0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 2.0),
            Container(
              width: 4.0,
              height: 4.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.black : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
