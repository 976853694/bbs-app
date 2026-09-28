import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';
import 'login_page.dart';
import 'points_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

/// 我的：个人中心（iOS 分组列表风格）。
/// 未登录显示游客引导页，已登录显示资料头 + 快捷入口 + 分组菜单。
class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: user == null
          ? const _GuestView()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const CupertinoSliverNavigationBar(
                  largeTitle: Text('我的'),
                  backgroundColor: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.separator, width: 0.5),
                  ),
                ),
                SliverToBoxAdapter(child: _header(context, user)),
                SliverToBoxAdapter(child: _quickMenu(context)),
                SliverToBoxAdapter(child: _menuGroup(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }

  Widget _header(BuildContext context, UserDetail user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brand2],
        ),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          Hero(
            tag: 'avatar-${user.id}',
            child: UserAvatar(
                name: user.displayName,
                id: user.id,
                url: user.avatar,
                size: 58),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: AppRadius.capsule,
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
                Text(
                  user.signature.isEmpty ? '这个人很懒～' : user.signature,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 12),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => Navigator.push(
                context, iosRoute<void>(const SettingsPage())),
            child: const Icon(CupertinoIcons.settings,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _quickMenu(BuildContext context) {
    final items = [
      ('📝', '我的帖子', null),
      ('⭐', '我的收藏', null),
      ('🎖️', '勋章墙',
          () => Navigator.push(context, iosRoute<void>(const PointsPage()))),
      ('💰', '积分商城',
          () => Navigator.push(context, iosRoute<void>(const PointsPage()))),
      ('🏆', '排行榜', null),
      ('📅', '每日签到',
          () => Navigator.push(context, iosRoute<void>(const PointsPage()))),
      ('📊', '统计', null),
      ('👤', '个人主页', () => Navigator.push(
          context,
          iosRoute<void>(
              ProfilePage(
                  username: context.read<AuthState>().user!.username)))),
    ];
    return IosCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.92,
        children: [
          for (final (icon, label, onTap) in items)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              borderRadius: BorderRadius.zero,
              onPressed: onTap == null
                  ? null
                  : () {
                      hapticLight();
                      onTap();
                    },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 6),
                  Text(label,
                      style: AppText.caption2.copyWith(color: AppColors.text2)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuGroup(BuildContext context) {
    return IosGroupCard(
      children: [
        IosCell(
          icon: CupertinoIcons.person,
          title: '个人资料',
          showArrow: true,
          onTap: () =>
              Navigator.push(context, iosRoute<void>(const SettingsPage())),
        ),
        IosCell(
          icon: CupertinoIcons.device_phone_portrait,
          iconBg: AppColors.purple,
          title: '设备管理',
          showArrow: true,
          onTap: () =>
              Navigator.push(context, iosRoute<void>(const SettingsPage())),
        ),
        IosCell(
          icon: CupertinoIcons.money_dollar_circle,
          iconBg: AppColors.success,
          title: '积分中心',
          showArrow: true,
          onTap: () =>
              Navigator.push(context, iosRoute<void>(const PointsPage())),
        ),
      ],
    );
  }
}

/// 游客引导视图（iOS 风格居中卡片）
class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brand2]),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Text('论',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            const Text('登录后体验完整功能', style: AppText.headline),
            const SizedBox(height: 6),
            const Text(
              '发帖、回复、私信、积分与勋章',
              style: AppText.footnote,
            ),
            const SizedBox(height: 22),
            IosButton(
              label: '登录 / 注册',
              expand: false,
              onTap: () =>
                  Navigator.push(context, iosRoute<bool>(const LoginPage())),
            ),
          ],
        ),
      ),
    );
  }
}
