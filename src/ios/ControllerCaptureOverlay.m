
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FusionPlugin.h"
#import "CaptureFocus.h"
#import "CaptureManager.h"
#import "ControllerCaptureOverlay.h"

@implementation ControllerCaptureOverlay {
    CaptureFocus* focusSquare;
    NSTimer* recordingTimer;
    UIAlertController* alertController;
    UITapGestureRecognizer* tapRecognizer;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.manager = [[CaptureManager alloc] initWithDelegate:self];
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

    if ([recordingTimer isValid])
      [recordingTimer invalidate];
    recordingTimer = nil;

    AudioServicesPlaySystemSound(1114);
  } else {
    [self.overlayImage setHidden:YES];

    NSError* error;
    [self.manager captureStart:&error];

    if (error.code != noErr) {
      alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Video" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self.plugin failed:[error localizedDescription]];
      }]];

      [self presentViewController:alertController animated:YES completion:nil];
      return;
    }

    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0f target:self selector:@selector(recordingTimerFired:) userInfo:nil repeats:NO];
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
        alertController = [UIAlertController alertControllerWithTitle:@"Unable to Delete Video" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
          [self.plugin failed:[error localizedDescription]];
        }]];

        [self presentViewController:alertController animated:YES completion:nil];
        return;
      }
    }
    
    [child willMoveToParentViewController:nil];
    [child.view removeFromSuperview];
    [child removeFromParentViewController];

    [[self captureButton] setUserInteractionEnabled:YES];
    [[self overlayImage] setHidden:NO];

    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
  }];
}

-(void) recordingTimerFired:(NSTimer *)timer {
  [[self captureButton] setUserInteractionEnabled:NO];
  [self.manager captureStop];

  if ([recordingTimer isValid])
    [recordingTimer invalidate];
  recordingTimer = nil;

  AudioServicesPlaySystemSound(1114);

  [self.cancelButton setHidden:YES];
  [self.captureButton setSelected:NO];
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
    alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Video" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
      [self.plugin failed:[error localizedDescription]];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
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
  
  [self.view removeGestureRecognizer:tapRecognizer];
  tapRecognizer = nil;

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

  NSError* error;
  [self.manager captureSetup:&error];

  if (error.code != noErr) {
    alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Video" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
      [self.plugin failed:[error localizedDescription]];
    }]];
    return;
  }
  
  CGRect screenFrame = [[UIScreen mainScreen] bounds];
  self.view.frame = screenFrame;

  [[self.manager preview] setBounds:screenFrame];
  [[self.manager session] startRunning];
  [[self.manager device] addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
  
  if (alertController) {
    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }

  SEL selector = NSSelectorFromString(@"setNeedsStatusBarAppearanceUpdate");
  if ([self respondsToSelector:selector]) {
    [self performSelector:selector withObject:nil afterDelay:0];
  }
    
  dispatch_async(dispatch_get_main_queue(), ^{
    CGSize screen = [[UIScreen mainScreen] bounds].size;

    float containerHeight = 0;
    UIView* container = self.captureButton.superview;
    if (container) {
      CGSize containerSize = [[container layer] bounds].size;
      containerHeight = containerSize.height * 1.0f;
    }

    CGRect layer = CGRectMake(0, 0, screen.width, (screen.height - containerHeight));
    [[self.manager preview] setBounds:layer];
    [[self.manager preview] setPosition:CGPointMake(CGRectGetMidX(layer), CGRectGetMidY(layer))];
    
    UIView* cameraView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screen.width, screen.height)];
    cameraView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:cameraView];
    [self.view sendSubviewToBack:cameraView];
    [[cameraView layer] addSublayer:self.manager.preview];
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
  });
}

-(void) viewWillDisappear:(BOOL)animated {
  [[self.manager device] removeObserver:self forKeyPath:@"adjustingFocus"];
  [self.manager captureTearDown];
  alertController = nil;

  [self.view removeGestureRecognizer:tapRecognizer];
  tapRecognizer = nil;

  [super viewWillDisappear:animated];
}

-(void) didReceiveMemoryWarning {
  alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Video" message:@"In appears you are running low on memory. Try closing a few applications. Make sure you have enough space to record a movie or video." preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    [self.plugin failed:@"Low memory warning"];
  }]];

  [self presentViewController:alertController animated:YES completion:nil];
  [super didReceiveMemoryWarning];
}

-(BOOL) prefersStatusBarHidden {
  return YES;
}

-(BOOL) shouldAutorotate {
  return NO;
}

-(UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationPortrait;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait;
}

-(UIViewController *) childViewControllerForStatusBarHidden {
  return nil;
}

@end