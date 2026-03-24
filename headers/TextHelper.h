#import <Foundation/Foundation.h>

#pragma mark - Item Names

NSString *TextHelperSingularNameForItemType(NSString *itemType);
NSString *TextHelperPluralNameForItemType(NSString *itemType);

#pragma mark - ListView

NSString *TextHelperSearchPlaceholder(void);

NSString *TextHelperEditButtonTitle(BOOL editing);
NSString *TextHelperCountDisplayText(NSUInteger count);

NSString *TextHelperNoItemsText(void);
NSString *TextHelperNoResultsText(void);

NSString *TextHelperSelectAllToolbarTitle(BOOL allSelected);

NSDictionary<NSString *, NSString *> *TextHelperInputConfigForItemType(NSString *itemType,
                                                                       BOOL isEditing);

NSString *TextHelperSaveActionTitle(void);
NSString *TextHelperCancelActionTitle(void);

#pragma mark - CRUD Toasts

NSString *TextHelperAlreadyExistsToast(NSString *text);
NSString *TextHelperNoChangesToast(NSString *text);
NSString *TextHelperCopiedToast(NSString *text);
NSString *TextHelperDeletedQuotedToast(NSString *text);
NSString *TextHelperDeletedPlainToast(NSString *text);
NSString *TextHelperAddedQuotedToast(NSString *text);
NSString *TextHelperEditedToast(NSString *oldText, NSString *newText);

#pragma mark - Count / Delete

NSString *TextHelperBlockedCountDescription(NSString *itemType, NSUInteger count);

NSString *TextHelperDeleteTitle(NSString *itemType, NSUInteger count);
NSString *TextHelperDeleteMessage(NSString *itemType,
                                  NSUInteger count,
                                  NSString *selectedText);
NSString *TextHelperDeleteToolbarTitle(void);
NSString *TextHelperDeleteActionTitle(void);
NSString *TextHelperMultipleDeleteToast(NSString *itemType, NSUInteger count);

#pragma mark - Settings

NSString *TextHelperGonerinoSettingsHeaderTitle(void);
NSString *TextHelperGonerinoSectionTitle(void);

NSString *TextHelperShowGonerinoButtonTitle(void);
NSString *TextHelperShowGonerinoButtonDescription(void);
NSString *TextHelperGonerinoButtonVisibilityToast(BOOL enabled);

NSString *TextHelperUseGonerinoToastTitle(void);
NSString *TextHelperUseGonerinoToastDescription(void);
NSString *TextHelperToastModeToast(BOOL enabled);

NSString *TextHelperManageChannelsTitle(void);
NSString *TextHelperManageVideosTitle(void);
NSString *TextHelperManageWordsTitle(void);

NSString *TextHelperNoBlockedVideosToast(void);
NSString *TextHelperBlockedVideosRowDescription(void);
NSString *TextHelperUnknownChannelText(void);
NSString *TextHelperUnknownTitleText(void);

NSString *TextHelperBlockPeopleWatchedTitle(void);
NSString *TextHelperBlockPeopleWatchedDescription(void);
NSString *TextHelperPeopleWatchedToggleToast(BOOL enabled);

NSString *TextHelperBlockMightLikeTitle(void);
NSString *TextHelperBlockMightLikeDescription(void);
NSString *TextHelperMightLikeToggleToast(BOOL enabled);

NSString *TextHelperManageSettingsHeaderTitle(void);
NSString *TextHelperExportSettingsTitle(void);
NSString *TextHelperExportSettingsDescription(void);
NSString *TextHelperImportSettingsTitle(void);
NSString *TextHelperImportSettingsDescription(void);

NSString *TextHelperAboutHeaderTitle(void);
NSString *TextHelperGitHubTitle(void);
NSString *TextHelperGitHubDescription(void);
NSString *TextHelperVersionTitle(void);

#pragma mark - Import / Export Toasts

NSString *TextHelperFailedToReadSettingsFileToast(void);
NSString *TextHelperInvalidSettingsFileFormatToast(void);
NSString *TextHelperSettingsImportedSuccessfullyToast(void);
NSString *TextHelperOutdatedBlockedVideosFormatToast(void);
NSString *TextHelperSettingsExportedSuccessfullyToast(void);
NSString *TextHelperImportExportCancelledToast(BOOL isImportOperation);
