//
//  NSImage+AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 25.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "NSImage+AWLColorPicker.h"

@implementation NSImage (AWLColorPicker)

+ (NSImage *)awl_swatchWithColor:(NSColor *)color size:(NSSize)size
{
    NSImage *image = [[NSImage alloc] initWithSize:size];
    [image lockFocus];
    [color drawSwatchInRect:NSMakeRect(0, 0, size.width, size.height)];
    [image unlockFocus];
    return image;
}

@end
