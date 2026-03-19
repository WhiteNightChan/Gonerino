#import "ListViewController.h"

@interface ListViewController (LVCInputHelper)
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
@end
