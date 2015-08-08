//
//  FourthViewController.m
//  REST EAZE
//
//  Created by Amitanshu Jha on 12/30/14.
//  Copyright (c) 2014 Amitanshu Jha. All rights reserved.
//
#include <sys/xattr.h>
#import "FourthViewController.h"
//#import "ZipArchive.h"
#import "sqlite3.h"

@implementation FourthViewController

#define CHUNK_SIZE 15000000
#define TimeStamp [[NSDate date] timeIntervalSince1970]
UIApplication *app;
NSTimer * myTimer;
NSString *tempFileToBeStored = @"sampledata.txt";
NSString *todaysUserFileName;
//NSString *username;
NSString *fileToBeWritten;
int inputSampleRate = 20;
bool backgroundUploadInProgress = false;
int gyroRepeatcount = 0;
int accRepeatcount = 0;

int accSampleCount = 0;
int gyroSampleCount = 0;

int frequencyVal = 25;
//load data global variables
float kFilteringFactor = 0.2;
float accelX =0;
float accelY =0;
float accelZ =0;
float xValue =0;
float yValue =0;
float zValue =0;
//double accPrevTime = 0;
//double gyroPrevTime = 0;


NSDate *startTime;
NSDate *currentTime;
NSTimeInterval upTimeInterval;

NSLock *arrayLock;
NSMutableIndexSet *discardedItems;
NSUInteger length;
NSString * accTempStr;
NSArray * linesAccelerometer;
NSArray * linesGyro;
NSString * gyrotempStr;
NSString *stmnt;
const char *sqlStatement;
sqlite3_stmt *compiledStatement;
NSString *stmnt1;
const char *sqlStatement1;
sqlite3_stmt *compiledStatement1;
bool writingToDB = false;
const char* pragmaSql;
NSString *createTable1;
const char *createTableStatement1;
char* errorCreatingTable;


//upload to server
NSString *tableName;
int numberOfRows =0;
int count=0;
int retVal;
int nextLimit=0;
NSString *count_statement;
NSString *sql_statement;
NSString* tempStr;
NSString* str;
sqlite3_stmt* statement;
UIAlertView *alert;
sqlite3_stmt* countStatement;
NSString *sql;
const char *del_stmt;
bool uploadInProgress = false;
bool isSensorStopped = true;
bool firstTime = true;
bool uploadButtonClicked = false;
int current=1;
int final=1;
NSString *pendingId;

sqlite3_stmt* deleteStmt;
NSString *name;
NSString *response;
NSString *table_statementUploadServer;
sqlite3_stmt* tableStatementUploadServer;

//variables for accelerometer timer method
//gets called every minute
UIDeviceOrientation orientationGyro;
UIDeviceOrientation orientationAcc;
NSArray* fooAcc;
NSArray* fooGyro;
NSLock *arrayLock1;
NSLock *arrayLock2;
float rootMeanSquareOfAccelerometer;
double referenceTimestamp;
double timestampAcc;
double timestampGyro;
NSDate *dateGyro;
NSString *newTimeGyro;
NSDate *dateAcc;
NSString *newTimeAcc;
NSDateFormatter *timeFormatterValAcc;
NSDateFormatter *timeFormatterValGyro;

//updateUploadButton global variables
int numberOfRowsUploadStatus =0;
NSString *tableNameInDB;
NSString *countStmtInTable;
sqlite3_stmt* countStatementVar;
int retValUploadStatus;
NSString *table_statementUploadStatus;
sqlite3_stmt* tableStatementUploadStatus;


//check orientation
#define kLowPassFilteringFactor 0.1
#define MOVEMENT_HZ 50
#define NOISE_REDUCTION 0.05
double previousLowPassFilteredAccelerationX;
double previousLowPassFilteredAccelerationY;
double previousLowPassFilteredAccelerationZ;
float accelerationX;
float accelerationY;
float angle_rad;
float angle_deg;
double lowpassFilterAccelerationX, lowpassFilterAccelerationY;
NSNumberFormatter * numberFormatter;
int orientationSampleCounter = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    _accOrientationValue = @"2"; //Portrait - leg position standing
    _gyroOrientationValue = @"2";
    // Bind the accelerometer events to our instance
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    
    previousLowPassFilteredAccelerationX = previousLowPassFilteredAccelerationY = previousLowPassFilteredAccelerationZ = 0.0;
//    [self checkOrientation];
    
    [self removeOlderFiles];
    [self createDatabaseConnection];
    self.locationTracker = [[LocationTracker alloc]init];
    upTimeInterval = [NSProcessInfo processInfo].systemUptime;
    referenceTimestamp = TimeStamp  - upTimeInterval;
    
//    self.writeToFileTimer =
//    [NSTimer scheduledTimerWithTimeInterval:60.0
//                                     target:self
//                                   selector:@selector(writeORUpload)
//                                   userInfo:nil
//                                    repeats:YES];
    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonDidPressed:)];
    UIBarButtonItem *flexableItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[self class] toolbarHeight])];
    [toolbar setItems:[NSArray arrayWithObjects:flexableItem,doneItem, nil]];
    _sampleRateTextBox.inputAccessoryView = toolbar;

}

- (void)viewDidUnload {
    [super viewDidUnload];
    sqlite3_close(_myDataBase);
}

- (void)errorCreatingTable:(NSString *)errorMsg
{
    NSLog(@"%@", errorMsg);
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTodaysTempUserFileName];
    [self setTodaysUserFileName];
    [self getUserName];
    
    //database
//    [self createDatabaseConnection];
    [self updateUploadStatus];
    
    _sampleRateTextBox.delegate = self;

}

- (void)doneButtonDidPressed:(id)sender {
    [_sampleRateTextBox resignFirstResponder];
}

