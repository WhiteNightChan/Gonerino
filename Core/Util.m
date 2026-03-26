#import "Util.h"
#import "ChannelManager.h"
#import "VideoManager.h"

// Add forward declarations for missing interfaces
@interface YTElementsInlineMutedPlaybackView : NSObject
@property(retain, nonatomic) id asdPlayableEntry;
@end

@interface ASTextNode : NSObject
@property(nonatomic, copy, nullable) NSAttributedString *attributedText;
@end

// Add category for node methods
@interface NSObject (NodeMethods)
- (nullable NSString *)channelName;
- (nullable NSString *)ownerName;
- (nullable NSArray *)subnodes;
- (nullable NSString *)accessibilityLabel;
- (nullable id)supernode;
- (nullable id)parentNode;
@end

static id GonerinoSafeProtoValue(id obj, NSString *key) {
    if (!obj || key.length == 0) {
        return nil;
    }

    @try {
        id value = [obj valueForKey:key];
        if (value) {
            return value;
        }
    } @catch (NSException *exception) {
    }

    SEL sel = NSSelectorFromString(key);
    if ([obj respondsToSelector:sel]) {
        @try {
            IMP imp = [obj methodForSelector:sel];
            if (imp) {
                id (*func)(id, SEL) = (id (*)(id, SEL))imp;
                return func(obj, sel);
            }
        } @catch (NSException *exception) {
        }
    }

    return nil;
}

static NSString *GonerinoSafeProtoStringValue(id obj, NSString *key) {
    id value = GonerinoSafeProtoValue(obj, key);
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    return nil;
}

@implementation Util

+ (NSDictionary *)videoInfoFromDescriptionString:(NSString *)descriptionString {
    if (descriptionString.length == 0) {
        return nil;
    }

    NSError *error       = nil;
    NSString *videoId    = nil;
    NSString *videoTitle = nil;
    NSString *ownerName  = nil;

    NSArray *patterns = @[
        @"video_id: \"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"",
        @"video_title: \"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\"",
        @"owner_display_name: \"([^\"\\\\]*(?:\\\\.[^\"\\\\]*)*)\""
    ];

    for (NSString *pattern in patterns) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0
                                                                                 error:&error];
        if (error) {
            NSLog(@"[Gonerino] Regex error for pattern %@: %@", pattern, error);
            continue;
        }

        NSTextCheckingResult *match = [regex firstMatchInString:descriptionString
                                                        options:0
                                                          range:NSMakeRange(0, descriptionString.length)];

        if (match && match.numberOfRanges > 1) {
            NSString *value = [descriptionString substringWithRange:[match rangeAtIndex:1]];

            value = [value stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
            value = [value stringByReplacingOccurrencesOfString:@"\\'" withString:@"'"];

            if ([pattern hasPrefix:@"video_id:"]) {
                videoId = value;
            } else if ([pattern hasPrefix:@"video_title:"]) {
                videoTitle = value;
            } else if ([pattern hasPrefix:@"owner_display_name:"]) {
                ownerName = value;
            }
        }
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (videoId.length > 0) {
        result[@"videoId"] = videoId;
    }
    if (videoTitle.length > 0) {
        result[@"videoTitle"] = videoTitle;
    }
    if (ownerName.length > 0) {
        result[@"ownerName"] = ownerName;
    }

    return result.count > 0 ? result : nil;
}

