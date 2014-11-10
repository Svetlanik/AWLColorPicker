
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
#import "AWLOptionsController.h"
#import "AWLWindowController.h"
#import "AWLInfoWindowController.h"

static NSString *const gAWLColorPickerKeyImage = @"image";
static NSString *const gAWLColorPickerKeyTitle = @"title";
static NSString *const gAWLColorPickerKeyColor = @"color";

extern NSString *const
gAWLColorPickerUserDefaultsKeyOptionExcludeNumberSingFromColorStrings;
extern NSString *const
gAWLColorPickerUserDefaultsKeyOptionShouldUseLowercaseForColorStrings;
static NSString *const gAWLColorPickerUserDefaultsKeyColorList =
@"ua.com.wavelabs.AWLColorPicker:colorListName";

static int colorObservanceContext = 0;
static int colorListsObservanceContext = 0;
static NSSize gAWLDefaultImageSize = { 26, 14 };

@interface AWLColorPicker () {
    AWLOptionsController *_optionsController;
}

@property(assign) BOOL colorChangeInProgress;
@property(assign, readonly) BOOL canEditColorList;
@property(strong, readonly) NSColorList *selectedColorList;
@property(strong, readonly) NSDictionary *selectedColorObject;
@property(strong, readonly) AWLOptionsController *optionsController;
@property (nonatomic, strong) AWLWindowController *sheet;
@property (nonatomic, strong) AWLInfoWindowController *aboutAWLColorPicker;

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
    NSArray *sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
    self.colorListsArrayController.sortDescriptors = sortDescriptors;
    
    // This makes table view focused.
    [[self colorPanel] makeFirstResponder:self.colorsTableView];
    
    [self p_subscribeForNotifications];
}

- (id)initWithPickerMask:(NSUInteger)mask
              colorPanel:(NSColorPanel *)owningColorPanel {
    return [super initWithPickerMask:mask colorPanel:owningColorPanel];
}

- (void)dealloc {
    [self p_unsubscribeFromNotifications];
    self.colorsArrayController = nil;
    self.colorListsArrayController = nil;
}

#pragma mark - NSColorPickingCustom

- (BOOL)supportsMode:(NSColorPanelMode)mode {
    switch (mode) {
        case NSColorListModeColorPanel:
            return YES;
        default:
            return NO;
    }
}

- (NSColorPanelMode)currentMode {
    return NSColorListModeColorPanel;
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
    else {
        NSArray *selectedObjects = self.colorListsArrayController.selectedObjects;
        self.colorListsArrayController.content = [[NSSet setWithArray:[NSColorList availableColorLists]] allObjects];
        self.colorListsArrayController.selectedObjects = selectedObjects;
    }
    
    return self.colorsPickerView;
}

