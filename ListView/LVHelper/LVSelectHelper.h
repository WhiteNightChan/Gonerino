#import "ListViewController.h"

@interface ListViewController (LVSelectHelper)
- (NSInteger)currentSelectedCount;
- (void)clearEditingSelectionForSearchRefresh;
- (void)updateDeleteToolbarButtonEnabled;
- (void)updateSelectionToolbarButtonsForCurrentState;
- (void)selectAllToolbarButtonTapped;
@end
