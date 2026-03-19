#import "ListViewController.h"

@interface ListViewController (LVCSetupHelper)
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
@end
