#import "ListViewController.h"

@class LVTextCell;

@interface ListViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>
@property (nonatomic, copy) NSString *currentInputPlaceholder;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *filteredItems;
@property (nonatomic, assign) BOOL hasAppliedInitialSearchBarOffset;
@property (nonatomic, assign) CGFloat initialTableViewOffsetY;
@property (nonatomic, strong) LVTextCell *sizingCell;

- (void)addButtonTapped;
- (void)goBack;
- (void)editButtonTapped;
- (void)updateSelectionUIForCurrentState;
- (void)loadItemsFromSourceIfNeeded;
- (void)reloadListDataForCurrentState;
- (void)refreshListUIForCurrentState;

- (void)showToastWithMessage:(NSString *)message;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
@end
