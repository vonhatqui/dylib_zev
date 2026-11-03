#pragma once
#import <UIKit/UIKit.h>

static inline BOOL MizzeUsableGameWindow(UIWindow *window) {
    if (!window || window.hidden || window.alpha <= 0.01) return NO;
    if (CGRectIsEmpty(window.bounds) || window.bounds.size.width <= 10 || window.bounds.size.height <= 10) return NO;
    if (!window.rootViewController) return NO;
    return YES;
}

static inline UIWindow *MizzeFindGameWindow(UIApplication *app) {
    if (!app) return nil;
    UIWindow *fallback = nil;

    // 1. Kiểm tra connectedScenes trên iOS 13+
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *window in ws.windows) {
                if (!MizzeUsableGameWindow(window)) continue;
                if (window.isKeyWindow) return window;
                if (!fallback) fallback = window;
            }
        }
    }
    if (fallback) return fallback;

    // 2. Kiểm tra Delegate Window (UnityAppController thường lưu window ở đây)
    if (app.delegate && [app.delegate respondsToSelector:@selector(window)]) {
        UIWindow *delegateWindow = [app.delegate window];
        if (MizzeUsableGameWindow(delegateWindow)) {
            return delegateWindow;
        }
    }

    // 3. Fallback kiểm tra toàn bộ app.windows (hỗ trợ cả khi connectedScenes rỗng)
    for (UIWindow *window in app.windows) {
        if (!MizzeUsableGameWindow(window)) continue;
        if (window.isKeyWindow) return window;
        if (!fallback) fallback = window;
    }
    return fallback;
}
