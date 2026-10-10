#import "DITThrowingCornerRadiusFixture.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation DITThrowingCornerRadiusFixture

- (CGFloat)_displayCornerRadius {
  [NSException raise:NSInternalInconsistencyException format:@"Simulated private getter failure"];
  return 0;
}

@end
