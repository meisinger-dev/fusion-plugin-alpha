
#import "CaptureFocus.h"
#import "CaptureManager.h"

@implementation CaptureManager
@synthesize device;
@synthesize session;
@synthesize preview;

-(id) initWithDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate{
  if ((self = [super init])) {
    [self setSession:[[AVCaptureSession alloc] init]];
    [self setDelegate:delegate];
  }
  
  return self;
}

-(void) addInput {
  self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  if (self.device) {
    NSError* error;
    AVCaptureDeviceInput* source = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    if (!error) {
      if ([self.session canAddInput:source])
        [self.session addInput:source];
      else {
        NSLog(@"Unable to source video input");
        // add alert with proper message
      }
    } else {
      NSLog(@"Unable to create video input");
      // add alert with proper message
    }
  } else {
    NSLog(@"Unable to capture video device");
    // add alert with proper message
  }
    
  if ([self.device lockForConfiguration:nil]) {
    if ([self.device hasFlash] && [self.device isFlashModeSupported:AVCaptureFlashModeAuto]) {
      [self.device setFlashMode:AVCaptureFlashModeAuto];
    }
    if ([self.device hasTorch] && [self.device isTorchModeSupported:AVCaptureTorchModeAuto]) {
      [self.device setTorchMode:AVCaptureTorchModeAuto];
    }
    [self.device unlockForConfiguration];
  }
  
  [self.session setSessionPreset:AVCaptureSessionPresetMedium];
  // if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720])
  //   [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
  
  movieOutput = [[AVCaptureMovieFileOutput alloc] init];
  if ([self.session canAddOutput:movieOutput]) {
    [self.session addOutput:movieOutput];
  }
}

-(void) addPreviewLayer {
  [self setPreview:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]]];
  [self.preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

-(void) captureStart {
  if (!movieOutput) {
    movieOutput = [[AVCaptureMovieFileOutput alloc] init];
    if ([self.session canAddOutput:movieOutput]) {
      [self.session addOutput:movieOutput];
    }
  }
      
  NSString* outputPath = [[NSString alloc] initWithFormat:@"%@%@%@", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString], @".mov"];
  NSURL* outputUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
  
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:outputPath]) {
    NSError* error;
    if ([fileManager removeItemAtPath:outputPath error:&error] != YES) {
      NSLog(@"Unable to delete file: %@", [error localizedDescription]);
      // add alert with proper message
    }
  }

  [movieOutput startRecordingToOutputFileURL:outputUrl recordingDelegate:[self delegate]];
}

-(void) captureStop {
  if ([movieOutput isRecording])
    [movieOutput stopRecording];
}

-(void) focus:(CGPoint)point {
  if (![self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ||
    ![self.device isFocusPointOfInterestSupported])
    return;
  
  CGPoint focus = [self.preview captureDevicePointOfInterestForPoint:point];
  if ([self.device lockForConfiguration:nil]) {
    [self.device setFocusMode:AVCaptureFocusModeAutoFocus];
    [self.device setFocusPointOfInterest:CGPointMake(focus.x, focus.y)];
    if ([self.device isExposureModeSupported:AVCaptureExposureModeAutoExpose])
      [self.device setExposureMode:AVCaptureExposureModeAutoExpose];
    [self.device unlockForConfiguration];
  }
}

-(void) tearDown {
  if ([movieOutput isRecording])
    [movieOutput stopRecording];
  
  if ([self.session isRunning])
    [self.session stopRunning];
  
  preview = nil;
  session = nil;
  movieOutput = nil;
}

@end