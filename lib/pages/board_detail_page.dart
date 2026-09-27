import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'topic_page.dart';

/// 版块详情：主题色头图 + 置顶 + 帖子列表（延续 ui-app 03-board-detail）。
class BoardDetailPage extends StatefulWidget {
  const BoardDetailPage({super.key, required this.slug});

  final String slug;

  @override
  State<BoardDetailPage> createState() => _BoardDetailPageState();
}

class _BoardDetailPageState extends State<BoardDetailPage> {
  BoardBrief? _board;
  List<TopicBrief> _pinned = [];
  final List<TopicBrief> _topics = [];
  String _cursor = '';
  bool _loading = true;
  bool _hasMore = true;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    try {
      final api = context.read<ForumApi>();
      final (board, pinned, paged) =
          await api.boardDetail(widget.slug, cursor: refresh ? null : _cursor);
      setState(() {
        _board = board;
        _pinned = pinned;
        if (refresh) _topics.clear();
        _topics.addAll(paged.list);
        _cursor = paged.cursor;
        _hasMore = paged.hasMore;
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final api = context.read<ForumApi>();
    try {
      final following = await api.followBoard(widget.slug);
      setState(() => _following = following);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            title: Text(board?.name ?? ''),
            actions: [
              IconButton(
                icon: Icon(_following ? Icons.star : Icons.star_border),
                onPressed: _toggleFollow,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [AppColors.brand, AppColors.brand2]),
                ),
                alignment: Alignment.center,
                child: Text(
                  board?.icon ?? '💬',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: board == null
                ? const LoadingView()
                : Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Text('主题 ${board.topicCount}',
                            style: const TextStyle(
                                color: AppColors.text2, fontSize: 12)),
                        const SizedBox(width: 16),
                        Text('今日 ${board.todayCount}',
                            style: const TextStyle(
                                color: AppColors.text2, fontSize: 12)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _toggleFollow,
                          icon: Icon(
                              _following ? Icons.star : Icons.star_border,
                              size: 16,
                              color: AppColors.brand),
                          label: Text(_following ? '已关注' : '关注',
                              style: const TextStyle(
                                  color: AppColors.brand, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_pinned.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('📌 置顶',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          if (_pinned.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FeedCard(
                    topic: _pinned[i],
                    onTap: () => _open(_pinned[i].id),
                  ),
                ),
                childCount: _pinned.length,
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                if (i == _topics.length) {
                  return _hasMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.brand)))
                      : const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                              child: Text('— 已经到底啦 —',
                                  style: TextStyle(
                                      color: AppColors.text3, fontSize: 11))));
                }
                final t = _topics[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FeedCard(topic: t, onTap: () => _open(t.id)),
                );
              },
              childCount: _topics.length + 1,
            ),
          ),
        ],
      ),
    );
  }

  void _open(int id) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TopicPage(topicId: id)),
      ).then((_) => _load(refresh: true));
}
