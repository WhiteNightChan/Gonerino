#import "LVControlHelper.h"
#import "LVPrivate.h"

@implementation ListViewController (LVControlHelper)

#pragma mark - Control

- (BOOL)shouldApplyInitialSearchBarOffset {
    if (self.hasAppliedInitialSearchBarOffset) {
        return NO;
    }

    if (self.tableView.tableHeaderView != self.searchBar) {
        return NO;
    }

    if (self.searchBar.text.length > 0 || self.isSearching) {
        return NO;
    }

    CGFloat searchBarHeight = CGRectGetHeight(self.searchBar.frame);
    if (searchBarHeight <= 0) {
        return NO;
    }

    return YES;
}

- (void)applyInitialSearchBarOffsetIfNeeded {
    if (![self shouldApplyInitialSearchBarOffset]) {
        return;
    }

    CGFloat searchBarHeight = CGRectGetHeight(self.searchBar.frame);

    CGPoint offset = self.tableView.contentOffset;
    offset.y = self.initialTableViewOffsetY + searchBarHeight;
    [self.tableView setContentOffset:offset animated:NO];

    self.hasAppliedInitialSearchBarOffset = YES;
}

- (void)updateInteractivePopGestureEnabled {
    UIGestureRecognizer *interactivePopGesture =
        self.navigationController.interactivePopGestureRecognizer;

    if (!interactivePopGesture) {
        return;
    }

    interactivePopGesture.enabled = !self.tableView.editing;
}

@end
