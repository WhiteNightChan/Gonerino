#import "ListViewController.h"

@interface ListViewController (LVDeleteFlowHelper)
- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction;
- (void)deleteSelectedItemsTapped;
- (void)performDeleteSelectedItems;

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath;
@end
