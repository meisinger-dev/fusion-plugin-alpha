
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

@property (strong, nonatomic) AVAssetWriter* writer;
@property (strong, nonatomic) AVAssetWriterInput* input;
@property (strong, nonatomic) AVCaptureDevice* device;
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* preview;
@property (strong, nonatomic) id<CaptureOutputDelegate> delegate;

-(id) initWithDelegate:(id<CaptureOutputDelegate>) delegate;
-(void) addInput;
-(void) addPreviewLayer;
-(void) captureStart;
-(void) captureStop;
-(void) focus:(CGPoint)point;
-(void) tearDown;

@end
