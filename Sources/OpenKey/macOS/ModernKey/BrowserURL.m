//
//  BrowserURL.m
//  KietKey
//

#import "BrowserURL.h"
#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import "AppDelegate.h"

extern AppDelegate* appDelegate;

/// Giới hạn độ sâu khi dò cây Accessibility. Vùng web thường nằm rất nông;
/// đặt trần để không bao giờ bò hết cây DOM của một trang lớn.
static const int kMaxDepth = 6;
static const int kMaxChildrenPerLevel = 40;

static NSSet<NSString*>* browserBundleIds(void) {
    static NSSet* ids = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ids = [NSSet setWithArray:@[
            @"com.apple.Safari",
            @"com.apple.SafariTechnologyPreview",
            @"com.google.Chrome",
            @"com.google.Chrome.beta",
            @"com.google.Chrome.canary",
            @"com.microsoft.edgemac",
            @"com.brave.Browser",
            @"company.thebrowser.Browser",   //Arc
            @"com.vivaldi.Vivaldi",
            @"com.operasoftware.Opera",
            @"ru.yandex.desktop.yandex-browser",
        ]];
    });
    return ids;
}

BOOL BrowserURLIsBrowser(NSString* bundleId) {
    if (bundleId == nil)
        return NO;
    return [browserBundleIds() containsObject:bundleId];
}

#pragma mark - tiện ích Accessibility

static id copyAttribute(AXUIElementRef element, CFStringRef attribute) {
    if (element == NULL)
        return nil;
    CFTypeRef value = NULL;
    AXError err = AXUIElementCopyAttributeValue(element, attribute, &value);
    if (err != kAXErrorSuccess || value == NULL)
        return nil;
    return CFBridgingRelease(value);
}

/// URL có thể nằm ở AXURL (Chromium) hoặc AXDocument (Safari); cả hai có khi
/// trả về NSURL, có khi trả về NSString.
static NSString* urlStringFromElement(AXUIElementRef element) {
    for (NSString* attr in @[(__bridge NSString*)kAXURLAttribute, @"AXDocument"]) {
        id value = copyAttribute(element, (__bridge CFStringRef)attr);
        if ([value isKindOfClass:[NSURL class]])
            return [(NSURL*)value absoluteString];
        if ([value isKindOfClass:[NSString class]] && [(NSString*)value length] > 0)
            return (NSString*)value;
    }
    return nil;
}

/// Dò theo bề rộng tìm phần tử mang URL. Dừng sớm ngay khi thấy.
static NSString* findURLInTree(AXUIElementRef root, int depth) {
    if (root == NULL || depth > kMaxDepth)
        return nil;

    NSString* url = urlStringFromElement(root);
    if (url != nil)
        return url;

    NSArray* children = copyAttribute(root, kAXChildrenAttribute);
    NSUInteger count = MIN(children.count, (NSUInteger)kMaxChildrenPerLevel);
    for (NSUInteger i = 0; i < count; i++) {
        id child = children[i];
        if (CFGetTypeID((__bridge CFTypeRef)child) != AXUIElementGetTypeID())
            continue;
        NSString* found = findURLInTree((__bridge AXUIElementRef)child, depth + 1);
        if (found != nil)
            return found;
    }
    return nil;
}

#pragma mark - API

NSString* BrowserURLCurrentHost(void) {
    NSRunningApplication* front = [[NSWorkspace sharedWorkspace] frontmostApplication];
    if (front == nil || !BrowserURLIsBrowser(front.bundleIdentifier))
        return nil;

    AXUIElementRef app = AXUIElementCreateApplication(front.processIdentifier);
    if (app == NULL)
        return nil;

    NSString* urlString = nil;
    id window = copyAttribute(app, kAXFocusedWindowAttribute);
    if (window != nil && CFGetTypeID((__bridge CFTypeRef)window) == AXUIElementGetTypeID()) {
        urlString = findURLInTree((__bridge AXUIElementRef)window, 0);
    }
    CFRelease(app);

    if (urlString.length == 0)
        return nil;

    NSURL* url = [NSURL URLWithString:urlString];
    NSString* host = url.host;
    if (host.length == 0)
        return nil;

    //bỏ "www." để quy tắc viết gọn hơn
    if ([host hasPrefix:@"www."])
        host = [host substringFromIndex:4];
    return [host lowercaseString];
}

#pragma mark - theo dõi & quy tắc theo tên miền

static const NSTimeInterval kPollInterval = 1.0;

@interface KKWebsiteWatcher : NSObject
@property (strong) NSTimer* timer;
@property (copy) NSString* lastHost;
@end

@implementation KKWebsiteWatcher

+ (instancetype)shared {
    static KKWebsiteWatcher* instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[KKWebsiteWatcher alloc] init]; });
    return instance;
}

- (NSDictionary*)rules {
    id value = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"vWebsiteRules"];
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

- (BOOL)isEnabled {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"vUseWebsiteRules"] != nil &&
        [defaults integerForKey:@"vUseWebsiteRules"] == 0)
        return NO;
    return [self rules].count > 0;
}

/// Khớp chính xác, hoặc khớp tên miền con ("mail.google.com" khớp "google.com").
- (NSNumber*)ruleForHost:(NSString*)host {
    NSDictionary* rules = [self rules];
    NSNumber* exact = rules[host];
    if (exact != nil)
        return exact;
    for (NSString* domain in rules) {
        if ([host hasSuffix:[@"." stringByAppendingString:domain]])
            return rules[domain];
    }
    return nil;
}

/// Bật bằng: defaults write com.tuyenmai.openkey vWebsiteDebug -int 1
/// rồi xem:  defaults read com.tuyenmai.openkey vWebsiteLastSeen
static BOOL debugEnabled(void) {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"vWebsiteDebug"] != 0;
}

- (void)tick:(NSTimer*)timer {
    if (![self isEnabled]) {
        if (debugEnabled())
            NSLog(@"[KietKey/web] tắt hoặc chưa có quy tắc nào");
        return;
    }

    NSString* host = BrowserURLCurrentHost();

    if (host == nil) {
        self.lastHost = nil; //rời trình duyệt -> lần quay lại coi như mới
        return;
    }
    if ([host isEqualToString:self.lastHost])
        return;
    self.lastHost = host;

    NSNumber* rule = [self ruleForHost:host];

    //Chẩn đoán: ghi thẳng vào defaults thay vì NSLog. os_log chặn thông điệp
    //lặp dày và nhiều khi không hiện ra `log show`, nên không tin được.
    //Xem bằng: defaults read com.tuyenmai.openkey vWebsiteLastSeen
    if (debugEnabled()) {
        NSString* seen = [NSString stringWithFormat:@"%@ -> %@", host,
                          rule == nil ? @"(khong co quy tac)"
                                      : ([rule integerValue] != 0 ? @"tieng Viet" : @"English")];
        [[NSUserDefaults standardUserDefaults] setObject:seen forKey:@"vWebsiteLastSeen"];
    }
    if (rule == nil)
        return; //không có quy tắc -> để nguyên, nhường cho quy tắc theo ứng dụng

    [appDelegate setVietnameseEnabled:([rule integerValue] != 0)];
}

- (void)start {
    if (self.timer != nil)
        return;
    self.timer = [NSTimer timerWithTimeInterval:kPollInterval
                                         target:self
                                       selector:@selector(tick:)
                                       userInfo:nil
                                        repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
    self.lastHost = nil;
}

@end

void BrowserURLStartWatching(void) { [[KKWebsiteWatcher shared] start]; }
void BrowserURLStopWatching(void)  { [[KKWebsiteWatcher shared] stop]; }
