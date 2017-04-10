
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "FusionResult.h"

@implementation FusionResult
@synthesize videoUrl;
@synthesize videoImage;
@synthesize videoTimestamp;

-(id)init {
  if ((self = [super init])) {
    self.cancelled = NO;
    self.capturedImage = NO;
    self.capturedVideo = NO;
  }

  return self;
}

-(NSDictionary*)toDictionary {
  return @{
   @"cancelled": self.cancelled ? @YES : @NO,
   @"capturedVideo": self.capturedVideo ? @YES : @NO,
   @"capturedImage": self.capturedImage ? @YES : @NO,
   @"videoUrl": self.videoUrl ? [self.videoUrl path]: [NSNull null],
   @"videoImage": self.videoImage ?: [NSNull null],
   @"videoTimestamp": self.videoTimestamp ?: [NSNull null],
  };
}

-(NSString*)toJSON:(NSError**)error {
  NSDictionary* dictionary = [self toDictionary];
  NSData* json = [NSJSONSerialization dataWithJSONObject:dictionary options:kNilOptions error:error];
  if (!json) {
    return nil;
  }
  
  return [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
}

@end
