#import "LVSetupHelper.h"
#import "LVPrivate.h"

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
    searchBar.placeholder = @"Search";
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

- (CGFloat)rightBarTrailingSlotWidth {
    UILabel *sizingLabel = [UILabel new];
    sizingLabel.text = @"XXXX items";
    sizingLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    [sizingLabel sizeToFit];

    return ceil(CGRectGetWidth(sizingLabel.bounds));
}

- (CGFloat)rightBarEditSlotWidth {
    UILabel *sizingLabel = [UILabel new];
    sizingLabel.text = @"Done";
    sizingLabel.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    [sizingLabel sizeToFit];

    return ceil(CGRectGetWidth(sizingLabel.bounds));
}

- (UIBarButtonItem *)fixedWidthTextBarButtonItemWithTitle:(NSString *)title
                                                textColor:(UIColor *)textColor
                                               fontWeight:(UIFontWeight)fontWeight
                                                    width:(CGFloat)width
                                                   target:(id)target
                                                   action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, width, 32.0);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:17.0 weight:fontWeight];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;

    if (target && action) {
        [button addTarget:target
                   action:action
         forControlEvents:UIControlEventTouchUpInside];
    } else {
        button.userInteractionEnabled = NO;
    }

    UIView *container = [[UIView alloc] initWithFrame:button.bounds];
    container.userInteractionEnabled = target != nil;
    [container addSubview:button];

    UIBarButtonItem *item =
        [[UIBarButtonItem alloc] initWithCustomView:container];

    return item;
}

- (UIBarButtonItem *)fixedWidthSymbolBarButtonItemWithSystemName:(NSString *)systemName
                                                       tintColor:(UIColor *)tintColor
                                                           width:(CGFloat)width
                                                          target:(id)target
                                                          action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, width, 32.0);

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

    UIBarButtonItem *item =
        [[UIBarButtonItem alloc] initWithCustomView:container];

    return item;
}

- (CGFloat)rightBarAddSlotWidth {
    return 28.0;
}

- (UIBarButtonItem *)fixedWidthPlaceholderBarButtonItemWithWidth:(CGFloat)width {
    UIView *placeholderView =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 32.0)];
    placeholderView.userInteractionEnabled = NO;

    UIBarButtonItem *placeholderItem =
        [[UIBarButtonItem alloc] initWithCustomView:placeholderView];

    return placeholderItem;
}

- (UIBarButtonItem *)addBarButtonItem {
    return [self fixedWidthSymbolBarButtonItemWithSystemName:@"plus"
                                                   tintColor:[UIColor whiteColor]
                                                       width:[self rightBarAddSlotWidth]
                                                      target:self
                                                      action:@selector(addButtonTapped)];
}

- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing {
    return [self fixedWidthTextBarButtonItemWithTitle:(editing ? @"Done" : @"Edit")
                                            textColor:[UIColor whiteColor]
                                           fontWeight:UIFontWeightRegular
                                                width:[self rightBarEditSlotWidth]
                                               target:self
                                               action:@selector(editButtonTapped)];
}

- (UIBarButtonItem *)countDisplayBarButtonItemWithText:(NSString *)text {
    return [self fixedWidthTextBarButtonItemWithTitle:text
                                            textColor:[UIColor whiteColor]
                                           fontWeight:UIFontWeightMedium
                                                width:[self rightBarTrailingSlotWidth]
                                               target:nil
                                               action:nil];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing {
    return [self rightBarButtonItemsForEditing:editing countDisplayText:@"0"];
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing
                                             countDisplayText:(NSString *)countDisplayText {
    UIBarButtonItem *rightSpace = [self fixedSpaceBarButtonItemWithWidth:10];
    UIBarButtonItem *editButton = [self editBarButtonItemForEditing:editing];
    UIBarButtonItem *countDisplayButton =
        [self countDisplayBarButtonItemWithText:countDisplayText];

    if (editing) {
        UIBarButtonItem *addPlaceholderButton =
            [self fixedWidthPlaceholderBarButtonItemWithWidth:[self rightBarAddSlotWidth]];

        return @[rightSpace, editButton, countDisplayButton, addPlaceholderButton];
    }

    UIBarButtonItem *addButton = [self addBarButtonItem];

    return @[rightSpace, editButton, addButton, countDisplayButton];
}

- (UIView *)configuredTitleView {
    UIView *customTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 174, 44)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 174, 44)];
    titleLabel.text = self.titleText;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:20];
    titleLabel.textAlignment = NSTextAlignmentLeft;

    [customTitleView addSubview:titleLabel];

    return customTitleView;
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
        [self selectAllToolbarButtonItemWithTitle:@"Select All"];

    UIBarButtonItem *flexibleSpace =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                      target:nil
                                                      action:nil];

    UIBarButtonItem *deleteButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(deleteSelectedItemsTapped)];

    deleteButton.tintColor = [UIColor systemRedColor];
    selectAllButton.enabled = NO;
    deleteButton.enabled = NO;

    self.toolbarItems = @[selectAllButton, flexibleSpace, deleteButton];
}

@end
