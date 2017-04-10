
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@interface CaptureManager : NSObject {
  AVCaptureMovieFileOutput* movieOutput;
}

@property (strong, nonatomic) AVCaptureDevice* device;
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* preview;
@property (strong, nonatomic) id<AVCaptureFileOutputRecordingDelegate> delegate;

-(id) initWithDelegate:(id<AVCaptureFileOutputRecordingDelegate>) delegate;
-(void) addInput;
-(void) addPreviewLayer;
-(void) captureStart;
-(void) captureStop;
-(void) focus:(CGPoint)point;
-(void) tearDown;

@end