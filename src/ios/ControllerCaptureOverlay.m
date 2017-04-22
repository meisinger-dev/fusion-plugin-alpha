
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FusionPlugin.h"
#import "CaptureFocus.h"
#import "CaptureManager.h"
#import "ControllerCaptureOverlay.h"

@implementation ControllerCaptureOverlay {
    CaptureFocus* focusSquare;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.manager = [[CaptureManager alloc] initWithDelegate:self];
    [self.manager addInput];
    [self.manager addPreviewLayer];
  }
  return self;
}

-(IBAction) cancel:(id)sender forEvent:(UIEvent *)event {
  [self.plugin cancelled];
}

-(IBAction) captureToggle:(id)sender forEvent:(UIEvent *)event {
  if ([self.captureButton isSelected]) {
    [[self captureButton] setUserInteractionEnabled:NO];
    [self.manager captureStop];
    AudioServicesPlaySystemSound(1114);
  } else {
    [self.overlayImage setHidden:YES];
    [self.manager captureStart];
    AudioServicesPlaySystemSound(1113);
  }
  
  [self.cancelButton setHidden:![self.captureButton isSelected]];
  [self.captureButton setSelected:![self.captureButton isSelected]];
}

-(IBAction) focusTap:(UITapGestureRecognizer *)gesture {
  CGPoint point = [gesture locationOfTouch:0 inView:self.view];
  [self.manager focus:point];
}

-(void) retakeVideo:(UIViewController *)child forMovie:(NSURL*)movieUrl {
  CGFloat point = CGRectGetWidth(child.view.frame);
  CGRect frame = child.view.bounds;
  frame.origin.x += point;
  frame.size.width = child.view.frame.size.width;
  frame.size.height = child.view.frame.size.height;
  
  [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{child.view.frame = frame;} completion:^(BOOL finished){
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[movieUrl path]]) {
      NSError* error;
      if ([fileManager removeItemAtPath:[movieUrl path] error:&error] != YES) {
        NSLog(@"Unable to delete file: %@", [error localizedDescription]);
        // add alert with proper message
      }
    }
    
    [child willMoveToParentViewController:nil];
    [child.view removeFromSuperview];
    [child removeFromParentViewController];
    [[self captureButton] setUserInteractionEnabled:YES];
    [[self overlayImage] setHidden:NO];
  }];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if ([keyPath isEqualToString:@"adjustingFocus"]) {
    BOOL adjusting = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
    if (adjusting) {
      CGPoint focusPoint = [[self.manager device] focusPointOfInterest];
      CGPoint screenPoint = [[self.manager preview] pointForCaptureDevicePointOfInterest:focusPoint];
      [self captureFocus:screenPoint];
    }
  }
}

-(void) captureOutput:(NSURL *)outputFileURL error:(NSError *)error {
  if (error.code != noErr) {
    NSLog(@"Errors -> %@", [error localizedDescription]);
    // add alert with proper message
    return;
  }

  [[self captureButton] setUserInteractionEnabled:NO];
  [self viewPlayer:outputFileURL];
}

-(void) captureFocus:(CGPoint)point {
  if (!focusSquare) {
    focusSquare = [[CaptureFocus alloc] initWithTouchPoint:point];
    [self.view addSubview:focusSquare];
    [focusSquare setNeedsDisplay];
    [focusSquare animate];
    return;
  }
  
  if ([focusSquare updateTouchPoint:point]) {
    [focusSquare animate];
    return;
  }
  
  if ([[self.manager device] focusMode] == AVCaptureFocusModeContinuousAutoFocus) {
    [focusSquare animate];
  }
}

-(void) viewPlayer:(NSURL *)outputFileUrl {
  ControllerCaptureReview* player = [[ControllerCaptureReview alloc] initWithNibName:@"ControllerCaptureReview" bundle:nil];
  player.plugin = self.plugin;
  player.movieUrl = outputFileUrl;
  
  [self addChildViewController:player];
  [self.view addSubview:player.view];
  [player didMoveToParentViewController:self];
  
  CGFloat point = CGRectGetWidth(self.view.frame);
  CGRect frame = self.view.bounds;
  frame.origin.x += point;
  frame.size.width = self.view.frame.size.width;
  frame.size.height = self.view.frame.size.height;
  
  player.view.frame = frame;
  [UIView animateWithDuration:0.25f animations:^{player.view.frame = self.view.bounds;}];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  
  CGRect screenFrame = [[UIScreen mainScreen] bounds];
  self.view.frame = screenFrame;
  [[self.manager preview] setBounds:screenFrame];
  [[self.manager session] startRunning];
  [[self.manager device] addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
    
  SEL selector = NSSelectorFromString(@"setNeedsStatusBarAppearanceUpdate");
  if ([self respondsToSelector:selector]) {
    [self performSelector:selector withObject:nil afterDelay:0];
  }
    
  dispatch_async(dispatch_get_main_queue(), ^{
    CGRect layer = [[self.view layer] bounds];
    [[self.manager preview] setBounds:layer];
    [[self.manager preview] setPosition:CGPointMake(CGRectGetMidX(layer), CGRectGetMidY(layer))];
    
    UIView* cameraView = [[UIView alloc] init];
    [self.view addSubview:cameraView];
    [self.view sendSubviewToBack:cameraView];
    [[cameraView layer] addSublayer:self.manager.preview];
    
    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
  });
}

-(void) viewWillDisappear:(BOOL)animated {
  [[self.manager device] removeObserver:self forKeyPath:@"adjustingFocus"];
  [self.manager tearDown];

  [super viewWillDisappear:animated];
}

-(void) didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

-(BOOL) prefersStatusBarHidden {
  return YES;
}

-(UIViewController *) childViewControllerForStatusBarHidden {
  return nil;
}

@end