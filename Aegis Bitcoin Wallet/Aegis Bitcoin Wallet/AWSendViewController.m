//
//  AWSendViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Tim Kelley on 8/21/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWSendViewController.h"
#import "BRTransaction.h"
#import "AWScanViewController.h"
#import "BRPaymentRequest.h"
#import "NSString+Base58.h"
#import "BRWalletManager.h"
#import "BRWallet.h"
#import "BRPeerManager.h"
#import "BRPaymentProtocol.h"
#import "NSMutableData+Bitcoin.h"

#define SCAN_TIP      NSLocalizedString(@"Scan someone else's QR code to get their bitcoin address. "\
"You can send a payment to anyone with an address.", nil)
#define CLIPBOARD_TIP NSLocalizedString(@"Bitcoin addresses can also be copied to the clipboard. "\
"A bitcoin address always starts with '1' or '3'.", nil)

#define LOCK @"\xF0\x9F\x94\x92" // unicode lock symbol U+1F512 (utf-8)
#define REDX @"\xE2\x9D\x8C"     // unicode cross mark U+274C, red x emoji (utf-8)

static NSString *sanitizeString(NSString *s)
{
    NSMutableString *sane = [NSMutableString stringWithString:s ? s : @""];
    
    CFStringTransform((CFMutableStringRef)sane, NULL, kCFStringTransformToUnicodeName, NO);
    return sane;
}

@interface AWSendViewController ()

@property (nonatomic, assign) BOOL clearClipboard, useClipboard, showTips, didAskFee, removeFee;
@property (nonatomic, strong) BRTransaction *tx, *sweepTx;
@property (nonatomic, strong) BRPaymentRequest *request;
@property (nonatomic, strong) BRPaymentProtocolRequest *protocolRequest;
@property (nonatomic, assign) uint64_t protoReqAmount;
//@property (nonatomic, strong) BRBubbleView *tipView;
@property (nonatomic, strong) NSString *okAddress;
@property (nonatomic, strong) AWScanViewController *scanController;
@property (nonatomic, strong) id clipboardObserver;

@property (weak, nonatomic) IBOutlet UILabel *bitcoinBalance;
@property (weak, nonatomic) IBOutlet UILabel *currencyBalance;
@property (weak, nonatomic) IBOutlet UITextField *amountTxtField;
@property (weak, nonatomic) IBOutlet UITextField *toAddressTxtField;
//@property (nonatomic, strong) IBOutlet UITextView *clipboardText;

@end

@implementation AWSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //self.clipboardText.textContainerInset = UIEdgeInsetsMake(8.0, 0.0, 0.0, 0.0);
    
    /*
    self.clipboardObserver =
    [[NSNotificationCenter defaultCenter] addObserverForName:UIPasteboardChangedNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (self.clipboardText.isFirstResponder) {
                                                          self.useClipboard = YES;
                                                      }
                                                      else [self updateClipboardText];
                                                  }];
     */
}

