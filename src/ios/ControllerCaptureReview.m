
#import "FusionPlugin.h"
#import "ControllerCaptureReview.h"
#import "ControllerImagePreview.h"

@implementation ControllerCaptureReview {
  UIAlertController* alertController;
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  return self;
}

-(void) initSeekbar {
  AVPlayer* player = self.moviePlayer.player;
  AVPlayerItem* playerItem = [player currentItem];
  CMTime duration = [playerItem.asset duration];
  if (CMTIME_IS_INVALID(duration)) {
      return;
  }
  
  double seconds = CMTimeGetSeconds(duration);
  if (isfinite(seconds)) {
    __weak id weakSelf = self;
    
    CGFloat seekbarWidth = CGRectGetWidth([self.slider bounds]);
    double interval = (0.5f * (seconds / seekbarWidth));
    
    CMTime seekbarSeconds = CMTimeMakeWithSeconds(interval, NSEC_PER_SEC);
    seekbarObserver = [player addPeriodicTimeObserverForInterval:seekbarSeconds queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
      [weakSelf seekbarSync];
    }];
  }
}

-(IBAction) cancel:(id)sender forEvent:(UIEvent *)event {
  [self.plugin cancelled];
}

-(IBAction) retakeVideo:(id)sender forEvent:(UIEvent *)event {
  ControllerCaptureOverlay* parent = (ControllerCaptureOverlay*)self.parentViewController;
  [parent retakeVideo:self forMovie:self.movieUrl];
}

-(IBAction) takePicture:(id)sender forEvent:(UIEvent *)event {
  AVPlayer* player = self.moviePlayer.player;
  AVAsset* asset = [[player currentItem] asset];
  CMTime currentTime = [player currentTime];
  
  AVAssetImageGenerator* generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
  [generator setAppliesPreferredTrackTransform:YES];
  [generator setMaximumSize:CGSizeMake(360, 640)];
  generator.requestedTimeToleranceBefore = kCMTimeZero;
  generator.requestedTimeToleranceAfter = kCMTimeZero;
  
  NSError* error;
  CMTime actualTime;
  CGImageRef imageRef = [generator copyCGImageAtTime:currentTime actualTime:&actualTime error:&error];
  
  if ((error.code != noErr)) {
    alertController = [UIAlertController alertControllerWithTitle:@"Unable to Capture Image" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
      [self.plugin failed:[error localizedDescription]];
    }]];

    [self presentViewController:alertController animated:YES completion:nil];
    return;
  }
  
  [[self takeButton] setUserInteractionEnabled:NO];
  
  NSNumber* timestamp = [NSNumber numberWithFloat:CMTimeGetSeconds(currentTime)];
  UIImage* image = [UIImage imageWithCGImage:imageRef];
  AudioServicesPlaySystemSound(1108);
  
  ControllerImagePreview* review = [[ControllerImagePreview alloc] initWithNibName:@"ControllerImagePreview" bundle:nil];
  review.plugin = self.plugin;
  review.movieUrl = self.movieUrl;
  review.movieTime = timestamp;
  review.movieImage = image;
  
  [self addChildViewController:review];
  [self.view addSubview:review.view];
  [review didMoveToParentViewController:self];
  
  CGFloat point = CGRectGetWidth(self.view.frame);
  CGRect frame = self.view.bounds;
  frame.origin.x += point;
  frame.size.width = self.view.frame.size.width;
  frame.size.height = self.view.frame.size.height;
  
  review.view.frame = frame;
  [UIView animateWithDuration:0.25f animations:^{review.view.frame = self.view.bounds;} completion:^(BOOL finished) {
    CGImageRelease(imageRef);
  }];
}

-(IBAction) togglePlayback:(id)sender forEvent:(UIEvent *)event {
  if ([self.playbackButton isSelected]) {
      [self.moviePlayer.player pause];
  } else {
      [self.moviePlayer.player play];
  }
  
  [self.takeButton setHidden:![self.playbackButton isSelected]];
  [self.playbackButton setSelected:![self.playbackButton isSelected]];
}

