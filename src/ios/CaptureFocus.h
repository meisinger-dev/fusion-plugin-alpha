
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CaptureFocus : UIView <CAAnimationDelegate> {}

-(id) initWithTouchPoint:(CGPoint)point;
-(BOOL) updateTouchPoint:(CGPoint)point;
-(void) animate;

@end
