#!/bin/bash
# Build + cài KietKey (bản cá nhân, không kết nối Internet).
# Dùng: ./build.sh            -> build, cài vào /Applications
#       ./build.sh --no-install -> chỉ build
set -euo pipefail
cd "$(dirname "$0")"

PROJ="Sources/OpenKey/macOS/OpenKey.xcodeproj"
DD="$(pwd)/.build"
APP="$DD/Build/Products/Release/KietKey.app"

# Chữ ký: đặt OPENKEY_SIGN_ID để dùng cert ổn định, ví dụ:
#   export OPENKEY_SIGN_ID="Apple Development: ban@email.com (XXXXXXXXXX)"
# Nếu không đặt, dùng ad-hoc (phải cấp lại quyền Accessibility sau mỗi lần build).
SIGN_ID="${OPENKEY_SIGN_ID:--}"

echo "==> Build (chữ ký: $SIGN_ID)"
xcodebuild -project "$PROJ" -scheme OpenKey -configuration Release \
  -derivedDataPath "$DD" \
  CODE_SIGN_IDENTITY="$SIGN_ID" CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  -quiet build

echo "==> Kiểm tra app không có code mạng"
if otool -L "$APP/Contents/MacOS/KietKey" | grep -q CFNetwork; then
  echo "CẢNH BÁO: binary có link CFNetwork!" >&2; exit 1
fi
if nm -u "$APP/Contents/MacOS/KietKey" 2>/dev/null | grep -qiE "NSURLSession|NSURLConnection|CFSocket"; then
  echo "CẢNH BÁO: binary có symbol mạng!" >&2; exit 1
fi
echo "    OK: không có symbol/framework mạng."
codesign -dv "$APP" 2>&1 | grep -E "Identifier|TeamIdentifier|Signature" || true

[[ "${1:-}" == "--no-install" ]] && { echo "==> Xong: $APP"; exit 0; }

echo "==> Cài vào /Applications (thoát KietKey đang chạy nếu có)"
pkill -x KietKey 2>/dev/null || true
sleep 1
rm -rf /Applications/KietKey.app
cp -R "$APP" /Applications/KietKey.app
xattr -dr com.apple.quarantine /Applications/KietKey.app 2>/dev/null || true
echo "==> Xong. Mở: open /Applications/KietKey.app"
echo "    Lần đầu: System Settings > Privacy & Security > Accessibility > bật KietKey"
