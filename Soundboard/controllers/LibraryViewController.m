//
//  ViewController.m
//  Soundboard
//

#import "LibraryViewController.h"
#import "PermissionsAlertController.h"
#import "RecordingViewController.h"

#import "../views/LibraryView.h"
#import "../views/LibraryViewCell.h"
#import "../models/Recording.h"
#import "../utility/Utility.h"

// Navigation bar constants
#define LIBRARY_TITLE @"Soundboard"

// Logging client name
#define LIB_VC NSStringFromClass([LibraryViewController class])

@interface LibraryViewController ()
{
    // Private variables
    LibraryView *libraryView;
    NSMutableArray<Recording*> *recordings;
    RecordingViewController *recordingModal;
    PermissionsAlertController *permissionsAlert;
}

// Private methods
- (void) checkDataCount;
- (void) addCell;
- (void) deleteCell:(UIButton*)sender;
- (void) enableAudioPlayAndRecord;
- (void) enableAudioPlayback;
- (void) checkMicrophoneAccess;

@end

@implementation LibraryViewController

#pragma mark - NSObject

- (instancetype) init {
    // Initialize collection view layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(2*layout.itemSize.width, layout.itemSize.height);
    layout.minimumLineSpacing *= 2;
    layout.sectionInsetReference = UICollectionViewFlowLayoutSectionInsetFromLayoutMargins;
    layout.minimumInteritemSpacing *= 1.5;

    // Initialize library view controller
    self = [super initWithCollectionViewLayout:layout];
    if (self != nil) {
        logger(LIB_VC, @"Initializing library view controller");

        // Initialize recordings array
        recordings = [[NSMutableArray alloc] init];

        // Initialize recording modal
        recordingModal = [[RecordingViewController alloc] init];

        // Initialize alert message
        permissionsAlert = [PermissionsAlertController alertController];
    }
    return self;
}

#pragma mark - UIViewController

- (void) loadView {
    [super loadView];

    // Initialize library view
    libraryView = [[LibraryView alloc] initWithFrame:self.collectionView.frame collectionViewLayout:self.collectionViewLayout];
    self.collectionView = libraryView;

    // Set navigation bar (managed by parent navigation controller)
    self.navigationItem.title = LIBRARY_TITLE;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addCell)];

    // Retrieve all file paths from `Documents` directory
    [recordingModal deleteTemporaryFile];
    NSError *error;
    NSArray<NSString*> *files = [NSFileManager.defaultManager contentsOfDirectoryAtPath:recordingModal.directory.path error:&error];
    NSAssert((files != nil), @"[%@] %@", ERROR, [error localizedDescription]);

    // Initialize library cells for preexisting audio recordings
    logger(LIB_VC, @"Found %lu potential old recordings", files.count);
    for (NSString *file in [files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF endswith %@", AUDIO_FILE_FORMAT]]) {
        NSString *name = [[file componentsSeparatedByString:@"_"] objectAtIndex:0].stringByRemovingPercentEncoding;
        NSURL *url = [recordingModal.directory URLByAppendingPathComponent:file];
        [self addRecordingItem:name url:url];
    }

    // Verify data source and library match
    [self checkDataCount];

    // Check microphone access
    [self checkMicrophoneAccess];
}

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];

    if (recordings.count - [libraryView numberOfItemsInSection:0] == 1) {
        // Create new library cell when modal view is closed and data source is updated
        [libraryView addCellAtEnd];
    }

    // Verify data source and library match
    [self checkDataCount];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    logger(LIB_VC, @"%@ button pressed", (editing) ? @"Edit" : @"Done");

    // Toggle editing mode for the library view
    [libraryView showCellMinusButtons:editing];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    // Retrieve current number of recordings
    return recordings.count;
}

