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

static BOOL isFeatureEnabled(void) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"SyncWithSystemInputSource"] == nil)
        return YES; //bật sẵn
    return [defaults integerForKey:@"SyncWithSystemInputSource"] != 0;
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

void InputSourceSyncSelectEnglish(void) {
    if (!isFeatureEnabled())
        return;
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

static void onInputSourceChanged(CFNotificationCenterRef center,
                                 void* observer,
                                 CFNotificationName name,
                                 const void* object,
                                 CFDictionaryRef userInfo) {
    if (_isSelectingProgrammatically)
        return;
    if (!isFeatureEnabled())
        return;

    //macOS đổi sang bộ gõ không phải tiếng Anh -> nhường quyền, tắt tiếng Việt
    if (!InputSourceSyncIsCurrentEnglish() && vLanguage == 1) {
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
