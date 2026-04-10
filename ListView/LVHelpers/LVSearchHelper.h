#import "ListViewController.h"

@interface ListViewController (LVSearchHelper)
- (void)applySearchStateForText:(NSString *)searchText;
- (void)rebuildFilteredItemsForCurrentSearchText;
@end
