//
//  InputSourceSync.h
//  ModernKey
//
//  Đồng bộ trạng thái OpenKey với input source của macOS, để tránh xung đột
//  khi máy có sẵn bộ gõ tiếng Việt của hệ thống (vd. Simple Telex).
//
//  Hai chiều:
//   1. macOS đổi sang input source KHÔNG phải tiếng Anh -> tắt tiếng Việt của OpenKey.
//   2. OpenKey bật tiếng Việt -> đổi input source của macOS về tiếng Anh (ABC).
//
//  Tắt tính năng:
//    defaults write com.tuyenmai.openkey SyncWithSystemInputSource -int 0
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
