#import "ListViewController.h"

@interface ListViewController (LVResolveHelper)
- (NSDictionary *)resolvedEntryForIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSDictionary *> *)resolvedEntriesForSelectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
@end
