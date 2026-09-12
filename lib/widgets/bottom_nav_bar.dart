import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color brandRed = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: [
              _NavItem(
                iconPath: 'assets/icons_bottom_navigation_bar/home.png',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                iconData: Icons.school_outlined,
                activeIconData: Icons.school_rounded,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                iconPath: 'assets/icons_bottom_navigation_bar/clips.png',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                iconPath: 'assets/icons_bottom_navigation_bar/new.png',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                iconPath: 'assets/icons_bottom_navigation_bar/account.png',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String? iconPath;
  final IconData? iconData;
  final IconData? activeIconData;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    this.iconPath,
    this.iconData,
    this.activeIconData,
    required this.isActive,
    required this.onTap,
  });

  static const Color brandRed = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: iconPath != null
              ? Image.asset(
                  iconPath!,
                  width: 26,
                  height: 26,
                  color: isActive ? brandRed : Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                )
              : Icon(
                  isActive ? (activeIconData ?? iconData) : iconData,
                  size: 26,
                  color: isActive ? brandRed : Colors.white,
                ),
        ),
      ),
    );
  }
}

