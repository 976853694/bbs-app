import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../theme.dart';
import 'ios.dart';

/// 头像：有图显示网络图，无图显示首字 + 色板底色。
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.id,
    this.url,
    this.size = 36,
  });

  final String name;
  final int id;
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarOf(id);
    final initial = name.isNotEmpty ? name.characters.first : '?';
    Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// 等级徽章：延续 .level 渐变。
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.name = ''});

  final int level;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.levelBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        name.isNotEmpty ? name : 'Lv$level',
        style: const TextStyle(
          color: AppColors.levelFg,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 状态徽章：置顶/精华/锁定/悬赏/新帖等。
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text,
      {super.key, this.color, this.bg, this.border = false});

  final String text;
  final Color? color;
  final Color? bg;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.badgeFg;
    final b = bg ?? AppColors.badgeBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: b,
        borderRadius: BorderRadius.circular(4),
        border: border ? Border.all(color: AppColors.border2) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 圆角标签（tag）。
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border2),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.text2, fontSize: 11),
      ),
    );
  }
}

/// 相对时间格式化。
String relativeTime(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 30) return '${diff.inDays} 天前';
    return DateFormat('yyyy-MM-dd').format(dt);
  } catch (_) {
    return '';
  }
}

/// 空状态占位。
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.icon = '📭', this.title = '暂无内容', this.sub});

  final String icon;
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: AppColors.text2,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(sub!,
                  style: const TextStyle(color: AppColors.text3, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载中占位。
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
    );
  }
}

/// 信息流帖子卡片（iOS 风格：按压高亮 + 渐显动画 + 系统蓝版块名）。
class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.topic, this.onTap, this.index = 0});

  final TopicBrief topic;
  final VoidCallback? onTap;
  /// 用于列表入场动画的顺序索引
  final int index;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      index: index,
      child: _FeedCardBody(topic: topic, onTap: onTap),
    );
  }
}

class _FeedCardBody extends StatefulWidget {
  const _FeedCardBody({required this.topic, this.onTap});

  final TopicBrief topic;
  final VoidCallback? onTap;

  @override
  State<_FeedCardBody> createState() => _FeedCardBodyState();
}

class _FeedCardBodyState extends State<_FeedCardBody> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap == null
          ? null
          : () {
              hapticLight();
              widget.onTap!();
            },
      // iOS 按压时整行轻微变灰（iOS 列表行高亮）
      child: AnimatedContainer(
        duration: AppMotion.fast,
        color: _pressed ? AppColors.fill.withOpacity(0.55) : AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
                name: topic.author.displayName,
                id: topic.author.id,
                url: topic.author.avatar),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 徽章行：仅在有状态徽章时显示
                  if (topic.isPinned ||
                      topic.isEssence ||
                      topic.bounty > 0 ||
                      topic.isLocked) ...[
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (topic.isPinned)
                          const StatusBadge('置顶', color: AppColors.danger),
                        if (topic.isEssence)
                          const StatusBadge('精华', color: AppColors.warn),
                        if (topic.bounty > 0)
                          StatusBadge('悬赏 ${topic.bounty}'),
                        if (topic.isLocked) const StatusBadge('锁定'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  // 标题：独立一行，可换行最多两行
                  Text(
                    topic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(topic.board.name,
                          style: const TextStyle(
                              color: AppColors.iosBlue, fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${topic.author.displayName} · ${relativeTime(topic.createdAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _stat(CupertinoIcons.eye, topic.viewCount),
                      const SizedBox(width: 14),
                      _stat(CupertinoIcons.chat_bubble, topic.replyCount),
                      const SizedBox(width: 14),
                      _stat(CupertinoIcons.hand_thumbsup, topic.likeCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, int n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.text3),
        const SizedBox(width: 3),
        Text('$n',
            style: const TextStyle(color: AppColors.text3, fontSize: 11)),
      ],
    );
  }
}

/// iOS 风格白色圆角卡片容器（圆角 14，无重阴影）。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
