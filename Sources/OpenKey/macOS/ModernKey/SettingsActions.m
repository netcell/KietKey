//
//  SettingsActions.m
//  KietKey
//

#import "SettingsActions.h"
#import "AppDelegate.h"
#import "OpenKeyManager.h"
#import <Cocoa/Cocoa.h>

extern AppDelegate* appDelegate;

extern void OnSpellCheckingChanged(void);
extern void OnSwitchKeyListChanged(void);

extern int vLanguage;
extern int vInputType;
extern int vCodeTable;
extern int vCheckSpelling;
extern int vUseModernOrthography;
extern int vFreeMark;
extern int vQuickTelex;
extern int vUseSmartSwitchKey;
extern int vRememberCode;
extern int vOtherLanguage;
extern int vUpperCaseFirstChar;
extern int vRestoreIfWrongSpelling;
extern int vSwitchKeyStatus;
extern int vHijackInputSourceKey;

@implementation KKSettingsActions

#pragma mark - tiếng Việt / English

+ (BOOL)vietnameseEnabled {
    return vLanguage == 1;
}

+ (void)setVietnameseEnabled:(BOOL)enabled {
    [appDelegate setVietnameseEnabled:enabled];
}

#pragma mark - kiểu gõ & bảng mã

+ (NSInteger)inputType {
    return vInputType;
}

+ (void)setInputType:(NSInteger)index {
    [appDelegate onInputTypeSelectedIndex:(int)index];
}

+ (NSArray<NSString*>*)inputTypeNames {
    return @[@"Telex", @"VNI", @"Simple Telex 1", @"Simple Telex 2"];
}

+ (NSInteger)codeTable {
    return vCodeTable;
}

+ (void)setCodeTable:(NSInteger)index {
    [appDelegate onCodeTableChanged:(int)index];
}

+ (NSArray<NSString*>*)codeTableNames {
    return [OpenKeyManager getTableCodes];
}

#pragma mark - công tắc

/// Khoá NSUserDefaults -> biến engine. Khoá không có trong bảng thì chỉ lưu
/// vào defaults (ví dụ các tuỳ chọn thuần giao diện như HUD).
static int* engineVariableForKey(NSString* key) {
    if ([key isEqualToString:@"Spelling"])            return &vCheckSpelling;
    if ([key isEqualToString:@"ModernOrthography"])   return &vUseModernOrthography;
    if ([key isEqualToString:@"FreeMark"])            return &vFreeMark;
    if ([key isEqualToString:@"QuickTelex"])          return &vQuickTelex;
    if ([key isEqualToString:@"UseSmartSwitchKey"])   return &vUseSmartSwitchKey;
    if ([key isEqualToString:@"vRememberCode"])       return &vRememberCode;
    if ([key isEqualToString:@"vOtherLanguage"])      return &vOtherLanguage;
    if ([key isEqualToString:@"UpperCaseFirstChar"])  return &vUpperCaseFirstChar;
    if ([key isEqualToString:@"RestoreIfWrongSpelling"]) return &vRestoreIfWrongSpelling;
    if ([key isEqualToString:@"vHijackInputSourceKey"]) return &vHijackInputSourceKey;
    return NULL;
}

/// Các khoá mà khi chưa đặt gì thì coi như đang BẬT.
static BOOL defaultsToOn(NSString* key) {
    return [key isEqualToString:@"vShowSwitchHUD"] ||
           [key isEqualToString:@"SyncWithSystemInputSource"];
}

+ (BOOL)flagForKey:(NSString*)key {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key] == nil)
        return defaultsToOn(key);
    return [defaults integerForKey:key] != 0;
}

+ (void)setFlag:(BOOL)value forKey:(NSString*)key {
    [[NSUserDefaults standardUserDefaults] setInteger:(value ? 1 : 0) forKey:key];

    int* engineVar = engineVariableForKey(key);
    if (engineVar != NULL)
        *engineVar = value ? 1 : 0;

    if ([key isEqualToString:@"Spelling"])
        OnSpellCheckingChanged();
}

#pragma mark - chế độ bộ gõ hệ thống

