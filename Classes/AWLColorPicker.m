//
//  AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLColorPicker.h"
#import "NSImage+AWLColorPicker.h"
#import "NSColor+AWLColorPicker.h"

static NSString *const gAWLColorPickerKeyImage = @"image";
static NSString *const gAWLColorPickerKeyTitle = @"title";
static NSString *const gAWLColorPickerKeyColor = @"color";

static NSString *const gAWLColorPickerUserDefaultsKeyColorList =
@"ua.com.wavelabs.AWLColorPicker:colorListName";

// Table Sorting: Automatic Table Sorting with NSArrayController

@implementation AWLColorPicker

- (void)awakeFromNib {
    // Fixing autolayout
    self.colorsPickerView.autoresizingMask =
    NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin |
    NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;

    [self p_initializeColorListsArrayControllerContents];
    
    [self p_switchColorList];
    self.colorsArrayController.selectionIndexes = [NSIndexSet indexSet];
    
    // Liteners for Color changes
    [self.colorsArrayController
     addObserver:self
     forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@",
                 gAWLColorPickerKeyTitle]
     options:NSKeyValueObservingOptionNew
     context:NULL];
    [self.colorsArrayController addObserver:self
                                 forKeyPath:@"selectionIndexes"
                                    options:NSKeyValueObservingOptionNew
                                    context:NULL];
    
    // Listeners for color list changes
    [self.colorListsArrayController addObserver:self
                                     forKeyPath:@"selectionIndex"
                                        options:NSKeyValueObservingOptionNew
                                        context:NULL];
    
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
    return NSLocalizedString(
                             @"AWL Picker", @"Tooltip for the color picker button in the color panel");
}

#pragma mark - NSColorPickingCustom

- (BOOL)supportsMode:(NSColorPanelMode)mode {
    switch (mode) {
        case NSColorPanelAllModesMask: // we support all modes
            return YES;
    }
    return NO;
}

- (NSColorPanelMode)currentMode {
    return NSColorPanelAllModesMask;
}

- (NSView *)provideNewView:(BOOL)initialRequest {
    if (initialRequest) {
        // Load our nib files
        static NSString *nibName = @"AWLColorPicker";
        if (![[NSBundle bundleForClass:self.class] loadNibNamed:nibName
                                                          owner:self
                                                topLevelObjects:nil]) {
            NSLog(@"ERROR: couldn't load %@ nib", nibName);
        }
    }
    return self.colorsPickerView;
}

- (void)setColor:(NSColor *)newColor {
    NSString *colorHEXCode = [[newColor awl_hexColor] uppercaseString];
    NSString *labelText = [NSString
                           stringWithFormat:@"%@ (%@)", colorHEXCode, newColor.colorSpaceName];
    self.labelColor.stringValue = labelText;
    NSLog(@"New color: %@", newColor);
}

#pragma mark - NSColorPickingDefault

- (void)viewSizeChanged:(id)sender {
    if ([sender isKindOfClass:NSView.class] == FALSE) {
        return;
    }
    // Do something with layout if needed
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.colorsArrayController) {
        NSArray *selectedColors = [object selectedObjects];
        if (selectedColors.count == 0) {
            return; // Empty selection
        }
        
        NSDictionary *dictionary =
        selectedColors[0]; // Expected array with only one element
        if ([keyPath hasSuffix:gAWLColorPickerKeyTitle]) {
            NSLog(@"Color name changed: %@", dictionary[gAWLColorPickerKeyTitle]);
        } else if ([keyPath isEqualToString:@"selectionIndexes"]) {
            NSLog(@"Table section changed: %@", dictionary[gAWLColorPickerKeyTitle]);
            NSColor *color = dictionary[gAWLColorPickerKeyColor];
            self.colorPanel.color = color;
        }
    } else if (object == self.colorListsArrayController) {
        [self p_switchColorList];
    }
}

#pragma mark -

- (void)p_initializeColorListsArrayControllerContents {
    // Getting color lists
    NSArray *colorLists = [NSColorList availableColorLists];
    if (colorLists.count == 0) {
        return;
    }
    // Preparing content
    NSArray* sortedColorLists = [colorLists sortedArrayUsingComparator:^NSComparisonResult(NSColorList* obj1, NSColorList* obj2) {
        return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
    }];
    self.colorListsArrayController.content = sortedColorLists;
    
    // Reading previously stored list name and searching for the right selection index.
    NSString *colorListName = [[NSUserDefaults standardUserDefaults]
                               stringForKey:gAWLColorPickerUserDefaultsKeyColorList];
    NSUInteger selectedColorListIndex = 0;
    if (colorListName != nil) {
        for (NSUInteger idx = 0; idx < sortedColorLists.count; idx++) {
            if ([[sortedColorLists[idx] name] isEqualToString:colorListName]) {
                selectedColorListIndex = idx;
                break;
            }
        }
    }
    // Selecting current color list
    self.colorListsArrayController.selectionIndex = selectedColorListIndex;
}

- (void)p_initializeColorsArrayControllerContents:(NSColorList *)aList {
    NSSize defaultImageSize = NSMakeSize(26, 14);
    NSArray *colorNames = [aList allKeys];
    NSMutableArray *content = [NSMutableArray array];
    for (NSString *colorName in colorNames) {
        NSColor *color = [aList colorWithKey:colorName];
        NSImage *image = [NSImage awl_swatchWithColor:color size:defaultImageSize];
        NSDictionary *dict = @{
                               gAWLColorPickerKeyImage : image,
                               gAWLColorPickerKeyTitle : colorName,
                               gAWLColorPickerKeyColor : color
                               };
        [content addObject:[dict mutableCopy]];
    }
    self.colorsArrayController.content = content;
}

- (void)p_switchColorList {
    NSArray *selectedColorLists =
    [self.colorListsArrayController selectedObjects];
    if (selectedColorLists.count == 0) {
        return; // Empty selection
    }
    NSColorList *colorList = selectedColorLists[0];
    NSLog(@"Color list changed: %@", colorList.name);
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:colorList.name forKey:gAWLColorPickerUserDefaultsKeyColorList];
    [defaults synchronize];
    
    [self p_initializeColorsArrayControllerContents:colorList];
}

@end
