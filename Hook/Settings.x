#import "Settings.h"
#import "SettingsExchangeHelper.h"
#import "SettingsModifyHelper.h"
#import "ListViewController.h"
#import "ToastHelper.h"
#import "TextHelper.h"
#import "Util.h"

%hook YTAppSettingsPresentationData

+ (NSArray *)settingsCategoryOrder {
    NSArray *order               = %orig;
    NSMutableArray *mutableOrder = [order mutableCopy];
    NSUInteger insertIndex       = [order indexOfObject:@(1)];
    if (insertIndex != NSNotFound) {
        [mutableOrder insertObject:@(GonerinoSection) atIndex:insertIndex + 1];
    }
    return mutableOrder;
}

%end

%hook YTSettingsSectionItemManager

%new
- (void)updateGonerinoSectionWithEntry:(id)entry {
    YTSettingsViewController *delegate = [self valueForKey:@"_settingsViewControllerDelegate"];
    NSMutableArray *sectionItems       = [NSMutableArray array];

    SECTION_HEADER(TextHelperGonerinoSettingsHeaderTitle());

    NSUInteger channelCount               = [[ChannelManager sharedInstance] blockedChannels].count;
    YTSettingsSectionItem *manageChannels = [%c(YTSettingsSectionItem)
                  itemWithTitle:TextHelperManageChannelsTitle()
               titleDescription:TextHelperBlockedCountDescription(@"channel", channelCount)
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

                        ListViewController *vc = [ListViewController new];

                        vc.titleText = TextHelperManageChannelsTitle();
                        vc.itemType = @"channel";
                        vc.loadItemsBlock = ^NSArray *{
                            return [[ChannelManager sharedInstance] blockedChannels];
                        };
                        vc.removeItemAtIndexBlock = ^(NSInteger index) {
                            NSString *deletedText =
                                [SettingsModifyHelper deleteChannelAtIndex:index];
                            if (deletedText.length == 0) {
                                return;
                            }

                            [self showGonerinoToastWithMessage:
                                TextHelperDeletedQuotedToast(deletedText)];
                        };
                        vc.removeItemsAtIndexesBlock = ^(NSArray<NSNumber *> *indexes) {
                            NSArray<NSString *> *deletedTexts =
                                [SettingsModifyHelper deleteChannelsAtIndexes:indexes];
                            if (deletedTexts.count == 1) {
                                [self showGonerinoToastWithMessage:
                                    TextHelperDeletedQuotedToast(deletedTexts.firstObject)];
                            } else if (deletedTexts.count > 1) {
                                [self showMultipleDeleteToastForItemType:@"channel" count:deletedTexts.count];
                            }
                        };
                        vc.moveItemBlock = ^(NSInteger fromIndex, NSInteger toIndex) {
                            [SettingsModifyHelper moveChannelFromIndex:fromIndex
                                                               toIndex:toIndex];
                        };

                        vc.addItemBlock = ^(NSString *newText) {
                            [SettingsModifyHelper addChannelWithText:newText];

                            [self showGonerinoToastWithMessage:
                                TextHelperAddedQuotedToast(newText)];
                        };

                        vc.editItemBlock = ^(NSInteger index, NSString *newText) {
                            NSString *previousText =
                                [SettingsModifyHelper editChannelAtIndex:index newText:newText];
                            if (previousText.length == 0) {
                                return;
                            }

                            [self showGonerinoToastWithMessage:
                                TextHelperEditedToast(previousText, newText)];
                        };

                        YTSettingsViewController *delegate =
                        [self valueForKey:@"_settingsViewControllerDelegate"];

                        [delegate.navigationController pushViewController:vc animated:YES];

                        return YES;
                    }];

    [sectionItems addObject:manageChannels];

    NSUInteger videoCount               = [[VideoManager sharedInstance] blockedVideos].count;
    YTSettingsSectionItem *manageVideos = [%c(YTSettingsSectionItem)
                  itemWithTitle:TextHelperManageVideosTitle()
               titleDescription:TextHelperBlockedCountDescription(@"video", videoCount)
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        NSArray *blockedVideos = [[VideoManager sharedInstance] blockedVideos];
                        if (blockedVideos.count == 0) {
                            [self showGonerinoToastWithMessage:TextHelperNoBlockedVideosToast()];
                            return YES;
                        }

                        NSMutableArray *rows = [NSMutableArray array];

                        [rows addObject:[%c(YTSettingsSectionItem)
                                                      itemWithTitle:@"\t"
                                                   titleDescription:TextHelperBlockedVideosRowDescription()
                                            accessibilityIdentifier:nil
                                                    detailTextBlock:nil
                                                        selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                            return NO;
                                                        }]];

                        for (NSDictionary *videoInfo in blockedVideos) {
                            [rows
                                addObject:
                                    [%c(YTSettingsSectionItem)
                                                  itemWithTitle:videoInfo[@"channel"] ?: TextHelperUnknownChannelText()
                                               titleDescription:videoInfo[@"title"] ?: TextHelperUnknownTitleText()
                                        accessibilityIdentifier:nil
                                                detailTextBlock:nil
                                                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                        YTSettingsViewController *settingsVC =
                                                            [self valueForKey:@"_settingsViewControllerDelegate"];
                                                        UIAlertController *alertController = [UIAlertController
                                                            alertControllerWithTitle:TextHelperDeleteTitle(@"video", 1)
                                                                             message:TextHelperDeleteMessage(@"video", 1, videoInfo[@"title"])
                                                                      preferredStyle:UIAlertControllerStyleAlert];

                                                        [alertController
                                                            addAction:
                                                                [UIAlertAction
                                                                    actionWithTitle:TextHelperDeleteActionTitle()
                                                                              style:UIAlertActionStyleDestructive
                                                                            handler:^(UIAlertAction *action) {
                                                                                [[VideoManager sharedInstance] removeBlockedVideo:videoInfo[@"id"]];
                                                                                [self reloadGonerinoSection];

                                                                                UIImpactFeedbackGenerator *generator =
                                                                                    [[UIImpactFeedbackGenerator alloc]
                                                                                        initWithStyle:
                                                                                            UIImpactFeedbackStyleMedium];
                                                                                [generator prepare];
                                                                                [generator impactOccurred];

                                                                                [self showGonerinoToastWithMessage:
                                                                                    TextHelperDeletedPlainToast(videoInfo[@"title"])];
                                                                            }]];

                                                        [alertController
                                                            addAction:[UIAlertAction
                                                                          actionWithTitle:TextHelperCancelActionTitle()
                                                                                    style:UIAlertActionStyleCancel
                                                                                  handler:nil]];

                                                        [settingsVC presentViewController:alertController
                                                                                 animated:YES
                                                                               completion:nil];
                                                        return YES;
                                                    }]];
                        }

                        YTSettingsViewController *settingsVC   = [self valueForKey:@"_settingsViewControllerDelegate"];
                        YTSettingsPickerViewController *picker = [[%c(YTSettingsPickerViewController) alloc]
                              initWithNavTitle:TextHelperManageVideosTitle()
                            pickerSectionTitle:nil
                                          rows:rows
                             selectedItemIndex:NSNotFound
                               parentResponder:[self parentResponder]];

                        if ([settingsVC respondsToSelector:@selector(navigationController)]) {
                            UINavigationController *nav = settingsVC.navigationController;
                            [nav pushViewController:picker animated:YES];
                        }
                        return YES;
                    }];
    [sectionItems addObject:manageVideos];

    NSUInteger wordCount               = [[WordManager sharedInstance] blockedWords].count;
    YTSettingsSectionItem *manageWords = [%c(YTSettingsSectionItem)
                  itemWithTitle:TextHelperManageWordsTitle()
               titleDescription:TextHelperBlockedCountDescription(@"word", wordCount)
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

                        ListViewController *vc = [ListViewController new];

                        vc.titleText = TextHelperManageWordsTitle();
                        vc.itemType = @"word";
                        vc.loadItemsBlock = ^NSArray *{
                            return [[WordManager sharedInstance] blockedWords];
                        };
                        vc.removeItemAtIndexBlock = ^(NSInteger index) {
                            NSString *deletedText =
                                [SettingsModifyHelper deleteWordAtIndex:index];
                            if (deletedText.length == 0) {
                                return;
                            }

                            [self showGonerinoToastWithMessage:
                                TextHelperDeletedQuotedToast(deletedText)];
                        };
                        vc.removeItemsAtIndexesBlock = ^(NSArray<NSNumber *> *indexes) {
                            NSArray<NSString *> *deletedTexts =
                                [SettingsModifyHelper deleteWordsAtIndexes:indexes];
                            if (deletedTexts.count == 1) {
                                [self showGonerinoToastWithMessage:
                                    TextHelperDeletedQuotedToast(deletedTexts.firstObject)];
                            } else if (deletedTexts.count > 1) {
                                [self showMultipleDeleteToastForItemType:@"word" count:deletedTexts.count];
                            }
                        };
                        vc.moveItemBlock = ^(NSInteger fromIndex, NSInteger toIndex) {
                            [SettingsModifyHelper moveWordFromIndex:fromIndex
                                                            toIndex:toIndex];
                        };

                        vc.addItemBlock = ^(NSString *newText) {
                            [SettingsModifyHelper addWordWithText:newText];

                            [self showGonerinoToastWithMessage:
                                TextHelperAddedQuotedToast(newText)];
                        };

                        vc.editItemBlock = ^(NSInteger index, NSString *newText) {
                            NSString *previousText =
                                [SettingsModifyHelper editWordAtIndex:index newText:newText];
                            if (previousText.length == 0) {
                                return;
                            }

                            [self showGonerinoToastWithMessage:
                                TextHelperEditedToast(previousText, newText)];
                        };

                        YTSettingsViewController *delegate =
                        [self valueForKey:@"_settingsViewControllerDelegate"];

                        [delegate.navigationController pushViewController:vc animated:YES];

                        return YES;
                    }];

    [sectionItems addObject:manageWords];

    YTSettingsSectionItem *blockPeopleWatched = [%c(YTSettingsSectionItem)
            switchItemWithTitle:TextHelperBlockPeopleWatchedTitle()
               titleDescription:TextHelperBlockPeopleWatchedDescription()
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoPeopleWatched"];
                        [self showGonerinoToastWithMessage:
                            TextHelperPeopleWatchedToggleToast(enabled)];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:blockPeopleWatched];

    YTSettingsSectionItem *blockMightLike = [%c(YTSettingsSectionItem)
            switchItemWithTitle:TextHelperBlockMightLikeTitle()
               titleDescription:TextHelperBlockMightLikeDescription()
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoMightLike"];
                        [self showGonerinoToastWithMessage:
                            TextHelperMightLikeToggleToast(enabled)];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:blockMightLike];

    SECTION_HEADER(TextHelperManageSettingsHeaderTitle());

    YTSettingsSectionItem *showButtonToggle = [%c(YTSettingsSectionItem)
            switchItemWithTitle:TextHelperShowGonerinoButtonTitle()
               titleDescription:TextHelperShowGonerinoButtonDescription()
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoShowButton"] == nil
                                    ? YES
                                    : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoShowButton"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoShowButton"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self showGonerinoToastWithMessage:
                            TextHelperGonerinoButtonVisibilityToast(enabled)];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:showButtonToggle];

    YTSettingsSectionItem *useCustomToastToggle = [%c(YTSettingsSectionItem)
            switchItemWithTitle:TextHelperUseGonerinoToastTitle()
               titleDescription:TextHelperUseGonerinoToastDescription()
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoUseCustomToast"] == nil
                                    ? YES
                                    : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoUseCustomToast"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoUseCustomToast"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self showGonerinoToastWithMessage:
                            TextHelperToastModeToast(enabled)];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:useCustomToastToggle];

    YTSettingsSectionItem *exportSettings = [%c(YTSettingsSectionItem)
                  itemWithTitle:TextHelperExportSettingsTitle()
               titleDescription:TextHelperExportSettingsDescription()
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        [self presentGonerinoSettingsExportPicker];
                        return YES;
                    }];
    [sectionItems addObject:exportSettings];

    YTSettingsSectionItem *importSettings = [%c(YTSettingsSectionItem)
                  itemWithTitle:TextHelperImportSettingsTitle()
               titleDescription:TextHelperImportSettingsDescription()
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        [self presentGonerinoSettingsImportPicker];
                        return YES;
                    }];
    [sectionItems addObject:importSettings];

    SECTION_HEADER(TextHelperAboutHeaderTitle());

    [sectionItems
        addObject:[%c(YTSettingsSectionItem) itemWithTitle:TextHelperGitHubTitle()
                                          titleDescription:TextHelperGitHubDescription()
                                   accessibilityIdentifier:nil
                                           detailTextBlock:nil
                                               selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                    return [%c(YTUIUtils)
                                                        openURL:[NSURL URLWithString:@"https://github.com/castdrian/Gonerino"]];
                                                            }]];

    [sectionItems
        addObject:[%c(YTSettingsSectionItem) itemWithTitle:TextHelperVersionTitle()
                      titleDescription:nil
                      accessibilityIdentifier:nil
                      detailTextBlock:^NSString *() { return [NSString stringWithFormat:@"v%@", TWEAK_VERSION]; }
                      selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                          return [%c(YTUIUtils)
                              openURL:[NSURL URLWithString:@"https://github.com/castdrian/Gonerino/releases"]];
                      }]];

    if ([delegate respondsToSelector:@selector(setSectionItems:
                                                   forCategory:title:icon:titleDescription:headerHidden:)]) {
        YTIIcon *icon = [%c(YTIIcon) new];
        icon.iconType = YT_FILTER;

        [delegate setSectionItems:sectionItems
                      forCategory:GonerinoSection
                            title:TextHelperGonerinoSectionTitle()
                             icon:icon
                 titleDescription:nil
                     headerHidden:NO];
    } else {
        [delegate setSectionItems:sectionItems
                      forCategory:GonerinoSection
                            title:TextHelperGonerinoSectionTitle()
                 titleDescription:nil
                     headerHidden:NO];
    }
}

