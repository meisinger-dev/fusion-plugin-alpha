
#import <QuartzCore/QuartzCore.h>
#import "CaptureFocus.h"

@implementation CaptureFocus {
  CGPoint focusPoint;
  CABasicAnimation* blinkAnimation;
}

-(id) initWithTouchPoint:(CGPoint)point {
  self = [super init];
  if (self) {
    [self updateTouchPoint:point];
    
    blinkAnimation = [CABasicAnimation animationWithKeyPath:@"borderColor"];
    blinkAnimation.repeatCount = 3;
    blinkAnimation.duration = 0.4;
    blinkAnimation.delegate = self;
    blinkAnimation.toValue = (id)[UIColor orangeColor].CGColor;
    
    [self setBackgroundColor:[UIColor clearColor]];
    [self.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.layer setBorderWidth:2.f];
    [self.layer setCornerRadius:8.f];
  }
  
  return self;
}

-(BOOL) updateTouchPoint:(CGPoint)point {
  if (CGPointEqualToPoint(focusPoint, point))
    return NO;
  
  CGRect frame = CGRectMake(point.x - 50, point.y - 50, 100, 100);
  self.frame = frame;
  
  focusPoint = point;
  return YES;
}

-(void) animate {
  self.alpha = 1.f;
  self.hidden = NO;
  
  [self.layer addAnimation:blinkAnimation forKey:@"selectionAnimation"];
}

-(void) animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
  self.alpha = 0.f;
  self.hidden = YES;
}

@end