//
//  AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLColorPicker.h"
#import "NSImage+AWLColorPicker.h"

static NSString * const gAWLColorPickerKeyImage = @"image";
static NSString * const gAWLColorPickerKeyTitle = @"title";
static NSString * const gAWLColorPickerKeyColor = @"color";

// Table Sorting: Automatic Table Sorting with NSArrayController

@implementation AWLColorPicker

- (void)awakeFromNib {
    [self p_initializeArrayControllerContents];
    self.colorsArrayController.selectionIndexes = [NSIndexSet indexSet];
    // start listening for selection changes in our NSTableView's array controller
	[self.colorsArrayController addObserver:self
                                 forKeyPath: [NSString stringWithFormat:@"arrangedObjects.%@", gAWLColorPickerKeyTitle]
                                    options: NSKeyValueObservingOptionNew
                                    context: NULL];
    [self.colorsArrayController addObserver:self
                                 forKeyPath: @"selectionIndexes"
                                    options: NSKeyValueObservingOptionNew
                                    context: NULL];
    // This makes table view focused.
    [[self colorPanel] makeFirstResponder:self.colorsTableView];
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
    self.labelColor.stringValue = newColor.description;
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSArray *selectedColors = [object selectedObjects];
    if (selectedColors.count == 0) {
        return; // Empty selection
    }
    
    NSDictionary *dictionary = selectedColors[0]; // Expected array with only one element
    if ([keyPath hasSuffix:gAWLColorPickerKeyTitle]) {
        NSLog(@"Color name changed: %@", dictionary[gAWLColorPickerKeyTitle]);
    } else if([keyPath isEqualToString:@"selectionIndexes"]) {
        NSLog(@"Table section changed: %@", dictionary[gAWLColorPickerKeyTitle]);
        NSColor *color = dictionary[gAWLColorPickerKeyColor];
        self.colorPanel.color = color;
    }
}

#pragma mark -

- (void)p_initializeArrayControllerContents {
    
    // Color lists
    NSArray *colorLists = [NSColorList availableColorLists];
    if (colorLists.count == 0) {
        return;
    }
    
    NSSize defaultImageSize = NSMakeSize(26, 14);
    NSColorList *colorList = colorLists[0];
    NSArray *colorNames = [colorList allKeys];
    for (NSString* colorName in colorNames) {
        NSColor *color = [colorList colorWithKey:colorName];
        NSImage *image = [NSImage awl_swatchWithColor:color size:defaultImageSize];
        NSDictionary *dict = @{gAWLColorPickerKeyImage:image,
                               gAWLColorPickerKeyTitle:colorName,
                               gAWLColorPickerKeyColor:color};
        [self.colorsArrayController addObject:[dict mutableCopy]];
    }
}

@end

