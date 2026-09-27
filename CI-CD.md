# GitHub Actions 自动化打包指南（APK + IPA）

本文档说明如何用 GitHub Actions 自动打包 Android APK 和 iOS IPA。

## 一、目录结构

```
.github/workflows/
├── build-android.yml   # Android APK 打包
└── build-ios.yml       # iOS IPA 打包
scripts/
├── gen-keystore.sh     # 生成 Android 签名密钥库
└── ios-secrets.sh      # 将 iOS 证书/描述文件转 Base64
```

## 二、前置条件

1. 项目已推送到 GitHub 仓库，`app/` 是其子目录。
2. GitHub 仓库已开启 Actions（默认开启）。

> 注意：workflow 里 `working-directory: app` 假设仓库根目录下是 `app/`。如果你的仓库结构不同（例如 `app/` 就是仓库根目录），请删掉所有 `working-directory: app` 行，并把路径里的 `app/` 前缀去掉。

## 三、Android APK 打包

### 1. 生成签名密钥库（一次性）

本地执行（需安装 JDK）：

```bash
cd app
bash scripts/gen-keystore.sh
```

会生成 `android/app/keystore/release.jks`，并输出 Base64 字符串。

### 2. 配置 GitHub Secrets

进入仓库 **Settings → Secrets and variables → Actions → New repository secret**，添加：

| Secret 名称 | 值 | 说明 |
|---|---|---|
| `KEYSTORE_BASE64` | `release.jks` 的 Base64 | 密钥库文件 |
| `KEYSTORE_PASSWORD` | 密钥库密码 | 如 `changeit` |
| `KEY_ALIAS` | 密钥别名 | 如 `community_forum` |
| `KEY_PASSWORD` | 密钥密码 | 通常与密钥库密码相同 |

> 生成 Base64（Linux/macOS）：`base64 -w 0 android/app/keystore/release.jks`
> Windows PowerShell：`[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/keystore/release.jks"))`

### 3. 触发打包

- **自动**：push 到 `main` 分支（仅 `app/**` 变更时）。
- **手动**：仓库 **Actions** 页 → 选 `Build Android APK` → **Run workflow**。

### 4. 下载产物

构建完成后，在对应 run 的 **Artifacts** 下载 `android-apk`，解压得到：
- `app-arm64-v8a-release.apk`、`app-armeabi-v7a-release.apk`、`app-x86_64-release.apk`（分 ABI）
- 如需单一通用包，可把 `--split-per-abi` 去掉。

## 四、iOS IPA 打包

iOS 打包比 Android 复杂，**必须**有 Apple 开发者账号和签名证书。

### 1. 准备证书与描述文件（一次性）

1. 登录 [Apple Developer](https://developer.apple.com/account/)。
2. **Certificates** → 创建 **iOS Distribution** 证书（.cer），下载后在 macOS 钥匙串中导出为 `.p12`（导出时设置一个密码）。
3. **Identifiers** → 注册 App ID（Bundle ID 需与 `ios/Runner.xcodeproj` 中一致，当前为 `com.example.communityForum` 或你自定义的）。
4. **Profiles** → 创建描述文件（.mobileprovision）：
   - 测试分发：**Ad Hoc**（需添加测试设备 UDID）
   - 上架：**App Store**

### 2. 生成 Base64 并配置 Secrets

```bash
cd app
bash scripts/ios-secrets.sh path/to/cert.p12 path/to/xxx.mobileprovision
```

配置以下 Secrets：

| Secret 名称 | 值 | 说明 |
|---|---|---|
| `IOS_P12_BASE64` | 证书 .p12 的 Base64 | 签名证书 |
| `IOS_P12_PASSWORD` | 导出 p12 时设置的密码 | 证书密码 |
| `IOS_PROVISION_BASE64` | 描述文件的 Base64 | 描述文件 |

### 3. 触发打包

- **手动**：Actions 页 → `Build iOS IPA` → Run workflow，可选择导出方式：
  - `ad-hoc`（默认）：测试分发，可安装到已登记设备
  - `app-store`：上架 App Store
  - `development`：开发调试

### 4. 下载产物

下载 `ios-ipa` artifact，得到 `.ipa` 文件。

## 五、常见问题

**Q1：Android 报 `keystore` 找不到？**
确认 `KEYSTORE_BASE64` 已配置且 Base64 正确。未配置时会回退到 debug 签名（仅能本地测试，无法上架）。

**Q2：iOS 报签名失败 / `No profiles found`？**
确认证书和描述文件的 Bundle ID、证书类型匹配；Ad Hoc 需在描述文件里包含目标设备 UDID。

**Q3：Flutter 版本不匹配？**
修改两个 workflow 顶部的 `FLUTTER_VERSION` 环境变量，改为你本地的版本（`flutter --version` 查看）。

**Q4：想发布到 GitHub Release？**
可在 workflow 末尾追加 softprops/action-gh-release 步骤，把 artifact 上传为 Release 附件。

## 六、安全提醒

- **绝不**把 `release.jks`、`.p12`、`.mobileprovision` 或明文密码提交到 Git 仓库。
- 这些文件已加入 `.gitignore`。
- 密钥丢失将无法更新已上架应用，请务必多份备份。
