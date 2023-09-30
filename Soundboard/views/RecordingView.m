//
//  RecordingView.m
//  Soundboard
//

#import "RecordingView.h"

#import "../utility/Utility.h"

// Modal view constants
#define MODAL_BACKGROUND_COLOR UIColor.systemBackgroundColor
#define DEFAULT_SUBVIEW_SPACING 8.0
#define SUBVIEW_CORNER_RADIUS 10.0
#define SUBVIEW_BACKGROUND_COLOR UIColor.secondarySystemBackgroundColor
#define CONTENT_WIDTH_RATIO 0.8
#define DEFAULT_HEIGHT_INSET 25.0

// Button constants
#define BUTTON_FONT_SIZE 44.0
#define LARGE_BUTTON_FONT_SIZE 1.5*BUTTON_FONT_SIZE
#define DISABLED_BUTTON_COLOR UIColor.systemGrayColor
#define PLAY_SYMBOL [UIImage systemImageNamed:@"play.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:BUTTON_FONT_SIZE]]
#define PAUSE_SYMBOL [UIImage systemImageNamed:@"pause.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:BUTTON_FONT_SIZE]]
#define RECORD_SYMBOL [UIImage systemImageNamed:@"largecircle.fill.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:LARGE_BUTTON_FONT_SIZE]]
#define STOP_SYMBOL [UIImage systemImageNamed:@"stop.circle" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:LARGE_BUTTON_FONT_SIZE]]

// Text field constants
#define DEFAULT_RECORDING_TEXT @"New Recording"

// Stopwatch constants
#define DEFAULT_TIMESTAMP @"-:--"
#define ZERO_TIMESTAMP @"0:00"
#define MAX_TIMESTAMP @"0:10"

// Progress bar constants
#define PROGRESS_BAR_HEIGHT_RATIO 0.05
#define ZERO_PROGRESS 0.0
#define FULL_PROGRESS 1.0

// Audio recorder constants
#define RECORDER_FORMAT @(kAudioFormatMPEG4AAC)
#define RECORDER_SAMPLE_RATE @48000.0
#define RECORDER_NUM_CHANNELS @1

// Logging client name
#define REC_V NSStringFromClass([RecordingView class])

@interface RecordingView ()
{
    // Private variables
    UIView *textFieldContainer;
    UIProgressView *progressBar;
    UILabel *currentTime;
    UILabel *duration;
}

// Private methods
- (void) setConstraints;
- (void) showPlayButton:(BOOL)playing;
- (void) showRecordButton:(BOOL)recording;

@end

@implementation RecordingView

@synthesize textField;
@synthesize playButton;
@synthesize recordButton;
@synthesize player;
@synthesize recorder;

