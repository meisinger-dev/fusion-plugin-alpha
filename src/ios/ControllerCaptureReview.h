
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class FusionPlugin;
@interface ControllerCaptureReview : UIViewController {
  id seekbarObserver;
}

@property (weak, nonatomic) IBOutlet UIView* playerView;
@property (weak, nonatomic) IBOutlet UIView* infoView;
@property (weak, nonatomic) IBOutlet UISlider* slider;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet UIButton* takeButton;
@property (weak, nonatomic) IBOutlet UIButton* retakeButton;
@property (weak, nonatomic) IBOutlet UIButton* playbackButton;
@property (strong, nonatomic) AVPlayerViewController* moviePlayer;
@property (strong, nonatomic) NSURL* movieUrl;
@property (strong, nonatomic) FusionPlugin* plugin;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) takePicture:(id)sender forEvent:(UIEvent*)event;
-(IBAction) retakeVideo:(id)sender forEvent:(UIEvent*)event;
-(IBAction) togglePlayback:(id)sender forEvent:(UIEvent*)event;
-(IBAction) seekbarAction:(UISlider*)sender forEvent:(UIEvent*)event;
-(IBAction) seekbarPause:(id)sender forEvent:(UIEvent*)event;
-(void) retakePicture:(UIViewController*)child;

@end