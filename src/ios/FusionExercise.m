
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "FusionExercise.h"

@implementation FusionExercise

-(id)initWithData:(NSDictionary *)data {
  self = [super init];
  if (self) {
    self.testId = data[@"testId"] ? data[@"testId"] : [NSNull null];
    self.testTypeId = data[@"testTypeId"] ? data[@"testTypeId"] : [NSNull null];
    self.uniqueId = data[@"uniqueId"] ? data[@"uniqueId"] : [NSNull null];
    self.version = data[@"version"] ? data[@"version"] : [NSNull null];
    self.viewId = data[@"viewId"] ? data[@"viewId"] : [NSNull null];
    self.exerciseId = data[@"exerciseId"] ? data[@"exerciseId"] : [NSNull null];
    self.bodySideId = data[@"bodySideId"] ? data[@"bodySideId"] : [NSNull null];
    self.name = data[@"name"] ? data[@"name"] : [NSNull null];
    self.filePrefix = data[@"filePrefix"] ? data[@"filePrefix"] : [NSNull null];
    self.videoUrl = data[@"videoUrl"] ? data[@"videoUrl"] : [NSNull null];
  }
  
  return self;
}

@end
