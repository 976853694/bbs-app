import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

/// 我的：个人中心（延续 ui-app 13-me）。
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return Scaffold(
      body: user == null
          ? const _GuestView()
          : Column(
              children: [
                _header(context, user),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 0),
                    children: [
                      _quickMenu(context),
                      _menuGroup(context),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, UserDetail user) {
    return Container(
      color: AppColors.brand,
      child: Column(
        children: [
          const SizedBox(height: 44),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                UserAvatar(
                    name: user.displayName,
                    id: user.id,
                    url: user.avatar,
                    size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user.displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(user.levelName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(user.signature.isEmpty ? '这个人很懒～' : user.signature,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SettingsPage())),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                _stat('发帖', '32'),
                _stat('积分', '${user.points}'),
                _stat('关注', '12'),
                _stat('连续签到', '${user.checkinStreak}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _quickMenu(BuildContext context) {
    final items = [
      ('📝', '我的帖子', null),
      ('⭐', '我的收藏', null),
      ('🎖️', '勋章墙', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PointsPage()))),
      ('💰', '积分商城', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PointsPage()))),
      ('🏆', '排行榜', null),
      ('📅', '每日签到', () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PointsPage()))),
      ('📊', '统计', null),
      ('👤', '个人主页', () => Navigator.push(context,
          MaterialPageRoute(
              builder: (_) => ProfilePage(
                  username: context.read<AuthState>().user!.username)))),
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.0,
        children: [
          for (final (icon, label, onTap) in items)
            InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.text2, fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuGroup(BuildContext context) {
    final auth = context.read<AuthState>();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppColors.brand),
            title: const Text('个人资料'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          const Divider(height: 1, indent: 52),
          ListTile(
            leading:
                const Icon(Icons.devices_outlined, color: AppColors.purple),
            title: const Text('设备管理'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.text3),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          const Divider(height: 1, indent: 52),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: const Text('退出登录',
                style: TextStyle(color: AppColors.danger)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出登录')));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.brand, AppColors.brand2]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('论',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          const Text('登录后体验完整功能',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text('登录 / 注册'),
            ),
          ),
        ],
      ),
    );
  }
}