+ (CGFloat)toolbarHeight {
    // This method will handle the case that the height of toolbar may change in future iOS.
    return 44.f;
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

//text field delegate method ends


- (void) updateUploadStatus{
    if(uploadInProgress==false && isSensorStopped==true){
    [self getUserName];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data.db",_username]];
//    
//    _databasePath = filePath;
//    int numberOfRows = 0;
//    const char *dbPath = [_databasePath UTF8String];
//    if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
    
        table_statementUploadStatus=[[NSString alloc]initWithFormat:@"SELECT name FROM sqlite_master WHERE type=\'table\'"];
    
        retValUploadStatus = sqlite3_prepare_v2(_myDataBase,
                                        [table_statementUploadStatus UTF8String],
                                        -1,
                                        &tableStatementUploadStatus,
                                        NULL);
        
        if ( retValUploadStatus == SQLITE_OK )
        {
            numberOfRowsUploadStatus =0;
            while(sqlite3_step(tableStatementUploadStatus) == SQLITE_ROW )
            {
                tableNameInDB = [NSString stringWithCString:(const char *)sqlite3_column_text(tableStatementUploadStatus, 0)
                                                         encoding:NSUTF8StringEncoding];
                
                if(![tableNameInDB isEqualToString:@"sqlite_sequence"] && ![[tableNameInDB substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"a"])
                {
                    pendingId =[[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"%@%@",_username,tableNameInDB]];
                    if(pendingId!=nil){
                        countStmtInTable=[[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@ WHERE ID>%@",tableNameInDB,pendingId];
                    }else{
                        countStmtInTable=[[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@",tableNameInDB];
                    }
                    
                    
                    if( sqlite3_prepare_v2(_myDataBase,[countStmtInTable UTF8String],-1,&countStatementVar,NULL) == SQLITE_OK )
                    {
                        //Loop through all the returned rows (should be just one)
                        while( sqlite3_step(countStatementVar) == SQLITE_ROW )
                        {
                            numberOfRowsUploadStatus += sqlite3_column_int(countStatementVar, 0);
                        }
                        
                    }
                    else
                    {
                        NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(_myDataBase) );
                    }
                    
                    // Finalize and close database.
                    sqlite3_clear_bindings(countStatementVar);
                    sqlite3_finalize(countStatementVar);
                    if(numberOfRowsUploadStatus>0){
                        break;
                    }
                }
            }
        }
        
        sqlite3_clear_bindings(tableStatementUploadStatus);
        sqlite3_finalize(tableStatementUploadStatus);
        
//        sqlite3_close(_myDataBase);
//    }

    if(numberOfRowsUploadStatus == 0){
        self.uploadButton.hidden = true;
    } else{
        self.uploadButton.hidden = false;
    }
    }
}

- (BOOL)addSkipBackupAttributeToItemAtURL:(const char * )filePath
{
    //const char* filePath = [[URL path] fileSystemRepresentation];
    
    const char * attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag ==1){
        if (buttonIndex == 2) { // means no button pressed
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
            [self performSegueWithIdentifier:@"SettingsToLogin" sender:nil];
        }
        if(buttonIndex == 1) { // means Yes button pressed
            NSString *default_leg =[[NSUserDefaults standardUserDefaults] stringForKey:@"default_leg"];
            [self getLeg];
            if(![_legPlacement isEqualToString:default_leg]){
                UIAlertView *alert = [[UIAlertView alloc]
                                      
                                      initWithTitle:@"Default Leg doesn't match your current selection"
                                      message:[NSString stringWithFormat:@"\nDefault leg for the app: %@ Leg.\nYour current selection: %@ Leg.\nDo you want to continue?",default_leg,_legPlacement]
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Yes", @"Change Default" , nil];
                [alert setTag:3];
                [alert show];
            }else{
                UIAlertView *alert = [[UIAlertView alloc]
                                      
                                      initWithTitle:[NSString stringWithFormat:@"You have selected %@ leg",_legPlacement]
                                      message:@"\nDo you want to continue?"
                                      delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"Yes", nil];
                [alert setTag:4];
                [alert show];
            }
//            [self start];
        }
    }
    else if(alertView.tag==2){
        if(buttonIndex == 1) { // means Yes button pressed
            [self stop];
        }
    } else if(alertView.tag==3){
        if(buttonIndex == 1) { // means Yes button pressed
            [self start];
        }else if (buttonIndex==2){// means Change Default button pressed
//            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"username"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"default_leg"];
            [self performSegueWithIdentifier:@"SettingsToLogin" sender:nil];
        }
    } else if(alertView.tag==4){
        if(buttonIndex == 1) { // means Yes button pressed
            [self start];
        }
    }
}
- (IBAction)startAccelerometer:(id)sender {
    [self setLeg];
    UIAlertView *alert = [[UIAlertView alloc]
                          
                          initWithTitle:@"Account Verification"
                          message:[NSString stringWithFormat:@"\nAre you %@ ?",_username]
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Yes", @"No" , nil];
    [alert setTag:1];
    [alert show];
}

- (void) start{
    UIAlertView * alert;
    //Get Current Time when accelerometer starts
    startTime = [NSDate date];
    isSensorStopped = false;
    self.uploadButton.hidden = true;
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    dateFormatter.dateFormat = @"hh:mm:ss";
//    NSString* startTime = [dateFormatter stringFromDate:now];
    
    self.startAccButton.hidden = true;
    self.stopAccButton.hidden = false;
    //now recording text visibility
    self.nowRecordingLabel.hidden = false;
    self.presStopLabel.hidden = false;
    
    self.sampleRateTextBox.hidden = true;
//    [self setLeg];
    self.legSegmentedControl.hidden = true;
    [_sampleRateTextBox resignFirstResponder];
    self.sampleLabel.hidden = true;
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        _accContent = [[NSMutableArray alloc] init];
        _gyroContent = [[NSMutableArray alloc] init];
        
        firstTime = true;
//        _accPrevTime=@"abc";
//        _gyroPrevTime=@"abc";
        
//        self.locationTracker = [[LocationTracker alloc]init];
        [self.locationTracker startLocationTracking];
        
        
        if(![_sampleRateTextBox.text  isEqualToString: @""]){
            frequencyVal = [_sampleRateTextBox.text intValue] + 15;
            inputSampleRate = [_sampleRateTextBox.text intValue];
        }
//        sqlite3_close(_myDataBase);
        //[self createDatabaseConnection];
        
        
        //Send the best location to server every 60 seconds
        NSTimeInterval time = 60.0;
        self.locationUpdateTimer =
        [NSTimer scheduledTimerWithTimeInterval:time
                                         target:self
                                       selector:@selector(updateLocation)
                                       userInfo:nil
                                        repeats:YES];
        [self loadData];
        self.accelerometerTimer =
        [NSTimer scheduledTimerWithTimeInterval:60.0
                                         target:self
                                       selector:@selector(loadData)
                                       userInfo:nil
                                        repeats:YES];
        
        
        self.writeToFileTimer =
        [NSTimer scheduledTimerWithTimeInterval:30.0
                                         target:self
                                       selector:@selector(writeORUpload)
                                       userInfo:nil
                                        repeats:YES];
        self.accPushTimer =
        [NSTimer scheduledTimerWithTimeInterval:3600.0
                                         target:self
                                       selector:@selector(checkTimeSendPush)
                                       userInfo:nil
                                        repeats:YES];
        self.uploadTempFileTimer =
        [NSTimer scheduledTimerWithTimeInterval:54.0 target:self selector:@selector(uploadToServer) userInfo:nil repeats:YES];
        
//        [self checkOrientation];

    }
}

- (void) createDatabaseConnection
{
    [self setTodaysUserFileName];
    [self setTodaysTempUserFileName];
    NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [path objectAtIndex:0];
    //NSString *tempDataFilePath = [documentsDirectory stringByAppendingPathComponent:fileToBeWritten];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:_username];
    NSError *error;
    if (![fileManager fileExistsAtPath:dataPath])
    {
        [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
    }
    
    self.databasePath = [NSString stringWithFormat:@"%@/data.db",dataPath];
    
//    sqlite3_close(_myDataBase);
    // create DB if it does not already exists
    if (![fileManager fileExistsAtPath:self.databasePath]) {
        
        const char *dbPath = [self.databasePath UTF8String];
        if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
            NSLog(@"Database open..");
//            char *errorMsg;
//            NSString *sql_statement=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", todaysUserFileName];
//            const char *statement = [sql_statement UTF8String];
//            if (sqlite3_exec(_myDataBase, statement, NULL, NULL, &errorMsg) != SQLITE_OK) {
//                
//                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorMsg]];
//            }
//            sql_statement=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", tempFileToBeStored];
//            statement = [sql_statement UTF8String];
//            if (sqlite3_exec(_myDataBase, statement, NULL, NULL, &errorMsg) != SQLITE_OK) {
//                
//                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorMsg]];
//            }
//            sqlite3_close(_myDataBase);
            
        } else {
            
            [self errorCreatingTable:@"failed openning / creating table"];
        }
    } else{
        
        
        const char *dbPath = [self.databasePath UTF8String];
        
        if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
            NSLog(@"Database open..");
            
            pragmaSql = "PRAGMA cache_size = 50";
            if (sqlite3_exec(_myDataBase, pragmaSql, NULL, NULL, NULL) != SQLITE_OK) {
                NSAssert1(0, @"Error: failed to execute pragma statement with message '%s'.", sqlite3_errmsg(_myDataBase));
            }
//            char *errorMsg;
//            NSString *sql_statement=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", todaysUserFileName];
//            const char *statement = [sql_statement UTF8String];
//            if (sqlite3_exec(_myDataBase, statement, NULL, NULL, &errorMsg) != SQLITE_OK) {
//                
//                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorMsg]];
//            }
//            
//            sql_statement=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", tempFileToBeStored];
//            statement = [sql_statement UTF8String];
//            if (sqlite3_exec(_myDataBase, statement, NULL, NULL, &errorMsg) != SQLITE_OK) {
//                
//                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorMsg]];
//            }
        }
    }
    
}

- (void) checkTimeSendPush
{
    currentTime = [NSDate date];
    NSTimeInterval distanceBetweenDates = [currentTime timeIntervalSinceDate:startTime];
    double secondsInAnHour = 3600;
    NSInteger hoursBetweenDates = distanceBetweenDates / secondsInAnHour;
    if(hoursBetweenDates>=10){
        NSString *deviceToken =[[NSUserDefaults standardUserDefaults] stringForKey:@"deviceToken"];
        if(deviceToken!=nil){
           NSString *urlString = [NSString stringWithFormat:@"https://covail.cs.umbc.edu/rls/accelerometer/push/Prod_Push/simplepush.php?devicetoken=%@",deviceToken];
        
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString]];
            // set Request Type
            [request setHTTPMethod: @"GET"];
            // Set content-type
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        
            // Now send a request and get Response
            NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
            // Log Response
            NSString *response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",response);
        }
    }
}
- (void) writeORUpload
{
//    [self setTodaysTempUserFileName];
//    [self setTodaysUserFileName];
    if(uploadInProgress == false && writingToDB==false && _accContent && _gyroContent){
        if([_accContent count]>0 &&[_gyroContent count]>0){
        writingToDB=true;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            pragmaSql = "PRAGMA cache_size = 50";
//            if (sqlite3_exec(_myDataBase, pragmaSql, NULL, NULL, NULL) != SQLITE_OK) {
//                NSAssert1(0, @"Error: failed to execute pragma statement with message '%s'.", sqlite3_errmsg(_myDataBase));
//            }
            createTable1=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", todaysUserFileName];
            
            createTableStatement1 = [createTable1 UTF8String];
            if (sqlite3_exec(_myDataBase, createTableStatement1, NULL, NULL, &errorCreatingTable) != SQLITE_OK) {
                
                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorCreatingTable]];
            }
            
            createTable1=[[NSString alloc]initWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (ID INTEGER PRIMARY KEY AUTOINCREMENT, Accx TEXT, AccY TEXT, AccZ TEXT, RMS TEXT, Orientation TEXT, Hour TEXT, Minute TEXT, Second TEXT, Timestamp TEXT, GyroX TEXT, GyroY TEXT, GyroZ TEXT)", tempFileToBeStored];
            createTableStatement1 = [createTable1 UTF8String];
            if (sqlite3_exec(_myDataBase, createTableStatement1, NULL, NULL, &errorCreatingTable) != SQLITE_OK) {
                
                [self errorCreatingTable:[NSString stringWithFormat:@"failed creating table. ERROR:%s", errorCreatingTable]];
            }
            
            arrayLock = [[NSLock alloc] init];
            //form string from stored objects
            discardedItems = [NSMutableIndexSet indexSet];
            if(_accContent && _gyroContent){
                if([_accContent count] < [_gyroContent count]){
                    length = [_accContent count] ;
                } else {
                    length = [_gyroContent count];
                }
                if(length>0){
                    @synchronized(self){
//                    [arrayLock lock];
                    sqlite3_exec(_myDataBase, "BEGIN TRANSACTION", 0, 0, 0);
                    for (NSUInteger i =0; i< length; i++) {
                        if(uploadInProgress == false){
                            if([_accContent count]> i && [_gyroContent count]>i){
//                              [arrayLock lock];
                            
                                accTempStr = [_accContent objectAtIndex:i];
                                gyrotempStr = [_gyroContent objectAtIndex:i];
                            
//                              [arrayLock unlock];
                                if((accTempStr!=nil && ![accTempStr isEqualToString:@""]) && (gyrotempStr!=nil && ![gyrotempStr isEqualToString:@""])){
                                    linesAccelerometer = [accTempStr componentsSeparatedByString: @" "];
                                
                                    linesGyro = [gyrotempStr componentsSeparatedByString: @" "];
                                    if([linesAccelerometer count]>8 && [linesGyro count]>7){
                                        stmnt=[[NSString alloc]initWithFormat:@"insert into %@  (Accx, AccY, AccZ, RMS, Orientation, Hour, Minute, Second, Timestamp, GyroX, GyroY, GyroZ) values(\"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\")", todaysUserFileName,linesAccelerometer[1], linesAccelerometer[2], linesAccelerometer[3], linesAccelerometer[4], linesAccelerometer[5],  linesAccelerometer[6], linesAccelerometer[7], linesAccelerometer[8], linesAccelerometer[0],linesGyro[1], linesGyro[2], linesGyro[3]];
                                        sqlStatement = [stmnt UTF8String];
//                                      [arrayLock lock];
                                        if (sqlite3_prepare_v2(_myDataBase, sqlStatement,-1, &compiledStatement,NULL) == SQLITE_OK)
                                        {
                                            if (SQLITE_DONE!=sqlite3_step(compiledStatement))
                                            {
                                                NSLog(@"insertion failed");
                                            }else {
                                                NSLog(@"inserted into main: %d of %d",i,length);
                                            }
                                        } else{
                                            NSLog(@"Error inserting:  %s",sqlite3_errmsg(_myDataBase));
                                        }
                                    
                                        sqlite3_clear_bindings(compiledStatement);
                                        sqlite3_finalize(compiledStatement);
//                                      [arrayLock unlock];
                                    
                                        stmnt1=[[NSString alloc]initWithFormat:@"insert into %@  (Accx, AccY, AccZ, RMS, Orientation, Hour, Minute, Second, Timestamp, GyroX, GyroY, GyroZ) values(\"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\", \"%@\",\"%@\",\"%@\")", tempFileToBeStored,linesAccelerometer[1], linesAccelerometer[2], linesAccelerometer[3], linesAccelerometer[4], linesAccelerometer[5],  linesAccelerometer[6], linesAccelerometer[7], linesAccelerometer[8], linesAccelerometer[0],linesGyro[1], linesGyro[2], linesGyro[3]];
                                        sqlStatement1 = [stmnt1 UTF8String];
                                    
//                                      [arrayLock lock];
                                        if (sqlite3_prepare_v2(_myDataBase, sqlStatement1,-1, &compiledStatement1,NULL) == SQLITE_OK)
                                        {
                                            if (SQLITE_DONE!=sqlite3_step(compiledStatement1))
                                            {
                                                NSLog(@"insertion failed");
                                            } else {
                                                NSLog(@"inserted into temp: %d of %d",i,length);
                                            }
                                        }
                                        sqlite3_clear_bindings(compiledStatement1);
                                        sqlite3_finalize(compiledStatement1);
//                                      [arrayLock unlock];
                                    }
                                }
                                [discardedItems addIndex:i];
                            }
                        }
                        //commit transaction
                        
                    }
                    sqlite3_exec(_myDataBase, "COMMIT TRANSACTION", 0, 0, 0);
//                    [arrayLock unlock];
                    }
                    
                }
                
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if([discardedItems count]>0){
//                    [arrayLock lock];
                    @synchronized(self){
                        if([_accContent count]>=[discardedItems count])
                            [_accContent removeObjectsAtIndexes:discardedItems];
                        //                        [arrayLock unlock];
                        //                        [arrayLock lock];
                        if([_gyroContent count]>=[discardedItems count])
                            [_gyroContent removeObjectsAtIndexes:discardedItems];
                    }
                    
//                    [arrayLock unlock];
                    [arrayLock lock];
                    [discardedItems removeAllIndexes];
                    [arrayLock unlock];
                }
                writingToDB = false;
            });
        });
        }
        
