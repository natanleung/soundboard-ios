//
//  SceneDelegate.m
//  Soundboard
//

#import "SceneDelegate.h"

#import "../controllers/LibraryViewController.h"

@implementation SceneDelegate

@synthesize window;

- (void) scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.

    // Initialize root view controller
    LibraryViewController *library = [[LibraryViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:library];

    // Initialize application window
    window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene*)scene];
    window.rootViewController = navigation;
    [window makeKeyAndVisible];
}

@end
