#import "Tweak.h"
#import "ToastHelper.h"

@interface YTDefaultSheetController (GonerinoSafeResolve)
- (id)gonerino_findVideoContextNodeFromNode:(id)node;
- (id)gonerino_findDescendantNodeInNode:(id)node
                              className:(NSString *)className
                               maxDepth:(NSInteger)maxDepth;
@end

@interface NSObject (GonerinoNodeTraversal)
- (id)supernode;
- (id)parentNode;
@end

%hook YTAsyncCollectionView

- (void)layoutSubviews {
    [self removeOffendingCells];
    %orig;
}

%new
- (void)removeOffendingCells {
    __weak typeof(self) weakSelf = self;

    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return;

        @try {
            NSArray *visibleCells              = [strongSelf visibleCells];
            if (visibleCells.count == 0) return;
            NSMutableArray *indexPathsToRemove = [NSMutableArray array];

            for (UICollectionViewCell *cell in visibleCells) {
                if (![cell isKindOfClass:NSClassFromString(@"_ASCollectionViewCell")]) {
                    continue;
                }

                _ASCollectionViewCell *asCell = (_ASCollectionViewCell *)cell;
                id node = [asCell node];
                if (![node isKindOfClass:NSClassFromString(@"YTVideoWithContextNode")]) {
                    continue;
                }

                if ([Util nodeContainsBlockedVideo:node]) {
                    NSIndexPath *indexPath = [strongSelf indexPathForCell:cell];
                    if (indexPath) {
                        [indexPathsToRemove addObject:indexPath];
                    }
                }
            }

            if (indexPathsToRemove.count > 0) {
                [strongSelf
                    performBatchUpdates:^{ [strongSelf deleteItemsAtIndexPaths:indexPathsToRemove]; }
                             completion:nil];
            }
        } @catch (NSException *exception) {
            NSLog(@"[Gonerino] Exception in removeOffendingCells: %@", exception);
        }
    });
}

%end

%hook YTDefaultSheetController

