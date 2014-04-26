//
//  NSString+AWLColorPicker.m
//  AWLColorPicker
//
//  Created by Svitlana on 26.04.14.
//  Copyright (c) 2014 WaveLabs. All rights reserved.
//

#import "NSColor+AWLColorPicker.h"

@implementation NSColor (AWLColorPicker)

/**
 @see Technical Q&A QA1576 http://goo.gl/MshnzM
 */
- (NSString *)awl_hexadecimalValueOfAnNSColor {
    CGFloat redFloatValue, greenFloatValue, blueFloatValue;
    int redIntValue, greenIntValue, blueIntValue;
    NSString *redHexValue, *greenHexValue, *blueHexValue;
    
    // Convert the NSColor to the RGB color space before we can access its
    // components
    NSColor *convertedColor =
    [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    
    if (convertedColor) {
        // Get the red, green, and blue components of the color
        [convertedColor getRed:&redFloatValue
                         green:&greenFloatValue
                          blue:&blueFloatValue
                         alpha:NULL];
        
        // Convert the components to numbers (unsigned decimal integer) between 0
        // and 255
        redIntValue = redFloatValue * 255.99999f;
        greenIntValue = greenFloatValue * 255.99999f;
        blueIntValue = blueFloatValue * 255.99999f;
        
        // Convert the numbers to hex strings
        redHexValue = [NSString stringWithFormat:@"%02x", redIntValue];
        greenHexValue = [NSString stringWithFormat:@"%02x", greenIntValue];
        blueHexValue = [NSString stringWithFormat:@"%02x", blueIntValue];
        
        // Concatenate the red, green, and blue components' hex strings together
        // with a "#"
        return [NSString
                stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
    }
    return nil;
}

/**
 @see Extracting hex value from NSColor By Michael Robinson
 http://pagesofinterest.net/blog/2011/12/extracting-hex-value-from-nscolor/
 */
+ (NSColor *)awl_colorWithHex:(NSString *)hexColor {
    
    // Remove the hash if it exists
    hexColor =
    [hexColor stringByReplacingOccurrencesOfString:@"#" withString:@""];
    int length = (int)[hexColor length];
    bool triple = (length == 3);
    
    NSMutableArray *rgb = [[NSMutableArray alloc] init];
    
    // Make sure the string is three or six characters long
    if (triple || length == 6) {
        
        CFIndex i = 0;
        UniChar character = 0;
        NSString *segment = @"";
        CFStringInlineBuffer buffer;
        CFStringInitInlineBuffer((CFStringRef)hexColor, &buffer,
                                 CFRangeMake(0, length));
        
        while ((character = CFStringGetCharacterFromInlineBuffer(&buffer, i)) !=
               0) {
            if (triple)
                segment =
                [segment stringByAppendingFormat:@"%c%c", character, character];
            else
                segment = [segment stringByAppendingFormat:@"%c", character];
            
            if ((int)[segment length] == 2) {
                NSScanner *scanner = [[NSScanner alloc] initWithString:segment];
                
                unsigned number;
                
                while ([scanner scanHexInt:&number]) {
                    [rgb addObject:
                     [NSNumber numberWithFloat:(float)(number / (float)255)]];
                }
                segment = @"";
            }
            
            i++;
        }
        
        // Pad the array out (for cases where we're given invalid input)
        while ([rgb count] != 3)
            [rgb addObject:[NSNumber numberWithFloat:0.0]];
        
        return [NSColor colorWithCalibratedRed:[[rgb objectAtIndex:0] floatValue]
                                         green:[[rgb objectAtIndex:1] floatValue]
                                          blue:[[rgb objectAtIndex:2] floatValue]
                                         alpha:1];
    } else {
        NSException *invalidHexException = [NSException
                                            exceptionWithName:@"InvalidHexException"
                                            reason:
                                            @"Hex color not three or six characters excluding hash"
                                            userInfo:nil];
        @throw invalidHexException;
    }
}

- (NSString *)awl_hexColor {
    CGFloat r, g, b;
    r = g = b = 255.99999f;
    if ([self.colorSpaceName isEqualToString:NSCalibratedWhiteColorSpace] ||
        [self.colorSpaceName isEqualToString:NSDeviceWhiteColorSpace]) {
        return [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X",
                (int)(r * self.whiteComponent),
                (int)(g * self.whiteComponent),
                (int)(b * self.whiteComponent)];
    } else if ([self.colorSpaceName isEqualToString:NSCalibratedRGBColorSpace] ||
               [self.colorSpaceName isEqualToString:NSDeviceRGBColorSpace]) {
        return [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X",
                (int)(r * self.redComponent),
                (int)(g * self.blueComponent),
                (int)(b * self.greenComponent)];
    } else if ([self.colorSpaceName isEqualToString:NSCustomColorSpace]) {
        NSColorSpaceModel model = self.colorSpace.colorSpaceModel;
        if (model == NSRGBColorSpaceModel) {
            return [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X",
                    (int)(r * self.redComponent),
                    (int)(g * self.blueComponent),
                    (int)(b * self.greenComponent)];
        }
    }
    else {
        NSLog(@"ERROR: unknown colorSpace %@", self.colorSpaceName);
    }
    return nil;
}

@end
