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
- (NSString *)awl_hexadecimalValue {
    if (!self.awl_canProvideRGBComponents) {
        return @"------";
    }
    
    NSString *result;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB: {
            CGFloat r = self.awl_red;
            CGFloat g = self.awl_green;
            CGFloat b = self.awl_blue;
            int rI = r * 255.99999f;
            int gI = g * 255.99999f;
            int bI = b * 255.99999f;
            result = [NSString stringWithFormat:@"%02X%02X%02X", rI, gI, bI];
            break;
        }
        case kCGColorSpaceModelMonochrome:
        {
            CGFloat w = self.awl_white;
            int wI = w * 255.99999f;
            result = [NSString stringWithFormat:@"%02X%02X%02X", wI, wI, wI];
            break;
        }
        default:
            result = nil;
    }
    return result;
}

- (CGColorSpaceModel)awl_colorSpaceModel {
    return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

- (BOOL)awl_canProvideRGBComponents {
    BOOL flag = NO;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB:
        case kCGColorSpaceModelMonochrome:
            flag = YES;
            break;
        default:
            flag = NO;
            break;
    }
    
    if (flag) {
        flag = ([self.colorSpaceName isEqualToString:NSCalibratedWhiteColorSpace] ||
                [self.colorSpaceName isEqualToString:NSDeviceWhiteColorSpace] ||
                [self.colorSpaceName isEqualToString:NSCalibratedRGBColorSpace] ||
                [self.colorSpaceName isEqualToString:NSDeviceRGBColorSpace] ||
                [self.colorSpaceName isEqualToString:NSCustomColorSpace]);
        
        if (flag) {
            if ([self.colorSpaceName isEqualToString:NSCustomColorSpace]) {
                @try {
                    [self getRed:NULL green:NULL blue:NULL alpha:NULL];
                }
                @catch (NSException *exception) {
                    flag = FALSE;
                }
            }
        }
    }
    
    return flag;
}

- (CGFloat)awl_red {
    CGFloat r = 0.0f;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB:
            [self getRed:&r green:NULL blue:NULL alpha:NULL];
            break;
        case kCGColorSpaceModelMonochrome:
            [self getWhite:&r alpha:NULL];
            break;
        default:
            NSAssert(false, @"Must be an RGB color to use -red");
            break;
    }
    return r;
}

- (CGFloat)awl_green {
    CGFloat g = 0.0f;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB:
            [self getRed:NULL green:&g blue:NULL alpha:NULL];
            break;
        case kCGColorSpaceModelMonochrome:
            [self getWhite:&g alpha:NULL];
            break;
        default:
            NSAssert(false, @"Must be an RGB color to use -green");
            break;
    }
    
    return g;
}

- (CGFloat)awl_blue {
    CGFloat b = 0.0f;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB:
            [self getRed:NULL green:NULL blue:&b alpha:NULL];
            break;
        case kCGColorSpaceModelMonochrome:
            [self getWhite:&b alpha:NULL];
            break;
        default:
            NSAssert(false, @"Must be an RGB color to use -blue");
            break;
    }
    return b;
}

- (CGFloat)awl_alpha {
    CGFloat a = 0.0f;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelRGB:
            [self getRed:NULL green:NULL blue:NULL alpha:&a];
            break;
        case kCGColorSpaceModelMonochrome:
            [self getWhite:NULL alpha:&a];
            break;
        default:
            NSAssert(false, @"Must be an RGB color to use -alpha");
            break;
    }
    return a;
}

- (CGFloat)awl_white {
    CGFloat w = 0.0f;
    switch (self.awl_colorSpaceModel) {
        case kCGColorSpaceModelMonochrome:
            [self getWhite:&w alpha:NULL];
            break;
        default:
            NSAssert(false, @"Must be an Monochrome color to use -white");
            break;
    }
    return w;
}

- (CGFloat)awl_distanceFrom:(NSColor *)anotherColor {
    CGFloat dR = self.awl_red - anotherColor.awl_red;
    CGFloat dG = self.awl_green - anotherColor.awl_green;
    CGFloat dB = self.awl_blue - anotherColor.awl_blue;
    
    return sqrtf(dR * dR + dG * dG + dB * dB);
}

- (CGFloat)awl_distanceFromUsingAlpha:(NSColor *)anotherColor {
    CGFloat dR = self.awl_red - anotherColor.awl_red;
    CGFloat dG = self.awl_green - anotherColor.awl_green;
    CGFloat dB = self.awl_blue - anotherColor.awl_blue;
    CGFloat dA = self.awl_alpha - anotherColor.awl_alpha;
    
    return sqrtf(dR * dR + dG * dG + dB * dB + dA * dA);
}

#pragma mark - Testing

- (BOOL)awl_isEqualToColor:(NSColor *)anotherColor withAlpha:(BOOL)isAplhaUsed {
    if (!self.awl_canProvideRGBComponents) {
        return false;
    }
    
    CGFloat distance = 0.f;
    if (isAplhaUsed) {
        distance = [self awl_distanceFromUsingAlpha:anotherColor];
    } else {
        distance = [self awl_distanceFrom:anotherColor];
    }
    return (distance < FLT_EPSILON);
}

@end
