import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api_types.dart';

/// API 客户端：统一响应解析、Bearer JWT、自动 refresh 轮换、cursor 分页、幂等键。
class ApiClient {
  ApiClient(this._dio, this._auth);

  final Dio _dio;
  final AuthStore _auth;

  /// 供 ForumApi 访问设备信息与 token 存储。
  AuthStore get auth => _auth;

  static const _uuid = Uuid();

  /// 基础 URL 由 AuthStore 提供（可运行时配置）。
  String get _baseUrl => _auth.baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final full = _baseUrl.endsWith('/')
        ? '${_baseUrl}api/v1/$path'
        : '$_baseUrl/api/v1/$path';
    return Uri.parse(full).replace(queryParameters: query);
  }

  Map<String, dynamic> _headers({bool idempotent = false}) {
    final h = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = _auth.accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    if (idempotent) {
      h['Idempotency-Key'] = _uuid.v4();
    }
    return h;
  }

  /// 核心请求：解析统一响应，处理 401 自动刷新，抛出 ApiException。
  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool idempotent = false,
    bool auth = true,
  }) async {
    final options = Options(headers: _headers(idempotent: idempotent));
    final uri = _uri(path, query);

    try {
      final res = await _dio.requestUri(
        uri,
        data: body,
        options: options,
      );
      final result = ApiResult.parse(res.data);
      if (!result.ok) {
        throw ApiException(result.code, result.message,
            statusCode: res.statusCode);
      }
      return result.data;
    } on DioException catch (e) {
      // 401 且带 refresh token 时，尝试刷新一次后重试
      if (e.response?.statusCode == 401 && auth && _auth.refreshToken != null) {
        final refreshed = await _tryRefresh();
        if (refreshed) {
          final retryOptions = Options(headers: _headers(idempotent: idempotent));
          final retry = await _dio.requestUri(uri, data: body, options: retryOptions);
          final result = ApiResult.parse(retry.data);
          if (!result.ok) {
            throw ApiException(result.code, result.message,
                statusCode: retry.statusCode);
          }
          return result.data;
        }
      }
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map) {
        final result = ApiResult.parse(data);
        throw ApiException(result.code, result.message, statusCode: statusCode);
      }
      throw ApiException(-1, '网络请求失败，请稍后重试', statusCode: statusCode);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = _auth.refreshToken;
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _dio.post(
        _uri('auth/refresh').toString(),
        options: Options(headers: {
          'Authorization': 'Bearer $refresh',
          'Content-Type': 'application/json',
        }),
      );
      final result = ApiResult.parse(res.data);
      if (result.ok) {
        await _auth.saveTokens(result.data);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ---------- 便捷方法 ----------
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      request('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool idempotent = false}) =>
      request('POST', path, body: body, idempotent: idempotent);

  Future<dynamic> put(String path, {Object? body}) =>
      request('PUT', path, body: body);

  Future<dynamic> delete(String path) => request('DELETE', path);

  /// 上传文件（头像/附件）。
  Future<dynamic> upload(String path, String field, List<int> bytes,
      String filename) async {
    final form = FormData.fromMap({
      field: MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post(
      _uri(path).toString(),
      data: form,
      options: Options(headers: _headers()),
    );
    final result = ApiResult.parse(res.data);
    if (!result.ok) {
      throw ApiException(result.code, result.message);
    }
    return result.data;
  }
}

/// 令牌与设备信息持久化。
class AuthStore {
  AuthStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kDeviceId = 'device_id';
  static const _kBaseUrl = 'base_url';

  /// 默认后端地址（开发期本机；Android 模拟器用 10.0.2.2）。
  static const defaultBaseUrl = 'http://10.0.2.2:8000/';

  String get baseUrl => _prefs.getString(_kBaseUrl) ?? defaultBaseUrl;

  Future<void> setBaseUrl(String url) => _prefs.setString(_kBaseUrl, url);

  String? get accessToken => _prefs.getString(_kAccess);
  String? get refreshToken => _prefs.getString(_kRefresh);

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  String get deviceId {
    var id = _prefs.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      _prefs.setString(_kDeviceId, id);
    }
    return id;
  }

  String get deviceName => 'App';

  Future<void> saveTokens(Map<String, dynamic> data) async {
    if (data['access_token'] != null) {
      await _prefs.setString(_kAccess, data['access_token'] as String);
    }
    if (data['refresh_token'] != null) {
      await _prefs.setString(_kRefresh, data['refresh_token'] as String);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
  }
}
