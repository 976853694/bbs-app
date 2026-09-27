import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme.dart';

/// 注册（延续 ui-app 16-register）。
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
    }
    // 注册成功后 RootPage 的 Consumer 会自动切换到主界面
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('创建账号',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('加入社区，和同好一起交流',
                style: TextStyle(color: AppColors.text3, fontSize: 12)),
            const SizedBox(height: 26),
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                hintText: '用户名（2-20 位字母、数字或中文）',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '密码（至少 8 位，含字母和数字）',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(
                hintText: '确认密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: '邮箱（选填，用于找回密码）',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _agree,
                  activeColor: AppColors.brand,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => setState(() => _agree = v ?? false),
                ),
                const Expanded(
                  child: Text('我已阅读并同意《用户协议》和《隐私政策》',
                      style: TextStyle(fontSize: 12, color: AppColors.text3)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('注册'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
