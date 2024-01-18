//
//  RecordingViewController.h
//  Soundboard
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

// Recording storage constants
#define AUDIO_FILE_FORMAT @".m4a"

@interface RecordingViewController : UIViewController <UIAdaptivePresentationControllerDelegate, UITextFieldDelegate, AVAudioPlayerDelegate>

// Public variables
@property (readonly) NSURL *directory;

// Public methods
- (void) reset;
- (void) deleteTemporaryFile;

@end