//    [self updateUploadStatus];
    //[self uploadInBackground];
    }
}
- (BOOL) connectedToInternet
{
    NSString *URLString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"https://covail.cs.umbc.edu/rls/accelerometer/web/index.html"]];
    return ( URLString != NULL ) ? YES : NO;
}
- (void) uploadToServer
{
    if((writingToDB ==false || uploadButtonClicked==true )&& uploadInProgress==false && _username!=nil){
        _uploadButton.enabled = NO;
        _uploadButton.alpha = 0.6f;
        [_uploadButton setTitle:@"Uploading.." forState:UIControlStateDisabled];
        if(writingToDB==true){

            [self performSelector:@selector(uploadToServer) withObject:self afterDelay:3.0 ];
            return;
        }
        
        //[self createDatabaseConnection];
        [self getUserName];
        
        uploadInProgress = true;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            //no background operations
            if([self connectedToInternet]){
                arrayLock= [[NSLock alloc] init];
                
                table_statementUploadServer=[[NSString alloc]initWithFormat:@"SELECT name FROM sqlite_master WHERE type=\'table\'"];
                retVal = sqlite3_prepare_v2(_myDataBase,
                                            [table_statementUploadServer UTF8String],
                                            -1,
                                            &tableStatementUploadServer,
                                            NULL);
                
                if ( retVal == SQLITE_OK )
                {
                    
                    while(sqlite3_step(tableStatementUploadServer) == SQLITE_ROW )
                    {
                        tableName = [NSString stringWithCString:(const char *)sqlite3_column_text(tableStatementUploadServer, 0)
                                                       encoding:NSUTF8StringEncoding];
                        if(![tableName isEqualToString:@"sqlite_sequence"] && ![[tableName substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"a"])
                        {
                            numberOfRows = 0;
                            pendingId =[[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"%@%@",_username,tableName]];
                            if(pendingId!=nil){
                                count_statement=[[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@ WHERE ID>%@",tableName,pendingId];
                            }else{
                                count_statement=[[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@",tableName];
                            }
                            
                            //                sqlite3_stmt* countStatement;
                            
                            if( sqlite3_prepare_v2(_myDataBase,[count_statement UTF8String],-1,&countStatement,NULL) == SQLITE_OK )
                            {
                                //Loop through all the returned rows (should be just one)
                                while( sqlite3_step(countStatement) == SQLITE_ROW )
                                {
                                    numberOfRows = sqlite3_column_int(countStatement, 0);
                                }
                            }
                            else
                            {
                                NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(_myDataBase) );
                            }
                            
                            // Finalize and close database.
                            
                            sqlite3_clear_bindings(countStatement);
                            sqlite3_finalize(countStatement);
                            if(numberOfRows!=0){
//                                sql_statement=[[NSString alloc]initWithFormat:@"SELECT * FROM %@",tableName];
//                                pendingId =[[NSUserDefaults standardUserDefaults] stringForKey:tableName];
                                if(pendingId!=nil){
                                    sql_statement=[[NSString alloc]initWithFormat:@"SELECT * FROM %@ WHERE ID>%@",tableName,pendingId];
                                }else{
                                    sql_statement=[[NSString alloc]initWithFormat:@"SELECT * FROM %@",tableName];
                                }
                                
                                retVal = sqlite3_prepare_v2(_myDataBase,
                                                            [sql_statement UTF8String],
                                                            -1,
                                                            &statement,
                                                            NULL);
                                tempStr = @"";
                                if ( retVal == SQLITE_OK )
                                {
                                    current =1;
                                    final = (numberOfRows/3000)+1;
                                    count = 0;
                                    nextLimit = 3000;
                                    while(sqlite3_step(statement) == SQLITE_ROW )
                                    {
                                        count++;
                                        
                                        str = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@\n",[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 5) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 6) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 7) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 8) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 9) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 10) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 11) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 12) encoding:NSUTF8StringEncoding] ];
                                        
                                        
                                        tempStr = [tempStr stringByAppendingString:str];
                                        if((nextLimit > numberOfRows) && (count == numberOfRows)){
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [_uploadButton setTitle:[NSString stringWithFormat:@"Uploading.. %d of %d",current,final] forState:UIControlStateDisabled];
                                            });
                                            
                                            response = [self uploadDataTableToServer:tempStr :tableName];
                                            NSLog(@"%@",response);
                                            name = [NSString stringWithFormat:@"%@.txt",[tableName substringFromIndex:1]];
                                            if(response!=nil && ![response isEqual:@""] && ![response isEqual:@" \n"] && ![response isEqual:@"Received file: \n"] &&[response isEqual:[NSString stringWithFormat:@"Received file: %@ \n", name]]){
                                                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] forKey:tableName];
                                                sql = [NSString stringWithFormat:@"delete from %@ where ID<=%d",tableName, [[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] intValue]];
                                                del_stmt = [sql UTF8String];
                                                //                                    sqlite3_stmt* deleteStmt;
                                                //                                    NSLock *arrayLock = [[NSLock alloc] init];
                                                [arrayLock lock];
                                                sqlite3_prepare_v2(_myDataBase, del_stmt, -1, & deleteStmt, NULL);
                                                if (sqlite3_step(deleteStmt) == SQLITE_DONE)
                                                {
                                                    
                                                    NSLog(@"deleted");
                                                    tempStr= @"";
                                                    //                                        alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Upload successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                    //                                        [alert show];
                                                } else {
                                                    
                                                    NSLog(@"failed");
                                                    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] forKey:[NSString stringWithFormat:@"%@%@",_username,tableName]];
                                                    
                                                    if(uploadButtonClicked ==true){
                                                        alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Deletion from device not successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                                                        [alert show];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            [alert show];
                                                        });
                                                        break;
                                                    }
                                                }
                                                [arrayLock unlock];
                                                
                                                sqlite3_clear_bindings(deleteStmt);
                                                sqlite3_finalize(deleteStmt);
                                            } else {
                                                if(uploadButtonClicked==true){
                                                alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Upload not successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                                                [alert show];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [alert show];
                                                    });
                                                }
                                                break;
                                            }
                                        }
                                        if(count==nextLimit){
//                                            [_uploadButton setTitle:@"Uploading.. 121" forState:UIControlStateDisabled];
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [_uploadButton setTitle:[NSString stringWithFormat:@"Uploading.. %d of %d",current,final] forState:UIControlStateDisabled];
                                            });
                                            
                                            current++;
                                            response = [self uploadDataTableToServer:tempStr :tableName];
                                            NSLog(@"%@",response);
                                            name = [NSString stringWithFormat:@"%@.txt",[tableName substringFromIndex:1]];
                                            if(response!=nil && ![response isEqual:@""] && ![response isEqual:@" \n"] && ![response isEqual:@"Received file: \n"] &&[response isEqual:[NSString stringWithFormat:@"Received file: %@ \n", name]]){
                                                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] forKey:tableName];
                                                
                                                sql = [NSString stringWithFormat:@"delete from %@ where ID<=%d",tableName, [[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] intValue]];
                                                del_stmt = [sql UTF8String];
                                                //                                    sqlite3_stmt* deleteStmt;
                                                //                                    NSLock *arrayLock = [[NSLock alloc] init];
                                                [arrayLock lock];
                                                sqlite3_prepare_v2(_myDataBase, del_stmt, -1, & deleteStmt, NULL);
                                                if (sqlite3_step(deleteStmt) == SQLITE_DONE)
                                                {
                                                    NSLog(@"deleted");
                                                } else {
                                                    NSLog(@"failed");
                                                    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] forKey:[NSString stringWithFormat:@"%@%@",_username,tableName]];
                                                    if(uploadButtonClicked ==true){
                                                        alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Deletion from device not successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            [alert show];
                                                        });
