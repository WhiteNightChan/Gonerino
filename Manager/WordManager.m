#import "WordManager.h"

@interface WordManager ()
@property(nonatomic, strong) NSMutableArray<NSString *> *blockedWordArray;
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
        NSArray *saved =
            [[NSUserDefaults standardUserDefaults] arrayForKey:@"GonerinoBlockedWords"];
        _blockedWordArray =
            saved ? [saved mutableCopy] : [NSMutableArray array];
    }
    return self;
}

- (NSArray<NSString *> *)blockedWords {
    return [self.blockedWordArray copy];
}

- (void)addBlockedWord:(NSString *)word {
    if (word.length > 0 && ![self.blockedWordArray containsObject:word]) {
        [self.blockedWordArray addObject:word];
        [self saveBlockedWords];
    }
}

- (void)removeBlockedWord:(NSString *)word {
    if (word) {
        [self.blockedWordArray removeObject:word];
        [self saveBlockedWords];
    }
}

- (BOOL)isWordBlocked:(NSString *)text {
    for (NSString *word in self.blockedWordArray) {
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
    [[NSUserDefaults standardUserDefaults] setObject:self.blockedWordArray
                                              forKey:@"GonerinoBlockedWords"];
}

- (void)setBlockedWords:(NSArray<NSString *> *)words {
    self.blockedWordArray = [words mutableCopy];
    [self saveBlockedWords];
}

@end
