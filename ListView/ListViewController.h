#import <UIKit/UIKit.h>

@interface ListViewController : UITableViewController

@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, copy) NSString *itemType;

@property (nonatomic, copy) NSArray *(^loadItemsBlock)(void);
@property (nonatomic, copy) void (^removeItemAtIndexBlock)(NSInteger index);
@property (nonatomic, copy) void (^removeItemsAtIndexesBlock)(NSArray<NSNumber *> *indexes);
@property (nonatomic, copy) void (^moveItemBlock)(NSInteger fromIndex, NSInteger toIndex);
@property (nonatomic, copy) void (^addItemBlock)(NSString *text);
@property (nonatomic, copy) void (^editItemBlock)(NSInteger index, NSString *newText);

@end
