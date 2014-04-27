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
@property (strong) IBOutlet NSArrayController* colorListsArrayController;

// Actions for demo purpose
@property (weak) IBOutlet NSTextField *labelColor;

@end
