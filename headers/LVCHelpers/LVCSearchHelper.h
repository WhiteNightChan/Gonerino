#import "ListViewController.h"

@interface ListViewController (LVCSearchHelper)
- (void)applySearchStateForText:(NSString *)searchText;
- (void)rebuildFilteredItemsForCurrentSearchText;
- (void)reloadItemsFromSourceAndRefresh;
- (void)updateFilteredItemsForSearchText:(NSString *)searchText;
@end
