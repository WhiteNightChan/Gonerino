#import "ListViewController.h"

@interface ListViewController (LVSetupHelper)
- (void)configureTableViewAppearance;
- (UISearchBar *)configuredSearchBar;
- (void)configureLongPressGesture;
- (UIBarButtonItem *)fixedSpaceBarButtonItemWithWidth:(CGFloat)width;
- (UIBarButtonItem *)backBarButtonItem;
- (UIBarButtonItem *)textBarButtonItemWithTitle:(NSString *)title
                                      textColor:(UIColor *)textColor
                                     fontWeight:(UIFontWeight)fontWeight
                                         target:(id)target
                                         action:(SEL)action;
- (UIBarButtonItem *)addBarButtonItem;
- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing;
- (void)configureToolbarItems;
@end
