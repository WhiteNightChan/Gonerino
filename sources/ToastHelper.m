#import "ToastHelper.h"
#import <UIKit/UIKit.h>

@interface YTToastResponderEvent : NSObject
+ (instancetype)eventWithMessage:(NSString *)message firstResponder:(id)firstResponder;
- (void)send;
@end

static __weak UIView *gGonerinoCurrentToastView = nil;

static CGFloat const kGonerinoToastHorizontalPadding = 16.0;
static CGFloat const kGonerinoToastVerticalPadding = 10.0;
static CGFloat const kGonerinoToastHorizontalMargin = 16.0;
static CGFloat const kGonerinoToastBottomSpacing = 12.0;
static CGFloat const kGonerinoToastCornerRadius = 10.0;
static CGFloat const kGonerinoToastBorderWidth = 0.5;
static CGFloat const kGonerinoToastFontSize = 14.0;
static CGFloat const kGonerinoToastAnimationDuration = 0.2;
static CGFloat const kGonerinoToastVisibleDuration = 1.8;

static BOOL GonerinoUsesCustomToast(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:@"GonerinoUseCustomToast"] == nil) {
        return YES;
    }

    return [defaults boolForKey:@"GonerinoUseCustomToast"];
}

static UIWindow *GonerinoActiveWindow(void) {
    UIApplication *application = [UIApplication sharedApplication];

    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }

            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (windowScene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }

            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }

            for (UIWindow *window in windowScene.windows) {
                if (!window.hidden && window.alpha > 0.0) {
                    return window;
                }
            }
        }
    }

    UIWindow *delegateWindow = application.delegate.window;
    if (delegateWindow) {
        return delegateWindow;
    }

    return application.windows.firstObject;
}

static UIViewController *GonerinoVisibleViewControllerFrom(UIViewController *viewController) {
    if (!viewController) {
        return nil;
    }

    UIViewController *presentedViewController = viewController.presentedViewController;
    if (presentedViewController && !presentedViewController.isBeingDismissed) {
        return GonerinoVisibleViewControllerFrom(presentedViewController);
    }

    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        UIViewController *visibleViewController =
            navigationController.visibleViewController ?: navigationController.topViewController;

        if (visibleViewController) {
            return GonerinoVisibleViewControllerFrom(visibleViewController);
        }
    }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        UIViewController *selectedViewController = tabBarController.selectedViewController;

        if (selectedViewController) {
            return GonerinoVisibleViewControllerFrom(selectedViewController);
        }
    }

    return viewController;
}

static UIViewController *GonerinoTopViewControllerInWindow(UIWindow *window) {
    if (!window) {
        return nil;
    }

    return GonerinoVisibleViewControllerFrom(window.rootViewController);
}

static UIViewController *GonerinoNativeToastResponderInWindow(UIWindow *window) {
    if (!window) {
        return nil;
    }

    UIViewController *topViewController = window.rootViewController;

    while (topViewController.presentedViewController &&
           !topViewController.presentedViewController.isBeingDismissed) {
        topViewController = topViewController.presentedViewController;
    }

    return topViewController;
}

static UINavigationController *GonerinoOwningNavigationController(UIViewController *viewController) {
    UIViewController *current = viewController;

    while (current) {
        if ([current isKindOfClass:[UINavigationController class]]) {
            return (UINavigationController *)current;
        }

        if (current.navigationController) {
            return current.navigationController;
        }

        current = current.parentViewController;
    }

    return nil;
}

static CGFloat GonerinoVisibleToolbarHeight(UIViewController *viewController, UIWindow *window) {
    UINavigationController *navigationController =
        GonerinoOwningNavigationController(viewController);

    if (!navigationController || !window) {
        return 0.0;
    }

    if (navigationController.isToolbarHidden) {
        return 0.0;
    }

    UIToolbar *toolbar = navigationController.toolbar;
    if (!toolbar || toolbar.hidden || toolbar.alpha <= 0.01 || !toolbar.superview) {
        return 0.0;
    }

    CGRect toolbarFrameInWindow = [toolbar.superview convertRect:toolbar.frame
                                                          toView:window];

    if (CGRectIsEmpty(toolbarFrameInWindow)) {
        return 0.0;
    }

    if (CGRectGetHeight(toolbarFrameInWindow) <= 1.0) {
        return 0.0;
    }

    if (CGRectGetMaxY(toolbarFrameInWindow) <= 0.0) {
        return 0.0;
    }

    return CGRectGetHeight(toolbarFrameInWindow);
}

