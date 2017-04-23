
#import "CaptureFocus.h"
#import "CaptureManager.h"

@implementation CaptureManager
@synthesize writer;
@synthesize input;
@synthesize device;
@synthesize session;
@synthesize preview;

-(id) initWithDelegate:(id<CaptureOutputDelegate>)delegate{
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
    
  [self.session setSessionPreset:AVCaptureSessionPresetMedium];
  if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720])
    [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
  
  queue = dispatch_queue_create("fusion-plugin-recording", DISPATCH_QUEUE_SERIAL);

  videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [videoOutput setSampleBufferDelegate:self queue:queue];

  if ([self.session canAddOutput:videoOutput])
    [self.session addOutput:videoOutput];

  for (AVCaptureConnection* connection in [videoOutput connections]) {
    for (AVCaptureInputPort* port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo])
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
  }
}

-(void) addPreviewLayer {
  [self setPreview:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]]];
  [self.preview setVideoGravity:AVLayerVideoGravityResizeAspectFill];
}

-(void) captureStart {
  NSString* outputPath = [[NSString alloc] initWithFormat:@"%@%@%@", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString], @".mp4"];
  outputUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
  
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:outputPath]) {
    NSError* error;
    if ([fileManager removeItemAtPath:outputPath error:&error] != YES) {
      NSLog(@"Unable to delete file: %@", [error localizedDescription]);
      // add alert with proper message
    }
  }

  NSDictionary* settings = @{
    AVVideoCodecKey : AVVideoCodecH264,
    AVVideoHeightKey : @960,
    AVVideoWidthKey : @540,
    AVVideoCompressionPropertiesKey : @{
      AVVideoAverageBitRateKey : @3400000,
      AVVideoMaxKeyFrameIntervalKey : @24,
      AVVideoProfileLevelKey : AVVideoProfileLevelH264Main31
    }
  };

  self.input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
  [self.input setExpectsMediaDataInRealTime:YES];

  NSError* error;
  self.writer = [AVAssetWriter assetWriterWithURL:outputUrl fileType:AVFileTypeMPEG4 error:&error];
  if (error.code != noErr) {
    NSLog(@"Unable to create asset writer");
    // add alert with proper message
    return;
  }

  if ([self.writer canAddInput:self.input])
    [self.writer addInput:self.input];
  else {
    NSLog(@"Unable to add input to asset writer");
    // add alert with proper message
  }
}

-(void) captureStop {
  dispatch_async(queue, ^{
    [self.input markAsFinished];
    [self.writer finishWritingWithCompletionHandler:^{
      if ([self.writer status] == AVAssetWriterStatusFailed) {
        [self.delegate captureOutput:outputUrl error:[self.writer error]];
      }

      if ([self.writer status] == AVAssetWriterStatusCompleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate captureOutput:outputUrl error:nil];
        });
      }
    }];
  });
}

-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  CFRetain(sampleBuffer);
  dispatch_async(queue, ^{
    if (self.writer) {
      if (captureOutput == videoOutput) {
        [self captureFromBuffer:sampleBuffer];
      }
    }
    CFRelease(sampleBuffer);
  });
}

-(void) captureFromBuffer:(CMSampleBufferRef)sampleBuffer {
  CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

  if ([self.writer status] == AVAssetWriterStatusUnknown) {
    if ([self.writer startWriting])
      [self.writer startSessionAtSourceTime:timestamp];
  }

  if ([self.writer status] == AVAssetWriterStatusWriting) {
    if ([self.input isReadyForMoreMediaData]) {
      if (![self.input appendSampleBuffer:sampleBuffer])
        NSLog(@"Unable to append sample buffer to input");
    }
  }

  if ([self.writer status] == AVAssetWriterStatusFailed)
    NSLog(@"Asset writer failed");
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
  [self.writer cancelWriting];
  
  if ([self.session isRunning])
    [self.session stopRunning];
  
  input = nil;
  writer = nil;
  preview = nil;
  session = nil;
  videoOutput = nil;
}

@end
