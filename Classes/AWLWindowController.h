//
//  AWLWindowController.h
//  AWLColorPicker
//
//  Created by Svitlana on 14.10.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

@import Cocoa;

@interface AWLWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, weak) IBOutlet NSTextField *textField;

- (IBAction)renameColorList:(id)sender;
- (IBAction)cancelColorList:(id)sender;

@end
