import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';
import '../state/auth_state.dart';
import '../theme.dart';

/// 账号设置：资料编辑 + 设备管理（延续 ui-app 17-settings）。
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
    final controller = TextEditingController(text: user.signature);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改个性签名'),
        content: TextField(controller: controller, maxLength: 120),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('保存')),
        ],
      ),
    );
    if (result != null) {
      final api = context.read<ForumApi>();
      try {
        await api.updateMe(signature: result);
        await auth.refreshUser();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: const Text('账号设置')),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _group('个人资料', [
                  ListTile(
                    leading: const Icon(Icons.badge_outlined, color: AppColors.brand),
                    title: const Text('昵称'),
                    trailing: Text(user.displayName,
                        style: const TextStyle(color: AppColors.text3)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_note, color: AppColors.brand),
                    title: const Text('个性签名'),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.text3),
                    onTap: _editSignature,
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline, color: AppColors.brand),
                    title: const Text('邮箱'),
                    trailing: Text(user.username,
                        style: const TextStyle(color: AppColors.text3)),
                  ),
                ]),
                _group('安全', [
                  ListTile(
                    leading:
                        const Icon(Icons.devices, color: AppColors.purple),
                    title: const Text('设备管理'),
                    subtitle: Text('${_devices.length} 台在线设备'),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.text3),
                    onTap: _showDevices,
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: AppColors.purple),
                    title: const Text('修改密码'),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.text3),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _group(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showDevices() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: _loadingDevices
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
            : ListView(
                shrinkWrap: true,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('设备管理',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  for (final d in _devices)
                    ListTile(
                      leading: const Icon(Icons.smartphone),
                      title: Text(d.deviceName),
                      subtitle: Text('最近活跃 ${d.lastSeen}'),
                      trailing: d.current
                          ? const Text('当前设备',
                              style: TextStyle(
                                  color: AppColors.brand, fontSize: 12))
                          : TextButton(
                              onPressed: () async {
                                final api = context.read<ForumApi>();
                                await api.deviceLogout(d.id);
                                _loadDevices();
                              },
                              child: const Text('下线',
                                  style:
                                      TextStyle(color: AppColors.danger)),
                            ),
                    ),
                ],
              ),
      ),
    );
  }
}
