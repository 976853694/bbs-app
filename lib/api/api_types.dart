import 'dart:convert';

import 'package:dio/dio.dart';

/// 统一 API 异常，携带后端错误码与提示。
class ApiException implements Exception {
  final int code;
  final String message;
  final int? statusCode;

  ApiException(this.code, this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 后端统一响应：{ code, message, data }，code == 0 表示成功。
class ApiResult {
  final int code;
  final String message;
  final dynamic data;

  ApiResult(this.code, this.message, this.data);

  bool get ok => code == 0;

  static ApiResult parse(dynamic raw) {
    final map = raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map);
    return ApiResult(
      (map['code'] as num?)?.toInt() ?? -1,
      map['message'] as String? ?? '',
      map['data'],
    );
  }
}

/// 分页数据（cursor 游标分页）。
class Paged<T> {
  final List<T> list;
  final int total;
  final bool hasMore;
  final String cursor;

  Paged(this.list, this.total, this.hasMore, this.cursor);
}