//                                                        [alert show];
                                                    }
                                                    break;
                                                    
                                                }
                                                [arrayLock unlock];
                                                sqlite3_clear_bindings(deleteStmt);
                                                sqlite3_finalize(deleteStmt);
                                                nextLimit +=3000;
                                                tempStr=@"";
                                            } else {
                                                if(uploadButtonClicked==true){
                                                alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Upload not successful" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                                                [alert show];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [alert show];
                                                    });
                                                }
                                                break;
                                            }
                                        }
                                    }
                                }
                                sqlite3_clear_bindings(statement);
                                sqlite3_finalize(statement);
                            }
                        }
                    }
                }
                
                sqlite3_clear_bindings(tableStatementUploadServer);
                sqlite3_finalize(tableStatementUploadServer);
            }else{
                if(uploadButtonClicked==true){
                alert = [[UIAlertView alloc] initWithTitle:@"Alert"                                                                                                            message:@"Network Error!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                [alert show];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                    });
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _uploadButton.enabled = YES;
                uploadInProgress = false;
                @synchronized(self){
                    [self updateUploadStatus];
                }
                uploadButtonClicked = false;
                _uploadButton.alpha = 1;
            });
        });
    
    }
}

-(void)updateLocation {
    NSLog(@"updateLocation");
    
    [self.locationTracker updateLocationToServer];
}

