import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 个人主页：资料 + 关注/私信 + TA 的帖子（延续 ui-app 14-profile）。
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
    return Scaffold(
      appBar: AppBar(title: const Text('个人主页')),
      body: _loading
          ? const LoadingView()
          : user == null
              ? const EmptyView(icon: '⚠️', title: '用户不存在')
              : ListView(
                  children: [
                    _header(user),
                    _stats(user),
                    _sectionTitle('TA 的帖子'),
                    for (final t in _topics) FeedCard(topic: t, onTap: null),
                  ],
                ),
    );
  }

  Widget _header(UserDetail user) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          UserAvatar(
              name: user.displayName, id: user.id, url: user.avatar, size: 80),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(user.displayName,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              LevelBadge(level: user.level, name: user.levelName),
            ],
          ),
          const SizedBox(height: 6),
          Text(user.signature,
              style: const TextStyle(color: AppColors.text2, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _follow,
                icon: Icon(_following ? Icons.check : Icons.add),
                label: Text(_following ? '已关注' : '关注'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('私信'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats(UserDetail user) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _s('积分', '${user.points}'),
          _s('经验', '${user.exp}'),
          _s('连续签到', '${user.checkinStreak}'),
        ],
      ),
    );
  }

  Widget _s(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.text3, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Text(title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }
}