+ (KKSystemInputSourceMode)systemInputSourceMode {
    if ([self flagForKey:@"vLockInputSourceABC"])
        return KKSystemInputSourceModeLock;
    if ([self flagForKey:@"SyncWithSystemInputSource"])
        return KKSystemInputSourceModeYield;
    return KKSystemInputSourceModeIgnore;
}

+ (void)setSystemInputSourceMode:(KKSystemInputSourceMode)mode {
    [self setFlag:(mode == KKSystemInputSourceModeLock)   forKey:@"vLockInputSourceABC"];
    [self setFlag:(mode != KKSystemInputSourceModeIgnore) forKey:@"SyncWithSystemInputSource"];
    //vOtherLanguage là cơ chế cũ của upstream: bỏ qua phím khi bộ gõ hệ thống
    //không phải tiếng Anh. Để nó đi cùng chế độ thay vì là một công tắc riêng.
    [self setFlag:(mode != KKSystemInputSourceModeIgnore) forKey:@"vOtherLanguage"];
}

#pragma mark - quy tắc theo ứng dụng

+ (NSDictionary*)rawAppRules {
    NSDictionary* rules = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"vAppRules"];
    return [rules isKindOfClass:[NSDictionary class]] ? rules : @{};
}

+ (NSString*)displayNameForBundleId:(NSString*)bundleId {
    NSURL* url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleId];
    if (url == nil)
        return bundleId;
    NSString* name = [[NSFileManager defaultManager] displayNameAtPath:url.path];
    name = [name stringByDeletingPathExtension];
    return name.length > 0 ? name : bundleId;
}

+ (NSArray<NSDictionary*>*)appRules {
    NSDictionary* rules = [self rawAppRules];
    NSMutableArray* out = [NSMutableArray array];
    for (NSString* bundleId in rules) {
        [out addObject:@{@"id": bundleId,
                         @"name": [self displayNameForBundleId:bundleId],
                         @"mode": @([rules[bundleId] integerValue])}];
    }
    //sắp theo TÊN hiển thị, vì đó là thứ người dùng đọc; sắp theo bundle id
    //cho ra thứ tự trông như ngẫu nhiên
    return [out sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
}

+ (void)setAppRuleMode:(NSInteger)mode forBundleId:(NSString*)bundleId {
    if (bundleId.length == 0) return;
    NSMutableDictionary* rules = [[self rawAppRules] mutableCopy];
    rules[bundleId] = @(mode);
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:@"vAppRules"];
}

+ (void)removeAppRuleForBundleId:(NSString*)bundleId {
    NSMutableDictionary* rules = [[self rawAppRules] mutableCopy];
    [rules removeObjectForKey:bundleId];
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:@"vAppRules"];
}

