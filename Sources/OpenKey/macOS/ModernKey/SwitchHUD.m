//
//  SwitchHUD.m
//  KietKey
//

#import "SwitchHUD.h"
#import <Cocoa/Cocoa.h>

static const CGFloat kHudSize       = 132.0;
static const CGFloat kHudRadius     = 30.0;
static const CGFloat kLetterHeight  = 58.0;
static const CGFloat kCaptionHeight = 17.0;
static const CGFloat kBottomMargin  = 180.0; //cách đáy vùng hiển thị
static const NSTimeInterval kHoldDuration  = 0.60;
static const NSTimeInterval kFadeDuration  = 0.22;
static const NSTimeInterval kSlideDuration = 0.26;
static const NSTimeInterval kFrameInterval = 1.0 / 60.0;

#pragma mark - đường cong & tween

/// Giải cubic-bezier kiểu CSS: cho x (phần thời gian) trả về y (phần quãng đường).
static CGFloat bezierEase(CGFloat x, CGFloat x1, CGFloat y1, CGFloat x2, CGFloat y2) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    CGFloat lo = 0, hi = 1, u = x;
    for (int i = 0; i < 24; i++) {
        CGFloat omu = 1 - u;
        CGFloat bx = 3 * omu * omu * u * x1 + 3 * omu * u * u * x2 + u * u * u;
        if (bx < x) lo = u; else hi = u;
        u = (lo + hi) / 2;
    }
    CGFloat omu = 1 - u;
    return 3 * omu * omu * u * y1 + 3 * omu * u * u * y2 + u * u * u;
}

static CGFloat easeFade(CGFloat t)  { return bezierEase(t, 0.33, 0.0, 0.67, 1.0); }
static CGFloat easeSlide(CGFloat t) { return bezierEase(t, 0.62, 0.01, 0.20, 1.0); }

/// Tween chạy bằng NSTimer.
/// KHÔNG dùng animator của AppKit: trong app dạng agent (LSUIElement, không bao
/// giờ được kích hoạt) animator của NSWindow không chạy — đã đo được: alpha
/// đứng nguyên 0 suốt, HUD không bao giờ hiện lẫn không bao giờ tắt.
@interface KKTween : NSObject
@property (strong) NSTimer* timer;
@property (assign) NSTimeInterval duration;
@property (strong) NSDate* startedAt;
@property (assign) CGFloat (*easing)(CGFloat);
@property (copy) void (^step)(CGFloat);
@property (copy) void (^completion)(void);
@end

@implementation KKTween

+ (KKTween*)startWithDuration:(NSTimeInterval)duration
                       easing:(CGFloat (*)(CGFloat))easing
                         step:(void (^)(CGFloat))step
                   completion:(void (^)(void))completion {
    KKTween* tween = [[KKTween alloc] init];
    tween.duration = duration;
    tween.easing = easing;
    tween.step = step;
    tween.completion = completion;
    tween.startedAt = [NSDate date];
    step(easing(0));
    tween.timer = [NSTimer timerWithTimeInterval:kFrameInterval
                                          target:tween
                                        selector:@selector(tick:)
                                        userInfo:nil
                                         repeats:YES];
    //CommonModes: HUD vẫn chạy khi đang mở menu trên thanh trạng thái
    [[NSRunLoop mainRunLoop] addTimer:tween.timer forMode:NSRunLoopCommonModes];
    return tween;
}

- (void)tick:(NSTimer*)timer {
    NSTimeInterval elapsed = -[self.startedAt timeIntervalSinceNow];
    CGFloat t = self.duration > 0 ? (CGFloat)(elapsed / self.duration) : 1.0;
    if (t >= 1.0) {
        void (^done)(void) = self.completion;
        self.step(1.0);
        [self cancel];
        if (done) done();
        return;
    }
    self.step(self.easing(t));
}

- (void)cancel {
    [self.timer invalidate];
    self.timer = nil;
}

@end

#pragma mark - HUD

@interface KKSwitchHUD : NSObject
@property (strong) NSPanel* panel;
@property (strong) NSView* letterStack;
@property (strong) NSView* captionStack;
@property (strong) NSTimer* hideTimer;
@property (strong) KKTween* fadeTween;
@property (strong) KKTween* slideTween;
@property (assign) BOOL currentIsVietnamese;
@property (assign) BOOL isVisible;
@end

@implementation KKSwitchHUD

+ (instancetype)shared {
    static KKSwitchHUD* instance = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[KKSwitchHUD alloc] init]; });
    return instance;
}

#pragma mark dựng giao diện

