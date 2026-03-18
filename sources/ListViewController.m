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

- (NSDictionary *)inputConfigForEditing:(BOOL)isEditing;
- (UITextView *)configuredInputTextViewWithFrame:(CGRect)frame;
- (UIAlertController *)inputAlertControllerWithTitle:(NSString *)title
                                             message:(NSString *)message
                                            textView:(UITextView **)textView
                                         initialText:(NSString *)initialText
                                         placeholder:(NSString *)placeholder;
- (void)reloadItemsFromSourceAndRefresh;
- (void)updateFilteredItemsForSearchText:(NSString *)searchText;
@end

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.titleText;

    if (self.loadItemsBlock) {
        NSArray *loadedItems = self.loadItemsBlock();
        self.items = loadedItems ? [loadedItems mutableCopy] : [NSMutableArray array];
    } else if (!self.items) {
        self.items = [NSMutableArray array];
    }

    self.filteredItems = [NSMutableArray array];
    self.searchText = @"";
    self.isSearching = NO;
    self.hasAppliedInitialSearchBarOffset = NO;
    self.initialTableViewOffsetY = CGFLOAT_MAX;

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"Cell"];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 0, 56)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.smartQuotesType = UITextSmartQuotesTypeNo;
    self.searchBar.smartDashesType = UITextSmartDashesTypeNo;
    self.searchBar.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    self.searchBar.returnKeyType = UIReturnKeyDone;
    self.searchBar.showsCancelButton = NO;

    self.tableView.tableHeaderView = self.searchBar;

    self.navigationItem.hidesBackButton = YES;

    UIImageSymbolConfiguration *config = 
        [UIImageSymbolConfiguration configurationWithPointSize:18.5 weight:UIImageSymbolWeightLight];

    UIImage *arrow = [[UIImage systemImageNamed:@"chevron.left"
                               withConfiguration:config]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    UIBarButtonItem *backButton =
        [[UIBarButtonItem alloc] initWithImage:arrow
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(goBack)];

    backButton.tintColor = [UIColor whiteColor];

    UIBarButtonItem *space =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    space.width = 10;

    self.navigationItem.leftBarButtonItems = @[space, backButton];

    UIBarButtonItem *addButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(addButtonTapped)];
    addButton.tintColor = [UIColor whiteColor];

    UIBarButtonItem *editButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editButtonTapped)];
    editButton.tintColor = [UIColor whiteColor];

    UIBarButtonItem *rightSpace =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    rightSpace.width = 10;

    self.navigationItem.rightBarButtonItems = @[rightSpace, editButton, addButton];

    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    [self configureToolbarItems];
    [self.navigationController setToolbarHidden:YES animated:NO];

    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(handleLongPress:)];

    longPress.delegate = self;

    [self.tableView addGestureRecognizer:longPress];

    UIView *customTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-80, 0, 150, 44)];
    titleLabel.text = self.titleText;
    titleLabel.textColor = [UIColor whiteColor];

    titleLabel.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:19];

    titleLabel.textAlignment = NSTextAlignmentLeft;

    [customTitleView addSubview:titleLabel];

    self.navigationItem.titleView = customTitleView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    if (self.initialTableViewOffsetY == CGFLOAT_MAX) {
        self.initialTableViewOffsetY = self.tableView.contentOffset.y;
    }

    if (self.hasAppliedInitialSearchBarOffset) {
        return;
    }

    if (self.searchBar.text.length > 0 || self.isSearching) {
        return;
    }

    CGFloat searchBarHeight = CGRectGetHeight(self.searchBar.frame);
    if (searchBarHeight <= 0) {
        return;
    }

    CGPoint offset = self.tableView.contentOffset;
    offset.y = self.initialTableViewOffsetY + searchBarHeight;
    [self.tableView setContentOffset:offset animated:NO];

    self.hasAppliedInitialSearchBarOffset = YES;
}

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
}

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

- (void)reloadItemsFromSourceAndRefresh {
    if (self.loadItemsBlock) {
        NSArray *loaded = self.loadItemsBlock();
        self.items = loaded ? [loaded mutableCopy] : [NSMutableArray array];
    } else if (!self.items) {
        self.items = [NSMutableArray array];
    }

    if (self.isSearching) {
        [self updateFilteredItemsForSearchText:self.searchText];
        return;
    }

    [self.tableView reloadData];
}

