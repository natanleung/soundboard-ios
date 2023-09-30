//
//  RecordingView.h
//  Soundboard
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

// Audio recorder constants
#define MAX_RECORDING_DURATION 10.0

@interface RecordingView : UIStackView

// Public variables
@property (readonly) UITextField *textField;
@property (readonly) UIButton *playButton;
@property (readonly) UIButton *recordButton;
@property (readonly) AVAudioPlayer *player;
@property (readonly) AVAudioRecorder *recorder;

// Public methods
- (void) resetSubviews;
- (void) updateStopwatch;
- (void) resetAudioPlayer;
- (void) playAudio;
- (void) pauseAudio;
- (void) endAudio;
- (void) deleteAudio:(NSURL*)file;
- (void) initRecorder:(NSURL*)file;
- (void) startRecording;
- (void) stopRecording:(NSURL*)file;

@end
