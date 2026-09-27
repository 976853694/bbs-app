#!/usr/bin/env bash
# 生成 Android release 签名密钥库（release.jks）
# 用法：bash scripts/gen-keystore.sh
# 生成后请立即备份，并配置到 GitHub Secrets（见 README）

set -e

cd "$(dirname "$0")/.."

KEYSTORE_DIR="android/app/keystore"
KEYSTORE_PATH="$KEYSTORE_DIR/release.jks"
ALIAS="community_forum"
STOREPASS="changeit"
KEYPASS="changeit"
VALIDITY=10000

# 交互式输入（可选覆盖默认值）
read -p "密钥别名 (默认 $ALIAS): " input_alias
ALIAS="${input_alias:-$ALIAS}"

read -s -p "密钥库密码 (默认 changeit): " input_storepass
echo ""
STOREPASS="${input_storepass:-$STOREPASS}"

read -s -p "密钥密码 (默认同密钥库): " input_keypass
echo ""
KEYPASS="${input_keypass:-$STOREPASS}"

read -p "组织/公司名 (CN，例如 社区论坛): " CN
CN="${CN:-社区论坛}"

mkdir -p "$KEYSTORE_DIR"

if [ -f "$KEYSTORE_PATH" ]; then
  echo "⚠️  已存在 $KEYSTORE_PATH，为避免覆盖，退出。"
  exit 1
fi

echo "正在生成密钥库..."

keytool -genkeypair -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity "$VALIDITY" \
  -storepass "$STOREPASS" \
  -keypass "$KEYPASS" \
  -dname "CN=$CN, OU=Mobile, O=$CN, L=Beijing, ST=Beijing, C=CN"

echo ""
echo "✅ 密钥库生成成功：$KEYSTORE_PATH"
echo ""
echo "请记下以下信息，并配置到 GitHub Secrets："
echo "  别名 (ALIAS):        $ALIAS"
echo "  密钥库密码 (STORE):  $STOREPASS"
echo "  密钥密码 (KEY):      $KEYPASS"
echo ""
echo "生成 Base64（用于 KEYSTORE_BASE64）："
base64 -w 0 "$KEYSTORE_PATH"
echo ""
