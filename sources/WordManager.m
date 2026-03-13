#import "WordManager.h"

@interface WordManager ()
@property(nonatomic, strong) NSMutableSet<NSString *> *blockedWordSet;
@end

@implementation WordManager

+ (instancetype)sharedInstance {
    static WordManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _blockedWordSet = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"GonerinoBlockedWords"] mutableCopy]
                              ?: [NSMutableSet set];
    }
    return self;
}

- (NSArray<NSString *> *)blockedWords {
    return [self.blockedWordSet allObjects];
}

- (void)addBlockedWord:(NSString *)word {
    if (word.length > 0) {
        [self.blockedWordSet addObject:word];
        [self saveBlockedWords];
    }
}

- (void)removeBlockedWord:(NSString *)word {
    if (word) {
        [self.blockedWordSet removeObject:word];
        [self saveBlockedWords];
    }
}

- (BOOL)isWordBlocked:(NSString *)text {
    for (NSString *word in self.blockedWordSet) {
        if ([word hasPrefix:@"/"] && [word containsString:@"/"]) {
            NSRange lastSlash = [word rangeOfString:@"/" options:NSBackwardsSearch];
            if (lastSlash.location == NSNotFound || lastSlash.location == 0) continue;

            NSString *pattern = [word substringWithRange:NSMakeRange(1, lastSlash.location - 1)];
            NSString *optionsStr = [word substringFromIndex:lastSlash.location + 1];

            NSRegularExpressionOptions options = 0;
            if ([optionsStr containsString:@"i"]) options |= NSRegularExpressionCaseInsensitive;
            if ([optionsStr containsString:@"m"]) options |= NSRegularExpressionAnchorsMatchLines;
            if ([optionsStr containsString:@"s"]) options |= NSRegularExpressionDotMatchesLineSeparators;

            NSError *error = nil;
            NSRegularExpression *regex =
                [NSRegularExpression regularExpressionWithPattern:pattern
                                                          options:options
                                                            error:&error];
            if (!error && [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)]) {
                return YES;
            }
        } else {
            if ([text.lowercaseString containsString:word.lowercaseString]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)saveBlockedWords {
    [[NSUserDefaults standardUserDefaults] setObject:[self.blockedWordSet allObjects] forKey:@"GonerinoBlockedWords"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setBlockedWords:(NSArray<NSString *> *)words {
    self.blockedWordSet = [NSMutableSet setWithArray:words];
    [self saveBlockedWords];
}

@end
