#import "ListViewController.h"
#import "ToastHelper.h"

@interface ListViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>
@property (nonatomic, copy) NSString *currentInputPlaceholder;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *filteredItems;
@property (nonatomic, assign) BOOL hasAppliedInitialSearchBarOffset;
@property (nonatomic, assign) CGFloat initialTableViewOffsetY;

- (void)goBack;
- (BOOL)shouldApplyInitialSearchBarOffset;
- (void)applyInitialSearchBarOffsetIfNeeded;
- (void)updateInteractivePopGestureEnabled;
- (void)loadItemsFromSourceIfNeeded;

- (void)configureTableViewAppearance;
- (UISearchBar *)configuredSearchBar;
- (void)configureLongPressGesture;
- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width;
- (UIBarButtonItem *)backBarButtonItem;
- (UIBarButtonItem *)addBarButtonItem;
- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing;
- (UIView *)configuredTitleView;
- (void)configureToolbarItems;

- (NSArray<NSIndexPath *> *)selectedIndexPathsForDeleteAction;
- (void)setDeleteToolbarButtonEnabled:(BOOL)enabled;
- (void)updateDeleteToolbarButtonEnabled;

- (void)applySearchStateForText:(NSString *)searchText;
- (void)rebuildFilteredItemsForCurrentSearchText;
- (void)reloadItemsFromSourceAndRefresh;
- (void)updateFilteredItemsForSearchText:(NSString *)searchText;
- (NSDictionary *)resolvedEntryForIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSDictionary *> *)resolvedEntriesForSelectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (NSDictionary *)inputConfigForEditing:(BOOL)isEditing;
- (UITextView *)configuredInputTextViewWithFrame:(CGRect)frame;
- (UIAlertController *)inputAlertControllerWithTitle:(NSString *)title
                                             message:(NSString *)message
                                            textView:(UITextView **)textView
                                         initialText:(NSString *)initialText
                                         placeholder:(NSString *)placeholder;
- (NSString *)trimmedInputTextFromTextView:(UITextView *)textView;
- (BOOL)isPlaceholderInputTextView:(UITextView *)textView;
- (void)handleAddInputSaveWithTextView:(UITextView *)textView;
- (void)handleEditInputSaveWithTextView:(UITextView *)textView
                                  index:(NSInteger)index
                            currentText:(NSString *)currentText;
- (void)addButtonTapped;
- (void)presentAddInputAlert;
- (void)presentEditInputAlertForIndex:(NSInteger)index
                          currentText:(NSString *)currentText;

- (void)handleItemSelectionAtIndex:(NSInteger)index;
- (void)editButtonTapped;
- (void)deleteSelectedItemsTapped;
- (void)performDeleteSelectedItems;

- (void)showToastWithMessage:(NSString *)message;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
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

#pragma mark - Navigation / State

- (void)goBack {
    if (self.tableView.editing) {
        [self.tableView setEditing:NO animated:NO];
    }

    [self updateInteractivePopGestureEnabled];
    [self.navigationController setToolbarHidden:YES animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)shouldApplyInitialSearchBarOffset {
    if (self.hasAppliedInitialSearchBarOffset) {
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

- (void)loadItemsFromSourceIfNeeded {
    if (self.loadItemsBlock) {
        NSArray *loadedItems = self.loadItemsBlock();
        self.items = loadedItems ? [loadedItems mutableCopy] : [NSMutableArray array];
    } else if (!self.items) {
        self.items = [NSMutableArray array];
    }
}

#pragma mark - Setup

- (void)configureTableViewAppearance {
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"Cell"];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
}

- (UISearchBar *)configuredSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 0, 56)];
    searchBar.delegate = self;
    searchBar.placeholder = @"Search";
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.smartQuotesType = UITextSmartQuotesTypeNo;
    searchBar.smartDashesType = UITextSmartDashesTypeNo;
    searchBar.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    searchBar.returnKeyType = UIReturnKeyDone;
    searchBar.showsCancelButton = NO;

    return searchBar;
}

- (void)configureLongPressGesture {
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(handleLongPress:)];

    longPress.delegate = self;

    [self.tableView addGestureRecognizer:longPress];
}

- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width {
    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    space.width = width;

    return space;
}

- (UIBarButtonItem *)backBarButtonItem {
    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:18.5
                                                       weight:UIImageSymbolWeightLight];

    UIImage *arrow = [[UIImage systemImageNamed:@"chevron.left"
                               withConfiguration:config]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    UIBarButtonItem *backButton =
        [[UIBarButtonItem alloc] initWithImage:arrow
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(goBack)];

    backButton.tintColor = [UIColor whiteColor];

    return backButton;
}

- (UIBarButtonItem *)addBarButtonItem {
    UIBarButtonItem *addButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(addButtonTapped)];
    addButton.tintColor = [UIColor whiteColor];

    return addButton;
}

- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing {
    UIBarButtonItem *editButton =
        [[UIBarButtonItem alloc] initWithTitle:(editing ? @"Done" : @"Edit")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editButtonTapped)];
    editButton.tintColor = [UIColor whiteColor];

    return editButton;
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing {
    UIBarButtonItem *rightSpace = [self fixedSpaceBarButtonItemWithWidth:10];
    UIBarButtonItem *editButton = [self editBarButtonItemForEditing:editing];

    if (editing) {
        return @[rightSpace, editButton];
    }

    UIBarButtonItem *addButton = [self addBarButtonItem];

    return @[rightSpace, editButton, addButton];
}

- (UIView *)configuredTitleView {
    UIView *customTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-80, 0, 150, 44)];
    titleLabel.text = self.titleText;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:19];
    titleLabel.textAlignment = NSTextAlignmentLeft;

    [customTitleView addSubview:titleLabel];

    return customTitleView;
}

- (void)configureToolbarItems {
    UIBarButtonItem *flexibleSpaceLeft =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    UIBarButtonItem *deleteButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(deleteSelectedItemsTapped)];

    deleteButton.tintColor = [UIColor systemRedColor];

    UIBarButtonItem *flexibleSpaceRight =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    deleteButton.enabled = NO;
    self.toolbarItems = @[flexibleSpaceLeft, deleteButton, flexibleSpaceRight];
}

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

- (void)reloadItemsFromSourceAndRefresh {
    [self loadItemsFromSourceIfNeeded];

    if (self.isSearching) {
        [self rebuildFilteredItemsForCurrentSearchText];
        [self.tableView reloadData];
        return;
    }

    [self.tableView reloadData];
}

- (void)updateFilteredItemsForSearchText:(NSString *)searchText {
    [self applySearchStateForText:searchText];
    [self rebuildFilteredItemsForCurrentSearchText];
    [self.tableView reloadData];
}

#pragma mark - Resolve

- (NSDictionary *)resolvedEntryForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }

    if (self.isSearching) {
        if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
            return nil;
        }

        NSDictionary *entry = self.filteredItems[indexPath.row];
        NSString *text = entry[@"text"];
        NSNumber *originalIndex = entry[@"originalIndex"];

        if (![text isKindOfClass:[NSString class]] ||
            ![originalIndex isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSInteger resolvedIndex = [originalIndex integerValue];
        if (resolvedIndex < 0 || resolvedIndex >= self.items.count) {
            return nil;
        }

        return @{
            @"text": text,
            @"originalIndex": originalIndex
        };
    }

    if (indexPath.row < 0 || indexPath.row >= self.items.count) {
        return nil;
    }

    NSString *text = self.items[indexPath.row];
    if (![text isKindOfClass:[NSString class]]) {
        return nil;
    }

    return @{
        @"text": text,
        @"originalIndex": @(indexPath.row)
    };
}

- (NSArray<NSDictionary *> *)resolvedEntriesForSelectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) {
        return @[];
    }

    NSArray<NSIndexPath *> *sortedIndexPaths =
        [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
            if (obj1.row > obj2.row) return NSOrderedAscending;
            if (obj1.row < obj2.row) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];

    for (NSIndexPath *indexPath in sortedIndexPaths) {
        NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
        if (entry) {
            [entries addObject:entry];
        }
    }

    return [entries copy];
}

#pragma mark - Input Config

- (NSDictionary *)inputConfigForEditing:(BOOL)isEditing {
    NSString *title = isEditing ? @"Edit Item" : @"Add Item";
    NSString *message = isEditing ? @"Edit text" : @"Enter text";
    NSString *placeholder = @"Text";

    if ([self.itemType isEqualToString:@"channel"]) {
        title = isEditing ? @"Edit Channel" : @"Add Channel";
        message = isEditing ? @"Edit the channel name or regex rule"
                            : @"Enter a channel name or regex rule";
        placeholder = @"Channel name";
    } else if ([self.itemType isEqualToString:@"word"]) {
        title = isEditing ? @"Edit Word" : @"Add Word";
        message = isEditing ? @"Edit the blocked word or regex rule"
                            : @"Enter a blocked word or regex rule";
        placeholder = @"Blocked word";
    }

    return @{
        @"title": title,
        @"message": message,
        @"placeholder": placeholder
    };
}

- (UITextView *)configuredInputTextViewWithFrame:(CGRect)frame {
    UIFont *font = [UIFont systemFontOfSize:14];

    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.font = font;
    textView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    textView.returnKeyType = UIReturnKeyDone;
    textView.delegate = self;

    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.smartQuotesType = UITextSmartQuotesTypeNo;
    textView.smartDashesType = UITextSmartDashesTypeNo;
    textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;

    textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    textView.scrollEnabled = YES;

    textView.layer.borderWidth = 0.5;
    textView.layer.cornerRadius = 6;

    return textView;
}

