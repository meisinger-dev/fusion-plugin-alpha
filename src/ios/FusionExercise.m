
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "FusionExercise.h"

@implementation FusionExercise

-(id) initWithData:(NSString *)name_ {
  self = [super init];
  if (self) {
    self.name = name_;
  }
  
  return self;
}