//
//  AWScanViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by HyperCorpCTO on 8/29/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWScanViewController.h"

@interface AWScanViewController ()

@property (nonatomic, strong) IBOutlet UIView *cameraView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

@implementation AWScanViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    
    if (error) NSLog(@"%@", [error localizedDescription]);
    
    if ([device lockForConfiguration:&error]) {
        if (device.isAutoFocusRangeRestrictionSupported) {
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        [device unlockForConfiguration];
    }
    
    self.session = [AVCaptureSession new];
    if (input) [self.session addInput:input];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self.delegate queue:dispatch_get_main_queue()];
    
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    
    self.preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.view.layer.bounds;
    [self.cameraView.layer addSublayer:self.preview];
    
    dispatch_async(dispatch_queue_create("qrscanner", NULL), ^{
        [self.session startRunning];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.session stopRunning];
    self.session = nil;
    [self.preview removeFromSuperlayer];
    self.preview = nil;
    
    [super viewDidDisappear:animated];
}

- (void)stop
{
    [self.session removeOutput:self.session.outputs.firstObject];
}

#pragma mark - IBAction

- (IBAction)flash:(id)sender
{
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device lockForConfiguration:&error]) {
        device.torchMode = device.torchActive ? AVCaptureTorchModeOff : AVCaptureTorchModeOn;
        [device unlockForConfiguration];
    }
}

- (IBAction)done:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (! device.hasTorch) self.toolbar.items = @[self.toolbar.items[0]];
    
    [self.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
