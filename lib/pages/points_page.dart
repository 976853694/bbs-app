import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 积分中心：签到 + 等级进度 + 商城 + 勋章 + 流水（延续 ui-app 10-points）。
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('兑换 ${item.name}'),
        content: Text('消耗 ${item.cost} 积分，确认兑换？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await api.redeem(item.id);
      _toast('兑换成功');
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
    return Scaffold(
      appBar: AppBar(title: const Text('积分中心')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              color: AppColors.brand,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _hero(ov!),
                  _levelCard(ov),
                  _shopCard(),
                  _medalCard(),
                ],
              ),
            ),
    );
  }

  Widget _hero(PointsOverview ov) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.brand, AppColors.purple]),
        borderRadius: BorderRadius.circular(12),
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
                        fontSize: 28,
                        fontWeight: FontWeight.w700)),
                Text('连续签到 ${ov.checkinStreak} 天',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: ov.checkedToday ? null : _checkin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: ov.checkedToday ? Colors.white24 : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ov.checkedToday ? '已签到 ✓' : '签到 +5',
                style: TextStyle(
                  color: ov.checkedToday ? Colors.white : AppColors.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelCard(PointsOverview ov) {
    final progress =
        ov.nextExp > 0 ? (ov.exp / ov.nextExp).clamp(0.0, 1.0) : 0.0;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${ov.levelName}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              LevelBadge(level: ov.level, name: 'Lv${ov.level}'),
              const Spacer(),
              Text('$ov.exp / ${ov.nextExp} 经验',
                  style: const TextStyle(color: AppColors.text3, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDF0F4),
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('🛍 积分商城',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              for (final item in _shop)
                AppCard(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _redeem(item),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.icon.isEmpty ? '🎁' : item.icon,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 6),
                          Text(item.name,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Text('${item.cost} 积分',
                              style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('🎖️ 勋章墙',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              for (final m in _medals)
                Container(
                  width: 72,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: AppColors.surface2,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(m.icon.isEmpty ? '🏅' : m.icon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 4),
                      Text(m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text2, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
