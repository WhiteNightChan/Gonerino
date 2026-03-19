#import "ListViewController.h"

@interface ListViewController (LVCStateHelper)
- (BOOL)shouldApplyInitialSearchBarOffset;
- (void)applyInitialSearchBarOffsetIfNeeded;
- (void)updateInteractivePopGestureEnabled;
- (void)loadItemsFromSourceIfNeeded;
@end
