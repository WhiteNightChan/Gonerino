#import "LVCHelpers/LVCInputHelper.h"
#import "LVCHelpers/LVCPrivate.h"
#import "LVCHelpers/LVCSearchHelper.h"

@implementation ListViewController (LVCInputHelper)

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

@end
