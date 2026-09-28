import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/ios.dart';
import 'board_detail_page.dart';

/// 版块列表：iOS 风格网格卡片 + 骨架屏 + 入场动画。
class BoardsPage extends StatefulWidget {
  const BoardsPage({super.key});

  @override
  State<BoardsPage> createState() => _BoardsPageState();
}

class _BoardsPageState extends State<BoardsPage>
    with AutomaticKeepAliveClientMixin {
  List<BoardGroup> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<ForumApi>();
      final groups = await api.boards();
      setState(() {
        _groups = groups;
        _error = null;
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            middle: Text('版块'),
            backgroundColor: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: _load),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _BoardSkeleton(),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: IosEmptyView(
                icon: '⚠️',
                title: '加载失败',
                sub: _error,
                action: IosButton(
                  label: '重试',
                  expand: false,
                  onTap: _load,
                ),
              ),
            )
          else ...[
            for (var gi = 0; gi < _groups.length; gi++) ...[
              // iOS 分组标题
              SliverToBoxAdapter(
                child: FadeSlideIn(
                  index: gi,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                    child: Text(_groups[gi].name, style: AppText.groupHeader),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final b = _groups[gi].boards[i];
                      return FadeSlideIn(
                        index: gi * 2 + i,
                        child: _BoardCard(
                          board: b,
                          onTap: () => Navigator.push(
                            context,
                            iosRoute<void>(BoardDetailPage(slug: b.slug)),
                          ),
                        ),
                      );
                    },
                    childCount: _groups[gi].boards.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ],
      ),
    );
  }
}

/// 版块卡片（iOS 风格，按压缩放）
class _BoardCard extends StatefulWidget {
  const _BoardCard({required this.board, required this.onTap});

  final BoardBrief board;
  final VoidCallback onTap;

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.board;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        hapticLight();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.ease,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand2, AppColors.brand],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  b.icon.isEmpty ? '💬' : b.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const Spacer(),
              Text(
                b.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.subhead.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '主题 ${b.topicCount} · 今日 ${b.todayCount}',
                style: AppText.caption2.copyWith(color: AppColors.text3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 版块骨架屏
class _BoardSkeleton extends StatelessWidget {
  const _BoardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var g = 0; g < 2; g++) ...[
          const Skeleton(
            width: 80,
            height: 12,
            margin: EdgeInsets.only(bottom: 10, top: 6),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              for (var i = 0; i < 4; i++)
                const Skeleton(radius: 14, height: double.infinity),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
