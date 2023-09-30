//
//  Utility.h
//  Soundboard
//

#import <UIKit/UIKit.h>

// System color
#define SYSTEM_COLOR UIColor.tintColor

// Logging error
#define ERROR @"Error"

// Custom logging function
void logger (NSString* client, NSString* format, ...) NS_FORMAT_FUNCTION(2, 3);
