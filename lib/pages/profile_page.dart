import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';
import 'topic_page.dart';

/// 个人主页：iOS 风格资料头 + 统计 + TA 的帖子。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.username});

  final String username;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserDetail? _user;
  List<TopicBrief> _topics = [];
  bool _loading = true;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ForumApi>();
    try {
      final user = await api.userPage(widget.username);
      final paged = await api.userTopics(widget.username);
      setState(() {
        _user = user;
        _topics = paged.list;
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  Future<void> _follow() async {
    final api = context.read<ForumApi>();
    hapticMedium();
    try {
      final following = await api.followUser(widget.username);
      setState(() => _following = following);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            middle: Text(user?.displayName ?? '个人主页'),
            backgroundColor: AppColors.surface.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: _load),
          if (_loading)
            const SliverToBoxAdapter(
              child: SizedBox(height: 320, child: IosLoadingView()),
            )
          else if (user == null)
            const SliverToBoxAdapter(
              child: IosEmptyView(icon: '⚠️', title: '用户不存在'),
            )
          else ...[
            SliverToBoxAdapter(child: _header(user)),
            SliverToBoxAdapter(child: _stats(user)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 16, 8),
                child: Text('TA 的帖子', style: AppText.groupHeader),
              ),
            ),
            if (_topics.isEmpty)
              const SliverToBoxAdapter(
                child: IosEmptyView(
                    icon: '📝', title: '还没有发帖', sub: 'TA 还没有发布任何主题'),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.card,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < _topics.length; i++)
                        FeedCard(
                          topic: _topics[i],
                          index: i,
                          onTap: () => Navigator.push(
                            context,
                            iosRoute<void>(
                                TopicPage(topicId: _topics[i].id)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _header(UserDetail user) {
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
        ),
        child: Column(
          children: [
            // Hero 头像（与「我的」页共享）
            Hero(
              tag: 'avatar-${user.id}',
              child: UserAvatar(
                  name: user.displayName,
                  id: user.id,
                  url: user.avatar,
                  size: 78),
            ),
            const SizedBox(height: 11),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title3),
                ),
                const SizedBox(width: 6),
                LevelBadge(level: user.level, name: user.levelName),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              user.signature.isEmpty ? '这个人很懒～' : user.signature,
              textAlign: TextAlign.center,
              style: AppText.footnote.copyWith(color: AppColors.text2),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FollowButton(following: _following, onTap: _follow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(UserDetail user) {
    return FadeSlideIn(
      index: 1,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _s('积分', '${user.points}'),
            _s('经验', '${user.exp}'),
            _s('连续签到', '${user.checkinStreak}'),
          ],
        ),
      ),
    );
  }

  Widget _s(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.title3),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.caption2.copyWith(color: AppColors.text3)),
        ],
      ),
    );
  }
}

/// 关注按钮（iOS 风格，带状态切换动画）
class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final following = widget.following;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
          decoration: BoxDecoration(
            color: following ? Colors.transparent : AppColors.iosBlue,
            borderRadius: AppRadius.capsule,
            border: following
                ? Border.all(color: AppColors.separator)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                following ? CupertinoIcons.checkmark : CupertinoIcons.add,
                size: 16,
                color: following ? AppColors.text2 : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                following ? '已关注' : '关注',
                style: AppText.subhead.copyWith(
                  color: following ? AppColors.text2 : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