- (void)updateFilteredItemsForSearchText:(NSString *)searchText {
    [self.filteredItems removeAllObjects];

    NSString *trimmedSearchText =
        [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    self.searchText = trimmedSearchText;
    self.isSearching = trimmedSearchText.length > 0;

    if (!self.isSearching) {
        [self.tableView reloadData];
        return;
    }

    NSString *lowercasedSearchText = [trimmedSearchText lowercaseString];

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

    [self.tableView reloadData];
}

- (void)addButtonTapped {
    if (self.addItemBlock) {
        [self presentAddInputAlert];
    }
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

- (void)updateDeleteToolbarButtonEnabled {
    if (self.toolbarItems.count < 2) {
        return;
    }

    UIBarButtonItem *deleteButton = self.toolbarItems[1];
    deleteButton.enabled = self.tableView.indexPathsForSelectedRows.count > 0;
}

- (void)editButtonTapped {
    BOOL editing = !self.tableView.editing;

    [self.tableView setEditing:editing animated:YES];

    UIBarButtonItem *editButton =
        [[UIBarButtonItem alloc] initWithTitle:(editing ? @"Done" : @"Edit")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editButtonTapped)];
    editButton.tintColor = [UIColor whiteColor];

    UIBarButtonItem *rightSpace =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                      target:nil
                                                      action:nil];
    rightSpace.width = 10;

    if (editing) {
        self.navigationItem.rightBarButtonItems = @[rightSpace, editButton];
        [self updateDeleteToolbarButtonEnabled];
        [self.navigationController setToolbarHidden:NO animated:YES];
    } else {
        UIBarButtonItem *addButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                          target:self
                                                          action:@selector(addButtonTapped)];
        addButton.tintColor = [UIColor whiteColor];

        self.navigationItem.rightBarButtonItems = @[rightSpace, editButton, addButton];
        [self.navigationController setToolbarHidden:YES animated:YES];
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

        NSString *rawText = textView.text;
        NSString *newText = [rawText stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        BOOL isPlaceholderText =
            textView.textColor == [UIColor secondaryLabelColor] ||
            [rawText isEqualToString:weakSelf.currentInputPlaceholder];

        // Empty or placeholder
        if (newText.length == 0 || isPlaceholderText) {
            return;
        }

        // Duplicate
        if ([weakSelf.items containsObject:newText]) {
            [weakSelf showToastWithMessage:
                [NSString stringWithFormat:@"Already exists: \"%@\"", newText]];
            return;
        }

        // Save normally
        if (weakSelf.addItemBlock) {
            weakSelf.addItemBlock(newText);
        }

        [weakSelf reloadItemsFromSourceAndRefresh];
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

        NSString *rawText = textView.text;
        NSString *newText = [rawText stringByTrimmingCharactersInSet:
            [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        BOOL isPlaceholderText =
            textView.textColor == [UIColor secondaryLabelColor] ||
            [rawText isEqualToString:weakSelf.currentInputPlaceholder];

        NSMutableArray *otherItems = [weakSelf.items mutableCopy];
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
            [weakSelf showToastWithMessage:
                [NSString stringWithFormat:@"No changes: \"%@\"", currentText]];
            return;
        }

        // Duplicate
        if ([otherItems containsObject:newText]) {
            [weakSelf showToastWithMessage:
                [NSString stringWithFormat:@"Already exists: \"%@\"", newText]];
            return;
        }

        // Save normally
        if (weakSelf.editItemBlock) {
            weakSelf.editItemBlock(index, currentText, newText);
        }

        [weakSelf reloadItemsFromSourceAndRefresh];
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

    NSString *displayText = nil;

    if (self.isSearching) {
        NSDictionary *entry = self.filteredItems[indexPath.row];
        displayText = entry[@"text"];
    } else {
        displayText = self.items[indexPath.row];
    }

    cell.textLabel.text = displayText;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    UIView *selectedView = [UIView new];
    selectedView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
    cell.selectedBackgroundView = selectedView;

    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;

    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateDeleteToolbarButtonEnabled];
        return;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger targetIndex = indexPath.row;

    if (self.isSearching) {
        if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
            return;
        }

        NSDictionary *entry = self.filteredItems[indexPath.row];
        NSNumber *originalIndex = entry[@"originalIndex"];
        if (![originalIndex isKindOfClass:[NSNumber class]]) {
            return;
        }

        targetIndex = [originalIndex integerValue];
    }

    [self handleItemSelectionAtIndex:targetIndex];
}

- (void)tableView:(UITableView *)tableView
didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView.editing) {
        [self updateDeleteToolbarButtonEnabled];
    }
}

