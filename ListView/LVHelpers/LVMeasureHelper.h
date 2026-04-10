#import "ListViewController.h"

@class LVTextCell;

@interface ListViewController (LVMeasureHelper)
- (LVTextCell *)estimatedSizingCell;
- (CGFloat)estimatedHeightForDisplayText:(NSString *)text
                               tableView:(UITableView *)tableView;
@end