- (void)setColor:(NSColor *)newColor {
    self.labelColor.stringValue = [self p_hexStringFromColor:newColor];
    self.labelColor.toolTip = [NSString stringWithFormat:@"%@\n%@", newColor.colorSpaceName, newColor.awl_RGBValue];
    // Update Table
    if (!self.colorChangeInProgress) {
        BOOL isMatchedColorFound = NO;
        for (NSDictionary *dictionary in self.colorsArrayController
             .arrangedObjects) {
            NSColor *color = dictionary[gAWLColorPickerKeyColor];
            BOOL isColorEqual = [newColor awl_isEqualToColor:color withAlpha:YES];
            if (isColorEqual) {
                isMatchedColorFound = YES;
                self.colorsArrayController.selectedObjects = @[ dictionary ];
                break;
            }
        }
        // Clear table if matched color not found
        if (!isMatchedColorFound) {
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

- (NSImage *)provideNewButtonImage {
    NSString *iconBaseName = @"AWLPickerIcon";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *iconURL = [bundle URLForResource:iconBaseName withExtension:@"tiff"];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:iconURL];
    return image;
}

- (NSString *)buttonToolTip {
    return NSLocalizedString(
                             @"AWL Color Picker",
                             @"Palette color picker with color matching functionality");
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
                NSString *colorName = dictionary[gAWLColorPickerKeyTitle];
                NSLog(@"Color name changed: %@", colorName);
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

- (IBAction)addColor:(id)sender {
    if (self.canEditColorList == FALSE) {
        return;
    }
    NSColorList *selectedColorList = self.selectedColorList;
    NSColor *color = self.colorPanel.color;
    // Search for available color name
    NSString *colorName = selectedColorList.name; // TODO: Make smart name
    // containing Color list name +
    // Color value + Alpha value
    NSUInteger counter = 0;
    while ([selectedColorList.allKeys containsObject:colorName]) {
        counter++;
        colorName = [NSString stringWithFormat:@"%@ %lu", selectedColorList.name,
                     (unsigned long)counter];
    }
    // Save color to color list
    [selectedColorList setColor:color forKey:colorName];
    BOOL isFileWritten = [selectedColorList writeToFile:nil];
    if (isFileWritten) {
        // Update array controller
        NSImage *image =
        [NSImage awl_swatchWithColor:color size:gAWLDefaultImageSize];
        NSDictionary *dict = @{
                               gAWLColorPickerKeyImage : image,
                               gAWLColorPickerKeyTitle : colorName,
                               gAWLColorPickerKeyColor : color
                               };
        [self.colorsArrayController addObject:[dict mutableCopy]];
    } else {
        NSLog(@"Unable to write to file"); // FIXME: Write detailed info to Console.app and show short info to user.
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:NSColorListDidChangeNotification
     object:self];
}

- (IBAction)removeColor:(id)sender {
    NSDictionary *selectedColor = self.selectedColorObject;
    NSColorList *selectedColorList = self.selectedColorList;
    if (selectedColor && selectedColorList) {
        NSString *colorName = selectedColor[gAWLColorPickerKeyTitle];
        // Remove color from Color List
        [selectedColorList removeColorWithKey:colorName];
        BOOL isFileWritten = [selectedColorList writeToFile:nil];
        if (isFileWritten) {
            // Update array controller
            [self.colorsArrayController removeObject:selectedColor];
        } else {
            NSLog(@"Unable to write to file"); // FIXME: Write detailed info to Console.app and show short info to user.
        }
    }
}

- (IBAction)copyColorToClipboard:(id)sender {
    NSString *colorHEXCode = [self p_hexStringFromColor:self.colorPanel.color];
    // Pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    BOOL isObjectsWritten = [pasteboard writeObjects:@[ colorHEXCode ]];
    if (!isObjectsWritten) {
        NSLog(@"Unable to write object to pasteboard: %@", colorHEXCode);
    }
}

#pragma mark - Notifications

- (void)userDefaultsChanged:(NSNotification *)aNotification {
    self.labelColor.stringValue = [self p_hexStringFromColor:self.colorPanel.color];
}

#pragma mark - Actions

- (IBAction)showOptionsWindow:(id)sender {
    [self.colorPanel beginSheet:self.optionsController.window completionHandler:nil];
}

- (IBAction)addNewColorList:(id)sender {
    NSString *colorListName = [NSString stringWithFormat:@"Unnamed_%ld", (long)([NSDate date].timeIntervalSinceReferenceDate)];
    NSColorList *colorList = [[NSColorList alloc] initWithName:colorListName];
    if (![colorList writeToFile:nil]) {
        NSLog(@"Error: could not be saved into file");
    }
    self.colorListsArrayController.content = [[NSSet setWithArray:[NSColorList availableColorLists]] allObjects];
    self.colorListsArrayController.selectedObjects = @[colorList];
    [self addColor:self];
}

- (IBAction)renameColorList:(id)sender {
    NSColorList *colorList = self.selectedColorList;
    self.sheet = [[AWLWindowController alloc] initWithWindowNibName:@"AWLWindowController"];
    [self.colorPanel beginSheet:self.sheet.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK) {
            NSString *myString = [self.sheet.textField stringValue];
            NSLog(@"Renaming color list %@ -> %@", colorList.name,  myString);
            if (colorList) {
                NSString *filePath = [@"~/Library/Colors" stringByExpandingTildeInPath];
                NSString* source = [filePath stringByAppendingPathComponent:[colorList.name stringByAppendingPathExtension:@"clr"]];
                NSString* destination = [filePath stringByAppendingPathComponent:[myString stringByAppendingPathExtension:@"clr"]];
                
                NSError* error;
                [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:source]
                                                        toURL:[NSURL fileURLWithPath:destination]
                                                        error:&error];
                if (error) {
                    NSLog(@"%@", error);
                    return;
                }
                NSColorList *new = [[NSColorList alloc] initWithName:myString fromFile:destination];
                BOOL writeStatus = [new writeToFile:nil];
                if (!writeStatus) {
                    NSLog(@"Unable to write to file.");
                    return;
                }
                [colorList removeFile];
                self.colorListsArrayController.content = [[NSSet setWithArray:[NSColorList availableColorLists]] allObjects];
                self.colorListsArrayController.selectedObjects = @[new];
            }
        }
        else if (returnCode == NSModalResponseCancel){
            NSLog(@"User pressed Cancel");
        }
    }];
}

-(IBAction)removeColorList:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Remove Color Palette"];
    [alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to remove the entire '%@' color palette?", self.selectedColorList.name]];
    [alert setAlertStyle: NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.colorPanel completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == NSAlertSecondButtonReturn){
            NSLog(@"Cancel");
        }
        else if (returnCode == NSAlertFirstButtonReturn) {
            NSLog(@"OK");
            NSColorList *thisColorList = self.selectedColorList;
            if (thisColorList) {
                [thisColorList removeFile];
                NSLog(@"Selected color list %@", thisColorList);
            }
            self.colorListsArrayController.content = [NSColorList availableColorLists];
        }
    }];
}

-(IBAction)aboutAWLColorPicker:(id)sender {
    self.aboutAWLColorPicker = [[AWLInfoWindowController alloc]initWithWindowNibName:@"AWLInfoWindowController"];
    [self.colorPanel beginSheet:self.aboutAWLColorPicker.window completionHandler:nil];
}

