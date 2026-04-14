#import "LVSearchHelper.h"
#import "LVPrivate.h"
#import "LVControlHelper.h"
#import "LVResolveHelper.h"
#import "LVSelectHelper.h"

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
        NSString *text = [self resolvedTextForOriginalIndex:i];
        if (![text isKindOfClass:[NSString class]]) {
            continue;
        }

        if ([[text lowercaseString] containsString:lowercasedSearchText]) {
            [self.filteredItems addObject:@(i)];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self clearEditingSelectionForSearchRefresh];
    [self applySearchStateForText:searchText];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
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
    [self clearEditingSelectionForSearchRefresh];
    [self applySearchStateForText:@""];
    [self reloadListDataForCurrentState];
    [self refreshListUIForCurrentState];
}

@end
