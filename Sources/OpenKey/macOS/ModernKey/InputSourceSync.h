//
//  InputSourceSync.h
//  ModernKey
//
//  Đồng bộ trạng thái KietKey với input source của macOS, để tránh xung đột
//  khi máy có sẵn bộ gõ tiếng Việt của hệ thống (vd. Simple Telex).
//
//  Khi KietKey BẬT tiếng Việt -> đổi input source của macOS về tiếng Anh (ABC).
//
//  Khi macOS đổi sang input source KHÔNG phải tiếng Anh, có hai chế độ:
//
//   A. "Khoá bộ gõ ở ABC" TẮT (mặc định) -> nhường quyền cho bộ gõ hệ thống:
//      tắt tiếng Việt của KietKey. Bật/tắt bằng:
//        defaults write com.tuyenmai.openkey SyncWithSystemInputSource -int 0
//
//   B. "Khoá bộ gõ ở ABC" BẬT -> giữ tiếng Việt, kéo input source về ABC ngay.
//      Muốn dùng bộ gõ của macOS thì phải tắt tiếng Việt của KietKey trước.
//      Bật/tắt bằng checkbox trong tab "Gõ tiếng Việt", hoặc:
//        defaults write com.tuyenmai.openkey vLockInputSourceABC -int 1
//
//  Chế độ B có ưu tiên cao hơn A khi cả hai cùng bật.
//
//  macOS không có API để chặn (veto) việc đổi input source, nên B được làm
//  bằng cách đổi lại ngay sau khi hệ thống đã đổi. Có throttle chống ping-pong.
//

#ifndef InputSourceSync_h
#define InputSourceSync_h

#import <Foundation/Foundation.h>

/// Bật theo dõi thay đổi input source của hệ thống. Gọi 1 lần lúc khởi động.
void InputSourceSyncStart(void);

/// Ngừng theo dõi.
void InputSourceSyncStop(void);

/// Input source đang chọn có phải tiếng Anh không.
BOOL InputSourceSyncIsCurrentEnglish(void);

/// Đổi input source của hệ thống về bàn phím tiếng Anh (ưu tiên ABC).
/// Không làm gì nếu input source hiện tại đã là tiếng Anh.
void InputSourceSyncSelectEnglish(void);

#endif /* InputSourceSync_h */
