import 'package:flutter/material.dart';

import '../theme.dart';

/// 底部五段式 TabBar，中间悬浮发布按钮（延续 ui-app 设计）。
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: widget.pages),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onPublish,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        elevation: 0,
        height: 60,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _tab(0, Icons.home_outlined, Icons.home, '首页'),
            _tab(1, Icons.grid_view_outlined, Icons.grid_view, '版块'),
            const SizedBox(width: 48),
            _tab(2, Icons.chat_bubble_outline, Icons.chat_bubble, '消息',
                badge: widget.unreadCount),
            _tab(3, Icons.person_outline, Icons.person, '我的'),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData activeIcon, String label,
      {int badge = 0}) {
    final selected = _index == index;
    final color = selected ? AppColors.brand : AppColors.text3;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? activeIcon : icon, color: color, size: 23),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
