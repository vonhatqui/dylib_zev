#import "ModMenuViewController.h"
#import "../esp/drawing_view/icons.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import <objc/runtime.h>
#import "UIView+SecureView.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import "../esp/Core/PlayerModes.h"

// ==========================================
// CÔNG TẮC (SWITCH) DẠNG VIÊN THUỐC ĐỎ - ĐEN
// ==========================================
@interface MizzeCheckBox : UIButton
@property(nonatomic,assign) BOOL on;
@property(nonatomic,strong) UIView *trackView;
@property(nonatomic,strong) UIView *thumbView;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@implementation MizzeCheckBox
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        
        self.trackView = [[UIView alloc] initWithFrame:self.bounds];
        self.trackView.layer.cornerRadius = frame.size.height / 2.0;
        self.trackView.userInteractionEnabled = NO;
        [self addSubview:self.trackView];
        
        CGFloat thumbSize = frame.size.height - 4;
        self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(2, 2, thumbSize, thumbSize)];
        self.thumbView.layer.cornerRadius = thumbSize / 2.0;
        self.thumbView.backgroundColor = [UIColor whiteColor];
        self.thumbView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.thumbView.layer.shadowOffset = CGSizeMake(0, 1.5);
        self.thumbView.layer.shadowOpacity = 0.28;
        self.thumbView.layer.shadowRadius = 2.0;
        self.thumbView.userInteractionEnabled = NO;
        [self addSubview:self.thumbView];
        
        [self setOn:NO animated:NO];
    }
    return self;
}

- (void)setOn:(BOOL)on {
    [self setOn:on animated:NO];
}

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    CGFloat thumbSize = self.bounds.size.height - 4;
    CGFloat targetX = on ? (self.bounds.size.width - thumbSize - 2) : 2;
    UIColor *onColor = [UIColor colorWithRed:0.96 green:0.20 blue:0.26 alpha:1.0]; // Đỏ Gaming ZEV
    UIColor *offColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    
    void (^updateBlock)(void) = ^{
        self.trackView.backgroundColor = on ? onColor : offColor;
        self.thumbView.frame = CGRectMake(targetX, 2, thumbSize, thumbSize);
    };
    
    if (animated) {
        [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:updateBlock completion:nil];
    } else {
        updateBlock();
    }
}
@end

// ==========================================
// CLASS CHÍNH CỦA MENU - GIAO DIỆN HIỆN ĐẠI
// ==========================================
@interface _0xDEADBEEE () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIView *tabIndicator;
@property (nonatomic, strong) NSArray<UIButton *> *navButtons;
@property (nonatomic, assign) CGFloat builtWidth;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) NSMutableArray<UIControl *> *controls;
@property (nonatomic, strong) UILabel *swatch;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, assign) NSInteger colorTarget;
@property (nonatomic, assign) BOOL aimExpanded;
@property (nonatomic, assign) BOOL advancedExpanded;
@property (nonatomic, assign) NSInteger pointer;
@property (nonatomic, assign) CGPoint began;
@property (nonatomic, assign) CGPoint panelOrigin;
@property (nonatomic, assign) CGFloat scrollOrigin;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, strong) UIControl *activeControl;
@property (nonatomic, strong) UILabel *spinStatusLabel;
@property (nonatomic, strong) NSTimer *spinStatusTimer;
@property (nonatomic, strong) UILabel *fpsLabel;
@property (nonatomic, strong) CADisplayLink *fpsDisplayLink;
@property (nonatomic, assign) CFTimeInterval lastFpsTimestamp;
@property (nonatomic, assign) NSInteger fpsFrameCount;
@end

@implementation _0xDEADBEEE

- (UIColor *)accentColor { return [UIColor colorWithRed:0.96 green:0.20 blue:0.26 alpha:1.0]; }
- (UIColor *)cardBgColor { return [UIColor colorWithWhite:0.08 alpha:0.96]; }
- (UIColor *)textColor { return [UIColor whiteColor]; }
- (UIColor *)mutedColor { return [UIColor colorWithWhite:0.55 alpha:1.0]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    MizzePrepareMenuPrefs();
    self.view.backgroundColor = UIColor.clearColor;
    self.pointer = -1;
    self.controls = [NSMutableArray array];
    self.page = 0;
    
    // Nền mờ kính tối
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.blurView.layer.cornerRadius = 18;
    self.blurView.clipsToBounds = YES;
    [self.view addSubview:self.blurView];
    
    // Bảng chính
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.09 alpha:0.95];
    self.panel.layer.cornerRadius = 18;
    self.panel.layer.borderWidth = 0.8;
    self.panel.layer.borderColor = [UIColor colorWithWhite:0.20 alpha:0.45].CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];
    
    [self setupHeaderInView];
    [self setupNavButtonsInView];
    
    // Vùng cuộn nội dung
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = YES;
    self.scroll.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.scroll.alwaysBounceVertical = YES;
    [self.panel addSubview:self.scroll];
    
    // FPS Monitor
    [self setupFpsMonitor];
    
    // Spin Timer
    __weak _0xDEADBEEE *weakSelf = self;
    self.spinStatusTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer *timer){
        _0xDEADBEEE *owner = weakSelf;
        if (owner.isViewLoaded && owner.view.window && !owner.view.hidden && owner.spinStatusLabel) {
            [owner updateSpinStatus];
        }
    }];
}

- (void)setupFpsMonitor {
    self.fpsFrameCount = 0;
    self.lastFpsTimestamp = 0;
    self.fpsDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onFpsTick:)];
    [self.fpsDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)onFpsTick:(CADisplayLink *)link {
    if (self.lastFpsTimestamp == 0) {
        self.lastFpsTimestamp = link.timestamp;
        return;
    }
    self.fpsFrameCount++;
    CFTimeInterval delta = link.timestamp - self.lastFpsTimestamp;
    if (delta >= 0.5) {
        NSInteger fps = (NSInteger)round(self.fpsFrameCount / delta);
        if (self.fpsLabel) {
            self.fpsLabel.text = [NSString stringWithFormat:@"%ld FPS", (long)fps];
        }
        self.fpsFrameCount = 0;
        self.lastFpsTimestamp = link.timestamp;
    }
}

