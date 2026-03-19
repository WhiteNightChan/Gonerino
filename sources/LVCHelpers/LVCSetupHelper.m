#import "LVCHelpers/LVCSetupHelper.h"
#import "LVCHelpers/LVCPrivate.h"

@implementation ListViewController (LVCSetupHelper)

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

- (UIBarButtonItem *)addBarButtonItem {
    UIBarButtonItem *addButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                      target:self
                                                      action:@selector(addButtonTapped)];
    addButton.tintColor = [UIColor whiteColor];

    return addButton;
}

- (UIBarButtonItem *)editBarButtonItemForEditing:(BOOL)editing {
    UIBarButtonItem *editButton =
        [[UIBarButtonItem alloc] initWithTitle:(editing ? @"Done" : @"Edit")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(editButtonTapped)];
    editButton.tintColor = [UIColor whiteColor];

    return editButton;
}

- (NSArray<UIBarButtonItem *> *)rightBarButtonItemsForEditing:(BOOL)editing {
    UIBarButtonItem *rightSpace = [self fixedSpaceBarButtonItemWithWidth:10];
    UIBarButtonItem *editButton = [self editBarButtonItemForEditing:editing];

    if (editing) {
        return @[rightSpace, editButton];
    }

    UIBarButtonItem *addButton = [self addBarButtonItem];

    return @[rightSpace, editButton, addButton];
}

- (UIView *)configuredTitleView {
    UIView *customTitleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 44)];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(-80, 0, 150, 44)];
    titleLabel.text = self.titleText;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont fontWithName:@"YouTubeSans-Bold" size:19];
    titleLabel.textAlignment = NSTextAlignmentLeft;

    [customTitleView addSubview:titleLabel];

    return customTitleView;
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

@end