- (void) setTodaysUserFileName
{
    [self getLeg];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"MM_dd_yyyy"];
    NSString *todaysDate = [timeFormatter stringFromDate:[[NSDate alloc]init] ];
    
    todaysUserFileName = [NSString stringWithFormat:@"a%@_%@",todaysDate,_legPlacement];
//    todaysUserFileName = [NSString stringWithFormat:@"%@_%@.txt",todaysDate,_legPlacement];

}

//set todays (current) temporary file name
- (void) setTodaysTempUserFileName
{
    [self getLeg];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"MM_dd_yyyy"];
    NSString *todaysDate = [timeFormatter stringFromDate:[[NSDate alloc]init] ];
    
    tempFileToBeStored = [NSString stringWithFormat:@"t%@_%@",todaysDate,_legPlacement];
    
}
//set todays (current) temporary file name
- (void) getUserName
{
    _username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
 
}
- (void) getLeg
{
    _legPlacement = [[NSUserDefaults standardUserDefaults] stringForKey:@"bandPlacement"];
}
- (void) setLeg
{
    if([_legSegmentedControl selectedSegmentIndex] ==0){
        [[NSUserDefaults standardUserDefaults] setObject:@"Left" forKey:@"bandPlacement"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@"Right" forKey:@"bandPlacement"];
    }
}


- (void) loadData
{
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 1.0/frequencyVal;
    self.motionManager.gyroUpdateInterval = 1.0/frequencyVal;
    [self getUserName];
    [self setTodaysUserFileName];
    [self setTodaysTempUserFileName];
    

    arrayLock1 = [[NSLock alloc] init];
    arrayLock2 = [[NSLock alloc] init];
    
    
    [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
                                             withHandler:^(CMAccelerometerData  *accelerometerData, NSError *error) {
            _acctimeStamp = [NSString stringWithFormat:@"%.2f",accelerometerData.timestamp];
//            if(isSensorStopped==false && firstTime==true){
//                firstTime= false;
//                referenceTimestamp = TimeStamp  - upTimeInterval;
//            }
                                                 
            timestampAcc = referenceTimestamp + accelerometerData.timestamp;
//            timestampAcc = timestampAcc + accelerometerData.timestamp;
            timeFormatterValAcc = [[NSDateFormatter alloc] init];
            [timeFormatterValAcc setDateFormat:@"HH:mm:ss"];
//            timestampAcc = [_acctimeStamp integerValue];
            dateAcc = [NSDate dateWithTimeIntervalSince1970:timestampAcc];
            newTimeAcc = [timeFormatterValAcc stringFromDate:dateAcc];
                                                 
//            if((accelerometerData.timestamp - accPrevTime) > 1){
            if(![newTimeAcc isEqualToString:_accPrevTime]){
//                accPrevTime = accelerometerData.timestamp;
                _accPrevTime = newTimeAcc;
                accRepeatcount =0;
                fooAcc = [newTimeAcc componentsSeparatedByString: @":"];
                _accHH = [fooAcc objectAtIndex: 0];
                _accMM = [fooAcc objectAtIndex: 1];
                _accSS = [fooAcc objectAtIndex: 2];
                
//                accelX = (accelerometerData.acceleration.x * kFilteringFactor) + (accelX * (1.0 - kFilteringFactor));
//                accelY = (accelerometerData.acceleration.y * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor));
//                accelZ = (accelerometerData.acceleration.z * kFilteringFactor) + (accelZ * (1.0 - kFilteringFactor));
                accelX = accelerometerData.acceleration.x * 9.80665f * kFilteringFactor + accelX * (1.0 - kFilteringFactor);
                accelY = accelerometerData.acceleration.y *  9.80665f * kFilteringFactor + accelY * (1.0 - kFilteringFactor);
                accelZ = accelerometerData.acceleration.z *  9.80665f * kFilteringFactor + accelZ * (1.0 - kFilteringFactor);
                
                xValue = (accelerometerData.acceleration.x * 9.80665f) - accelX;
                
                yValue = (accelerometerData.acceleration.y * 9.80665f) - accelY;
                zValue= (accelerometerData.acceleration.z * 9.80665f) - accelZ;
                
                _accX = [NSString stringWithFormat:@"%f",xValue];
                _accY = [NSString stringWithFormat:@"%f",yValue];
                _accZ = [NSString stringWithFormat:@"%f",zValue];
                                                     
                rootMeanSquareOfAccelerometer = sqrtf((([_accX floatValue] * [_accX floatValue]) + ([_accY floatValue] * [_accY floatValue]) + ([_accZ floatValue] * [_accZ floatValue]))/3);
                _accRootMeanVal = [[NSNumber numberWithFloat:rootMeanSquareOfAccelerometer] stringValue];
                                                     
//                orientationAcc = [[UIDevice currentDevice] orientation];
//                if (orientationAcc == UIDeviceOrientationPortrait || orientationAcc == UIDeviceOrientationPortraitUpsideDown){
//                    //NSLog(@"portrait");
//                    _accOrientationValue = @"2"; //Portrait - leg position standing
//                }else{
//                    //NSLog(@"landscape");
//                    _accOrientationValue = @"1"; //Landscape  - Leg position sleeping
//                }
                _accStrVal = [NSString stringWithFormat:@"%0.2f %@ %@ %@ %@ %@ %@ %@ %@", timestampAcc, _accX, _accY,_accZ, _accRootMeanVal,_accOrientationValue, _accHH, _accMM, _accSS];
//                [arrayLock1 lock];
                @synchronized(self){
                    [_accContent addObject:_accStrVal];
                }
                
//                [arrayLock1 unlock];
                NSLog(@"Acc: %d", accRepeatcount);
                                                     
                accRepeatcount++;
            } else {
//                if(accRepeatcount<20){
                    fooAcc = [newTimeAcc componentsSeparatedByString: @":"];
                    _accHH = [fooAcc objectAtIndex: 0];
                    _accMM = [fooAcc objectAtIndex: 1];
                    _accSS = [fooAcc objectAtIndex: 2];
                                                         
//                    accelX = (accelerometerData.acceleration.x * kFilteringFactor) + (accelX * (1.0 - kFilteringFactor));
//                    accelY = (accelerometerData.acceleration.y * kFilteringFactor) + (accelY * (1.0 - kFilteringFactor));
//                    accelZ = (accelerometerData.acceleration.z * kFilteringFactor) + (accelZ * (1.0 - kFilteringFactor));
                    
                    accelX = accelerometerData.acceleration.x * 9.80665f * kFilteringFactor + accelX * (1.0 - kFilteringFactor);
                    accelY = accelerometerData.acceleration.y *  9.80665f * kFilteringFactor + accelY * (1.0 - kFilteringFactor);
                    accelZ = accelerometerData.acceleration.z *  9.80665f * kFilteringFactor + accelZ * (1.0 - kFilteringFactor);
                    
                    xValue = (accelerometerData.acceleration.x * 9.80665f) - accelX;
                    
                    yValue = (accelerometerData.acceleration.y * 9.80665f) - accelY;
                    zValue= (accelerometerData.acceleration.z * 9.80665f) - accelZ;
                    
                    _accX = [NSString stringWithFormat:@"%f",xValue];
                    _accY = [NSString stringWithFormat:@"%f",yValue];
                    _accZ = [NSString stringWithFormat:@"%f",zValue];
                                                         
                    rootMeanSquareOfAccelerometer = sqrtf((([_accX floatValue] * [_accX floatValue]) + ([_accY floatValue] * [_accY floatValue]) + ([_accZ floatValue] * [_accZ floatValue]))/3);
                    _accRootMeanVal = [[NSNumber numberWithFloat:rootMeanSquareOfAccelerometer] stringValue];
                                                         
//                    orientationAcc = [[UIDevice currentDevice] orientation];
//                    if (orientationAcc == UIDeviceOrientationPortrait || orientationAcc == UIDeviceOrientationPortraitUpsideDown){
//                        //NSLog(@"portrait");
//                        _accOrientationValue = @"2"; //Portrait - leg position standing
//                    }else{
//                        //NSLog(@"landscape");
//                        _accOrientationValue = @"1"; //Landscape  - Leg position sleeping
//                    }
                    _accStrVal = [NSString stringWithFormat:@"%0.2f %@ %@ %@ %@ %@ %@ %@ %@", timestampAcc, _accX, _accY,_accZ, _accRootMeanVal,_accOrientationValue, _accHH, _accMM, _accSS];
                    
//                    NSLock *arrayLock = [[NSLock alloc] init];
//                    [arrayLock1 lock];
                    @synchronized(self){
                        [_accContent addObject:_accStrVal];
                    }
                    
//                    [arrayLock1 unlock];
                    NSLog(@"Acc: %d", accRepeatcount);
                    accRepeatcount++;
//                }
            }
                                                 
        }];
    
    [self.motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
            _gyrotimeStamp = [NSString stringWithFormat:@"%.2f",gyroData.timestamp];
//            timestampGyro = TimeStamp - upTimeInterval;
//            timestampGyro = timestampGyro + [_gyrotimeStamp integerValue];
//            if(isSensorStopped==false && firstTime==true){
//                firstTime= false;
//                referenceTimestamp = TimeStamp  - upTimeInterval;
//            }
            timestampGyro = referenceTimestamp + gyroData.timestamp;
                                        
            timeFormatterValGyro = [[NSDateFormatter alloc] init];
            [timeFormatterValGyro setDateFormat:@"HH:mm:ss"];
//            timestampGyro = [_gyrotimeStamp integerValue];
            dateGyro = [NSDate dateWithTimeIntervalSince1970:timestampGyro];
            newTimeGyro = [timeFormatterValGyro stringFromDate:dateGyro];
                                        
//            if((gyroData.timestamp - gyroPrevTime) > 1){
            if(![newTimeGyro isEqualToString:_gyroPrevTime]){
//                gyroPrevTime = gyroData.timestamp;
                _gyroPrevTime = newTimeGyro;
                gyroRepeatcount = 0;
                fooGyro = [newTimeGyro componentsSeparatedByString: @":"];
                _gyroHH = [fooGyro objectAtIndex: 0];
                _gyroMM = [fooGyro objectAtIndex: 1];
                _gyroSS = [fooGyro objectAtIndex: 2];
                                            
                _gyroX = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.x];
                _gyroY = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.y];
                _gyroZ = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.z];
                                            
