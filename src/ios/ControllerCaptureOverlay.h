
#import <UIKit/UIKit.h>
#import "CaptureManager.h"

@class FusionPlugin;
@interface ControllerCaptureOverlay : UIViewController <UINavigationControllerDelegate, CaptureOutputDelegate> {}

@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet UIButton* captureButton;
@property (weak, nonatomic) IBOutlet UIImageView* overlayImage;
@property (strong, nonatomic) FusionPlugin* plugin;
@property (strong, nonatomic) CaptureManager* manager;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) captureToggle:(id)sender forEvent:(UIEvent*)event;
-(void) retakeVideo:(UIViewController*)child forMovie:(NSURL*)movieUrl;

@end
