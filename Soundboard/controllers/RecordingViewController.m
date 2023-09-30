//
//  RecordingViewController.m
//  Soundboard
//

#import "RecordingViewController.h"
#import "LibraryViewController.h"

#import "../views/RecordingView.h"
#import "../utility/Utility.h"

// Navigation bar constants
#define RECORDING_TITLE @"Add Recording"

// Timer constants
#define TIMER_INTERVAL 0.001

// Recording storage constants
#define TEMPORARY_FILENAME [NSString stringWithFormat:@"temp_recording%@", AUDIO_FILE_FORMAT]

// Text field constants
#define MAX_RECORDING_NAME_LENGTH 10

// Logging client name
#define REC_VC NSStringFromClass([RecordingViewController class])

@interface RecordingViewController ()
{
    // Private variables
    RecordingView *recordingView;
    LibraryViewController __weak *library;
    NSTimer *timer;
    NSURL *temporaryAudioFile;
}

// Private methods
- (void) timerFire:(NSTimer *)timer;
- (void) audioPlayback;
- (void) audioRecording;
- (void) cancelRecording;
- (void) saveRecording;

@end

@implementation RecordingViewController

@synthesize directory;

#pragma mark - NSObject

- (instancetype) init {
    self = [super init];
    if (self != nil) {
        logger(REC_VC, @"Initializing recording view controller");

        // Initialize timer
        [timer invalidate];
        timer = nil;

        // Initialize temporary audio recording file (write to `Documents` directory)
        NSError *error;
        directory = [NSFileManager.defaultManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        NSAssert((directory != nil), @"[%@] %@", ERROR, [error localizedDescription]);
        temporaryAudioFile = [directory URLByAppendingPathComponent:TEMPORARY_FILENAME];
    }
    return self;
}

#pragma mark - UIViewController

- (void) loadView {
    [super loadView];

    // Initialize recording view
    recordingView = [[RecordingView alloc] init];
    recordingView.textField.delegate = self;
    [recordingView.playButton addTarget:self action:@selector(audioPlayback) forControlEvents:UIControlEventTouchUpInside];
    [recordingView.recordButton addTarget:self action:@selector(audioRecording) forControlEvents:UIControlEventTouchUpInside];
    [recordingView initRecorder:temporaryAudioFile];
    self.view = recordingView;

    // Define parent view controller
    library = (LibraryViewController*)(((UINavigationController*)self.presentingViewController).topViewController);

    // Set navigation bar (managed by parent navigation controller)
    self.navigationItem.title = RECORDING_TITLE;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelRecording)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveRecording)];
    self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleDone;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (void) presentationControllerDidDismiss:(UIPresentationController *)presentationController {
    logger(REC_VC, @"Dismissing recording window");

    // Interactive dismissal (tap outside modal window to close)
    [recordingView deleteAudio:temporaryAudioFile];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // Only insert `string` if the total resultant string <= `MAX_RECORDING_NAME_LENGTH`
    if (textField.text.length - range.length + string.length <= MAX_RECORDING_NAME_LENGTH) {
        for (NSUInteger i = 0; i < string.length; i++) {
            unichar c = [string characterAtIndex:i];

            // Only allow alphanumeric characters, spaces, and underscores
            if (![[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] && ![string isEqual:@" "]) {
                return NO;
            }
        }
        return YES;
    }
    return NO;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    // Dismiss the keyboard when the user taps the return button
    return [textField resignFirstResponder];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSAssert(flag, @"[%@] Could not finish playing audio successfully", ERROR);

    // Finished playing current audio recording
    logger(REC_VC, @"Finished audio playback");
    [recordingView endAudio];
    [timer invalidate];
    timer = nil;
}

#pragma mark - Private methods

- (void) timerFire:(NSTimer *)timer {
    // Update stopwatch values
    [recordingView updateStopwatch];

    if (recordingView.recorder.recording && recordingView.recorder.currentTime >= MAX_RECORDING_DURATION) {
        // Stop audio recording once max duration is reached
        [self audioRecording];
    }
}

- (void) audioPlayback {
    logger(REC_VC, @"%@ audio playback", (!recordingView.player.playing) ? @"Starting" : @"Pausing");

    if (!recordingView.player.playing) {
        // Start audio playback and timer
        [recordingView playAudio];
        timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
    }
    else {
        // Pause audio playback and stop timer
        [recordingView pauseAudio];
        [timer invalidate];
        timer = nil;
    }
}

- (void) audioRecording {
    logger(REC_VC, @"%@ audio recording", (!recordingView.recorder.recording) ? @"Starting" : @"Stopping");

    if (!recordingView.recorder.recording) {
        // Start audio recording and timer
        [recordingView startRecording];
        timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else {
        // Stop audio recording and timer
        [recordingView stopRecording:temporaryAudioFile];
        [timer invalidate];
        timer = nil;
        self.navigationItem.rightBarButtonItem.enabled = YES;

        // Set AVAudioPlayer delegate
        recordingView.player.delegate = self;
    }
}

- (void) cancelRecording {
    logger(REC_VC, @"Cancel button pressed");

    // Delete temporary audio file
    [recordingView deleteAudio:temporaryAudioFile];

    // Deallocate timer object
    [timer invalidate];
    timer = nil;

    // Dismiss modal view
    [library dismissViewControllerAnimated:YES completion:nil];
}

- (void) saveRecording {
    logger(REC_VC, @"Save button pressed");

    // Deallocate audio player object
    [recordingView resetAudioPlayer];

    // Create output audio file
    NSString *outputName = [recordingView.textField.text stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    NSString *timestamp = [NSString stringWithFormat:@"%lf", [NSDate date].timeIntervalSince1970];
    timestamp = [timestamp stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSURL *outputURL = [directory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@%@", outputName, timestamp, AUDIO_FILE_FORMAT]];
    NSError *error;
    if (![NSFileManager.defaultManager moveItemAtURL:temporaryAudioFile toURL:outputURL error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }

    // Save new audio recording
    [library addRecordingItem:recordingView.textField.text url:outputURL];

    // Dismiss modal view
    [library dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Public methods

- (void) reset {
    // Reset recording view
    [recordingView resetSubviews];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) deleteTemporaryFile {
    if ([NSFileManager.defaultManager fileExistsAtPath:temporaryAudioFile.path]) {
        // Delete old temporary file
        NSError *error;
        if (![NSFileManager.defaultManager removeItemAtURL:temporaryAudioFile error:&error]) {
            NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
        }
    }
}

@end
