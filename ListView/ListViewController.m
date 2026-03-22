#import "ListViewController.h"
#import "ToastHelper.h"
#import "LVTextCell.h"

#import "LVHelpers/LVPrivate.h"
#import "LVHelpers/LVResolveHelper.h"
#import "LVHelpers/LVDeleteHelper.h"
#import "LVHelpers/LVStateHelper.h"
#import "LVHelpers/LVSetupHelper.h"
#import "LVHelpers/LVInputHelper.h"

@interface ListViewController ()
- (void)handleItemSelectionAtIndex:(NSInteger)index;
- (BOOL)shouldShowSearchBar;
- (UILabel *)emptyStateLabelWithText:(NSString *)text;
- (void)updateSearchBarVisibilityIfNeeded;
- (void)updateEmptyStateIfNeeded;
- (NSInteger)currentSelectedCount;
- (NSInteger)currentVisibleItemCount;
- (NSString *)currentCountDisplayText;
- (void)updateRightBarButtonItemsForCurrentState;
- (void)updateSelectionUIForCurrentState;
@end

@implementation ListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.titleText;

    [self loadItemsFromSourceIfNeeded];

    self.filteredItems = [NSMutableArray array];
    self.searchText = @"";
    self.isSearching = NO;
    self.hasAppliedInitialSearchBarOffset = NO;
    self.initialTableViewOffsetY = CGFLOAT_MAX;

    [self configureTableViewAppearance];
    [self.tableView registerClass:LVTextCell.class
           forCellReuseIdentifier:@"LVTextCell"];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 56.0;

    self.searchBar = [self configuredSearchBar];
    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[
        [self fixedSpaceBarButtonItemWithWidth:10],
        [self backBarButtonItem]
    ];
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:NO
                           countDisplayText:[self currentCountDisplayText]];

    [self configureToolbarItems];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self updateInteractivePopGestureEnabled];

    [self configureLongPressGesture];

    self.navigationItem.titleView = [self configuredTitleView];
    [self updateEmptyStateIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.initialTableViewOffsetY == CGFLOAT_MAX) {
        self.initialTableViewOffsetY = self.tableView.contentOffset.y;
    }

    [self applyInitialSearchBarOffsetIfNeeded];
}

#pragma mark - Navigation

- (void)goBack {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:NO];
    }

    [self updateInteractivePopGestureEnabled];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Empty State

- (BOOL)shouldShowSearchBar {
    if (self.isSearching) {
        return YES;
    }

    return self.items.count > 0;
}

- (UILabel *)emptyStateLabelWithText:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.45];
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

- (void)updateEmptyStateIfNeeded {
    [self updateSearchBarVisibilityIfNeeded];

    NSString *emptyText = nil;

    if (self.isSearching) {
        if (self.filteredItems.count == 0) {
            emptyText = @"No results";
        }
    } else if (self.items.count == 0) {
        emptyText = @"No items";
    }

    if (emptyText.length == 0) {
        self.tableView.backgroundView = nil;
        return;
    }

    self.tableView.backgroundView = [self emptyStateLabelWithText:emptyText];
}

- (NSInteger)currentSelectedCount {
    if (!self.tableView.editing) {
        return 0;
    }

    return [self selectedIndexPathsForDeleteAction].count;
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

    return [NSString stringWithFormat:@"%ld items", (long)visibleCount];
}

- (void)updateRightBarButtonItemsForCurrentState {
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:self.tableView.editing
                           countDisplayText:[self currentCountDisplayText]];
}

- (void)updateSelectionUIForCurrentState {
    [self updateSelectionToolbarButtonsForCurrentState];
    [self updateRightBarButtonItemsForCurrentState];
}

#pragma mark - Table Data

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    if (self.isSearching) {
        return self.filteredItems.count;
    }

    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    LVTextCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"LVTextCell"
                                    forIndexPath:indexPath];

    NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
    NSString *displayText = entry[@"text"];

    [cell configureWithText:displayText];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    return cell;
}

#pragma mark - Table Selection

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateSelectionUIForCurrentState];
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
    NSNumber *originalIndex = entry[@"originalIndex"];
    if (![originalIndex isKindOfClass:[NSNumber class]]) {
        return;
    }

    [self handleItemSelectionAtIndex:[originalIndex integerValue]];
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateSelectionUIForCurrentState];
    }
}

- (void)handleItemSelectionAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return;
    }

    if (self.editItemBlock) {
        [self presentEditInputAlertForIndex:index currentText:self.items[index]];
    }
}

#pragma mark - Edit Mode / Reordering

- (void)editButtonTapped {
    BOOL editing = !self.tableView.editing;

    if (editing) {
        [self.searchBar resignFirstResponder];
    }

    [self.tableView setEditing:editing animated:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    [self updateSelectionUIForCurrentState];
    [self updateInteractivePopGestureEnabled];

    if (editing) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    } else {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSearching) {
        return NO;
    }

    return YES;
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath
      toIndexPath:(NSIndexPath *)toIndexPath {

    NSString *item = self.items[fromIndexPath.row];
    [self.items removeObjectAtIndex:fromIndexPath.row];
    [self.items insertObject:item atIndex:toIndexPath.row];

    if (self.moveItemBlock) {
        self.moveItemBlock(fromIndexPath.row, toIndexPath.row);
    }
}

#pragma mark - Feedback / Gesture

- (void)showToastWithMessage:(NSString *)message {
    GonerinoShowToast(message);
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    if (self.tableView.editing) {
        return;
    }

    CGPoint point = [gesture locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];

    if (!indexPath) {
        return;
    }

    NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
    NSString *text = entry[@"text"];

    if (![text isKindOfClass:[NSString class]]) {
        return;
    }

    UIPasteboard.generalPasteboard.string = text;

    [self showToastWithMessage:
        [NSString stringWithFormat:@"Copied \"%@\"", text]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {

    if (self.tableView.editing) {
        return NO;
    }

    return YES;
}

@end
