
#import <AVFoundation/AVFoundation.h>

@interface FusionExercise : NSObject {}

@property (assign, nullable) NSString* name;
@property (assign, nullable) NSString* instructions;
@property (assign, nullable) NSURL* instructionsUrl;
@property (assign, nullable) NSURL* videoUrl;

-(id)initWithData:(NSString*)name_;

@end
