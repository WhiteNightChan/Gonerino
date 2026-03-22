#import "LVTextCell.h"

@interface LVTextCell ()

@property (nonatomic, strong) UILabel *itemLabel;

@end

@implementation LVTextCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    if (self) {
        _itemLabel = [UILabel new];
        _itemLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _itemLabel.numberOfLines = 0;
        _itemLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _itemLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _itemLabel.textColor = UIColor.whiteColor;
        _itemLabel.backgroundColor = UIColor.clearColor;

        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        UIView *selectedView = [UIView new];
        selectedView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.12];
        selectedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.selectedBackgroundView = selectedView;

        UIView *multipleSelectedView = [UIView new];
        multipleSelectedView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
        multipleSelectedView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.multipleSelectionBackgroundView = multipleSelectedView;

        [self.contentView addSubview:_itemLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_itemLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor
                                                 constant:10],
            [_itemLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor
                                                    constant:-10],
            [_itemLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor
                                                     constant:16.25],
            [_itemLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor
                                                      constant:-16.25]
        ]];
    }

    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.itemLabel.text = nil;
}

- (void)configureWithText:(NSString *)text {
    self.itemLabel.text = text;
}

@end
