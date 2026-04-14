#import "SettingsModifyHelper.h"
#import "Settings.h"

@implementation SettingsModifyHelper

+ (NSString *)deleteChannelAtIndex:(NSInteger)index {
    NSMutableArray<NSString *> *updatedChannels =
        [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
    if (!updatedChannels) {
        updatedChannels = [NSMutableArray array];
    }

    if (index < 0 || index >= updatedChannels.count) {
        return nil;
    }

    NSString *deletedText = updatedChannels[index];
    [updatedChannels removeObjectAtIndex:index];
    [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];

    return deletedText;
}

+ (NSArray<NSString *> *)deleteChannelsAtIndexes:(NSArray<NSNumber *> *)indexes {
    NSMutableArray<NSString *> *updatedChannels =
        [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
    if (!updatedChannels) {
        updatedChannels = [NSMutableArray array];
    }

    NSMutableArray<NSString *> *deletedTexts = [NSMutableArray array];

    NSArray<NSNumber *> *sortedIndexes =
        [indexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            if (obj1.integerValue > obj2.integerValue) return NSOrderedAscending;
            if (obj1.integerValue < obj2.integerValue) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    for (NSNumber *targetIndex in sortedIndexes) {
        NSInteger row = [targetIndex integerValue];
        if (row < 0 || row >= updatedChannels.count) {
            continue;
        }

        NSString *deletedText = updatedChannels[row];
        [deletedTexts addObject:deletedText];
        [updatedChannels removeObjectAtIndex:row];
    }

    [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];

    return [deletedTexts copy];
}

+ (NSString *)editChannelAtIndex:(NSInteger)index newText:(NSString *)newText {
    NSMutableArray<NSString *> *updatedChannels =
        [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
    if (!updatedChannels) {
        updatedChannels = [NSMutableArray array];
    }

    if (index < 0 || index >= updatedChannels.count) {
        return nil;
    }

    NSString *oldText = updatedChannels[index];
    updatedChannels[index] = newText;
    [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];

    return oldText;
}

+ (void)moveChannelFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSMutableArray<NSString *> *updatedChannels =
        [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
    if (!updatedChannels) {
        return;
    }

    if (fromIndex < 0 || toIndex < 0 ||
        fromIndex >= updatedChannels.count ||
        toIndex >= updatedChannels.count) {
        return;
    }

    NSString *item = updatedChannels[fromIndex];
    [updatedChannels removeObjectAtIndex:fromIndex];
    [updatedChannels insertObject:item atIndex:toIndex];

    [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];
}

+ (void)addChannelWithText:(NSString *)text {
    [[ChannelManager sharedInstance] addBlockedChannel:text];
}

+ (NSString *)deleteWordAtIndex:(NSInteger)index {
    NSMutableArray<NSString *> *updatedWords =
        [[[WordManager sharedInstance] blockedWords] mutableCopy];
    if (!updatedWords) {
        updatedWords = [NSMutableArray array];
    }

    if (index < 0 || index >= updatedWords.count) {
        return nil;
    }

    NSString *deletedText = updatedWords[index];
    [updatedWords removeObjectAtIndex:index];
    [[WordManager sharedInstance] setBlockedWords:updatedWords];

    return deletedText;
}

+ (NSArray<NSString *> *)deleteWordsAtIndexes:(NSArray<NSNumber *> *)indexes {
    NSMutableArray<NSString *> *updatedWords =
        [[[WordManager sharedInstance] blockedWords] mutableCopy];
    if (!updatedWords) {
        updatedWords = [NSMutableArray array];
    }

    NSMutableArray<NSString *> *deletedTexts = [NSMutableArray array];

    NSArray<NSNumber *> *sortedIndexes =
        [indexes sortedArrayUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
            if (obj1.integerValue > obj2.integerValue) return NSOrderedAscending;
            if (obj1.integerValue < obj2.integerValue) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    for (NSNumber *targetIndex in sortedIndexes) {
        NSInteger row = [targetIndex integerValue];
        if (row < 0 || row >= updatedWords.count) {
            continue;
        }

        NSString *deletedText = updatedWords[row];
        [deletedTexts addObject:deletedText];
        [updatedWords removeObjectAtIndex:row];
    }

    [[WordManager sharedInstance] setBlockedWords:updatedWords];

    return [deletedTexts copy];
}

+ (NSString *)editWordAtIndex:(NSInteger)index newText:(NSString *)newText {
    NSMutableArray<NSString *> *updatedWords =
        [[[WordManager sharedInstance] blockedWords] mutableCopy];
    if (!updatedWords) {
        updatedWords = [NSMutableArray array];
    }

    if (index < 0 || index >= updatedWords.count) {
        return nil;
    }

    NSString *oldText = updatedWords[index];
    updatedWords[index] = newText;
    [[WordManager sharedInstance] setBlockedWords:updatedWords];

    return oldText;
}

+ (void)moveWordFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSMutableArray<NSString *> *updatedWords =
        [[[WordManager sharedInstance] blockedWords] mutableCopy];
    if (!updatedWords) {
        return;
    }

    if (fromIndex < 0 || toIndex < 0 ||
        fromIndex >= updatedWords.count ||
        toIndex >= updatedWords.count) {
        return;
    }

    NSString *item = updatedWords[fromIndex];
    [updatedWords removeObjectAtIndex:fromIndex];
    [updatedWords insertObject:item atIndex:toIndex];

    [[WordManager sharedInstance] setBlockedWords:updatedWords];
}

+ (void)addWordWithText:(NSString *)text {
    [[WordManager sharedInstance] addBlockedWord:text];
}

@end
