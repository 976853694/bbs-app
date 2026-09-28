import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme.dart';
import '../widgets/ios.dart';
import 'register_page.dart';

/// 登录（iOS 风格表单）。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      _toast('请输入用户名和密码');
      return;
    }
    final auth = context.read<AuthState>();
    final ok = await auth.login(username, password);
    if (!mounted) return;
    if (!ok) {
      _toast(auth.error ?? '登录失败');
      return;
    }
    hapticMedium();
    // 登录成功：返回上一页（true），由调用方决定后续动作
    Navigator.pop(context, true);
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
            const SizedBox(height: 26),
            // 品牌头
            Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.brand, AppColors.brand2]),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text('论',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: Text('欢迎回来', style: AppText.title2)),
            const SizedBox(height: 4),
            Center(
              child: Text('登录社区论坛，继续你的精彩',
                  style: AppText.footnote.copyWith(color: AppColors.text3)),
            ),
            const SizedBox(height: 30),
            // 用户名
            CupertinoTextField(
              controller: _username,
              placeholder: '用户名 / 邮箱',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.person,
                    size: 19, color: AppColors.text3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator, width: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            // 密码
            CupertinoTextField(
              controller: _password,
              placeholder: '密码',
              obscureText: _obscure,
              prefix: const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(CupertinoIcons.lock,
                    size: 19, color: AppColors.text3),
              ),
              suffix: CupertinoButton(
                padding: const EdgeInsets.only(right: 8),
                minSize: 0,
                onPressed: () => setState(() => _obscure = !_obscure),
                child: Icon(
                    _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                    size: 19,
                    color: AppColors.text3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.separator, width: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            // 记住我
            Row(
              children: [
                CupertinoSwitch(
                  value: _remember,
                  activeColor: AppColors.success,
                  onChanged: (v) => setState(() => _remember = v),
                ),
                const SizedBox(width: 8),
                const Text('记住我',
                    style: AppText.subhead),
              ],
            ),
            const SizedBox(height: 22),
            // 登录按钮
            IosButton(
              label: loading ? '登录中…' : '登录',
              onTap: _login,
              enabled: !loading,
            ),
            const SizedBox(height: 26),
            // 注册入口
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('还没有账号？',
                    style: AppText.subhead),
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 4),
                  minSize: 0,
                  onPressed: () => Navigator.push(
                      context, iosRoute<void>(const RegisterPage())),
                  child: const Text('立即注册',
                      style: TextStyle(
                          color: AppColors.iosBlue, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
