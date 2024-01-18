//
//  Recording.m
//  Soundboard
//

#import "Recording.h"

#import "../utility/Utility.h"

// Logging client name
#define REC_OBJ NSStringFromClass([Recording class])

@implementation Recording

@synthesize name;
@synthesize url;

#pragma mark - Factory methods

+ (Recording*) recordingWithName:(NSString*)_name url:(NSURL*)_url {
    // Factory method to create a Recording object
    return [[self alloc] initWithName:_name url:_url];
}

#pragma mark - Initialization methods

- (Recording*) initWithName:(NSString*)_name url:(NSURL*)_url {
    logger(REC_OBJ, @"Creating recording object");

    // Designated initializer to create a Recording object
    self = [super init];
    if (self != nil) {
        name = _name;
        url = _url;
    }
    return self;
}

@end
