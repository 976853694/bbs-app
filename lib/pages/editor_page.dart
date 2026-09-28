import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/ios.dart';

/// 发帖编辑器：选版块 + 标题 + Markdown 正文（延续 ui-app 07-editor）。
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<BoardGroup> _groups = [];
  BoardBrief? _board;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    final api = context.read<ForumApi>();
    try {
      final groups = await api.boards();
      setState(() => _groups = groups);
    } on ApiException {}
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (_board == null) {
      _toast('请选择版块');
      return;
    }
    if (title.length < 2) {
      _toast('标题至少 2 个字');
      return;
    }
    setState(() => _submitting = true);
    final api = context.read<ForumApi>();
    try {
      await api.createTopic(
          boardId: _board!.id, title: title, content: content);
      _toast('发布成功');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      setState(() => _submitting = false);
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
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('发布主题'),
        backgroundColor: AppColors.surface.withOpacity(0.9),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消',
              style: TextStyle(color: AppColors.iosBlue, fontSize: 16)),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const CupertinoActivityIndicator(radius: 9)
              : const Text('发布',
                  style: TextStyle(
                      color: AppColors.iosBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
        ),
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _boardSelector(),
            const SizedBox(height: 14),
            // 标题
            CupertinoTextField(
              controller: _titleController,
              placeholder: '请输入标题（不超过 100 字）',
              maxLength: 100,
              style: AppText.headline,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator, width: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            // 正文
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator, width: 0.5),
              ),
              child: CupertinoTextField(
                controller: _contentController,
                placeholder: '支持 Markdown 语法…',
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: AppText.subhead,
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
            const SizedBox(height: 14),
            const Text('发布即代表同意《社区规范》· 敏感词将触发审核',
                style: AppText.caption2),
          ],
        ),
      ),
    );
  }

  Widget _boardSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        borderRadius: BorderRadius.zero,
        onPressed: _pickBoard,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(CupertinoIcons.square_grid_2x2,
                  size: 19, color: AppColors.iosBlue),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  _board?.name ?? '选择版块',
                  style: AppText.subhead.copyWith(
                      color: _board == null
                          ? AppColors.text3
                          : AppColors.text),
                ),
              ),
              const Icon(CupertinoIcons.chevron_down,
                  size: 15, color: AppColors.text3),
            ],
          ),
        ),
      ),
    );
  }

  /// iOS 风格版块选择弹窗
  Future<void> _pickBoard() async {
    final selected = await showCupertinoModalPopup<BoardBrief>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          // iOS 弹层圆角
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: AppColors.separator, width: 0.5)),
                ),
                child: const Center(
                  child: Text('选择版块', style: AppText.headline),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final g in _groups) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
                        child: Text(g.name, style: AppText.groupHeader),
                      ),
                      for (final b in g.boards)
                        IosCell(
                          icon: CupertinoIcons.number,
                          iconBg: AppColors.brandLight,
                          iconColor: AppColors.brand,
                          title: '${b.icon}  ${b.name}',
                          onTap: () => Navigator.pop(ctx, b),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      hapticSelection();
      setState(() => _board = selected);
    }
  }
}
