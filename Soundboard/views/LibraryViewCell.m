//
//  LibraryViewCell.m
//  Soundboard
//

#import "LibraryViewCell.h"

#import "../utility/Utility.h"

// Library cell constants
#define CELL_BACKGROUND_COLOR UIColor.systemFillColor
#define CELL_CORNER_RADIUS 10.0
#define CELL_ANIMATION_DURATION 0.25

// Label constants
#define LABEL_WIDTH_RATIO 0.9

// Minus button constants
#define MINUS_SYMBOL [UIImage systemImageNamed:@"minus.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:MINUS_BUTTON_FONT_SIZE]]
#define MINUS_BUTTON_FONT_SIZE 25.0

@interface LibraryViewCell ()
{
    // Private variables
    UILabel *label;
}

// Private methods
- (void) setConstraints;

@end

@implementation LibraryViewCell

@synthesize minusButton;

#pragma mark - UIView

- (instancetype) initWithFrame:(CGRect)frame {
    logger(LIB_CELL, @"Initializing library view cell");

    self = [super initWithFrame:frame];
    if (self != nil) {
        // Initialize cell
        self.layer.cornerRadius = CELL_CORNER_RADIUS;
        self.backgroundColor = CELL_BACKGROUND_COLOR;

        // Initialize minus button
        minusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [minusButton setImage:MINUS_SYMBOL forState:UIControlStateNormal];
        minusButton.tintColor = SYSTEM_COLOR;
        minusButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:minusButton];

        // Initialize title label
        label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.adjustsFontSizeToFitWidth = YES;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:label];

        // Set subview layout constraints
        [self setConstraints];
    }
    return self;
}

#pragma mark - Private methods

- (void) setConstraints {
    // Set layout constraints
    UILayoutGuide *guide = self.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [minusButton.centerXAnchor constraintEqualToAnchor:guide.leftAnchor],
        [minusButton.centerYAnchor constraintEqualToAnchor:guide.topAnchor],
        [label.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor],
        [label.widthAnchor constraintEqualToAnchor:guide.widthAnchor multiplier:LABEL_WIDTH_RATIO],
    ]];
}

#pragma mark - Public methods

- (void) showMinusButton:(BOOL)editing {
    // Show or hide minus button
    minusButton.hidden = !editing;
}

- (void) resetSubviewsWithName:(NSString*)name editing:(BOOL)editing {
    // Set label text to `text`
    label.text = name;

    // Set minus buttons
    [self showMinusButton:editing];
}

- (void) cellTapAnimation {
    [UIView animateWithDuration:CELL_ANIMATION_DURATION animations:^ void (void) {
        self.backgroundColor = SYSTEM_COLOR;
        self.backgroundColor = CELL_BACKGROUND_COLOR;
    }];
}

- (void) minusButtonTapAnimation {
    [UIView animateWithDuration:CELL_ANIMATION_DURATION animations:^ void (void) {
        self.minusButton.tintColor = UIColor.clearColor;
        self.minusButton.tintColor = SYSTEM_COLOR;
    }];
}

@end
