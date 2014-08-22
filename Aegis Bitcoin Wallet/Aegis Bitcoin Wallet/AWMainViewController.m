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
#import "Reachability.h"


@interface AWMainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *bitcoinBalance;
@property (weak, nonatomic) IBOutlet UILabel *currencyBalance;
@property (nonatomic, strong) id balanceObserver;
@property (nonatomic, strong) id reachabilityObserver, syncStartedObserver, syncFinishedObserver, syncFailedObserver;
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, strong) BRWalletManager *manager;
@property (nonatomic, strong) IBOutlet UIView *errorBar;

@property (nonatomic, assign) NSTimeInterval timeout, start;


@end

@implementation AWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[BRPeerManager sharedInstance] connect];
    self.manager = [BRWalletManager sharedInstance];
    
    
    self.bitcoinBalance.text = [self.manager stringForAmount:self.manager.wallet.balance];
    
    self.balanceObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletBalanceChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([[BRPeerManager sharedInstance] syncProgress] < 1.0) return; // wait for sync before updating balance
                                                      
                                                      self.bitcoinBalance.text = [NSString stringWithFormat:@"%@", [self.manager stringForAmount:self.manager.wallet.balance]];
                                                  }];
    
    
    self.reachabilityObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      NSLog(@"Reachability status: %ld", self.reachability.currentReachabilityStatus);
                                                      
                                                      if (self.reachability.currentReachabilityStatus != NotReachable) {
                                                          NSLog(@"Doing connection for reachability...");
                                                          [[BRPeerManager sharedInstance] connect];
                                                      }
                                                      else if (self.reachability.currentReachabilityStatus == NotReachable){
                                                          NSLog(@"Not able to reach...");
                                                      }
                                                  }];
    
    
    self.syncStartedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncStartedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           BRPeerManager *p = [BRPeerManager sharedInstance];
                                                           
                                                           if (self.reachability.currentReachabilityStatus != NotReachable)
                                                               NSLog(@"Not able to reach...");
                                                           
                                                           [self startActivityWithTimeout:0];
                                                           
                                                           if (p.lastBlockHeight + 2016/2 < p.estimatedBlockHeight &&
                                                               self.manager.seedCreationTime + 60*60*24 < [NSDate timeIntervalSinceReferenceDate]) {
                                                               //self.percent.hidden = NO;
                                                               self.navigationItem.title = NSLocalizedString(@"syncing...", nil);
                                                           }
                                                       }];
    
    self.syncFinishedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncFinishedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           //if (self.timeout < 1.0) [self stopActivityWithSuccess:YES];
                                                           //[self triggerBackupDialog];
                                                           //self.percent.hidden = YES;
                                                           self.bitcoinBalance.text = [NSString stringWithFormat:@"%@", [self.manager stringForAmount:self.manager.wallet.balance]];
                                                       }];
    
    self.syncFailedObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerSyncFailedNotification object:nil
                                                       queue:nil usingBlock:^(NSNotification *note) {
                                                           //if (self.timeout < 1.0) [self stopActivityWithSuccess:NO];
                                                           //[self showErrorBar];
                                                           //[self triggerBackupDialog];
                                                           //self.percent.hidden = YES;
                                                           self.bitcoinBalance.text = [NSString stringWithFormat:@"%@", [self.manager stringForAmount:self.manager.wallet.balance]];
                                                       }];
    
    
    NSArray *array = [self.manager.wallet recentTransactions];
    NSLog(@"SIZE OF TX ARRAY: %lu", sizeof(array));
    
    double syncProgress = [[BRPeerManager sharedInstance] syncProgress];
    NSLog(@"SYNC PROGRESS: %f", syncProgress);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)startActivityWithTimeout:(NSTimeInterval)timeout
{
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    if (timeout > 1 && start + timeout > self.start + self.timeout) {
        self.timeout = timeout;
        self.start = start;
    }
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    //self.progress.hidden = self.pulse.hidden = NO;
    //[UIView animateWithDuration:0.2 animations:^{ self.progress.alpha = 1.0; }];
    //[self updateProgress];
}

- (void)stopActivityWithSuccess:(BOOL)success
{
    double progress = [[BRPeerManager sharedInstance] syncProgress];
    
    self.start = self.timeout = 0.0;
    if (progress > DBL_EPSILON && progress < 1.0) return; // not done syncing
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    //if (self.progress.alpha < 0.5) return;
    
    if (success) {
        //[self.progress setProgress:1.0 animated:YES];
        //[self.pulse setProgress:1.0 animated:YES];
        
        [UIView animateWithDuration:0.2 animations:^{
            //self.progress.alpha = self.pulse.alpha = 0.0;
        } completion:^(BOOL finished) {
            //self.progress.hidden = self.pulse.hidden = YES;
            //self.progress.progress = self.pulse.progress = 0.0;
        }];
    }
    else {
        //self.progress.hidden = self.pulse.hidden = YES;
        //self.progress.progress = self.pulse.progress = 0.0;
    }
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