static NSTextField* makeLabel(NSString* text, CGFloat fontSize, NSFontWeight weight,
                              CGFloat alpha, NSRect frame) {
    NSTextField* label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.font = [NSFont systemFontOfSize:fontSize weight:weight];
    label.textColor = [NSColor colorWithWhite:1.0 alpha:alpha];
    label.alignment = NSTextAlignmentCenter;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    return label;
}

/// Khung cắt chứa cột hai ô: trạng thái Việt ở nửa trên, English ở nửa dưới.
static NSView* makeSlidingPair(NSString* topText, NSString* bottomText,
                               CGFloat fontSize, NSFontWeight weight, CGFloat alpha,
                               CGFloat width, CGFloat cellHeight,
                               NSView* __strong * stackOut) {
    NSView* clip = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, cellHeight)];
    clip.wantsLayer = YES;
    clip.layer.masksToBounds = YES;

    __strong NSView* stack = [[NSView alloc] initWithFrame:NSMakeRect(0, -cellHeight, width, cellHeight * 2)];
    //toạ độ AppKit gốc dưới-trái: ô trên nằm ở y = cellHeight
    [stack addSubview:makeLabel(topText, fontSize, weight, alpha,
                                NSMakeRect(0, cellHeight, width, cellHeight))];
    [stack addSubview:makeLabel(bottomText, fontSize, weight, alpha,
                                NSMakeRect(0, 0, width, cellHeight))];
    [clip addSubview:stack];

    *stackOut = stack;
    return clip;
}