- (void)setupHeaderInView {
    self.header = [[UIView alloc] initWithFrame:CGRectZero];
    self.header.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.11 alpha:0.98];
    [self.panel addSubview:self.header];
    
    // Avatar / Logo ZEV với viền đỏ
    UIView *logoBadge = [[UIView alloc] initWithFrame:CGRectMake(14, 9, 36, 36)];
    logoBadge.layer.cornerRadius = 9;
    logoBadge.backgroundColor = [self accentColor];
    logoBadge.layer.shadowColor = [self accentColor].CGColor;
    logoBadge.layer.shadowOffset = CGSizeZero;
    logoBadge.layer.shadowOpacity = 0.75;
    logoBadge.layer.shadowRadius = 4.0;
    
    UIImageView *logoImg = [[UIImageView alloc] initWithFrame:CGRectMake(3, 3, 30, 30)];
    logoImg.image = FloatButtonIcon();
    logoImg.contentMode = UIViewContentModeScaleAspectFit;
    [logoBadge addSubview:logoImg];
    logoBadge.tag = 13;
    [self.header addSubview:logoBadge];
    
    // Tên thương hiệu
    UILabel *brand = [[UILabel alloc] initWithFrame:CGRectMake(58, 8, 200, 20)];
    brand.text = @"ZEV VIP x FreeFire";
    brand.font = MizzeFont(15, UIFontWeightBold);
    brand.textColor = [UIColor whiteColor];
    brand.tag = 10;
    [self.header addSubview:brand];
    
    // Phụ đề
    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(58, 28, 200, 14)];
    caption.text = @"Telegram: @vassco911";
    caption.font = MizzeFont(10, UIFontWeightMedium);
    caption.textColor = [self mutedColor];
    caption.tag = 11;
    [self.header addSubview:caption];
    
    // LIVE Badge
    UIView *liveBadge = [[UIView alloc] initWithFrame:CGRectMake(260, 16, 50, 20)];
    liveBadge.backgroundColor = [[self accentColor] colorWithAlphaComponent:0.16];
    liveBadge.layer.cornerRadius = 10;
    liveBadge.layer.borderWidth = 0.5;
    liveBadge.layer.borderColor = [[self accentColor] colorWithAlphaComponent:0.45].CGColor;
    liveBadge.tag = 14;
    
    UILabel *liveLbl = [[UILabel alloc] initWithFrame:liveBadge.bounds];
    liveLbl.text = @"• LIVE";
    liveLbl.font = MizzeFont(9.5, UIFontWeightBold);
    liveLbl.textColor = [self accentColor];
    liveLbl.textAlignment = NSTextAlignmentCenter;
    [liveBadge addSubview:liveLbl];
    [self.header addSubview:liveBadge];
    
    // FPS Label
    self.fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(316, 16, 48, 20)];
    self.fpsLabel.text = @"60 FPS";
    self.fpsLabel.font = MizzeFont(11, UIFontWeightBold);
    self.fpsLabel.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    self.fpsLabel.textAlignment = NSTextAlignmentCenter;
    self.fpsLabel.tag = 15;
    [self.header addSubview:self.fpsLabel];
    
    // Nút đóng (Close Button X)
    UIButton *close = [UIButton buttonWithType:UIButtonTypeCustom];
    close.frame = CGRectMake(370, 13, 28, 28);
    close.tag = 12;
    close.layer.cornerRadius = 14;
    close.backgroundColor = [UIColor colorWithWhite:0.18 alpha:0.65];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:[UIColor colorWithWhite:0.85 alpha:1.0] forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.header addSubview:close];
    
    // Cử chỉ kéo Header để di chuyển Menu
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragHeader:)];
    pan.delegate = self;
    [self.header addGestureRecognizer:pan];
}

