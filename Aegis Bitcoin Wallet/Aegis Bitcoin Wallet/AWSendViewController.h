//
//  AWSendViewController.h
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 8/21/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
//TODO: do something with amount view
//#import "BRAmountViewController.h"

@interface AWSendViewController : UIViewController <UIAlertViewDelegate,
    UITextViewDelegate,
    AVCaptureMetadataOutputObjectsDelegate,
    UIViewControllerTransitioningDelegate>

- (void)handleURL:(NSURL *)url;
- (void)handleFile:(NSData *)file;

@end