#pragma mark - UIView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        logger(REC_V, @"Initializing recording view");

        // Initialize recording view
        self.backgroundColor = MODAL_BACKGROUND_COLOR;
        self.axis = UILayoutConstraintAxisVertical;
        self.layoutMarginsRelativeArrangement = YES;
        self.alignment = UIStackViewAlignmentCenter;
        self.spacing = DEFAULT_SUBVIEW_SPACING;
        self.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(0.0, 0.0, DEFAULT_SUBVIEW_SPACING, 0.0);

        // Initialize text field
        // Simulator log: [Query] Error for queryMetaDataSync: 2
        textField = [[UITextField alloc] init];
        textField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleLargeTitle];
        textField.tintColor = SYSTEM_COLOR;
        textField.adjustsFontForContentSizeCategory = YES;
        textField.clearsOnBeginEditing = YES;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textFieldContainer = [[UIView alloc] init];
        [textFieldContainer addSubview:textField];
        [self addArrangedSubview:textFieldContainer];

        // Initialized stopwatch labels
        currentTime = [[UILabel alloc] init];
        currentTime.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        currentTime.adjustsFontForContentSizeCategory = YES;
        duration = [[UILabel alloc] init];
        duration.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        duration.adjustsFontForContentSizeCategory = YES;

        UIStackView *stopwatchRow = [[UIStackView alloc] initWithArrangedSubviews:[NSArray arrayWithObjects:currentTime, duration, nil]];
        stopwatchRow.distribution = UIStackViewDistributionEqualSpacing;

        // Initialize progress bar
        progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressBar.trackTintColor = SUBVIEW_BACKGROUND_COLOR;
        progressBar.progressTintColor = SYSTEM_COLOR;
        progressBar.layer.cornerRadius = SUBVIEW_CORNER_RADIUS;

        UIStackView *progressCol = [[UIStackView alloc] initWithArrangedSubviews:[NSArray arrayWithObjects:progressBar, stopwatchRow, nil]];
        progressCol.axis = UILayoutConstraintAxisVertical;

        // Initialize play button
        playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [playButton setImage:PLAY_SYMBOL forState:UIControlStateNormal];

        UIStackView *playbackRow = [[UIStackView alloc] initWithArrangedSubviews:[NSArray arrayWithObjects:playButton, progressCol, nil]];
        playbackRow.alignment = UIStackViewAlignmentLastBaseline;
        playbackRow.spacing = DEFAULT_SUBVIEW_SPACING;
        [self addArrangedSubview:playbackRow];

        // Initialize record button
        recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [recordButton setImage:RECORD_SYMBOL forState:UIControlStateNormal];
        recordButton.backgroundColor = SUBVIEW_BACKGROUND_COLOR;
        recordButton.layer.cornerRadius = SUBVIEW_CORNER_RADIUS;
        recordButton.tintColor = SYSTEM_COLOR;
        [self addArrangedSubview:recordButton];

        // Reset subviews
        [self resetSubviews];

        // Set subview layout constraints
        [self setConstraints];
    }
    return self;
}

#pragma mark - Private methods

- (void) setConstraints {
    UILayoutGuide *guide = self.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [textField.widthAnchor constraintEqualToAnchor:textFieldContainer.widthAnchor],
        [textField.centerYAnchor constraintEqualToAnchor:textFieldContainer.centerYAnchor],
        [textFieldContainer.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:CONTENT_WIDTH_RATIO],
        [playButton.widthAnchor constraintEqualToAnchor:playButton.heightAnchor],
        [playButton.widthAnchor constraintEqualToConstant:BUTTON_FONT_SIZE],
        [progressBar.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:CONTENT_WIDTH_RATIO constant:-(BUTTON_FONT_SIZE + DEFAULT_SUBVIEW_SPACING)],
        [currentTime.leadingAnchor constraintEqualToAnchor:progressBar.leadingAnchor],
        [duration.trailingAnchor constraintEqualToAnchor:progressBar.trailingAnchor],
        [recordButton.heightAnchor constraintEqualToConstant:LARGE_BUTTON_FONT_SIZE + (2*DEFAULT_SUBVIEW_SPACING)],
        [recordButton.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:CONTENT_WIDTH_RATIO],
    ]];
}

- (void) showPlayButton:(BOOL)playing {
    if (playing) {
        // Show pause button
        [playButton setImage:PAUSE_SYMBOL forState:UIControlStateNormal];
    }
    else {
        // Show play button
        [playButton setImage:PLAY_SYMBOL forState:UIControlStateNormal];
    }
}

- (void) showRecordButton:(BOOL)recording {
    if (recording) {
        // Show stop (recording) button
        [recordButton setImage:STOP_SYMBOL forState:UIControlStateNormal];
    }
    else {
        // Show record button
        [recordButton setImage:RECORD_SYMBOL forState:UIControlStateNormal];
    }
}

#pragma mark - Public methods