- (void)setupNavButtonsInView {
    NSArray *names = @[@"NGẮM", @"ESP", @"KHÁC", @"CÀI ĐẶT", @"INFO"];
    NSMutableArray *buttons = [NSMutableArray array];
    for (NSInteger i = 0; i < names.count; ++i) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 200 + i;
        [btn setTitle:names[i] forState:UIControlStateNormal];
        btn.titleLabel.font = MizzeFont(12.5, UIFontWeightBold);
        [btn setTitleColor:[UIColor colorWithWhite:0.50 alpha:1.0] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
        [self.panel addSubview:btn];
        [buttons addObject:btn];
    }
    self.navButtons = buttons;
    
    // Thanh đỏ chỉ báo Tab đang chọn (Red underline indicator)
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectZero];
    self.tabIndicator.backgroundColor = [self accentColor];
    self.tabIndicator.layer.cornerRadius = 1.25;
    [self.panel addSubview:self.tabIndicator];
    
    UIView *navSep = [[UIView alloc] initWithFrame:CGRectMake(0, 92, 520, 0.5)];
    navSep.backgroundColor = [UIColor colorWithWhite:0.16 alpha:0.4];
    navSep.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navSep.tag = 99;
    [self.panel addSubview:navSep];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGSize sz = self.view.bounds.size;
    CGFloat screenW = sz.width, screenH = sz.height;
    CGFloat w = MIN(510.0f, screenW - 24.0f);
    CGFloat h = MIN(320.0f, screenH - 24.0f);
    
    CGRect f = self.panel.frame;
    if (f.size.width != w || f.size.height != h) {
        f.size = CGSizeMake(w, h);
        if (f.origin.x <= 0) f.origin.x = MAX(12.0f, (screenW - w) / 2.0f);
        if (f.origin.y <= 0) f.origin.y = MAX(12.0f, (screenH - h) / 2.0f);
    }
    f.origin.x = MAX(10.0f, MIN(f.origin.x, screenW - w - 10.0f));
    f.origin.y = MAX(10.0f, MIN(f.origin.y, screenH - h - 10.0f));
    self.panel.frame = f;
    self.blurView.frame = f;
    
    // Header
    self.header.frame = CGRectMake(0, 0, w, 54);
    UIView *liveBadge = [self.header viewWithTag:14];
    UIView *fpsLbl = [self.header viewWithTag:15];
    UIView *closeBtn = [self.header viewWithTag:12];
    if (closeBtn) closeBtn.frame = CGRectMake(w - 38, 13, 28, 28);
    if (fpsLbl) fpsLbl.frame = CGRectMake(w - 90, 17, 48, 20);
    if (liveBadge) liveBadge.frame = CGRectMake(w - 146, 17, 50, 20);
    
    // Nav buttons
    CGFloat navY = 54.0f;
    CGFloat navH = 38.0f;
    CGFloat count = (CGFloat)self.navButtons.count;
    CGFloat tabW = w / count;
    for (NSInteger i = 0; i < self.navButtons.count; ++i) {
        self.navButtons[i].frame = CGRectMake(i * tabW, navY, tabW, navH);
    }
    
    // Indicator
    if (self.page >= 0 && self.page < (NSInteger)self.navButtons.count) {
        UIButton *curBtn = self.navButtons[self.page];
        CGFloat indW = MIN(46.0f, tabW - 14.0f);
        CGFloat indX = curBtn.frame.origin.x + (tabW - indW) / 2.0f;
        self.tabIndicator.frame = CGRectMake(indX, navY + navH - 2.5f, indW, 2.5f);
    }
    
    UIView *navSep = [self.panel viewWithTag:99];
    if (navSep) navSep.frame = CGRectMake(0, navY + navH, w, 0.5f);
    
    // Scroll view
    CGFloat scrollY = navY + navH + 6.0f;
    self.scroll.frame = CGRectMake(12, scrollY, w - 24, h - scrollY - 8.0f);
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
}

- (void)closeMenu {
    if (self.fpsDisplayLink) {
        [self.fpsDisplayLink invalidate];
        self.fpsDisplayLink = nil;
    }
    if (self.onCloseBlock) self.onCloseBlock();
}

- (void)changePage:(UIButton *)sender {
    NSInteger targetPage = sender.tag - 200;
    if (self.page == targetPage) return;
    self.page = targetPage;
    self.scroll.contentOffset = CGPointZero;
    
    // Cập nhật vị trí thanh đỏ chỉ báo
    CGFloat tabW = self.panel.bounds.size.width / (CGFloat)self.navButtons.count;
    CGFloat indW = MIN(46.0f, tabW - 14.0f);
    CGFloat indX = sender.frame.origin.x + (tabW - indW) / 2.0f;
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.tabIndicator.frame = CGRectMake(indX, 54 + 38 - 2.5f, indW, 2.5f);
    } completion:nil];
    
    [self rebuildAnimated];
}

- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.2
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    for (UIView *view = touch.view; view && view != gesture.view; view = view.superview)
        if ([view isKindOfClass:UIControl.class]) return NO;
    return YES;
}

- (void)dragHeader:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) self.panelOrigin = self.panel.frame.origin;
    CGPoint delta = [pan translationInView:self.view];
    CGRect frame = self.panel.frame;
    frame.origin = CGPointMake(self.panelOrigin.x + delta.x, self.panelOrigin.y + delta.y);
    self.panel.frame = frame;
    self.blurView.frame = frame;
    [self viewDidLayoutSubviews];
}

- (CGFloat)contentWidth { return self.scroll.bounds.size.width > 10 ? self.scroll.bounds.size.width : 360; }

- (NSString *)colorPrefix {
    NSArray *prefixes = @[@"BoxColor", @"FovColor"];
    NSInteger idx = MAX(0, MIN((NSInteger)prefixes.count - 1, self.colorTarget));
    return prefixes[idx];
}

- (UILabel *)label:(NSString *)text frame:(CGRect)frame size:(CGFloat)size {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = [self textColor];
    label.font = MizzeFont(size, UIFontWeightMedium);
    return label;
}

// ==========================================
// THÀNH PHẦN GIAO DIỆN DẠNG CARD CHUYÊN NGHIỆP
// ==========================================

