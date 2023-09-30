//
//  Recording.h
//  Soundboard
//

#import <UIKit/UIKit.h>

@interface Recording : NSObject

// Public variables
@property (readonly) NSString *name;
@property (readonly) NSURL *url;

// Public methods
+ (Recording*) recordingWithName:(NSString*)_name url:(NSURL*)_url;
- (Recording*) initWithName:(NSString*)_name url:(NSURL*)_url;

@end
