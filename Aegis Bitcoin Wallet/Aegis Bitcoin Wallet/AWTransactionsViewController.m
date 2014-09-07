//
//  AWTransactionsViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 9/6/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWTransactionsViewController.h"
#import "BRWalletManager.h"
#import "BRWallet.h"
#import "BRPeerManager.h"
#import "BRTransaction.h"

@interface AWTransactionsViewController ()
@property (nonatomic, strong) NSArray *transactions;
@property (nonatomic, assign) BOOL moreTx;
@property (nonatomic, strong) NSMutableDictionary *txDates;
@property (nonatomic, strong) id balanceObserver, txStatusObserver;

@end

@implementation AWTransactionsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.txDates = [NSMutableDictionary dictionary];
    //self.navigationController.delegate = self;
    self.moreTx = ([BRWalletManager sharedInstance].wallet.recentTransactions.count > 5) ? YES : NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    BRWalletManager *m = [BRWalletManager sharedInstance];
    NSArray *a = m.wallet.recentTransactions;
    
    self.transactions = [a subarrayWithRange:NSMakeRange(0, (a.count > 5 && self.moreTx) ? 5 : a.count)];
    
    if (! self.balanceObserver) {
        self.balanceObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletBalanceChangedNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               BRTransaction *tx = self.transactions.firstObject;
                                                               NSArray *a = m.wallet.recentTransactions;
                                                               
                                                               if (! m.wallet) return;
                                                               
                                                               if (self.moreTx) {
                                                                   self.transactions = [a subarrayWithRange:NSMakeRange(0, a.count > 5 ? 5 : a.count)];
                                                                   self.moreTx = (a.count > 5) ? YES : NO;
                                                               }
                                                               else self.transactions = [NSArray arrayWithArray:a];
                                                               
                                                               self.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", [m stringForAmount:m.wallet.balance],
                                                                                            [m localCurrencyStringForAmount:m.wallet.balance]];
                                                               
                                                               if (self.transactions.firstObject != tx) {
                                                                   [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                                                                 withRowAnimation:UITableViewRowAnimationAutomatic];
                                                               }
                                                               else [self.tableView reloadData];
                                                           }];
    }
    
    if (! self.txStatusObserver) {
        self.txStatusObserver =
        [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerTxStatusNotification object:nil
                                                           queue:nil usingBlock:^(NSNotification *note) {
                                                               if (! m.wallet) return;
                                                               [self.tableView reloadData];
                                                           }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.navigationController.isBeingDismissed) {
        if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
        self.balanceObserver = nil;
        if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
        self.txStatusObserver = nil;
    }
    
    [super viewWillDisappear:animated];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //TODO: Determine if any other logic needed here
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) {
        if (self.transactions.count == 0) return 1;
        return (self.moreTx) ? self.transactions.count + 1 : self.transactions.count;
    }
    
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *noTxIdent = @"NoTxCell", *transactionIdent = @"TransactionCell";
    UITableViewCell *cell = nil;
    UILabel *textLabel, *unconfirmedLabel, *sentLabel, *localCurrencyLabel, *balanceLabel, *localBalanceLabel,
    *toggleLabel;