// Card Toggle (Hàng bật/tắt có tiêu đề và mô tả)
- (CGFloat)cardToggle:(NSString *)title desc:(NSString *)desc key:(NSString *)key fallback:(BOOL)fallback y:(CGFloat)y {
    CGFloat width = [self contentWidth];
    CGFloat rowH = desc.length > 0 ? 58.0f : 48.0f;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, rowH)];
    card.backgroundColor = [self cardBgColor];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.6;
    card.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:0.35].CGColor;
    card.clipsToBounds = YES;
    
    if (desc.length > 0) {
        UILabel *titleLabel = [self label:title frame:CGRectMake(16, 9, width - 78, 20) size:14.0];
        titleLabel.font = MizzeFont(14.0, UIFontWeightBold);
        titleLabel.textColor = [UIColor whiteColor];
        [card addSubview:titleLabel];
        
        UILabel *descLabel = [self label:desc frame:CGRectMake(16, 31, width - 78, 16) size:11.0];
        descLabel.font = MizzeFont(11.0, UIFontWeightRegular);
        descLabel.textColor = [self mutedColor];
        [card addSubview:descLabel];
    } else {
        UILabel *titleLabel = [self label:title frame:CGRectMake(16, 0, width - 78, rowH) size:14.0];
        titleLabel.font = MizzeFont(14.0, UIFontWeightBold);
        titleLabel.textColor = [UIColor whiteColor];
        [card addSubview:titleLabel];
    }
    
    CGFloat swW = 46.0f, swH = 26.0f;
    MizzeCheckBox *sw = [[MizzeCheckBox alloc] initWithFrame:CGRectMake(width - swW - 14, (rowH - swH) / 2.0, swW, swH)];
    sw.accessibilityLabel = title;
    sw.on = ESPPrefsBool(key, fallback);
    objc_setAssociatedObject(sw, "key", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [sw addTarget:self action:@selector(checkboxPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleRow:)];
    tap.delegate = self;
    objc_setAssociatedObject(tap, "switch", sw, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [card addGestureRecognizer:tap];
    
    [card addSubview:sw];
    [self.controls addObject:sw];
    [self.scroll addSubview:card];
    return y + rowH + 8;
}

- (void)toggleRow:(UITapGestureRecognizer *)tap {
    MizzeCheckBox *sw = objc_getAssociatedObject(tap, "switch");
    if (sw.enabled) [sw sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (void)checkboxPressed:(MizzeCheckBox *)sender {
    NSString *key = objc_getAssociatedObject(sender, "key");
    NSNumber *choice = objc_getAssociatedObject(sender, "choice");
    if (choice) {
        if ([key isEqualToString:@"AimType"]) {
            self.aimExpanded = NO;
            if ((int)AimModePolicy::ReadType(ESPPrefsFloat(key, 0)) == choice.intValue) {
                [self rebuildAnimated]; return;
            }
            ESPPrefsSetFloat(key, choice.floatValue);
            ESPPrefsSetFloat(@"AimActivation", static_cast<int>(AimModePolicy::AfterTypeSelection(
                AimModePolicy::ReadType(choice.floatValue))));
            ESPPrefsSetBool(@"SilentAim", NO);
        } else {
            ESPPrefsSetFloat(key, sender.on ? 0 : choice.floatValue);
            const NSInteger active = static_cast<int>(AimModePolicy::ReadActivation(ESPPrefsFloat(key, 0)));
            for (UIControl *control in self.controls) {
                if (![control isKindOfClass:MizzeCheckBox.class] ||
                    ![objc_getAssociatedObject(control, "key") isEqualToString:key]) continue;
                NSNumber *value = objc_getAssociatedObject(control, "choice");
                [(MizzeCheckBox *)control setOn:value.integerValue == active animated:YES];
            }
            ESPClearAimLock(); ESPSyncFromPrefs(); return;
        }
        ESPClearAimLock(); ESPSyncFromPrefs(); [self rebuildAnimated];
        return;
    }
    [sender setOn:!sender.on animated:YES];
    [self toggleChanged:sender];
}

// Card Slider (Thanh trượt kèm hiển thị giá trị thời gian thực)
- (CGFloat)cardSlider:(NSString *)title desc:(NSString *)desc key:(NSString *)key min:(float)minimum max:(float)maximum fallback:(float)fallback unit:(NSString *)unit y:(CGFloat)y {
    CGFloat width = [self contentWidth];
    CGFloat rowH = 74.0f;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, rowH)];
    card.backgroundColor = [self cardBgColor];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.6;
    card.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:0.35].CGColor;
    card.clipsToBounds = YES;
    
    UILabel *titleLabel = [self label:title frame:CGRectMake(16, 10, width - 110, 20) size:14.0];
    titleLabel.font = MizzeFont(14.0, UIFontWeightBold);
    titleLabel.textColor = [UIColor whiteColor];
    [card addSubview:titleLabel];
    
    UILabel *valLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 96, 10, 80, 20)];
    valLabel.textAlignment = NSTextAlignmentRight;
    valLabel.font = MizzeFont(13.0, UIFontWeightBold);
    valLabel.textColor = [self accentColor];
    [card addSubview:valLabel];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(14, 36, width - 28, 28)];
    slider.minimumValue = minimum;
    slider.maximumValue = maximum;
    slider.value = ESPPrefsFloat(key, fallback);
    slider.minimumTrackTintColor = [self accentColor];
    slider.maximumTrackTintColor = [UIColor colorWithWhite:0.22 alpha:1.0];
    slider.thumbTintColor = [UIColor whiteColor];
    
    objc_setAssociatedObject(slider, "key", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(slider, "valLabel", valLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(slider, "unit", unit ?: @"", OBJC_ASSOCIATION_COPY_NONATOMIC);
    [slider addTarget:self action:@selector(sliderCardChanged:) forControlEvents:UIControlEventValueChanged];
    [slider addTarget:self action:@selector(fovSliderTouchUp:)
        forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
    
    float val = slider.value;
    valLabel.text = [NSString stringWithFormat:@"%.0f%@", val, unit ?: @""];
    
    [card addSubview:slider];
    [self.controls addObject:slider];
    [self.scroll addSubview:card];
    return y + rowH + 8;
}

- (void)sliderCardChanged:(UISlider *)slider {
    NSString *key = objc_getAssociatedObject(slider, "key");
    UILabel *valLabel = objc_getAssociatedObject(slider, "valLabel");
    NSString *unit = objc_getAssociatedObject(slider, "unit");
    float val = slider.value;
    if (valLabel) {
        valLabel.text = [NSString stringWithFormat:@"%.0f%@", val, unit ?: @""];
    }
    ESPPrefsSetFloat(key, val);
    ESPSyncFromPrefs();
}

// Card Thông tin hiển thị 2 cột (Title bên trái, Value bên phải)
- (CGFloat)cardInfo:(NSString *)title value:(NSString *)value y:(CGFloat)y {
    CGFloat width = [self contentWidth];
    CGFloat rowH = 48.0f;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, rowH)];
    card.backgroundColor = [self cardBgColor];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.6;
    card.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:0.35].CGColor;
    card.clipsToBounds = YES;
    
    UILabel *titleLabel = [self label:title frame:CGRectMake(16, 0, width / 2.0 - 16, rowH) size:13.5];
    titleLabel.textColor = [self mutedColor];
    titleLabel.font = MizzeFont(13.5, UIFontWeightMedium);
    [card addSubview:titleLabel];
    
    UILabel *valLabel = [[UILabel alloc] initWithFrame:CGRectMake(width / 2.0, 0, width / 2.0 - 16, rowH)];
    valLabel.text = value;
    valLabel.textAlignment = NSTextAlignmentRight;
    valLabel.textColor = [UIColor whiteColor];
    valLabel.font = MizzeFont(13.5, UIFontWeightBold);
    [card addSubview:valLabel];
    
    [self.scroll addSubview:card];
    return y + rowH + 8;
}

