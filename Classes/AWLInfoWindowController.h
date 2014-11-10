//
//  AWLInfoWindowController.h
//  AWLColorPicker
//
//  Created by Svitlana on 15.10.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

@import Cocoa;

@interface AWLInfoWindowController : NSWindowController

@property (strong) IBOutlet NSImageView *imageView;

- (IBAction)cancelWindow:(id)sender;

@end
