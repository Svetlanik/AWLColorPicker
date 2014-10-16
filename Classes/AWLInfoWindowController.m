//
//  AWLInfoWindowController.m
//  AWLColorPicker
//
//  Created by Svitlana on 15.10.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "AWLInfoWindowController.h"

@interface AWLInfoWindowController ()
@end

@implementation AWLInfoWindowController


- (void)windowDidLoad {
    
    [super windowDidLoad];
    [self.window setStyleMask:[self.window styleMask] & ~(unsigned long)NSResizableWindowMask];
    self.imageView.image = [self provideImageSet];
}

- (NSImage *)provideImageSet {
    NSString *iconBaseName = @"AWLPickerImage";
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *iconURL = [bundle URLForResource:iconBaseName withExtension:@"tiff"];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:iconURL];
    return image;
}

- (IBAction)cancelWindow:(id)sender {
    [self close];
}
@end
