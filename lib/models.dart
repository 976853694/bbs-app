/// 数据模型，与后端 API v1 序列化字段一一对应。
library;

class UserBrief {
  final int id;
  final String username;
  final String nickname;
  final int level;
  final String levelName;
  final String title;
  final String avatar;

  UserBrief({
    required this.id,
    required this.username,
    required this.nickname,
    required this.level,
    required this.levelName,
    required this.title,
    required this.avatar,
  });

  factory UserBrief.fromJson(Map<String, dynamic> j) => UserBrief(
        id: (j['id'] as num?)?.toInt() ?? 0,
        username: j['username'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        level: (j['level'] as num?)?.toInt() ?? 0,
        levelName: j['level_name'] as String? ?? '',
        title: j['title'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
      );

  String get displayName => nickname.isNotEmpty ? nickname : username;
}

class UserDetail extends UserBrief {
  final String signature;
  final String gender;
  final String homepage;
  final int points;
  final int exp;
  final int checkinStreak;
  final String role;
  final String joinedAt;

  UserDetail({
    required super.id,
    required super.username,
    required super.nickname,
    required super.level,
    required super.levelName,
    required super.title,
    required super.avatar,
    required this.signature,
    required this.gender,
    required this.homepage,
    required this.points,
    required this.exp,
    required this.checkinStreak,
    required this.role,
    required this.joinedAt,
  });

  factory UserDetail.fromJson(Map<String, dynamic> j) => UserDetail(
        id: (j['id'] as num?)?.toInt() ?? 0,
        username: j['username'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        level: (j['level'] as num?)?.toInt() ?? 0,
        levelName: j['level_name'] as String? ?? '',
        title: j['title'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
        signature: j['signature'] as String? ?? '',
        gender: j['gender'] as String? ?? '',
        homepage: j['homepage'] as String? ?? '',
        points: (j['points'] as num?)?.toInt() ?? 0,
        exp: (j['exp'] as num?)?.toInt() ?? 0,
        checkinStreak: (j['checkin_streak'] as num?)?.toInt() ?? 0,
        role: j['role'] as String? ?? '',
        joinedAt: j['joined_at'] as String? ?? '',
      );
}

class BoardBrief {
  final int id;
  final String slug;
  final String name;
  final String icon;
  final String description;
  final int topicCount;
  final int replyCount;
  final int todayCount;

  BoardBrief({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.description,
    required this.topicCount,
    required this.replyCount,
    required this.todayCount,
  });

  factory BoardBrief.fromJson(Map<String, dynamic> j) => BoardBrief(
        id: (j['id'] as num?)?.toInt() ?? 0,
        slug: j['slug'] as String? ?? '',
        name: j['name'] as String? ?? '',
        icon: j['icon'] as String? ?? '💬',
        description: j['description'] as String? ?? '',
        topicCount: (j['topic_count'] as num?)?.toInt() ?? 0,
        replyCount: (j['reply_count'] as num?)?.toInt() ?? 0,
        todayCount: (j['today_count'] as num?)?.toInt() ?? 0,
      );
}

class BoardGroup {
  final int id;
  final String name;
  final List<BoardBrief> boards;

  BoardGroup({required this.id, required this.name, required this.boards});

  factory BoardGroup.fromJson(Map<String, dynamic> j) => BoardGroup(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        boards: (j['boards'] as List? ?? [])
            .map((e) => BoardBrief.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TopicBrief {
  final int id;
  final String title;
  final String summary;
  final BoardBrief board;
  final UserBrief author;
  final int replyCount;
  final int likeCount;
  final int favoriteCount;
  final int viewCount;
  final bool isPinned;
  final bool isEssence;
  final bool isLocked;
  final int bounty;
  final String bountyState;
  final String createdAt;
  final String lastReplyAt;

  TopicBrief({
    required this.id,
    required this.title,
    required this.summary,
    required this.board,
    required this.author,
    required this.replyCount,
    required this.likeCount,
    required this.favoriteCount,
    required this.viewCount,
    required this.isPinned,
    required this.isEssence,
    required this.isLocked,
    required this.bounty,
    required this.bountyState,
    required this.createdAt,
    required this.lastReplyAt,
  });

  factory TopicBrief.fromJson(Map<String, dynamic> j) {
    final boardJson = j['board'] as Map<String, dynamic>? ?? {};
    final authorJson = j['author'] as Map<String, dynamic>? ?? {};
    return TopicBrief(
      id: (j['id'] as num?)?.toInt() ?? 0,
      title: j['title'] as String? ?? '',
      summary: j['summary'] as String? ?? '',
      board: BoardBrief.fromJson({
        'id': boardJson['id'] ?? 0,
        'slug': boardJson['slug'] ?? '',
        'name': boardJson['name'] ?? '',
      }),
      author: UserBrief.fromJson(authorJson),
      replyCount: (j['reply_count'] as num?)?.toInt() ?? 0,
      likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (j['favorite_count'] as num?)?.toInt() ?? 0,
      viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
      isPinned: j['is_pinned'] as bool? ?? false,
      isEssence: j['is_essence'] as bool? ?? false,
      isLocked: j['is_locked'] as bool? ?? false,
      bounty: (j['bounty'] as num?)?.toInt() ?? 0,
      bountyState: j['bounty_state'] as String? ?? '',
      createdAt: j['created_at'] as String? ?? '',
      lastReplyAt: j['last_reply_at'] as String? ?? '',
    );
  }
}

class TopicDetail extends TopicBrief {
  final String content;
  final List<String> tags;
  final bool isRecommended;
  final int bestReplyId;

  TopicDetail({
    required super.id,
    required super.title,
    required super.summary,
    required super.board,
    required super.author,
    required super.replyCount,
    required super.likeCount,
    required super.favoriteCount,
    required super.viewCount,
    required super.isPinned,
    required super.isEssence,
    required super.isLocked,
    required super.bounty,
    required super.bountyState,
    required super.createdAt,
    required super.lastReplyAt,
    required this.content,
    required this.tags,
    required this.isRecommended,
    required this.bestReplyId,
  });

  factory TopicDetail.fromJson(Map<String, dynamic> j) {
    final brief = TopicBrief.fromJson(j);
    return TopicDetail(
      id: brief.id,
      title: brief.title,
      summary: brief.summary,
      board: brief.board,
      author: brief.author,
      replyCount: brief.replyCount,
      likeCount: brief.likeCount,
      favoriteCount: brief.favoriteCount,
      viewCount: brief.viewCount,
      isPinned: brief.isPinned,
      isEssence: brief.isEssence,
      isLocked: brief.isLocked,
      bounty: brief.bounty,
      bountyState: brief.bountyState,
      createdAt: brief.createdAt,
      lastReplyAt: brief.lastReplyAt,
      content: j['content'] as String? ?? '',
      tags: (j['tags'] as List? ?? []).map((e) => e.toString()).toList(),
      isRecommended: j['is_recommended'] as bool? ?? false,
      bestReplyId: (j['best_reply_id'] as num?)?.toInt() ?? 0,
    );
  }
}

class Reply {
  final int id;
  final int floor;
  final int parentId;
  final String content;
  final String quote;
  final int likeCount;
  final UserBrief author;
  final String createdAt;
  final List<Reply> children;

  Reply({
    required this.id,
    required this.floor,
    required this.parentId,
    required this.content,
    required this.quote,
    required this.likeCount,
    required this.author,
    required this.createdAt,
    required this.children,
  });

  factory Reply.fromJson(Map<String, dynamic> j) => Reply(
        id: (j['id'] as num?)?.toInt() ?? 0,
        floor: (j['floor'] as num?)?.toInt() ?? 0,
        parentId: (j['parent_id'] as num?)?.toInt() ?? 0,
        content: j['content'] as String? ?? '',
        quote: j['quote'] as String? ?? '',
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        author: UserBrief.fromJson(j['author'] as Map<String, dynamic>? ?? {}),
        createdAt: j['created_at'] as String? ?? '',
        children: (j['children'] as List? ?? [])
            .map((e) => Reply.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Notification {
  final int id;
  final String kind;
  final String text;
  final String url;
  final bool isRead;
  final String createdAt;

  Notification({
    required this.id,
    required this.kind,
    required this.text,
    required this.url,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> j) => Notification(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kind: j['kind'] as String? ?? '',
        text: j['text'] as String? ?? '',
        url: j['url'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String? ?? '',
      );
}

class Conversation {
  final int id;
  final UserBrief peer;
  final String lastText;
  final String updatedAt;

  Conversation({
    required this.id,
    required this.peer,
    required this.lastText,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: (j['id'] as num?)?.toInt() ?? 0,
        peer: UserBrief.fromJson(j['peer'] as Map<String, dynamic>? ?? {}),
        lastText: j['last_text'] as String? ?? '',
        updatedAt: j['updated_at'] as String? ?? '',
      );
}

class ChatMessage {
  final int id;
  final bool mine;
  final String content;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.mine,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: (j['id'] as num?)?.toInt() ?? 0,
        mine: j['mine'] as bool? ?? false,
        content: j['content'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
      );
}

class PointsOverview {
  final int points;
  final int exp;
  final int level;
  final String levelName;
  final int nextExp;
  final int checkinStreak;
  final bool checkedToday;
  final int makeupCards;
  final int renameCards;

  PointsOverview({
    required this.points,
    required this.exp,
    required this.level,
    required this.levelName,
    required this.nextExp,
    required this.checkinStreak,
    required this.checkedToday,
    required this.makeupCards,
    required this.renameCards,
  });

  factory PointsOverview.fromJson(Map<String, dynamic> j) => PointsOverview(
        points: (j['points'] as num?)?.toInt() ?? 0,
        exp: (j['exp'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 0,
        levelName: j['level_name'] as String? ?? '',
        nextExp: (j['next_exp'] as num?)?.toInt() ?? 0,
        checkinStreak: (j['checkin_streak'] as num?)?.toInt() ?? 0,
        checkedToday: j['checked_today'] as bool? ?? false,
        makeupCards: (j['makeup_cards'] as num?)?.toInt() ?? 0,
        renameCards: (j['rename_cards'] as num?)?.toInt() ?? 0,
      );
}

class PointLog {
  final int id;
  final String event;
  final String eventName;
  final int amount;
  final int balance;
  final String remark;
  final String createdAt;

  PointLog({
    required this.id,
    required this.event,
    required this.eventName,
    required this.amount,
    required this.balance,
    required this.remark,
    required this.createdAt,
  });

  factory PointLog.fromJson(Map<String, dynamic> j) => PointLog(
        id: (j['id'] as num?)?.toInt() ?? 0,
        event: j['event'] as String? ?? '',
        eventName: j['event_name'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        balance: (j['balance'] as num?)?.toInt() ?? 0,
        remark: j['remark'] as String? ?? '',
        createdAt: j['created_at'] as String? ?? '',
      );
}

class ShopItem {
  final int id;
  final String name;
  final String icon;
  final String kind;
  final int cost;
  final String description;

  ShopItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.cost,
    required this.description,
  });

  factory ShopItem.fromJson(Map<String, dynamic> j) => ShopItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        icon: j['icon'] as String? ?? '🎁',
        kind: j['kind'] as String? ?? '',
        cost: (j['cost'] as num?)?.toInt() ?? 0,
        description: j['description'] as String? ?? '',
      );
}

class Medal {
  final int id;
  final String name;
  final String icon;
  final String description;

  Medal({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory Medal.fromJson(Map<String, dynamic> j) => Medal(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        icon: j['icon'] as String? ?? '🏅',
        description: j['description'] as String? ?? '',
      );
}

class MyMedal {
  final int id;
  final String name;
  final String icon;
  final bool worn;
  final String awardedAt;

  MyMedal({
    required this.id,
    required this.name,
    required this.icon,
    required this.worn,
    required this.awardedAt,
  });

  factory MyMedal.fromJson(Map<String, dynamic> j) => MyMedal(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        icon: j['icon'] as String? ?? '🏅',
        worn: j['worn'] as bool? ?? false,
        awardedAt: j['awarded_at'] as String? ?? '',
      );
}

class DeviceSession {
  final int id;
  final String deviceId;
  final String deviceName;
  final bool current;
  final String lastSeen;

  DeviceSession({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.current,
    required this.lastSeen,
  });

  factory DeviceSession.fromJson(Map<String, dynamic> j) => DeviceSession(
        id: (j['id'] as num?)?.toInt() ?? 0,
        deviceId: j['device_id'] as String? ?? '',
        deviceName: j['device_name'] as String? ?? '',
        current: j['current'] as bool? ?? false,
        lastSeen: j['last_seen'] as String? ?? '',
      );
}
