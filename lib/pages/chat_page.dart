import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ios.dart';

/// 私信会话：iOS 风格聊天气泡 + 输入框（带发送动画）。
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.convId, required this.peer});

  final int convId;
  final UserBrief peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ForumApi>();
    try {
      final paged = await api.messages(widget.convId);
      setState(() {
        _messages
          ..clear()
          ..addAll(paged.list.reversed);
        _loading = false;
      });
    } on ApiException {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    final api = context.read<ForumApi>();
    hapticMedium();
    try {
      await api.sendConvMessage(widget.convId, content);
      _controller.clear();
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.peer.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            LevelBadge(level: widget.peer.level, name: widget.peer.levelName),
          ],
        ),
        backgroundColor: AppColors.surface.withOpacity(0.9),
        border: const Border(
            bottom: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const IosLoadingView()
                  : _messages.isEmpty
                      ? const IosEmptyView(
                          icon: '💬', title: '还没有消息', sub: '打个招呼吧')
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) => FadeSlideIn(
                            index: i,
                            distance: 8,
                            child: _bubble(_messages[i]),
                          ),
                        ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              placeholder: '输入消息…',
              style: AppText.subhead,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: AppRadius.capsule,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(onTap: _send),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          // iOS iMessage 风格：自己的消息用蓝色
          color: m.mine ? AppColors.iosBlue : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.mine ? 16 : 4),
            bottomRight: Radius.circular(m.mine ? 4 : 16),
          ),
          border: m.mine
              ? null
              : Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Text(
          m.content,
          style: AppText.subhead.copyWith(
              color: m.mine ? Colors.white : AppColors.text, height: 1.35),
        ),
      ),
    );
  }
}

/// 发送按钮（圆形，按压缩放）
class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: AppMotion.fast,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: AppColors.iosBlue, shape: BoxShape.circle),
          child: const Icon(CupertinoIcons.arrow_up,
              color: Colors.white, size: 19),
        ),
      ),
    );
  }
}
