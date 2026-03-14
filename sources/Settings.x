#import "Settings.h"
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

static void gonerinoFeedback(YTSettingsViewController *settingsVC, NSString *message) {
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [generator prepare];
    [generator impactOccurred];
    
    [[%c(YTToastResponderEvent) eventWithMessage:message firstResponder:settingsVC] send];
}

typedef struct {
    NSString *title;
    NSString *addTitle;
    NSString *deleteTitle;
    NSString *editTitle;
    NSString *addDescription;
    NSString *inputDescription;
    NSString *placeholder;
} GonerinoPickerConfig;

// Shared picker helper extracted from the original
// Manage Channels / Manage Words implementations
static void openPicker(
    YTSettingsSectionItemManager *self,
    GonerinoPickerConfig config,
    NSArray *items,
    void (^addBlock)(NSString *text),
    void (^deleteBlock)(NSString *text),
    void (^editBlock)(NSString *oldText, NSString *newText)
) {
    YTSettingsViewController *settingsVC =
        [self valueForKey:@"_settingsViewControllerDelegate"];

    NSMutableArray *rows = [NSMutableArray array];

    [rows addObject:[%c(YTSettingsSectionItem)
        itemWithTitle:config.addTitle
        titleDescription:config.addDescription
        accessibilityIdentifier:nil
        detailTextBlock:nil
        selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

        UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:config.addTitle
                                            message:config.inputDescription
                                     preferredStyle:UIAlertControllerStyleAlert];

        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = config.placeholder;
        }];

        [alert addAction:[UIAlertAction actionWithTitle:@"Add"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *a) {

            NSString *text = alert.textFields.firstObject.text;

            if (text.length > 0) {
                addBlock(text);
                gonerinoFeedback(settingsVC, [NSString stringWithFormat:@"Added %@", text]);
                [self reloadGonerinoSection];
            }

        }]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];

        [settingsVC presentViewController:alert animated:YES completion:nil];

        return YES;
    }]];

    for (NSString *item in items) {

        [rows addObject:[%c(YTSettingsSectionItem)
            itemWithTitle:item
            titleDescription:nil
            accessibilityIdentifier:nil
            detailTextBlock:nil
            selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {

            UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:config.deleteTitle
                                                message:[NSString stringWithFormat:@"Are you sure you want to delete '%@'?",item]
                                         preferredStyle:UIAlertControllerStyleAlert];

            [alert addAction:[UIAlertAction actionWithTitle:@"Edit"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *a) {

                [self presentEditAlertWithTitle:config.editTitle
                                     initialText:item
                                      saveBlock:^(NSString *newText) {

                    editBlock(item,newText);
                    gonerinoFeedback(settingsVC, [NSString stringWithFormat:@"Edited %@ → %@", item, newText]);
                }];

            }]];

            [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                                      style:UIAlertActionStyleDestructive
                                                    handler:^(UIAlertAction *a) {

                deleteBlock(item);
                gonerinoFeedback(settingsVC, [NSString stringWithFormat:@"Deleted %@", item]);
                [self reloadGonerinoSection];

            }]];

            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];

            [settingsVC presentViewController:alert animated:YES completion:nil];

            return YES;
        }]];
    }

    YTSettingsPickerViewController *picker =
    [[%c(YTSettingsPickerViewController) alloc]
        initWithNavTitle:config.title
        pickerSectionTitle:nil
        rows:rows
        selectedItemIndex:NSNotFound
        parentResponder:[self parentResponder]];

    [settingsVC.navigationController pushViewController:picker animated:YES];
}

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
                        YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];
                        [[%c(YTToastResponderEvent)
                            eventWithMessage:[NSString
                                                 stringWithFormat:@"Gonerino button %@", enabled ? @"shown" : @"hidden"]
                              firstResponder:settingsVC] send];
                        return YES;
                    }
                  settingItemId:0];
    [sectionItems addObject:showButtonToggle];

    // picker logic moved to openPicker()
    NSUInteger channelCount               = [[ChannelManager sharedInstance] blockedChannels].count;
    YTSettingsSectionItem *manageChannels = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Manage Channels"
               titleDescription:[NSString stringWithFormat:@"%lu blocked channel%@", (unsigned long)channelCount,
                                                           channelCount == 1 ? @"" : @"s"]
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        GonerinoPickerConfig config = {
                            .title = @"Manage Channels",
                            .addTitle = @"Add Channel",
                            .deleteTitle = @"Delete Channel",
                            .editTitle = @"Edit Channel",
                            .addDescription = @"Block a new channel",
                            .inputDescription = @"Enter the channel name to block",
                            .placeholder = @"Channel Name"
                        };
                        openPicker(
                            self,
                            config,
                            [[ChannelManager sharedInstance] blockedChannels],
                            ^(NSString *text) {
                                [[ChannelManager sharedInstance] addBlockedChannel:text];
                            },
                            ^(NSString *text) {
                                [[ChannelManager sharedInstance] removeBlockedChannel:text];
                            },
                            ^(NSString *oldText, NSString *newText) {
                                NSMutableArray *channels =
                                    [[[ChannelManager sharedInstance] blockedChannels] mutableCopy];
                                NSUInteger index = [channels indexOfObject:oldText];
                                if (index != NSNotFound) {
                                    channels[index] = newText;
                                    [[ChannelManager sharedInstance] setBlockedChannels:channels];
                                }
                            });
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
                            YTSettingsViewController *settingsVC =
                                [self valueForKey:@"_settingsViewControllerDelegate"];
                            [[%c(YTToastResponderEvent) eventWithMessage:@"No blocked videos"
                                                                     firstResponder:settingsVC] send];
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

                                                                                [[%c(YTToastResponderEvent)
                                                                                    eventWithMessage:
                                                                                        [NSString
                                                                                            stringWithFormat:
                                                                                                @"Deleted %@",
                                                                                                videoInfo[@"title"]]
                                                                                      firstResponder:settingsVC] send];
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

    // picker logic moved to openPicker()
    NSUInteger wordCount               = [[WordManager sharedInstance] blockedWords].count;
    YTSettingsSectionItem *manageWords = [%c(YTSettingsSectionItem)
                  itemWithTitle:@"Manage Words"
               titleDescription:[NSString stringWithFormat:@"%lu blocked word%@", (unsigned long)wordCount,
                                                           wordCount == 1 ? @"" : @"s"]
        accessibilityIdentifier:nil
                detailTextBlock:nil
                    selectBlock:^BOOL(YTSettingsCell *cell, NSUInteger arg1) {
                        GonerinoPickerConfig config = {
                            .title = @"Manage Words",
                            .addTitle = @"Add Word",
                            .deleteTitle = @"Delete Word",
                            .editTitle = @"Edit Word",
                            .addDescription = @"Block a new word or phrase",
                            .inputDescription = @"Enter a word or phrase to block",
                            .placeholder = @"Word or phrase"
                        };
                        openPicker(
                            self,
                            config,
                            [[WordManager sharedInstance] blockedWords],
                            ^(NSString *text) {
                                [[WordManager sharedInstance] addBlockedWord:text];
                            },
                            ^(NSString *text) {
                                [[WordManager sharedInstance] removeBlockedWord:text];
                            },
                            ^(NSString *oldText, NSString *newText) {
                                NSMutableArray *words =
                                    [[[WordManager sharedInstance] blockedWords] mutableCopy];

                                NSUInteger index = [words indexOfObject:oldText];

                                if (index != NSNotFound) {
                                    words[index] = newText;
                                    [[WordManager sharedInstance] setBlockedWords:words];
                                }
                            });
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
                        YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];
                        [[%c(YTToastResponderEvent)
                            eventWithMessage:[NSString stringWithFormat:@"'People also watched' %@",
                                                                        enabled ? @"blocked" : @"unblocked"]
                              firstResponder:settingsVC] send];
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
                        YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];
                        [[%c(YTToastResponderEvent)
                            eventWithMessage:[NSString stringWithFormat:@"'You might also like' %@",
                                                                        enabled ? @"blocked" : @"unblocked"]
                              firstResponder:settingsVC] send];
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

    YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];
    NSURL *url                           = urls.firstObject;

    if (isImportOperation) {
        [url startAccessingSecurityScopedResource];

        NSError *error = nil;
        NSData *data   = [NSData dataWithContentsOfURL:url options:0 error:&error];

        [url stopAccessingSecurityScopedResource];

        if (!data || error) {
            [[%c(YTToastResponderEvent) eventWithMessage:@"Failed to read settings file"
                                                     firstResponder:settingsVC] send];
            return;
        }

        NSDictionary *settings = [NSPropertyListSerialization propertyListWithData:data
                                                                           options:NSPropertyListImmutable
                                                                            format:NULL
                                                                             error:&error];

        if (!settings || error) {
            [[%c(YTToastResponderEvent) eventWithMessage:@"Invalid settings file format"
                                                     firstResponder:settingsVC] send];
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

            [[NSUserDefaults standardUserDefaults] synchronize];
            [self reloadGonerinoSection];
            [[%c(YTToastResponderEvent) eventWithMessage:@"Settings imported successfully"
                                                     firstResponder:settingsVC] send];
        };

        NSArray *channels = settings[@"blockedChannels"];
        if (channels) {
            [[ChannelManager sharedInstance] setBlockedChannels:[NSMutableArray arrayWithArray:channels]];
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
                    [[%c(YTToastResponderEvent)
                        eventWithMessage:@"Format outdated, blocked videos will not be imported"
                          firstResponder:settingsVC] send];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{ continueImport(); });
                }
            } else {
                [[%c(YTToastResponderEvent)
                    eventWithMessage:@"Format outdated, blocked videos will not be imported"
                      firstResponder:settingsVC] send];

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
        settings[@"blockPeopleWatched"] =
            @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoPeopleWatched"]);
        settings[@"blockMightLike"] = @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]);

        [settings writeToURL:url atomically:YES];
        [[%c(YTToastResponderEvent) eventWithMessage:@"Settings exported successfully"
                                                 firstResponder:settingsVC] send];
    }
}