- (UIAlertController *)inputAlertControllerWithTitle:(NSString *)title
                                             message:(NSString *)message
                                            textView:(UITextView **)textView
                                         initialText:(NSString *)initialText
                                         placeholder:(NSString *)placeholder {
    self.currentInputPlaceholder = placeholder;

    NSString *spacer = @"\n\n\n\n\n\n\n\n\n\n";
    NSString *alertMessage = [NSString stringWithFormat:@"%@%@", message, spacer];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:alertMessage
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat height = font.lineHeight * 9 + 12;

    UITextView *input =
        [self configuredInputTextViewWithFrame:CGRectMake(10, 70, 250, height)];

    if (initialText.length > 0) {
        input.text = initialText;
        input.textColor = [UIColor labelColor];
    } else {
        input.text = placeholder;
        input.textColor = [UIColor secondaryLabelColor];
    }

    [alert.view addSubview:input];

    if (textView) {
        *textView = input;
    }

    return alert;
}

- (NSString *)trimmedInputTextFromTextView:(UITextView *)textView {
    NSString *rawText = textView.text ?: @"";

    return [rawText stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isPlaceholderInputTextView:(UITextView *)textView {
    NSString *rawText = textView.text ?: @"";

    return textView.textColor == [UIColor secondaryLabelColor] ||
           [rawText isEqualToString:self.currentInputPlaceholder];
}

- (void)handleAddInputSaveWithTextView:(UITextView *)textView {
    NSString *newText = [self trimmedInputTextFromTextView:textView];
    BOOL isPlaceholderText = [self isPlaceholderInputTextView:textView];

    // Empty or placeholder
    if (newText.length == 0 || isPlaceholderText) {
        return;
    }

    // Duplicate
    if ([self.items containsObject:newText]) {
        [self showToastWithMessage:
            [NSString stringWithFormat:@"Already exists: \"%@\"", newText]];
        return;
    }

    // Save normally
    if (self.addItemBlock) {
        self.addItemBlock(newText);
    }

    [self reloadItemsFromSourceAndRefresh];
}

- (void)handleEditInputSaveWithTextView:(UITextView *)textView
                                  index:(NSInteger)index
                            currentText:(NSString *)currentText {
    NSString *newText = [self trimmedInputTextFromTextView:textView];
    BOOL isPlaceholderText = [self isPlaceholderInputTextView:textView];

    NSMutableArray *otherItems = [self.items mutableCopy];
    if (!otherItems) {
        otherItems = [NSMutableArray array];
    }

    if (index >= 0 && index < otherItems.count) {
        [otherItems removeObjectAtIndex:index];
    }

    // Empty or placeholder
    if (newText.length == 0 || isPlaceholderText) {
        return;
    }

    // No changes
    if ([newText isEqualToString:currentText]) {
        [self showToastWithMessage:
            [NSString stringWithFormat:@"No changes: \"%@\"", currentText]];
        return;
    }

    // Duplicate
    if ([otherItems containsObject:newText]) {
        [self showToastWithMessage:
            [NSString stringWithFormat:@"Already exists: \"%@\"", newText]];
        return;
    }

    // Save normally
    if (self.editItemBlock) {
        self.editItemBlock(index, currentText, newText);
    }

    [self reloadItemsFromSourceAndRefresh];
}

#pragma mark - Input Actions

- (void)addButtonTapped {
    if (self.addItemBlock) {
        [self presentAddInputAlert];
    }
}

- (void)presentAddInputAlert {
    NSDictionary *config = [self inputConfigForEditing:NO];
    NSString *title = config[@"title"];
    NSString *message = config[@"message"];
    NSString *placeholder = config[@"placeholder"];

    UITextView *textView = nil;
    UIAlertController *alert =
        [self inputAlertControllerWithTitle:title
                                    message:message
                                   textView:&textView
                                initialText:nil
                                placeholder:placeholder];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Save"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
        [weakSelf handleAddInputSaveWithTextView:textView];
    }]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentEditInputAlertForIndex:(NSInteger)index
                          currentText:(NSString *)currentText {
    NSDictionary *config = [self inputConfigForEditing:YES];
    NSString *title = config[@"title"];
    NSString *message = config[@"message"];
    NSString *placeholder = config[@"placeholder"];

    UITextView *textView = nil;
    UIAlertController *alert =
        [self inputAlertControllerWithTitle:title
                                    message:message
                                   textView:&textView
                                initialText:currentText
                                placeholder:placeholder];

    __weak typeof(self) weakSelf = self;

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Save"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
        [weakSelf handleEditInputSaveWithTextView:textView
                                            index:index
                                      currentText:currentText];
    }]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
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

#pragma mark - Edit Mode

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

#pragma mark - Delete

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

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
replacementText:(NSString *)text {

    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (textView.textColor == [UIColor secondaryLabelColor]) {
        textView.text = @"";
        textView.textColor = [UIColor labelColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0 && self.currentInputPlaceholder.length > 0) {
        textView.text = self.currentInputPlaceholder;
        textView.textColor = [UIColor secondaryLabelColor];
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
