#import "TextHelper.h"
#import <dispatch/dispatch.h>

#pragma mark - Internal Helpers

static NSString *TextHelperLocalizationBundlePath(void) {
    NSString *rootlessBundlePath =
        @"/var/jb/Library/Application Support/Gonerino.bundle";

    if ([[NSFileManager defaultManager] fileExistsAtPath:rootlessBundlePath]) {
        return rootlessBundlePath;
    }

    NSString *sideloadBundlePath =
        [[NSBundle mainBundle] pathForResource:@"Gonerino"
                                        ofType:@"bundle"];
    if (sideloadBundlePath.length > 0) {
        return sideloadBundlePath;
    }

    return nil;
}

static NSBundle *TextHelperLocalizationBundle(void) {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *bundlePath = TextHelperLocalizationBundlePath();
        if (bundlePath.length > 0) {
            bundle = [NSBundle bundleWithPath:bundlePath];
        }
    });

    return bundle;
}

static NSString *TextHelperLocalizedText(NSString *key) {
    NSBundle *bundle = TextHelperLocalizationBundle();
    if (!bundle) {
        return key;
    }

    return [bundle localizedStringForKey:key
                                   value:key
                                   table:nil];
}

static NSString *TextHelperNormalizedItemType(NSString *itemType) {
    if ([itemType isKindOfClass:[NSString class]] && itemType.length > 0) {
        return itemType;
    }

    return @"item";
}

#pragma mark - Item Names

NSString *TextHelperSingularNameForItemType(NSString *itemType) {
    NSString *normalizedItemType = TextHelperNormalizedItemType(itemType);

    if ([normalizedItemType isEqualToString:@"channel"]) {
        return TextHelperLocalizedText(@"texthelper.item.channel.singular");
    }

    if ([normalizedItemType isEqualToString:@"word"]) {
        return TextHelperLocalizedText(@"texthelper.item.word.singular");
    }

    if ([normalizedItemType isEqualToString:@"video"]) {
        return TextHelperLocalizedText(@"texthelper.item.video.singular");
    }

    return TextHelperLocalizedText(@"texthelper.item.item.singular");
}

NSString *TextHelperPluralNameForItemType(NSString *itemType) {
    NSString *normalizedItemType = TextHelperNormalizedItemType(itemType);

    if ([normalizedItemType isEqualToString:@"channel"]) {
        return TextHelperLocalizedText(@"texthelper.item.channel.plural");
    }

    if ([normalizedItemType isEqualToString:@"word"]) {
        return TextHelperLocalizedText(@"texthelper.item.word.plural");
    }

    if ([normalizedItemType isEqualToString:@"video"]) {
        return TextHelperLocalizedText(@"texthelper.item.video.plural");
    }

    return TextHelperLocalizedText(@"texthelper.item.item.plural");
}

#pragma mark - ListView

NSString *TextHelperSearchPlaceholder(void) {
    return TextHelperLocalizedText(@"texthelper.search.placeholder");
}

NSString *TextHelperEditButtonTitle(BOOL editing) {
    return editing
        ? TextHelperLocalizedText(@"texthelper.edit_button.done")
        : TextHelperLocalizedText(@"texthelper.edit_button.edit");
}

NSString *TextHelperCountDisplayText(NSUInteger count) {
    NSString *unit = (count == 1)
        ? TextHelperSingularNameForItemType(@"item")
        : TextHelperPluralNameForItemType(@"item");

    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.count.display"),
        (unsigned long)count,
        unit];
}

NSString *TextHelperNoItemsText(void) {
    return TextHelperLocalizedText(@"texthelper.list.empty.no_items");
}

NSString *TextHelperNoResultsText(void) {
    return TextHelperLocalizedText(@"texthelper.list.empty.no_results");
}

NSString *TextHelperSelectAllToolbarTitle(BOOL allSelected) {
    return allSelected
        ? TextHelperLocalizedText(@"texthelper.toolbar.deselect_all")
        : TextHelperLocalizedText(@"texthelper.toolbar.select_all");
}