- (void)addAction:(YTActionSheetAction *)action {
    %orig;

    static void *blockActionKey = &blockActionKey;
    if (objc_getAssociatedObject(self, blockActionKey)) {
        return;
    }

    UIView *sourceView  = [self valueForKey:@"sourceView"];
    id node             = [sourceView valueForKey:@"asyncdisplaykit_node"];
    id videoContextNode = [self gonerino_findVideoContextNodeFromNode:node];

    if (!videoContextNode) {
        return;
    }

    NSInteger currentActionsCount = 3;
    if ([self respondsToSelector:@selector(actions)]) {
        currentActionsCount = [[self actions] count];
    }

    if (currentActionsCount < 3) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    CGSize iconSize              = CGSizeMake(24, 24);
    if (action) {
        UIImage *originalIcon = [action valueForKey:@"_iconImage"];
        if (originalIcon) {
            iconSize = originalIcon.size;
        }
    }

    YTActionSheetAction *blockChannelAction = [%c(YTActionSheetAction)
        actionWithTitle:@"Block channel"
              iconImage:[Util createBlockChannelIconWithSize:iconSize]
                  style:0
                handler:^(YTActionSheetAction *action) {
                    __strong typeof(self) strongSelf = weakSelf;
                    @try {
                        UIView *sourceView  = [strongSelf valueForKey:@"sourceView"];
                        id node             = [sourceView valueForKey:@"asyncdisplaykit_node"];
                        id videoContextNode = [strongSelf gonerino_findVideoContextNodeFromNode:node];

                        if (!videoContextNode) {
                            GonerinoShowToast(
                                @"Couldn’t block channel\nReason: videoContextNode not found");
                            return;
                        }

                        id inlinePlaybackNode =
                            [strongSelf gonerino_findDescendantNodeInNode:videoContextNode
                                                                className:@"YTInlinePlaybackPlayerNode"
                                                                 maxDepth:8];

                        if (!inlinePlaybackNode) {
                            GonerinoShowToast(
                                @"Couldn’t block channel\nReason: inlinePlaybackNode not found");
                            return;
                        }

                        __block BOOL didComplete = NO;

                        [Util extractVideoInfoFromNode:inlinePlaybackNode
                                            completion:^(NSString *videoId, NSString *videoTitle,
                                                         NSString *ownerName) {
                                                didComplete = YES;

                                                if (ownerName.length > 0) {
                                                    [[ChannelManager sharedInstance]
                                                        addBlockedChannel:ownerName];
                                                    GonerinoShowToast(
                                                        [NSString stringWithFormat:@"Blocked \"%@\"",
                                                                                   ownerName]);
                                                } else {
                                                    GonerinoShowToast(
                                                        @"Couldn’t block channel\nReason: ownerName missing");
                                                }
                                            }];

                        if (!didComplete) {
                            GonerinoShowToast(
                                @"Couldn’t block channel\nReason: Util completion not called");
                        }
                    } @catch (NSException *e) {
                        NSLog(@"[Gonerino] Exception in block action: %@", e);
                    }
                }];

    YTActionSheetAction *blockVideoAction = [%c(YTActionSheetAction)
        actionWithTitle:@"Block video"
              iconImage:[Util createBlockVideoIconWithSize:iconSize]
                  style:0
                handler:^(YTActionSheetAction *action) {
                    __strong typeof(self) strongSelf = weakSelf;
                    @try {
                        UIView *sourceView  = [strongSelf valueForKey:@"sourceView"];
                        id node             = [sourceView valueForKey:@"asyncdisplaykit_node"];
                        id videoContextNode = [strongSelf gonerino_findVideoContextNodeFromNode:node];

                        if (!videoContextNode) {
                            GonerinoShowToast(
                                @"Couldn’t block video\nReason: videoContextNode not found");
                            return;
                        }

                        id inlinePlaybackNode =
                            [strongSelf gonerino_findDescendantNodeInNode:videoContextNode
                                                                className:@"YTInlinePlaybackPlayerNode"
                                                                 maxDepth:8];

                        if (!inlinePlaybackNode) {
                            GonerinoShowToast(
                                @"Couldn’t block video\nReason: inlinePlaybackNode not found");
                            return;
                        }

                        __block BOOL didComplete = NO;

                        [Util
                            extractVideoInfoFromNode:inlinePlaybackNode
                                          completion:^(NSString *videoId, NSString *videoTitle,
                                                       NSString *ownerName) {
                                              didComplete = YES;

                                              if (videoId.length > 0) {
                                                  [[VideoManager sharedInstance] addBlockedVideo:videoId
                                                                                           title:videoTitle
                                                                                         channel:ownerName];
                                                  GonerinoShowToast(
                                                      [NSString stringWithFormat:@"Blocked video: \"%@\"",
                                                                                 videoTitle ?: videoId]);
                                                  if ([strongSelf respondsToSelector:@selector(dismiss)]) {
                                                      [strongSelf dismiss];
                                                  }
                                              } else {
                                                  GonerinoShowToast(
                                                      @"Couldn’t block video\nReason: videoId missing");
                                              }
                                          }];

                        if (!didComplete) {
                            GonerinoShowToast(
                                @"Couldn’t block video\nReason: Util completion not called");
                        }
                    } @catch (NSException *e) {
                        NSLog(@"[Gonerino] Exception in block action: %@", e);
                    }
                }];

    objc_setAssociatedObject(self, blockActionKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self addAction:blockChannelAction];
    [self addAction:blockVideoAction];
}

%new
- (id)gonerino_findVideoContextNodeFromNode:(id)node {
    id currentNode = node;
    NSInteger depth = 0;

    while (currentNode && depth < 10) {
        if ([currentNode isKindOfClass:NSClassFromString(@"YTVideoWithContextNode")]) {
            return currentNode;
        }

        if ([currentNode respondsToSelector:@selector(supernode)]) {
            currentNode = [currentNode supernode];
        } else if ([currentNode respondsToSelector:@selector(parentNode)]) { // 推測API
            currentNode = [currentNode parentNode];
        } else {
            currentNode = nil;
        }

        depth++;
    }

    return nil;
}

%new
- (id)gonerino_findDescendantNodeInNode:(id)node
                              className:(NSString *)className
                               maxDepth:(NSInteger)maxDepth {
    if (!node || maxDepth < 0) {
        return nil;
    }

    if ([node isKindOfClass:NSClassFromString(className)]) {
        return node;
    }

    if (![node respondsToSelector:@selector(subnodes)]) {
        return nil;
    }

    NSArray *subnodes = [node subnodes];
    for (id subnode in subnodes) {
        id foundNode = [self gonerino_findDescendantNodeInNode:subnode
                                                     className:className
                                                      maxDepth:maxDepth - 1];
        if (foundNode) {
            return foundNode;
        }
    }

    return nil;
}

