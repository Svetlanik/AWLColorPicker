//
//  AWLWindowController.m
//  AWLColorPicker
//
//  Created by Svitlana on 14.10.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLWindowController.h"

@implementation AWLWindowController

-(void)awakeFromNib {
    [self.window setStyleMask:[self.window styleMask] & ~(unsigned long)NSResizableWindowMask];
}

- (IBAction)renameColorList:(id)sender {
    [[self.window sheetParent] endSheet:self.window returnCode:NSModalResponseOK];
}

- (IBAction)cancelColorList:(id)sender {
    [[self.window sheetParent] endSheet:self.window returnCode:NSModalResponseCancel];
}
@end
