#import "ChannelManager.h"

@interface ChannelManager ()
@property(nonatomic, strong) NSMutableSet<NSString *> *blockedChannelSet;
@end

@implementation ChannelManager

+ (instancetype)sharedInstance {
    static ChannelManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _blockedChannelSet =
            [[[NSUserDefaults standardUserDefaults] arrayForKey:@"GonerinoBlockedChannels"] mutableCopy]
                ?: [NSMutableSet set];
    }
    return self;
}

- (NSArray<NSString *> *)blockedChannels {
    return [self.blockedChannelSet allObjects];
}

- (void)addBlockedChannel:(NSString *)channelName {
    if (channelName.length > 0) {
        [self.blockedChannelSet addObject:channelName];
        [self saveBlockedChannels];
    }
}

- (void)removeBlockedChannel:(NSString *)channelName {
    if (channelName) {
        [self.blockedChannelSet removeObject:channelName];
        [self saveBlockedChannels];
    }
}

- (BOOL)isChannelBlocked:(NSString *)channelName {
    for (NSString *channel in self.blockedChannelSet) {
        if ([channel hasPrefix:@"/"] && [channel containsString:@"/"]) {
            NSRange lastSlash = [channel rangeOfString:@"/" options:NSBackwardsSearch];
            if (lastSlash.location == NSNotFound || lastSlash.location == 0) continue;

            NSString *pattern = [channel substringWithRange:NSMakeRange(1, lastSlash.location - 1)];
            NSString *optionsStr = [channel substringFromIndex:lastSlash.location + 1];

            NSRegularExpressionOptions options = 0;
            if ([optionsStr containsString:@"i"]) options |= NSRegularExpressionCaseInsensitive;
            if ([optionsStr containsString:@"m"]) options |= NSRegularExpressionAnchorsMatchLines;
            if ([optionsStr containsString:@"s"]) options |= NSRegularExpressionDotMatchesLineSeparators;

            NSError *error = nil;
            NSRegularExpression *regex =
                [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:options
                                                            error:&error];
            if (!error && [regex firstMatchInString:channelName options:0 range:NSMakeRange(0, channelName.length)]) {
                return YES;
            }
        } else {
            if ([channelName isEqualToString:channel]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)saveBlockedChannels {
    [[NSUserDefaults standardUserDefaults] setObject:[self.blockedChannelSet allObjects]
                                              forKey:@"GonerinoBlockedChannels"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setBlockedChannels:(NSArray<NSString *> *)channels {
    self.blockedChannelSet = [NSMutableSet setWithArray:channels];
    [self saveBlockedChannels];
}

@end
