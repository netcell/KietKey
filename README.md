# KietKey

Bộ gõ tiếng Việt cho macOS. **Không kết nối Internet.**

Website: [kietkey.anhnt.com](https://kietkey.anhnt.com)

KietKey là bản phát triển riêng từ [OpenKey](https://github.com/tuyenvm/OpenKey)
của Mai Vũ Tuyên, chỉ tập trung cho macOS. Giấy phép GPL, giữ nguyên như bản gốc.

## Khác gì so với OpenKey

**Không có một dòng code mạng nào.** Toàn bộ phần kiểm tra bản mới và tự cập nhật
đã bị gỡ. Script build tự kiểm tra lại binary và **dừng build** nếu có symbol hay
framework mạng lọt vào.

**Báo hiệu giữa màn hình** khi chuyển tiếng Việt / English, thay cho tiếng beep.
Chữ trượt dọc khi đổi trạng thái.

**Đồng bộ với bộ gõ của macOS.** Ba chế độ: không can thiệp, nhường bộ gõ hệ thống,
hoặc khoá ở ABC khi đang gõ tiếng Việt — để không xung đột với Simple Telex.

**Nhiều tổ hợp phím chuyển** cùng lúc, thêm cả phím `fn`. Máy bàn dùng `⌃⇧`,
MacBook dùng `fn⇧`, không phải đổi qua lại.

**Quy tắc theo ứng dụng và website.** Mỗi app chọn *luôn tắt* / *luôn bật* /
*nhớ lần cuối*. Website đặt theo tên miền, khớp cả tên miền con.

**Chiếm phím đổi bộ gõ của macOS** (`⌃Space`) để bật/tắt tiếng Việt.

**Cửa sổ Cài đặt mới** viết bằng SwiftUI, theo kiểu System Settings của macOS.

## Yêu cầu

macOS 26 trở lên. Cần cấp quyền Accessibility — bắt buộc với mọi bộ gõ.

## Tự build

Cần Xcode 26 trở lên.

```bash
git clone https://github.com/netcell/KietKey.git
cd KietKey
OPENKEY_SIGN_ID="-" ./build.sh
```

Ký ad-hoc như trên thì mỗi lần build lại phải cấp lại quyền Accessibility, vì
macOS gắn quyền theo chữ ký. Muốn chữ ký ổn định thì tạo một certificate tự ký
tên bất kỳ rồi truyền vào `OPENKEY_SIGN_ID`.

Để phân phối cho máy khác mà không bị Gatekeeper chặn thì cần Developer ID +
notarize:

```bash
OPENKEY_SIGN_ID="Developer ID Application: ... (TEAMID)" \
OPENKEY_NOTARIZE_PROFILE=<tên hồ sơ notarytool> \
./build.sh
```

`build.sh` tự bật Hardened Runtime, thêm secure timestamp, gỡ entitlement debug,
gửi Apple notarize rồi staple. Có hai bước kiểm tra chạy ngay trên máy nên hỏng
gì sẽ fail trước khi tốn một vòng gửi lên Apple.

> Lưu ý: `notarytool` lưu hồ sơ trong data-protection keychain với thuộc tính
> *WhenUnlocked*. **Khoá màn hình là không notarize được.** Muốn build tự động
> thì dùng App Store Connect API key (`OPENKEY_NOTARIZE_KEY`).

## Cấu trúc

```
Sources/OpenKey/engine/   engine xử lý tiếng Việt, C++ thuần (chung với OpenKey)
Sources/OpenKey/macOS/    ứng dụng macOS
site/                     website
build.sh                  build + ký + notarize + cài
```

## Giấy phép

GPL, kế thừa từ OpenKey. Mã nguồn gốc: https://github.com/tuyenvm/OpenKey
