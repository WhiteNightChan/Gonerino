#import "ListViewController.h"

@interface ListViewController (LVSearchHelper)
- (void)applySearchStateForText:(NSString *)searchText;
- (void)rebuildFilteredItemsForCurrentSearchText;
- (void)reloadItemsFromSourceAndRefresh;
- (void)updateFilteredItemsForSearchText:(NSString *)searchText;
@end
