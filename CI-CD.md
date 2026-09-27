# GitHub Actions 自动化打包指南（默认无证书 + 自行签名）

本文档说明如何用 GitHub Actions 自动打包 **未签名** 的 Android APK 和 iOS IPA，然后由你**自行签名**。

## 一、核心理念

- **默认无证书**：CI 只负责把代码编译成 App 产物，不内置任何签名证书。
- **自行签名**：产物下载后，用你自己的证书/密钥在本地完成签名，再安装或上架。
- **好处**：签名密钥永不上传到 GitHub，更安全；同一产物可用不同证书重复签名。

## 二、目录结构

```
.github/workflows/
├── build-android.yml   # Android 未签名 APK 打包
└── build-ios.yml       # iOS 未签名应用/ipa 打包
scripts/
├── gen-keystore.sh     # （可选）生成 Android 签名密钥库
└── ios-secrets.sh      # （可选）iOS 证书/描述文件转 Base64
```

## 三、前置条件

1. 项目已推送到 GitHub 仓库（仓库 `bbs-app` 的**根目录即 Flutter 工程本身**，`pubspec.yaml`、`lib/`、`android/`、`ios/` 均在顶层）。
2. GitHub 仓库已开启 Actions（默认开启）。

> 已适配：workflow 不含 `working-directory: app`，所有路径均为仓库根相对路径。若你的仓库结构不同，请自行调整。

## 四、Android APK（未签名）

### 1. 触发打包

- **自动**：push 到 `main` 分支（仅 `lib/**`、`android/**`、`pubspec.yaml` 等变更时）。
- **手动**：Actions 页 → 选 `Build Android APK (未签名)` → **Run workflow**。

### 2. 下载产物

下载 `android-apk-unsigned` artifact，解压得到 `app-*-release.apk`（未签名，分 ABI）。

> 未签名 APK **无法直接安装**，需先签名。

### 3. 自行签名（本地，需 JDK）

```bash
# ① 先生成一个签名密钥库（如果还没有）
keytool -genkeypair -v -keystore release.jks -alias mykey \
  -keyalg RSA -keysize 2048 -validity 10000

# ② 对 APK 做 v1+v2 签名（Android 7+ 必须 v2）
$ANDROID_HOME/build-tools/<版本>/apksigner sign \
  --ks release.jks --ks-key-alias mykey \
  --ks-pass pass:你的密码 --key-pass pass:你的密码 \
  --out app-signed.apk app-release.apk

# ③ 验证签名
$ANDROID_HOME/build-tools/<版本>/apksigner verify app-signed.apk
```

或者用 `jarsigner`（旧方式，仅 v1）：`jarsigner -verbose -keystore release.jks app-release.apk mykey`

> 提示：`apksigner` 位于 Android SDK 的 `build-tools/<版本>/` 目录，或用 `zipalign` 先对齐：`zipalign -p 4 app-release.apk aligned.apk` 再签名。

## 五、iOS（未签名）

### 1. 触发打包

- **手动**：Actions 页 → 选 `Build iOS (未签名)` → **Run workflow**。

### 2. 下载产物

下载 `ios-ipa-unsigned` artifact，得到：
- `Runner.app`（未签名应用）
- `Runner-unsigned.ipa`（未签名 ipa，仅作传输容器，**不能直接安装**）

### 3. 自行签名（本地，需 macOS + Xcode + 你的证书）

```bash
# ① 用你的证书对 Runner.app 重签
codesign --force --deep --sign "你的证书名" Runner.app

# ② 重新打包成可安装的 ipa
mkdir -p Payload
cp -R Runner.app Payload/
zip -qry Runner.ipa Payload

# ③ （可选）用 altool/Transporter 上传，或分发安装
```

> 正式上架建议走 Xcode 的 Archive → Distribute 流程，或配置证书后走带签名的 CI（见文末「进阶」）。

## 六、进阶：如需 CI 内签名（可选）

如果你后续希望 CI 直接产出**已签名**包，可以：

1. **Android**：本地准备 `key.properties`（指向 `release.jks`），并把密钥库放入仓库外（或 Secrets），再参考 `scripts/gen-keystore.sh` 恢复签名配置。`build.gradle` 已支持：存在 `key.properties` 时自动启用正式签名，否则默认无签名。
2. **iOS**：需要 Apple 开发者证书 + 描述文件，用 `scripts/ios-secrets.sh` 转 Base64 后配置 Secrets，再在 workflow 中恢复「导入证书 + `flutter build ipa`」的完整签名流程。

## 七、常见问题

**Q1：为什么下载的 APK 装不上？**
未签名 APK 无法安装，必须先按上文用 `apksigner` 签名。

**Q2：iOS 的 ipa 打不开/装不上？**
未签名 ipa 不能安装，必须用你的证书 `codesign` 重签后再分发。

**Q3：Flutter 版本不匹配？**
修改两个 workflow 顶部的 `FLUTTER_VERSION`，改为你本地的版本（`flutter --version` 查看）。

**Q4：想发布到 GitHub Release？**
可在 workflow 末尾追加 softprops/action-gh-release 步骤，把 artifact 上传为 Release 附件。

## 八、安全提醒

- 签名密钥、`.p12`、`.mobileprovision` 及密码**绝不**提交到 Git 仓库。
- 相关文件已加入 `.gitignore`。
- 密钥丢失将无法更新已上架应用，请务必多份备份。
