#import "LVResolveHelper.h"
#import "LVPrivate.h"

@implementation ListViewController (LVResolveHelper)

#pragma mark - Resolve

- (NSString *)resolvedTextForOriginalIndex:(NSInteger)originalIndex {
    if (originalIndex < 0 || originalIndex >= self.items.count) {
        return nil;
    }

    id item = self.items[originalIndex];
    if (![item isKindOfClass:[NSString class]]) {
        return nil;
    }

    return (NSString *)item;
}

- (NSString *)resolvedTextForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return nil;
    }

    NSInteger originalIndex = [self resolvedOriginalIndexForIndexPath:indexPath];
    if (originalIndex == NSNotFound) {
        return nil;
    }

    return [self resolvedTextForOriginalIndex:originalIndex];
}

- (NSInteger)resolvedOriginalIndexForIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath) {
        return NSNotFound;
    }

    if (self.isSearching) {
        if (indexPath.row < 0 || indexPath.row >= self.filteredItems.count) {
            return NSNotFound;
        }

        id filteredItem = self.filteredItems[indexPath.row];
        if (![filteredItem isKindOfClass:[NSNumber class]]) {
            return NSNotFound;
        }

        NSInteger resolvedIndex = [(NSNumber *)filteredItem integerValue];
        if (resolvedIndex < 0 || resolvedIndex >= self.items.count) {
            return NSNotFound;
        }

        return resolvedIndex;
    }

    if (indexPath.row < 0 || indexPath.row >= self.items.count) {
        return NSNotFound;
    }

    id item = self.items[indexPath.row];
    if (![item isKindOfClass:[NSString class]]) {
        return NSNotFound;
    }

    return indexPath.row;
}

- (NSArray<NSString *> *)resolvedTextsForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *texts = [NSMutableArray array];

    for (NSIndexPath *indexPath in indexPaths) {
        NSString *text = [self resolvedTextForIndexPath:indexPath];
        if ([text isKindOfClass:[NSString class]]) {
            [texts addObject:text];
        }
    }

    return [texts copy];
}

- (NSArray<NSNumber *> *)resolvedOriginalIndexesForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (indexPaths.count == 0) {
        return @[];
    }

    NSMutableArray<NSNumber *> *originalIndexes = [NSMutableArray array];

    for (NSIndexPath *indexPath in indexPaths) {
        NSInteger originalIndex = [self resolvedOriginalIndexForIndexPath:indexPath];
        if (originalIndex != NSNotFound) {
            [originalIndexes addObject:@(originalIndex)];
        }
    }

    return [originalIndexes copy];
}

@end
