import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import 'package:sungguard/core/constants/app_images.dart';

class LiquidBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const LiquidBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<LiquidBottomNav> createState() => _LiquidBottomNavState();
}

class _LiquidBottomNavState extends State<LiquidBottomNav>
    with TickerProviderStateMixin {
  static const double barHeight = 58.0;

  static const Color activeColor = Color(0xFF163B6D);
  static const Color inactiveColor = Color(0xFF64748B);

  late AnimationController _controller;
  late Animation<double> _position;

  @override
  void initState() {
    super.initState();

    _position = AlwaysStoppedAnimation(widget.currentIndex.toDouble());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant LiquidBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentIndex != widget.currentIndex) {
      final begin = _position.value;

      _position =
          Tween<double>(
            begin: begin,
            end: widget.currentIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
          );

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_NavItem> _getItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NavItem(l10n.navHome, AppImages.homeIcon, AppImages.homeIcon),
      _NavItem(l10n.homeCityParcel, AppImages.parcelIcon, AppImages.parcelIcon),
      _NavItem(l10n.navHistory, AppImages.historyIcon, AppImages.historyIcon),
      _NavItem(l10n.navProfile, AppImages.profileIcon, AppImages.profileIcon),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    final items = _getItems(context);

    return Positioned(
      left: 10,
      right: 10,
      bottom: bottom + 10,
      child: SizedBox(
        height: barHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x250F172A),
                    blurRadius: 18,
                    offset: Offset(0, 7),
                  ),
                  BoxShadow(
                    color: Color(0x120F172A),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(children: [_buildActivePill(items.length), _buildItems(items)]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePill(int totalItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / totalItems;
        final pillWidth = itemWidth - 6;
        final left = (_position.value * itemWidth) + 3;

        return Transform.translate(
          offset: Offset(left, 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: pillWidth,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.88),
                      const Color(0xFFDCE7F2).withValues(alpha: 0.72),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFD5E0EC),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x2A64748B),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Color(0x99FFFFFF),
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItems(List<_NavItem> items) {
    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final active = widget.currentIndex == index;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onTabSelected(index);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  active ? item.activeIcon : item.icon,
                  width: 21,
                  height: 21,
                  fit: BoxFit.contain,
                  color: active ? activeColor : inactiveColor,
                  colorBlendMode: BlendMode.srcIn,
                ),

                const SizedBox(height: 2),

                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 8.5,
                    height: 1,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _NavItem {
  final String label;
  final String icon;
  final String activeIcon;

  const _NavItem(this.label, this.icon, this.activeIcon);
}