#pragma mark - Edit Actions

- (void)deleteSelectedItemsTapped {
    NSArray<NSIndexPath *> *selectedIndexPaths = [self.tableView.indexPathsForSelectedRows copy];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSString *type = self.itemType.length > 0 ? self.itemType : @"item";
    NSString *pluralType = [type stringByAppendingString:@"s"];

    NSString *title = nil;
    NSString *message = nil;

    if (selectedIndexPaths.count == 1) {
        NSIndexPath *indexPath = selectedIndexPaths.firstObject;
        NSString *selectedText = nil;

        if (self.isSearching) {
            if (indexPath.row >= 0 && indexPath.row < self.filteredItems.count) {
                NSDictionary *entry = self.filteredItems[indexPath.row];
                if ([entry[@"text"] isKindOfClass:[NSString class]]) {
                    selectedText = entry[@"text"];
                }
            }
        } else {
            if (indexPath.row >= 0 && indexPath.row < self.items.count) {
                selectedText = self.items[indexPath.row];
            }
        }

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
    NSArray<NSIndexPath *> *selectedIndexPaths = [self.tableView.indexPathsForSelectedRows copy];
    if (selectedIndexPaths.count == 0) {
        return;
    }

    NSArray<NSIndexPath *> *sortedIndexPaths =
        [selectedIndexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
            if (obj1.row > obj2.row) return NSOrderedAscending;
            if (obj1.row < obj2.row) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    NSMutableArray<NSString *> *selectedTexts = [NSMutableArray array];
    NSMutableArray<NSNumber *> *targetIndexes = [NSMutableArray array];

    for (NSIndexPath *indexPath in sortedIndexPaths) {
        if (self.isSearching) {
            if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
                continue;
            }

            NSDictionary *entry = self.filteredItems[indexPath.row];
            NSString *text = entry[@"text"];
            NSNumber *originalIndex = entry[@"originalIndex"];

            if (![text isKindOfClass:[NSString class]] ||
                ![originalIndex isKindOfClass:[NSNumber class]]) {
                continue;
            }

            NSInteger targetIndex = [originalIndex integerValue];
            if (targetIndex < 0 || targetIndex >= self.items.count) {
                continue;
            }

            [selectedTexts addObject:text];
            [targetIndexes addObject:originalIndex];
        } else {
            if (indexPath.row < 0 || indexPath.row >= self.items.count) {
                continue;
            }

            [selectedTexts addObject:self.items[indexPath.row]];
            [targetIndexes addObject:@(indexPath.row)];
        }
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

    if (selectedTexts.count == 1) {
        [self showToastWithMessage:
            [NSString stringWithFormat:@"Deleted \"%@\"", selectedTexts.firstObject]];
    } else {
        NSString *type = self.itemType.length > 0 ? self.itemType : @"item";
        NSString *pluralType = [type stringByAppendingString:@"s"];

        [self showToastWithMessage:
            [NSString stringWithFormat:@"Deleted %lu %@",
                                       (unsigned long)selectedTexts.count,
                                       pluralType]];
    }

    if (self.toolbarItems.count >= 2) {
        UIBarButtonItem *deleteButton = self.toolbarItems[1];
        deleteButton.enabled = NO;
    }
}

#pragma mark - Edit Mode

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
        NSInteger targetIndex = indexPath.row;
        NSString *item = nil;

        if (self.isSearching) {
            if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
                return;
            }

            NSDictionary *entry = self.filteredItems[indexPath.row];
            NSNumber *originalIndex = entry[@"originalIndex"];
            if (![originalIndex isKindOfClass:[NSNumber class]]) {
                return;
            }

            targetIndex = [originalIndex integerValue];
            if (targetIndex < 0 || targetIndex >= self.items.count) {
                return;
            }

            item = entry[@"text"];
        } else {
            if (indexPath.row < 0 || indexPath.row >= self.items.count) {
                return;
            }

            item = self.items[indexPath.row];
        }

        if (self.removeItemBlock) {
            self.removeItemBlock(item);
        }

        [self.items removeObjectAtIndex:targetIndex];
        [self reloadItemsFromSourceAndRefresh];
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

    NSString *text = nil;

    if (self.isSearching) {
        if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
            return;
        }

        NSDictionary *entry = self.filteredItems[indexPath.row];
        text = entry[@"text"];
    } else {
        if (indexPath.row < 0 || indexPath.row >= self.items.count) {
            return;
        }

        text = self.items[indexPath.row];
    }

    if (!text) {
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
