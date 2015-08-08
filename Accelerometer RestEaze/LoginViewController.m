//
//  LoginViewController.m
//  REST EAZE
//
//  Created by Amitanshu Jha on 2/10/15.
//  Copyright (c) 2015 Amitanshu Jha. All rights reserved.
//

#import "LoginViewController.h"
#import "FirstViewController.h"

@interface LoginViewController ()<UITextFieldDelegate>

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //_firstNameTextField.delegate = self;
    //_lastNameTextField.delegate = self;
    // Do any additional setup after loading the view.
    
    _firstNameTextField.delegate = self;
    _lastNameTextField.delegate = self;

    
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSString *username =[[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    NSString *defaultLeg =[[NSUserDefaults standardUserDefaults] stringForKey:@"default_leg"];
    NSString *lastName =[[NSUserDefaults standardUserDefaults] stringForKey:@"last_name"];
    NSString *firstName =[[NSUserDefaults standardUserDefaults] stringForKey:@"first_name"];
    
    if(username!=nil && defaultLeg!=nil){
        [self performSegueWithIdentifier:@"showTabbar" sender:nil];
    }
    if(username!=nil && defaultLeg==nil && lastName!=nil && firstName!=nil){
        [_firstNameTextField setText:firstName];
        [_lastNameTextField setText:lastName];
    }
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
//    [vc setModalPresentationStyle:UIModalPresentationFullScreen];
//    
//    [self presentModalViewController:vc animated:YES];
}

#pragma mark -
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField:textField up:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField:textField up:NO];
}

-(void)animateTextField:(UITextField*)textField up:(BOOL)up
{
    const int movementDistance = -130; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? movementDistance : -movementDistance);
    
    [UIView beginAnimations: @"animateTextField" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
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
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"LoginToTabbar"])
    {
        NSString *fname = [self.firstNameTextField text];
        NSString *lname = [self.lastNameTextField text];
        NSString *default_leg;
        if(_segmentedControl.selectedSegmentIndex==0)
        {
            default_leg = @"Left";
        }else{
            default_leg = @"Right";
        }
        if(![lname isEqualToString:@""]){
            self.name = [fname stringByAppendingString:[NSString stringWithFormat:@" %@",lname]];
        } else {
            self.name = fname;
        }
        [[NSUserDefaults standardUserDefaults] setObject:[self.name lowercaseString] forKey:@"username"];
        [[NSUserDefaults standardUserDefaults] setObject:default_leg forKey:@"default_leg"];
        [[NSUserDefaults standardUserDefaults] setObject:lname forKey:@"last_name"];
        [[NSUserDefaults standardUserDefaults] setObject:fname forKey:@"first_name"];
        [_firstNameTextField resignFirstResponder];
        [_lastNameTextField resignFirstResponder];
        
//        fname = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    }
}
- (IBAction)buttonDoneClick:(id)sender {
    NSString *fname = [self.firstNameTextField text];
    if([fname isEqualToString:@""]){
        UIAlertView *firstNameError = [[UIAlertView alloc]
                                             initWithTitle:@"First Name!" message:[NSString stringWithFormat:@"Please enter first name!"]
                                             delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        // Display this message.
        [firstNameError show];
    }
    else {
        [self performSegueWithIdentifier:@"LoginToTabbar" sender:sender];
    }
    
}
@end