- (void)updateSectionForCategory:(NSUInteger)category withEntry:(id)entry {
    if (category == GonerinoSection) {
        [self updateGonerinoSectionWithEntry:entry];
        return;
    }
    %orig;
}

%new
- (UITableView *)findTableViewInView:(UIView *)view {
    if ([view isKindOfClass:[UITableView class]]) {
        return (UITableView *)view;
    }
    for (UIView *subview in view.subviews) {
        UITableView *tableView = [self findTableViewInView:subview];
        if (tableView) {
            return tableView;
        }
    }
    return nil;
}

%new
- (void)reloadGonerinoSection {
    dispatch_async(dispatch_get_main_queue(), ^{
        YTSettingsViewController *delegate = [self valueForKey:@"_settingsViewControllerDelegate"];
        if ([delegate isKindOfClass:%c(YTSettingsViewController)]) {
            [self updateGonerinoSectionWithEntry:nil];
            UITableView *tableView = [self findTableViewInView:delegate.view];
            if (tableView) {
                [tableView beginUpdates];
                NSIndexSet *sectionSet = [NSIndexSet indexSetWithIndex:GonerinoSection];
                [tableView reloadSections:sectionSet withRowAnimation:UITableViewRowAnimationAutomatic];
                [tableView endUpdates];
            }
        }
    });
}



%new
- (void)showGonerinoToastWithMessage:(NSString *)message {
    GonerinoShowToast(message);
}

%new
- (void)showMultipleDeleteToastForItemType:(NSString *)itemType count:(NSUInteger)count {
    NSString *message = TextHelperMultipleDeleteToast(itemType, count);
    [self showGonerinoToastWithMessage:message];
}

%end

%hook YTSettingsViewController

- (void)loadWithModel:(id)model {
    %orig;
    if ([self respondsToSelector:@selector(updateSectionForCategory:withEntry:)]) {
        [(YTSettingsSectionItemManager *)[self valueForKey:@"_sectionItemManager"] updateGonerinoSectionWithEntry:nil];
    }
}

%end

%ctor {
    %init;
}
