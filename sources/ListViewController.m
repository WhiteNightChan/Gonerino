#import "ListViewController.h"
#import "ToastHelper.h"

@interface ListViewController () <UITextViewDelegate>
@property (nonatomic, copy) NSString *currentInputPlaceholder;
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

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"Cell"];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];

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

    longPress.delegate = (id<UIGestureRecognizerDelegate>)self;

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

- (void)goBack {
    [self.navigationController popViewControllerAnimated:YES];
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
    NSString *title = @"Add Item";
    NSString *message = @"Enter text";
    NSString *placeholder = @"Text";

    if ([self.itemType isEqualToString:@"channel"]) {
        title = @"Add Channel";
        message = @"Enter a channel name or regex rule";
        placeholder = @"Channel name";
    } else if ([self.itemType isEqualToString:@"word"]) {
        title = @"Add Word";
        message = @"Enter a blocked word or regex rule";
        placeholder = @"Blocked word";
    }

    self.currentInputPlaceholder = placeholder;

    NSString *spacer = @"\n\n\n\n\n\n\n\n\n\n";
    NSString *alertMessage = [NSString stringWithFormat:@"%@%@", message, spacer];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:alertMessage
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat height = font.lineHeight * 9 + 12;

    UITextView *textView =
        [[UITextView alloc] initWithFrame:CGRectMake(10, 70, 250, height)];

    textView.text = placeholder;
    textView.textColor = [UIColor secondaryLabelColor];
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

    [alert.view addSubview:textView];

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

        if (weakSelf.loadItemsBlock) {
            NSArray *loaded = weakSelf.loadItemsBlock();
            weakSelf.items = loaded ? [loaded mutableCopy] : [NSMutableArray array];
        } else if (!weakSelf.items) {
            weakSelf.items = [NSMutableArray array];
        }

        [weakSelf.tableView reloadData];
    }]];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)presentEditInputAlertForIndex:(NSInteger)index
                          currentText:(NSString *)currentText {
    NSString *title = @"Edit Item";
    NSString *message = @"Edit text";
    NSString *placeholder = @"Text";

    if ([self.itemType isEqualToString:@"channel"]) {
        title = @"Edit Channel";
        message = @"Edit the channel name or regex rule";
        placeholder = @"Channel name";
    } else if ([self.itemType isEqualToString:@"word"]) {
        title = @"Edit Word";
        message = @"Edit the blocked word or regex rule";
        placeholder = @"Blocked word";
    }

    self.currentInputPlaceholder = placeholder;

    NSString *spacer = @"\n\n\n\n\n\n\n\n\n\n";
    NSString *alertMessage = [NSString stringWithFormat:@"%@%@", message, spacer];

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:alertMessage
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat height = font.lineHeight * 9 + 12;

    UITextView *textView =
        [[UITextView alloc] initWithFrame:CGRectMake(10, 70, 250, height)];

    if (currentText.length > 0) {
        textView.text = currentText;
        textView.textColor = [UIColor labelColor];
    } else {
        textView.text = placeholder;
        textView.textColor = [UIColor secondaryLabelColor];
    }

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

    [alert.view addSubview:textView];

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

        if (weakSelf.loadItemsBlock) {
            NSArray *loaded = weakSelf.loadItemsBlock();
            weakSelf.items = loaded ? [loaded mutableCopy] : [NSMutableArray array];
        } else if (!weakSelf.items) {
            weakSelf.items = [NSMutableArray array];
        }

        [weakSelf.tableView reloadData];
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

    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"Cell"
                                    forIndexPath:indexPath];

    cell.textLabel.text = self.items[indexPath.row];
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

    [self handleItemSelectionAtIndex:indexPath.row];
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

    NSString *title = [NSString stringWithFormat:@"Delete %@",
                                                 [pluralType capitalizedString]];

    NSString *message = [NSString stringWithFormat:@"Are you sure you want to delete %lu %@?",
                                                   (unsigned long)selectedIndexPaths.count,
                                                   pluralType];

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
    for (NSIndexPath *indexPath in sortedIndexPaths) {
        [selectedTexts addObject:self.items[indexPath.row]];
    }

    if (self.removeSelectedItemsBlock) {
        self.removeSelectedItemsBlock([selectedTexts copy]);
    } else if (self.removeItemBlock) {
        for (NSString *text in selectedTexts) {
            self.removeItemBlock(text);
        }
    }

    for (NSIndexPath *indexPath in sortedIndexPaths) {
        [self.items removeObjectAtIndex:indexPath.row];
    }

    [self.tableView deleteRowsAtIndexPaths:sortedIndexPaths
                          withRowAnimation:UITableViewRowAnimationAutomatic];

    if (self.toolbarItems.count >= 2) {
        UIBarButtonItem *deleteButton = self.toolbarItems[1];
        deleteButton.enabled = NO;
    }
}

#pragma mark - Edit Mode

- (BOOL)tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
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

        NSString *item = self.items[indexPath.row];

        if (self.removeItemBlock) {
            self.removeItemBlock(item);
        }

        [self.items removeObjectAtIndex:indexPath.row];

        [tableView deleteRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
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

    if (indexPath.row < 0 || indexPath.row >= self.items.count) {
        return;
    }

    NSString *text = self.items[indexPath.row];

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
