import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'api/forum_api.dart';
import 'pages/boards_page.dart';
import 'pages/editor_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/me_page.dart';
import 'pages/messages_page.dart';
import 'state/auth_state.dart';
import 'theme.dart';
import 'widgets/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final authStore = AuthStore(prefs);
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    validateStatus: (s) => s != null && s < 500,
  ));
  final apiClient = ApiClient(dio, authStore);
  final forumApi = ForumApi(apiClient);
  final authState = AuthState(authStore, forumApi);

  await authState.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthStore>.value(value: authStore),
        Provider<ApiClient>.value(value: apiClient),
        Provider<ForumApi>.value(value: forumApi),
        ChangeNotifierProvider<AuthState>.value(value: authState),
      ],
      child: const ForumApp(),
    ),
  );
}

class ForumApp extends StatelessWidget {
  const ForumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '社区论坛',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootPage(),
    );
  }
}

/// 根页面：游客也可访问，默认进入首页（主框架第一个 Tab）。
/// 未登录不强制跳登录，需要登录的操作在具体入口处引导。
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Home();
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _unread = 0;

  Future<void> _publish() async {
    // 游客发帖前先引导登录
    if (!context.read<AuthState>().isLoggedIn) {
      final ok = await _requireLogin();
      if (!ok) return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorPage()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('发布成功')));
    }
  }

  /// 引导登录，登录成功返回 true，取消返回 false。
  Future<bool> _requireLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      unreadCount: _unread,
      onPublish: _publish,
      pages: const [
        HomePage(),
        BoardsPage(),
        MessagesPage(),
        MePage(),
      ],
    );
  }
}
