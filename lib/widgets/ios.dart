import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ============================================================
// 页面转场：iOS 风格（右滑进入 + 边缘滑动返回）
// ============================================================

/// iOS 风格页面路由：新页面从右侧滑入，支持从左边缘滑动返回。
/// Android 上同样生效，保持统一的苹果体验。
Route<T> iosRoute<T>(Widget page, {RouteSettings? settings}) {
  return CupertinoPageRoute<T>(
    builder: (_) => page,
    settings: settings,
  );
}

/// 从底部弹出的 iOS 模态页（Sheet 风格）。
Route<T> iosModalRoute<T>(Widget page, {RouteSettings? settings}) {
  return CupertinoPageRoute<T>(
    builder: (_) => page,
    settings: settings,
    fullscreenDialog: true,
  );
}

/// 淡入淡出转场（用于登录页等无返回关系的场景）。
Route<T> fadeRoute<T>(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: AppMotion.pageTransition,
    reverseTransitionDuration: AppMotion.fast,
    pageBuilder: (_, anim, __) => page,
    transitionsBuilder: (_, anim, ___, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: AppMotion.ease),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: AppMotion.decelerate)),
        child: child,
      ),
    ),
  );
}

// ============================================================
// 触感反馈：iOS Haptic
// ============================================================

/// 轻触感（选中、切换）
void hapticLight() => HapticFeedback.lightImpact();
/// 中等触感（点赞、提交）
void hapticMedium() => HapticFeedback.mediumImpact();
/// 重触感（重要操作）
void hapticHeavy() => HapticFeedback.heavyImpact();
/// 选择反馈（滚动选择器）
void hapticSelection() => HapticFeedback.selectionClick();

// ============================================================
// 列表项入场动画：淡入 + 上滑（iOS 列表加载感）
// ============================================================

/// 列表项逐个淡入上滑，index 越大延迟越久，形成瀑布式入场。
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = 28,
    this.distance = 14,
    this.duration = AppMotion.itemIn,
    this.curve = AppMotion.decelerate,
  });

  final Widget child;
  final int index;
  /// 每项之间的延迟毫秒（总延迟会被限制，避免长列表等待太久）
  final int delayStep;
  /// 上滑距离
  final double distance;
  final Duration duration;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: widget.curve),
    );
    _offset = Tween<Offset>(
      begin: Offset(0, widget.distance / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));

    // 延迟上限 400ms，保证长列表也能快速显示
    final delay = (widget.index * widget.delayStep).clamp(0, 400);
    Future<void>.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

// ============================================================
// iOS 分组卡片容器（inset grouped）
// ============================================================

/// iOS 设置页风格的分组容器：白色圆角卡片 + 内部左缩进分隔线。
class IosGroupCard extends StatelessWidget {
  const IosGroupCard({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showSeparators = true,
  });