+ (NSDictionary *)videoInfoFromPlayableEntry:(id)playableEntry {
    if (!playableEntry) {
        return nil;
    }

    NSString *videoId    = GonerinoSafeProtoStringValue(playableEntry, @"videoId");
    NSString *videoTitle = GonerinoSafeProtoStringValue(playableEntry, @"videoTitle");
    NSString *ownerName  = GonerinoSafeProtoStringValue(playableEntry, @"ownerDisplayName");

    id navigationEndpoint     = GonerinoSafeProtoValue(playableEntry, @"navigationEndpoint");    
    id inlinePlaybackEndpoint = GonerinoSafeProtoValue(playableEntry, @"inlinePlaybackEndpoint");

    if (videoId.length == 0 && navigationEndpoint) {
        videoId = GonerinoSafeProtoStringValue(navigationEndpoint, @"videoId");
    }
    if (videoTitle.length == 0 && navigationEndpoint) {
        videoTitle = GonerinoSafeProtoStringValue(navigationEndpoint, @"videoTitle");
    }
    if (ownerName.length == 0 && navigationEndpoint) {
        ownerName = GonerinoSafeProtoStringValue(navigationEndpoint, @"ownerDisplayName");
    }

    if (videoId.length == 0 && inlinePlaybackEndpoint) {
        videoId = GonerinoSafeProtoStringValue(inlinePlaybackEndpoint, @"videoId");
    }
    if (videoTitle.length == 0 && inlinePlaybackEndpoint) {
        videoTitle = GonerinoSafeProtoStringValue(inlinePlaybackEndpoint, @"videoTitle");
    }
    if (ownerName.length == 0 && inlinePlaybackEndpoint) {
        ownerName = GonerinoSafeProtoStringValue(inlinePlaybackEndpoint, @"ownerDisplayName");
    }

    if (videoId.length == 0 || videoTitle.length == 0 || ownerName.length == 0) {
        NSDictionary *endpointInfo = [self videoInfoFromDescriptionString:[navigationEndpoint description]];
        if (videoId.length == 0) {
            videoId = endpointInfo[@"videoId"];
        }
        if (videoTitle.length == 0) {
            videoTitle = endpointInfo[@"videoTitle"];
        }
        if (ownerName.length == 0) {
            ownerName = endpointInfo[@"ownerName"];
        }
    }

    if (videoId.length == 0 || videoTitle.length == 0 || ownerName.length == 0) {
        NSDictionary *inlineInfo = [self videoInfoFromDescriptionString:[inlinePlaybackEndpoint description]];
        if (videoId.length == 0) {
            videoId = inlineInfo[@"videoId"];
        }
        if (videoTitle.length == 0) {
            videoTitle = inlineInfo[@"videoTitle"];
        }
        if (ownerName.length == 0) {
            ownerName = inlineInfo[@"ownerName"];
        }
    }

    if (videoId.length == 0 || videoTitle.length == 0 || ownerName.length == 0) {
        NSDictionary *playableInfo = [self videoInfoFromDescriptionString:[playableEntry description]];
        if (videoId.length == 0) {
            videoId = playableInfo[@"videoId"];
        }
        if (videoTitle.length == 0) {
            videoTitle = playableInfo[@"videoTitle"];
        }
        if (ownerName.length == 0) {
            ownerName = playableInfo[@"ownerName"];
        }
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (videoId.length > 0) {
        result[@"videoId"] = videoId;
    }
    if (videoTitle.length > 0) {
        result[@"videoTitle"] = videoTitle;
    }
    if (ownerName.length > 0) {
        result[@"ownerName"] = ownerName;
    }

    return result.count > 0 ? result : nil;
}

+ (NSString *)fallbackOwnerNameFromNode:(id)node {
    id currentNode = node;
    NSInteger depth = 0;

    while (currentNode && depth < 10) {
        if ([currentNode respondsToSelector:@selector(ownerName)]) {
            NSString *ownerName = [currentNode ownerName];
            if (ownerName.length > 0) {
                return ownerName;
            }
        }

        if ([currentNode respondsToSelector:@selector(channelName)]) {
            NSString *channelName = [currentNode channelName];
            if (channelName.length > 0) {
                return channelName;
            }
        }

        if ([currentNode respondsToSelector:@selector(supernode)]) {
            currentNode = [currentNode supernode];
        } else if ([currentNode respondsToSelector:@selector(parentNode)]) {
            currentNode = [currentNode parentNode];
        } else {
            currentNode = nil;
        }

        depth++;
    }

    return nil;
}

+ (NSDictionary *)fallbackVideoInfoFromNodeDescriptionChain:(id)node {
    id currentNode = node;
    NSInteger depth = 0;

    while (currentNode && depth < 10) {
        NSDictionary *info = [self videoInfoFromDescriptionString:[currentNode description]];
        if (info.count > 0) {
            return info;
        }

        if ([currentNode respondsToSelector:@selector(supernode)]) {
            currentNode = [currentNode supernode];
        } else if ([currentNode respondsToSelector:@selector(parentNode)]) {
            currentNode = [currentNode parentNode];
        } else {
            currentNode = nil;
        }

        depth++;
    }

    return nil;
}

+ (UIView *)findDescendantViewInView:(UIView *)view
                           className:(NSString *)className
                            maxDepth:(NSInteger)maxDepth {
    if (!view || maxDepth < 0) {
        return nil;
    }

    if ([view isKindOfClass:NSClassFromString(className)]) {
        return view;
    }

    for (UIView *subview in view.subviews) {
        UIView *foundView = [self findDescendantViewInView:subview
                                                 className:className
                                                  maxDepth:maxDepth - 1];
        if (foundView) {
            return foundView;
        }
    }

    return nil;
}

+ (void)extractVideoInfoFromNode:(id)node
                      completion:(void (^)(NSString *videoId, NSString *videoTitle, NSString *ownerName))completion {
    if (!completion)
        return;

    if (![node isKindOfClass:NSClassFromString(@"YTInlinePlaybackPlayerNode")]) {
        completion(nil, nil, nil);
        return;
    }

    @try {
        UIView *view = [node view];

        UIView *playbackSubview =
            [self findDescendantViewInView:view
                                 className:@"YTElementsInlineMutedPlaybackView"
                                  maxDepth:6];

        if ([playbackSubview isKindOfClass:NSClassFromString(@"YTElementsInlineMutedPlaybackView")]) {
            id playbackView = playbackSubview;

            id playableEntry = GonerinoSafeProtoValue(playbackView, @"asdPlayableEntry");
            if (!playableEntry) {
                playableEntry = GonerinoSafeProtoValue(playbackView, @"_asdPlayableEntry");
            }
            if (!playableEntry) {
                playableEntry = GonerinoSafeProtoValue(playbackView, @"playableEntry");
            }

            NSDictionary *info = [self videoInfoFromPlayableEntry:playableEntry];
            NSString *videoId    = info[@"videoId"];
            NSString *videoTitle = info[@"videoTitle"];
            NSString *ownerName  = info[@"ownerName"];

            if (ownerName.length == 0) {
                ownerName = [self fallbackOwnerNameFromNode:node];
            }

            if (videoId.length > 0 || videoTitle.length > 0 || ownerName.length > 0) {
                completion(videoId, videoTitle, ownerName);
                return;
            }
        }

        NSDictionary *fallbackInfo = [self fallbackVideoInfoFromNodeDescriptionChain:node];
        if (fallbackInfo.count > 0) {
            NSString *videoId    = fallbackInfo[@"videoId"];
            NSString *videoTitle = fallbackInfo[@"videoTitle"];
            NSString *ownerName  = fallbackInfo[@"ownerName"];

            if (ownerName.length == 0) {
                ownerName = [self fallbackOwnerNameFromNode:node];
            }

            completion(videoId, videoTitle, ownerName);
            return;
        }

        completion(nil, nil, nil);
    } @catch (NSException *exception) {
        completion(nil, nil, nil);
    }
}

+ (void)extractVideoInfoFromNode:(id)node
                    fallbackNode:(id)fallbackNode
                      completion:(void (^)(NSString *videoId, NSString *videoTitle, NSString *ownerName))completion {
    if (!completion) {
        return;
    }

    [self extractVideoInfoFromNode:node
                        completion:^(NSString *videoId, NSString *videoTitle, NSString *ownerName) {
        if (videoId.length > 0 || videoTitle.length > 0 || ownerName.length > 0) {
            completion(videoId, videoTitle, ownerName);
            return;
        }

        NSDictionary *fallbackInfo = [self fallbackVideoInfoFromNodeDescriptionChain:fallbackNode];
        if (fallbackInfo.count > 0) {
            NSString *fallbackVideoId    = fallbackInfo[@"videoId"];
            NSString *fallbackVideoTitle = fallbackInfo[@"videoTitle"];
            NSString *fallbackOwnerName  = fallbackInfo[@"ownerName"];

            if (fallbackOwnerName.length == 0) {
                fallbackOwnerName = [self fallbackOwnerNameFromNode:fallbackNode];
            }

            completion(fallbackVideoId, fallbackVideoTitle, fallbackOwnerName);
            return;
        }

        completion(nil, nil, nil);
    }];
}

+ (BOOL)nodeContainsBlockedVideo:(id)node {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoEnabled"] == nil ? 
                    YES : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoEnabled"];
    
    if (!isEnabled) {
        return NO;
    }
    
    if ([node respondsToSelector:@selector(accessibilityLabel)]) {
        NSString *accessibilityLabel = [node accessibilityLabel];
        if (accessibilityLabel) {
            NSArray *components = [accessibilityLabel componentsSeparatedByString:@" - "];
            if (components.count >= 4) {
                NSString *title = components[0];
                NSString *channelName = components[3];
                
                if ([[WordManager sharedInstance] isWordBlocked:title]) {
                    NSLog(@"[Gonerino] Blocking video because of blocked word in title: %@", title);
                    return YES;
                }
                
                if ([[ChannelManager sharedInstance] isChannelBlocked:channelName]) {
                    NSLog(@"[Gonerino] Blocking content from blocked channel: %@", channelName);
                    return YES;
                }
            }
        }
    }

    if ([node isKindOfClass:NSClassFromString(@"ASTextNode")]) {
        ASTextNode *textNode = (ASTextNode *)node;
        NSAttributedString *attributedText = textNode.attributedText;
        NSString *text = [attributedText string];

        if ([text containsString:@" · "]) {
            NSArray *components = [text componentsSeparatedByString:@" · "];
            if (components.count >= 1) {
                NSString *potentialChannelName = components[0];
                if ([[ChannelManager sharedInstance] isChannelBlocked:potentialChannelName]) {
                    NSLog(@"[Gonerino] Blocking content from blocked channel: %@", potentialChannelName);
                    return YES;
                }
            }
        }
    }

    if ([node respondsToSelector:@selector(channelName)]) {
        NSString *nodeChannelName = [node channelName];
        if ([[ChannelManager sharedInstance] isChannelBlocked:nodeChannelName]) {
            NSLog(@"[Gonerino] Blocking content from blocked channel: %@", nodeChannelName);
            return YES;
        }
    }

    if ([node respondsToSelector:@selector(ownerName)]) {
        NSString *nodeOwnerName = [node ownerName];
        if ([[ChannelManager sharedInstance] isChannelBlocked:nodeOwnerName]) {
            NSLog(@"[Gonerino] Blocking content from blocked channel: %@", nodeOwnerName);
            return YES;
        }
    }

    __block BOOL isBlocked = NO;

    if ([node isKindOfClass:NSClassFromString(@"ASTextNode")]) {
        ASTextNode *textNode = (ASTextNode *)node;
        NSAttributedString *attributedText = textNode.attributedText;
        NSString *text = [attributedText string];

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"] &&
            [text isEqualToString:@"People also watched this video"]) {
            NSLog(@"[Gonerino] Blocking 'People also watched' section");
            return YES;
        }

        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"] &&
            [text isEqualToString:@"You might also like this"]) {
            NSLog(@"[Gonerino] Blocking 'You might also like' section");
            return YES;
        }
    }

    if ([node isKindOfClass:NSClassFromString(@"YTInlinePlaybackPlayerNode")]) {
        id fallbackNode = node;
        id currentNode = node;
        NSInteger depth = 0;

        while (currentNode && depth < 10) {
            if ([currentNode isKindOfClass:NSClassFromString(@"YTVideoWithContextNode")]) {
                fallbackNode = currentNode;
                break;
            }

            if ([currentNode respondsToSelector:@selector(supernode)]) {
                currentNode = [currentNode supernode];
            } else if ([currentNode respondsToSelector:@selector(parentNode)]) {
                currentNode = [currentNode parentNode];
            } else {
                currentNode = nil;
            }

            depth++;
        }

        [self
            extractVideoInfoFromNode:node
                        fallbackNode:fallbackNode
                          completion:^(NSString *videoId, NSString *videoTitle, NSString *ownerName) {
                              if ([[VideoManager sharedInstance] isVideoBlocked:videoId]) {
                                  isBlocked = YES;
                                  NSLog(@"[Gonerino] Blocking video with id: %@", videoId);
                              }
                              if ([[ChannelManager sharedInstance] isChannelBlocked:ownerName]) {
                                  isBlocked = YES;
                                  NSLog(@"[Gonerino] Blocking video with id %@: Channel %@ is blocked", videoId,
                                        ownerName);
                              }
                              if ([[WordManager sharedInstance] isWordBlocked:videoTitle]) {
                                  isBlocked = YES;
                                  NSLog(@"[Gonerino] Blocking video with id %@: title contains blocked word", videoId);
                              }
                          }];
        return isBlocked;
    }

    if ([node respondsToSelector:@selector(subnodes)]) {
        NSArray *subnodes = [node subnodes];
        for (id subnode in subnodes) {
            if ([self nodeContainsBlockedVideo:subnode]) {
                return YES;
            }
        }
    }

    return NO;
}