%new
- (UIViewController *)findViewControllerForView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

%end

%hook YTRightNavigationButtons
%property(retain, nonatomic) YTQTMButton *gonerinoButton;

- (NSMutableArray *)buttons {
    NSMutableArray *retVal = %orig.mutableCopy;

    BOOL showButton = [[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoShowButton"] == nil
                          ? YES
                          : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoShowButton"];

    if (showButton) {
        [self.gonerinoButton removeFromSuperview];
        [self addSubview:self.gonerinoButton];

        NSInteger pageStyle;
        Class YTPageStyleControllerClass = %c(YTPageStyleController);
        if (YTPageStyleControllerClass)
            pageStyle = [YTPageStyleControllerClass pageStyle];
        else {
            YTAppDelegate *delegate                    = (YTAppDelegate *)[UIApplication sharedApplication].delegate;
            YTAppViewControllerImpl *appViewController = [delegate valueForKey:@"_appViewController"];
            pageStyle                                  = [appViewController pageStyle];
        }

        if (!self.gonerinoButton) {
            self.gonerinoButton = [%c(YTQTMButton) iconButton];
            if ([self.gonerinoButton respondsToSelector:@selector(enableNewTouchFeedback)]) {
                [self.gonerinoButton enableNewTouchFeedback];
            }
            self.gonerinoButton.frame = CGRectMake(0, 0, 40, 40);
            [self.gonerinoButton addTarget:self
                                    action:@selector(gonerinoButtonPressed:)
                          forControlEvents:UIControlEventTouchUpInside];
            [retVal insertObject:self.gonerinoButton atIndex:0];
        }

        BOOL isEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoEnabled"] == nil
                             ? YES
                             : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoEnabled"];

        UIImage *image     = [Util createBlockVideoIconWithSize:CGSizeMake(20, 20)];
        UIColor *tintColor = pageStyle ? UIColor.whiteColor : UIColor.blackColor;

        if (!isEnabled) {
            tintColor = [tintColor colorWithAlphaComponent:0.4];
        }

        image = [%c(QTMIcon) tintImage:image color:tintColor];
        [self.gonerinoButton setImage:image forState:UIControlStateNormal];
    } else {
        if (self.gonerinoButton) {
            [self.gonerinoButton removeFromSuperview];
            self.gonerinoButton = nil;
        }
    }

    return retVal;
}

- (NSMutableArray *)visibleButtons {
    NSMutableArray *retVal = %orig.mutableCopy;

    BOOL showButton = [[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoShowButton"] == nil
                          ? YES
                          : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoShowButton"];

    if (showButton && self.gonerinoButton) {
        [self.gonerinoButton removeFromSuperview];
        [self addSubview:self.gonerinoButton];
        [retVal insertObject:self.gonerinoButton atIndex:0];
    }

    return retVal;
}

%new
- (void)gonerinoButtonPressed:(UIButton *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isEnabled = [defaults objectForKey:@"GonerinoEnabled"] == nil ? YES : [defaults boolForKey:@"GonerinoEnabled"];
    BOOL newState  = !isEnabled;
    [defaults setBool:newState forKey:@"GonerinoEnabled"];
    [defaults synchronize];

    NSInteger pageStyle;
    Class YTPageStyleControllerClass = %c(YTPageStyleController);
    if (YTPageStyleControllerClass)
        pageStyle = [YTPageStyleControllerClass pageStyle];
    else {
        YTAppDelegate *delegate                    = (YTAppDelegate *)[UIApplication sharedApplication].delegate;
        YTAppViewControllerImpl *appViewController = [delegate valueForKey:@"_appViewController"];
        pageStyle                                  = [appViewController pageStyle];
    }

    UIImage *image     = [Util createBlockVideoIconWithSize:CGSizeMake(20, 20)];
    UIColor *tintColor = pageStyle ? UIColor.whiteColor : UIColor.blackColor;

    if (!newState) {
        tintColor = [tintColor colorWithAlphaComponent:0.4];
    }

    image = [%c(QTMIcon) tintImage:image color:tintColor];
    [self.gonerinoButton setImage:image forState:UIControlStateNormal];

    dispatch_async(dispatch_get_main_queue(), ^{
        GonerinoShowToast([NSString stringWithFormat:@"Gonerino %@", newState ? @"enabled" : @"disabled"]);
    });
}

%end

%ctor {
    %init;
}
