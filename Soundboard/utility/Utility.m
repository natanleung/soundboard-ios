//
//  Utility.m
//  Soundboard
//

#import "Utility.h"

#pragma mark - Public methods

void logger (NSString* client, NSString* format, ...) {
    // Custom logging function
    va_list args;
    va_start(args, format);
    format = [NSString stringWithFormat:@"[%@] %@", client, format];
    NSLogv(format, args);
    va_end(args);
}
