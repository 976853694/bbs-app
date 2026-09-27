import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 帖子详情：正文 Markdown + 楼层回复 + 点赞/收藏/分享/举报（延续 ui-app 04-topic）。
class TopicPage extends StatefulWidget {
  const TopicPage({super.key, required this.topicId});

  final int topicId;

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  TopicDetail? _topic;
  final List<Reply> _replies = [];
  String _cursor = '';
  bool _loading = true;
  bool _hasMore = true;
  bool _liked = false;
  bool _favorited = false;
  String? _error;

  final _replyController = TextEditingController();
  int _replyingTo = 0; // 0=楼主，>0=楼中楼 parent id

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ForumApi>();
      final topic = await api.topic(widget.topicId);
      final paged = await api.replies(widget.topicId);
      setState(() {
        _topic = topic;
        _replies
          ..clear()
          ..addAll(paged.list);
        _cursor = paged.cursor;
        _hasMore = paged.hasMore;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    final api = context.read<ForumApi>();
    final paged = await api.replies(widget.topicId, cursor: _cursor);
    setState(() {
      _replies.addAll(paged.list);
      _cursor = paged.cursor;
      _hasMore = paged.hasMore;
    });
  }

  Future<void> _toggleLike() async {
    final api = context.read<ForumApi>();
    try {
      final liked = await api.topicLike(widget.topicId);
      setState(() => _liked = liked);
      if (_topic != null) {
        final delta = liked ? 1 : -1;
        final t = _topic!;
        _topic = TopicDetail(
          id: t.id,
          title: t.title,
          summary: t.summary,
          board: t.board,
          author: t.author,
          replyCount: t.replyCount,
          likeCount: (t.likeCount + delta).clamp(0, 1 << 30),
          favoriteCount: t.favoriteCount,
          viewCount: t.viewCount,
          isPinned: t.isPinned,
          isEssence: t.isEssence,
          isLocked: t.isLocked,
          bounty: t.bounty,
          bountyState: t.bountyState,
          createdAt: t.createdAt,
          lastReplyAt: t.lastReplyAt,
          content: t.content,
          tags: t.tags,
          isRecommended: t.isRecommended,
          bestReplyId: t.bestReplyId,
        );
      }
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _toggleFavorite() async {
    final api = context.read<ForumApi>();
    try {
      final saved = await api.topicFavorite(widget.topicId);
      setState(() => _favorited = saved);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;
    final api = context.read<ForumApi>();
    try {
      await api.createReply(widget.topicId, content, parentId: _replyingTo);
      _replyController.clear();
      setState(() => _replyingTo = 0);
      _toast('回复成功');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _report() async {
    final api = context.read<ForumApi>();
    final reasonController = TextEditingController();
    final category = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('选择举报类型', textAlign: TextAlign.center)),
            for (final c in ['垃圾广告', '色情低俗', '辱骂攻击', '违法违规', '其他'])
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(c),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (category == null) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('举报理由'),
        content: TextField(controller: reasonController, maxLines: 3),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, reasonController.text),
              child: const Text('提交')),
        ],
      ),
    );
    try {
      await api.topicReport(widget.topicId, category, reason ?? '');
      _toast('举报已提交');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    return Scaffold(
      appBar: AppBar(
        title: const Text('帖子详情'),
        actions: [
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? EmptyView(icon: '⚠️', title: '加载失败', sub: _error)
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          _head(topic!),
                          _actions(topic),
                          _replyHeader(),
                          for (final r in _replies) _floor(r),
                          if (_hasMore)
                            TextButton(
                              onPressed: _loadMore,
                              child: const Text('加载更多回复',
                                  style: TextStyle(color: AppColors.brand)),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                  child: Text('— 已加载全部回复 —',
                                      style: TextStyle(
                                          color: AppColors.text3,
                                          fontSize: 11))),
                            ),
                        ],
                      ),
                    ),
                    _replyBar(),
                  ],
                ),
    );
  }

  Widget _head(TopicDetail t) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (t.isEssence)
                const StatusBadge('精华',
                    color: AppColors.warn, bg: AppColors.warnLight),
              if (t.bounty > 0)
                StatusBadge('悬赏 ${t.bounty}',
                    color: AppColors.gold, bg: AppColors.warnLight),
              for (final tag in t.tags) TagChip(tag),
            ],
          ),
          const SizedBox(height: 10),
          Text(t.title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, height: 1.45)),
          const SizedBox(height: 12),
          Row(
            children: [
              UserAvatar(
                  name: t.author.displayName,
                  id: t.author.id,
                  url: t.author.avatar,
                  size: 30),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(t.author.displayName,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      LevelBadge(
                          level: t.author.level, name: t.author.levelName),
                    ],
                  ),
                  Text(relativeTime(t.createdAt),
                      style: const TextStyle(
                          color: AppColors.text3, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actions(TopicDetail t) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
              child: _actBtn(_liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                  '赞 ${t.likeCount}', _liked ? AppColors.brand : null,
                  _toggleLike)),
          Expanded(
              child: _actBtn(
                  _favorited ? Icons.star : Icons.star_border,
                  '收藏 ${t.favoriteCount}',
                  _favorited ? AppColors.gold : null,
                  _toggleFavorite)),
          Expanded(child: _actBtn(Icons.share_outlined, '分享', null, () {})),
          Expanded(
              child: _actBtn(Icons.flag_outlined, '举报', AppColors.danger,
                  _report)),
        ],
      ),
    );
  }

  Widget _actBtn(IconData icon, String label, Color? color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.text2),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: color ?? AppColors.text2)),
          ],
        ),
      ),
    );
  }

  Widget _replyHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text('全部回复',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('${_topic?.replyCount ?? 0}',
              style: const TextStyle(color: AppColors.text3, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _floor(Reply r) {
    final isBest = _topic?.bestReplyId == r.id;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Center(
              child: Text('${r.floor}',
                  style: const TextStyle(color: AppColors.text3, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar(
                        name: r.author.displayName,
                        id: r.author.id,
                        url: r.author.avatar,
                        size: 24),
                    const SizedBox(width: 6),
                    Text(r.author.displayName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    LevelBadge(
                        level: r.author.level, name: r.author.levelName),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      const StatusBadge('✓ 已采纳',
                          color: AppColors.success, bg: AppColors.successLight),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                MarkdownBody(
                  data: r.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, height: 1.7),
                  ),
                ),
                if (r.children.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        for (final c in r.children)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c.author.displayName}：',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: AppColors.text2)),
                                Expanded(
                                  child: Text(c.content,
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _floorAct('👍 ${r.likeCount}', () {}),
                    const SizedBox(width: 18),
                    _floorAct('回复', () => setState(() => _replyingTo = r.id)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorAct(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(color: AppColors.text3, fontSize: 11)),
    );
  }

  Widget _replyBar() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
          left: 12, right: 8, top: 8, bottom: 8 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(19),
              ),
              child: TextField(
                controller: _replyController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _replyingTo > 0 ? '回复 #$_replyingTo' : '说点什么…',
                  hintStyle: const TextStyle(color: AppColors.text3, fontSize: 13),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.brand),
            onPressed: () {
              final auth = context.read<AuthState>();
              if (!auth.isLoggedIn) {
                _toast('请先登录');
                return;
              }
              _submitReply();
            },
          ),
        ],
      ),
    );
  }
}
