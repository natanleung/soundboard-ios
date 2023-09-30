//
//  UICollectionView+TouchEvent.m
//  Soundboard
//

#import "UICollectionView+TouchEvent.h"
#import "LibraryViewCell.h"

@implementation UICollectionView (TouchEvent)

#pragma mark - UIView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    // Manually detect minus button presses for deletion because minus button partially lies outside its parent cell view
    if (self.isEditing) {
        for (LibraryViewCell *cell in self.visibleCells) {
            if (CGRectContainsPoint([self convertRect:cell.minusButton.frame fromView:cell], point)) {
                return cell.minusButton;
            }
        }
    }
    return [super hitTest:point withEvent:event];
}

@end
