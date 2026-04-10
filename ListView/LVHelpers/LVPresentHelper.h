#import "ListViewController.h"

@interface ListViewController (LVPresentHelper)
- (BOOL)shouldShowSearchBar;
- (UILabel *)emptyStateLabelWithText:(NSString *)text;
- (void)updateSearchBarVisibilityIfNeeded;
- (NSInteger)currentVisibleItemCount;
- (NSString *)currentCountDisplayText;
- (void)updateRightBarButtonItemsForCurrentState;
- (UIBarButtonItem *)titleBarButtonItem;
- (UIBarButtonItem *)countDisplayBarButtonItemWithText:(NSString *)text;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText;
@end
