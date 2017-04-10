
#import "FusionResult.h"
#import "FusionPlugin.h"

@implementation FusionPlugin
@synthesize hasPendingOperation;

-(void) takeVideo:(CDVInvokedUrlCommand *)command {
  hasPendingOperation = YES;
  self.command = command;

  //NSBundle* bundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"bundle"]];
  self.overlay = [[ControllerCaptureOverlay alloc] initWithNibName:@"ControllerCaptureOverlay" bundle:nil];
  self.overlay.plugin = self;

  [self.viewController presentViewController:self.overlay animated:YES completion:nil];
}

-(void) playVideo:(CDVInvokedUrlCommand *)command {
  hasPendingOperation = YES;
  self.command = command;

  //NSBundle* bundle = [NSBundle bundleWithPath: [[NSBundle mainBundle] pathForResource:NSStringFromClass([self class]) ofType:@"bundle"]];
  self.preview = [[ControllerCaptureReview alloc] initWithNibName:@"ControllerCaptureReview" bundle:nil];
  self.preview.plugin = self;
  self.preview.movieUrl = [command.arguments objectAtIndex:0];

  [self.viewController presentViewController:self.preview animated:YES completion:nil];
}

-(void) cancelled {
  FusionResult* result = [[FusionResult alloc] init];
  [result setCancelled:YES];

  [self captured:result];
}

-(void) captured:(FusionResult *)result {
  NSError* error;
  NSString* message = [result toJSON:&error];

  if (error.code != noErr) {
    [self.commandDelegate sendPluginResult:[CDVPluginResult 
      resultWithStatus:CDVCommandStatus_ERROR
      messageAsString:[error localizedDescription]] callbackId:self.command.callbackId];
  } else {
    [self.commandDelegate sendPluginResult:[CDVPluginResult
      resultWithStatus:CDVCommandStatus_OK
      messageAsString:message] callbackId:self.command.callbackId];
  }

  hasPendingOperation = NO;
  [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end