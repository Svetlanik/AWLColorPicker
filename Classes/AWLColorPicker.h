//
//  AWLColorPicker.h
//  AWLColorPicker
//
//  Created by Svitlana on 23.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AWLColorPicker : NSColorPicker <NSColorPickingCustom>
@property (weak) IBOutlet NSView *colorsPickerView;
@property (weak) IBOutlet NSTableView *colorsTableView;
@property (strong) IBOutlet NSArrayController* colorsArrayController;

// Actions for demo purpose
@property (weak) IBOutlet NSButton *buttonRed;
@property (weak) IBOutlet NSButton *buttonGreen;
@property (weak) IBOutlet NSButton *buttonBlue;
@property (weak) IBOutlet NSTextField *labelColor;

- (IBAction)colorChanged:(id)sender;

@end
