import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';

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
    // iOS 动作面板：选择举报类型
    final category = await iosActionSheet<String>(
      context,
      title: '举报该帖子',
      message: '请选择举报类型',
      actions: [
        for (final c in ['垃圾广告', '色情低俗', '辱骂攻击', '违法违规', '其他'])
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, c),
            child: Text(c,
                style: const TextStyle(color: AppColors.danger)),
          ),
      ],
    );
    if (category == null) return;
    // iOS 输入弹窗：补充说明
    final reason = await iosPrompt(
      context,
      title: '举报理由',
      message: '类型：$category\n请补充说明（选填）',
      placeholder: '例如：多次发布广告内容',
      maxLines: 3,
      maxLength: 200,
    );
    if (reason == null) return;
    try {
      await api.topicReport(widget.topicId, category, reason);
      hapticMedium();
      _toast('举报已提交，感谢反馈');
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('帖子详情'),
        backgroundColor: AppColors.surface.withOpacity(0.9),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () {},
          child: const Icon(CupertinoIcons.ellipsis, size: 22),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: _loading
            ? const IosLoadingView(message: '加载中…')
            : _error != null
                ? IosEmptyView(icon: '⚠️', title: '加载失败', sub: _error,
                    action: IosButton(
                        label: '重试', expand: false, onTap: _load))
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _head(topic!),
                            _actions(topic),
                            _replyHeader(),
                            for (var i = 0; i < _replies.length; i++)
                              FadeSlideIn(index: i, child: _floor(_replies[i])),
                            if (_hasMore)
                              CupertinoButton(
                                onPressed: _loadMore,
                                child: const Text('加载更多回复',
                                    style: TextStyle(
                                        color: AppColors.iosBlue,
                                        fontSize: 15)),
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
              child: _actBtn(
                  _liked ? CupertinoIcons.hand_thumbsup_fill
                      : CupertinoIcons.hand_thumbsup,
                  '赞 ${t.likeCount}',
                  _liked ? AppColors.iosBlue : null,
                  _toggleLike,
                  animate: true)),
          Expanded(
              child: _actBtn(
                  _favorited ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  '收藏 ${t.favoriteCount}',
                  _favorited ? AppColors.gold : null,
                  _toggleFavorite,
                  animate: true)),
          Expanded(
              child: _actBtn(CupertinoIcons.share, '分享', null, () {})),
          Expanded(
              child: _actBtn(CupertinoIcons.flag, '举报', AppColors.danger,
                  _report)),
        ],
      ),
    );
  }

  Widget _actBtn(IconData icon, String label, Color? color, VoidCallback onTap,
      {bool animate = false}) {
    return _ActionButton(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
      animate: animate,
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
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              final auth = context.read<AuthState>();
              if (!auth.isLoggedIn) {
                _toast('请先登录');
                return;
              }
              _submitReply();
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                  color: AppColors.iosBlue, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.arrow_up,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS 风格操作按钮（点赞/收藏时弹性缩放反馈）
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
    this.animate = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final bool animate;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.spring),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      borderRadius: BorderRadius.zero,
      onPressed: () {
        if (widget.animate) {
          hapticMedium();
          _ctrl.forward(from: 0);
        }
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(widget.icon,
                  size: 20, color: widget.color ?? AppColors.text2),
            ),
            const SizedBox(height: 2),
            Text(widget.label,
                style: TextStyle(
                    fontSize: 11, color: widget.color ?? AppColors.text2)),
          ],
        ),
      ),
    );
  }
}
