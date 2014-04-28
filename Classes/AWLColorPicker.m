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

static int colorObservanceContext = 0;
static int colorListsObservanceContext = 0;

// Table Sorting: Automatic Table Sorting with NSArrayController
@interface AWLColorPicker ()
@property(assign) BOOL colorChangeInProgress;
@end

@implementation AWLColorPicker

- (void)awakeFromNib {
    // Fixing autolayout
    self.colorsPickerView.autoresizingMask =
    NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin |
    NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;
    
    [self p_initializeColorListsArrayControllerContents];
    [self p_switchColorList];
    
    // Listeners for color list changes
    [self.colorListsArrayController addObserver:self
                                     forKeyPath:@"selectionIndex"
                                        options:NSKeyValueObservingOptionNew
                                        context:&colorListsObservanceContext];
    
    // This makes table view focused.
    [[self colorPanel] makeFirstResponder:self.colorsTableView];
}

- (id)initWithPickerMask:(NSUInteger)mask
              colorPanel:(NSColorPanel *)owningColorPanel {
    return [super initWithPickerMask:mask colorPanel:owningColorPanel];
}

- (void)dealloc {
    self.colorsArrayController = nil;
    self.colorListsArrayController = nil;
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
    NSString *colorHEXCode = [newColor awl_hexadecimalValue];
    NSString *labelText = [NSString
                           stringWithFormat:@"%@ (%@)", colorHEXCode, newColor.colorSpaceName];
    self.labelColor.stringValue = labelText;
    NSLog(@"New color: %@", newColor);
    if (self.colorChangeInProgress == NO) {
        BOOL isMatchedColorFound = NO;
        for (NSDictionary *dictionary in self.colorsArrayController
             .arrangedObjects) {
            NSColor *color = dictionary[gAWLColorPickerKeyColor];
            BOOL isColoreEqual = [color awl_isEqualToColor:newColor withAlpha:YES];
            if (isColoreEqual) {
                isMatchedColorFound = YES;
                self.colorsArrayController.selectedObjects = @[ dictionary ];
                break;
            }
        }
        // Clear table if matched color not found
        if (isMatchedColorFound == NO) {
            self.colorsArrayController.selectionIndexes = [NSIndexSet indexSet];
        }
    }
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
        if (context == &colorObservanceContext) {
            NSArray *selectedColors = [object selectedObjects];
            if (selectedColors.count == 0) {
                return; // Empty selection
            }
            
            NSDictionary *dictionary =
            selectedColors[0]; // Expected array with only one element
            if ([keyPath hasSuffix:gAWLColorPickerKeyTitle]) {
                NSLog(@"Color name changed: %@", dictionary[gAWLColorPickerKeyTitle]);
            } else if ([keyPath isEqualToString:@"selectionIndexes"]) {
                NSLog(@"Table section changed: %@",
                      dictionary[gAWLColorPickerKeyTitle]);
                NSColor *color = dictionary[gAWLColorPickerKeyColor];
                self.colorChangeInProgress = YES;
                self.colorPanel.color = color;
                self.colorChangeInProgress = NO;
            }
        } else {
            // not my observer callback
            [super observeValueForKeyPath:keyPath
                                 ofObject:object
                                   change:change
                                  context:context];
        }
        
    } else if (object == self.colorListsArrayController) {
        if (context == &colorListsObservanceContext) {
            [self p_switchColorList];
        } else {
            // not my observer callback
            [super observeValueForKeyPath:keyPath
                                 ofObject:object
                                   change:change
                                  context:context];
        }
    }
}

#pragma mark - Handlers
- (IBAction)showPopupActions:(id)sender {
    NSPopUpButton *menu = sender;
    NSInteger itemId = menu.selectedTag;
    NSLog(@"Selected menu item with tag = %ld", (long)itemId);
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
    
    // Reading previously stored list name and searching for the right selection
    // index.
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
    [self p_removeObserversForColorsArrayController];
    self.colorsArrayController.content = content;
    self.colorsArrayController.selectionIndexes = [NSIndexSet indexSet];
    [self p_addObserversForColorsArrayController];
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
    [defaults setObject:colorList.name
                 forKey:gAWLColorPickerUserDefaultsKeyColorList];
    [defaults synchronize];
    
    [self p_initializeColorsArrayControllerContents:colorList];
}

- (void)p_addObserversForColorsArrayController {
    if (!colorObservanceContext) {
        [self.colorsArrayController
         addObserver:self
         forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@",
                     gAWLColorPickerKeyTitle]
         options:NSKeyValueObservingOptionNew
         context:&colorObservanceContext];
        [self.colorsArrayController addObserver:self
                                     forKeyPath:@"selectionIndexes"
                                        options:NSKeyValueObservingOptionNew
                                        context:&colorObservanceContext];
        colorObservanceContext = 1;
    }
}

- (void)p_removeObserversForColorsArrayController {
    if (colorObservanceContext) {
        [self.colorsArrayController
         removeObserver:self
         forKeyPath:[NSString stringWithFormat:@"arrangedObjects.%@",
                     gAWLColorPickerKeyTitle]
         context:&colorObservanceContext];
        [self.colorsArrayController removeObserver:self
                                        forKeyPath:@"selectionIndexes"
                                           context:&colorObservanceContext];
        colorObservanceContext = 0;
    }
}

@end
