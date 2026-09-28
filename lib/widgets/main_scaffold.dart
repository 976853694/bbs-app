import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'ios.dart';

/// 底部五段式 TabBar（iOS 风格）+ 中间悬浮发布按钮。
/// 毛玻璃背景、安全区适配、图标缩放动画与触感反馈。
class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.pages,
    required this.unreadCount,
    required this.onPublish,
  });

  final List<Widget> pages;
  final int unreadCount;
  final VoidCallback onPublish;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  void _onTap(int i) {
    if (i == _index) return;
    hapticSelection();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.iosGroupedBg,
      body: IndexedStack(index: _index, children: widget.pages),
      extendBody: true,
      floatingActionButton: _PublishButton(onTap: widget.onPublish),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _IosTabBar(
        index: _index,
        unreadCount: widget.unreadCount,
        bottomPadding: bottom,
        onTap: _onTap,
      ),
    );
  }
}

/// 中间悬浮发布按钮（按压缩放 + 阴影）
class _PublishButton extends StatefulWidget {
  const _PublishButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends State<_PublishButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        hapticMedium();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.ease,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brand2, AppColors.brand],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withOpacity(0.35),
                blurRadius: _pressed ? 6 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// iOS 风格底部标签栏：毛玻璃 + 安全区 + 选中缩放动画
class _IosTabBar extends StatelessWidget {
  const _IosTabBar({
    required this.index,
    required this.unreadCount,
    required this.bottomPadding,
    required this.onTap,
  });

  final int index;
  final int unreadCount;
  final double bottomPadding;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // iOS TabBar 标准高度 49 + 安全区
    final height = 56 + bottomPadding;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.82),
            border: const Border(
              top: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              children: [
                _tab(0, CupertinoIcons.house, CupertinoIcons.house_fill, '首页'),
                _tab(1, CupertinoIcons.square_grid_2x2,
                    CupertinoIcons.square_grid_2x2_fill, '版块'),
                const SizedBox(width: 56),
                _tab(2, CupertinoIcons.bubble_left_bubble_right,
                    CupertinoIcons.bubble_left_bubble_right_fill, '消息',
                    badge: unreadCount),
                _tab(3, CupertinoIcons.person, CupertinoIcons.person_fill, '我的'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, IconData activeIcon, String label,
      {int badge = 0}) {
    final selected = index == i;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        borderRadius: BorderRadius.zero,
        onPressed: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: AppMotion.fast,
                  curve: AppMotion.spring,
                  child: Icon(
                    selected ? activeIcon : icon,
                    color: selected ? AppColors.iosBlue : AppColors.text3,
                    size: 24,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -11,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: AppRadius.capsule,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppMotion.fast,
              style: AppText.caption2.copyWith(
                color: selected ? AppColors.iosBlue : AppColors.text3,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
