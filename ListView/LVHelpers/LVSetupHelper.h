#import "ListViewController.h"

@interface ListViewController (LVSetupHelper)
- (void)configureTableViewAppearance;
- (UISearchBar *)configuredSearchBar;
- (void)configureLongPressGesture;
- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width;
- (UIBarButtonItem *)backBarButtonItem;
- (UIBarButtonItem *)addBarButtonItem;
- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing;
- (UIBarButtonItem *)countDisplayBarButtonItemWithText:(NSString *)text;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing;
- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText;
- (UIView *)configuredTitleView;
- (void)configureToolbarItems;
@end
