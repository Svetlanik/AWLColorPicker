//
//  AWLOptionsController.m
//  AWLColorPicker
//
//  Created by Svitlana on 07.05.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLOptionsController.h"

NSString *const
gAWLColorPickerUserDefaultsKeyOptionExcludeNumberSingFromColorStrings =
@"ua.com.wavelabs.AWLColorPicker:excludeNumberSing";
NSString *const
gAWLColorPickerUserDefaultsKeyOptionShouldUseLowercaseForColorStrings =
@"ua.com.wavelabs.AWLColorPicker:shouldUseLowercase";

@implementation AWLOptionsController

- (id)init {
    static NSString *nibName = @"AWLOptionsWindow";
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSString *nibPath = [bundle pathForResource:nibName ofType:@"nib"];
    if (!nibPath) {
        NSLog(@"Error: Unable to load nib %@", nibName);
    }
    self = [super initWithWindowNibPath:nibPath owner:self];
    return self;
}

- (IBAction)closeOptionsWindow:(id)sender {
    [[self.window sheetParent] endSheet:self.window returnCode:NSModalResponseOK];
}
@end