- (void) resetSubviews {
    if (self != nil) {
        // Reset subviews when recording view is opened
        textField.text = DEFAULT_RECORDING_TEXT;
        playButton.enabled = NO;
        playButton.tintColor = DISABLED_BUTTON_COLOR;
        [progressBar setProgress:ZERO_PROGRESS animated:NO];
        currentTime.text = DEFAULT_TIMESTAMP;
        duration.text = DEFAULT_TIMESTAMP;
    }
}

- (void) updateStopwatch {
    if (recorder.recording) {
        // Update audio recording duration
        duration.text = [NSString stringWithFormat:@"0:%0.2d", (int)recorder.currentTime];
    }
    else if (player.playing) {
        // Update audio playback timestamp
        NSTimeInterval time = player.currentTime;
        float progressRatio = time / player.duration;
        if (progressRatio > progressBar.progress) {
            // Do not update subviews if `player.currentTime` resets
            currentTime.text = [NSString stringWithFormat:@"0:%0.2d", (int)time];
            [progressBar setProgress:progressRatio animated:YES];
        }
    }
}

- (void) resetAudioPlayer {
    if (player.playing) {
        // Stop audio playback
        [self showPlayButton:NO];
        [player stop];
    }

    // Release player object
    player = nil;
}

- (void) playAudio {
    // Start audio playback
    [self showPlayButton:YES];
    [player play];
    
    // Update playback subviews
    duration.text = [NSString stringWithFormat:@"0:%0.2d", (int)player.duration];
    [progressBar setProgress:player.currentTime/player.duration animated:NO];
}

- (void) pauseAudio {
    // Pause audio playback
    [self showPlayButton:NO];
    [player pause];
}

- (void) endAudio {
    // Update subviews after audio playback finishes
    [self showPlayButton:NO];
    [progressBar setProgress:FULL_PROGRESS animated:YES];
    
    if (player.duration >= MAX_RECORDING_DURATION) {
        // Set stopwatch to max values
        currentTime.text = MAX_TIMESTAMP;
    }
}

- (void) deleteAudio:(NSURL*)file {
    // Reset audio player
    [self resetAudioPlayer];

    // Stop ongoing recording
    if (recorder.recording) {
        [recorder stop];
    }

    // Delete temporary audio file
    if ([NSFileManager.defaultManager fileExistsAtPath:file.path]) {
        logger(REC_V, @"Deleting temporary audio file");

        if (![recorder deleteRecording]) {
            NSAssert(FALSE, @"[%@] Could not delete temporary audio file", ERROR);
        }
    }
}

- (void) initRecorder:(NSURL*)file {
    // Initialize audio recorder
    NSError *error;
    NSDictionary *settings = @{
        AVFormatIDKey: RECORDER_FORMAT,
        AVSampleRateKey: RECORDER_SAMPLE_RATE,
        AVNumberOfChannelsKey: RECORDER_NUM_CHANNELS,
    };
    recorder = [[AVAudioRecorder alloc] initWithURL:file settings:settings error:&error];
    NSAssert((recorder != nil), @"[%@] %@", ERROR, [error localizedDescription]);
}

- (void) startRecording {
    // Reset audio player
    [self resetAudioPlayer];

    // Start audio recording
    [self showRecordButton:YES];
    [recorder record];

    // Reset playback subviews
    playButton.enabled = NO;
    playButton.tintColor = DISABLED_BUTTON_COLOR;
    currentTime.text = ZERO_TIMESTAMP;
    [progressBar setProgress:ZERO_PROGRESS animated:NO];
}

- (void) stopRecording:(NSURL*)file {
    // Stop audio playback
    [self showRecordButton:NO];
    [recorder stop];

    // Enable playback subviews
    playButton.enabled = YES;
    playButton.tintColor = SYSTEM_COLOR;

    // Initialize audio player
    // Simulator log: [plugin] AddInstanceForFactory: No factory registered for id
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:file fileTypeHint:AVFileTypeAppleM4A error:&error];
    NSAssert((player != nil), @"[%@] %@", ERROR, [error localizedDescription]);
}

@end
