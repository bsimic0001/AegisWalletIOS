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
@property (strong, nonatomic) NSString* receiveAddress;

@end

@implementation AWReceiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    self.addressLabel.text = self.receiveAddress;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)receiveAddress {
    return [[[BRWalletManager sharedInstance] wallet] receiveAddress];
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