//                orientationGyro = [[UIDevice currentDevice] orientation];
//                if (orientationGyro == UIDeviceOrientationPortrait || orientationGyro == UIDeviceOrientationPortraitUpsideDown){
//                    //                    NSLog(@"portrait");
//                    _gyroOrientationValue = @"2"; //Portrait
//                }else{
//                    //                    NSLog(@"landscape");
//                    _gyroOrientationValue = @"1"; //Portrait
//                }
                _gyroStrVal = [NSString stringWithFormat:@"%0.2f %@ %@ %@ %@ %@ %@ %@", timestampGyro, _gyroX, _gyroY,_gyroZ, _gyroOrientationValue, _gyroHH, _gyroMM, _gyroSS];
//                _gyroStrVal = [NSString stringWithFormat:@"%@ %@ %@ %@", _gyrotimeStamp, _gyroX, _gyroY,_gyroZ];
                                            
                
                
//                [arrayLock2 lock];
                @synchronized(self){
                    [_gyroContent addObject:_gyroStrVal];
                }
                
//                [arrayLock2 unlock];
                
                NSLog(@"Gyro: %d",gyroRepeatcount);
                gyroRepeatcount++;
            } else {
//                if(gyroRepeatcount<20){
                    fooGyro = [newTimeGyro componentsSeparatedByString: @":"];
                                                
                    _gyroHH = [fooGyro objectAtIndex: 0];
                    _gyroMM = [fooGyro objectAtIndex: 1];
                    _gyroSS = [fooGyro objectAtIndex: 2];
                                                
                    _gyroX = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.x];
                    _gyroY = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.y];
                    _gyroZ = [[NSString alloc] initWithFormat:@"%f",gyroData.rotationRate.z];
                                                
                                                
//                    orientationGyro = [[UIDevice currentDevice] orientation];
//                    if (orientationGyro == UIDeviceOrientationPortrait || orientationGyro == UIDeviceOrientationPortraitUpsideDown){
//                        //                    NSLog(@"portrait");
//                        _gyroOrientationValue = @"2"; //Portrait
//                    }else{
//                        //                    NSLog(@"landscape");
//                        _gyroOrientationValue = @"1"; //Portrait
//                    }
                    _gyroStrVal = [NSString stringWithFormat:@"%0.2f %@ %@ %@ %@ %@ %@ %@", timestampGyro, _gyroX, _gyroY,_gyroZ, _gyroOrientationValue, _gyroHH, _gyroMM, _gyroSS];
//                    _gyroStrVal = [NSString stringWithFormat:@"%@ %@ %@ %@", _gyrotimeStamp, _gyroX, _gyroY,_gyroZ];
                    
//                    NSLock *arrayLock = [[NSLock alloc] init];
                    @synchronized(self){
                        [_gyroContent addObject:_gyroStrVal];
                    }
//                    [arrayLock2 lock];
//                    [_gyroContent addObject:_gyroStrVal];
//                    [arrayLock2 unlock];
                    NSLog(@"Gyro: %d",gyroRepeatcount);
                    
                    gyroRepeatcount++;