- (__kindof UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // Retrieve cell based on `indexPath`
    LibraryViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LIB_CELL forIndexPath:indexPath];

    // Update cell
    Recording *recording = recordings[indexPath.item];
    [cell resetSubviewsWithName:recording.name editing:self.editing];
    [cell.minusButton addTarget:self action:@selector(deleteCell:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Animation on cell tap
    LibraryViewCell *cell = (LibraryViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    [cell cellTapAnimation];

    // Play recording corresponding with selected cell
    Recording *recording = recordings[indexPath.item];
    logger(LIB_VC, @"Playing cell recording \"%@\"", recording.name);
    [libraryView playCellAudio:recording.url];
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidChangeAdjustedContentInset:(UIScrollView*)scrollView {
    // Scroll view content inset has changed
    // Likely due to device rotation changing the safe area layout

    // Compute uniform interitem spacing
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    CGFloat minInteritemSpacing = layout.minimumInteritemSpacing;
    CGFloat width = scrollView.safeAreaLayoutGuide.layoutFrame.size.width;
    NSInteger itemsPerLine = (width - minInteritemSpacing) / (layout.itemSize.width + minInteritemSpacing);
    CGFloat interitemSpacing = (width - (itemsPerLine * layout.itemSize.width)) / (itemsPerLine+1);

    // Set content inset based on safe area insets
    if ((scrollView.contentInset.left != interitemSpacing) || (scrollView.contentInset.right != interitemSpacing)) {
        logger(LIB_VC, @"Device rotated, computing content inset to set uniform interitem spacing: %lf", interitemSpacing);

        // Only visible if content inset > layout margins (usually in portrait)
        scrollView.contentInset = UIEdgeInsetsMake(0.0, interitemSpacing, 0.0, interitemSpacing);
        [self.collectionViewLayout invalidateLayout];
    }
}

#pragma mark - Private methods

- (void) checkDataCount {
    // Check that the number of recordings (data source) and cells (library view) match
    // Raise exception if a data count mismatch is found
    NSAssert((recordings.count == [libraryView numberOfItemsInSection:0]), @"[%@] Number of recordings does not match number of cells", ERROR);
}

- (void) addCell {
    logger(LIB_VC, @"Plus button pressed");

    // Disable editing mode
    if (self.editing) {
        [self setEditing:NO animated:YES];
    }

    // Stop ongoing audio playback
    [libraryView stopCellAudio];

    AVAudioSessionCategory category = [AVAudioSession sharedInstance].category;
    if ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        logger(LIB_VC, @"Audio session enables recording");

        // Reset recording modal subviews
        [recordingModal reset];

        // Set UIAdaptivePresentationController delegate
        UINavigationController *recordingNavigation = [[UINavigationController alloc] initWithRootViewController:recordingModal];
        recordingNavigation.presentationController.delegate = recordingModal;

        // Set modal detent height
        recordingNavigation.sheetPresentationController.detents = [NSArray arrayWithObject:[UISheetPresentationControllerDetent mediumDetent]];

        // Present recording modal to create a new recording
        [self presentViewController:recordingNavigation animated:YES completion:nil];
    }
    else if ([category isEqualToString:AVAudioSessionCategoryPlayback]) {
        logger(LIB_VC, @"Audio session disables recording");

        // Present permissions alert to request microphone access
        [self presentViewController:permissionsAlert animated:YES completion:nil];
    }
    else {
        NSAssert(FALSE, @"[%@] Invalid audio session category", ERROR);
    }
}

- (void) deleteCell:(UIButton*)sender {
    logger(LIB_VC, @"Delete button pressed");

    // Animation on minus button tap
    NSIndexPath *indexPath = [libraryView indexPathForButton:sender];
    LibraryViewCell *cell = (LibraryViewCell*)[libraryView cellForItemAtIndexPath:indexPath];
    [cell minusButtonTapAnimation];

    // Delete audio recording
    Recording *deletedRecording = recordings[indexPath.item];
    logger(LIB_VC, @"Deleting audio recording \"%@\"", deletedRecording.url.lastPathComponent);
    NSError *error;
    if (![NSFileManager.defaultManager removeItemAtURL:deletedRecording.url error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }

    // Delete data source element
    [recordings removeObjectAtIndex:indexPath.item];

    // Delete cell
    [libraryView deleteCellAtIndex:indexPath];

    if (recordings.count == 0) {
        // Disable editing mode if deleting the last cell
        [self setEditing:NO animated:YES];
        self.navigationItem.leftBarButtonItem.enabled = NO;

        // Show instruction if no cells are left
        [libraryView showInstruction:YES];
    }

    // Verify data source and library match
    [self checkDataCount];
}

- (void) enableAudioPlayAndRecord {
    // Initialize audio session for playback and recording
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }

    // Activate audio session
    if (![session setActive:YES error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }
}

- (void) enableAudioPlayback {
    // Initialize audio session for just playback
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (![session setCategory:AVAudioSessionCategoryPlayback error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }

    // Activate audio session
    if (![session setActive:YES error:&error]) {
        NSAssert(FALSE, @"[%@] %@", ERROR, [error localizedDescription]);
    }
}

- (void) checkMicrophoneAccess {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    switch (session.recordPermission) {
        case (AVAudioSessionRecordPermissionUndetermined):
        {
            // Request microphone access
            [session requestRecordPermission:^ void (BOOL granted) {
                logger(LIB_VC, @"Microphone access %@", (granted) ? @"granted" : @"denied");
                // Initialize audio session based on user setting
                if (granted) {
                    [self enableAudioPlayAndRecord];
                }
                else {
                    [self enableAudioPlayback];
                }
            }];
            break;
        }
        case (AVAudioSessionRecordPermissionDenied):
        {
            logger(LIB_VC, @"Microphone access denied");

            // Microphone access denied so only initialize for audio playback of preexisting cells
            [self enableAudioPlayback];
            break;
        }
        case (AVAudioSessionRecordPermissionGranted):
        {
            logger(LIB_VC, @"Microphone access granted");

            // Microphone access granted so initialize for audio playback and recording
            [self enableAudioPlayAndRecord];
            break;
        }
        default:
        {
            NSAssert(FALSE, @"[%@] Could not obtain microphone access", ERROR);
        }
    }
}

#pragma mark - Public methods

- (void) addRecordingItem:(NSString*)name url:(NSURL*)url {
    logger(LIB_VC, @"Adding audio recording \"%@\" to data source", url.lastPathComponent);

    // Add new recording to data source
    Recording *newRecording = [Recording recordingWithName:name url:url];
    [recordings addObject:newRecording];

    if (recordings.count == 1) {
        // Enable cell deletion
        self.navigationItem.leftBarButtonItem.enabled = YES;

        // Hide instruction after adding the first cell
        [libraryView showInstruction:NO];
    }
}

@end