+ (NSArray<NSDictionary*>*)pickableApps {
    NSMutableArray* out = [NSMutableArray array];
    NSMutableSet* seen = [NSMutableSet set];
    NSDictionary* existing = [self rawAppRules];
    for (NSRunningApplication* app in [[NSWorkspace sharedWorkspace] runningApplications]) {
        if (app.activationPolicy != NSApplicationActivationPolicyRegular)
            continue; //bỏ qua tiến trình nền, không có cửa sổ để gõ
        NSString* bundleId = app.bundleIdentifier;
        if (bundleId.length == 0 || [seen containsObject:bundleId] || existing[bundleId] != nil)
            continue;
        [seen addObject:bundleId];
        [out addObject:@{@"id": bundleId, @"name": app.localizedName ?: bundleId}];
    }
    return [out sortedArrayUsingComparator:^NSComparisonResult(NSDictionary* a, NSDictionary* b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
}

#pragma mark - quy tắc theo website

+ (NSDictionary*)rawWebsiteRules {
    NSDictionary* rules = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"vWebsiteRules"];
    return [rules isKindOfClass:[NSDictionary class]] ? rules : @{};
}

+ (NSArray<NSDictionary*>*)websiteRules {
    NSDictionary* rules = [self rawWebsiteRules];
    NSMutableArray* out = [NSMutableArray array];
    for (NSString* host in [rules.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        [out addObject:@{@"host": host, @"mode": @([rules[host] integerValue])}];
    }
    return out;
}

+ (void)setWebsiteRuleMode:(NSInteger)mode forHost:(NSString*)host {
    NSString* clean = [[host stringByTrimmingCharactersInSet:
                        [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([clean hasPrefix:@"www."])
        clean = [clean substringFromIndex:4];
    if (clean.length == 0) return;
    NSMutableDictionary* rules = [[self rawWebsiteRules] mutableCopy];
    rules[clean] = @(mode);
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:@"vWebsiteRules"];
}

+ (void)removeWebsiteRuleForHost:(NSString*)host {
    NSMutableDictionary* rules = [[self rawWebsiteRules] mutableCopy];
    [rules removeObjectForKey:host];
    [[NSUserDefaults standardUserDefaults] setObject:rules forKey:@"vWebsiteRules"];
}

#pragma mark - tổ hợp phím chuyển

+ (NSArray<NSNumber*>*)switchKeys {
    NSMutableArray* keys = [NSMutableArray arrayWithObject:@(vSwitchKeyStatus)];
    NSArray* extra = [[NSUserDefaults standardUserDefaults] arrayForKey:@"vSwitchKeyList"];
    for (id item in extra) {
        if ([item isKindOfClass:[NSNumber class]] && [item intValue] != vSwitchKeyStatus)
            [keys addObject:item];
    }
    return keys;
}

+ (void)setSwitchKeys:(NSArray<NSNumber*>*)keys {
    if (keys.count == 0) return;
    //phần tử đầu vẫn là vSwitchKeyStatus để Bảng điều khiển cũ dùng tiếp được
    vSwitchKeyStatus = [keys.firstObject intValue];
    [[NSUserDefaults standardUserDefaults] setInteger:vSwitchKeyStatus forKey:@"SwitchKeyStatus"];
    NSArray* rest = keys.count > 1
        ? [keys subarrayWithRange:NSMakeRange(1, keys.count - 1)] : @[];
    [[NSUserDefaults standardUserDefaults] setObject:rest forKey:@"vSwitchKeyList"];
    OnSwitchKeyListChanged();
}

+ (NSString*)describeSwitchKey:(NSInteger)hotKey {
    NSMutableString* out = [NSMutableString string];
    if (hotKey & 0x1000) [out appendString:@"fn "];
    if (hotKey & 0x100)  [out appendString:@"⌃"];
    if (hotKey & 0x200)  [out appendString:@"⌥"];
    if (hotKey & 0x400)  [out appendString:@"⌘"];
    if (hotKey & 0x800)  [out appendString:@"⇧"];
    unichar character = (unichar)((hotKey >> 24) & 0xFF);
    if ((hotKey & 0xFF) != 0xFE && character != 0xFE && character != 0) {
        [out appendFormat:@"%@", [[NSString stringWithCharacters:&character length:1] uppercaseString]];
    }
    return out.length > 0 ? out : @"(chưa đặt)";
}

+ (NSInteger)encodeSwitchKeyWithFlags:(NSUInteger)flags
                              keyCode:(NSInteger)keyCode
                            character:(NSString*)character {
    NSInteger value = 0;
    if (flags & NSEventModifierFlagControl)  value |= 0x100;
    if (flags & NSEventModifierFlagOption)   value |= 0x200;
    if (flags & NSEventModifierFlagCommand)  value |= 0x400;
    if (flags & NSEventModifierFlagShift)    value |= 0x800;
    if (flags & NSEventModifierFlagFunction) value |= 0x1000;

    if (keyCode < 0 || keyCode > 0xFD) {
        value |= 0xFE;                    //chỉ dùng phím bổ trợ
        value |= (NSInteger)0xFE << 24;
    } else {
        value |= (keyCode & 0xFF);
        unichar ch = character.length > 0 ? [character characterAtIndex:0] : 0;
        value |= ((NSInteger)(ch & 0xFF)) << 24;
    }
    return value;
}

#pragma mark - khác

+ (NSString*)versionString {
    NSBundle* bundle = [NSBundle mainBundle];
    return [NSString stringWithFormat:@"%@ (build %@)",
            [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
}

@end
