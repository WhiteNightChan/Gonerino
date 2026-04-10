#import "LVMeasureHelper.h"
#import "LVPrivate.h"
#import "LVTextCell.h"

@implementation ListViewController (LVMeasureHelper)

#pragma mark - Measure

- (LVTextCell *)estimatedSizingCell {
    if (!self.sizingCell) {
        self.sizingCell =
            [[LVTextCell alloc] initWithStyle:UITableViewCellStyleDefault
                              reuseIdentifier:nil];
    }

    return self.sizingCell;
}

- (CGFloat)estimatedHeightForDisplayText:(NSString *)text
                               tableView:(UITableView *)tableView {
    CGFloat tableWidth = CGRectGetWidth(tableView.bounds);
    if (tableWidth <= 0.0) {
        return 44.0;
    }

    LVTextCell *cell = [self estimatedSizingCell];
    [cell configureWithText:text ?: @""];

    [cell setEditing:tableView.editing animated:NO];

    cell.bounds = CGRectMake(0, 0, tableWidth, CGFLOAT_MAX);
    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGSize targetSize =
        CGSizeMake(tableWidth, UILayoutFittingCompressedSize.height);

    CGFloat height =
        [cell.contentView systemLayoutSizeFittingSize:targetSize
                 withHorizontalFittingPriority:UILayoutPriorityRequired
                       verticalFittingPriority:UILayoutPriorityFittingSizeLevel].height;

    return MAX(height, 1.0);
}

@end
