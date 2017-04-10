
#import <AVFoundation/AVFoundation.h>

@interface FusionResult : NSObject {}

@property (assign) BOOL cancelled;
@property (assign) BOOL capturedImage;
@property (assign) BOOL capturedVideo;
@property (assign, nullable) NSURL* videoUrl;
@property (assign, nullable) NSString* videoImage;
@property (assign, nullable) NSNumber* videoTimestamp;

-(nullable NSString*) toJSON:(NSError * _Nonnull * _Nonnull)error;
-(nullable NSDictionary*) toDictionary;

@end