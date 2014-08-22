//
//  AWReceiveViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 8/18/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWReceiveViewController.h"
#import "BRWalletManager.h"
#import "BRWallet.h"

@interface AWReceiveViewController ()

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitcoinBalance;
@property (weak, nonatomic) IBOutlet UILabel *currencyBalance;
@property (weak, nonatomic) IBOutlet UITextField *amountTxtField;
@property (strong, nonatomic) NSString* receiveAddress;
@property (weak, nonatomic) IBOutlet UIImageView *qrCode;

@end

@implementation AWReceiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.addressLabel.text = self.receiveAddress;
    
    BRWalletManager *manager = [BRWalletManager sharedInstance];
    self.bitcoinBalance.text = [manager stringForAmount:manager.wallet.balance];
    self.currencyBalance.text = [manager localCurrencyStringForAmount:manager.wallet.balance];
    
    [self showQrCode];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)receiveAddress {
    return [[[BRWalletManager sharedInstance] wallet] receiveAddress];
}

- (void) showQrCode{
    
    NSData *data = [self.receiveAddress dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setValue:[s dataUsingEncoding:NSISOLatin1StringEncoding] forKey:@"inputMessage"];
    [filter setValue:@"L" forKey:@"inputCorrectionLevel"];
    UIGraphicsBeginImageContext(self.qrCode.bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGImageRef img = [[CIContext contextWithOptions:nil] createCGImage:filter.outputImage
                                                              fromRect:filter.outputImage.extent];
    
    if (context) {
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        CGContextDrawImage(context, CGContextGetClipBoundingBox(context), img);
        self.qrCode.image = [UIImage imageWithCGImage:UIGraphicsGetImageFromCurrentImageContext().CGImage scale:1.0
                                          orientation:UIImageOrientationDownMirrored];
        //[self.addressButton setTitle:self.paymentAddress forState:UIControlStateNormal];
        //    self.updated = YES;
    }
    
    UIGraphicsEndImageContext();
    CGImageRelease(img);

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