- (void)resetQRGuide
{
    self.scanController.message.text = nil;
    self.scanController.cameraGuide.image = [UIImage imageNamed:@"cameraguide"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)scanQrCode:(id)sender {
    
    [sender setEnabled:NO];
    self.scanController.delegate = self;
    self.scanController.transitioningDelegate = self;
    [self.navigationController presentViewController:self.scanController animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (! self.scanController) {
        self.scanController = [self.storyboard instantiateViewControllerWithIdentifier:@"ScanViewController"];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (IBAction)send:(id)sender {
    BRWalletManager *m = [BRWalletManager sharedInstance];
    //Check if there is a request
    if(self.request) {
        if([self.toAddressTxtField.text length] != 0 && [self.amountTxtField.text length] != 0) {
            self.request.amount = [m amountForString:self.amountTxtField.text];
            [self confirmRequest:self.request];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Input" message:@"A receive address and amount must be entered." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
    else {
        if([self.toAddressTxtField.text length] != 0 && [self.amountTxtField.text length] != 0) {
            BRPaymentRequest *request = [BRPaymentRequest requestWithString:self.toAddressTxtField.text];
            request.amount = [m amountForString:self.amountTxtField.text];
            [self confirmRequest:request];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Input" message:@"A receive address and amount must be entered." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }
}

- (IBAction)cancel:(id)sender
{
    self.tx = nil;
    self.sweepTx = nil;
    self.request = nil;
    self.protocolRequest = nil;
    self.protoReqAmount = 0;
    self.clearClipboard = self.useClipboard = NO;
    self.didAskFee = self.removeFee = NO;
    //self.scanButton.enabled = self.clipboardButton.enabled = YES;
    //[self updateClipboardText];
}

//TODO: add cancel

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *o in metadataObjects) {
        if (! [o.type isEqual:AVMetadataObjectTypeQRCode]) continue;
        
        NSString *s = o.stringValue;
        BRPaymentRequest *request = [BRPaymentRequest requestWithString:s];
        
        if (! [request isValid] && ! [s isValidBitcoinPrivateKey] && ! [s isValidBitcoinBIP38Key]) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetQRGuide) object:nil];
            self.scanController.cameraGuide.image = [UIImage imageNamed:@"cameraguide-red"];
            
            if ([s hasPrefix:@"bitcoin:"] || [request.paymentAddress hasPrefix:@"1"]) {
                self.scanController.message.text = [NSString stringWithFormat:@"%@\n%@",
                                                    NSLocalizedString(@"not a valid bitcoin address", nil),
                                                    request.paymentAddress];
            }
            else self.scanController.message.text = NSLocalizedString(@"not a bitcoin QR code", nil);
            
            [self performSelector:@selector(resetQRGuide) withObject:nil afterDelay:0.35];
        }
        else {
            self.scanController.cameraGuide.image = [UIImage imageNamed:@"cameraguide-green"];
            [self.scanController stop];
            
            if (request.r.length > 0) { // start fetching payment protocol request right away
                [BRPaymentRequest fetch:request.r timeout:5.0
                             completion:^(BRPaymentProtocolRequest *req, NSError *error) {
                                 if (error) request.r = nil;
                                 
                                 
                                 
                                 if (error && ! [request isValid]) {
                                     [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                                                 message:error.localizedDescription delegate:nil
                                                       cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
                                     [self cancel:nil];
                                     return;
                                 }
                                 
                                 self.amountTxtField.text = [NSString stringWithFormat:@"%llu", request.amount];
                                 self.toAddressTxtField.text = request.paymentAddress;
                                 
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     [self.navigationController dismissViewControllerAnimated:YES completion:^{
                                         if (error) {
                                             [self confirmRequest:request];
                                         }
                                         else [self confirmProtocolRequest:req];
                                         
                                         [self resetQRGuide];
                                     }];
                                 });
                             }];
            }
            else {
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    [self confirmRequest:request];
                    [self resetQRGuide];
                }];
            }
        }
        
        break;
    }
}

