//
//  ViewController.m
//  CellularAutomataStarter
//
//  Created by Kim Pedersen on 19/02/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"
@import SpriteKit;
@import AVFoundation;

@interface ViewController ()
@property (strong, nonatomic) AVAudioPlayer *backgroundMusicPlayer;
@end

@implementation ViewController

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  
  SKView * skView = (SKView *)self.view;
  
  if (!skView.scene) {
    // Configure the view.
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.showsDrawCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Play some lovely background music
    NSError *error;
    NSURL *backgroundMusicURL =[[NSBundle mainBundle] URLForResource:@"theforgottentemple" withExtension:@"mp3"];
    self.backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicURL error:&error];
    self.backgroundMusicPlayer.numberOfLoops = -1;
    self.backgroundMusicPlayer.volume = 0.5f;
    [self.backgroundMusicPlayer prepareToPlay];
    [self.backgroundMusicPlayer play];
    
    if (error) {
      NSLog(@"Error: %@", error.localizedDescription);
    }
    
    // Present the scene.
    [skView presentScene:scene];
  }
}

- (BOOL)prefersStatusBarHidden
{
  return YES;
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskLandscape;
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

@end
