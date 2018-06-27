
#import <AVFoundation/AVFoundation.h>

@interface FusionExercise : NSObject {}

@property (nullable) NSNumber* testId;
@property (nullable) NSNumber* testTypeId;
@property (nullable) NSString* uniqueId;
@property (nullable) NSString* version;
@property (nullable) NSNumber* viewId;
@property (nullable) NSNumber* exerciseId;
@property (nullable) NSNumber* bodySideId;
@property (nullable) NSString* name;
@property (nullable) NSString* filePrefix;
@property (nullable) NSURL* videoUrl;

-(nonnull id)initWithData:(NSDictionary*_Nullable)data;

@end