- (void)confirmRequest:(BRPaymentRequest *)request
{
    if (! [request isValid]) {
        if ([request.paymentAddress isValidBitcoinPrivateKey] || [request.paymentAddress isValidBitcoinBIP38Key]) {
            //[self confirmSweep:request.paymentAddress];
        }
        else {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"not a valid bitcoin address", nil)
                                        message:request.paymentAddress delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                              otherButtonTitles:nil] show];
            [self cancel:nil];
        }
        
        return;
    }
    
    if (request.r.length > 0) { // payment protocol over HTTP
        
        //TODO: let main activity know that payment has been sent over HTTP
        //[(id)self.parentViewController.parentViewController startActivityWithTimeout:20.0];
        
        
        //TODO: let main activity know that the send has completed
        
        [BRPaymentRequest fetch:request.r timeout:20.0 completion:^(BRPaymentProtocolRequest *req, NSError *error) {
            //[(id)self.parentViewController.parentViewController stopActivityWithSuccess:(! error)];
            
            if (error) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                            message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                 otherButtonTitles:nil] show];
                [self cancel:nil];
            }
            else [self confirmProtocolRequest:req];
        }];
        
        
        return;
    }
    
    BRWalletManager *m = [BRWalletManager sharedInstance];
    
    if ([m.wallet containsAddress:request.paymentAddress]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"this payment address is already in your wallet", nil)
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
    }
    else if (request.amount == 0) {
        //Set payment address field.  Then return to get amount input from UI.
        self.toAddressTxtField.text = request.paymentAddress;
        return;
    }
    else if (request.amount < TX_MIN_OUTPUT_AMOUNT) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:[NSString stringWithFormat:NSLocalizedString(@"bitcoin payments can't be less than %@", nil),
                                             [m stringForAmount:TX_MIN_OUTPUT_AMOUNT]] delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
    }
    else {
        self.request = request;
        self.tx = [m.wallet transactionFor:request.amount to:request.paymentAddress withFee:NO];
        
        uint64_t amount = (! self.tx) ? request.amount :
        [m.wallet amountSentByTransaction:self.tx] - [m.wallet amountReceivedFromTransaction:self.tx];
        uint64_t fee = 0;
        
        /*
        if (self.tx && [m.wallet blockHeightUntilFree:self.tx] <= [[BRPeerManager sharedInstance] lastBlockHeight] +1 &&
            ! self.didAskFee && [[NSUserDefaults standardUserDefaults] boolForKey:SETTINGS_SKIP_FEE_KEY]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"bitcoin network fee", nil)
                                        message:[NSString stringWithFormat:NSLocalizedString(@"the standard bitcoin network fee for this "
                                                                                             "transaction is %@ (%@)\n\nremoving this fee may "
                                                                                             "delay confirmation", nil),
                                                 [m stringForAmount:self.tx.standardFee], [m localCurrencyStringForAmount:self.tx.standardFee]]
                                       delegate:self cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"remove fee", nil), NSLocalizedString(@"continue", nil), nil] show];
            return;
        }
        */
        
        if (! self.removeFee) {
            fee = self.tx.standardFee;
            amount += fee;
            self.tx = [m.wallet transactionFor:request.amount to:request.paymentAddress withFee:YES];
            if (self.tx) {
                amount = [m.wallet amountSentByTransaction:self.tx] - [m.wallet amountReceivedFromTransaction:self.tx];
                fee = [m.wallet feeForTransaction:self.tx];
            }
        }
        
        [self confirmAmount:amount fee:fee address:request.paymentAddress name:request.label memo:request.message
                   isSecure:NO];
    }
}

