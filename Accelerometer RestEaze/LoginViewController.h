//
//  LoginViewController.h
//  REST EAZE
//
//  Created by Amitanshu Jha on 2/10/15.
//  Copyright (c) 2015 Amitanshu Jha. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *lastNameTextField;
@property(nonatomic) NSString *name;

- (IBAction)buttonDoneClick:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;


@end