- (CGFloat)sectionHeader:(NSString *)title y:(CGFloat)y {
    UILabel *label = [self label:title frame:CGRectMake(6, y + 4, [self contentWidth] - 12, 18) size:11.5];
    label.textColor = [self accentColor];
    label.font = MizzeFont(11.5, UIFontWeightBold);
    label.text = [title uppercaseString];
    [self.scroll addSubview:label];
    return y + 26;
}

// Card Lựa chọn phân đoạn (Segmented Control)
- (CGFloat)cardSegment:(NSString *)title desc:(NSString *)desc items:(NSArray<NSString *> *)items selected:(NSInteger)selected action:(SEL)action tag:(NSInteger)tag y:(CGFloat)y {
    CGFloat width = [self contentWidth];
    CGFloat rowH = 82.0f;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, y, width, rowH)];
    card.backgroundColor = [self cardBgColor];
    card.layer.cornerRadius = 12;
    card.layer.borderWidth = 0.6;
    card.layer.borderColor = [UIColor colorWithWhite:0.18 alpha:0.35].CGColor;
    card.clipsToBounds = YES;
    
    UILabel *titleLabel = [self label:title frame:CGRectMake(16, 8, width - 32, 18) size:13.5];
    titleLabel.font = MizzeFont(13.5, UIFontWeightBold);
    titleLabel.textColor = [UIColor whiteColor];
    [card addSubview:titleLabel];
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
    seg.frame = CGRectMake(14, 34, width - 28, 36);
    seg.tag = tag;
    seg.selectedSegmentIndex = selected;
    seg.backgroundColor = [UIColor colorWithWhite:0.14 alpha:1.0];
    seg.selectedSegmentTintColor = [self accentColor];
    [seg setTitleTextAttributes:@{NSFontAttributeName: MizzeFont(12.5, UIFontWeightBold),
                                  NSForegroundColorAttributeName: [UIColor colorWithWhite:0.65 alpha:1.0]} forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSFontAttributeName: MizzeFont(12.5, UIFontWeightBold),
                                  NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [seg addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    
    [card addSubview:seg];
    [self.controls addObject:seg];
    [self.scroll addSubview:card];
    return y + rowH + 8;
}

// ==========================================
// DỰNG GIAO DIỆN CỦA TỪNG TAB
// ==========================================
- (void)buildPage {
    self.builtWidth = self.scroll.bounds.size.width;
    CGFloat offset = self.scroll.contentOffset.y;
    for (UIView *view in self.scroll.subviews) [view removeFromSuperview];
    [self.controls removeAllObjects];
    self.activeControl = nil;
    
    // Cập nhật màu nút điều hướng
    for (NSInteger i = 0; i < self.navButtons.count; ++i) {
        UIButton *button = self.navButtons[i];
        if (i == self.page) {
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [button setTitleColor:[UIColor colorWithWhite:0.50 alpha:1.0] forState:UIControlStateNormal];
        }
    }
    
    CGFloat y = 4;
    
    // ============================================================
    // TAB 0: NGẮM (AIM / COMBAT)
    // ============================================================
    if (self.page == 0) {
        const NSInteger currentAimType = static_cast<int>(AimModePolicy::ReadType(ESPPrefsFloat(@"AimType", 0)));
        y = [self cardSegment:@"Chế độ ngắm bắn" desc:@"Chọn cơ chế tự động khóa mục tiêu"
                        items:@[@"Tắt", @"Chạm", @"Ống ngắm", @"Silent"]
                     selected:currentAimType
                       action:@selector(aimModeChanged:)
                          tag:1001 y:y];
        
        y = [self cardToggle:@"Bật Silent Aim" desc:@"Tự động găm đạn vào mục tiêu khi bắn" key:@"SilentAim" fallback:NO y:y];
        y = [self cardToggle:@"AimKill Tự động bắn" desc:@"Tự động kích hoạt nhả đạn khi khóa được địch" key:@"AutoFireFloating" fallback:NO y:y];
        y = [self cardSlider:@"Tỷ lệ trúng đầu (Headshot)" desc:@"Ưu tiên khóa vào vùng đầu" key:@"SilentHeadPercent" min:0 max:100 fallback:75 unit:@"%" y:y];
        y = [self cardSlider:@"Kích thước vòng FOV" desc:@"Phạm vi quét và khóa mục tiêu" key:@"FovSize" min:5 max:50 fallback:30 unit:@"°" y:y];
        y = [self cardToggle:@"Hiện vòng tròn FOV" desc:@"Hiển thị phạm vi ngắm trên màn hình" key:@"ShowFov" fallback:YES y:y];
        y = [self cardToggle:@"Aimlag khi ngắm" desc:@"Khóa tâm tức thì vào đầu khi bật ngắm" key:@"AimLag" fallback:NO y:y];
        y = [self cardToggle:@"Dây tới mục tiêu" desc:@"Vẽ đường chỉ dẫn tới kẻ địch gần nhất" key:@"AimTargetLine" fallback:YES y:y];
        y = [self cardToggle:@"Bắn siêu nhanh (2×)" desc:@"Tăng tốc độ nhả đạn của súng" key:@"FastFire" fallback:NO y:y];
        y = [self cardToggle:@"Không nạp đạn" desc:@"Bắn liên tục không cần chờ thay băng đạn" key:@"ShootNoReload" fallback:NO y:y];
        y = [self cardSlider:@"Tầm chọn Silent" desc:@"Khoảng cách hiệu quả của Silent Aim" key:@"SilentMaxDistance" min:10 max:150 fallback:100 unit:@"m" y:y];
    }
    
    // ============================================================
    // TAB 1: ESP (VISUALS / ĐỊNH VỊ)
    // ============================================================
    else if (self.page == 1) {
        y = [self cardToggle:@"Bật ESP" desc:@"Kích hoạt toàn bộ hệ thống định vị mục tiêu" key:@"ESPEnabled" fallback:YES y:y];
        
        NSInteger boxStyle = ESPPrefsBool(@"Box3D", NO) ? 1 : 0;
        y = [self cardSegment:@"Kiểu khung người chơi" desc:@"Chọn định dạng hiển thị khung"
                        items:@[@"2D Góc mảnh", @"Hộp 3D"]
                     selected:boxStyle
                       action:@selector(boxStyleChanged:)
                          tag:1002 y:y];
        
        y = [self cardToggle:@"Khung người chơi" desc:@"Vẽ khung bao quanh toàn thân kẻ địch" key:@"Box" fallback:YES y:y];
        y = [self cardToggle:@"Xương người chơi" desc:@"Hiển thị khung xương theo cử động nhân vật" key:@"Skeleton" fallback:NO y:y];
        y = [self cardToggle:@"Tên người chơi" desc:@"Hiển thị nickname nhân vật hoặc bot" key:@"Name" fallback:YES y:y];
        y = [self cardToggle:@"Thanh máu" desc:@"Hiển thị lượng máu và giáp theo thời gian thực" key:@"Health" fallback:YES y:y];
        y = [self cardToggle:@"Điểm đánh dấu đầu" desc:@"Chấm đỏ chính xác tại vị trí đầu mục tiêu" key:@"HeadRedDot" fallback:NO y:y];
        y = [self cardToggle:@"Khoảng cách (m)" desc:@"Đo khoảng cách chính xác từ bạn tới kẻ địch" key:@"Dis" fallback:YES y:y];
        y = [self cardToggle:@"Trục XYZ chỉ hướng" desc:@"Vẽ tia chỉ hướng từ tâm tới mục tiêu" key:@"Line" fallback:NO y:y];
        y = [self cardSlider:@"Tầm hiển thị ESP" desc:@"Khoảng cách tối đa quét mục tiêu" key:@"ESPMaxDistance" min:50 max:500 fallback:150 unit:@"m" y:y];
        y = [self cardSlider:@"Cảnh báo máu Vàng ≤" desc:@"Đổi màu khung khi máu địch xuống mức vàng" key:@"HealthYellowPercent" min:10 max:90 fallback:50 unit:@"%" y:y];
        y = [self cardSlider:@"Cảnh báo máu Đỏ ≤" desc:@"Đổi màu khung khi máu địch xuống mức đỏ" key:@"HealthRedPercent" min:5 max:80 fallback:25 unit:@"%" y:y];
    }
    
    // ============================================================
    // TAB 2: KHÁC (MISC / MOVEMENT)
    // ============================================================
    else if (self.page == 2) {
        y = [self sectionHeader:@"Tính năng di chuyển & bay" y:y];
        y = [self cardToggle:@"Tàng hình (Ghost Mode)" desc:@"Tàng hình di chuyển không bị phát hiện" key:@"GhostModeFloating" fallback:NO y:y];
        y = [self cardToggle:@"Fake Lag" desc:@"Tạo độ trễ ảo khiến địch không thể bắn trúng" key:@"FakeLagFloating" fallback:NO y:y];
        y = [self cardToggle:@"Bay (Fly Mode)" desc:@"Bay lên không trung quan sát toàn trận đấu" key:@"FlyFloating" fallback:NO y:y];
        y = [self cardSlider:@"Độ cao Fly" desc:@"Độ cao nhân vật khi kích hoạt bay" key:@"FlyHeight" min:1 max:6 fallback:4 unit:@"m" y:y];
        y = [self cardToggle:@"Chạy nhanh (Speed)" desc:@"Tăng tốc độ di chuyển và chạy bo" key:@"RunSpeedFloating" fallback:NO y:y];
        
        y = [self sectionHeader:@"Hiệu ứng & Khác" y:y];
        y = [self cardToggle:@"Xoay Spin ảo 360°" desc:@"Xoay nhân vật cực nhanh (chỉ mình thấy)" key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin", NO)) {
            y = [self cardSlider:@"Tốc độ xoay Spin" desc:@"Tốc độ vòng quay trên giây" key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 unit:@" v/s" y:y];
        }
        y = [self cardToggle:@"Ẩn nút chức năng nổi" desc:@"Ẩn các phím tắt tính năng nổi trên màn hình" key:@"HideFeatureButtons" fallback:NO y:y];
    }
    
    // ============================================================
    // TAB 3: CÀI ĐẶT (SETTINGS / THEME)
    // ============================================================
    else if (self.page == 3) {
        y = [self sectionHeader:@"Bảo vệ & Tối ưu" y:y];
        y = [self cardToggle:@"Ẩn khi quay / chụp (Streamproof)" desc:@"Bảo vệ chống lộ cheat khi livestream hoặc ghi màn hình" key:@"AnLive" fallback:NO y:y];
        y = [self cardToggle:@"Tiết kiệm pin (30 FPS)" desc:@"Giảm tần số quét đồ họa giúp máy mát và tiết kiệm pin" key:@"BalancedRender" fallback:NO y:y];
        
        y = [self sectionHeader:@"Tùy chỉnh màu sắc RGB" y:y];
        y = [self cardSegment:@"Mục tiêu chỉnh màu" desc:@"Chọn đối tượng cần đổi màu"
                        items:@[@"Khung Box", @"Vòng FOV"]
                     selected:self.colorTarget
                       action:@selector(colorTargetChanged:)
                          tag:1003 y:y];
        
        // Bảng Swatch xem trước màu
        self.swatch = [self label:@"" frame:CGRectMake(0, y, [self contentWidth], 44) size:14];
        self.swatch.textAlignment = NSTextAlignmentCenter;
        self.swatch.layer.cornerRadius = 12;
        self.swatch.clipsToBounds = YES;
        self.swatch.font = MizzeFont(14, UIFontWeightBold);
        [self.scroll addSubview:self.swatch];
        y += 52;
        
        NSString *prefix = [self colorPrefix];
        float defaults[3] = {0.96f, 0.20f, 0.26f};
        NSArray *names = @[@"Kênh Đỏ (R)", @"Kênh Lục (G)", @"Kênh Lam (B)"];
        NSArray *suffixes = @[@"R", @"G", @"B"];
        for (int i = 0; i < 3; ++i) {
            y = [self cardSlider:names[i] desc:@"Cân chỉnh dải màu từ 0 đến 255"
                             key:[prefix stringByAppendingString:suffixes[i]]
                             min:0 max:1 fallback:defaults[i] unit:@"" y:y];
        }
        [self updateSwatch];
    }
    
    // ============================================================
    // TAB 4: INFO (THÔNG TIN / GIỚI THIỆU)
    // ============================================================
    else {
        y = [self sectionHeader:@"Thông tin hệ thống" y:y];
        y = [self cardInfo:@"Tên sản phẩm" value:@"ZEV VIP CHEAT" y:y];
        y = [self cardInfo:@"Phiên bản" value:@"1.0.0 (No-Key Edition)" y:y];
        y = [self cardInfo:@"Kiến trúc" value:@"ARM64 (In-Process Sandbox)" y:y];
        y = [self cardInfo:@"Hỗ trợ hệ điều hành" value:@"iOS 13.0 - iOS 18.x" y:y];
        y = [self cardInfo:@"Phương thức" value:@"mach_task_self (Jailed/JB)" y:y];
        y = [self cardInfo:@"Trạng thái hệ thống" value:@"ĐANG HOẠT ĐỘNG" y:y];
        
        y = [self sectionHeader:@"Hỗ trợ & Bản quyền" y:y];
        y = [self cardInfo:@"Đơn vị phát triển" value:@"ZEV IOS TEAM" y:y];
        y = [self cardInfo:@"Kênh Telegram" value:@"@vassco911" y:y];
    }
    
    self.scroll.contentSize = CGSizeMake([self contentWidth], y + 16);
    self.scroll.contentOffset = CGPointMake(0, MAX(0, MIN(offset, y + 16 - self.scroll.bounds.size.height)));
}

// ==========================================
// CÁC HÀM XỬ LÝ SỰ KIỆN TƯƠNG TÁC
// ==========================================
- (void)aimModeChanged:(UISegmentedControl *)sender {
    NSInteger choice = sender.selectedSegmentIndex;
    ESPPrefsSetFloat(@"AimType", (float)choice);
    ESPPrefsSetFloat(@"AimActivation", static_cast<int>(AimModePolicy::AfterTypeSelection(
        AimModePolicy::ReadType((float)choice))));
    if (choice != 3) {
        ESPPrefsSetBool(@"SilentAim", NO);
    } else {
        ESPPrefsSetBool(@"SilentAim", YES);
    }
    ESPClearAimLock();
    ESPSyncFromPrefs();
    [self rebuildAnimated];
}

- (void)boxStyleChanged:(UISegmentedControl *)sender {
    ESPPrefsSetBool(@"Box3D", sender.selectedSegmentIndex == 1);
    ESPPrefsSetBool(@"Box", YES);
    if (sender.selectedSegmentIndex == 1) {
        ESPPrefsSetBool(@"CleanESP", NO);
    }
    ESPSyncFromPrefs();
}

- (void)colorTargetChanged:(UISegmentedControl *)sender {
    self.colorTarget = sender.selectedSegmentIndex;
    [self rebuildAnimated];
}

- (void)updateSwatch {
    if (!self.swatch) return;
    NSString *prefix = [self colorPrefix];
    UIColor *col = [UIColor colorWithRed:ESPPrefsFloat([prefix stringByAppendingString:@"R"], 0.96f)
                                   green:ESPPrefsFloat([prefix stringByAppendingString:@"G"], 0.20f)
                                    blue:ESPPrefsFloat([prefix stringByAppendingString:@"B"], 0.26f)
                                   alpha:1.0f];
    self.swatch.backgroundColor = col;
    self.swatch.text = [self.colorPrefix isEqualToString:@"BoxColor"] ? @"MÀU KHUNG BOX" : @"MÀU VÒNG FOV";
    self.swatch.textColor = UIColor.whiteColor;
}

- (void)updateSpinStatus {
    if (!self.spinStatusLabel) return;
    self.spinStatusLabel.text = ESPPrefsBool(@"VisualSpin", NO) ? @"Trạng thái: Đang kích hoạt xoay" : @"Trạng thái: Đang tắt";
}

- (void)fovSliderTouchUp:(UISlider *)sender {
    NSString *key = objc_getAssociatedObject(sender, "key");
    if (![key isEqualToString:@"FovSize"] && ![key isEqualToString:@"SilentFovSize"]) return;
    BOOL orig = [objc_getAssociatedObject(sender, "origShowFov") boolValue];
    if (orig && !ESPPrefsBool(@"ShowFov", YES)) {
        ESPPrefsSetBool(@"ShowFov", YES);
    }
    objc_setAssociatedObject(sender, "origShowFov", nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSlider:(UISlider *)slider point:(CGPoint)point {
    CGPoint local = [slider convertPoint:point fromView:self.view];
    CGFloat width = slider.bounds.size.width;
    if (width <= 0) return;
    CGFloat ratio = MAX(0.0f, MIN(1.0f, local.x / width));
    slider.value = slider.minimumValue + ratio * (slider.maximumValue - slider.minimumValue);
    [slider sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)toggleChanged:(MizzeCheckBox *)sender {
    NSString *key = objc_getAssociatedObject(sender, "key");
    if ([@[@"GhostModeFloating", @"FakeLagFloating", @"AutoFireFloating", @"FlyFloating"] containsObject:key]) {
        NSString *feature = [key stringByReplacingOccurrencesOfString:@"Floating" withString:@""];
        ESPPrefsSetBool(feature, sender.on);
        if (sender.on) {
            ESPPrefsSetBool(@"HideFeatureButtons", NO);
        }
    }
    if ([key isEqualToString:@"CleanESP"] && sender.on) ESPPrefsSetBool(@"Box3D", NO);
    ESPPrefsSetBool(key, sender.on);
    ESPSyncFromPrefs();
}

// ==========================================
// ĐIỀU PHỐI TOUCH TỪ UNITY VÀO MENU
// ==========================================
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase == UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame, point)) return NO;
        if (self.pointer != -1) return YES;
        self.pointer = pointerId;
        self.began = point;
        self.panelOrigin = self.panel.frame.origin;
        self.scrollOrigin = self.scroll.contentOffset.y;
        self.scrolling = NO;
        self.activeControl = nil;
        
        CGPoint local = [self.panel convertPoint:point fromView:self.view];
        self.dragging = local.y < 54 && local.x < self.panel.bounds.size.width - 54;
        if (self.dragging) return YES;
        
        NSMutableArray *fixed = [NSMutableArray array];
        [fixed addObjectsFromArray:self.navButtons];
        UIView *closeBtn = [self.header viewWithTag:12];
        if ([closeBtn isKindOfClass:[UIControl class]]) [fixed addObject:closeBtn];
        for (UIControl *c in fixed) {
            if (CGRectContainsPoint(c.bounds, [c convertPoint:point fromView:self.view])) {
                self.activeControl = c;
            }
        }
        
        if (CGRectContainsPoint(self.scroll.bounds, [self.scroll convertPoint:point fromView:self.view])) {
            for (UIControl *c in self.controls) {
                if (!c.enabled) continue;
                CGRect hit = c.bounds;
                if ([c isKindOfClass:MizzeCheckBox.class]) {
                    hit = [c convertRect:c.superview.bounds fromView:c.superview];
                }
                if (CGRectContainsPoint(hit, [c convertPoint:point fromView:self.view])) {
                    self.activeControl = c;
                    break;
                }
            }
        }
        if ([self.activeControl isKindOfClass:UIButton.class]) ((UIButton *)self.activeControl).highlighted = YES;
        if ([self.activeControl isKindOfClass:UISlider.class]) [self setSlider:(UISlider *)self.activeControl point:point];
        return YES;
    }
    
    if (self.pointer != pointerId) return NO;
    CGFloat dx = point.x - self.began.x, dy = point.y - self.began.y;
    
    if (phase == UITouchPhaseMoved) {
        if (self.dragging) {
            CGRect f = self.panel.frame;
            f.origin = CGPointMake(self.panelOrigin.x + dx, self.panelOrigin.y + dy);
            self.panel.frame = f;
            self.blurView.frame = f;
            [self viewDidLayoutSubviews];
        } else if ([self.activeControl isKindOfClass:UISlider.class]) {
            [self setSlider:(UISlider *)self.activeControl point:point];
        } else if (fabs(dy) > 7 || self.scrolling) {
            self.scrolling = YES;
            if ([self.activeControl isKindOfClass:UIButton.class]) ((UIButton *)self.activeControl).highlighted = NO;
            CGFloat maxY = MAX(0, self.scroll.contentSize.height - self.scroll.bounds.size.height);
            self.scroll.contentOffset = CGPointMake(0, MAX(0, MIN(maxY, self.scrollOrigin - dy)));
        }
        return YES;
    }
    
    if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
        UIControl *control = self.activeControl;
        BOOL activate = phase == UITouchPhaseEnded && !self.dragging && !self.scrolling && fabs(dx) < 24 && fabs(dy) < 24;
        self.pointer = -1;
        self.activeControl = nil;
        if (activate && !control.enabled) activate = NO;
        if ([control isKindOfClass:UIButton.class]) ((UIButton *)control).highlighted = NO;
        
        if (activate && [control isKindOfClass:UISegmentedControl.class]) {
            UISegmentedControl *seg = (UISegmentedControl *)control;
            CGPoint p = [seg convertPoint:point fromView:self.view];
            seg.selectedSegmentIndex = MAX(0, MIN(seg.numberOfSegments - 1, (NSInteger)(p.x / (seg.bounds.size.width / seg.numberOfSegments))));
            [seg sendActionsForControlEvents:UIControlEventValueChanged];
        } else if (activate && [control isKindOfClass:UIButton.class]) {
            [control sendActionsForControlEvents:UIControlEventTouchUpInside];
        } else if (activate && [control isKindOfClass:UITextField.class]) {
            [control becomeFirstResponder];
        }
        if ([control isKindOfClass:UISlider.class]) [self fovSliderTouchUp:(UISlider *)control];
        return YES;
    }
    return NO;
}

@end
