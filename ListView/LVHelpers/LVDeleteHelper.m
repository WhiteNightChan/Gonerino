#import "LVDeleteHelper.h"
#import "LVPrivate.h"
#import "LVResolveHelper.h"
#import "LVSearchHelper.h"
#import "TextHelper.h"

@implementation ListViewController (LVDeleteHelper)

#pragma mark - Delete

- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self.tableView.indexPathsForSelectedRows copy];

    return selectedIndexPaths ?: @[];
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

- (void)deleteSelectedItemsTapped {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self selectedIndexPathsForDeleteAction];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSString *selectedText = nil;

    if (selectedIndexPaths.count == 1) {
        NSIndexPath *indexPath = selectedIndexPaths.firstObject;
        NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
        if ([entry[@"text"] isKindOfClass:[NSString class]]) {
            selectedText = entry[@"text"];
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

    NSArray<NSDictionary *> *resolvedEntries =
        [self resolvedEntriesForSelectedIndexPaths:selectedIndexPaths];

    NSMutableArray<NSString *> *selectedTexts = [NSMutableArray array];
    NSMutableArray<NSNumber *> *targetIndexes = [NSMutableArray array];

    for (NSDictionary *entry in resolvedEntries) {
        NSString *text = entry[@"text"];
        NSNumber *originalIndex = entry[@"originalIndex"];

        if (![text isKindOfClass:[NSString class]] ||
            ![originalIndex isKindOfClass:[NSNumber class]]) {
            continue;
        }

        [selectedTexts addObject:text];
        [targetIndexes addObject:originalIndex];
    }

    if (selectedTexts.count == 0 || targetIndexes.count == 0) {
        return;
    }

    if (self.removeSelectedItemsBlock) {
        self.removeSelectedItemsBlock([selectedTexts copy]);
    } else if (self.removeItemBlock) {
        for (NSString *text in selectedTexts) {
            self.removeItemBlock(text);
        }
    }

    NSArray<NSNumber *> *sortedTargetIndexes =
        [targetIndexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            if (obj1.integerValue > obj2.integerValue) return NSOrderedAscending;
            if (obj1.integerValue < obj2.integerValue) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    for (NSNumber *targetIndex in sortedTargetIndexes) {
        NSInteger row = [targetIndex integerValue];
        if (row >= 0 && row < self.items.count) {
            [self.items removeObjectAtIndex:row];
        }
    }

    [self reloadItemsFromSourceAndRefresh];
    [self setDeleteToolbarButtonEnabled:NO];
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
        NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
        NSString *item = entry[@"text"];
        NSNumber *originalIndex = entry[@"originalIndex"];

        if (![item isKindOfClass:[NSString class]] ||
            ![originalIndex isKindOfClass:[NSNumber class]]) {
            return;
        }

        NSInteger targetIndex = [originalIndex integerValue];

        if (self.removeItemBlock) {
            self.removeItemBlock(item);
        }

        [self.items removeObjectAtIndex:targetIndex];
        [self reloadItemsFromSourceAndRefresh];
    }
}

@end
