//
//  SettingsActions.h
//  KietKey
//
//  Cầu nối cho cửa sổ Settings viết bằng SwiftUI.
//
//  Mọi thay đổi cài đặt đi qua đây chứ không chạm thẳng vào biến engine, để
//  phần Swift không phải lặp lại logic đã có trong Objective-C (và không
//  phải kéo phần C++ của engine vào trình biên dịch Swift).
//

#ifndef SettingsActions_h
#define SettingsActions_h

#import <Foundation/Foundation.h>

/// Chế độ xử lý khi bộ gõ của macOS đổi sang ngôn ngữ khác tiếng Anh.
/// Gộp ba tuỳ chọn chồng chéo trước đây thành một lựa chọn duy nhất.
typedef NS_ENUM(NSInteger, KKSystemInputSourceMode) {
    KKSystemInputSourceModeIgnore = 0,  //không can thiệp
    KKSystemInputSourceModeYield  = 1,  //nhường bộ gõ hệ thống, tự tắt tiếng Việt
    KKSystemInputSourceModeLock   = 2,  //khoá ở ABC khi đang gõ tiếng Việt
};

@interface KKSettingsActions : NSObject

+ (BOOL)vietnameseEnabled;
+ (void)setVietnameseEnabled:(BOOL)enabled;

+ (NSInteger)inputType;
+ (void)setInputType:(NSInteger)index;
+ (NSArray<NSString*>*)inputTypeNames;

+ (NSInteger)codeTable;
+ (void)setCodeTable:(NSInteger)index;
+ (NSArray<NSString*>*)codeTableNames;

/// Công tắc bật/tắt, định danh bằng khoá NSUserDefaults. Hàm tự cập nhật
/// biến engine tương ứng nếu khoá đó có gắn với engine.
+ (BOOL)flagForKey:(NSString*)key;
+ (void)setFlag:(BOOL)value forKey:(NSString*)key;

+ (KKSystemInputSourceMode)systemInputSourceMode;
+ (void)setSystemInputSourceMode:(KKSystemInputSourceMode)mode;

/// Phiên bản hiển thị, ví dụ "3.0 (2024)".
+ (NSString*)versionString;

@end

#endif /* SettingsActions_h */