#pragma mark - Private methods

- (void)p_initializeColorListsArrayControllerContents {
    // Getting color lists
    NSArray *colorLists = [[NSSet setWithArray:[NSColorList availableColorLists]] allObjects];
    if (colorLists.count == 0) {
        return;
    }
    self.colorListsArrayController.content = [colorLists copy];
    // Reading previously stored list name and searching for the right selection
    // index.
    NSString *colorListName = [[NSUserDefaults standardUserDefaults]
                               stringForKey:gAWLColorPickerUserDefaultsKeyColorList];
    NSUInteger selectedColorListIndex = 0;
    if (colorListName != nil) {
        for (NSUInteger idx = 0; idx < colorLists.count; idx++) {
            if ([[colorLists[idx] name] isEqualToString:colorListName]) {
                selectedColorListIndex = idx;
                break;
            }
        }
    }
    // Selecting current color list
    self.colorListsArrayController.selectionIndex = selectedColorListIndex;
}

- (void)p_initializeColorsArrayControllerContents:(NSColorList *)aList {
    NSArray *colorNames = [aList allKeys];
    NSMutableArray *content = [NSMutableArray array];
    for (NSString *colorName in colorNames) {
        NSColor *color = [aList colorWithKey:colorName];
        NSImage *image =
        [NSImage awl_swatchWithColor:color size:gAWLDefaultImageSize];
        NSDictionary *dict = @{
                               gAWLColorPickerKeyImage : image,
                               gAWLColorPickerKeyTitle : colorName,
                               gAWLColorPickerKeyColor : color
                               };
        [content addObject:[dict mutableCopy]];
    }
    [self p_removeObserversForColorsArrayController];
    self.colorsArrayController.content = content;
    [self p_selectColorIfMatched:self.colorPanel.color];
    [self p_addObserversForColorsArrayController];
}

- (void)p_switchColorList {
    NSColorList *colorList = self.selectedColorList;
    if (colorList == nil) {
        return; // Empty selection
    }
    NSLog(@"Color list changed: %@", colorList.name);
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:colorList.name
                 forKey:gAWLColorPickerUserDefaultsKeyColorList];
    [defaults synchronize];
    
    [self p_initializeColorsArrayControllerContents:colorList];
}

- (NSString*)p_hexStringFromColor:(NSColor *)aColor {
    BOOL prefixDisabled = [[NSUserDefaults standardUserDefaults]
                           boolForKey:
                           gAWLColorPickerUserDefaultsKeyOptionExcludeNumberSingFromColorStrings];
    BOOL shouldUseLowercase = [[NSUserDefaults standardUserDefaults]
                               boolForKey:
                               gAWLColorPickerUserDefaultsKeyOptionShouldUseLowercaseForColorStrings];
    NSString *colorHEXCode = [aColor awl_hexadecimalValue];
    if (!prefixDisabled) {
        colorHEXCode = [@"#" stringByAppendingString:colorHEXCode];
    }
    colorHEXCode = (shouldUseLowercase) ? [colorHEXCode lowercaseString]
    : [colorHEXCode uppercaseString];
    
    return colorHEXCode;
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

- (void)p_selectColorIfMatched:(NSColor *)aColor {
    BOOL isMatchedColorFound = NO;
    for(NSDictionary *dictionary in self.colorsArrayController.arrangedObjects) {
        NSColor *color = dictionary[gAWLColorPickerKeyColor];
        NSLog(@"Dictionary with color %@", color);
        BOOL isColorEgual = [color awl_isEqualToColor:aColor withAlpha:YES];
        if (isColorEgual) {
            isMatchedColorFound = YES;
            self.colorsArrayController.selectedObjects = @[dictionary];
            break;
        }
    }
    if (isMatchedColorFound == NO) {
        self.colorsArrayController.selectionIndexes = [NSIndexSet indexSet];
    }
}

- (void)p_subscribeForNotifications {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(userDefaultsChanged:)
     name:NSUserDefaultsDidChangeNotification
     object:userDefaults];
}

- (void)p_unsubscribeFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (BOOL)canEditColorList {
    NSColorList *colorList = self.selectedColorList;
    return colorList.editable;
}

- (NSColorList *)selectedColorList {
    NSArray *selectedColorLists =
    [self.colorListsArrayController selectedObjects];
    if (selectedColorLists.count == 0) {
        return nil;
    }
    NSColorList *colorList = selectedColorLists[0];
    return colorList;
}

- (NSDictionary *)selectedColorObject {
    NSArray *selectedColors = [self.colorsArrayController selectedObjects];
    if (selectedColors.count == 0) {
        return nil;
    }
    NSDictionary *color = selectedColors[0];
    return color;
}

- (AWLOptionsController *)optionsController {
    if (!_optionsController) {
        _optionsController = [[AWLOptionsController alloc] init];
    }
    return _optionsController;
}

@end