- (void)confirmProtocolRequest:(BRPaymentProtocolRequest *)protoReq
{
    BRWalletManager *m = [BRWalletManager sharedInstance];
    uint64_t amount = 0, fee = 0;
    NSString *address = @"";
    BOOL valid = [protoReq isValid], outputTooSmall = NO;
    
    if (! valid && [protoReq.errorMessage isEqual:NSLocalizedString(@"request expired", nil)]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"bad payment request", nil) message:protoReq.errorMessage
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    
    //TODO: check for duplicates of already paid requests
    
    for (NSNumber *n in protoReq.details.outputAmounts) {
        if ([n unsignedLongLongValue] < TX_MIN_OUTPUT_AMOUNT) outputTooSmall = YES;
        amount += [n unsignedLongLongValue];
    }
    
    if ([m.wallet containsAddress:[NSString addressWithScriptPubKey:protoReq.details.outputScripts.firstObject]]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"this payment address is already in your wallet", nil)
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
    }
    else if (amount == 0 && self.protoReqAmount == 0) {
        /*
        BRAmountViewController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"AmountViewController"];
        
        c.info = protoReq;
        c.delegate = self;
        
        if (protoReq.commonName.length > 0) {
            if (valid && ! [protoReq.pkiType isEqual:@"none"]) {
                c.to = [LOCK @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            }
            else if (protoReq.errorMessage.length > 0) {
                c.to = [REDX @" " stringByAppendingString:sanitizeString(protoReq.commonName)];
            }
            else c.to = sanitizeString(protoReq.commonName);
        }
        else c.to = [NSString addressWithScriptPubKey:protoReq.details.outputScripts.firstObject];
        
        c.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", [m stringForAmount:m.wallet.balance],
                                  [m localCurrencyStringForAmount:m.wallet.balance]];
        [self.navigationController pushViewController:c animated:YES];
         */
    }
    else if (amount > 0 && amount < TX_MIN_OUTPUT_AMOUNT) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:[NSString stringWithFormat:NSLocalizedString(@"bitcoin payments can't be less than %@", nil),
                                             [m stringForAmount:TX_MIN_OUTPUT_AMOUNT]] delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
    }
    else if (amount > 0 && outputTooSmall) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:[NSString stringWithFormat:NSLocalizedString(@"bitcoin transaction outputs can't be less than %@",
                                                                                         nil), [m stringForAmount:TX_MIN_OUTPUT_AMOUNT]]
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
    }
    else {
        self.protocolRequest = protoReq;
        
        if (self.protoReqAmount > 0) {
            self.tx = [m.wallet transactionForAmounts:@[@(self.protoReqAmount)]
                                      toOutputScripts:@[protoReq.details.outputScripts.firstObject] withFee:NO];
        }
        else {
            self.tx = [m.wallet transactionForAmounts:protoReq.details.outputAmounts
                                      toOutputScripts:protoReq.details.outputScripts withFee:NO];
        }
        
        /*
        
        if (self.tx && [m.wallet blockHeightUntilFree:self.tx] <= [[BRPeerManager sharedInstance] lastBlockHeight] +1 &&
            ! self.didAskFee && [[NSUserDefaults standardUserDefaults] boolForKey:SETTINGS_SKIP_FEE_KEY]) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"bitcoin network fee", nil)
                                        message:[NSString stringWithFormat:NSLocalizedString(@"the standard bitcoin network fee for this "
                                                                                             "transaction is %@ (%@)\n\nremoving this fee may "
                                                                                             "delay confirmation", nil),
                                                 [m stringForAmount:self.tx.standardFee], [m localCurrencyStringForAmount:self.tx.standardFee]]
                                       delegate:self cancelButtonTitle:nil
                              otherButtonTitles:NSLocalizedString(@"remove fee", nil), NSLocalizedString(@"continue", nil), nil] show];
            return;
        }
         */
        
        if (self.tx) {
            amount = [m.wallet amountSentByTransaction:self.tx] - [m.wallet amountReceivedFromTransaction:self.tx];
        }
        
        if (! self.removeFee) {
            fee = self.tx.standardFee;
            amount += fee;
            
            if (self.protoReqAmount > 0) {
                self.tx = [m.wallet transactionForAmounts:@[@(self.protoReqAmount)]
                                          toOutputScripts:@[protoReq.details.outputScripts.firstObject] withFee:YES];
            }
            else {
                self.tx = [m.wallet transactionForAmounts:protoReq.details.outputAmounts
                                          toOutputScripts:protoReq.details.outputScripts withFee:YES];
            }
            
            if (self.tx) {
                amount = [m.wallet amountSentByTransaction:self.tx] - [m.wallet amountReceivedFromTransaction:self.tx];
                fee = [m.wallet feeForTransaction:self.tx];
            }
        }
        
        for (NSData *script in protoReq.details.outputScripts) {
            NSString *addr = [NSString addressWithScriptPubKey:script];
            
            address = [address stringByAppendingFormat:@"%@%@", (address.length > 0) ? @", " : @"",
                       (addr) ? addr : NSLocalizedString(@"unrecognized address", nil)];
        }
        
        [self confirmAmount:amount fee:fee address:address name:protoReq.commonName memo:protoReq.details.memo
                   isSecure:(valid && ! [protoReq.pkiType isEqual:@"none"]) ? YES : NO];
    }
}

