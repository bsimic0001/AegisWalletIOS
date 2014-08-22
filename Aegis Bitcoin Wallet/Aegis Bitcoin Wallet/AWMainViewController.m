//
//  AWMainViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 8/21/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWMainViewController.h"
#import "BRWalletManager.h"
#import "BRPeerManager.h"
#import "BRWallet.h"


@interface AWMainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *bitcoinBalance;
@property (weak, nonatomic) IBOutlet UILabel *currencyBalance;
@property (nonatomic, strong) id balanceObserver;
@property (nonatomic, strong) BRWalletManager *manager;


@end

@implementation AWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.manager = [BRWalletManager sharedInstance];
    
    
    self.bitcoinBalance.text = [self.manager stringForAmount:self.manager.wallet.balance];
    
    self.balanceObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletBalanceChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([[BRPeerManager sharedInstance] syncProgress] < 1.0) return; // wait for sync before updating balance
                                                      
                                                      self.bitcoinBalance.text = [NSString stringWithFormat:@"%@", [self.manager stringForAmount:self.manager.wallet.balance]];
                                                  }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
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
