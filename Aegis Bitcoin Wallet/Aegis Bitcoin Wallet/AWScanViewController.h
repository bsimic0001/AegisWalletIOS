//
//  AWScanViewController.h
//  Aegis Bitcoin Wallet
//
//  Created by HyperCorpCTO on 8/29/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AWScanViewController : UIViewController

@property (nonatomic, assign) id<AVCaptureMetadataOutputObjectsDelegate> delegate;
@property (nonatomic, strong) IBOutlet UILabel *message;
@property (nonatomic, strong) IBOutlet UIImageView *cameraGuide;

- (IBAction)flash:(id)sender;

- (void)stop;
@end
