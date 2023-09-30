//
//  PermissionsAlertController.m
//  Soundboard
//

#import "PermissionsAlertController.h"

#import "../utility/Utility.h"

// Logging client name
#define PER_VC NSStringFromClass([PermissionsAlertController class])

@implementation PermissionsAlertController

#pragma mark - Factory methods

+ (instancetype) alertController {
    logger(PER_VC, @"Initializing permissions alert controller");

    // Initialize permissions alert controller
    return (PermissionsAlertController*)[super alertControllerWithTitle:@"\"Soundboard\" Would Like to Access the Microphone" message:@"Enable microphone access to create audio recordings." preferredStyle:UIAlertControllerStyleAlert];
}

#pragma mark - UIViewController

- (void) loadView {
    [super loadView];

    // Add "Settings" button to permissions alert
    [self addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler: ^ void (UIAlertAction *action) {
        logger(PER_VC, @"Settings button pressed");

        // Open settings app
        logger(PER_VC, @"Opening Settings app");
        NSURL *url = [[NSURL alloc] initWithString:UIApplicationOpenSettingsURLString];
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^ void (BOOL success) {
            NSAssert(success, @"[%@] Could not open Settings app", ERROR);
        }];

    }]];

    // Add "OK" button to permissions alert
    [self addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler: ^ void (UIAlertAction *action) {
        logger(PER_VC, @"OK button pressed");

        // Close alert message
        UIViewController *library = (((UINavigationController*)self.presentingViewController).topViewController);
        [library dismissViewControllerAnimated:YES completion:nil];
    }]];
    self.preferredAction = [self.actions lastObject];
}

@end
