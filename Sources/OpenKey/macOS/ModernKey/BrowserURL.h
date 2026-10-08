//
//  BrowserURL.h
//  KietKey
//
//  Đọc tên miền của trang đang xem trên trình duyệt đang ở phía trước,
//  qua Accessibility API (quyền app đã có sẵn để gõ tiếng Việt).
//
//  Chỉ lấy HOST, không đọc đường dẫn, không đọc nội dung trang, không gửi đi đâu.
//
//  Giới hạn đã biết:
//   - Chỉ chạy với Safari và các trình duyệt nền Chromium. Firefox không ổn định.
//   - macOS không báo khi đổi tab/URL, nên phải hỏi theo chu kỳ.
//

#ifndef BrowserURL_h
#define BrowserURL_h

#import <Foundation/Foundation.h>

/// Bundle id đang ở phía trước có phải trình duyệt mà ta đọc được URL không.
BOOL BrowserURLIsBrowser(NSString* bundleId);

/// Tên miền của tab đang xem (ví dụ "github.com"), hoặc nil nếu không đọc được.
/// Gọi trên main thread.
NSString* BrowserURLCurrentHost(void);

/// Bắt đầu / ngừng theo dõi theo chu kỳ để áp dụng quy tắc theo tên miền.
/// Không tốn gì khi chưa đặt quy tắc nào: thoát ngay ở bước đầu.
///
/// Quy tắc lưu ở NSUserDefaults khoá "vWebsiteRules", dạng { "<tên miền>": 0|1 }
/// với 0 = English, 1 = tiếng Việt. Khớp cả tên miền con:
/// quy tắc "google.com" áp cho "mail.google.com".
///
///   defaults write com.tuyenmai.openkey vWebsiteRules -dict github.com 0 messenger.com 1
///
/// Tắt hẳn: defaults write com.tuyenmai.openkey vUseWebsiteRules -int 0
void BrowserURLStartWatching(void);
void BrowserURLStopWatching(void);

#endif /* BrowserURL_h */
