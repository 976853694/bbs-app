import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme.dart';
import 'register_page.dart';

/// 登录（延续 ui-app 15-login）。
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
    }
    // 登录成功后 RootPage 的 Consumer 会自动切换到主界面
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
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.brand, AppColors.brand2]),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              alignment: Alignment.center,
              child: const Text('论',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            const Text('欢迎回来',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('登录社区论坛，继续你的精彩',
                style: TextStyle(color: AppColors.text3, fontSize: 12)),
            const SizedBox(height: 30),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                hintText: '用户名 / 邮箱',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '密码',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _remember,
                      activeColor: AppColors.brand,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setState(() => _remember = v ?? true),
                    ),
                    const Text('记住我',
                        style: TextStyle(fontSize: 13, color: AppColors.text2)),
                  ],
                ),
                const Spacer(),
                const Text('忘记密码？',
                    style: TextStyle(fontSize: 13, color: AppColors.brand)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('登录'),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider()),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('其他登录方式',
                      style:
                          TextStyle(color: AppColors.text3, fontSize: 12)),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OAuthIcon('💬'),
                SizedBox(width: 16),
                _OAuthIcon('🐧'),
                SizedBox(width: 16),
                _OAuthIcon('🐙'),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('还没有账号？',
                    style: TextStyle(color: AppColors.text2, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterPage())),
                  child: const Text('立即注册',
                      style: TextStyle(color: AppColors.brand, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OAuthIcon extends StatelessWidget {
  const _OAuthIcon(this.emoji);
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}
