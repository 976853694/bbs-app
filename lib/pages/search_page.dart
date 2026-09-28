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

/// 搜索：iOS 搜索框 + 排序分段 + 结果列表（带入场动画）。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _keyword = '';
  String _order = 'relevance';
  List<TopicBrief> _topics = [];
  bool _loading = false;

  static const _orders = ['relevance', 'latest', 'most_replies', 'most_likes'];
  static const _orderLabels = ['相关度', '最新', '最多回复', '最多点赞'];

  Future<void> _search() async {
    final kw = _controller.text.trim();
    if (kw.isEmpty) return;
    setState(() {
      _keyword = kw;
      _loading = true;
    });
    try {
      final api = context.read<ForumApi>();
      final result = await api.search(kw, order: _order);
      setState(() => _topics = result.topics.list);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: SafeArea(
        child: Column(
          children: [
            // iOS 搜索框
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      controller: _controller,
                      autofocus: true,
                      placeholder: '搜索帖子、用户、版块…',
                      onSubmitted: (_) => _search(),
                      borderRadius: BorderRadius.circular(10),
                      backgroundColor: AppColors.fill,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _search,
                    child: const Text('搜索',
                        style: TextStyle(
                            color: AppColors.iosBlue, fontSize: 15)),
                  ),
                ],
              ),
            ),
            // 排序分段控件
            IosSegmented(
              tabs: _orderLabels,
              selected: _orders.indexOf(_order),
              onChanged: (i) => setState(() {
                _order = _orders[i];
                if (_keyword.isNotEmpty) _search();
              }),
            ),
            Expanded(
              child: _loading
                  ? const FeedSkeleton(count: 6)
                  : _keyword.isEmpty
                      ? const IosEmptyView(
                          icon: '🔍',
                          title: '输入关键词搜索',
                          sub: '支持搜索帖子标题、内容与标签',
                        )
                      : _topics.isEmpty
                          ? const IosEmptyView(
                              icon: '📭',
                              title: '没有找到相关内容',
                              sub: '换个关键词试试',
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _topics.length,
                              itemBuilder: (context, i) => Container(
                                color: AppColors.surface,
                                child: FeedCard(
                                  topic: _topics[i],
                                  index: i,
                                  onTap: () => Navigator.push(
                                    context,
                                    iosRoute<void>(
                                        TopicPage(topicId: _topics[i].id)),
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
