//
//  LibraryView.h
//  Soundboard
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>

@interface LibraryView : UICollectionView

// Public methods
- (void) showInstruction:(BOOL)empty;
- (void) showCellMinusButtons:(BOOL)editing;
- (NSIndexPath*) indexPathForButton:(UIButton*)sender;
- (void) addCellAtEnd;
- (void) deleteCellAtIndex:(NSIndexPath*)indexPath;
- (void) playCellAudio:(NSURL*)url;
- (void) stopCellAudio;

@end
