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
# Tuỳ chọn: ép notarytool đọc hồ sơ từ một keychain cụ thể.
NOTARIZE_KEYCHAIN="${OPENKEY_NOTARIZE_KEYCHAIN:-}"

# Hardened Runtime bắt buộc để notarize được; bật luôn cho Developer ID.
# --timestamp: notarize BẮT BUỘC có secure timestamp. Không có thì Apple trả về
# Invalid mà không nói rõ lý do — đã dính một lần.
# CODE_SIGN_INJECT_BASE_ENTITLEMENTS: `xcodebuild build` tiêm entitlement debug
# com.apple.security.get-task-allow kể cả ở cấu hình Release. Apple từ chối
# notarize vì entitlement này — đã dính một lần, log mới nói ra.
HARDENED=NO
EXTRA_SIGN_FLAGS=""
INJECT_BASE_ENTS=YES
case "$SIGN_ID" in
  "Developer ID Application"*)
    HARDENED=YES; EXTRA_SIGN_FLAGS="--timestamp"; INJECT_BASE_ENTS=NO ;;
esac

echo "==> Build (chữ ký: $SIGN_ID, hardened runtime: $HARDENED)"
xcodebuild -project "$PROJ" -scheme OpenKey -configuration Release \
  -derivedDataPath "$DD" \
  CODE_SIGN_IDENTITY="$SIGN_ID" CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  ENABLE_HARDENED_RUNTIME="$HARDENED" \
  OTHER_CODE_SIGN_FLAGS="$EXTRA_SIGN_FLAGS" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS="$INJECT_BASE_ENTS" \
  -quiet build

echo "==> Kiểm tra app không có code mạng"
if otool -L "$APP/Contents/MacOS/KietKey" | grep -q CFNetwork; then
  echo "CẢNH BÁO: binary có link CFNetwork!" >&2; exit 1
fi
if nm -u "$APP/Contents/MacOS/KietKey" 2>/dev/null | grep -qiE "NSURLSession|NSURLConnection|CFSocket"; then
  echo "CẢNH BÁO: binary có symbol mạng!" >&2; exit 1
fi
echo "    OK: không có symbol/framework mạng."
SIGN_INFO="$(codesign -dvv "$APP" 2>&1)"
grep -E "Identifier|TeamIdentifier|flags|Timestamp" <<<"$SIGN_INFO" || true

# Dùng biến trung gian: dạng `[[ ... ]] && ! cmd | grep` bị bash phân tích sai
# (cả vế trái bị đưa vào pipe), guard luôn báo nhầm.
if [[ "$HARDENED" == "YES" ]]; then
  if ! grep -q "^Timestamp=" <<<"$SIGN_INFO"; then
    echo "CẢNH BÁO: chữ ký thiếu secure timestamp -> notarize sẽ bị từ chối." >&2
    exit 1
  fi
  ENTS="$(codesign -d --entitlements - --xml "$APP" 2>/dev/null || true)"
  if grep -q "get-task-allow" <<<"$ENTS"; then
    echo "CẢNH BÁO: binary còn entitlement debug get-task-allow -> Apple sẽ từ chối." >&2
    exit 1
  fi
  echo "    OK: có secure timestamp, không còn entitlement debug."
fi

if [[ -n "$NOTARIZE_PROFILE" ]]; then
  if [[ "$HARDENED" != "YES" ]]; then
    echo "Bỏ qua notarize: cần ký bằng Developer ID Application." >&2
  else
    ZIP="$DD/KietKey-notarize.zip"
    echo "==> Gửi Apple notarize (chỉ bước này cần mạng, app thì không)"
    rm -f "$ZIP"
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
    if [[ -n "$NOTARIZE_KEYCHAIN" ]]; then
      SUBMIT_OUT="$(xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARIZE_PROFILE" \
                      --keychain "$NOTARIZE_KEYCHAIN" --wait 2>&1 || true)"
    else
      SUBMIT_OUT="$(xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARIZE_PROFILE" \
                      --wait 2>&1 || true)"
    fi
    echo "$SUBMIT_OUT"
    if ! grep -q "status: Accepted" <<<"$SUBMIT_OUT"; then
      SUB_ID="$(grep -m1 "  id: " <<<"$SUBMIT_OUT" | awk '{print $2}')"
      echo "Notarize THẤT BẠI. Xem lý do:" >&2
      KC_HINT=""
      [[ -n "$NOTARIZE_KEYCHAIN" ]] && KC_HINT=" --keychain $NOTARIZE_KEYCHAIN"
      echo "  xcrun notarytool log $SUB_ID --keychain-profile $NOTARIZE_PROFILE$KC_HINT" >&2
      exit 1
    fi
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
