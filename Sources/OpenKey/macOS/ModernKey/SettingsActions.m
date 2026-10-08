//
//  SettingsActions.m
//  KietKey
//

#import "SettingsActions.h"
#import "AppDelegate.h"
#import "OpenKeyManager.h"

extern AppDelegate* appDelegate;

extern void OnSpellCheckingChanged(void);

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

#pragma mark - khác

+ (NSString*)versionString {
    NSBundle* bundle = [NSBundle mainBundle];
    return [NSString stringWithFormat:@"%@ (build %@)",
            [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
            [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
}

@end
