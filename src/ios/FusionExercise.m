
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "FusionExercise.h"

@implementation FusionExercise

-(id)initWithData:(NSDictionary *)data {
  self = [super init];
  if (self) {
    self.testId = data[@"testId"];
    self.testTypeId = data[@"testTypeId"];
    self.uniqueId = data[@"uniqueId"];
    self.version = data[@"version"];
    self.viewId = data[@"viewId"];
    self.exerciseId = data[@"exerciseId"];
    self.bodySideId = data[@"bodySideId"];
    self.name = data[@"name"];
    self.filePrefix = data[@"filePrefix"];
  }
  
  return self;
}

@end
