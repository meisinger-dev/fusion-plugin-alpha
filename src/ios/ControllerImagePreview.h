
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class FusionPlugin;
@interface ControllerImagePreview : UIViewController {
  UIImageView* movieImageView;
}

@property (weak, nonatomic) IBOutlet UIView* imageView;
@property (weak, nonatomic) IBOutlet UIView* infoView;
@property (weak, nonatomic) IBOutlet UIButton* nextButton;
@property (weak, nonatomic) IBOutlet UIButton* backButton;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (strong, nonatomic) UIImage* movieImage;
@property (strong, nonatomic) NSNumber* movieTime;
@property (atomic) FusionPlugin* plugin;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) retakePicture:(id)sender forEvent:(UIEvent*)event;
-(IBAction) savePicture:(id)sender forEvent:(UIEvent*)event;

@end