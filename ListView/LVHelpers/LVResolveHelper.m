#import "LVResolveHelper.h"
#import "LVPrivate.h"

@implementation ListViewController (LVResolveHelper)

#pragma mark - Resolve

- (NSDictionary *)resolvedEntryForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }

    if (self.isSearching) {
        if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
            return nil;
        }

        NSDictionary *entry = self.filteredItems[indexPath.row];
        NSString *text = entry[@"text"];
        NSNumber *originalIndex = entry[@"originalIndex"];

        if (![text isKindOfClass:[NSString class]] ||
            ![originalIndex isKindOfClass:[NSNumber class]]) {
            return nil;
        }

        NSInteger resolvedIndex = [originalIndex integerValue];
        if (resolvedIndex < 0 || resolvedIndex >= self.items.count) {
            return nil;
        }

        return @{
            @"text": text,
            @"originalIndex": originalIndex
        };
    }

    if (indexPath.row < 0 || indexPath.row >= self.items.count) {
        return nil;
    }

    NSString *text = self.items[indexPath.row];
    if (![text isKindOfClass:[NSString class]]) {
        return nil;
    }

    return @{
        @"text": text,
        @"originalIndex": @(indexPath.row)
    };
}

- (NSArray<NSDictionary *> *)resolvedEntriesForSelectedIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) {
        return @[];
    }

    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];

    for (NSIndexPath *indexPath in indexPaths) {
        NSDictionary *entry = [self resolvedEntryForIndexPath:indexPath];
        if (entry) {
            [entries addObject:entry];
        }
    }

    return [entries copy];
}

@end
