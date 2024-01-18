//
//  LibraryViewCell.h
//  Soundboard
//

#import <UIKit/UIKit.h>

// Logger client name
#define LIB_CELL NSStringFromClass([LibraryViewCell class])

@interface LibraryViewCell : UICollectionViewCell

// Public variables
@property (readonly) UIButton *minusButton;

// Public methods
- (void) showMinusButton:(BOOL)editing;
- (void) resetSubviewsWithName:(NSString*)name editing:(BOOL)editing;
- (void) cellTapAnimation;
- (void) minusButtonTapAnimation;

@end