  final List<Widget> children;
  /// 分组上方标题（灰字）
  final String? header;
  /// 分组下方说明（灰字小字）
  final String? footer;
  final EdgeInsetsGeometry margin;
  final bool showSeparators;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(header!, style: AppText.groupHeader),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.card,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  // 单元格之间的左缩进分隔线（最后一项不加）
                  if (showSeparators && i < children.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Divider(height: 0.5, thickness: 0.5),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(
                footer!,
                style: AppText.caption.copyWith(color: AppColors.text3),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// iOS 单元格（List Tile）
// ============================================================

/// iOS 风格单元格：左侧图标/标题，右侧值 + 可选箭头，带 iOS 按压高亮。
class IosCell extends StatelessWidget {
  const IosCell({
    super.key,
    this.icon,
    this.iconColor,
    this.iconBg,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.showArrow = false,
    this.trailing,
    this.titleColor,
    this.isDestructive = false,
    this.centerTitle = false,
  });

  final IconData? icon;
  final Color? iconColor;
  final Color? iconBg;
  final String title;
  final String? subtitle;
  /// 右侧灰色值文本
  final String? value;
  final VoidCallback? onTap;
  /// 是否显示右侧箭头（iOS  disclosing）
  final bool showArrow;
  /// 自定义右侧组件（优先于 value / showArrow）
  final Widget? trailing;
  final Color? titleColor;
  /// 危险操作（红色文字，如退出登录）
  final bool isDestructive;
  /// 标题居中（用于退出登录等）
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppText.body.copyWith(
      color: isDestructive ? AppColors.danger : (titleColor ?? AppColors.text),
    );

    Widget? leadingWidget;
    if (icon != null) {
      leadingWidget = Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(
          color: iconBg ?? AppColors.iosBlue,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: iconColor ?? Colors.white),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      borderRadius: BorderRadius.zero,
      // iOS 按压时灰色高亮
      color: Colors.transparent,
      pressedOpacity: 1,
      onPressed: onTap == null
          ? null
          : () {
              hapticSelection();
              onTap!();
            },
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.transparent,
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: centerTitle
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: titleStyle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.caption.copyWith(color: AppColors.text3),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else ...[
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(color: AppColors.text3),
                  ),
                ),
              ],
              if (showArrow) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.text3,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// iOS 骨架屏（加载占位）
// ============================================================

/// 骨架屏微光动画
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppMotion.shimmer)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8E8ED),
                Color(0xFFF5F5F7),
                Color(0xFFE8E8ED),
              ],
              stops: [0.0, (t * 2 - 0.5).clamp(0.0, 1.0), 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// 帖子列表骨架屏（首页/版块加载时显示）
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.count = 5});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, i) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 36, height: 36, radius: 18),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(
                    width: double.infinity,
                    height: 15,
                    margin: const EdgeInsets.only(bottom: 7),
                  ),
                  Skeleton(
                    width: i % 2 == 0 ? 180 : 140,
                    height: 11,
                    margin: const EdgeInsets.only(bottom: 9),
                  ),
                  const Skeleton(width: 110, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// iOS 下拉刷新
// ============================================================

/// iOS 风格下拉刷新控件（Cupertino 风格）
class IosRefresh extends StatelessWidget {
  const IosRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

// ============================================================
// iOS 弹窗 / 确认框
// ============================================================

/// iOS 风格确认对话框（CupertinoAlertDialog）
Future<bool> iosConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmText = '确认',
  String cancelText = '取消',
  bool isDestructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          isDestructiveAction: isDestructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// iOS 风格输入对话框
Future<String?> iosPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String? initialValue,
  String? placeholder,
  int maxLength = 120,
  int maxLines = 1,
}) async {
  final controller = TextEditingController(text: initialValue ?? '');
  return showCupertinoDialog<String>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Column(
        children: [
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text(message, style: AppText.footnote),
            ),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            maxLength: maxLength,
            maxLines: maxLines,
            autofocus: true,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

/// iOS 风格底部动作面板（Action Sheet）
Future<T?> iosActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<CupertinoActionSheetAction> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (ctx) => CupertinoActionSheet(
      title: title == null ? null : Text(title),
      message: message == null ? null : Text(message),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(ctx),
        child: const Text('取消', style: TextStyle(color: AppColors.iosBlue)),
      ),
    ),
  );
}

// ============================================================
// iOS 分段控件（Segmented Control）
// ============================================================

/// iOS 分段控件（带滑动指示器动画）
class IosSegmented extends StatelessWidget {
  const IosSegmented({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: _SegmentItem(
                label: tabs[i],
                selected: i == selected,
                isFirst: i == 0,
                isLast: i == tabs.length - 1,
                onTap: () {
                  hapticSelection();
                  onChanged(i);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(7) : Radius.zero,
          right: isLast ? const Radius.circular(7) : Radius.zero,
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        borderRadius: BorderRadius.zero,
        onPressed: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: AppText.footnote.copyWith(
              color: selected ? AppColors.text : AppColors.text2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// iOS 卡片容器
// ============================================================

/// iOS 风格白色圆角卡片
class IosCard extends StatelessWidget {
  const IosCard({
    super.key,
    required this.child,
    this.padding,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

// ============================================================
// iOS 按钮
// ============================================================

/// iOS 风格主按钮（带按压缩放动画）
class IosButton extends StatefulWidget {
  const IosButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.iosBlue,
    this.textColor = Colors.white,
    this.enabled = true,
    this.expand = true,
    this.icon,
    this.height = 48,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool enabled;
  final bool expand;
  final IconData? icon;
  final double height;

  @override
  State<IosButton> createState() => _IosButtonState();
}

class _IosButtonState extends State<IosButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      child: Container(
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.enabled ? widget.color : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize:
              widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon,
                  size: 19,
                  color: widget.enabled ? widget.textColor : AppColors.text3),
              const SizedBox(width: 7),
            ],
            Text(
              widget.label,
              style: AppText.headline.copyWith(
                color: widget.enabled ? widget.textColor : AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );

    final btn = GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled
          ? () {
              hapticLight();
              widget.onTap();
            }
          : null,
      child: content,
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: btn)
        : btn;
  }
}

// ============================================================
// iOS 加载指示器
// ============================================================

/// iOS 风车加载指示器
class IosLoading extends StatelessWidget {
  const IosLoading({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? AppColors.iosGrayBlue,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}

/// iOS 风格居中加载占位
class IosLoadingView extends StatelessWidget {
  const IosLoadingView({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 13),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, style: AppText.footnote),
          ],
        ],
      ),
    );
  }
}

/// iOS 风格空状态
class IosEmptyView extends StatelessWidget {
  const IosEmptyView({
    super.key,
    this.icon = '📭',
    this.title = '暂无内容',
    this.sub,
    this.action,
  });

  final String icon;
  final String title;
  final String? sub;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 38)),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppText.headline.copyWith(color: AppColors.text2),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                style: AppText.footnote.copyWith(color: AppColors.text3),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