NSDictionary<NSString *, NSString *> *TextHelperInputConfigForItemType(NSString *itemType,
                                                                       BOOL isEditing) {
    NSString *normalizedItemType = TextHelperNormalizedItemType(itemType);

    NSString *titleKey = isEditing
        ? @"texthelper.input.item.edit.title"
        : @"texthelper.input.item.add.title";
    NSString *messageKey = isEditing
        ? @"texthelper.input.item.edit.message"
        : @"texthelper.input.item.add.message";
    NSString *placeholderKey = @"texthelper.input.item.placeholder";

    if ([normalizedItemType isEqualToString:@"channel"]) {
        titleKey = isEditing
            ? @"texthelper.input.channel.edit.title"
            : @"texthelper.input.channel.add.title";
        messageKey = isEditing
            ? @"texthelper.input.channel.edit.message"
            : @"texthelper.input.channel.add.message";
        placeholderKey = @"texthelper.input.channel.placeholder";
    } else if ([normalizedItemType isEqualToString:@"word"]) {
        titleKey = isEditing
            ? @"texthelper.input.word.edit.title"
            : @"texthelper.input.word.add.title";
        messageKey = isEditing
            ? @"texthelper.input.word.edit.message"
            : @"texthelper.input.word.add.message";
        placeholderKey = @"texthelper.input.word.placeholder";
    }

    return @{
        @"title": TextHelperLocalizedText(titleKey),
        @"message": TextHelperLocalizedText(messageKey),
        @"placeholder": TextHelperLocalizedText(placeholderKey)
    };
}

NSString *TextHelperSaveActionTitle(void) {
    return TextHelperLocalizedText(@"texthelper.action.save");
}

NSString *TextHelperCancelActionTitle(void) {
    return TextHelperLocalizedText(@"texthelper.action.cancel");
}

#pragma mark - CRUD Toasts

NSString *TextHelperAlreadyExistsToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.already_exists"),
        text ?: @""];
}

NSString *TextHelperNoChangesToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.no_changes"),
        text ?: @""];
}

NSString *TextHelperCopiedToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.copied"),
        text ?: @""];
}

NSString *TextHelperDeletedQuotedToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.deleted_quoted"),
        text ?: @""];
}

NSString *TextHelperDeletedPlainToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.deleted_plain"),
        text ?: @""];
}

NSString *TextHelperAddedQuotedToast(NSString *text) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.added_quoted"),
        text ?: @""];
}

NSString *TextHelperEditedToast(NSString *oldText, NSString *newText) {
    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.toast.edited"),
        oldText ?: @"",
        newText ?: @""];
}

#pragma mark - Count / Delete

NSString *TextHelperBlockedCountDescription(NSString *itemType, NSUInteger count) {
    NSString *name = (count == 1)
        ? TextHelperSingularNameForItemType(itemType)
        : TextHelperPluralNameForItemType(itemType);

    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.count.blocked"),
        (unsigned long)count,
        name];
}

NSString *TextHelperDeleteTitle(NSString *itemType, NSUInteger count) {
    NSString *name = (count == 1)
        ? TextHelperSingularNameForItemType(itemType)
        : TextHelperPluralNameForItemType(itemType);

    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.delete.title"),
        name];
}

NSString *TextHelperDeleteMessage(NSString *itemType,
                                  NSUInteger count,
                                  NSString *selectedText) {
    if (count == 1) {
        if ([selectedText isKindOfClass:[NSString class]] &&
            selectedText.length > 0) {
            return [NSString stringWithFormat:
                TextHelperLocalizedText(@"texthelper.delete.message.single_selected"),
                selectedText];
        }

        return [NSString stringWithFormat:
            TextHelperLocalizedText(@"texthelper.delete.message.single_generic"),
            TextHelperSingularNameForItemType(itemType)];
    }

    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.delete.message.multiple"),
        (unsigned long)count,
        TextHelperPluralNameForItemType(itemType),
        TextHelperSingularNameForItemType(itemType)];
}

NSString *TextHelperDeleteToolbarTitle(void) {
    return TextHelperLocalizedText(@"texthelper.toolbar.delete");
}

NSString *TextHelperDeleteActionTitle(void) {
    return TextHelperLocalizedText(@"texthelper.action.delete");
}

NSString *TextHelperMultipleDeleteToast(NSString *itemType, NSUInteger count) {
    NSString *name = (count == 1)
        ? TextHelperSingularNameForItemType(itemType)
        : TextHelperPluralNameForItemType(itemType);

    return [NSString stringWithFormat:
        TextHelperLocalizedText(@"texthelper.delete.toast.multiple"),
        (unsigned long)count,
        name,
        TextHelperSingularNameForItemType(itemType)];
}

