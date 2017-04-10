
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class FusionPlugin;
@interface ControllerImagePreview : UIViewController {
    UIImageView* movieImageView;
}

@property (weak, nonatomic) IBOutlet UIView* imageView;
@property (weak, nonatomic) IBOutlet UIButton* saveButton;
@property (weak, nonatomic) IBOutlet UIButton* cancelButton;
@property (strong, nonatomic) NSURL* movieUrl;
@property (strong, nonatomic) UIImage* movieImage;
@property (strong, nonatomic) NSNumber* movieTime;
@property (strong, nonatomic) FusionPlugin* plugin;

-(IBAction) cancel:(id)sender forEvent:(UIEvent*)event;
-(IBAction) savePicture:(id)sender forEvent:(UIEvent*)event;

@end