import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';

/// 积分中心：iOS 风格头图 + 等级进度 + 商城 + 勋章。
class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  PointsOverview? _overview;
  List<ShopItem> _shop = [];
  List<Medal> _medals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ForumApi>();
    try {
      final overview = await api.points();
      final shop = await api.shop();
      final medals = await api.medals();
      setState(() {
        _overview = overview;
        _shop = shop;
        _medals = medals;
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkin() async {
    final api = context.read<ForumApi>();
    hapticMedium();
    try {
      final (gained, message) = await api.checkin();
      _toast('$message（+$gained）');
      _load();
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _redeem(ShopItem item) async {
    final api = context.read<ForumApi>();
    final confirm = await iosConfirm(
      context,
      title: '兑换 ${item.name}',
      message: '消耗 ${item.cost} 积分，确认兑换？',
      confirmText: '兑换',
    );
    if (!confirm) return;
    try {
      await api.redeem(item.id);
      _toast('兑换成功');
      hapticMedium();
      _load();
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
    final ov = _overview;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          const CupertinoSliverNavigationBar(
            middle: Text('积分中心'),
            backgroundColor: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.separator, width: 0.5),
            ),
          ),
          CupertinoSliverRefreshControl(onRefresh: _load),
          if (_loading)
            const SliverToBoxAdapter(
              child: SizedBox(height: 300, child: IosLoadingView()),
            )
          else ...[
            SliverToBoxAdapter(child: _hero(ov!)),
            SliverToBoxAdapter(child: _levelCard(ov)),
            SliverToBoxAdapter(child: _shopCard()),
            SliverToBoxAdapter(child: _medalCard()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _hero(PointsOverview ov) {
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.iosBlue, AppColors.brand],
          ),
          borderRadius: AppRadius.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ov.points}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('连续签到 ${ov.checkinStreak} 天',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12)),
                ],
              ),
            ),
            // 签到按钮（按压缩放）
            _CheckinButton(
              checkedToday: ov.checkedToday,
              onTap: _checkin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(PointsOverview ov) {
    final progress =
        ov.nextExp > 0 ? (ov.exp / ov.nextExp).clamp(0.0, 1.0) : 0.0;
    return FadeSlideIn(
      index: 1,
      child: AppCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(ov.levelName,
                    style: AppText.headline),
                const SizedBox(width: 6),
                LevelBadge(level: ov.level, name: 'Lv${ov.level}'),
                const Spacer(),
                Text('${ov.exp} / ${ov.nextExp} 经验',
                    style: AppText.caption.copyWith(color: AppColors.text3)),
              ],
            ),
            const SizedBox(height: 11),
            // iOS 风格进度条（圆角 + 动画）
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 900),
              curve: AppMotion.decelerate,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.fill,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.iosBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 16, 8),
          child: Text('🛍 积分商城', style: AppText.groupHeader),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (var i = 0; i < _shop.length; i++)
                FadeSlideIn(index: i, child: _ShopCard(
                  item: _shop[i],
                  onTap: () => _redeem(_shop[i]),
                )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medalCard() {
    if (_medals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 16, 8),
          child: Text('🎖️ 勋章墙', style: AppText.groupHeader),
        ),
        SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _medals.length,
            itemBuilder: (context, i) => FadeSlideIn(
              index: i,
              child: Container(
                width: 74,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.surface3,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(_medals[i].icon.isEmpty ? '🏅' : _medals[i].icon,
                          style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 5),
                    Text(_medals[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption2.copyWith(
                            color: AppColors.text2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 签到按钮（按压缩放）
class _CheckinButton extends StatefulWidget {
  const _CheckinButton({required this.checkedToday, required this.onTap});

  final bool checkedToday;
  final VoidCallback onTap;

  @override
  State<_CheckinButton> createState() => _CheckinButtonState();
}

class _CheckinButtonState extends State<_CheckinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final done = widget.checkedToday;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: done ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppMotion.fast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: done ? Colors.white24 : Colors.white,
            borderRadius: AppRadius.capsule,
          ),
          child: Text(
            done ? '已签到 ✓' : '签到 +5',
            style: TextStyle(
              color: done ? Colors.white : AppColors.brand,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// 商城商品卡片（按压缩放）
class _ShopCard extends StatefulWidget {
  const _ShopCard({required this.item, required this.onTap});

  final ShopItem item;
  final VoidCallback onTap;

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.icon.isEmpty ? '🎁' : item.icon,
                  style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.subhead.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text('${item.cost} 积分',
                  style: AppText.caption.copyWith(
                      color: AppColors.iosBlue, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
