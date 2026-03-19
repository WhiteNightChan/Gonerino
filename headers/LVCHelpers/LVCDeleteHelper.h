#import "ListViewController.h"

@interface ListViewController (LVCDeleteHelper)
- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction;
- (void)setDeleteToolbarButtonEnabled:(BOOL)enabled;
- (void)updateDeleteToolbarButtonEnabled;

- (void)deleteSelectedItemsTapped;
- (void)performDeleteSelectedItems;

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath;
@end
