//
//  AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLColorPicker.h"

@interface NSBundle (AWLColorPicker)
+ (BOOL)awl_loadNibNamed:(NSString*)aNibName forBundleWithIdentifier:(NSString*)aBundleIdentifier owner:(id)anOwner;
@end

#pragma mark -

@implementation AWLColorPicker

- (id)initWithPickerMask:(NSUInteger)mask
              colorPanel:(NSColorPanel *)owningColorPanel {
    return [super initWithPickerMask:mask colorPanel:owningColorPanel];
}

- (void)dealloc {

}

- (NSString *)buttonToolTip {
    return NSLocalizedString(@"AWL Picker", @"Tooltip for the color picker button in the color panel");
}

#pragma mark - NSColorPickingCustom

- (BOOL)supportsMode:(NSColorPanelMode)mode {
    return (mode == NSRGBModeColorPanel) ? YES : NO;
}

- (NSColorPanelMode)currentMode {
    return NSRGBModeColorPanel;
}

- (NSView *)provideNewView:(BOOL)initialRequest {
    if (initialRequest) {
        // Load our nib files
        static NSString *nibName = @"AWLColorPicker";
        static NSString *bundleID = @"ua.com.wavelabs.AWLColorPicker";
        if (![NSBundle awl_loadNibNamed:nibName forBundleWithIdentifier:bundleID owner:self]) {
            NSLog(@"ERROR: couldn't load %@ nib", nibName);
        }
    }
    return self.colorPickerView;
}

- (void)setColor:(NSColor *)newColor {
    self.labelColor.textColor = newColor; // TODO: Dynamically update label text with color components values
}

#pragma mark -

- (void)colorChanged:(id)sender {
    if (sender == self.buttonRed) {
        self.colorPanel.color = [NSColor redColor];
    } else if (sender == self.buttonGreen) {
        self.colorPanel.color = [NSColor greenColor];
    } else if (sender == self.buttonBlue) {
        self.colorPanel.color = [NSColor blueColor];
    }
}

@end

#pragma mark -

@implementation NSBundle (AWLColorPicker)
+ (BOOL)awl_loadNibNamed:(NSString*)aNibName forBundleWithIdentifier:(NSString*)aBundleIdentifier owner:(id)anOwner {
    /// loadNibNamed:owner:topLevelObjects was introduced in 10.8 (Mountain Lion).
    /// In order to support Lion and Mountain Lion +, we need to see which OS we're
    /// on. We do this by testing to see if [NSBundle mainBundle] responds to
    /// loadNibNamed:owner:topLevelObjects: ... If so, the app is running on at least
    /// Mountain Lion... If not, then the app is running on Lion so we fall back to the
    /// the older loadNibNamed:owner: method. If your app does not support Lion, then
    /// you can go with strictly the newer one and not deal with the if/else conditional.
    /// @see http://goo.gl/BFEQJd
    if ([[NSBundle mainBundle] respondsToSelector:@selector(loadNibNamed:owner:topLevelObjects:)]) {
        // We're running on Mountain Lion or higher
        return [[NSBundle bundleWithIdentifier:aBundleIdentifier] loadNibNamed:aNibName
                                                                         owner:anOwner
                                                               topLevelObjects:nil];
    } else {
        // We're running on Lion
        return [NSBundle loadNibNamed:aNibName
                                owner:anOwner];
    }
}
@end
