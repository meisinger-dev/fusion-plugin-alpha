
#import "CaptureFocus.h"
#import "CaptureManager.h"

@implementation CaptureManager {
  BOOL isActivelyRecording;
}

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

-(void) captureSetup:(NSError **)setupError {
  queue = dispatch_queue_create("fusion-plugin-recording", DISPATCH_QUEUE_SERIAL);

  [self initializeDevice:setupError];
  if ((*setupError != nil))
    return;

  [self initializeVideoOutput];
  [self setPreview:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self session]]];
  [self.preview setVideoGravity:AVLayerVideoGravityResizeAspect];
}

-(void) captureStart:(NSError **)startError {
  NSString* outputPath = [[NSString alloc] initWithFormat:@"%@%@%@", NSTemporaryDirectory(), [[NSUUID UUID] UUIDString], @".mp4"];
  outputUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
  
  NSDictionary* settings = @{
    AVVideoCodecKey : AVVideoCodecH264,
    AVVideoHeightKey : @960,
    AVVideoWidthKey : @540,
    AVVideoCompressionPropertiesKey : @{
      AVVideoAverageBitRateKey : @2600000,
      AVVideoMaxKeyFrameIntervalKey : @24,
      AVVideoProfileLevelKey : AVVideoProfileLevelH264Main31
    }
  };

  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:outputPath]) {
    NSError* error;
    if ([fileManager removeItemAtPath:outputPath error:&error] != YES) {
      if (startError) {
        *startError = [NSError errorWithDomain:@"com.fusion.recording" code:20 userInfo:[NSDictionary dictionaryWithObject:@"Unable to remove a previously discarded movie from this device." forKey:NSLocalizedDescriptionKey]];
      }
      return;
    }
  }

  NSError* error;
  self.writer = [AVAssetWriter assetWriterWithURL:outputUrl fileType:AVFileTypeMPEG4 error:&error];

  if (error.code != noErr) {
    if (startError) {
      *startError = [NSError errorWithDomain:@"com.fusion.recording" code:21 userInfo:[NSDictionary dictionaryWithObject:@"Unable to record a movie in the required MPEG4 format." forKey:NSLocalizedDescriptionKey]];
    }
    return;
  }

  self.input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
  [self.input setExpectsMediaDataInRealTime:YES];

  if ([self.writer canAddInput:self.input]) {
    [self.writer addInput:self.input];
    isActivelyRecording = YES;
  } else if (startError) {
    *startError = [NSError errorWithDomain:@"com.fusion.recording" code:22 userInfo:[NSDictionary dictionaryWithObject:@"Unable to configure this device with the required recording format." forKey:NSLocalizedDescriptionKey]];
  }
}

-(void) captureStop {
  isActivelyRecording = NO;

  dispatch_async(queue, ^{
    if ([self.writer status] == AVAssetWriterStatusUnknown) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate captureOutput:outputUrl error:[NSError errorWithDomain:@"com.fusion.recording" code:31 userInfo:[NSDictionary dictionaryWithObject:@"Lucy? Is that you?" forKey:NSLocalizedDescriptionKey]]];
      });

      return;
    }

    [self.input markAsFinished];
    [self.writer finishWritingWithCompletionHandler:^{
      if ([self.writer status] == AVAssetWriterStatusFailed) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate captureOutput:outputUrl error:[NSError errorWithDomain:@"com.fusion.recording" code:32 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unable to record movie. Description: %@", [[self.writer error] localizedDescription]] forKey:NSLocalizedDescriptionKey]]];
        });
      }

      if ([self.writer status] == AVAssetWriterStatusCompleted) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self.delegate captureOutput:outputUrl error:nil];
        });
      }
    }];
  });
}

-(void) captureTearDown {
  [self.writer cancelWriting];
  
  if ([self.session isRunning])
    [self.session stopRunning];
  
  input = nil;
  writer = nil;
  preview = nil;
  session = nil;
  videoOutput = nil;
}

-(void) focus:(CGPoint)point {
  if (![self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] || ![self.device isFocusPointOfInterestSupported])
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

-(void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
  if (!isActivelyRecording)
    return;

  CFRetain(sampleBuffer);
  dispatch_async(queue, ^{
    if (self.writer && captureOutput == videoOutput)
      [self captureFromBuffer:sampleBuffer ofType:AVMediaTypeVideo];

    CFRelease(sampleBuffer);
  });
}

-(void) captureFromBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType {
  if (!CMSampleBufferDataIsReady(sampleBuffer))
    return;

  if ([self.writer status] == AVAssetWriterStatusUnknown) {
    CMTime timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if ([self.writer startWriting])
      [self.writer startSessionAtSourceTime:timestamp];
  }

  if ([self.writer status] == AVAssetWriterStatusWriting && mediaType == AVMediaTypeVideo) {
    if ([self.input isReadyForMoreMediaData])
      [self.input appendSampleBuffer:sampleBuffer];
  }

  if ([self.writer status] == AVAssetWriterStatusFailed)
    isActivelyRecording = NO;
}

-(void) initializeDevice:(NSError**)error {
  self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

  if (self.device) {
    NSError* sourceError;
    AVCaptureDeviceInput* source = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&sourceError];

    if ((sourceError.code == noErr)) {
      if ([self.session canAddInput:source]) {
        [self.session addInput:source];
        [self.session setSessionPreset:AVCaptureSessionPresetMedium];

        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720])
          [self.session setSessionPreset:AVCaptureSessionPreset1280x720];

      } else if (error) {
        *error = [NSError errorWithDomain:@"com.fusion.recording" code:10 userInfo:[NSDictionary dictionaryWithObject:@"Unable to configure this device to record a movie." forKey:NSLocalizedDescriptionKey]];
      }
    } else if (error) {
      *error = [NSError errorWithDomain:@"com.fusion.recording" code:11 userInfo:[NSDictionary dictionaryWithObject:@"Unable to find a input capable of recording a movie." forKey:NSLocalizedDescriptionKey]];
    }
  } else if (error) {
    *error = [NSError errorWithDomain:@"com.fusion.recording" code:12 userInfo:[NSDictionary dictionaryWithObject:@"Unable to find a device capable of recording a movie." forKey:NSLocalizedDescriptionKey]];
  }
}

-(void) initializeVideoOutput {
  videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [videoOutput setSampleBufferDelegate:self queue:queue];
  
  if ([self.session canAddOutput:videoOutput]) {
    [self.session addOutput:videoOutput];
  }
  
  for (AVCaptureConnection* connection in [videoOutput connections]) {
    for (AVCaptureInputPort* port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo])
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    };
  }
}

@end