//    BRCopyLabel *detailTextLabel;
    BRWalletManager *m = [BRWalletManager sharedInstance];
    
  // TODO: How many transactions do we want to display? And how to display additional transactions?
  //  if (indexPath.row > 0 && indexPath.row >= self.transactions.count) {
  //      cell = [tableView dequeueReusableCellWithIdentifier:actionIdent];
  //      cell.textLabel.text = NSLocalizedString(@"more...", nil);
  //      cell.imageView.image = nil;
  //  }
  //  else
    
    if (self.transactions.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:transactionIdent];
        textLabel = (id)[cell viewWithTag:1];
        //detailTextLabel = (id)[cell viewWithTag:2];
        unconfirmedLabel = (id)[cell viewWithTag:3];
        localCurrencyLabel = (id)[cell viewWithTag:5];
        sentLabel = (id)[cell viewWithTag:6];
        balanceLabel = (id)[cell viewWithTag:7];
        localBalanceLabel = (id)[cell viewWithTag:8];
        
        BRTransaction *tx = self.transactions[indexPath.row];
        uint64_t received = [m.wallet amountReceivedFromTransaction:tx],
        sent = [m.wallet amountSentByTransaction:tx],
        balance = [m.wallet balanceAfterTransaction:tx];
        uint32_t height = [[BRPeerManager sharedInstance] lastBlockHeight],
        confirms = (tx.blockHeight == TX_UNCONFIRMED) ? 0 : (height - tx.blockHeight) + 1;
        NSUInteger peerCount = [[BRPeerManager sharedInstance] peerCount],
        relayCount = [[BRPeerManager sharedInstance] relayCountForTransaction:tx.txHash];
        
        sentLabel.hidden = YES;
        unconfirmedLabel.hidden = NO;
        //detailTextLabel.text = [self dateForTx:tx];
        balanceLabel.text = [m stringForAmount:balance];
        localBalanceLabel.text = [NSString stringWithFormat:@"(%@)", [m localCurrencyStringForAmount:balance]];
        
        if (confirms == 0 && ! [m.wallet transactionIsValid:tx]) {
            unconfirmedLabel.text = NSLocalizedString(@"INVALID", nil);
            unconfirmedLabel.backgroundColor = [UIColor redColor];
        }
        else if (confirms == 0 && [m.wallet transactionIsPending:tx atBlockHeight:height]) {
            unconfirmedLabel.text = NSLocalizedString(@"post-dated", nil);
            unconfirmedLabel.backgroundColor = [UIColor redColor];
        }
        else if (confirms == 0 && (peerCount == 0 || relayCount < peerCount)) {
            unconfirmedLabel.text = NSLocalizedString(@"unverified", nil);
        }
        else if (confirms < 6) {
            unconfirmedLabel.text = (confirms == 1) ? NSLocalizedString(@"1 confirmation", nil) :
            [NSString stringWithFormat:NSLocalizedString(@"%d confirmations", nil),
             (int)confirms];
        }
        else {
            unconfirmedLabel.text = nil;
            unconfirmedLabel.hidden = YES;
            sentLabel.hidden = NO;
        }
        
        if (! [m.wallet addressForTransaction:tx] && sent > 0) {
            textLabel.text = [m stringForAmount:sent];
            localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                       [m localCurrencyStringForAmount:sent]];
            sentLabel.text = NSLocalizedString(@"moved", nil);
            sentLabel.textColor = [UIColor blackColor];
        }
        else if (sent > 0) {
            textLabel.text = [m stringForAmount:received - sent];
            localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                       [m localCurrencyStringForAmount:received - sent]];
            sentLabel.text = NSLocalizedString(@"sent", nil);
            sentLabel.textColor = [UIColor colorWithRed:1.0 green:0.33 blue:0.33 alpha:1.0];
        }
        else {
            textLabel.text = [m stringForAmount:received];
            localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                       [m localCurrencyStringForAmount:received]];
            sentLabel.text = NSLocalizedString(@"received", nil);
            sentLabel.textColor = [UIColor colorWithRed:0.0 green:0.75 blue:0.0 alpha:1.0];
        }
        
        if (! unconfirmedLabel.hidden) {
            unconfirmedLabel.layer.cornerRadius = 3.0;
            unconfirmedLabel.backgroundColor = [UIColor lightGrayColor];
            unconfirmedLabel.text = [unconfirmedLabel.text stringByAppendingString:@"  "];
        }
        else {
            sentLabel.layer.cornerRadius = 3.0;
            sentLabel.layer.borderWidth = 0.5;
            sentLabel.text = [sentLabel.text stringByAppendingString:@"  "];
            sentLabel.layer.borderColor = sentLabel.textColor.CGColor;
            sentLabel.highlightedTextColor = sentLabel.textColor;
        }
    }
    else cell = [tableView dequeueReusableCellWithIdentifier:noTxIdent];

    
    return cell;
}

@end
