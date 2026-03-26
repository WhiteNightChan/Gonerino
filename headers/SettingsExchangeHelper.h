#import "Settings.h"

@interface YTSettingsSectionItemManager (SettingsExchange)

- (void)presentGonerinoSettingsExportPicker;
- (void)presentGonerinoSettingsImportPicker;

- (void)reloadGonerinoSection;
- (void)showGonerinoToastWithMessage:(NSString *)message;

@end
