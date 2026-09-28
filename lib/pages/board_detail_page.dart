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

/// 版块详情：iOS 大标题 + 头图 + 置顶 + 帖子列表（入场动画）。
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
    hapticMedium();
    try {
      final following = await api.followBoard(widget.slug);
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
    final board = _board;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(board?.name ?? '版块'),
            backgroundColor: AppColors.surface.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: _toggleFollow,
              child: Icon(
                _following ? CupertinoIcons.star_fill : CupertinoIcons.star,
                color: _following ? AppColors.gold : AppColors.iosBlue,
                size: 24,
              ),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: () => _load(refresh: true)),
          // 版块头图（iOS 渐变头）
          if (board != null)
            SliverToBoxAdapter(
              child: FadeSlideIn(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
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
                      // Hero 共享动画：与版块卡片图标呼应
                      Hero(
                        tag: 'board-icon-${board.slug}',
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            board.icon.isEmpty ? '💬' : board.icon,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              board.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              board.description.isEmpty
                                  ? '主题 ${board.topicCount} · 今日 ${board.todayCount}'
                                  : board.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_loading)
            const SliverToBoxAdapter(
              child: SizedBox(height: 400, child: FeedSkeleton(count: 4)),
            )
          else ...[
            // 置顶区
            if (_pinned.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 16, 8),
                  child: Text('📌 置顶', style: AppText.groupHeader),
                ),
              ),
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
                      for (var i = 0; i < _pinned.length; i++)
                        FeedCard(
                          topic: _pinned[i],
                          index: i,
                          onTap: () => _open(_pinned[i].id),
                        ),
                    ],
                  ),
                ),
              ),
            ],
            // 全部帖子
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Text('全部主题', style: AppText.groupHeader),
              ),
            ),
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
                        onTap: () => _open(_topics[i].id),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: _hasMore
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () => _load(),
                          child: const Text('加载更多',
                              style: TextStyle(color: AppColors.iosBlue)),
                        )
                      : const Text('— 已经到底啦 —',
                          style:
                              TextStyle(color: AppColors.text3, fontSize: 12)),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  void _open(int id) => Navigator.push(
        context,
        iosRoute<void>(TopicPage(topicId: id)),
      ).then((_) => _load(refresh: true));
}