//                }
            }
                                        
                                        
        }];
    
}
- (void)checkOrientation
{
//    CMMotionManager *motionManager1 = [CMMotionManager SharedMotionManager];
    if ([self.motionManager isDeviceMotionAvailable])
    {
        [self.motionManager setDeviceMotionUpdateInterval:1.0/MOVEMENT_HZ];
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler: ^(CMDeviceMotion *motion, NSError *error)
         {
             CMAcceleration lowpassFilterAcceleration, userAcceleration = motion.userAcceleration;
             
             lowpassFilterAcceleration.x = (userAcceleration.x * kLowPassFilteringFactor) + (previousLowPassFilteredAccelerationX * (1.0 - kLowPassFilteringFactor));
             lowpassFilterAcceleration.y = (userAcceleration.y * kLowPassFilteringFactor) + (previousLowPassFilteredAccelerationY * (1.0 - kLowPassFilteringFactor));
//             lowpassFilterAcceleration.z = (userAcceleration.z * kLowPassFilteringFactor) + (previousLowPassFilteredAccelerationZ * (1.0 - kLowPassFilteringFactor));
             
             if (lowpassFilterAcceleration.x > NOISE_REDUCTION || lowpassFilterAcceleration.y > NOISE_REDUCTION){
                 int maxDigitsAfterDecimal = 3; // here's where you set the dp
                 
                 NSNumberFormatter * nf = [[NSNumberFormatter alloc] init];
                 [nf setMaximumFractionDigits:maxDigitsAfterDecimal];
                 
                 //             NSString * trimmed = [nf stringFromNumber:[NSNumber numberWithDouble:3.14159]];
                 //
                 //             [trimmed floatValue];
                 NSString *accX =[nf stringFromNumber:[NSNumber numberWithDouble:-lowpassFilterAcceleration.x]];
                 NSString *accY =[nf stringFromNumber:[NSNumber numberWithDouble:lowpassFilterAcceleration.y]];
                 float xx = [accX floatValue];
                 float yy = [accY floatValue];
                 float angle_rad = atan2(yy, xx);
                 float angle_deg = (angle_rad/M_PI*180) + (angle_rad > 0 ? 0 : 360);
//                 NSLog(@"angle: %f",angle_deg);
                 // Add 1.5 to the angle to keep the label constantly horizontal to the viewer.
                 //    [interfaceOrientationLabel setTransform:CGAffineTransformMakeRotation(angle+1.5)];
                 
                 if(angle_rad >= -2.25 && angle_rad <= -0.25)
                 {
                     NSLog(@"Portrait");
                     _accOrientationValue = @"2"; //Portrait - leg position standing
                     _gyroOrientationValue = @"2"; //Portrait - leg position standing
                 }
                 else if(angle_rad >= -1.75 && angle_rad <= 0.75)
                 {
                     NSLog(@"Landscape Right");
                     _accOrientationValue = @"1"; //Landscape  - Leg position sleeping
                     _gyroOrientationValue = @"1"; //Landscape  - Leg position sleeping
                 }
                 else if(angle_rad >= 0.75 && angle_rad <= 2.25)
                 {
                     NSLog(@"Portrait upside down");
                     _accOrientationValue = @"2"; //Portrait - leg position standing
                     _gyroOrientationValue = @"2"; //Portrait - leg position standing
                 }
                 else if(angle_rad <= -2.25 || angle_rad >= 2.25)
                 {
                     NSLog(@"Landscape Left");
                     _accOrientationValue = @"1"; //Landscape  - Leg position sleeping
                     _gyroOrientationValue = @"1"; //Landscape  - Leg position sleeping
                 }
             }
             
//                 [self.points addObject:[NSString stringWithFormat:@"%.2f,%.2f", lowpassFilterAcceleration.x, lowpassFilterAcceleration.y]];
             
             previousLowPassFilteredAccelerationX = lowpassFilterAcceleration.x;
             previousLowPassFilteredAccelerationY = lowpassFilterAcceleration.y;
//             previousLowPassFilteredAccelerationZ = lowpassFilterAcceleration.z;
         }];
    }
    else NSLog(@"DeviceMotion is not available");
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
    lowpassFilterAccelerationX = (acceleration.x * kLowPassFilteringFactor) + (previousLowPassFilteredAccelerationX * (1.0 - kLowPassFilteringFactor));
    lowpassFilterAccelerationY = (acceleration.y * kLowPassFilteringFactor) + (previousLowPassFilteredAccelerationY * (1.0 - kLowPassFilteringFactor));
    
//    if (fabs(acceleration.x) > NOISE_REDUCTION || fabs(acceleration.y) > NOISE_REDUCTION){
    
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setMaximumFractionDigits:2];
        accelerationX += atof([[numberFormatter stringFromNumber:[NSNumber numberWithDouble:-lowpassFilterAccelerationX]] UTF8String]);
        accelerationY += atof([[numberFormatter stringFromNumber:[NSNumber numberWithDouble:lowpassFilterAccelerationY]] UTF8String]);
    if(orientationSampleCounter > 5){
        
        angle_rad = atan2(accelerationY, accelerationX);
        angle_deg = (angle_rad/M_PI*180) + (angle_rad > 0 ? 0 : 360);
//        NSLog(@"angle: %f",angle_deg);
        
        if((angle_deg >= 60 && angle_deg<120)|| (angle_deg>=240 && angle_deg<=300))
        {
            NSLog(@"Standing");
            _accOrientationValue = @"2"; //Portrait - leg position standing
            _gyroOrientationValue = @"2"; //Portrait - leg position standing
        }else{
            NSLog(@"Sleeping");
            _accOrientationValue = @"1"; //Landscape  - Leg position sleeping
            _gyroOrientationValue = @"1"; //Landscape  - Leg position sleeping
        }
        orientationSampleCounter = 0;
        accelerationX = 0;
        accelerationY = 0;
    } else{
        orientationSampleCounter++;
    }
//    }
    
    previousLowPassFilteredAccelerationX = lowpassFilterAccelerationX;
    previousLowPassFilteredAccelerationY = lowpassFilterAccelerationY;

}

//radians to degree conversion
CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
};

//degree to radian
CGFloat DegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
};

- (IBAction)stopAccelerometer:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]
                          
                          initWithTitle:@"Are you sure?"
                          message:@"\nDo you want to stop?"
                          delegate:self
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles:@"Yes", nil];
    [alert setTag:2];
    
    [alert show];
    double delayInSeconds = 30.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // code executed on main thread
        if(isSensorStopped!=true){
            [alert dismissWithClickedButtonIndex:0 animated:YES];
        }
    });
    
}
-(void) stop{
   
//    if(writingToDB==false)
//    {
////         sqlite3_close(_myDataBase);
//    }
    
    isSensorStopped = true;
    
    self.startAccButton.hidden = false;
    self.stopAccButton.hidden = true;
    
    //now recording text visibility
    self.nowRecordingLabel.hidden = true;
    self.presStopLabel.hidden = true;
    
    self.legSegmentedControl.hidden = false;
//    self.sampleRateTextBox.hidden = false;
//    self.sampleLabel.hidden = false;
    [self.locationUpdateTimer invalidate];
    [self.locationTracker stopLocationTracking];
    [self.accelerometerTimer invalidate];
    [self.accPushTimer invalidate];
//    [self.writeToFileTimer invalidate];
    [self.motionManager stopGyroUpdates];
    [self.motionManager stopAccelerometerUpdates];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @synchronized(self){
            [self updateUploadStatus];
        }
    });
    NSLog(@"Accelerometer Stopped");
}


- (IBAction)uploadFileToServer:(id)sender {
    uploadButtonClicked = true;
    [self uploadToServer];
}

- (NSString *)uploadDataToServerBackground:(NSString *) contentStr{
    NSString *urlString = @"https://covail.cs.umbc.edu/rls/accelerometer/upload.php";
    NSString *name = [NSString stringWithFormat:@"%@.txt",[todaysUserFileName substringFromIndex:1]];
    NSString *myRequestString = [NSString stringWithFormat:@"username=%@&&title=%@&&contentstring=%@",_username, name,contentStr];
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString]];
    // set Request Type
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    // Now send a request and get Response
    NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    // Log Response
    NSString *response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
    return response;
}

- (NSString *)uploadDataTableToServer:(NSString *)contentStr : (NSString *)tableName{
    NSString *urlString = @"https://covail.cs.umbc.edu/rls/accelerometer/upload.php";
    NSString *name = [NSString stringWithFormat:@"%@.txt",[tableName substringFromIndex:1]];
    
    NSString *myRequestString = [NSString stringWithFormat:@"username=%@&&title=%@&&contentstring=%@",_username, name,contentStr];
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString]];
    // set Request Type
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    // Now send a request and get Response
    NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    // Log Response
    NSString *response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
    return response;
}
/*
- (NSString *)uploadDataToServer:(NSString *) contentStr{
    NSString *urlString = @"https://covail.cs.umbc.edu/rls/accelerometer/upload.php";
    NSString *myRequestString = [NSString stringWithFormat:@"username=%@&&title=%@&&contentstring=%@",_username, todaysUserFileName,contentStr];
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: urlString]];
    // set Request Type
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    // Now send a request and get Response
    NSData *returnData = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    // Log Response
    NSString *response = [[NSString alloc] initWithBytes:[returnData bytes] length:[returnData length] encoding:NSUTF8StringEncoding];
    return response;
}

*/

