//
//  main.m
//  color-pick
//
//  Created by Johan Nordberg on 2011-09-20.
//  Copyright 2011 FFFF00 Agents AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSColor (Additions)
+(NSColor *)colorFromString:(NSString *)colorRepresentation;

// Compacts a regular hex6 string where possible.
//
// I.e. this can be compacted:
//   "#ff0000" => "#f00"
//
// This, however, can not be compacted:
//   "#cbb298" => "#cbb298"
-(NSString *)toHexString;
-(NSString *)toHexStringWithoutHash;

-(NSString *)toRGBString:(BOOL)shortVersion;
-(NSString *)toRGBAString:(BOOL)shortVersion;

-(NSString *)toHSLString:(BOOL)shortVersion;
-(NSString *)toHSLAString:(BOOL)shortVersion;

-(NSString *)toObjcNSColor:(BOOL)shortVersion;
-(NSString *)toMacRubyNSColor:(BOOL)shortVersion;

-(NSString *)toObjcUIColor:(BOOL)shortVersion;
-(NSString *)toMotionUIColor:(BOOL)shortVersion;
@end


@implementation NSColor (Additions)
+(NSColor *)colorFromString:(NSString *)colorRepresentation {
  float alpha = 1;
  
  NSScanner *scanner = [NSScanner scannerWithString: [colorRepresentation lowercaseString]];
  NSMutableCharacterSet *skipChars = [NSMutableCharacterSet characterSetWithCharactersInString: @"%,"];
  [skipChars formUnionWithCharacterSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
  [scanner setCharactersToBeSkipped: skipChars];
  
  if ([scanner scanString:@"hsl(" intoString:nil] || [scanner scanString:@"hsla(" intoString:nil]) {
    int hue = 0, saturation = 0, brightness = 0;
    
    [scanner scanInt: &hue];
    [scanner scanInt: &saturation];
    [scanner scanInt: &brightness];
    [scanner scanFloat: &alpha];
    
    return [NSColor colorWithCalibratedHue: (hue / 360.0)
                                saturation: (saturation / 100.0)
                                brightness: (brightness / 100.0)
                                     alpha: alpha];
  }
  
  float red = 0, green = 0, blue = 0;
  
  if ([scanner scanString:@"rgb(" intoString:nil] || [scanner scanString:@"rgba(" intoString:nil]) {
    signed int r = 0, g = 0, b = 0;
    
    [scanner scanInt: &r];
    [scanner scanInt: &g];
    [scanner scanInt: &b];
    [scanner scanFloat: &alpha];
    
    red = ((unsigned int)r / 255.0); green = ((unsigned int)g / 255.0); blue = ((unsigned int)b / 255.0);
    
  } else if ([scanner scanString:@"[NSColor" intoString:nil] || [scanner scanString:@"NSColor." intoString:nil]) {
    // objective-c or macruby NSColor
    [scanner scanString:@"colorWithCalibratedRed:" intoString:nil] || [scanner scanString:@"colorWithCalibratedRed(" intoString:nil];
    [scanner scanFloat: &red];
    [scanner scanString:@"green:" intoString:nil];
    [scanner scanFloat: &green];
    [scanner scanString:@"blue:" intoString:nil];
    [scanner scanFloat: &blue];
    [scanner scanString:@"alpha:" intoString:nil];
    [scanner scanFloat: &alpha];

  } else if ([scanner scanString:@"[UIColor" intoString:nil] || [scanner scanString:@"UIColor." intoString:nil]) {
    [scanner scanString:@"colorWithRed:" intoString:nil] || [scanner scanString:@"colorWithRed(" intoString:nil];
    [scanner scanFloat: &red];
    [scanner scanString:@"green:" intoString:nil];
    [scanner scanFloat: &green];
    [scanner scanString:@"blue:" intoString:nil];
    [scanner scanFloat: &blue];
    [scanner scanString:@"alpha:" intoString:nil];
    [scanner scanFloat: &alpha];

  } else {
    [scanner scanString:@"#" intoString:nil];

    unsigned int r = 0, g = 0, b = 0;
    NSString *hex = @"000000";

    NSCharacterSet *hexChars = [NSCharacterSet characterSetWithCharactersInString: @"0123456789abcdef"];

    if([scanner scanCharactersFromSet:hexChars intoString:&hex]){

      if ([hex length] == 3) {
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(0, 1)]] scanHexInt: &r];
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(1, 1)]] scanHexInt: &g];
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(2, 1)]] scanHexInt: &b];
        r += r * 16; g += g * 16; b += b * 16;
      } else if ([hex length] == 6) {
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(0, 2)]] scanHexInt: &r];
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(2, 2)]] scanHexInt: &g];
        [[NSScanner scannerWithString: [hex substringWithRange: NSMakeRange(4, 2)]] scanHexInt: &b];
      } else {
        return nil;
      }

      red = (r / 255.0); green = (g / 255.0); blue = (b / 255.0);

    } else {
      return nil;
    }
  }
  
  return [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
}

