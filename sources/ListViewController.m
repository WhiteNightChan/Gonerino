#import "ListViewController.h"

@implementation ListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.titleText;

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

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self handleItemSelectionAtIndex:indexPath.row];
}

- (void)handleItemSelectionAtIndex:(NSInteger)index {

}

@end
