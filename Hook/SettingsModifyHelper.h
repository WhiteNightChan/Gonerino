#import <Foundation/Foundation.h>

@interface SettingsModifyHelper : NSObject

+ (NSString *)deleteChannelAtIndex:(NSInteger)index;
+ (NSArray<NSString *> *)deleteChannelsAtIndexes:(NSArray<NSNumber *> *)indexes;
+ (NSString *)editChannelAtIndex:(NSInteger)index newText:(NSString *)newText;
+ (void)moveChannelFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)addChannelWithText:(NSString *)text;

+ (NSString *)deleteWordAtIndex:(NSInteger)index;
+ (NSArray<NSString *> *)deleteWordsAtIndexes:(NSArray<NSNumber *> *)indexes;
+ (NSString *)editWordAtIndex:(NSInteger)index newText:(NSString *)newText;
+ (void)moveWordFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)addWordWithText:(NSString *)text;

@end
