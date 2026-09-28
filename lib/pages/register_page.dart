import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/ios.dart';

/// 注册（iOS 风格表单）。
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _email = TextEditingController();
  bool _obscure = true;
  bool _agree = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _username.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;
    if (username.isEmpty || password.isEmpty) {
      _toast('请填写完整信息');
      return;
    }
    if (password != confirm) {
      _toast('两次密码不一致');
      return;
    }
    if (!_agree) {
      _toast('请先同意用户协议');
      return;
    }
    final auth = context.read<AuthState>();
    final ok =
        await auth.register(username, password, email: _email.text.trim());
    if (!mounted) return;
    if (!ok) {
      _toast(auth.error ?? '注册失败');
      return;
    }
    hapticMedium();
    _toast('注册成功，已自动登录');
    // 注册成功，返回上一页
    if (mounted) Navigator.pop(context, true);
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthState>().loading;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.iosGroupedBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.white,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 26),
          children: [
            const SizedBox(height: 14),
            const Text('创建账号', style: AppText.title2),
            const SizedBox(height: 4),
            Text('加入社区，和同好一起交流',
                style: AppText.footnote.copyWith(color: AppColors.text3)),
            const SizedBox(height: 26),
            _field(
              controller: _username,
              placeholder: '用户名（2-20 位字母、数字或中文）',
              icon: CupertinoIcons.person,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _password,
              placeholder: '密码（至少 8 位，含字母和数字）',
              icon: CupertinoIcons.lock,
              obscure: true,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _confirm,
              placeholder: '确认密码',
              icon: CupertinoIcons.lock,
              obscure: true,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _email,
              placeholder: '邮箱（选填，用于找回密码）',
              icon: CupertinoIcons.mail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            // 协议勾选（iOS 开关风格）
            Row(
              children: [
                CupertinoSwitch(
                  value: _agree,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _agree = v),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('我已阅读并同意《用户协议》和《隐私政策》',
                      style: AppText.caption),
                ),
              ],
            ),
            const SizedBox(height: 20),
            IosButton(
              label: loading ? '注册中…' : '注册',
              onTap: _register,
              enabled: !loading,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscure ? _obscure : false,
      keyboardType: keyboardType,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Icon(icon, size: 19, color: AppColors.text3),
      ),
      suffix: obscure
          ? CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              minSize: 0,
              onPressed: () => setState(() => _obscure = !_obscure),
              child: Icon(
                  _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 19,
                  color: AppColors.text3),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
    );
  }
}
