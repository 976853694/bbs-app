import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/ios.dart';

/// 账号设置：资料编辑 + 设备管理（iOS 分组列表风格）。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<DeviceSession> _devices = [];
  bool _loadingDevices = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final api = context.read<ForumApi>();
    try {
      final devices = await api.devices();
      setState(() {
        _devices = devices;
        _loadingDevices = false;
      });
    } on ApiException {
      setState(() => _loadingDevices = false);
    }
  }

  Future<void> _editSignature() async {
    final auth = context.read<AuthState>();
    final user = auth.user;
    if (user == null) return;
    final result = await iosPrompt(
      context,
      title: '修改个性签名',
      initialValue: user.signature,
      placeholder: '介绍一下自己…',
      maxLength: 120,
    );
    if (result == null) return;
    final api = context.read<ForumApi>();
    try {
      await api.updateMe(signature: result);
      await auth.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已保存')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('账号设置'),
        backgroundColor: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.separator)),
      ),
      child: SafeArea(
        child: user == null
            ? const IosEmptyView(icon: '👤', title: '请先登录')
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 30),
                children: [
                  IosGroupCard(
                    header: '个人资料',
                    children: [
                      IosCell(
                        icon: CupertinoIcons.person,
                        title: '昵称',
                        value: user.displayName,
                      ),
                      IosCell(
                        icon: CupertinoIcons.pencil,
                        title: '个性签名',
                        value: user.signature.isEmpty
                            ? '这个人很懒～'
                            : user.signature,
                        showArrow: true,
                        onTap: _editSignature,
                      ),
                      IosCell(
                        icon: CupertinoIcons.mail,
                        title: '用户名',
                        value: '@${user.username}',
                      ),
                    ],
                  ),
                  IosGroupCard(
                    header: '安全',
                    children: [
                      IosCell(
                        icon: CupertinoIcons.device_phone_portrait,
                        iconBg: AppColors.purple,
                        title: '设备管理',
                        subtitle: '${_devices.length} 台在线设备',
                        showArrow: true,
                        onTap: _showDevices,
                      ),
                    ],
                  ),
                  IosGroupCard(
                    children: [
                      IosCell(
                        title: '退出登录',
                        isDestructive: true,
                        centerTitle: true,
                        onTap: () async {
                          final ok = await iosConfirm(
                            context,
                            title: '退出登录',
                            message: '确定要退出当前账号吗？',
                            confirmText: '退出',
                            isDestructive: true,
                          );
                          if (!ok || !context.mounted) return;
                          await auth.logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已退出登录')));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _showDevices() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('设备管理'),
        message: Text('共 ${_devices.length} 台设备'),
        actions: [
          for (final d in _devices)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.device_phone_portrait, size: 18),
                  const SizedBox(width: 8),
                  Text(d.deviceName),
                  if (d.current) ...[
                    const SizedBox(width: 6),
                    const Text('（当前）',
                        style: TextStyle(
                            color: AppColors.iosBlue, fontSize: 13)),
                  ],
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('关闭', style: TextStyle(color: AppColors.iosBlue)),
        ),
      ),
    );
  }
}
