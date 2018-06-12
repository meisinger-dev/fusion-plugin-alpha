
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class FusionPlugin;
@interface ControllerCaptureReview : UIViewController <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate> {
  id seekbarObserver;
}

@property (weak, nonatomic) IBOutlet UIView* playerView;
@property (weak, nonatomic) IBOutlet UIView* captureInfoView;
@property (weak, nonatomic) IBOutlet UIView* saveInfoView;
@property (weak, nonatomic) IBOutlet UISlider* slider;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (weak, nonatomic) IBOutlet UIButton* takeButton;
@property (weak, nonatomic) IBOutlet UIButton* saveButton;
@property (weak, nonatomic) IBOutlet UIButton* retakeButton;
@property (weak, nonatomic) IBOutlet UIButton* playbackButton;
@property AVPlayerViewController* moviePlayer;
@property FusionPlugin* plugin;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) takePicture:(id)sender forEvent:(UIEvent*)event;
-(IBAction) saveVideo:(id)sender forEvent:(UIEvent*)event;
-(IBAction) retakeVideo:(id)sender forEvent:(UIEvent*)event;
-(IBAction) togglePlayback:(id)sender forEvent:(UIEvent*)event;
-(IBAction) seekbarAction:(UISlider*)sender forEvent:(UIEvent*)event;
-(IBAction) seekbarPause:(id)sender forEvent:(UIEvent*)event;
-(void) retakePicture:(UIViewController*)child;

@end