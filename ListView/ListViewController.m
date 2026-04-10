#import "ListViewController.h"
#import "ToastHelper.h"
#import "TextHelper.h"
#import "LVTextCell.h"

#import "LVHelpers/LVPrivate.h"
#import "LVHelpers/LVResolveHelper.h"
#import "LVHelpers/LVDeleteFlowHelper.h"
#import "LVHelpers/LVSelectHelper.h"
#import "LVHelpers/LVControlHelper.h"
#import "LVHelpers/LVSetupHelper.h"
#import "LVHelpers/LVInputHelper.h"
#import "LVHelpers/LVMeasureHelper.h"
#import "LVHelpers/LVPresentHelper.h"
#import "LVHelpers/LVSearchHelper.h"

@interface ListViewController ()

- (void)handleItemSelectionWithResolvedEntry:(NSDictionary *)entry;
- (void)updateEmptyStateIfNeeded;

@end

@implementation ListViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

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

    self.searchBar = [self configuredSearchBar];
    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[
        [self backBarButtonItem],
        [self titleBarButtonItem]
    ];
    self.navigationItem.rightBarButtonItems =
        [self rightBarButtonItemsForEditing:NO
                           countDisplayText:[self currentCountDisplayText]];

    [self configureToolbarItems];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self updateInteractivePopGestureEnabled];

    [self configureLongPressGesture];

    [self updateEmptyStateIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.initialTableViewOffsetY == CGFLOAT_MAX) {
        self.initialTableViewOffsetY = self.tableView.contentOffset.y;
    }

    [self applyInitialSearchBarOffsetIfNeeded];
}

#pragma mark - Data Loading

- (void)loadItemsFromSourceIfNeeded {
    if (self.loadItemsBlock) {
        NSArray *loadedItems = self.loadItemsBlock();
        self.items = loadedItems ? [loadedItems mutableCopy] : [NSMutableArray array];
    } else if (!self.items) {
        self.items = [NSMutableArray array];
    }
}

#pragma mark - Data / UI Refresh

- (void)reloadListDataForCurrentState {
    [self rebuildFilteredItemsForCurrentSearchText];
    [self.tableView reloadData];
}

- (void)refreshListUIForCurrentState {
    [self updateEmptyStateIfNeeded];
    [self updateSelectionUIForCurrentState];
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

- (void)updateEmptyStateIfNeeded {
    [self updateSearchBarVisibilityIfNeeded];

    NSString *emptyText = nil;

    if (self.isSearching) {
        if (self.filteredItems.count == 0) {
            emptyText = TextHelperNoResultsText();
        }
    } else if (self.items.count == 0) {
        emptyText = TextHelperNoItemsText();
    }

    if (emptyText.length == 0) {
        self.tableView.backgroundView = nil;
        return;
    }

    self.tableView.backgroundView = [self emptyStateLabelWithText:emptyText];
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

- (CGFloat)tableView:(UITableView *)tableView
estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
    NSString *text = entry[@"text"];

    if (![text isKindOfClass:[NSString class]]) {
        return 44.0;
    }

    return [self estimatedHeightForDisplayText:text tableView:tableView];
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
    [self handleItemSelectionWithResolvedEntry:entry];
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateSelectionUIForCurrentState];
    }
}

- (void)addButtonTapped {
    if (self.addItemBlock) {
        [self presentAddInputAlert];
    }
}

- (void)handleItemSelectionWithResolvedEntry:(NSDictionary *)entry {
    NSNumber *originalIndex = entry[@"originalIndex"];
    NSString *currentText = entry[@"text"];

    if (![originalIndex isKindOfClass:[NSNumber class]] ||
        ![currentText isKindOfClass:[NSString class]]) {
        return;
    }

    NSInteger index = [originalIndex integerValue];
    if (index < 0 || index >= self.items.count) {
        return;
    }

    if (self.editItemBlock) {
        [self presentEditInputAlertForIndex:index currentText:currentText];
    }
}

#pragma mark - Edit Mode / Reordering

- (void)editButtonTapped {
    BOOL editing = !self.tableView.editing;

    if (editing) {
        [self.searchBar resignFirstResponder];
    }

    [self.tableView setEditing:editing animated:YES];

    // One layout pass is always needed after toggling editing.
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    if (!editing && !self.tableView.editing) {
        // Exiting editing needs one additional synchronous layout pass to fully settle row geometry.
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }

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

    [self showToastWithMessage:TextHelperCopiedToast(text)];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {

    if (self.tableView.editing) {
        return NO;
    }

    return YES;
}

@end
