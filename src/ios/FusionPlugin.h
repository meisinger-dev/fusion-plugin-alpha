
#import <Cordova/CDV.h>
#import "FusionExercise.h"
#import "FusionResult.h"
#import "ControllerCaptureOverlay.h"
#import "ControllerCaptureReview.h"

@interface FusionPlugin : CDVPlugin {
  BOOL hasPendingOperation;
}

@property (strong, nonatomic) CDVInvokedUrlCommand* command;
@property (strong, atomic) FusionExercise* exercise;
@property (strong, atomic) NSURL* currentVideoUrl;
@property (strong, atomic) NSURL* uploadEndpointUrl;
@property (strong, atomic) NSString* apiAuthorize;
@property (strong, atomic) NSString* apiVersion;

-(void) takeVideo:(CDVInvokedUrlCommand*)command;
-(void) playVideo:(CDVInvokedUrlCommand*)command;
-(void) cancelled;
-(void) failed:(NSString*)message;
-(void) captured:(FusionResult*)result;

@end