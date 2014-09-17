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
    UILabel *localCurrencyLabel, *bitcoinsLabel, *dateLabel, *merchantLabel;
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
        UIImageView *imageView = (id) [cell viewWithTag:0];
        localCurrencyLabel = (id)[cell viewWithTag:1];
        bitcoinsLabel = (id)[cell viewWithTag:2];
        dateLabel = (id)[cell viewWithTag:3];
        merchantLabel = (id)[cell viewWithTag:4];
        
        BRTransaction *tx = self.transactions[indexPath.row];
        uint64_t received = [m.wallet amountReceivedFromTransaction:tx],
        sent = [m.wallet amountSentByTransaction:tx],
        balance = [m.wallet balanceAfterTransaction:tx];
        uint32_t height = [[BRPeerManager sharedInstance] lastBlockHeight],
        confirms = (tx.blockHeight == TX_UNCONFIRMED) ? 0 : (height - tx.blockHeight) + 1;
        NSUInteger peerCount = [[BRPeerManager sharedInstance] peerCount],
        relayCount = [[BRPeerManager sharedInstance] relayCountForTransaction:tx.txHash];
        
        //bitcoinsLabel.text = [m stringForAmount:balance];
        //localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)", [m localCurrencyStringForAmount:balance]];
        
        dateLabel.text = [self dateForTx:tx];
        
        if (! [m.wallet addressForTransaction:tx] && sent > 0) {
            merchantLabel.text = [m.wallet addressForTransaction:tx];
        }
        else if (sent > 0) {
            //Sent image
            imageView.image = [UIImage imageNamed:@"aegis_send_icon"];
            bitcoinsLabel.text = [m stringForAmount:sent];
            localCurrencyLabel.text = [m localCurrencyStringForAmount:sent];
        }
        else {
            //Received image
            imageView.image = [UIImage imageNamed:@"aegis_receive_icon"];
            bitcoinsLabel.text = [m stringForAmount:received];
            localCurrencyLabel.text = [m localCurrencyStringForAmount:received];
        }
        
    }
    else cell = [tableView dequeueReusableCellWithIdentifier:noTxIdent];

    
    return cell;
}

- (NSString *)dateForTx:(BRTransaction *)tx
{
    //Friday | 13 June, 2014 | 7:14 PM
    static NSDateFormatter *f1 = nil, *f2 = nil, *f3 = nil;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate], w = now - 6*24*60*60, y = now - 365*24*60*60;
    NSString *date = self.txDates[tx.txHash];
    
    if (date) return date;
    
    if (! f1) { //BUG: need to watch for NSCurrentLocaleDidChangeNotification
        f1 = [NSDateFormatter new];
        f2 = [NSDateFormatter new];
        f3 = [NSDateFormatter new];
        
        f1.dateFormat = [[[[[[[NSDateFormatter dateFormatFromTemplate:@"Mdja" options:0 locale:[NSLocale currentLocale]]
                              stringByReplacingOccurrencesOfString:@", " withString:@" "]
                             stringByReplacingOccurrencesOfString:@" a" withString:@"a"]
                            stringByReplacingOccurrencesOfString:@"hh" withString:@"h"]
                           stringByReplacingOccurrencesOfString:@" ha" withString:@"@ha"]
                          stringByReplacingOccurrencesOfString:@"HH" withString:@"H"]
                         stringByReplacingOccurrencesOfString:@"H " withString:@"H'h' "];
        f1.dateFormat = [f1.dateFormat stringByReplacingOccurrencesOfString:@"H" withString:@"H'h'"
                                                                    options:NSBackwardsSearch|NSAnchoredSearch range:NSMakeRange(0, f1.dateFormat.length)];
        f2.dateFormat = [[NSDateFormatter dateFormatFromTemplate:@"Md" options:0 locale:[NSLocale currentLocale]]
                         stringByReplacingOccurrencesOfString:@", " withString:@" "];
        f3.dateFormat = [[NSDateFormatter dateFormatFromTemplate:@"yyMd" options:0 locale:[NSLocale currentLocale]]
                         stringByReplacingOccurrencesOfString:@", " withString:@" "];
    }
    
    NSTimeInterval t = [[BRPeerManager sharedInstance] timestampForBlockHeight:tx.blockHeight];
    NSDateFormatter *f = (t > w) ? f1 : ((t > y) ? f2 : f3);
    
    //date = [[[[f stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:t - 5*60]] lowercaseString]
      //       stringByReplacingOccurrencesOfString:@"am" withString:@"a"]
      //      stringByReplacingOccurrencesOfString:@"pm" withString:@"p"];
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE' | 'dd MMM, yyyy' | 'HH:mm"];
    
    date = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:t - 5*60]];
    
    self.txDates[tx.txHash] = date;
    
    return date;
}


@end