- (void)buildPanelIfNeeded {
    if (self.panel != nil)
        return;

    NSRect frame = NSMakeRect(0, 0, kHudSize, kHudSize);

    NSPanel* panel = [[NSPanel alloc] initWithContentRect:frame
                                                styleMask:NSWindowStyleMaskBorderless
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    panel.opaque = NO;
    panel.backgroundColor = [NSColor clearColor];
    panel.hasShadow = YES;
    panel.level = NSStatusWindowLevel;
    panel.ignoresMouseEvents = YES;
    panel.floatingPanel = YES;
    panel.hidesOnDeactivate = NO;
    panel.releasedWhenClosed = NO;
    panel.animationBehavior = NSWindowAnimationBehaviorNone;
    panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces |
                               NSWindowCollectionBehaviorFullScreenAuxiliary |
                               NSWindowCollectionBehaviorStationary |
                               NSWindowCollectionBehaviorIgnoresCycle;
    panel.alphaValue = 0.0;

    NSView* content = [[NSView alloc] initWithFrame:frame];
    content.wantsLayer = YES;

    NSView* letterStack = nil;
    NSView* letterClip = makeSlidingPair(@"V", @"E", 54, NSFontWeightSemibold, 1.0,
                                         kHudSize, kLetterHeight, &letterStack);
    letterClip.frame = NSMakeRect(0, (kHudSize - kLetterHeight) / 2.0 + 10, kHudSize, kLetterHeight);
    [content addSubview:letterClip];
    self.letterStack = letterStack;

    NSView* captionStack = nil;
    NSView* captionClip = makeSlidingPair(@"Tiếng Việt", @"English", 12.5, NSFontWeightRegular, 0.92,
                                          kHudSize, kCaptionHeight, &captionStack);
    captionClip.frame = NSMakeRect(0, (kHudSize - kLetterHeight) / 2.0 - 12, kHudSize, kCaptionHeight);
    [content addSubview:captionClip];
    self.captionStack = captionStack;

    //lớp kính của macOS 26
    NSGlassEffectView* glass = [[NSGlassEffectView alloc] initWithFrame:frame];
    glass.cornerRadius = kHudRadius;
    glass.contentView = content;
    panel.contentView = glass;

    self.panel = panel;
}

#pragma mark vị trí

- (void)centerOnActiveScreen {
    NSPoint mouse = [NSEvent mouseLocation];
    NSScreen* target = [NSScreen mainScreen];
    for (NSScreen* screen in [NSScreen screens]) {
        if (NSPointInRect(mouse, screen.frame)) {
            target = screen;
            break;
        }
    }
    if (target == nil)
        return;
    NSRect visible = target.visibleFrame;
    [self.panel setFrameOrigin:NSMakePoint(NSMidX(visible) - kHudSize / 2.0,
                                           NSMinY(visible) + kBottomMargin)];
}

#pragma mark trượt chữ

/// Ô "V" nằm ở nửa trên, nên muốn hiện V thì cột phải tụt xuống đúng một ô.
static CGFloat stackOffsetFor(BOOL vietnamese, CGFloat cellHeight) {
    return vietnamese ? -cellHeight : 0;
}

- (void)setStacksToVietnamese:(BOOL)vietnamese animated:(BOOL)animated {
    [self.slideTween cancel];
    self.slideTween = nil;

    CGFloat letterTo  = stackOffsetFor(vietnamese, kLetterHeight);
    CGFloat captionTo = stackOffsetFor(vietnamese, kCaptionHeight);

    if (!animated) {
        NSRect lf = self.letterStack.frame;  lf.origin.y = letterTo;  self.letterStack.frame = lf;
        NSRect cf = self.captionStack.frame; cf.origin.y = captionTo; self.captionStack.frame = cf;
        return;
    }

    CGFloat letterFrom  = self.letterStack.frame.origin.y;
    CGFloat captionFrom = self.captionStack.frame.origin.y;
    __weak KKSwitchHUD* weakSelf = self;

    self.slideTween = [KKTween startWithDuration:kSlideDuration
                                          easing:easeSlide
                                            step:^(CGFloat p) {
        KKSwitchHUD* strongSelf = weakSelf;
        if (strongSelf == nil) return;
        NSRect lf = strongSelf.letterStack.frame;
        lf.origin.y = letterFrom + (letterTo - letterFrom) * p;
        strongSelf.letterStack.frame = lf;
        NSRect cf = strongSelf.captionStack.frame;
        cf.origin.y = captionFrom + (captionTo - captionFrom) * p;
        strongSelf.captionStack.frame = cf;
    } completion:nil];
}

#pragma mark hiện / ẩn

- (void)fadeTo:(CGFloat)target completion:(void (^)(void))completion {
    [self.fadeTween cancel];
    self.fadeTween = nil;
    CGFloat from = self.panel.alphaValue;
    if (fabs(target - from) < 0.001) {
        self.panel.alphaValue = target;
        if (completion) completion();
        return;
    }
    __weak KKSwitchHUD* weakSelf = self;
    self.fadeTween = [KKTween startWithDuration:kFadeDuration
                                         easing:easeFade
                                           step:^(CGFloat p) {
        KKSwitchHUD* strongSelf = weakSelf;
        if (strongSelf == nil) return;
        strongSelf.panel.alphaValue = from + (target - from) * p;
    } completion:completion];
}

- (void)showVietnamese:(BOOL)vietnamese {
    [self buildPanelIfNeeded];

    BOOL wasVisible = self.isVisible;
    BOOL changed = (vietnamese != self.currentIsVietnamese);

    //Phương án A: lần hiện mới thì đặt thẳng chữ; chỉ trượt khi HUD đang hiện sẵn.
    [self setStacksToVietnamese:vietnamese animated:(wasVisible && changed)];
    self.currentIsVietnamese = vietnamese;

    if (!wasVisible) {
        [self centerOnActiveScreen];
        [self.panel orderFrontRegardless];
        self.isVisible = YES;
        [self fadeTo:1.0 completion:nil];
    }

    [self.hideTimer invalidate];
    NSTimeInterval hold = kHoldDuration + ((wasVisible && changed) ? kSlideDuration : 0);
    self.hideTimer = [NSTimer timerWithTimeInterval:hold
                                             target:self
                                           selector:@selector(hideTimerFired:)
                                           userInfo:nil
                                            repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.hideTimer forMode:NSRunLoopCommonModes];
}

- (void)hideTimerFired:(NSTimer*)timer {
    [self fadeOut];
}

- (void)fadeOut {
    if (!self.isVisible)
        return;
    self.isVisible = NO;
    __weak KKSwitchHUD* weakSelf = self;
    [self fadeTo:0.0 completion:^{
        KKSwitchHUD* strongSelf = weakSelf;
        if (strongSelf != nil && !strongSelf.isVisible)
            [strongSelf.panel orderOut:nil];
    }];
}

- (void)dismissNow {
    [self.hideTimer invalidate];
    self.hideTimer = nil;
    [self.fadeTween cancel];
    self.fadeTween = nil;
    [self.slideTween cancel];
    self.slideTween = nil;
    self.isVisible = NO;
    self.panel.alphaValue = 0.0;
    [self.panel orderOut:nil];
}

@end

#pragma mark - API dạng hàm

static BOOL hudEnabled(void) {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"vShowSwitchHUD"] == nil)
        return YES; //bật sẵn
    return [defaults integerForKey:@"vShowSwitchHUD"] != 0;
}

void SwitchHUDShow(BOOL vietnamese) {
    if (!hudEnabled())
        return;
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ SwitchHUDShow(vietnamese); });
        return;
    }
    [[KKSwitchHUD shared] showVietnamese:vietnamese];
}

void SwitchHUDDismiss(void) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ SwitchHUDDismiss(); });
        return;
    }
    [[KKSwitchHUD shared] dismissNow];
}