+ (UIImage *)createBlockChannelIconWithSize:(CGSize)size {
    @try {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            NSLog(@"[Gonerino] Failed to create graphics context");
            return nil;
        }

        CGContextSetShouldAntialias(context, YES);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetShouldSmoothFonts(context, NO);

        [[UIColor whiteColor] setStroke];

        CGFloat noSymbolRadius   = size.width * 0.45;
        CGPoint center           = CGPointMake(size.width / 2, size.height / 2);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center
                                                                  radius:noSymbolRadius
                                                              startAngle:0
                                                                endAngle:2 * M_PI
                                                               clockwise:YES];

        CGFloat bodyRadius     = size.width * 0.3;
        CGPoint bodyCenter     = CGPointMake(size.width / 2, size.height * 0.85);
        UIBezierPath *bodyPath = [UIBezierPath bezierPathWithArcCenter:bodyCenter
                                                                radius:bodyRadius
                                                            startAngle:M_PI
                                                              endAngle:2 * M_PI
                                                             clockwise:YES];

        CGFloat headRadius     = size.width * 0.15;
        CGPoint headCenter     = CGPointMake(size.width / 2, size.height * 0.35);
        UIBezierPath *headPath = [UIBezierPath bezierPathWithArcCenter:headCenter
                                                                radius:headRadius
                                                            startAngle:0
                                                              endAngle:2 * M_PI
                                                             clockwise:YES];

        UIBezierPath *linePath = [UIBezierPath bezierPath];
        CGFloat offset         = noSymbolRadius * 0.7071;
        [linePath moveToPoint:CGPointMake(center.x - offset, center.y - offset)];
        [linePath addLineToPoint:CGPointMake(center.x + offset, center.y + offset)];

        CGFloat lineWidth    = 1.5;
        circlePath.lineWidth = lineWidth;
        headPath.lineWidth   = lineWidth;
        bodyPath.lineWidth   = lineWidth;
        linePath.lineWidth   = lineWidth;

        [circlePath stroke];
        [bodyPath stroke];
        [headPath stroke];
        [linePath stroke];

        UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } @catch (NSException *exception) {
        NSLog(@"[Gonerino] Exception in createBlockChannelIcon: %@", exception);
        return nil;
    }
}

