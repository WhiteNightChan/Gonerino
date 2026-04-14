#import "SettingsExchangeHelper.h"
#import "TextHelper.h"

static BOOL gIsImportOperation = NO;

%hook YTSettingsSectionItemManager

%new
- (void)presentGonerinoSettingsExportPicker {
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

    gIsImportOperation = NO;

    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initForExportingURLs:@[tempFileURL]];
    picker.delegate = (id<UIDocumentPickerDelegate>)self;
    [settingsVC presentViewController:picker animated:YES completion:nil];
}

%new
- (void)presentGonerinoSettingsImportPicker {
    YTSettingsViewController *settingsVC = [self valueForKey:@"_settingsViewControllerDelegate"];

    gIsImportOperation = YES;

    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc]
        initForOpeningContentTypes:@[[UTType typeWithIdentifier:@"com.apple.property-list"]]];
    picker.delegate = (id<UIDocumentPickerDelegate>)self;
    [settingsVC presentViewController:picker animated:YES completion:nil];
}

%new
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count == 0)
        return;

    NSURL *url = urls.firstObject;

    if (gIsImportOperation) {
        [url startAccessingSecurityScopedResource];

        NSError *error = nil;
        NSData *data   = [NSData dataWithContentsOfURL:url options:0 error:&error];

        [url stopAccessingSecurityScopedResource];

        if (!data || error) {
            [self showGonerinoToastWithMessage:TextHelperFailedToReadSettingsFileToast()];
            return;
        }

        NSDictionary *settings = [NSPropertyListSerialization propertyListWithData:data
                                                                           options:NSPropertyListImmutable
                                                                            format:NULL
                                                                             error:&error];

        if (!settings || error) {
            [self showGonerinoToastWithMessage:TextHelperInvalidSettingsFileFormatToast()];
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
                [[NSUserDefaults standardUserDefaults] setBool:[mightLike boolValue]
                                                        forKey:@"GonerinoMightLike"];
            }

            NSNumber *gonerinoEnabled = settings[@"gonerinoEnabled"];
            if (gonerinoEnabled) {
                [[NSUserDefaults standardUserDefaults] setBool:[gonerinoEnabled boolValue]
                                                        forKey:@"GonerinoEnabled"];
            }

            NSNumber *useCustomToast = settings[@"useCustomToast"];
            if (useCustomToast) {
                [[NSUserDefaults standardUserDefaults] setBool:[useCustomToast boolValue]
                                                        forKey:@"GonerinoUseCustomToast"];
            }

            [[NSUserDefaults standardUserDefaults] synchronize];
            // [self reloadGonerinoSection]; // Broken
            [self showGonerinoToastWithMessage:TextHelperSettingsImportedSuccessfullyToast()];
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
                        ![videoEntry[@"channel"] isKindOfClass:[NSString class]] ||
                        [videoEntry count] != 3) {
                        isValidFormat = NO;
                        break;
                    }
                }

                if (isValidFormat) {
                    [[VideoManager sharedInstance] setBlockedVideos:videos];
                    continueImport();
                } else {
                    [self showGonerinoToastWithMessage:TextHelperOutdatedBlockedVideosFormatToast()];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                                   dispatch_get_main_queue(), ^{
                                       continueImport();
                                   });
                }
            } else {
                [self showGonerinoToastWithMessage:TextHelperOutdatedBlockedVideosFormatToast()];

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                                   continueImport();
                               });
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
        settings[@"blockMightLike"] =
            @([[NSUserDefaults standardUserDefaults] boolForKey:@"GonerinoMightLike"]);

        [settings writeToURL:url atomically:YES];
        [self showGonerinoToastWithMessage:TextHelperSettingsExportedSuccessfullyToast()];
    }
}

%new
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    NSString *message = TextHelperImportExportCancelledToast(gIsImportOperation);
    [self showGonerinoToastWithMessage:message];
}

%end
