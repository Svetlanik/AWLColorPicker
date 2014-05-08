//
//  AWLOptionsController.h
//  AWLColorPicker
//
//  Created by Svitlana on 07.05.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AWLOptionsController : NSWindowController

@property(strong) IBOutlet NSButton *colorNamesWithoutPrefix;

- (IBAction)checkChangePrefix:(id)sender;
- (IBAction)closeOptionsWindow:(id)sender;
@end
