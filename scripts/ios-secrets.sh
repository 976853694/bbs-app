#!/usr/bin/env bash
# 将 iOS 证书 (.p12) 和描述文件 (.mobileprovision) 转成 Base64，用于 GitHub Secrets。
# 用法：
#   bash scripts/ios-secrets.sh path/to/cert.p12 path/to/xx.mobileprovision
# 输出两个值，分别填入 GitHub Secrets：
#   IOS_P12_BASE64 和 IOS_PROVISION_BASE64

set -e

P12="$1"
PROVISION="$2"

if [ -z "$P12" ] || [ -z "$PROVISION" ]; then
  echo "用法: $0 <cert.p12> <xxx.mobileprovision>"
  exit 1
fi

if [ ! -f "$P12" ]; then
  echo "❌ 找不到 p12 文件: $P12"
  exit 1
fi
if [ ! -f "$PROVISION" ]; then
  echo "❌ 找不到 mobileprovision 文件: $PROVISION"
  exit 1
fi

echo ""
echo "===== IOS_P12_BASE64（填入 GitHub Secret）====="
base64 -w 0 "$P12"
echo ""
echo ""
echo "===== IOS_PROVISION_BASE64（填入 GitHub Secret）====="
base64 -w 0 "$PROVISION"
echo ""
echo ""
echo "提示：IOS_P12_PASSWORD 需要你手动记录（导出 p12 时设置的密码）。"
