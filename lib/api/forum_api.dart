import '../models.dart';
import 'api_client.dart';

/// 论坛 API 服务层：把后端接口封装成强类型方法，供页面与状态调用。
class ForumApi {
  ForumApi(this._client);

  final ApiClient _client;

  // ---------- 认证 ----------
  Future<(UserDetail, Map<String, dynamic>)> login(
      String username, String password) async {
    final data = await _client.post('auth/login', body: {
      'username': username,
      'password': password,
      'device_id': _client.auth.deviceId,
      'device_name': _client.auth.deviceName,
    });
    final user = UserDetail.fromJson(data['user'] as Map<String, dynamic>);
    await _client.auth.saveTokens(data as Map<String, dynamic>);
    return (user, data);
  }

  Future<(UserDetail, Map<String, dynamic>)> register(
      String username, String password, {String? email}) async {
    final data = await _client.post('auth/register', body: {
      'username': username,
      'password': password,
      if (email != null && email.isNotEmpty) 'email': email,
      'device_id': _client.auth.deviceId,
      'device_name': _client.auth.deviceName,
    });
    final user = UserDetail.fromJson(data['user'] as Map<String, dynamic>);
    await _client.auth.saveTokens(data as Map<String, dynamic>);
    return (user, data);
  }

  Future<void> logout() async {
    try {
      await _client.post('auth/logout');
    } catch (_) {}
    await _client.auth.clear();
  }

