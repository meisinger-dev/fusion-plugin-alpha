
#import <Cordova/CDV.h>
#import "FusionExercise.h"
#import "FusionResult.h"
#import "ControllerCaptureOverlay.h"
#import "ControllerCaptureReview.h"

@interface FusionPlugin : CDVPlugin {
  BOOL hasPendingOperation;
}

@property (nonatomic) CDVInvokedUrlCommand* command;
@property FusionExercise* exercise;
@property NSURL* currentVideoUrl;
@property NSURL* uploadEndpointUrl;
@property NSString* apiAuthorize;
@property NSString* apiVersion;
@property BOOL markersEnabled;

-(void) takeVideo:(CDVInvokedUrlCommand*)command;
-(void) playVideo:(CDVInvokedUrlCommand*)command;
-(void) cancelled;
-(void) failed:(NSString*)message;
-(void) captured:(FusionResult*)result;

@end