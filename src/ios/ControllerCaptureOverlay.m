
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FusionPlugin.h"
#import "CaptureFocus.h"
#import "CaptureManager.h"
#import "ControllerCaptureOverlay.h"

@implementation ControllerCaptureOverlay {
    CaptureFocus* focusSquare;
    NSDate* recordingDate;
    NSTimer* recordingTimer;
    UIAlertController* alertController;
    UITapGestureRecognizer* tapRecognizer;
    UIView* grid;
    BOOL usingFocus;
    BOOL showingGrid;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.manager = [[CaptureManager alloc] initWithDelegate:self];
  }
  return self;
}

-(IBAction) cancel:(id)sender forEvent:(UIEvent *)event {
  alertController = [UIAlertController alertControllerWithTitle:@"Warning" message:@"You are about to leave this section of the test and will lose any data." preferredStyle:UIAlertControllerStyleAlert];
  [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    [self.plugin cancelled];
  }]];
  [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
  
  [self presentViewController:alertController animated:YES completion:nil];
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
    if (showingGrid) {
      [grid removeFromSuperview];
      showingGrid = NO;
    }

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

    recordingDate = [NSDate date];
    recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(recordingTimerFired:) userInfo:nil repeats:YES];
    AudioServicesPlaySystemSound(1113);
  }
  
  [self.cancelButton setHidden:![self.captureButton isSelected]];
  [self.captureButton setSelected:![self.captureButton isSelected]];
}

-(IBAction) focusTap:(UITapGestureRecognizer *)gesture {
  CGPoint point = [gesture locationOfTouch:0 inView:self.view];
  [self.manager focus:point];
}

-(IBAction) gridToggle:(id)sender forEvent:(UIEvent *)event {
  CGRect mainBounds = [[UIScreen mainScreen] bounds];
  CGSize mainSize = mainBounds.size;
  CGRect upperLocation = [self.controlsViewTop frame];
  CGRect lowerLocation = [self.controlsViewBottom frame];
  
  if (!grid) {
    CGRect gridFrame = CGRectMake(0, upperLocation.size.height, mainSize.width, (lowerLocation.origin.y - upperLocation.size.height));
    grid = [[UIView alloc] initWithFrame:gridFrame];
    
    CGSize gridSize = gridFrame.size;
    float gridWidth = gridSize.width;
    float gridHeight = gridSize.height;
    
    UIView* gridVert1 = [[UIView alloc] initWithFrame:CGRectMake((gridWidth * 0.25), 0, 2, gridHeight)];
    UIView* gridVert2 = [[UIView alloc] initWithFrame:CGRectMake((gridWidth * 0.75), 0, 2, gridHeight)];
    [gridVert1 setBackgroundColor:UIColorWithHexStringAndAlpha(@"#dfdfdf", 0.2)];
    [gridVert2 setBackgroundColor:UIColorWithHexStringAndAlpha(@"#dfdfdf", 0.2)];
    [grid addSubview:gridVert1];
    [grid addSubview:gridVert2];
    
    UIView* gridHorz1 = [[UIView alloc] initWithFrame:CGRectMake(0, (gridHeight * 0.25), gridWidth, 2)];
    UIView* gridHorz2 = [[UIView alloc] initWithFrame:CGRectMake(0, (gridHeight * 0.50), gridWidth, 2)];
    UIView* gridHorz3 = [[UIView alloc] initWithFrame:CGRectMake(0, (gridHeight * 0.75), gridWidth, 2)];
    [gridHorz1 setBackgroundColor:UIColorWithHexStringAndAlpha(@"#dfdfdf", 0.2)];
    [gridHorz2 setBackgroundColor:UIColorWithHexStringAndAlpha(@"#dfdfdf", 0.2)];
    [gridHorz3 setBackgroundColor:UIColorWithHexStringAndAlpha(@"#dfdfdf", 0.2)];
    [grid addSubview:gridHorz1];
    [grid addSubview:gridHorz2];
    [grid addSubview:gridHorz3];
    [self.view addSubview:grid];
  }
  
  if (!showingGrid) {
    [self.view addSubview:grid];
    showingGrid = YES;
  } else {
    [grid removeFromSuperview];
    showingGrid = NO;
  }
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
    [[self.manager device] addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:nil];
    usingFocus = YES;

    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusTap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapRecognizer];
  }];
}

-(void) recordingTimerFired:(NSTimer *)timer {
  NSDate* current = [NSDate date];
  NSTimeInterval interval = [current timeIntervalSinceDate:recordingDate];
  
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"ss.SSS"];
  [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
  
  NSDate* sinceEpoch = [NSDate dateWithTimeIntervalSince1970:interval];
  [self.timerLabel setText:[formatter stringFromDate:sinceEpoch]];
  
  if (interval > 20.0) {
    [[self captureButton] setUserInteractionEnabled:NO];
    [self.manager captureStop];

    if ([recordingTimer isValid])
      [recordingTimer invalidate];
    recordingTimer = nil;

    AudioServicesPlaySystemSound(1114);

    [self.cancelButton setHidden:YES];
    [self.captureButton setSelected:NO];
  }
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
  [self.plugin setCurrentVideoUrl:outputFileUrl];

  ControllerCaptureReview* player = [[ControllerCaptureReview alloc] initWithNibName:@"ControllerCaptureReview" bundle:nil];
  [player setPlugin:self.plugin];
  
  [[self.manager device] removeObserver:self forKeyPath:@"adjustingFocus"];
  [self.view removeGestureRecognizer:tapRecognizer];
  tapRecognizer = nil;
  usingFocus = NO;

  [self addChildViewController:player];
  [self.view addSubview:player.view];
  [player didMoveToParentViewController:self];
  
  CGFloat point = CGRectGetWidth(self.view.frame);
  CGRect frame = self.view.bounds;
  frame.origin.x += point;
  frame.size.width = self.view.frame.size.width;
  frame.size.height = self.view.frame.size.height;
  
  player.view.frame = frame;
  [UIView animateWithDuration:0.25f animations:^{
    player.view.frame = self.view.bounds;
    [player.takeButton setHidden:YES];
    [player.saveButton setHidden:NO];
    [player.retakeButton setHidden:NO];
  }];
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

    CGRect layer = CGRectMake(0, 45, screen.width, (screen.height - containerHeight - 45));
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
  if (usingFocus)
    [[self.manager device] removeObserver:self forKeyPath:@"adjustingFocus"];
  
  [self.manager captureTearDown];
  alertController = nil;

  [self.view removeGestureRecognizer:tapRecognizer];
  tapRecognizer = nil;

  [super viewWillDisappear:animated];
}

-(void) didReceiveMemoryWarning {
  alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Video" message:@"It appears you are running low on memory. Try closing a few applications. Make sure you have enough space to record a movie or video." preferredStyle:UIAlertControllerStyleAlert];
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

static UIColor* UIColorWithHexStringAndAlpha(NSString* hex, float alpha) {
  unsigned int rgb = 0;
  [[NSScanner scannerWithString:
    [[hex uppercaseString] stringByTrimmingCharactersInSet:
     [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"] invertedSet]]] scanHexInt:&rgb];
  return [UIColor colorWithRed:((CGFloat)((rgb & 0xFF0000) >> 16)) / 255.0
                         green:((CGFloat)((rgb & 0xFF00) >> 8)) / 255.0
                          blue:((CGFloat)(rgb & 0xFF)) / 255.0
                         alpha:alpha];
}

@end