#import <UIKit/UIKit.h>

@interface ListViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) NSString *titleText;
@property (nonatomic, copy) NSString *itemType;

@property (nonatomic, copy) NSArray *(^loadItemsBlock)(void);
@property (nonatomic, copy) void (^removeItemBlock)(NSString *text);
@property (nonatomic, copy) void (^removeSelectedItemsBlock)(NSArray<NSString *> *texts);
@property (nonatomic, copy) void (^moveItemBlock)(NSInteger fromIndex, NSInteger toIndex);
@property (nonatomic, copy) void (^addItemBlock)(NSString *text);
@property (nonatomic, copy) void (^editItemBlock)(NSInteger index, NSString *oldText, NSString *newText);

@end