-(IBAction) seekbarAction:(UISlider *)sender forEvent:(UIEvent *)event {
  AVPlayer* player = self.moviePlayer.player;
  AVPlayerItem* playerItem = [player currentItem];
  CMTime duration = [playerItem.asset duration];

  double seconds = CMTimeGetSeconds(duration);
  float minValue = [sender minimumValue];
  float maxValue = [sender maximumValue];
  float currentValue = [sender value];
  double value = seconds * (currentValue - minValue) / (maxValue - minValue);
  
  CMTime time = CMTimeMakeWithSeconds(value, NSEC_PER_SEC);
  [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}

-(IBAction) seekbarPause:(id)sender forEvent:(UIEvent *)event {
  AVPlayer* player = self.moviePlayer.player;
  [player setRate:0.f];
  
  [self.takeButton setHidden:NO];
  [self.playbackButton setSelected:NO];
}

-(void) retakePicture:(UIViewController *)child {
  CGFloat point = CGRectGetWidth(child.view.frame);
  CGRect frame = child.view.bounds;
  frame.origin.x += point;
  frame.size.width = child.view.frame.size.width;
  frame.size.height = child.view.frame.size.height;
  
  [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{child.view.frame = frame;} completion:^(BOOL finished){
    [child willMoveToParentViewController:nil];
    [child.view removeFromSuperview];
    [child removeFromParentViewController];
    [[self takeButton] setUserInteractionEnabled:YES];
  }];
}

-(void) playerReachedEnd:(NSNotification *)notification {
  AVPlayerItem* item = [notification object];
  [item seekToTime:kCMTimeZero];
  
  [self.takeButton setHidden:NO];
  [self.playbackButton setSelected:NO];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
  if (object == self.moviePlayer.player && [keyPath isEqualToString:@"status"]) {
    if (self.moviePlayer.player.status == AVPlayerItemStatusReadyToPlay) {
      [self initSeekbar];
    }
  }
}

-(void) seekbarSync {
  AVPlayer* player = self.moviePlayer.player;
  AVPlayerItem* playerItem = [player currentItem];
  CMTime duration = [playerItem.asset duration];
  
  if (CMTIME_IS_INVALID(duration)) {
    self.slider.minimumValue = 0.0;
    return;
  }
  
  double seconds = CMTimeGetSeconds(duration);
  double currentSeconds = CMTimeGetSeconds([player currentTime]);
  
  float minValue = [self.slider minimumValue];
  float maxValue = [self.slider maximumValue];
  [self.slider setValue:(maxValue - minValue) * currentSeconds/seconds + minValue];
}

-(void) viewDidLoad {
  [super viewDidLoad];
  
  AVPlayer* player = [AVPlayer playerWithURL:self.movieUrl];
  player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
  player.muted = YES;
  
  self.moviePlayer = [[AVPlayerViewController alloc] init];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerReachedEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[player currentItem]];
  [player addObserver:self forKeyPath:@"status" options:0 context:nil];
  
  self.moviePlayer.player = player;
  self.moviePlayer.showsPlaybackControls = NO;
  self.moviePlayer.allowsPictureInPicturePlayback = NO;
}

-(void) viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.playerView addSubview:self.moviePlayer.view];
    [self.moviePlayer.player play];
    
    [self.takeButton setHidden:YES];
    [self.playbackButton setSelected:YES];
  });
}

-(void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
    
  [self.playerView layoutIfNeeded];
  self.moviePlayer.view.frame = self.playerView.bounds;
}

-(void) viewWillDisappear:(BOOL)animated {
  AVPlayer* player = self.moviePlayer.player;
  [player removeTimeObserver:seekbarObserver];
  [player removeObserver:self forKeyPath:@"status"];
  alertController = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
  [super viewWillDisappear:animated];
}

@end