#import "ListViewController.h"

@interface ListViewController (LVCResolveHelper)
- (NSDictionary *)resolvedEntryForIndexPath:(NSIndexPath *)indexPath;
- (NSArray<NSDictionary *> *)resolvedEntriesForSelectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
@end
