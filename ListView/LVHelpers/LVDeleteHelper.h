#import "ListViewController.h"

@interface ListViewController (LVDeleteHelper)
- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction;
- (void)setDeleteToolbarButtonEnabled:(BOOL)enabled;
- (void)updateDeleteToolbarButtonEnabled;
- (void)updateSelectionToolbarButtonsForCurrentState;

- (void)selectAllToolbarButtonTapped;
- (void)deleteSelectedItemsTapped;
- (void)performDeleteSelectedItems;

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath;
@end
