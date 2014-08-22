//
//  AWSeedStartController.m
//  Aegis Bitcoin Wallet
//
//  Created by HyperCorpCTO on 8/15/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWSeedStartController.h"
#import "BRWalletManager.h"
#import "BRPeerManager.h"

@interface AWSeedStartController ()

@property (weak, nonatomic) IBOutlet UILabel *seedLabel;

@end

@implementation AWSeedStartController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void) viewWillAppear:(BOOL)animated{
    
    BRWalletManager *manager = [BRWalletManager sharedInstance];
    
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    if ([[UIApplication sharedApplication] isProtectedDataAvailable] && !manager.wallet){
        [manager generateRandomSeed];
        [[BRPeerManager sharedInstance] connect];
    }
    
    self.seedLabel.text = manager.seedPhrase;

}

/*- (IBAction)done:(id)sender
{
    if (self.navigationController.viewControllers.firstObject != self) return;
    
    self.navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.navigationController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES
                                                                                                    completion:nil];
}
*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