-(NSString *)toHexString {
    return [NSString stringWithFormat:@"#%@", [self toHexStringWithoutHash]];
}

-(NSString *)toHexStringWithoutHash {
    NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
    
    NSString *result = [NSString stringWithFormat: @"%02x%02x%02x",
                        (unsigned int)(255 * [color redComponent]),
                        (unsigned int)(255 * [color greenComponent]),
                        (unsigned int)(255 * [color blueComponent])];
    
    if (([result characterAtIndex: 0] == [result characterAtIndex: 1]) &&
        ([result characterAtIndex: 2] == [result characterAtIndex: 3]) &&
        ([result characterAtIndex: 4] == [result characterAtIndex: 5])) {
        return [NSString stringWithFormat: @"%C%C%C",
                [result characterAtIndex: 0],
                [result characterAtIndex: 2],
                [result characterAtIndex: 4]];
    } else {
        return result;
    }  
}

-(NSString *)toRGBString:(BOOL)shortVersion {
  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  
  NSString *result = [NSString stringWithFormat: (shortVersion ? @"%d, %d, %d" : @"rgb(%d, %d, %d)"),
                       (unsigned int)(255 * [color redComponent]),
                       (unsigned int)(255 * [color greenComponent]),
                       (unsigned int)(255 * [color blueComponent])];
  
  return result;
}

-(NSString *)toRGBAString:(BOOL)shortVersion {
  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  
  NSString *result = [NSString stringWithFormat: (shortVersion ? @"%d, %d, %d, %g" : @"rgba(%d, %d, %d, %g)"),
                       (unsigned int)(255 * [color redComponent]),
                       (unsigned int)(255 * [color greenComponent]),
                       (unsigned int)(255 * [color blueComponent]),
                       (float)[color alphaComponent]];
  
  return result;
}

-(NSString *)toHSLString:(BOOL)shortVersion {
  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  
  NSString *result = [NSString stringWithFormat: (shortVersion ? @"%d, %d%%, %d%%" : @"hsl(%d, %d%%, %d%%)"),
                       (unsigned int)(360 * [color hueComponent]),
                       (unsigned int)(100 * [color saturationComponent]),
                       (unsigned int)(100 * [color brightnessComponent])];
  
  return result;
}

-(NSString *)toHSLAString:(BOOL)shortVersion {
  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  
  NSString *result = [NSString stringWithFormat: (shortVersion ? @"%d, %d%%, %d%%, %g" : @"hsla(%d, %d%%, %d%%, %g)"),
                       (unsigned int)(360 * [color hueComponent]),
                       (unsigned int)(100 * [color saturationComponent]),
                       (unsigned int)(100 * [color brightnessComponent]),
                       (float)[color alphaComponent]];
  
  return result;
}

-(NSString *)_componentToString:(CGFloat)component {
  if (component == 0.0) {
    return @"0.0";
  } else if (component == 1.0) {
    return @"1.0";
  } else {
    return [NSString stringWithFormat: @"%g", component];
  }
}

-(NSString *)toObjcNSColor:(BOOL)shortVersion {
  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];
  
  if (shortVersion) {
    return [NSString stringWithFormat: @"%g %g %g %g",
                                       [color redComponent],
                                       [color greenComponent],
                                       [color blueComponent],
                                       [color alphaComponent]];
  } else {
    NSString *red   = [self _componentToString: [color redComponent]];
    NSString *green = [self _componentToString: [color greenComponent]];
    NSString *blue  = [self _componentToString: [color blueComponent]];
    NSString *alpha = [self _componentToString: [color alphaComponent]];
    return [NSString stringWithFormat: @"[NSColor colorWithCalibratedRed:%@ green:%@ blue:%@ alpha:%@]", red, green, blue, alpha];
  }
}

