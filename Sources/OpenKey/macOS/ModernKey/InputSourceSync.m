//
//  InputSourceSync.m
//  ModernKey
//

#import "InputSourceSync.h"
#import "AppDelegate.h"
#import <Carbon/Carbon.h>

extern AppDelegate* appDelegate;
extern int vLanguage;

/// Đang tự đổi input source, dùng để bỏ qua notification do chính mình gây ra.
static BOOL _isSelectingProgrammatically = NO;
static BOOL _isObserving = NO;

/// Tự tắt tiếng Việt khi bộ gõ hệ thống không phải tiếng Anh (mặc định bật).
static BOOL isSyncEnabled(void) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"SyncWithSystemInputSource"] == nil)
        return YES; //bật sẵn
    return [defaults integerForKey:@"SyncWithSystemInputSource"] != 0;
}

/// Khoá bộ gõ hệ thống ở ABC khi đang bật tiếng Việt (mặc định tắt).
static BOOL isLockEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"vLockInputSourceABC"] != 0;
}

/// Ngôn ngữ chính của một input source có phải tiếng Anh không.
static BOOL isEnglishSource(TISInputSourceRef source) {
    if (source == NULL)
        return NO;

    NSArray* languages = (__bridge NSArray*)
        TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages);
    NSString* primary = languages.firstObject;
    if (primary == nil)
        return NO; //không rõ ngôn ngữ -> coi như không phải tiếng Anh

    return [primary isEqualToString:@"en"] || [primary hasPrefix:@"en-"];
}

BOOL InputSourceSyncIsCurrentEnglish(void) {
    TISInputSourceRef current = TISCopyCurrentKeyboardInputSource();
    if (current == NULL)
        return YES; //không đọc được -> không can thiệp
    BOOL result = isEnglishSource(current);
    CFRelease(current);
    return result;
}

/// Đổi về bàn phím tiếng Anh, không qua bất kỳ gate nào.
static void selectEnglishNow(void) {
    if (InputSourceSyncIsCurrentEnglish())
        return;

    //chỉ xét bàn phím thường (loại bỏ bộ gõ, palette...)
    NSDictionary* filter = @{
        (__bridge NSString*)kTISPropertyInputSourceType:
            (__bridge NSString*)kTISTypeKeyboardLayout
    };
    CFArrayRef sources = TISCreateInputSourceList((__bridge CFDictionaryRef)filter, false);
    if (sources == NULL)
        return;

    TISInputSourceRef chosen = NULL;
    CFIndex count = CFArrayGetCount(sources);
    for (CFIndex i = 0; i < count; i++) {
        TISInputSourceRef source = (TISInputSourceRef)CFArrayGetValueAtIndex(sources, i);
        if (!isEnglishSource(source))
            continue;

        CFBooleanRef selectable =
            (CFBooleanRef)TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable);
        if (selectable != NULL && !CFBooleanGetValue(selectable))
            continue;

        NSString* sourceId = (__bridge NSString*)
            TISGetInputSourceProperty(source, kTISPropertyInputSourceID);

        if ([sourceId isEqualToString:@"com.apple.keylayout.ABC"]) {
            chosen = source; //ưu tiên ABC
            break;
        }
        if (chosen == NULL)
            chosen = source; //dự phòng: bàn phím tiếng Anh đầu tiên tìm được
    }

    if (chosen != NULL) {
        _isSelectingProgrammatically = YES;
        TISSelectInputSource(chosen);
        //notification được gửi không đồng bộ, nên bỏ cờ ở vòng run loop sau
        dispatch_async(dispatch_get_main_queue(), ^{
            _isSelectingProgrammatically = NO;
        });
    }

    CFRelease(sources);
}

void InputSourceSyncSelectEnglish(void) {
    //cả hai tính năng đều cần hệ thống ở tiếng Anh khi bật tiếng Việt
    if (isSyncEnabled() || isLockEnabled())
        selectEnglishNow();
}

/// Chống ping-pong: nếu hệ thống liên tục đổi lại, ngừng kéo về ABC một lúc
/// thay vì giành nhau vô hạn.
static BOOL shouldThrottleRevert(void) {
    static const int kMaxReverts = 5;
    static const NSTimeInterval kWindow = 2.0;   //cửa sổ đếm
    static const NSTimeInterval kCooldown = 5.0; //nghỉ sau khi vượt ngưỡng

    static int count = 0;
    static NSTimeInterval windowStart = 0;
    static NSTimeInterval cooldownUntil = 0;

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

    if (now < cooldownUntil)
        return YES;

    if (now - windowStart > kWindow) {
        windowStart = now;
        count = 0;
    }
    if (++count > kMaxReverts) {
        cooldownUntil = now + kCooldown;
        count = 0;
        windowStart = now;
        return YES;
    }
    return NO;
}

static void onInputSourceChanged(CFNotificationCenterRef center,
                                 void* observer,
                                 CFNotificationName name,
                                 const void* object,
                                 CFDictionaryRef userInfo) {
    if (_isSelectingProgrammatically)
        return;
    if (vLanguage != 1)
        return; //đang ở tiếng Anh thì để người dùng tự do đổi bộ gõ
    if (InputSourceSyncIsCurrentEnglish())
        return;

    if (isLockEnabled()) {
        //Khoá: giữ tiếng Việt, kéo bộ gõ hệ thống về ABC ngay.
        if (shouldThrottleRevert())
            return;
        dispatch_async(dispatch_get_main_queue(), ^{
            selectEnglishNow();
        });
    } else if (isSyncEnabled()) {
        //Không khoá: nhường quyền cho bộ gõ hệ thống, tắt tiếng Việt.
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate setVietnameseEnabled:NO];
        });
    }
}

void InputSourceSyncStart(void) {
    if (_isObserving)
        return;
    _isObserving = YES;

    CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                    NULL,
                                    onInputSourceChanged,
                                    kTISNotifySelectedKeyboardInputSourceChanged,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    //xử lý luôn trạng thái lúc khởi động
    onInputSourceChanged(NULL, NULL, NULL, NULL, NULL);
}

void InputSourceSyncStop(void) {
    if (!_isObserving)
        return;
    _isObserving = NO;

    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDistributedCenter(),
                                       NULL,
                                       kTISNotifySelectedKeyboardInputSourceChanged,
                                       NULL);
}
