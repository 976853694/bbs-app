import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';
import 'chat_page.dart';
import 'login_page.dart';

/// 消息中心：通知 + 私信（iOS 分段控件 + 入场动画）。
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _tab = 0;
  final List<AppNotification> _notifs = [];
  final List<Conversation> _convs = [];
  bool _loading = true;
  int _unread = 0;

  static const _icons = {
    'reply': '💬',
    'like': '👍',
    'levelup': '⬆️',
    'medal': '🏅',
    'review': '✅',
    'announcement': '📌',
  };

  @override
  void initState() {
    super.initState();
    // 游客不请求消息接口，直接显示登录引导
    if (context.read<AuthState>().isLoggedIn) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    if (!context.read<AuthState>().isLoggedIn) return;
    final api = context.read<ForumApi>();
    try {
      final (notifs, unread) = await api.notifications();
      final convs = await api.conversations();
      setState(() {
        _notifs
          ..clear()
          ..addAll(notifs.list);
        _convs
          ..clear()
          ..addAll(convs.list);
        _unread = unread;
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  Future<void> _readAll() async {
    final api = context.read<ForumApi>();
    hapticMedium();
    await api.readNotifications();
    setState(() => _unread = 0);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthState>().isLoggedIn;
    // 游客登录后自动拉取一次
    if (isLoggedIn && _notifs.isEmpty && _convs.isEmpty && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            middle: const Text('消息'),
            backgroundColor: AppColors.surface.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
            trailing: isLoggedIn
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _readAll,
                    child: const Text('全部已读',
                        style: TextStyle(
                            color: AppColors.iosBlue, fontSize: 15)),
                  )
                : null,
          ),
          if (!isLoggedIn)
            const SliverToBoxAdapter(child: _guestView())
          else ...[
            // iOS 分段控件
            SliverToBoxAdapter(
              child: IosSegmented(
                tabs: const ['通知', '私信'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: IosLoadingView()),
              )
            else if (_tab == 0)
              _notifs.isEmpty
                  ? const SliverToBoxAdapter(
                      child: IosEmptyView(
                          icon: '🔔', title: '暂无通知', sub: '有新消息时会在这里显示'),
                    )
                  : SliverToBoxAdapter(
                      child: IosGroupCard(
                        showSeparators: true,
                        children: [
                          for (var i = 0; i < _notifs.length; i++)
                            FadeSlideIn(
                              index: i,
                              child: _notifRow(_notifs[i]),
                            ),
                        ],
                      ),
                    )
            else
              _convs.isEmpty
                  ? const SliverToBoxAdapter(
                      child: IosEmptyView(
                          icon: '💬', title: '暂无私信', sub: '和好友聊聊吧'),
                    )
                  : SliverToBoxAdapter(
                      child: IosGroupCard(
                        children: [
                          for (var i = 0; i < _convs.length; i++)
                            FadeSlideIn(
                              index: i,
                              child: _convRow(_convs[i]),
                            ),
                        ],
                      ),
                    ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _notifRow(AppNotification n) {
    return Container(
      color: n.isRead ? AppColors.surface : AppColors.brandLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(_icons[n.kind] ?? '🔔',
                style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.text, style: AppText.subhead),
                const SizedBox(height: 3),
                Text(relativeTime(n.createdAt),
                    style: AppText.caption2.copyWith(color: AppColors.text3)),
              ],
            ),
          ),
          if (!n.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                  color: AppColors.danger, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Widget _convRow(Conversation c) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      borderRadius: BorderRadius.zero,
      onPressed: () {
        hapticLight();
        Navigator.push(
          context,
          iosRoute<void>(ChatPage(convId: c.id, peer: c.peer)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserAvatar(
                name: c.peer.displayName, id: c.peer.id, url: c.peer.avatar),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.peer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.subhead.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      LevelBadge(
                          level: c.peer.level, name: c.peer.levelName),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.lastText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: AppColors.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(relativeTime(c.updatedAt),
                style: AppText.caption2.copyWith(color: AppColors.text3)),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right,
                size: 15, color: AppColors.text3),
          ],
        ),
      ),
    );
  }
}

/// 游客登录引导
class _guestView extends StatelessWidget {
  const _guestView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: IosEmptyView(
        icon: '🔔',
        title: '登录后查看通知与私信',
        sub: '打开 App 即可浏览帖子，登录后可接收消息',
        action: IosButton(
          label: '登录 / 注册',
          expand: false,
          onTap: () =>
              Navigator.push(context, iosRoute<bool>(const LoginPage())),
        ),
      ),
    );
  }
}
