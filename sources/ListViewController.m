#import "ListViewController.h"
#import "ToastHelper.h"

#import "LVCHelpers/LVCPrivate.h"
#import "LVCHelpers/LVCResolveHelper.h"
#import "LVCHelpers/LVCDeleteHelper.h"
#import "LVCHelpers/LVCStateHelper.h"
#import "LVCHelpers/LVCSetupHelper.h"
#import "LVCHelpers/LVCInputHelper.h"

@interface ListViewController ()
- (void)handleItemSelectionAtIndex:(NSInteger)index;
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

    self.searchBar = [self configuredSearchBar];
    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[
        [self fixedSpaceBarButtonItemWithWidth:10],
        [self backBarButtonItem]
    ];
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForEditing:NO];

    [self configureToolbarItems];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self updateInteractivePopGestureEnabled];

    [self configureLongPressGesture];

    self.navigationItem.titleView = [self configuredTitleView];
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

    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                    forIndexPath:indexPath];

    NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
    NSString *displayText = entry[@"text"];

    cell.textLabel.text = displayText;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    UIView *selectedView = [UIView new];
    selectedView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    cell.selectedBackgroundView = selectedView;

    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;

    return cell;
}

#pragma mark - Table Selection

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateDeleteToolbarButtonEnabled];
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
        [self updateDeleteToolbarButtonEnabled];
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

    [self.tableView setEditing:editing animated:YES];
    self.navigationItem.rightBarButtonItems = [self rightBarButtonItemsForEditing:editing];
    [self updateInteractivePopGestureEnabled];

    if (editing) {
        [self updateDeleteToolbarButtonEnabled];
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
