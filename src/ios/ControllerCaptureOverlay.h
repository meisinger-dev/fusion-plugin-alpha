
#import <UIKit/UIKit.h>
#import "CaptureManager.h"

@class FusionPlugin;
@interface ControllerCaptureOverlay : UIViewController <UINavigationControllerDelegate, CaptureOutputDelegate> {}

@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet UIButton* captureButton;
@property (weak, nonatomic) IBOutlet UIImageView* overlayImage;
@property (weak, nonatomic) IBOutlet UIView* controlsViewBottom;
@property (weak, nonatomic) IBOutlet UIView* controlsViewTop;
@property (weak, nonatomic) IBOutlet UILabel* timerLabel;
@property CaptureManager* manager;
@property FusionPlugin* plugin;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) captureToggle:(id)sender forEvent:(UIEvent*)event;
-(void) retakeVideo:(UIViewController*)child forMovie:(NSURL*)movieUrl;
-(void) recordingTimerFired:(NSTimer*)timer;

@end