static void GonerinoShowCustomToast(NSString *message,
                                    UIViewController *topViewController,
                                    UIWindow *window) {
    if (!window || message.length == 0) {
        return;
    }

    [gGonerinoCurrentToastView removeFromSuperview];
    gGonerinoCurrentToastView = nil;

    CGFloat maxWidth = CGRectGetWidth(window.bounds) - kGonerinoToastHorizontalMargin * 2.0;

    UILabel *label = [UILabel new];
    label.text = message;
    label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.92];
    label.font = [UIFont systemFontOfSize:kGonerinoToastFontSize
                                   weight:UIFontWeightRegular];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;

    CGSize labelSize = [label sizeThatFits:CGSizeMake(maxWidth - kGonerinoToastHorizontalPadding * 2.0,
                                                      CGFLOAT_MAX)];

    CGFloat toastWidth =
        MIN(maxWidth, ceil(labelSize.width) + kGonerinoToastHorizontalPadding * 2.0);
    CGFloat toastHeight =
        ceil(labelSize.height) + kGonerinoToastVerticalPadding * 2.0;

    UIView *toastView =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, toastWidth, toastHeight)];
    toastView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.94];
    toastView.layer.cornerRadius = kGonerinoToastCornerRadius;
    toastView.layer.masksToBounds = YES;
    toastView.layer.borderWidth = kGonerinoToastBorderWidth;
    toastView.layer.borderColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.12].CGColor;
    toastView.alpha = 0.0;
    toastView.userInteractionEnabled = NO;

    label.frame = CGRectMake(kGonerinoToastHorizontalPadding,
                             kGonerinoToastVerticalPadding,
                             toastWidth - kGonerinoToastHorizontalPadding * 2.0,
                             toastHeight - kGonerinoToastVerticalPadding * 2.0);
    [toastView addSubview:label];

    CGFloat bottomInset = window.safeAreaInsets.bottom;
    CGFloat toolbarHeight = GonerinoVisibleToolbarHeight(topViewController, window);
    CGFloat bottomMargin = bottomInset + toolbarHeight + kGonerinoToastBottomSpacing;

    CGFloat x = floor((CGRectGetWidth(window.bounds) - toastWidth) / 2.0);
    CGFloat y = CGRectGetHeight(window.bounds) - bottomMargin - toastHeight;
    toastView.frame = CGRectMake(x, y, toastWidth, toastHeight);

    [window addSubview:toastView];
    gGonerinoCurrentToastView = toastView;

    [UIView animateWithDuration:kGonerinoToastAnimationDuration animations:^{
        toastView.alpha = 1.0;
    } completion:^(__unused BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(kGonerinoToastVisibleDuration * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:kGonerinoToastAnimationDuration animations:^{
                toastView.alpha = 0.0;
            } completion:^(__unused BOOL finished2) {
                if (gGonerinoCurrentToastView == toastView) {
                    gGonerinoCurrentToastView = nil;
                }

                [toastView removeFromSuperview];
            }];
        });
    }];
}

void GonerinoShowToast(NSString *message) {
    if (message.length == 0) {
        return;
    }

    UIWindow *window = GonerinoActiveWindow();
    if (!window) {
        return;
    }

    if (GonerinoUsesCustomToast()) {
        UIViewController *topViewController = GonerinoTopViewControllerInWindow(window);
        if (!topViewController) {
            return;
        }

        GonerinoShowCustomToast(message, topViewController, window);
        return;
    }

    Class toastClass = NSClassFromString(@"YTToastResponderEvent");
    if (!toastClass) {
        return;
    }

    UIViewController *nativeResponder = GonerinoNativeToastResponderInWindow(window);
    if (!nativeResponder) {
        return;
    }

    id event = [(id)toastClass eventWithMessage:message
                                 firstResponder:nativeResponder];
    [event send];
}
