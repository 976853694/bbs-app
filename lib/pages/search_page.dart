import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'topic_page.dart';

/// 搜索：关键词 + 排序 + 结果（延续 ui-app 06-search）。
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: '搜索帖子、用户、版块…',
            isDense: true,
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _search,
            child: const Text('搜索', style: TextStyle(color: AppColors.brand)),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: [
                _orderChip('relevance', '相关度'),
                _orderChip('latest', '最新'),
                _orderChip('most_replies', '最多回复'),
                _orderChip('most_likes', '最多点赞'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _keyword.isEmpty
                    ? const EmptyView(icon: '🔍', title: '输入关键词搜索')
                    : _topics.isEmpty
                        ? const EmptyView(icon: '📭', title: '没有找到相关内容')
                        : ListView(
                            children: [
                              for (final t in _topics)
                                FeedCard(
                                  topic: t,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            TopicPage(topicId: t.id)),
                                  ),
                                ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _orderChip(String value, String label) {
    final on = _order == value;
    return GestureDetector(
      onTap: () => setState(() {
        _order = value;
        if (_keyword.isNotEmpty) _search();
      }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.brandLight : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: on ? AppColors.brandLight : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: on ? AppColors.brand : AppColors.text2,
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}
