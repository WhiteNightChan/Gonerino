#import "Settings.h"
#import "ListViewController.h"
#import "ToastHelper.h"
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

typedef struct {
    NSString *pickerTitle;
    NSString *rowDescription;
    NSString *addTitle;
    NSString *editTitle;
    NSString *deleteTitle;
    NSString *addDescription;
    NSString *editDescription;
    NSString *placeholder;
} GonerinoPickerConfig;

%hook YTSettingsSectionItemManager

%new
- (void)updateGonerinoSectionWithEntry:(id)entry {
    YTSettingsViewController *delegate = [self valueForKey:@"_settingsViewControllerDelegate"];
    NSMutableArray *sectionItems       = [NSMutableArray array];

    SECTION_HEADER(@"Gonerino Settings");

    YTSettingsSectionItem *showButtonToggle = [%c(YTSettingsSectionItem)
            switchItemWithTitle:@"Show Gonerino Button"
               titleDescription:@"Display Gonerino toggle button in top navbar"
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoShowButton"] == nil
                                    ? YES
                                    : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoShowButton"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoShowButton"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self showGonerinoToastWithMessage:
                            [NSString stringWithFormat:@"Gonerino button %@", enabled ? @"shown" : @"hidden"]];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:showButtonToggle];

    YTSettingsSectionItem *useCustomToastToggle = [%c(YTSettingsSectionItem)
            switchItemWithTitle:@"Use Gonerino Toast"
               titleDescription:@"Use Gonerino's custom toast instead of YouTube's default toast"
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoUseCustomToast"] == nil
                                    ? YES
                                    : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoUseCustomToast"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoUseCustomToast"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self showGonerinoToastWithMessage:
                            enabled ? @"Using Gonerino toast" : @"Using YouTube toast"];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:useCustomToastToggle];

    // picker logic WIP
    NSUInteger channelCount               = [[ChannelManager sharedInstance] blockedChannels].count;
    YTSettingsSectionItem *manageChannels = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Manage Channels"
               titleDescription:[NSString stringWithFormat:@"%lu blocked channel%@", (unsigned long)channelCount,
                                                           channelCount == 1 ? @"" : @"s"]
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

                        ListViewController *vc = [ListViewController new];

                        vc.titleText = @"Manage Channels";
                        vc.itemType = @"channel";
                        vc.loadItemsBlock = ^NSArray *{
                            return [[ChannelManager sharedInstance] blockedChannels];
                        };
                        vc.removeItemBlock = ^(NSString *text) {
                            [[ChannelManager sharedInstance] removeBlockedChannel:text];
                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Deleted \"%@\"", text]];
                        };
                        vc.removeSelectedItemsBlock = ^(NSArray<NSString *> *texts) {
                            NSMutableArray *updatedChannels =
                                [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
                            if (!updatedChannels) {
                                updatedChannels = [NSMutableArray array];
                            }

                            [updatedChannels removeObjectsInArray:texts];
                            [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];

                            if (texts.count == 1) {
                                [self showGonerinoToastWithMessage:
                                    [NSString stringWithFormat:@"Deleted \"%@\"", texts.firstObject]];
                            } else {
                                [self showMultipleDeleteToastForItemType:@"channel" count:texts.count];
                            }
                        };
                        vc.moveItemBlock = ^(NSInteger fromIndex, NSInteger toIndex) {
                            NSMutableArray *updatedChannels =
                                [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
                            if (!updatedChannels) return;

                            if (fromIndex < 0 || toIndex < 0 ||
                                fromIndex >= updatedChannels.count ||
                                toIndex >= updatedChannels.count) {
                                return;
                            }

                            NSString *item = updatedChannels[fromIndex];
                            [updatedChannels removeObjectAtIndex:fromIndex];
                            [updatedChannels insertObject:item atIndex:toIndex];

                            [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];
                        };

                        vc.addItemBlock = ^(NSString *newText) {
                            [[ChannelManager sharedInstance] addBlockedChannel:newText];

                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Added \"%@\"", newText]];
                        };

                        vc.editItemBlock = ^(NSInteger index, NSString *oldText, NSString *newText) {
                            NSMutableArray<NSString *> *updatedChannels =
                                [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
                            if (!updatedChannels) {
                                updatedChannels = [NSMutableArray array];
                            }

                            if (index < 0 || index >= updatedChannels.count) {
                                return;
                            }

                            updatedChannels[index] = newText;
                            [[ChannelManager sharedInstance] setBlockedChannels:updatedChannels];

                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Edited \"%@\" → \"%@\"", oldText, newText]];
                        };

                        YTSettingsViewController *delegate =
                        [self valueForKey:@"_settingsViewControllerDelegate"];

                        [delegate.navigationController pushViewController:vc animated:YES];

                        return YES;
                    }];

    [sectionItems addObject:manageChannels];

    NSUInteger videoCount               = [[VideoManager sharedInstance] blockedVideos].count;
    YTSettingsSectionItem *manageVideos = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Manage Videos"
               titleDescription:[NSString stringWithFormat:@"%lu blocked video%@", (unsigned long)videoCount,
                                                           videoCount == 1 ? @"" : @"s"]
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        NSArray *blockedVideos = [[VideoManager sharedInstance] blockedVideos];
                        if (blockedVideos.count == 0) {
                            [self showGonerinoToastWithMessage:@"No blocked videos"];
                            return YES;
                        }

                        NSMutableArray *rows = [NSMutableArray array];

                        [rows addObject:[%c(YTSettingsSectionItem)
                                                      itemWithTitle:@"\t"
                                                   titleDescription:@"Blocked videos"
                                            accessibilityIdentifier:nil
                                                    detailTextBlock:nil
                                                        selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                            return NO;
                                                        }]];

                        for (NSDictionary *videoInfo in blockedVideos) {
                            [rows
                                addObject:
                                    [%c(YTSettingsSectionItem)
                                                  itemWithTitle:videoInfo[@"channel"] ?: @"Unknown Channel"
                                               titleDescription:videoInfo[@"title"] ?: @"Unknown Title"
                                        accessibilityIdentifier:nil
                                                detailTextBlock:nil
                                                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                        YTSettingsViewController *settingsVC =
                                                            [self valueForKey:@"_settingsViewControllerDelegate"];
                                                        UIAlertController *alertController = [UIAlertController
                                                            alertControllerWithTitle:@"Delete Video"
                                                                             message:[NSString
                                                                                         stringWithFormat:
                                                                                             @"Are you sure you want "
                                                                                             @"to delete '%@'?",
                                                                                             videoInfo[@"title"]]
                                                                      preferredStyle:UIAlertControllerStyleAlert];

                                                        [alertController
                                                            addAction:
                                                                [UIAlertAction
                                                                    actionWithTitle:@"Delete"
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
                                                                                    [NSString stringWithFormat:@"Deleted %@",
                                                                                                               videoInfo[@"title"]]];
                                                                            }]];

                                                        [alertController
                                                            addAction:[UIAlertAction
                                                                          actionWithTitle:@"Cancel"
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
                              initWithNavTitle:@"Manage Videos"
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

    // picker logic WIP
    NSUInteger wordCount               = [[WordManager sharedInstance] blockedWords].count;
    YTSettingsSectionItem *manageWords = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Manage Words"
               titleDescription:[NSString stringWithFormat:@"%lu blocked word%@", (unsigned long)wordCount,
                                                           wordCount == 1 ? @"" : @"s"]
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

                        ListViewController *vc = [ListViewController new];

                        vc.titleText = @"Manage Words";
                        vc.itemType = @"word";
                        vc.loadItemsBlock = ^NSArray *{
                            return [[WordManager sharedInstance] blockedWords];
                        };
                        vc.removeItemBlock = ^(NSString *text) {
                            [[WordManager sharedInstance] removeBlockedWord:text];
                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Deleted \"%@\"", text]];
                        };
                        vc.removeSelectedItemsBlock = ^(NSArray<NSString *> *texts) {
                            NSMutableArray *updatedWords =
                                [[[WordManager sharedInstance] blockedWords] mutableCopy];
                            if (!updatedWords) {
                                updatedWords = [NSMutableArray array];
                            }

                            [updatedWords removeObjectsInArray:texts];
                            [[WordManager sharedInstance] setBlockedWords:updatedWords];

                            if (texts.count == 1) {
                                [self showGonerinoToastWithMessage:
                                    [NSString stringWithFormat:@"Deleted \"%@\"", texts.firstObject]];
                            } else {
                                [self showMultipleDeleteToastForItemType:@"word" count:texts.count];
                            }
                        };
                        vc.moveItemBlock = ^(NSInteger fromIndex, NSInteger toIndex) {
                            NSMutableArray *updatedWords =
                                [[[WordManager sharedInstance] blockedWords] mutableCopy];
                            if (!updatedWords) return;

                            if (fromIndex < 0 || toIndex < 0 ||
                                fromIndex >= updatedWords.count ||
                                toIndex >= updatedWords.count) {
                                return;
                            }

                            NSString *item = updatedWords[fromIndex];
                            [updatedWords removeObjectAtIndex:fromIndex];
                            [updatedWords insertObject:item atIndex:toIndex];

                            [[WordManager sharedInstance] setBlockedWords:updatedWords];
                        };

                        vc.addItemBlock = ^(NSString *newText) {
                            [[WordManager sharedInstance] addBlockedWord:newText];

                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Added \"%@\"", newText]];
                        };

                        vc.editItemBlock = ^(NSInteger index, NSString *oldText, NSString *newText) {
                            NSMutableArray<NSString *> *updatedWords =
                                [[[WordManager sharedInstance] blockedWords] mutableCopy];
                            if (!updatedWords) {
                                updatedWords = [NSMutableArray array];
                            }

                            if (index < 0 || index >= updatedWords.count) {
                                return;
                            }

                            updatedWords[index] = newText;
                            [[WordManager sharedInstance] setBlockedWords:updatedWords];

                            [self showGonerinoToastWithMessage:
                                [NSString stringWithFormat:@"Edited \"%@\" → \"%@\"", oldText, newText]];
                        };

                        YTSettingsViewController *delegate =
                        [self valueForKey:@"_settingsViewControllerDelegate"];

                        [delegate.navigationController pushViewController:vc animated:YES];

                        return YES;
                    }];

    [sectionItems addObject:manageWords];

    YTSettingsSectionItem *blockPeopleWatched = [%c(YTSettingsSectionItem)
            switchItemWithTitle:@"Block 'People also watched this video'"
               titleDescription:@"Remove 'People also watched' suggestions"
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoPeopleWatched"];
                        [self showGonerinoToastWithMessage:
                            [NSString stringWithFormat:@"'People also watched' %@",
                                                       enabled ? @"blocked" : @"unblocked"]];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:blockPeopleWatched];

    YTSettingsSectionItem *blockMightLike = [%c(YTSettingsSectionItem)
            switchItemWithTitle:@"Block 'You might also like this'"
               titleDescription:@"Remove 'You might also like this' suggestions"
        accessibilityIdentifier:nil
                       switchOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]
                    switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
                        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"GonerinoMightLike"];
                        [self showGonerinoToastWithMessage:
                            [NSString stringWithFormat:@"'You might also like' %@",
                                                       enabled ? @"blocked" : @"unblocked"]];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:blockMightLike];

    SECTION_HEADER(@"Manage Settings");

    YTSettingsSectionItem *exportSettings = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Export Settings"
               titleDescription:@"Export settings to a plist file"
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];

                        NSMutableDictionary *settings = [NSMutableDictionary dictionary];
                        settings[@"blockedChannels"]  = [[ChannelManager sharedInstance] blockedChannels];
                        settings[@"blockedVideos"]    = [[VideoManager sharedInstance] blockedVideos];
                        settings[@"blockedWords"]     = [[WordManager sharedInstance] blockedWords];
                        settings[@"gonerinoEnabled"] =
                            @([[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoEnabled"] == nil
                                  ? YES
                                  : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoEnabled"]);
                        settings[@"useCustomToast"] =
                            @([[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoUseCustomToast"] == nil
                                  ? YES
                                  : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoUseCustomToast"]);
                        settings[@"blockPeopleWatched"] =
                            @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"]);
                        settings[@"blockMightLike"] =
                            @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]);

                        NSURL *tempFileURL =
                            [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                                       stringByAppendingPathComponent:@"gonerino_settings.plist"]];
                        [settings writeToURL:tempFileURL atomically:YES];

                        isImportOperation = NO;

                        UIDocumentPickerViewController *picker =
                            [[UIDocumentPickerViewController alloc] initForExportingURLs:@[tempFileURL]];
                        picker.delegate = (id<UIDocumentPickerDelegate>)self;
                        [settingsVC presentViewController:picker animated:YES completion:nil];
                        return YES;
                    }];
    [sectionItems addObject:exportSettings];

    YTSettingsSectionItem *importSettings = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Import Settings"
               titleDescription:@"Import settings from a plist file"
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];

                        isImportOperation = YES;

                        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
                            initForOpeningContentTypes:@[[UTType typeWithIdentifier:@"com.apple.property-list"]]];
                        picker.delegate                        = (id<UIDocumentPickerDelegate>)self;
                        [settingsVC presentViewController:picker animated:YES completion:nil];
                        return YES;
                    }];
    [sectionItems addObject:importSettings];

    SECTION_HEADER(@"About");

    [sectionItems
        addObject:[%c(YTSettingsSectionItem) itemWithTitle:@"GitHub"
                                                     titleDescription:@"View source code and report issues"
                                              accessibilityIdentifier:nil
                                                      detailTextBlock:nil
                                                          selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                                                              return [%c(YTUIUtils)
                                                                  openURL:[NSURL URLWithString:@"https://github.com/"
                                                                                               @"castdrian/Gonerino"]];
                                                          }]];

    [sectionItems
        addObject:[%c(YTSettingsSectionItem) itemWithTitle:@"Version"
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
                            title:@"Gonerino"
                             icon:icon
                 titleDescription:nil
                     headerHidden:NO];
    } else {
        [delegate setSectionItems:sectionItems
                      forCategory:GonerinoSection
                            title:@"Gonerino"
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
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0)
        return;

    NSURL *url                           = urls.firstObject;

    if (isImportOperation) {
        [url startAccessingSecurityScopedResource];

        NSError *error = nil;
        NSData *data   = [NSData dataWithContentsOfURL:url options:0 error:&error];

        [url stopAccessingSecurityScopedResource];

        if (!data || error) {
            [self showGonerinoToastWithMessage:@"Failed to read settings file"];
            return;
        }

        NSDictionary *settings = [NSPropertyListSerialization propertyListWithData:data
                                                                           options:NSPropertyListImmutable
                                                                            format:NULL
                                                                             error:&error];

        if (!settings || error) {
            [self showGonerinoToastWithMessage:@"Invalid settings file format"];
            return;
        }

        void (^continueImport)(void) = ^{
            NSArray *words = settings[@"blockedWords"];
            if (words) {
                [[WordManager sharedInstance] setBlockedWords:words];
            }

            NSNumber *peopleWatched = settings[@"blockPeopleWatched"];
            if (peopleWatched) {
                [[NSUserDefaults standardUserDefaults] setBool:[peopleWatched boolValue]
                                                        forKey:@"GonerinoPeopleWatched"];
            }

            NSNumber *mightLike = settings[@"blockMightLike"];
            if (mightLike) {
                [[NSUserDefaults standardUserDefaults] setBool:[mightLike boolValue] forKey:@"GonerinoMightLike"];
            }

            NSNumber *gonerinoEnabled = settings[@"gonerinoEnabled"];
            if (gonerinoEnabled) {
                [[NSUserDefaults standardUserDefaults] setBool:[gonerinoEnabled boolValue] forKey:@"GonerinoEnabled"];
            }

            NSNumber *useCustomToast = settings[@"useCustomToast"];
            if (useCustomToast) {
                [[NSUserDefaults standardUserDefaults] setBool:[useCustomToast boolValue]
                                                        forKey:@"GonerinoUseCustomToast"];
            }

            [[NSUserDefaults standardUserDefaults] synchronize];
            [self reloadGonerinoSection];
            [self showGonerinoToastWithMessage:@"Settings imported successfully"];
        };

        NSArray *channels = settings[@"blockedChannels"];
        if (channels) {
            [[ChannelManager sharedInstance] setBlockedChannels:channels];
        }

        NSArray *videos = settings[@"blockedVideos"];
        if (videos) {
            if ([videos isKindOfClass:[NSArray class]]) {
                BOOL isValidFormat = YES;
                for (id videoEntry in videos) {
                    if (![videoEntry isKindOfClass:[NSDictionary class]] ||
                        ![videoEntry[@"id"] isKindOfClass:[NSString class]] ||
                        ![videoEntry[@"title"] isKindOfClass:[NSString class]] ||
                        ![videoEntry[@"channel"] isKindOfClass:[NSString class]] || [videoEntry count] != 3) {
                        isValidFormat = NO;
                        break;
                    }
                }

                if (isValidFormat) {
                    [[VideoManager sharedInstance] setBlockedVideos:videos];
                    continueImport();
                } else {
                    [self showGonerinoToastWithMessage:@"Format outdated, blocked videos will not be imported"];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{ continueImport(); });
                }
            } else {
                [self showGonerinoToastWithMessage:@"Format outdated, blocked videos will not be imported"];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{ continueImport(); });
            }
        } else {
            continueImport();
        }
    } else {
        NSMutableDictionary *settings = [NSMutableDictionary dictionary];
        settings[@"blockedChannels"]  = [[ChannelManager sharedInstance] blockedChannels];
        settings[@"blockedVideos"]    = [[VideoManager sharedInstance] blockedVideos];
        settings[@"blockedWords"]     = [[WordManager sharedInstance] blockedWords];
        settings[@"gonerinoEnabled"]  = @([[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoEnabled"] == nil
                                              ? YES
                                              : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoEnabled"]);
        settings[@"useCustomToast"]   = @([[NSUserDefaults standardUserDefaults] objectForKey:@"GonerinoUseCustomToast"] == nil
                                              ? YES
                                              : [[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoUseCustomToast"]);
        settings[@"blockPeopleWatched"] =
            @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"]);
        settings[@"blockMightLike"] = @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]);

        [settings writeToURL:url atomically:YES];
        [self showGonerinoToastWithMessage:@"Settings exported successfully"];
    }
}

%new
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSString *message = isImportOperation ? @"Import cancelled" : @"Export cancelled";
    [self showGonerinoToastWithMessage:message];
}

%new
- (void)showGonerinoToastWithMessage:(NSString *)message {
    GonerinoShowToast(message);
}

%new
- (void)showMultipleDeleteToastForItemType:(NSString *)itemType count:(NSUInteger)count {
    NSString *message = [NSString stringWithFormat:@"Deleted %lu %@%@",
                                                   (unsigned long)count,
                                                   itemType,
                                                   count == 1 ? @"" : @"s"];
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