//Method to delete all the older files (More than two days)
//check all this file, make sure all the files are covered in each folder
// delete all such files
- (void) removeOlderFiles{
    [self getUserName];
    
    NSMutableArray *deletedFiles = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString  *filePath = [paths objectAtIndex:0];
    filePath = [filePath stringByAppendingString:[NSString stringWithFormat:@"/%@/",_username]];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:filePath
                                                      error:nil];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"MM_dd_yyyy"];
    NSDate *todaysDate = [[NSDate alloc]init];
    //NSError *err;
    for(NSString *filename in files)
    {
        if([filename isEqualToString:@"data.db"]){
            _databasePath = [NSString stringWithFormat:@"%@%@",filePath,filename];
            
            sqlite3_close(_myDataBase);
            const char *dbPath = [_databasePath UTF8String];
            if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
                
                NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT name FROM sqlite_master WHERE type=\'table\'"];
                sqlite3_stmt* statement;
                int retVal = sqlite3_prepare_v2(_myDataBase,[sql_statement UTF8String],-1,&statement,NULL);
                
                if ( retVal == SQLITE_OK )
                {
                    while(sqlite3_step(statement) == SQLITE_ROW )
                    {
                        NSString *tableName = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0)
                                                                 encoding:NSUTF8StringEncoding];
                        
                        if(![tableName isEqualToString:@"sqlite_sequence"]){
                            NSString* dateString = [tableName substringWithRange:NSMakeRange(1, 10)];
                            NSDateFormatter * dateFormatter = [[NSDateFormatter alloc]init];
                            [dateFormatter setDateFormat:@"MM_dd_yyyy"];
                            NSDate *fileDate = [dateFormatter dateFromString:dateString];
                            NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                            NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit
                                                                                fromDate:fileDate
                                                                                  toDate:todaysDate
                                                                                 options:0];
                            
                            NSLog(@"%ld",(long)[components day]);
                            if([components day]>=2){
                                [deletedFiles addObject:tableName];
                            }
                        }
                    }
                }
                for(NSString* name in deletedFiles){
                    NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@",name];
                    
                    //                                NSString *sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@",tableName];
                    const char *del_stmt = [sql UTF8String];
                    sqlite3_stmt* deleteStmt;
                    if(sqlite3_prepare_v2(_myDataBase, del_stmt, -1, & deleteStmt, NULL) == SQLITE_OK){
                        if (sqlite3_step(deleteStmt) == SQLITE_DONE)
                        {
                            NSLog(@"deleted");
                        } else {
                            NSLog(@"failed");
                        }
                    }
                    
                    sqlite3_finalize(deleteStmt);
                    
                }
                
                
                sqlite3_clear_bindings(statement);
                sqlite3_finalize(statement);
//                sqlite3_close(_myDataBase);
                //                [_userFiles addObject:filename];
            }
            
        }
    }
}

- (void) uploadInBackground
{
    [self getUserName];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data.db",_username]];
    
    _databasePath = filePath;
    
    const char *dbPath = [_databasePath UTF8String];
    if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
        
        int numberOfRows = 0;
        NSString *count_statement=[[NSString alloc]initWithFormat:@"SELECT COUNT(*) FROM %@",tempFileToBeStored];
        sqlite3_stmt* countStatement;
        
        if( sqlite3_prepare_v2(_myDataBase,[count_statement UTF8String],-1,&countStatement,NULL) == SQLITE_OK )
        {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(countStatement) == SQLITE_ROW )
            {
                numberOfRows = sqlite3_column_int(countStatement, 0);
            }
        }
        else
        {
            NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(_myDataBase) );
        }
        
        // Finalize and close database.
        sqlite3_finalize(countStatement);
        
        NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT * FROM %@",tempFileToBeStored];
        sqlite3_stmt* statement;
        int retVal = sqlite3_prepare_v2(_myDataBase,
                                        [sql_statement UTF8String],
                                        -1,
                                        &statement,
                                        NULL);
        NSString* tempStr = @"";
        if ( retVal == SQLITE_OK )
        {
            int count = 0;
            int nextLimit = 1000;
            while(sqlite3_step(statement) == SQLITE_ROW )
            {
                count++;
                
                NSString * str = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@ %@\n",[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 5) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 6) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 7) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 8) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 9) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 10) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 11) encoding:NSUTF8StringEncoding], [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 12) encoding:NSUTF8StringEncoding] ];
                
                tempStr = [tempStr stringByAppendingString:str];
                if((nextLimit > numberOfRows) && (count == numberOfRows)){
                    NSString *response = [self uploadDataToServerBackground:tempStr];
                    NSLog(@"%@",response);
                    NSString *name = [NSString stringWithFormat:@"%@.txt",[todaysUserFileName substringFromIndex:1]];
                    if(response!=nil && ![response isEqual:@""] && ![response isEqual:@" \n"] && ![response isEqual:@"Received file: \n"] &&[response isEqual:[NSString stringWithFormat:@"Received file: %@ \n", name]]){
                        NSString *sql = [NSString stringWithFormat:@"delete from %@ where ID<=%d",tempFileToBeStored, [[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] intValue]];
                        const char *del_stmt = [sql UTF8String];
                        sqlite3_stmt* deleteStmt;
                        sqlite3_prepare_v2(_myDataBase, del_stmt, -1, & deleteStmt, NULL);
                        if (sqlite3_step(deleteStmt) == SQLITE_DONE)
                        {
                            NSLog(@"deleted");
                        } else {
                            NSLog(@"failed");
                        }
                        sqlite3_finalize(deleteStmt);
                    }
                }
                if(count==nextLimit){
                    NSString *response = [self uploadDataToServerBackground:tempStr];
                    NSLog(@"%@",response);
                    NSString *name = [NSString stringWithFormat:@"%@.txt",[todaysUserFileName substringFromIndex:1]];
                    if(response!=nil && ![response isEqual:@""] && ![response isEqual:@" \n"] && ![response isEqual:@"Received file: \n"] &&[response isEqual:[NSString stringWithFormat:@"Received file: %@ \n", name]]){
                        
                        NSString *sql = [NSString stringWithFormat:@"delete from %@ where ID<=%d",tempFileToBeStored, [[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] intValue]];
                        const char *del_stmt = [sql UTF8String];
                        sqlite3_stmt* deleteStmt;
                        sqlite3_prepare_v2(_myDataBase, del_stmt, -1, & deleteStmt, NULL);
                        if (sqlite3_step(deleteStmt) == SQLITE_DONE)
                        {
                            NSLog(@"deleted");
                        } else {
                            NSLog(@"failed");
                        }
                        sqlite3_finalize(deleteStmt);
                        
                        nextLimit += 1000;
                        tempStr=@"";
                    } else {
                        break;
                    }
                    
                }
            }
        }
        
        
        sqlite3_clear_bindings(statement);
        sqlite3_finalize(statement);
        
        sqlite3_close(_myDataBase);
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    sqlite3_close(_myDataBase);
    [self createDatabaseConnection];
    // Dispose of any resources that can be recreated.
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
//                                                    message:@"Memomry is low"
//                                                   delegate:self
//                                          cancelButtonTitle:@"OK"
//                                          otherButtonTitles:nil];
//    [alert show];
}


@end
