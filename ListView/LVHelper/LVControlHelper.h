#import "ListViewController.h"

@interface ListViewController (LVControlHelper)
- (BOOL)shouldApplyInitialSearchBarOffset;
- (void)applyInitialSearchBarOffsetIfNeeded;
- (void)updateInteractivePopGestureEnabled;
@end