- (void)confirmAmount:(uint64_t)amount fee:(uint64_t)fee address:(NSString *)address name:(NSString *)name
                 memo:(NSString *)memo isSecure:(BOOL)isSecure
{
    BRWalletManager *m = [BRWalletManager sharedInstance];
    NSString *amountStr = [NSString stringWithFormat:@"%@ (%@)", [m stringForAmount:amount],
                           [m localCurrencyStringForAmount:amount]];
    NSString *msg = (isSecure && name.length > 0) ? LOCK @" " : @"";
    
    if (! isSecure && self.protocolRequest.errorMessage.length > 0) msg = [msg stringByAppendingString:REDX @" "];
    if (name.length > 0) msg = [msg stringByAppendingString:sanitizeString(name)];
    if (! isSecure && msg.length > 0) msg = [msg stringByAppendingString:@"\n"];
    
    if (! isSecure || msg.length == 0) {
        msg = [msg stringByAppendingString:[NSString base58WithData:[address base58ToData]]];
    }
    
    if (memo.length > 0) msg = [msg stringByAppendingFormat:@"\n\n%@", sanitizeString(memo)];
    
    msg = [msg stringByAppendingFormat:@"\n\n%@ (%@)", [m stringForAmount:amount - fee],
           [m localCurrencyStringForAmount:amount - fee]];
    
    if (fee > 0) {
        msg = [msg stringByAppendingFormat:NSLocalizedString(@"\nbitcoin network fee +%@ (%@)", nil),
               [m stringForAmount:fee], [m localCurrencyStringForAmount:fee]];
    }
    
    //TODO: XXXX full screen dialog with clean transitions
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"confirm payment", nil) message:msg delegate:self
                      cancelButtonTitle:NSLocalizedString(@"cancel", nil) otherButtonTitles:amountStr, nil] show];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

- (void)handleURL:(NSURL *)url
{
    //TODO: XXXX custom url splash image per: "Providing Launch Images for Custom URL Schemes."
    if ([url.scheme isEqual:@"bitcoin"]) {
        [self confirmRequest:[BRPaymentRequest requestWithURL:url]];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unsupported url", nil) message:url.absoluteString
                                   delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
    }
}

