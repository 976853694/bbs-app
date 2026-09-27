import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_types.dart';
import '../api/forum_api.dart';
import '../models.dart';

/// 全局认证状态：登录用户、token、登录/登出/刷新。
class AuthState extends ChangeNotifier {
  AuthState(this._auth, this._api);

  final AuthStore _auth;
  final ForumApi _api;

  UserDetail? _user;
  UserDetail? get user => _user;

  bool get isLoggedIn => _auth.isLoggedIn;

  bool _loading = false;
  bool get loading => _loading;

  String? get accessToken => _auth.accessToken;

  String? _error;
  String? get error => _error;

  Future<void> bootstrap() async {
    if (!isLoggedIn) return;
    try {
      _user = await _api.me();
      notifyListeners();
    } catch (_) {
      // token 失效则静默清除
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final (user, _) = await _api.login(username, password);
      _user = user;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String password, {String? email}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final (user, _) = await _api.register(username, password, email: email);
      _user = user;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      _user = await _api.me();
      notifyListeners();
    } catch (_) {}
  }
}
