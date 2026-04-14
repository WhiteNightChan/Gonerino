#import "LVPresentHelper.h"
#import "LVPrivate.h"
#import "LVSetupHelper.h"
#import "LVSelectHelper.h"
#import "TextHelper.h"

@implementation ListViewController (LVPresentHelper)

#pragma mark - Present

- (BOOL)shouldShowSearchBar {
    if (self.isSearching) {
        return YES;
    }

    return self.items.count > 0;
}

- (UILabel *)emptyStateLabelWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = [UIColor secondaryLabelColor];
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    return label;
}

- (void)updateSearchBarVisibilityIfNeeded {
    BOOL shouldShowSearchBar = [self shouldShowSearchBar];

    if (shouldShowSearchBar) {
        if (self.searchBar.frame.size.height != 56.0) {
            self.searchBar.frame = CGRectMake(0, 0, 0, 56.0);
        }

        if (self.tableView.tableHeaderView != self.searchBar) {
            self.tableView.tableHeaderView = self.searchBar;
        }

        return;
    }

    if (self.searchBar.isFirstResponder) {
        [self.searchBar resignFirstResponder];
    }

    if (self.tableView.tableHeaderView != nil) {
        self.tableView.tableHeaderView = nil;
    }
}

- (NSInteger)currentVisibleItemCount {
    if (self.isSearching) {
        return self.filteredItems.count;
    }

    return self.items.count;
}

- (NSString *)currentCountDisplayText {
    NSInteger visibleCount = [self currentVisibleItemCount];
    NSInteger selectedCount = [self currentSelectedCount];

    if (self.tableView.editing) {
        return [NSString stringWithFormat:@"%ld/%ld",
                                          (long)selectedCount,
                                          (long)visibleCount];
    }

    return TextHelperCountDisplayText((NSUInteger)visibleCount);
}

- (void)updateRightBarButtonItemsForCurrentState {
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:self.tableView.editing
                           countDisplayText:[self currentCountDisplayText]];
}

- (UIBarButtonItem *)titleBarButtonItem {
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = self.titleText;
    titleLabel.textColor = [UIColor labelColor];
    titleLabel.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:20];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabel sizeToFit];

    CGFloat titleOffset = -4.0;

    UIView *container =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                 CGRectGetWidth(titleLabel.bounds) - titleOffset,
                                                 44.0)];
    container.userInteractionEnabled = NO;

    CGRect labelFrame = titleLabel.frame;
    labelFrame.origin.x = titleOffset;
    labelFrame.origin.y = floor((44.0 - CGRectGetHeight(labelFrame)) / 2.0);
    titleLabel.frame = labelFrame;

    [container addSubview:titleLabel];

    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)countDisplayBarButtonItemWithText:(NSString *)text {
    return [self textBarButtonItemWithTitle:text
                                  textColor:[UIColor labelColor]
                                 fontWeight:UIFontWeightMedium
                                     target:nil
                                     action:nil];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing {
    return [self rightBarButtonItemsForEditing:editing
                              countDisplayText:TextHelperCountDisplayText(0)];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText {
    UIBarButtonItem *rightSpace = [self fixedSpaceBarButtonItemWithWidth:12.5];
    UIBarButtonItem *editButton = [self editBarButtonItemForEditing:editing];
    UIBarButtonItem *countDisplayButton =
        [self countDisplayBarButtonItemWithText:countDisplayText];

    if (editing) {
        return @[rightSpace, editButton, countDisplayButton];
    }

    UIBarButtonItem *addButton = [self addBarButtonItem];

    return @[rightSpace, editButton, addButton, countDisplayButton];
}

@end
