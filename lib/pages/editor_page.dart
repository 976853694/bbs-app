import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布主题'),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brand))
                : const Text('发布', style: TextStyle(color: AppColors.brand)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _boardSelector(),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            maxLength: 100,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: '请输入标题（不超过 100 字）',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: '支持 Markdown 语法…',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('发布即代表同意《社区规范》· 敏感词将触发审核',
              style: TextStyle(color: AppColors.text3, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _boardSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.forum_outlined, color: AppColors.brand),
        title: Text(_board?.name ?? '选择版块'),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () async {
          final selected = await showModalBottomSheet<BoardBrief>(
            context: context,
            builder: (ctx) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final g in _groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(g.name,
                          style: const TextStyle(
                              color: AppColors.text3, fontSize: 12)),
                    ),
                    for (final b in g.boards)
                      ListTile(
                        leading: Text(b.icon),
                        title: Text(b.name),
                        onTap: () => Navigator.pop(ctx, b),
                      ),
                  ],
                ],
              ),
            ),
          );
          if (selected != null) setState(() => _board = selected);
        },
      ),
    );
  }
}
