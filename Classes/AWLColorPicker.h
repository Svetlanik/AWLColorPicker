//
//  AWLColorPicker.h
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// TODO: Handle NSColorListDidChangeNotification notification to dynamically
// update colors table.

@interface AWLColorPicker
: NSColorPicker <NSColorPickingCustom, NSWindowDelegate>
@property(weak) IBOutlet NSView *colorsPickerView;
@property(weak) IBOutlet NSTableView *colorsTableView;

@property(strong) IBOutlet NSArrayController *colorsArrayController;
@property(strong) IBOutlet NSArrayController *colorListsArrayController;

- (IBAction)addColor:(id)sender;
- (IBAction)removeColor:(id)sender;
- (IBAction)copyColorToClipboard:(id)sender;
- (IBAction)showOptionsWindow:(id)sender;

// Actions for demo purpose
@property(weak) IBOutlet NSTextField *labelColor;

@end
