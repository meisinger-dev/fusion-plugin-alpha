
#import <Cordova/CDV.h>
#import "FusionResult.h"
#import "ControllerCaptureOverlay.h"
#import "ControllerCaptureReview.h"

@interface FusionPlugin : CDVPlugin {
  BOOL hasPendingOperation;
}

@property (strong, nonatomic) ControllerCaptureOverlay* overlay;
@property (strong, nonatomic) ControllerCaptureReview* preview;
@property (strong, nonatomic) CDVInvokedUrlCommand* command;

-(void) takeVideo:(CDVInvokedUrlCommand*)command;
-(void) playVideo:(CDVInvokedUrlCommand*)command;
-(void) cancelled;
-(void) failed:(NSString*)message;
-(void) captured:(FusionResult*)result;

@end