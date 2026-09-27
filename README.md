# 社区论坛 · Flutter 移动端 App

基于项目 `ui-app/` 移动端设计稿实现的 Flutter 客户端，支持 **Android + iOS** 双端，消费 Django 论坛后端 **API v1**（`/api/v1/`）。

## 技术栈

| 层 | 选型 |
| --- | --- |
| 框架 | Flutter（Dart SDK >= 3.3） |
| 状态管理 | `provider` |
| 网络 | `dio`（统一响应解析、JWT 自动刷新、幂等键、游标分页） |
| 本地存储 | `shared_preferences`（token、设备 ID） |
| 图片 | `cached_network_image` |
| Markdown | `flutter_markdown` |
| 工具 | `intl`、`uuid`、`image_picker` |

## 目录结构

```
app/
├── lib/
│   ├── main.dart                 # 入口 + Provider 注入 + 根路由
│   ├── theme.dart                # 设计系统（品牌蓝 #2f6ee0，延续 ui-app）
│   ├── models.dart               # 数据模型（与后端序列化字段一一对应）
│   ├── api/
│   │   ├── api_types.dart        # 统一响应 / 异常 / 分页类型
│   │   ├── api_client.dart       # HTTP 客户端（鉴权、刷新、上传）
│   │   └── forum_api.dart        # 接口服务层（强类型方法）
│   ├── state/
│   │   └── auth_state.dart       # 登录态（Provider）
│   ├── widgets/
│   │   ├── common.dart           # 通用组件（头像/等级徽章/状态徽章/FeedCard…）
│   │   └── main_scaffold.dart    # 底部五段 TabBar + 悬浮发布
│   └── pages/                    # 15 个页面
│       ├── home_page.dart        # 首页信息流
│       ├── boards_page.dart      # 版块列表
│       ├── board_detail_page.dart# 版块详情
│       ├── topic_page.dart       # 帖子详情（Markdown + 楼层 + 点赞/收藏/举报）
│       ├── search_page.dart      # 搜索（排序）
│       ├── editor_page.dart      # 发帖编辑器
│       ├── messages_page.dart    # 消息中心（通知 + 私信）
│       ├── chat_page.dart        # 私信会话
│       ├── points_page.dart      # 积分中心（签到/商城/勋章）
│       ├── me_page.dart          # 我的（个人中心）
│       ├── profile_page.dart     # 个人主页
│       ├── settings_page.dart    # 账号设置（签名编辑 + 设备管理）
│       ├── login_page.dart       # 登录
│       └── register_page.dart    # 注册
├── android/                      # Android 工程（Kotlin + Gradle）
├── ios/                          # iOS 工程（Swift + CocoaPods）
└── pubspec.yaml
```

## 运行前准备

1. **安装 Flutter SDK**（本项目未在本机安装）：
   - 下载：https://docs.flutter.dev/get-started/install
   - 确认：`flutter doctor` 全部通过（Android SDK / Xcode / CocoaPods）

2. **启动后端**（Django 项目根目录）：
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

3. **配置后端地址**：默认 `http://10.0.2.2:8000/`（Android 模拟器访问宿主机）。
   - iOS 模拟器用 `http://127.0.0.1:8000/`
   - 真机需改为局域网 IP，如 `http://192.168.x.x:8000/`
   - 修改位置：`lib/api/api_client.dart` 的 `AuthStore.defaultBaseUrl`（也可运行时通过 `AuthStore.setBaseUrl` 配置）

## 运行

```bash
cd app
flutter pub get

# Android
flutter run -d <device>

# iOS（需 macOS + Xcode）
flutter run -d <simulator>
```

## 打包

### 本地打包

```bash
# Android APK
flutter build apk --release
# Android App Bundle（上架用）
flutter build appbundle --release

# iOS（需 macOS）
flutter build ios --release
```

### GitHub Actions 自动化打包（默认无证书）

已配置 CI/CD，push 到 `main` 分支或手动触发即可自动打包 **未签名** 产物，由你自行签名后安装/上架：

| 平台 | Workflow 文件 | 产物 |
|---|---|---|
| Android | `.github/workflows/build-android.yml` | 未签名 APK（分 ABI） |
| iOS | `.github/workflows/build-ios.yml` | 未签名 `Runner.app` + `Runner-unsigned.ipa` |

**签名方法（apksigner / codesign）与完整说明见 [CI-CD.md](./CI-CD.md)。**

## 已对接的 API（对照后端 views）

认证（register/login/refresh/logout/devices）、用户（me/资料/头像/关注/拉黑）、版块（列表/详情/关注）、帖子（列表/详情/创建/点赞/收藏/举报/删除/审核）、回复（列表/创建/点赞/采纳）、通知/私信、积分（签到/流水）、商城/勋章、搜索、排行榜、标签、上传。

## 说明

- 应用图标为**占位图标**（品牌蓝 + 白色圆点），正式发布前请用 `flutter_launcher_icons` 替换。
- 第三方登录（微信/QQ/GitHub）与推送（JPush）为后端暂缓项（K4/K6），App 端已预留入口但未接入。
- `NSAppTransportSecurity` 与 `usesCleartextTraffic` 已开启，允许开发期 HTTP 明文请求；生产环境请切换 HTTPS 并关闭。
