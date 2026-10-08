#!/bin/bash
# Build + cài KietKey (bản cá nhân, không kết nối Internet).
#
# Dùng:
#   ./build.sh                 build, cài vào /Applications
#   ./build.sh --no-install    chỉ build
#
# Chữ ký — đặt OPENKEY_SIGN_ID:
#   "OpenKey Personal"                                  cert tự ký (mặc định cũ)
#   "Developer ID Application: ... (TEAMID)"            để notarize được
#   không đặt                                           ad-hoc
#
# Notarize (chỉ chạy khi ký bằng Developer ID):
#   Tạo hồ sơ một lần, BẠN tự chạy vì có mật khẩu:
#     xcrun notarytool store-credentials kietkey \
#       --apple-id <email> --team-id 2WS3ZR8QBR --password <app-specific-password>
#   Rồi:
#     OPENKEY_NOTARIZE_PROFILE=kietkey ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

PROJ="Sources/OpenKey/macOS/OpenKey.xcodeproj"
DD="$(pwd)/.build"
APP="$DD/Build/Products/Release/KietKey.app"
SIGN_ID="${OPENKEY_SIGN_ID:--}"
NOTARIZE_PROFILE="${OPENKEY_NOTARIZE_PROFILE:-}"

# Hardened Runtime bắt buộc để notarize được; bật luôn cho Developer ID.
HARDENED=NO
case "$SIGN_ID" in
  "Developer ID Application"*) HARDENED=YES ;;
esac

echo "==> Build (chữ ký: $SIGN_ID, hardened runtime: $HARDENED)"
xcodebuild -project "$PROJ" -scheme OpenKey -configuration Release \
  -derivedDataPath "$DD" \
  CODE_SIGN_IDENTITY="$SIGN_ID" CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  ENABLE_HARDENED_RUNTIME="$HARDENED" \
  -quiet build

echo "==> Kiểm tra app không có code mạng"
if otool -L "$APP/Contents/MacOS/KietKey" | grep -q CFNetwork; then
  echo "CẢNH BÁO: binary có link CFNetwork!" >&2; exit 1
fi
if nm -u "$APP/Contents/MacOS/KietKey" 2>/dev/null | grep -qiE "NSURLSession|NSURLConnection|CFSocket"; then
  echo "CẢNH BÁO: binary có symbol mạng!" >&2; exit 1
fi
echo "    OK: không có symbol/framework mạng."
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E "Identifier|TeamIdentifier|flags" || true

if [[ -n "$NOTARIZE_PROFILE" ]]; then
  if [[ "$HARDENED" != "YES" ]]; then
    echo "Bỏ qua notarize: cần ký bằng Developer ID Application." >&2
  else
    ZIP="$DD/KietKey-notarize.zip"
    echo "==> Gửi Apple notarize (chỉ bước này cần mạng, app thì không)"
    rm -f "$ZIP"
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
    xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARIZE_PROFILE" --wait
    echo "==> Đóng vé vào app"
    xcrun stapler staple "$APP"
    xcrun stapler validate "$APP"
  fi
fi

[[ "${1:-}" == "--no-install" ]] && { echo "==> Xong: $APP"; exit 0; }

echo "==> Cài vào /Applications (thoát KietKey đang chạy nếu có)"
pkill -x KietKey 2>/dev/null || true
sleep 1
rm -rf /Applications/KietKey.app
cp -R "$APP" /Applications/KietKey.app
xattr -dr com.apple.quarantine /Applications/KietKey.app 2>/dev/null || true
echo "==> Xong. Mở: open /Applications/KietKey.app"