#pragma mark - Settings

NSString *TextHelperGonerinoSettingsHeaderTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.header.gonerino");
}

NSString *TextHelperGonerinoSectionTitle(void) {
    return @"Gonerino";
}

NSString *TextHelperShowGonerinoButtonTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.show_button.title");
}

NSString *TextHelperShowGonerinoButtonDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.show_button.description");
}

NSString *TextHelperGonerinoButtonVisibilityToast(BOOL enabled) {
    return enabled
        ? TextHelperLocalizedText(@"texthelper.toast.show_button.enabled")
        : TextHelperLocalizedText(@"texthelper.toast.show_button.disabled");
}

NSString *TextHelperUseGonerinoToastTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.use_toast.title");
}

NSString *TextHelperUseGonerinoToastDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.use_toast.description");
}

NSString *TextHelperToastModeToast(BOOL enabled) {
    return enabled
        ? TextHelperLocalizedText(@"texthelper.toast.mode.gonerino")
        : TextHelperLocalizedText(@"texthelper.toast.mode.youtube");
}

NSString *TextHelperManageChannelsTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.manage_channels");
}

NSString *TextHelperManageVideosTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.manage_videos");
}

NSString *TextHelperManageWordsTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.manage_words");
}

NSString *TextHelperNoBlockedVideosToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.no_blocked_videos");
}

NSString *TextHelperBlockedVideosRowDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.blocked_videos_row");
}

NSString *TextHelperUnknownChannelText(void) {
    return TextHelperLocalizedText(@"texthelper.settings.unknown_channel");
}

NSString *TextHelperUnknownTitleText(void) {
    return TextHelperLocalizedText(@"texthelper.settings.unknown_title");
}

NSString *TextHelperBlockPeopleWatchedTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.people_watched.title");
}

NSString *TextHelperBlockPeopleWatchedDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.people_watched.description");
}

NSString *TextHelperPeopleWatchedToggleToast(BOOL enabled) {
    return enabled
        ? TextHelperLocalizedText(@"texthelper.toast.people_watched.enabled")
        : TextHelperLocalizedText(@"texthelper.toast.people_watched.disabled");
}

NSString *TextHelperBlockMightLikeTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.might_like.title");
}

NSString *TextHelperBlockMightLikeDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.might_like.description");
}

NSString *TextHelperMightLikeToggleToast(BOOL enabled) {
    return enabled
        ? TextHelperLocalizedText(@"texthelper.toast.might_like.enabled")
        : TextHelperLocalizedText(@"texthelper.toast.might_like.disabled");
}

NSString *TextHelperManageSettingsHeaderTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.header.manage");
}

NSString *TextHelperExportSettingsTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.export.title");
}

NSString *TextHelperExportSettingsDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.export.description");
}

NSString *TextHelperImportSettingsTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.import.title");
}

NSString *TextHelperImportSettingsDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.import.description");
}

NSString *TextHelperAboutHeaderTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.header.about");
}

NSString *TextHelperGitHubTitle(void) {
    return @"GitHub";
}

NSString *TextHelperGitHubDescription(void) {
    return TextHelperLocalizedText(@"texthelper.settings.github.description");
}

NSString *TextHelperVersionTitle(void) {
    return TextHelperLocalizedText(@"texthelper.settings.version.title");
}

#pragma mark - Import / Export Toasts

NSString *TextHelperFailedToReadSettingsFileToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.import.failed_read");
}

NSString *TextHelperInvalidSettingsFileFormatToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.import.invalid_format");
}

NSString *TextHelperSettingsImportedSuccessfullyToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.import.success");
}

NSString *TextHelperOutdatedBlockedVideosFormatToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.import.outdated_videos");
}

NSString *TextHelperSettingsExportedSuccessfullyToast(void) {
    return TextHelperLocalizedText(@"texthelper.toast.export.success");
}

NSString *TextHelperImportExportCancelledToast(BOOL isImportOperation) {
    return isImportOperation
        ? TextHelperLocalizedText(@"texthelper.toast.import.cancelled")
        : TextHelperLocalizedText(@"texthelper.toast.export.cancelled");
}
