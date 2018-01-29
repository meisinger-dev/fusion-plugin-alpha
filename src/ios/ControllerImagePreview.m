
#import "FusionResult.h"
#import "FusionPlugin.h"
#import "ControllerImagePreview.h"

@implementation ControllerImagePreview {
  UIAlertController* alertController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

-(IBAction) retakePicture:(id)sender forEvent:(UIEvent *)event {
  ControllerCaptureReview* parent = (ControllerCaptureReview *)self.parentViewController;
  [parent retakePicture:self];
}

-(IBAction) savePicture:(id)sender forEvent:(UIEvent *)event {
  NSData* imageData = UIImageJPEGRepresentation(self.movieImage, 1.f);
  
  FusionResult* result = [[FusionResult alloc] init];
  [result setCapturedImage:YES];
  [result setCapturedVideo:YES];
  [result setVideoUrl:self.movieUrl];
  [result setVideoTimestamp:self.movieTime];
  [result setVideoImage:[imageData base64EncodedStringWithOptions:kNilOptions]];
  
  [self.plugin captured:result];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  [[self.infoView layer] setCornerRadius:8];
  
  movieImageView = [[UIImageView alloc] initWithImage:self.movieImage];
  movieImageView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];

  [[self.backButton layer] setCornerRadius:8];
  [[self.nextButton layer] setCornerRadius:8];

  [self.backButton setClipsToBounds:YES];
  [self.nextButton setClipsToBounds:YES];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.imageView addSubview:movieImageView];
  });
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  
  [movieImageView layoutIfNeeded];
  movieImageView.frame = self.imageView.bounds;
}

-(void) viewWillDisappear:(BOOL)animated {
  alertController = nil;
  
  [super viewWillDisappear:animated];
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

@end