import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'messages_page.dart';
import 'search_page.dart';
import 'topic_page.dart';

/// 首页：公告 + 信息流 Tabs + 帖子列表（延续 ui-app 01-home）。
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
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brand2]),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('论',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            const Text('社区论坛'),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MessagesPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        onRefresh: () => _load(refresh: true),
        child: _error != null && _topics.isEmpty
            ? ListView(children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                EmptyView(
                    icon: '⚠️', title: '加载失败', sub: _error),
              ])
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _topics.length + 1,
                itemBuilder: (context, i) {
                  if (i == _topics.length) {
                    if (_hasMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.brand)),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: Text('— 已经到底啦 —',
                              style: TextStyle(
                                  color: AppColors.text3, fontSize: 11))),
                    );
                  }
                  final t = _topics[i];
                  return FeedCard(
                    topic: t,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TopicPage(topicId: t.id)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
