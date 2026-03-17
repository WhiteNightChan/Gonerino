#import "ToastHelper.h"
#import <UIKit/UIKit.h>

@interface YTToastResponderEvent : NSObject
+ (instancetype)eventWithMessage:(NSString *)message firstResponder:(id)firstResponder;
- (void)send;
@end

void GonerinoShowToast(NSString *message) {
    Class toastClass = NSClassFromString(@"YTToastResponderEvent");
    if (!toastClass) return;

    UIViewController *topVC = [UIApplication sharedApplication].delegate.window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }

    id event = [(id)toastClass eventWithMessage:message firstResponder:topVC];
    [event send];
}
