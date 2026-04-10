#import "LVSelectHelper.h"
#import "LVPrivate.h"
#import "LVDeleteFlowHelper.h"
#import "TextHelper.h"

@implementation ListViewController (LVSelectHelper)

#pragma mark - Select

- (NSInteger)currentSelectedCount {
    if (!self.tableView.editing) {
        return 0;
    }

    return [self selectedIndexPathsForDeleteAction].count;
}

- (void)clearEditingSelectionForSearchRefresh {
    if (!self.tableView.editing) {
        return;
    }

    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self.tableView.indexPathsForSelectedRows copy];

    for (NSIndexPath *indexPath in selectedIndexPaths) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)setDeleteToolbarButtonEnabled:(BOOL)enabled {
    if (self.toolbarItems.count < 3) {
        return;
    }

    UIBarButtonItem *deleteButton = self.toolbarItems[2];
    deleteButton.enabled = enabled;
}

- (void)setSelectAllToolbarButtonEnabled:(BOOL)enabled {
    if (self.toolbarItems.count < 1) {
        return;
    }

    UIBarButtonItem *selectAllButton = self.toolbarItems[0];
    selectAllButton.enabled = enabled;
}

- (void)setSelectAllToolbarButtonTitle:(NSString *)title {
    if (self.toolbarItems.count < 1) {
        return;
    }

    UIBarButtonItem *selectAllButton = self.toolbarItems[0];
    selectAllButton.title = title;
}

- (NSInteger)selectableRowCountForSelectionActions {
    if (self.isSearching) {
        return self.filteredItems.count;
    }

    return self.items.count;
}

- (BOOL)areAllRowsSelectedForSelectionActions {
    NSInteger totalRowCount = [self selectableRowCountForSelectionActions];
    NSInteger selectedCount = [self selectedIndexPathsForDeleteAction].count;

    return totalRowCount > 0 && selectedCount == totalRowCount;
}

- (void)updateDeleteToolbarButtonEnabled {
    [self setDeleteToolbarButtonEnabled:
        [self selectedIndexPathsForDeleteAction].count > 0];
}

- (void)updateSelectAllToolbarButtonState {
    if (!self.tableView.editing) {
        [self setSelectAllToolbarButtonTitle:TextHelperSelectAllToolbarTitle(NO)];
        [self setSelectAllToolbarButtonEnabled:NO];
        return;
    }

    NSInteger totalRowCount = [self selectableRowCountForSelectionActions];
    if (totalRowCount == 0) {
        [self setSelectAllToolbarButtonTitle:TextHelperSelectAllToolbarTitle(NO)];
        [self setSelectAllToolbarButtonEnabled:NO];
        return;
    }

    [self setSelectAllToolbarButtonEnabled:YES];

    if ([self areAllRowsSelectedForSelectionActions]) {
        [self setSelectAllToolbarButtonTitle:TextHelperSelectAllToolbarTitle(YES)];
    } else {
        [self setSelectAllToolbarButtonTitle:TextHelperSelectAllToolbarTitle(NO)];
    }
}

- (void)updateSelectionToolbarButtonsForCurrentState {
    [self updateDeleteToolbarButtonEnabled];
    [self updateSelectAllToolbarButtonState];
}

- (void)selectAllToolbarButtonTapped {
    if (!self.tableView.editing) {
        return;
    }

    NSInteger totalRowCount = [self selectableRowCountForSelectionActions];
    if (totalRowCount == 0) {
        [self updateSelectionUIForCurrentState];
        return;
    }

    if ([self areAllRowsSelectedForSelectionActions]) {
        NSArray<NSIndexPath *> *selectedIndexPaths =
            [self selectedIndexPathsForDeleteAction];

        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    } else {
        for (NSInteger row = 0; row < totalRowCount; row++) {
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:row inSection:0];

            [self.tableView selectRowAtIndexPath:indexPath
                                        animated:NO
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    }

    [self updateSelectionUIForCurrentState];
}

@end
