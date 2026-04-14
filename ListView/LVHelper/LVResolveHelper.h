#import "ListViewController.h"

@interface ListViewController (LVResolveHelper)
- (NSString *)resolvedTextForOriginalIndex:(NSInteger)originalIndex;
- (NSString *)resolvedTextForIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)resolvedOriginalIndexForIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSString *> *)resolvedTextsForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
- (NSArray<NSNumber *> *)resolvedOriginalIndexesForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
@end
