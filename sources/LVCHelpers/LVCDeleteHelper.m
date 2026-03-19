#import "LVCHelpers/LVCDeleteHelper.h"
#import "LVCHelpers/LVCResolveHelper.h"
#import "LVCHelpers/LVCSearchHelper.h"

@implementation ListViewController (LVCDeleteHelper)

#pragma mark - Delete

- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self.tableView.indexPathsForSelectedRows copy];

    return selectedIndexPaths ?: @[];
}

- (void)setDeleteToolbarButtonEnabled:(BOOL)enabled {
    if (self.toolbarItems.count < 2) {
        return;
    }

    UIBarButtonItem *deleteButton = self.toolbarItems[1];
    deleteButton.enabled = enabled;
}

- (void)updateDeleteToolbarButtonEnabled {
    [self setDeleteToolbarButtonEnabled:
        [self selectedIndexPathsForDeleteAction].count > 0];
}

- (void)deleteSelectedItemsTapped {
    NSArray<NSIndexPath *> *selectedIndexPaths =
        [self selectedIndexPathsForDeleteAction];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSString *type = self.itemType.length > 0 ? self.itemType : @"item";
    NSString *pluralType = [type stringByAppendingString:@"s"];

    NSString *title = nil;
    NSString *message = nil;

    if (selectedIndexPaths.count == 1) {
        NSIndexPath *indexPath = selectedIndexPaths.firstObject;
        NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
        NSString *selectedText = entry[@"text"];

        title = [NSString stringWithFormat:@"Delete %@",
                                           [type capitalizedString]];

        if (selectedText.length > 0) {
            message = [NSString stringWithFormat:@"Are you sure you want to delete \"%@\"?",
                                                     selectedText];
        } else {
            message = [NSString stringWithFormat:@"Are you sure you want to delete this %@?",
                                                     type];
        }
    } else {
        title = [NSString stringWithFormat:@"Delete %@",
                                           [pluralType capitalizedString]];

        message = [NSString stringWithFormat:@"Are you sure you want to delete %lu %@?",
                                                   (unsigned long)selectedIndexPaths.count,
                                                   pluralType];
    }

    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:
        [UIAlertAction actionWithTitle:@"Delete"
                                 style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction *action) {
        [self performDeleteSelectedItems];
    }]];

    [alertController addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
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