-(NSString *)toMacRubyNSColor:(BOOL)shortVersion {
  if (shortVersion) {
    return [self toObjcNSColor: YES];
  }

  NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];

  NSString *result = [NSString stringWithFormat: @"NSColor.colorWithCalibratedRed(%g, green: %g, blue: %g, alpha: %g)",
                                                 [color redComponent],
                                                 [color greenComponent],
                                                 [color blueComponent],
                                                 [color alphaComponent]];

  return result;
}

-(NSString *)toObjcUIColor:(BOOL)shortVersion {

  if (shortVersion) {
    return [self toObjcNSColor: YES];
  } else {
    NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];

    NSString *red   = [self _componentToString: [color redComponent]];
    NSString *green = [self _componentToString: [color greenComponent]];
    NSString *blue  = [self _componentToString: [color blueComponent]];
    NSString *alpha = [self _componentToString: [color alphaComponent]];
    return [NSString stringWithFormat: @"[UIColor colorWithRed:%@ green:%@ blue:%@ alpha:%@]", red, green, blue, alpha];
  }
}

-(NSString *)toMotionUIColor:(BOOL)shortVersion {
  if (shortVersion) {
    return [self toObjcNSColor: YES];
  } else {
    NSColor *color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace];

    NSString *result = [NSString stringWithFormat: @"NSColor.colorWithCalibratedRed(%g, green: %g, blue: %g, alpha: %g)",
                                                   [color redComponent],
                                                   [color greenComponent],
                                                   [color blueComponent],
                                                   [color alphaComponent]];

    return result;
  }    
}

@end


@interface Picker : NSObject <NSApplicationDelegate, NSWindowDelegate> {
  NSColorPanel *panel; // weak ref
}

- (void)show;
- (void)writeColor;
- (void)exit;

@end

@implementation Picker

- (void)show {
  // setup panel and its accessory view

  NSView *accessoryView = [[NSView alloc] initWithFrame:(NSRect){{0, 0}, {220, 30}}];

  NSButton *button = [[NSButton alloc] initWithFrame:(NSRect){{110, 4}, {110 - 8, 24}}];
  [button setButtonType:NSMomentaryPushInButton];
  [button setBezelStyle:NSRoundedBezelStyle];
  button.title = @"Pick";
  button.action = @selector(writeColor);
  button.target = self;

  NSButton *cancelButton = [[NSButton alloc] initWithFrame:(NSRect){{8, 4}, {110 - 8, 24}}];
  [cancelButton setButtonType:NSMomentaryPushInButton];
  [cancelButton setBezelStyle:NSRoundedBezelStyle];
  cancelButton.title = @"Cancel";
  cancelButton.action = @selector(exit);
  cancelButton.target = self;

  [accessoryView addSubview:[button autorelease]];
  [accessoryView addSubview:[cancelButton autorelease]];

  panel = [NSColorPanel sharedColorPanel];
  [panel setDelegate:self];
  [panel setShowsAlpha:YES]; // TODO: support for rgba() output values
  [panel setAccessoryView:[accessoryView autorelease]];
  [panel setDefaultButtonCell:[button cell]];

  // load user settings
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *color = [defaults stringForKey:@"startColor"];
  if (color != nil) {
    [panel setColor:[NSColor colorFromString:color]];
  }
  [panel setMode:[defaults integerForKey:@"mode"]]; // will be 0 if not set, wich is NSGrayModeColorPanel

  // show panel
  [panel makeKeyAndOrderFront:self];
  //[NSApp runModalForWindow:panel]; // resets panel position
}

- (void)writeColor {
  NSString *hex = [panel.color toRGBAString:false];

  // save color and current mode to defaults
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:hex forKey:@"startColor"];
  [defaults setInteger:panel.mode forKey:@"mode"];
  [defaults synchronize]; // force a save since we are exiting

  // write color to stdout
  NSFileHandle *stdOut = [NSFileHandle fileHandleWithStandardOutput];
  [stdOut writeData:[hex dataUsingEncoding:NSASCIIStringEncoding]];

  [self exit];
}


- (void)exit {
  [panel close];
}

// panel delegate methods

- (void)windowWillClose:(NSNotification *)notification {
  [NSApp terminate:self];
}

// application delegate methods

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification {
  ProcessSerialNumber psn = {0, kCurrentProcess};
  TransformProcessType(&psn, kProcessTransformToForegroundApplication);
  SetFrontProcess(&psn);
  [self show];
}

@end

int main (int argc, const char * argv[]) {
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  NSApplication *app = [NSApplication sharedApplication];
  app.delegate = [[[Picker alloc] init] autorelease];
  [app run];
  [pool drain];
  return 0;
}
