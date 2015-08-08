//
//  FourthViewController.h
//  REST EAZE
//
//  Created by Amitanshu Jha on 12/30/14.
//  Copyright (c) 2014 Amitanshu Jha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "LocationTracker.h"
#import "sqlite3.h"

@interface FourthViewController : UIViewController<UITextFieldDelegate,UIAccelerometerDelegate>


- (IBAction)uploadFileToServer:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *nowRecordingLabel;
@property (weak, nonatomic) IBOutlet UILabel *presStopLabel;

@property (strong, nonatomic) IBOutlet UIButton *uploadButton;
@property (strong, nonatomic) IBOutlet UITextField *sampleRateTextBox;
@property (strong, nonatomic) IBOutlet UIButton *stopAccButton;
@property (strong, nonatomic) IBOutlet UIButton *startAccButton;
@property (strong, nonatomic) IBOutlet UILabel *sampleLabel;
@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) IBOutlet UISegmentedControl *legSegmentedControl;

@property (strong, nonatomic) NSString *legPlacement;


@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic) UIBackgroundTaskIdentifier* bgTaskID;

@property (strong) NSMutableArray *accContent;
@property (strong) NSMutableArray *gyroContent;

@property (strong) NSString *accPrevTime;
@property (strong) NSString *gyroPrevTime;
@property (strong) NSString *accX;
@property (strong) NSString *accY;
@property (strong) NSString *accZ;
@property (strong) NSString *gyroX;
@property (strong) NSString *gyroY;
@property (strong) NSString *gyroZ;
@property (strong) NSString *acctimeStamp;
@property (strong) NSString *gyrotimeStamp;
@property (strong) NSString *accOrientationValue;
@property (strong) NSString *gyroOrientationValue;
@property (strong) NSString *accRootMeanVal;
@property (strong) NSString* accHH;
@property (strong) NSString* accMM;
@property (strong) NSString* accSS;
@property (strong) NSString* gyroHH;
@property (strong) NSString* gyroMM;
@property (strong) NSString* gyroSS;
@property (strong) NSString *gyroStrVal;
@property (strong) NSString *accStrVal;


@property LocationTracker * locationTracker;
@property (nonatomic) NSTimer* locationUpdateTimer;
@property (nonatomic) NSTimer* accelerometerTimer;
@property (nonatomic) NSTimer* writeToFileTimer;
@property (nonatomic) NSTimer* uploadTempFileTimer;
@property (nonatomic) NSTimer* accPushTimer;
//@property (nonatomic) NSTimer* gyroscopeTimer;

//database
@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *myDataBase;

@end

