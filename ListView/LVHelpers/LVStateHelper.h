#import "ListViewController.h"

@interface ListViewController (LVStateHelper)
- (BOOL)shouldApplyInitialSearchBarOffset;
- (void)applyInitialSearchBarOffsetIfNeeded;
- (void)updateInteractivePopGestureEnabled;
- (void)loadItemsFromSourceIfNeeded;
@end
