#import "LVSearchHelper.h"
#import "LVPrivate.h"
#import "LVStateHelper.h"
#import "LVDeleteHelper.h"

@implementation ListViewController (LVSearchHelper)

#pragma mark - Search

- (void)applySearchStateForText:(NSString *)searchText {
    NSString *trimmedSearchText =
        [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    self.searchText = trimmedSearchText;
    self.isSearching = trimmedSearchText.length > 0;
}

- (void)rebuildFilteredItemsForCurrentSearchText {
    [self.filteredItems removeAllObjects];

    if (!self.isSearching) {
        return;
    }

    NSString *lowercasedSearchText = [self.searchText lowercaseString];

    for (NSInteger i = 0; i < self.items.count; i++) {
        NSString *text = self.items[i];
        if (![text isKindOfClass:[NSString class]]) {
            continue;
        }

        if ([[text lowercaseString] containsString:lowercasedSearchText]) {
            [self.filteredItems addObject:@{
                @"text": text,
                @"originalIndex": @(i)
            }];
        }
    }
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

    [self updateSelectionUIForCurrentState];
}

- (void)reloadItemsFromSourceAndRefresh {
    [self loadItemsFromSourceIfNeeded];
    [self clearEditingSelectionForSearchRefresh];

    if (self.isSearching) {
        [self rebuildFilteredItemsForCurrentSearchText];
        [self.tableView reloadData];
        [self updateDeleteToolbarButtonEnabled];
        [self updateEmptyStateIfNeeded];
        [self updateSelectionUIForCurrentState];
        return;
    }

    [self.tableView reloadData];
    [self updateDeleteToolbarButtonEnabled];
    [self updateEmptyStateIfNeeded];
    [self updateSelectionUIForCurrentState];
}

- (void)updateFilteredItemsForSearchText:(NSString *)searchText {
    [self clearEditingSelectionForSearchRefresh];
    [self applySearchStateForText:searchText];
    [self rebuildFilteredItemsForCurrentSearchText];
    [self.tableView reloadData];
    [self updateDeleteToolbarButtonEnabled];
    [self updateEmptyStateIfNeeded];
    [self updateSelectionUIForCurrentState];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self updateFilteredItemsForSearchText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
    [self updateFilteredItemsForSearchText:@""];
}

@end
