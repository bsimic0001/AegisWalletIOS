//
//  AWMainViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 8/21/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWMainViewController.h"

@interface AWMainViewController ()
@property (weak, nonatomic) IBOutlet UILabel *bitcoinBalance;
@property (weak, nonatomic) IBOutlet UILabel *currencyBalance;

@end

@implementation AWMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
