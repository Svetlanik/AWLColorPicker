//
//  NSString+AWLColorPicker.h
//  AWLColorPicker
//
//  Created by Svitlana on 26.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSColor (AWLColorPicker)
- (NSString *)awl_hexadecimalValue;
- (NSString *)awl_RGBValue;
- (BOOL)awl_isEqualToColor:(NSColor *)anotherColor withAlpha:(BOOL)isAlphaUsed;
@end