- (void)handleFile:(NSData *)file
{
    BRPaymentProtocolRequest *request = [BRPaymentProtocolRequest requestWithData:file];
    
    if (request) {
        [self confirmProtocolRequest:request];
        return;
    }
    
    // TODO: reject payments that don't match requested amounts/scripts, implement refunds
    BRPaymentProtocolPayment *payment = [BRPaymentProtocolPayment paymentWithData:file];
    
    if (payment.transactions.count > 0) {
        for (BRTransaction *tx in payment.transactions) {
            //[(id)self.parentViewController.parentViewController startActivityWithTimeout:30];
            
            [[BRPeerManager sharedInstance] publishTransaction:tx completion:^(NSError *error) {
                //[(id)self.parentViewController.parentViewController stopActivityWithSuccess:(! error)];
                
                if (error) {
                    [[[UIAlertView alloc]
                      initWithTitle:NSLocalizedString(@"couldn't transmit payment to bitcoin network", nil)
                      message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                      otherButtonTitles:nil] show];
                }
                
                /*
                [self.view addSubview:[[[BRBubbleView
                                         viewWithText:(payment.memo.length > 0 ? payment.memo : NSLocalizedString(@"recieved", nil))
                                         center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
                                       popOutAfterDelay:(payment.memo.length > 10 ? 3.0 : 2.0)]];
                 
                 */
            }];
        }
        
        return;
    }
    
    BRPaymentProtocolACK *ack = [BRPaymentProtocolACK ackWithData:file];
    
    if (ack) {
        if (ack.memo.length > 0) {

        }
        
        return;
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"unsupported or corrupted document", nil) message:nil
                               delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self cancel:nil];
        return;
    }
    
    if (self.sweepTx) {
       // [(id)self.parentViewController.parentViewController startActivityWithTimeout:30];
        
        [[BRPeerManager sharedInstance] publishTransaction:self.sweepTx completion:^(NSError *error) {
            //[(id)self.parentViewController.parentViewController stopActivityWithSuccess:(! error)];
            
            if (error) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't sweep balance", nil)
                                            message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                                  otherButtonTitles:nil] show];
                [self cancel:nil];
                return;
            }
            
            /*[self.view addSubview:[[[BRBubbleView viewWithText:NSLocalizedString(@"swept!", nil)
                                                        center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)]
                                    popIn] popOutAfterDelay:2.0]];
            */
             [self reset:nil];
        }];
        
        return;
    }
    else if (! self.tx && self.okAddress) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqual:NSLocalizedString(@"ignore", nil)]) {
            if (self.protocolRequest) [self confirmProtocolRequest:self.protocolRequest];
            else if (self.request) [self confirmRequest:self.request];
        }
        else [self cancel:nil];
        
        return;
    }
    
    BRWalletManager *m = [BRWalletManager sharedInstance];
    BRPaymentProtocolRequest *protoReq = self.protocolRequest;
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqual:NSLocalizedString(@"remove fee", nil)] || [title isEqual:NSLocalizedString(@"continue", nil)]) {
        self.didAskFee = YES;
        self.removeFee = ([title isEqual:NSLocalizedString(@"remove fee", nil)]) ? YES : NO;
        if (self.protocolRequest) [self confirmProtocolRequest:self.protocolRequest];
        else if (self.request) [self confirmRequest:self.request];
        return;
    }
    
    if (! self.tx) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"insufficient funds", nil) message:nil delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    
    //TODO: check for duplicate transactions
    
    if (self.navigationController.topViewController != self.parentViewController.parentViewController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    NSLog(@"signing transaction");
    
   // [(id)self.parentViewController.parentViewController startActivityWithTimeout:30.0];
    
    //TODO: don't sign on main thread
    if (! [m.wallet signTransaction:self.tx]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                    message:NSLocalizedString(@"error signing bitcoin transaction", nil) delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        [self cancel:nil];
        return;
    }
    
    NSLog(@"signed transaction:\n%@", [NSString hexWithData:self.tx.data]);
    
    [[BRPeerManager sharedInstance] publishTransaction:self.tx completion:^(NSError *error) {
        if (protoReq.details.paymentURL.length > 0) return;
       // [(id)self.parentViewController.parentViewController stopActivityWithSuccess:(! error)];
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"couldn't make payment", nil)
                                        message:error.localizedDescription delegate:nil cancelButtonTitle:NSLocalizedString(@"ok", nil)
                              otherButtonTitles:nil] show];
            [self cancel:nil];
        }
        else {
           /* [self.view addSubview:[[[BRBubbleView viewWithText:NSLocalizedString(@"sent!", nil)
                                                        center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)]
                                    popIn] popOutAfterDelay:2.0]];
            */
            [self reset:nil];
        }
    }];
    
    if (protoReq.details.paymentURL.length > 0) {
        uint64_t refundAmount = 0;
        NSMutableData *refundScript = [NSMutableData data];
        
        // use the payment transaction's change address as the refund address, which prevents the same address being
        // used in other transactions in the event no refund is ever issued
        [refundScript appendScriptPubKeyForAddress:m.wallet.changeAddress];
        
        for (NSNumber *amount in protoReq.details.outputAmounts) {
            refundAmount += [amount unsignedLongLongValue];
        }
        
        // TODO: keep track of commonName/memo to associate them with outputScripts
        BRPaymentProtocolPayment *payment =
        [[BRPaymentProtocolPayment alloc] initWithMerchantData:protoReq.details.merchantData
                                                  transactions:@[self.tx] refundToAmounts:@[@(refundAmount)] refundToScripts:@[refundScript] memo:nil];
        
        NSLog(@"posting payment to: %@", protoReq.details.paymentURL);
        
        [BRPaymentRequest postPayment:payment to:protoReq.details.paymentURL timeout:20.0
                           completion:^(BRPaymentProtocolACK *ack, NSError *error) {
   //                            [(id)self.parentViewController.parentViewController stopActivityWithSuccess:(! error)];
                               
                               if (error && ! [m.wallet transactionIsRegistered:self.tx.txHash]) {
                                   [[[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
                                   [self cancel:nil];
                               }
                               else {
            /*                       [self.view
                                    addSubview:[[[BRBubbleView
                                                  viewWithText:(ack.memo.length > 0 ? ack.memo : NSLocalizedString(@"sent!", nil))
                                                  center:CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2)] popIn]
                                                popOutAfterDelay:(ack.memo.length > 10 ? 3.0 : 2.0)]];
              */
                                   [self reset:nil];
                                   
                                   if (error) NSLog(@"%@", error.localizedDescription); // transaction was sent despite pay protocol error
                               }
                           }];
    }
}

- (IBAction)reset:(id)sender
{
    if (self.navigationController.topViewController != self.parentViewController.parentViewController) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    
    if (self.clearClipboard) [[UIPasteboard generalPasteboard] setString:@""];
    [self cancel:sender];
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