%new
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];
    NSString *message                    = isImportOperation ? @"Import cancelled" : @"Export cancelled";
    [[%c(YTToastResponderEvent) eventWithMessage:message firstResponder:settingsVC] send];
}

%new
- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
replacementText:(NSString *)text {

    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    return YES;
}

%new
- (void)presentEditAlertWithTitle:(NSString *)title
                       initialText:(NSString *)text
                        saveBlock:(void (^)(NSString *newText))saveBlock {

    YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];

    UIAlertController *editController =
        [UIAlertController alertControllerWithTitle:title
                                            message:@"\n\n\n\n\n\n\n\n\n\n"
                                     preferredStyle:UIAlertControllerStyleAlert];

    UIFont *font = [UIFont systemFontOfSize:14];
    CGFloat height = font.lineHeight * 9 + 12;

    UITextView *textView =
        [[UITextView alloc] initWithFrame:CGRectMake(10, 58, 250, height)];

    textView.text = text;
    textView.font = font;
    textView.textContainerInset = UIEdgeInsetsMake(8, 4, 8, 4);
    textView.returnKeyType = UIReturnKeyDone;
    textView.delegate = (id<UITextViewDelegate>)self;

    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.smartQuotesType = UITextSmartQuotesTypeNo;
    textView.smartDashesType = UITextSmartDashesTypeNo;
    textView.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;

    textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
    textView.scrollEnabled = YES;

    textView.layer.borderWidth = 0.5;
    textView.layer.cornerRadius = 6;

    [editController.view addSubview:textView];

    [editController addAction:
        [UIAlertAction actionWithTitle:@"Save"
                                 style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {

        NSString *newText = textView.text;

        if (newText.length > 0) {
            saveBlock(newText);
            [self reloadGonerinoSection];
        }

    }]];

    [editController addAction:
        [UIAlertAction actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                               handler:nil]];

    [settingsVC presentViewController:editController animated:YES completion:nil];
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
