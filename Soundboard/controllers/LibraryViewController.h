//
//  ViewController.h
//  Soundboard
//

#import <UIKit/UIKit.h>

@interface LibraryViewController : UICollectionViewController <UIContentContainer>

// Public methods
- (void) addRecordingItem:(NSString*)name url:(NSURL*)url;

@end
