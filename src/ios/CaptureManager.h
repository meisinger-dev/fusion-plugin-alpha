
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@protocol CaptureOutputDelegate <NSObject>

-(void) captureOutput:(NSURL *)outputFileURL error:(NSError *)error;

@end

@interface CaptureManager : NSObject {
  dispatch_queue_t queue;

  NSURL* outputUrl;
  AVCaptureVideoDataOutput* videoOutput;
}

@property AVAssetWriter* writer;
@property AVAssetWriterInput* input;
@property AVCaptureDevice* device;
@property AVCaptureSession* session;
@property AVCaptureVideoPreviewLayer* preview;
@property id<CaptureOutputDelegate> delegate;

-(id) initWithDelegate:(id<CaptureOutputDelegate>) delegate;
-(void) captureSetup:(NSError **)setupError;
-(void) captureStart:(NSError **)startError;
-(void) captureStop;
-(void) captureTearDown;
-(void) focus:(CGPoint)point;

@end