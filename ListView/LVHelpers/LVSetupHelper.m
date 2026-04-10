#import "LVSetupHelper.h"
#import "LVPrivate.h"
#import "TextHelper.h"

@implementation ListViewController (LVSetupHelper)

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
    searchBar.placeholder = TextHelperSearchPlaceholder();
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchBar.smartQuotesType = UITextSmartQuotesTypeNo;
    searchBar.smartDashesType = UITextSmartDashesTypeNo;
    searchBar.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    searchBar.returnKeyType = UIReturnKeyDone;
    searchBar.showsCancelButton = NO;

    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.backgroundImage = [UIImage new];
    searchBar.backgroundColor = UIColor.clearColor;
    searchBar.barTintColor = UIColor.clearColor;
    searchBar.translucent = YES;

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
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:18.5
                                                       weight:UIImageSymbolWeightLight];
    UIImage *arrow = [[UIImage systemImageNamed:@"chevron.left"
                               withConfiguration:config]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [button setImage:arrow forState:UIControlStateNormal];
    button.tintColor = [UIColor labelColor];
    button.frame = CGRectMake(0, 0, 42, 44);
    [button addTarget:self
               action:@selector(goBack)
     forControlEvents:UIControlEventTouchUpInside];

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 42, 44)];
    [container addSubview:button];

    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)textBarButtonItemWithTitle:(NSString *)title
                                      textColor:(UIColor *)textColor
                                     fontWeight:(UIFontWeight)fontWeight
                                         target:(id)target
                                         action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title ?: @"" forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:fontWeight];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    [button sizeToFit];

    CGRect buttonFrame = button.frame;
    buttonFrame.size.width = ceil(CGRectGetWidth(buttonFrame));
    buttonFrame.size.height = 32.0;
    button.frame = buttonFrame;

    if (target && action) {
        [button addTarget:target
                   action:action
         forControlEvents:UIControlEventTouchUpInside];
    } else {
        button.userInteractionEnabled = NO;
    }

    UIView *container =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                 CGRectGetWidth(buttonFrame),
                                                 32.0)];
    container.userInteractionEnabled = target != nil;
    [container addSubview:button];

    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)symbolBarButtonItemWithSystemName:(NSString *)systemName
                                             tintColor:(UIColor *)tintColor
                                                target:(id)target
                                                action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 22.5, 32.0);

    UIImageSymbolConfiguration *config =
        [UIImageSymbolConfiguration configurationWithPointSize:17.0
                                                       weight:UIImageSymbolWeightRegular];
    UIImage *image = [[UIImage systemImageNamed:systemName
                               withConfiguration:config]
                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    [button setImage:image forState:UIControlStateNormal];
    button.tintColor = tintColor;
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    [button addTarget:target
               action:action
     forControlEvents:UIControlEventTouchUpInside];

    UIView *container = [[UIView alloc] initWithFrame:button.bounds];
    [container addSubview:button];

    return [[UIBarButtonItem alloc] initWithCustomView:container];
}

- (UIBarButtonItem *)addBarButtonItem {
    return [self symbolBarButtonItemWithSystemName:@"plus"
                                         tintColor:[UIColor labelColor]
                                            target:self
                                            action:@selector(addButtonTapped)];
}

- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing {
    return [self textBarButtonItemWithTitle:TextHelperEditButtonTitle(editing)
                                  textColor:[UIColor labelColor]
                                 fontWeight:UIFontWeightRegular
                                     target:self
                                     action:@selector(editButtonTapped)];
}

- (UIBarButtonItem *)selectAllToolbarButtonItemWithTitle:(NSString *)title {
    UIBarButtonItem *selectAllButton =
        [[UIBarButtonItem alloc] initWithTitle:title
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(selectAllToolbarButtonTapped)];
    selectAllButton.tintColor = [UIColor systemBlueColor];

    return selectAllButton;
}

- (void)configureToolbarItems {
    UIBarButtonItem *selectAllButton =
        [self selectAllToolbarButtonItemWithTitle:TextHelperSelectAllToolbarTitle(NO)];

    UIBarButtonItem *flexibleSpace =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    UIBarButtonItem *deleteButton =
        [[UIBarButtonItem alloc] initWithTitle:TextHelperDeleteToolbarTitle()
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(deleteSelectedItemsTapped)];

    deleteButton.tintColor = [UIColor systemRedColor];
    selectAllButton.enabled = NO;
    deleteButton.enabled = NO;

    self.toolbarItems = @[selectAllButton, flexibleSpace, deleteButton];
}

@end
