//
//  AWInitViewController.m
//  Aegis Bitcoin Wallet
//
//  Created by Bojan Simic on 6/20/14.
//  Copyright (c) 2014 Bojan Simic. All rights reserved.
//

#import "AWInitViewController.h"
#import "NJOPasswordStrengthEvaluator.h"

@interface AWInitViewController ()

@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UITextField *passwordConfirmField;

@property (nonatomic, strong) IBOutlet UIView *backgroundView;
@property (nonatomic, strong) IBOutlet UILabel *welcomeTextView;
@property (nonatomic, strong) IBOutlet UILabel *walletNameTextView;
@property (nonatomic, strong) IBOutlet UILabel *enterPasswordTextView;

@property (nonatomic, strong) IBOutlet UILabel *passwordStrengthLabel;
@property (nonatomic, strong) IBOutlet UIButton *continueButton;

@end

@implementation AWInitViewController


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
    [self.passwordField setFont:[UIFont fontWithName:@"Neustadt-Regular" size:15]];
    [self.passwordConfirmField setFont:[UIFont fontWithName:@"Neustadt-Regular" size:15]];
    
    [self.welcomeTextView setFont:[UIFont fontWithName:@"Neustadt-Regular" size:20]];
    [self.walletNameTextView setFont:[UIFont fontWithName:@"Neustadt-Regular" size:20]];
    [self.enterPasswordTextView setFont:[UIFont fontWithName:@"Neustadt-Regular" size:17]];
    
    [self.passwordStrengthLabel setFont:[UIFont fontWithName:@"Neustadt-Regular" size:15]];
    
    [self.passwordField resignFirstResponder];
    
    self.passwordField.delegate = self;
    self.passwordConfirmField.delegate = self;
    
    self.continueButton.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"light_honeycomb.png"]];
    self.backgroundView.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"light_honeycomb.png"]];

    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)handleButtonClick:(id)sender
{
    NSString *password = [self.passwordField text];
    NSString *passwordConfirm = [self.passwordConfirmField text];
    
    NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:password];

    if(![password isEqualToString:passwordConfirm]){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Passwords do not match!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else if(strength < 3){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Weak Password"
                                                        message:@"Please choose a secure password! It should be long, hard to predict, and contain digits, special characters, lower and upper case letters."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        
    }
    
    
    
    
}

- (IBAction) passwordTextFieldChanged:(id)sender
{
    NSString *passwordValue = [self.passwordField text];
    
    NJOPasswordStrength strength = [NJOPasswordStrengthEvaluator strengthOfPassword:passwordValue];
    [self.passwordStrengthLabel setText:[NJOPasswordStrengthEvaluator localizedStringForPasswordStrength:strength]];
    
    NSLog(@"Strength: %d", strength);
    NSLog(@"%@", [NJOPasswordStrengthEvaluator localizedStringForPasswordStrength:strength]);
    NSLog(@"%@", passwordValue);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.passwordField || textField == self.passwordConfirmField) {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    //hides keyboard when another part of layout was touched
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
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