  Future<List<DeviceSession>> devices() async {
    final data = await _client.get('auth/devices');
    return (data['list'] as List? ?? [])
        .map((e) => DeviceSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deviceLogout(int id) => _client.post('auth/devices/$id');

  // ---------- 用户 ----------
  Future<UserDetail> me() async {
    final data = await _client.get('me');
    return UserDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<UserDetail> updateMe({String? signature, String? nickname}) async {
    final body = <String, dynamic>{
      if (signature != null) 'signature': signature,
      if (nickname != null) 'nickname': nickname,
    };
    final data = await _client.put('me', body: body);
    return UserDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<UserDetail> userPage(String username) async {
    final data = await _client.get('users/$username');
    return UserDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<Paged<TopicBrief>> userTopics(String username,
      {String? cursor}) async {
    final data = await _client.get('users/$username/topics',
        query: {if (cursor != null) 'cursor': cursor});
    return _pagedTopics(data);
  }

  Future<bool> followUser(String username) async {
    final data = await _client.post('users/$username/follow');
    return data['following'] as bool? ?? false;
  }

  Future<bool> blockUser(String username) async {
    final data = await _client.post('users/$username/block');
    return data['blocked'] as bool? ?? false;
  }

  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final data = await _client.upload('me/avatar', 'file', bytes, filename);
    return data['avatar'] as String? ?? '';
  }

  // ---------- 版块 ----------
  Future<List<BoardGroup>> boards() async {
    final data = await _client.get('boards');
    return (data['list'] as List? ?? [])
        .map((e) => BoardGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<bool> followBoard(String slug) async {
    final data = await _client.post('boards/$slug/follow');
    return data['following'] as bool? ?? false;
  }

  Future<(BoardBrief, List<TopicBrief>, Paged<TopicBrief>)> boardDetail(
      String slug, {String? cursor}) async {
    final data = await _client.get('boards/$slug',
        query: {if (cursor != null) 'cursor': cursor});
    final board = BoardBrief.fromJson(data['board'] as Map<String, dynamic>);
    final pinned = (data['pinned'] as List? ?? [])
        .map((e) => TopicBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    final paged = _pagedTopics(data);
    return (board, pinned, paged);
  }

  // ---------- 帖子 ----------
  Future<Paged<TopicBrief>> topics({String? cursor}) async {
    final data = await _client.get('topics',
        query: {if (cursor != null) 'cursor': cursor});
    return _pagedTopics(data);
  }

  Future<TopicDetail> topic(int id) async {
    final data = await _client.get('topics/$id');
    return TopicDetail.fromJson(data as Map<String, dynamic>);
  }

  Future<(int, String)> createTopic({
    required int boardId,
    required String title,
    required String content,
    List<String>? tags,
    int bounty = 0,
    bool draft = false,
  }) async {
    final data = await _client.post('topics/create',
        idempotent: true,
        body: {
          'board_id': boardId,
          'title': title,
          'content': content,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          if (bounty > 0) 'bounty': bounty,
          if (draft) 'draft': true,
        });
    return ((data['id'] as num?)?.toInt() ?? 0, data['status'] as String? ?? '');
  }

  Future<bool> topicLike(int id, {bool idempotent = true}) async {
    final data = await _client.post('topics/$id/like', idempotent: idempotent);
    return data['liked'] as bool? ?? false;
  }

  Future<bool> topicFavorite(int id) async {
    final data = await _client.post('topics/$id/favorite', idempotent: true);
    return data['favorited'] as bool? ?? false;
  }

  Future<void> topicReport(int id, String category, String reason) =>
      _client.post('topics/$id/report',
          body: {'category': category, 'reason': reason});

  Future<void> topicDelete(int id) => _client.post('topics/$id/delete');

  Future<void> topicModerate(int id, String action,
          {bool value = true, String reason = '', int boardId = 0}) =>
      _client.post('topics/$id/moderate/$action', body: {
        'value': value,
        'reason': reason,
        if (boardId > 0) 'board_id': boardId,
      });

  // ---------- 回复 ----------
  Future<Paged<Reply>> replies(int topicId, {String? cursor}) async {
    final data = await _client.get('topics/$topicId/replies',
        query: {if (cursor != null) 'cursor': cursor});
    final list = (data['list'] as List? ?? [])
        .map((e) => Reply.fromJson(e as Map<String, dynamic>))
        .toList();
    return Paged(list, (data['total'] as num?)?.toInt() ?? 0,
        data['has_more'] as bool? ?? false, data['cursor'] as String? ?? '');
  }

  Future<Reply> createReply(int topicId, String content,
      {int parentId = 0, String quote = ''}) async {
    final data = await _client.post('topics/$topicId/replies/create',
        idempotent: true,
        body: {
          'content': content,
          if (parentId > 0) 'parent_id': parentId,
          if (quote.isNotEmpty) 'quote': quote,
        });
    return Reply.fromJson(data as Map<String, dynamic>);
  }

  Future<bool> replyLike(int replyId) async {
    final data = await _client.post('replies/$replyId/like', idempotent: true);
    return data['liked'] as bool? ?? false;
  }

  Future<void> replyAccept(int topicId, int replyId) =>
      _client.post('topics/$topicId/accept/$replyId');

  // ---------- 通知 / 私信 ----------
  Future<(Paged<Notification>, int)> notifications(
      {String? cursor, String? kind}) async {
    final data = await _client.get('me/notifications',
        query: {
          if (cursor != null) 'cursor': cursor,
          if (kind != null) 'kind': kind,
        });
    final list = (data['list'] as List? ?? [])
        .map((e) => Notification.fromJson(e as Map<String, dynamic>))
        .toList();
    final unread = (data['unread'] as num?)?.toInt() ?? 0;
    return (
      Paged(list, (data['total'] as num?)?.toInt() ?? 0,
          data['has_more'] as bool? ?? false, data['cursor'] as String? ?? ''),
      unread,
    );
  }

  Future<void> readNotifications({int? id}) =>
      _client.post('me/notifications/read', body: {if (id != null) 'id': id});

  Future<Paged<Conversation>> conversations({String? cursor}) async {
    final data = await _client.get('me/conversations',
        query: {if (cursor != null) 'cursor': cursor});
    final list = (data['list'] as List? ?? [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
    return Paged(list, (data['total'] as num?)?.toInt() ?? 0,
        data['has_more'] as bool? ?? false, data['cursor'] as String? ?? '');
  }

  Future<Paged<ChatMessage>> messages(int convId, {String? cursor}) async {
    final data = await _client.get('me/conversations/$convId',
        query: {if (cursor != null) 'cursor': cursor});
    final list = (data['list'] as List? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
    return Paged(list, (data['total'] as num?)?.toInt() ?? 0,
        data['has_more'] as bool? ?? false, data['cursor'] as String? ?? '');
  }

  Future<void> sendMessage(String username, String content) =>
      _client.post('me/messages',
          idempotent: true, body: {'username': username, 'content': content});

  Future<void> sendConvMessage(int convId, String content) =>
      _client.post('me/conversations/$convId',
          idempotent: true, body: {'content': content});

  // ---------- 积分 / 商城 / 勋章 ----------
  Future<PointsOverview> points() async {
    final data = await _client.get('me/points');
    return PointsOverview.fromJson(data as Map<String, dynamic>);
  }

  Future<(int, String)> checkin() async {
    final data = await _client.post('me/checkin', idempotent: true);
    return ((data['gained'] as num?)?.toInt() ?? 0, data['message'] as String? ?? '');
  }

  Future<Paged<PointLog>> pointLogs({String? cursor}) async {
    final data = await _client.get('me/points/logs',
        query: {if (cursor != null) 'cursor': cursor});
    final list = (data['list'] as List? ?? [])
        .map((e) => PointLog.fromJson(e as Map<String, dynamic>))
        .toList();
    return Paged(list, (data['total'] as num?)?.toInt() ?? 0,
        data['has_more'] as bool? ?? false, data['cursor'] as String? ?? '');
  }

  Future<List<ShopItem>> shop() async {
    final data = await _client.get('shop');
    return (data['list'] as List? ?? [])
        .map((e) => ShopItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> redeem(int itemId) =>
      _client.post('shop/$itemId/redeem', idempotent: true, body: {});

  Future<List<Medal>> medals() async {
    final data = await _client.get('medals');
    return (data['list'] as List? ?? [])
        .map((e) => Medal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MyMedal>> myMedals() async {
    final data = await _client.get('me/medals');
    return (data['list'] as List? ?? [])
        .map((e) => MyMedal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> makeup(String date) =>
      _client.post('me/makeup', idempotent: true, body: {'date': date});

  // ---------- 搜索 / 排行 ----------
  Future<({Paged<TopicBrief> topics, List<UserBrief> users, List<BoardBrief> boards})>
      search(String keyword, {String? cursor, String order = 'relevance'}) async {
    final data = await _client.get('search',
        query: {'q': keyword, 'order': order, if (cursor != null) 'cursor': cursor});
    final list = (data['list'] as List? ?? [])
        .map((e) => TopicBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    final users = (data['users'] as List? ?? [])
        .map((e) => UserBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    final boards = (data['boards'] as List? ?? [])
        .map((e) => BoardBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      topics: Paged(list, (data['total'] as num?)?.toInt() ?? 0,
          data['has_more'] as bool? ?? false, data['cursor'] as String? ?? ''),
      users: users,
      boards: boards,
    );
  }

  Future<List<TopicBrief>> ranking(String tab) async {
    final data = await _client.get('ranking', query: {'tab': tab});
    return (data['list'] as List? ?? [])
        .map((e) => TopicBrief.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- 标签 ----------
  Future<List<(String, int)>> tags() async {
    final data = await _client.get('tags');
    return (data['list'] as List? ?? [])
        .map((e) => (
              (e as Map<String, dynamic>)['name'] as String? ?? '',
              (e['use_count'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  Future<Paged<TopicBrief>> tagTopics(String name, {String? cursor}) async {
    final data = await _client.get('tags/$name',
        query: {if (cursor != null) 'cursor': cursor});
    return _pagedTopics(data);
  }

  Future<bool> tagFollow(String name) async {
    final data = await _client.post('tags/$name/follow');
    return data['following'] as bool? ?? false;
  }

  // ---------- 上传附件 ----------
  Future<dynamic> uploadAttachment(List<int> bytes, String filename,
      {int? topicId}) async {
    return _client.upload('upload', 'file', bytes, filename);
  }

  // ---------- 配置 ----------
  Future<Map<String, dynamic>> config() async {
    final data = await _client.get('config');
    return data as Map<String, dynamic>;
  }

  Paged<TopicBrief> _pagedTopics(dynamic data) {
    final list = (data['list'] as List? ?? [])
        .map((e) => TopicBrief.fromJson(e as Map<String, dynamic>))
        .toList();
    return Paged(list, (data['total'] as num?)?.toInt() ?? 0,
        data['has_more'] as bool? ?? false, data['cursor'] as String? ?? '');
  }
}
