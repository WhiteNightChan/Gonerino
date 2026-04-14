#import "LVDeleteFlowHelper.h"
#import "LVPrivate.h"
#import "LVResolveHelper.h"
#import "LVSelectHelper.h"
#import "TextHelper.h"

@implementation ListViewController (LVDeleteFlowHelper)

#pragma mark - Delete Flow

- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self.tableView.indexPathsForSelectedRows copy];

    return selectedIndexPaths ?: @[];
}

- (void)deleteSelectedItemsTapped {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self selectedIndexPathsForDeleteAction];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSString *selectedText = nil;

    if (selectedIndexPaths.count == 1) {
        NSIndexPath *indexPath = selectedIndexPaths.firstObject;
        NSString *resolvedText = [self resolvedTextForIndexPath:indexPath];
        if ([resolvedText isKindOfClass:[NSString class]]) {
            selectedText = resolvedText;
        }
    }

    NSString *title =
        TextHelperDeleteTitle(self.itemType, selectedIndexPaths.count);
    NSString *message =
        TextHelperDeleteMessage(self.itemType,
                                selectedIndexPaths.count,
                                selectedText);

    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:
        [UIAlertAction actionWithTitle:TextHelperDeleteActionTitle()
                                 style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *action) {
        [self performDeleteSelectedItems];
    }]];

    [alertController addAction:
        [UIAlertAction actionWithTitle:TextHelperCancelActionTitle()
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)performDeleteSelectedItems {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self selectedIndexPathsForDeleteAction];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSMutableArray<NSNumber *> *targetIndexes = [NSMutableArray array];

    for (NSIndexPath *indexPath in selectedIndexPaths) {
        NSInteger originalIndex = [self resolvedOriginalIndexForIndexPath:indexPath];
        if (originalIndex == NSNotFound) {
            continue;
        }

        [targetIndexes addObject:@(originalIndex)];
    }

    if (targetIndexes.count == 0) {
        return;
    }

    NSArray<NSNumber *> *sortedTargetIndexes =
        [targetIndexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            if (obj1.integerValue > obj2.integerValue) return NSOrderedAscending;
            if (obj1.integerValue < obj2.integerValue) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    if (self.removeItemsAtIndexesBlock) {
        self.removeItemsAtIndexesBlock([sortedTargetIndexes copy]);
    } else if (self.removeItemAtIndexBlock) {
        for (NSNumber *targetIndex in sortedTargetIndexes) {
            self.removeItemAtIndexBlock([targetIndex integerValue]);
        }
    }

    for (NSNumber *targetIndex in sortedTargetIndexes) {
        NSInteger row = [targetIndex integerValue];
        if (row >= 0 && row < self.items.count) {
            [self.items removeObjectAtIndex:row];
        }
    }

    [self loadItemsFromSourceIfNeeded];
    [self clearEditingSelectionForSearchRefresh];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        return UITableViewCellEditingStyleNone;
    }

    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger targetIndex = [self resolvedOriginalIndexForIndexPath:indexPath];
        if (targetIndex == NSNotFound) {
            return;
        }

        if (self.removeItemAtIndexBlock) {
            self.removeItemAtIndexBlock(targetIndex);
        }

        [self.items removeObjectAtIndex:targetIndex];

        [self loadItemsFromSourceIfNeeded];
        [self clearEditingSelectionForSearchRefresh];
        [self reloadListDataForCurrentState];
        [self refreshListUIForCurrentState];
    }
}

@end
