import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_page.dart';

/// 消息中心：通知 + 私信（延续 ui-app 08-messages）。
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _tab = 0;
  final List<Notification> _notifs = [];
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
    _load();
  }

  Future<void> _load() async {
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
    await api.readNotifications();
    setState(() => _unread = 0);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          TextButton(
            onPressed: _readAll,
            child: const Text('全部已读',
                style: TextStyle(color: AppColors.brand, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: _segmented(),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _tab == 0 ? _notifList() : _convList(),
          ),
        ],
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _segItem(0, '通知', _unread)),
          Expanded(child: _segItem(1, '私信', 0)),
        ],
      ),
    );
  }

  Widget _segItem(int index, String label, int badge) {
    final on = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: on
              ? const [BoxShadow(color: Color(0x0A101828), blurRadius: 2)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: on ? AppColors.brand : AppColors.text2,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                )),
            if (badge > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notifList() {
    if (_notifs.isEmpty) return const EmptyView();
    return ListView(
      children: [
        for (final n in _notifs)
          Container(
            color: n.isRead ? AppColors.surface : const Color(0xFFF5F9FF),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(_icons[n.kind] ?? '🔔',
                      style: const TextStyle(fontSize: 17)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.text,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(relativeTime(n.createdAt),
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 11)),
                    ],
                  ),
                ),
                if (!n.isRead)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _convList() {
    if (_convs.isEmpty) return const EmptyView(icon: '💬', title: '暂无私信');
    return ListView(
      children: [
        for (final c in _convs)
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ChatPage(convId: c.id, peer: c.peer)),
            ),
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  UserAvatar(
                      name: c.peer.displayName,
                      id: c.peer.id,
                      url: c.peer.avatar),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(c.peer.displayName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                            LevelBadge(
                                level: c.peer.level,
                                name: c.peer.levelName),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(c.lastText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.text3, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(relativeTime(c.updatedAt),
                      style:
                          const TextStyle(color: AppColors.text3, fontSize: 11)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
