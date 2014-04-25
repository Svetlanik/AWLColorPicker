//
//  AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLColorPicker.h"
#import "NSImage+AWLColorPicker.h"

@implementation AWLColorPicker

- (void)awakeFromNib {
    NSSize defaultImageSize = NSMakeSize(26, 14);
    static NSString * const keyImage = @"image";
    static NSString * const keyTitle = @"title";
    
    NSImage * imageR = [NSImage awl_swatchWithColor:[NSColor redColor] size:defaultImageSize];
    NSImage * imageG = [NSImage awl_swatchWithColor:[NSColor greenColor] size:defaultImageSize];
    NSImage * imageB = [NSImage awl_swatchWithColor:[NSColor blueColor] size:defaultImageSize];
    
    NSMutableDictionary *colorsR = [@{keyImage: imageR, keyTitle: @"Red"} mutableCopy];
    NSMutableDictionary *colorsG = [@{keyImage: imageG, keyTitle: @"Green"} mutableCopy];
    NSMutableDictionary *colorsB = [@{keyImage: imageB, keyTitle: @"Blue"} mutableCopy];
    
    [self.colorsArrayController addObject:colorsR];
    [self.colorsArrayController addObject:colorsG];
    [self.colorsArrayController addObject:colorsB];
}

- (id)initWithPickerMask:(NSUInteger)mask
              colorPanel:(NSColorPanel *)owningColorPanel {
    return [super initWithPickerMask:mask colorPanel:owningColorPanel];
}

- (void)dealloc {
    self.colorsArrayController = nil;
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
        if (![[NSBundle bundleForClass:self.class] loadNibNamed:nibName owner:self topLevelObjects:nil]) {
            NSLog(@"ERROR: couldn't load %@ nib", nibName);
        }
    }
    return self.colorsPickerView;
}

- (void)setColor:(NSColor *)newColor {
    self.labelColor.textColor = newColor; // TODO: Dynamically update label text with color components values
    self.labelColor.stringValue = newColor.description;
}

#pragma mark -

- (void)colorChanged:(id)sender {
    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    CGFloat a = 0.5;
    
    if (sender == self.buttonRed) {
        r = 1;
    } else if (sender == self.buttonGreen) {
        g = 1;
    } else if (sender == self.buttonBlue) {
        b = 1;
    }
    self.colorPanel.color = [NSColor colorWithRed:r green:g blue:b alpha:a];
}

@end

