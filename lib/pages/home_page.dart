import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';
import 'messages_page.dart';
import 'search_page.dart';
import 'topic_page.dart';

/// 首页：iOS 大标题导航栏 + 信息流帖子列表。
/// 含骨架屏加载、逐项入场动画、iOS 下拉刷新与弹性滚动。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  final List<TopicBrief> _topics = [];
  String _cursor = '';
  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load(refresh: true, initial: true);
  }

  Future<void> _load({bool refresh = false, bool initial = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (refresh) _error = null;
    });
    try {
      final api = context.read<ForumApi>();
      final paged = await api.topics(cursor: refresh ? null : _cursor);
      setState(() {
        if (refresh) _topics.clear();
        _topics.addAll(paged.list);
        _cursor = paged.cursor;
        _hasMore = paged.hasMore;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() {
        _loading = false;
        _initialLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // iOS 大标题导航栏（滚动时收起为普通标题）
          CupertinoSliverNavigationBar(
            largeTitle: const Text('社区论坛'),
            backgroundColor: AppColors.surface.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => Navigator.push(
                      context, iosRoute<void>(const SearchPage())),
                  child: const Icon(CupertinoIcons.search, size: 23),
                ),
                const SizedBox(width: 14),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () => Navigator.push(
                      context, iosRoute<void>(const MessagesPage())),
                  child: const Icon(CupertinoIcons.bell, size: 23),
                ),
              ],
            ),
          ),
          // iOS 下拉刷新
          CupertinoSliverRefreshControl(
            onRefresh: () => _load(refresh: true),
          ),
          if (_initialLoading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 520,
                child: FeedSkeleton(count: 6),
              ),
            )
          else if (_error != null && _topics.isEmpty)
            SliverToBoxAdapter(
              child: IosEmptyView(
                icon: '⚠️',
                title: '加载失败',
                sub: _error,
                action: IosButton(
                  label: '重试',
                  expand: false,
                  onTap: () => _load(refresh: true),
                ),
              ),
            )
          else if (_topics.isEmpty)
            const SliverToBoxAdapter(
              child: IosEmptyView(
                icon: '📭',
                title: '还没有帖子',
                sub: '成为第一个发帖的人吧',
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                child: Column(
                  children: [
                    for (var i = 0; i < _topics.length; i++)
                      FeedCard(
                        topic: _topics[i],
                        index: i,
                        onTap: () => Navigator.push(
                          context,
                          iosRoute<void>(TopicPage(topicId: _topics[i].id)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _hasMore
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Center(
                        child: _loading
                            ? const CupertinoActivityIndicator()
                            : CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 0,
                                onPressed: () => _load(),
                                child: const Text(
                                  '加载更多',
                                  style: TextStyle(color: AppColors.iosBlue),
                                ),
                              ),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text('— 已经到底啦 —',
                            style: TextStyle(
                                color: AppColors.text3, fontSize: 12)),
                      ),
                    ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}
