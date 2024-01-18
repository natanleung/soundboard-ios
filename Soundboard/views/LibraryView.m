//
//  LibraryView.m
//  Soundboard
//

#import "LibraryView.h"
#import "LibraryViewCell.h"

#import "../utility/Utility.h"

// Instruction label constants
#define INSTRUCTION_LABEL_COLOR UIColor.secondaryLabelColor

// Logging client name
#define LIB_VIEW NSStringFromClass([LibraryView class])

@interface LibraryView ()
{
    // Private variables
    UILabel *instruction;
    AVAudioPlayer *player;
}

// Private methods
- (void) setConstraints;

@end

@implementation LibraryView

#pragma mark - UICollectionView

- (instancetype) initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    logger(LIB_VIEW, @"Initializing library view");

    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self != nil) {
        // Initialize collection view
        self.backgroundColor = UIColor.systemBackgroundColor;
        self.alwaysBounceVertical = YES;

        // Register collection view classes
        [self registerClass:[LibraryViewCell class] forCellWithReuseIdentifier:LIB_CELL];

        // Initialize instruction label
        instruction = [[UILabel alloc] init];
        instruction.text = @"Press the \"+\" button to create a new recording.";
        instruction.textColor = INSTRUCTION_LABEL_COLOR;
        instruction.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        instruction.adjustsFontForContentSizeCategory = YES;
        instruction.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:instruction];

        // Set subview layout constraints
        [self setConstraints];
    }
    return self;
}

#pragma mark - Private methods

- (void) setConstraints {
    // Set layout constraints
    UILayoutGuide *guide = self.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [instruction.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [instruction.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor],
    ]];
}

#pragma mark - Public methods

- (void) showInstruction:(BOOL)empty {
    // Show or hide instruction label
    instruction.hidden = !empty;
}

- (void) showCellMinusButtons:(BOOL)editing {
    // Show or hide minus buttons for all visible cells
    for (LibraryViewCell *cell in self.visibleCells) {
        [cell showMinusButton:editing];
    }
}

- (NSIndexPath*) indexPathForButton:(UIButton*)sender {
    // Return index path of cell associated with the tapped button
    // View hierarchy: UIButton -> LibraryViewCell.contentView (UIView) -> LibraryViewCell
    LibraryViewCell *cell = (LibraryViewCell*)sender.superview.superview;
    return [self indexPathForCell:cell];
}

- (void) addCellAtEnd {
    // Create new cell at the end of the library view
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[self numberOfItemsInSection:0] inSection:0];
    [self insertItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];

    // Scroll to bottom of the collection view to add cell onscreen
    [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
}

- (void) deleteCellAtIndex:(NSIndexPath*)indexPath {
    // Delete cell at `indexPath`
    [self deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
}

- (void) playCellAudio:(NSURL*)url {
    // Stop ongoing audio playback
    [self stopCellAudio];

    // Initialize audio player
    NSError *error;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url fileTypeHint:AVFileTypeAppleM4A error:&error];
    NSAssert((player != nil), @"[%@] %@", ERROR, [error localizedDescription]);

    // Play audio recording at `url`
    logger(LIB_VIEW, @"Playing cell recording \"%@\"", url.lastPathComponent);
    [player play];
}

- (void) stopCellAudio {
    // Stop ongoing audio playback
    [player stop];
    player = nil;
}

@end
