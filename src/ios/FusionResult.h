
#import <AVFoundation/AVFoundation.h>

@interface FusionResult : NSObject {}

@property (assign) BOOL cancelled;
@property (assign) BOOL capturedImage;
@property (assign) BOOL capturedVideo;
@property (nullable) NSURL* videoUrl;
@property (nullable) NSString* videoImage;
@property (nullable) NSNumber* videoTimestamp;

-(nullable NSString*) toJSON:(NSError * _Nonnull * _Nonnull)error;
-(nullable NSDictionary*) toDictionary;

@end