+ (UIImage *)createBlockVideoIconWithSize:(CGSize)size {
    @try {
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (!context) {
            NSLog(@"[Gonerino] Failed to create graphics context");
            return nil;
        }

        CGContextSetShouldAntialias(context, YES);
        CGContextSetAllowsAntialiasing(context, YES);
        CGContextSetShouldSmoothFonts(context, NO);

        [[UIColor whiteColor] setStroke];
        [[UIColor whiteColor] setFill];

        CGPoint center = CGPointMake(size.width / 2, size.height / 2);

        UIBezierPath *rectPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(size.width * 0.2, size.height * 0.3,
                                                                                    size.width * 0.6, size.height * 0.4)
                                                            cornerRadius:3.0];

        UIBezierPath *trianglePath = [UIBezierPath bezierPath];
        CGFloat triangleSize       = size.width * 0.2;
        CGPoint triangleCenter     = center;

        [trianglePath
            moveToPoint:CGPointMake(triangleCenter.x - triangleSize / 2, triangleCenter.y - triangleSize / 2)];
        [trianglePath addLineToPoint:CGPointMake(triangleCenter.x + triangleSize / 2, triangleCenter.y)];
        [trianglePath
            addLineToPoint:CGPointMake(triangleCenter.x - triangleSize / 2, triangleCenter.y + triangleSize / 2)];
        [trianglePath closePath];

        CGFloat noSymbolRadius   = size.width * 0.45;
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center
                                                                  radius:noSymbolRadius
                                                              startAngle:0
                                                                endAngle:2 * M_PI
                                                               clockwise:YES];

        UIBezierPath *linePath = [UIBezierPath bezierPath];
        CGFloat offset         = noSymbolRadius * 0.7071;
        [linePath moveToPoint:CGPointMake(center.x - offset, center.y - offset)];
        [linePath addLineToPoint:CGPointMake(center.x + offset, center.y + offset)];

        CGFloat lineWidth      = 1.5;
        rectPath.lineWidth     = lineWidth;
        trianglePath.lineWidth = lineWidth;
        circlePath.lineWidth   = lineWidth;
        linePath.lineWidth     = lineWidth;

        [rectPath stroke];
        [trianglePath fill];
        [circlePath stroke];
        [linePath stroke];

        UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    } @catch (NSException *exception) {
        NSLog(@"[Gonerino] Exception in createBlockVideoIcon: %@", exception);
        return nil;
    }
}

@end
