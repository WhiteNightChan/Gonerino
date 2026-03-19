#import "ListViewController.h"

@interface ListViewController () <UITextViewDelegate, UIGestureRecognizerDelegate, UISearchBarDelegate>
@property (nonatomic, copy) NSString *currentInputPlaceholder;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, copy) NSString *searchText;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *filteredItems;
@property (nonatomic, assign) BOOL hasAppliedInitialSearchBarOffset;
@property (nonatomic, assign) CGFloat initialTableViewOffsetY;

- (void)goBack;
- (void)editButtonTapped;

- (void)showToastWithMessage:(NSString *)message;
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture;
@end
