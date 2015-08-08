//
//  FirstViewController.m
//  REST EAZE
//
//  Created by Amitanshu Jha on 12/30/14.
//  Copyright (c) 2014 Amitanshu Jha. All rights reserved.
//

#import "FirstViewController.h"
#import "FSLineChart.h"
#import "UIColor+FSPalette.h"
#import "sqlite3.h"

@interface FirstViewController ()

@property (nonatomic) NSMutableArray* currentTime;
@property (nonatomic) NSMutableArray* accRootMean;

//temp mutable array
@property (nonatomic) NSMutableArray* tempCurrentTime;
@property (nonatomic) NSMutableArray* tempAccRootMean;
@property (nonatomic) NSMutableArray* tempGyroscopeX;
@property (nonatomic) NSMutableArray* tempGyroscopeY;
@property (nonatomic) NSMutableArray* tempGyroscopeZ;

@property (nonatomic) NSMutableArray* userFiles;
@property (nonatomic) NSMutableArray* accelerometerX;
@property (nonatomic) NSMutableArray* accelerometerY;
@property (nonatomic) NSMutableArray* accelerometerZ;
@property (nonatomic) NSMutableArray* gyroscopeX;
@property (nonatomic) NSMutableArray* gyroscopeY;
@property (nonatomic) NSMutableArray* gyroscopeZ;
@property (nonatomic) NSMutableArray* magX;
@property (nonatomic) NSMutableArray* magY;
@property (nonatomic) NSMutableArray* magZ;
@property (nonatomic) FSLineChart *accMeanlineChart;
@property (nonatomic) FSLineChart* gyrolineChart;
@property (nonatomic) NSMutableArray* allLinedStrings;
@property (nonatomic) UISegmentedControl *segmentedControl;
@property (nonatomic) NSMutableArray *segmentedUserFiles;


@end
@implementation FirstViewController

int startValue = 0;
int finalValue = 1000;
int intervalValue = 1000;
int maxSize = 0;
NSString *todaysUserFileName;
UIActivityIndicatorView *spinner;

//NSString *username;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self removeOlderFiles];
//    [self createDatabaseConnection];
    //[self readFileFromServerAndStoreInMemory];
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Do any additional setup after loading the view, typically from a nib.
//    NSArray *subviewsCopy = [[self.scrollView subviews] copy];
//    for (UIView *subview in subviewsCopy) {
//        [subview removeFromSuperview];
//    }
    sqlite3_close(_myDataBase);
    //[self readFileFromServerAndStoreInMemory];
    
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // You code here to update the view.
    [self createDatabaseConnection];
    NSArray *subviewsCopy = [[self.scrollView subviews] copy];
    for (UIView *subview in subviewsCopy) {
        [subview removeFromSuperview];
    }
    [self startActivityIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat maxDepth = 0;
            startValue = 0;
            finalValue = startValue + intervalValue;
            [self readUserFiles];
            if(_userFiles.count>0){
                
                //[self loadGraph];
                [self.scrollView addSubview:[self createSegementedControl]];
                [self loadFile];
                
//                [self.scrollView addSubview:[self prevButton]];
//                [self.scrollView addSubview:[self nextButton]];
                [self.scrollView addSubview:[self refreshButton]];
                
            } else{
                [self.scrollView addSubview:[self noDataLabel]];
            }
            for (int i = 0; i < self.scrollView.subviews.count; i++)
            {
                UIView *aSubview = (UIView *) [self.scrollView.subviews objectAtIndex:i];
                CGFloat depth = aSubview.frame.origin.y + aSubview.frame.size.height;
                if (depth > maxDepth)
                    maxDepth = depth;
            }
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, maxDepth+20);
//            [self showButton];
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
        });
    });
    
}
- (UISegmentedControl*) createSegementedControl {
    NSArray* months = [NSArray arrayWithObjects:@"Jan",@"Feb",@"Mar",@"Apr",@"May",@"Jun",@"Jul",@"Aug", @"Sep", @"Oct", @"Nov", @"Dec",nil];
    _segmentedUserFiles = [[NSMutableArray alloc] init];
    for(NSString* item in _userFiles){
        int month = [[item substringWithRange:NSMakeRange(1, 2)] intValue];
        NSString* monthString = months[month-1];
        NSString * day = [item substringWithRange:NSMakeRange(4, 2)];
        NSString *finalStr;
        if([item length] > 15){
            NSString *leg;
            if([item length] ==16){
                leg = [item substringWithRange:NSMakeRange(12, 4)];
            } else if([item length] ==17){
                leg = [item substringWithRange:NSMakeRange(12, 5)];
            }
            finalStr = [monthString stringByAppendingString:[NSString stringWithFormat:@" %@,%@",day, leg]];
        } else {
            finalStr = [monthString stringByAppendingString:[NSString stringWithFormat:@" %@",day]];
        }
        [_segmentedUserFiles addObject:finalStr];
    }
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:_segmentedUserFiles];
    _segmentedControl.frame = CGRectMake(10, 15, [UIScreen mainScreen].bounds.size.width - 20, 40);
    [_segmentedControl addTarget:self action:@selector(MySegmentControlAction:) forControlEvents: UIControlEventValueChanged];
    _segmentedControl.selectedSegmentIndex = 0;
    
    return _segmentedControl;
}
- (void)MySegmentControlAction:(UISegmentedControl *)segment
{
    [_accMeanlineChart removeFromSuperview];
    [_gyrolineChart removeFromSuperview];
    startValue = 0;
    finalValue = startValue + intervalValue;
    //    [self loadGraph];
    [self startActivityIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        //no background operations
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadFile];
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
        });
    });
}
-(UIButton*) prevButton {
    _prevBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _prevBtn.frame = CGRectMake(10, 70, ([UIScreen mainScreen].bounds.size.width/2) - 15, 40);
    [_prevBtn setTitle:@"Prev"
             forState:(UIControlState)UIControlStateNormal];
    [_prevBtn addTarget:self
                action:@selector(prevButtonClick:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [_prevBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_prevBtn setBackgroundColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
    return _prevBtn;
}
-(UIButton*) refreshButton {
    _refreshBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _refreshBtn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width/4), 70, ([UIScreen mainScreen].bounds.size.width/2), 40);
    [_refreshBtn setTitle:@"Refresh"
                 forState:(UIControlState)UIControlStateNormal];
    [_refreshBtn addTarget:self
                    action:@selector(refreshButtonClick:)
          forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    _refreshBtn.layer.cornerRadius = 5;
    _refreshBtn.clipsToBounds = YES;
    [[_refreshBtn layer] setBorderWidth:1.0f];
    //    [[_refreshBtn layer] setBorderWidth:2.0f];
    [[_refreshBtn layer] setBorderColor:[self colorFromHexString:@"#5C8AE6"].CGColor];
    [_refreshBtn setTitleColor:[self colorFromHexString:@"#5C8AE6"] forState:UIControlStateNormal];
    [_refreshBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [_refreshBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    
    
    [_refreshBtn setImage:[UIImage imageNamed:@"Refresh"] forState:UIControlStateNormal];
    
    
    return _refreshBtn;
}
// Assumes input like "#00FF00" (#RRGGBB).
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
-(void) disableButtons{
    _prevBtn.alpha = 0.6f;
    _prevBtn.enabled = NO;
    _nextBtn.alpha = 0.6f;
    _nextBtn.enabled = NO;
}

-(void) showButton{
    if(startValue == 0){
        _prevBtn.alpha = 0.6f;
        _prevBtn.enabled = NO;
    } else {
        _prevBtn.alpha = 1.0f;
        _prevBtn.enabled = YES;
    }
    if(finalValue >= maxSize){
        _nextBtn.alpha = 0.6f;
        _nextBtn.enabled = NO;
    } else {
        _nextBtn.alpha = 1.0f;
        _nextBtn.enabled = YES;
    }
}

- (void)nextButtonClick:(id)sender {
    startValue = startValue + intervalValue;
    finalValue = finalValue + intervalValue;
    [_accMeanlineChart removeFromSuperview];
    [_gyrolineChart removeFromSuperview];
    //[self.scrollView addSubview:[self chart1]];
    [self startActivityIndicator];
    [self disableButtons];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadGraph];
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            [self showButton];
        });
    });
    
    
}
- (void)refreshButtonClick:(id)sender {
    //    [self loadStatisticsData];
    _refreshBtn.enabled=NO;
    _refreshBtn.hidden = true;
    [_accMeanlineChart removeFromSuperview];
    [_gyrolineChart removeFromSuperview];
    
    [self startActivityIndicator];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        //no background operations
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadFile];
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            _refreshBtn.enabled=YES;
            _refreshBtn.hidden = false;
        });
    });
    //    [self loadFile];
    
}
- (void)prevButtonClick:(id)sender {
    startValue = startValue - intervalValue;
    finalValue = finalValue - intervalValue;
    [_accMeanlineChart removeFromSuperview];
//    [self.scrollView addSubview:[self chart1]];
    [_gyrolineChart removeFromSuperview];
    [self startActivityIndicator];
    [self disableButtons];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadGraph];
            
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            [self showButton];
        });
    });
    
}

-(UIButton*) nextButton {
    _nextBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _nextBtn.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width/2) + 5, 70, ([UIScreen mainScreen].bounds.size.width/2) - 15, 40);
    [_nextBtn setTitle:@"Next"
             forState:(UIControlState)UIControlStateNormal];
    [_nextBtn addTarget:self
                action:@selector(nextButtonClick:)
      forControlEvents:(UIControlEvents)UIControlEventTouchDown];
    [_nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_nextBtn setBackgroundColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
    
    //add line
//    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 115, self.view.bounds.size.width, 1)];
//    lineView.backgroundColor = [UIColor blackColor];
//    [self.scrollView addSubview:lineView];
    
    return _nextBtn;
}
-(UILabel*)accMeanLabel {
    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(3, 155, 10, 190)];
    label.text = @"ACCELEROMETER";
    label.textColor = [UIColor darkTextColor];
    label.numberOfLines = 0;
    label.font =[UIFont systemFontOfSize:12];
    label.lineBreakMode = NSLineBreakByCharWrapping;
    return label;
}
-(UILabel*)accelerometerLabel {
    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(10, 200, [UIScreen mainScreen].bounds.size.width - 40, 50)];
    label.numberOfLines=2;
    label.text = @"Accelerometer vs Packets\nX-Blue, Y-Green, Z-Red";
    label.textColor = [UIColor darkTextColor];
    return label;
}
-(UILabel*)gyroscopeLabel {
    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(3, 345, 10, 190)];
    label.numberOfLines=2;
    label.text = @"GYROSCOPE";
    label.textColor = [UIColor darkTextColor];
    
    label.numberOfLines = 0;
    label.font =[UIFont systemFontOfSize:12];
    label.lineBreakMode = NSLineBreakByCharWrapping;
    return label;
}
-(UILabel*)gyroscopeAxisLabel {
    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(60, 540, [UIScreen mainScreen].bounds.size.width - 40, 20)];
    label.numberOfLines=2;
    label.text = @"X-Blue, Y-Red, Z-Yellow";
    label.textColor = [UIColor darkTextColor];
    return label;
}
-(UILabel*)noDataLabel {
    UILabel *label =  [[UILabel alloc] initWithFrame: CGRectMake(80, 180, [UIScreen mainScreen].bounds.size.width - 40, 50)];
    label.numberOfLines=2;
    label.text = @"Data Not Present...";
    label.textColor = [UIColor darkTextColor];
    return label;
}

- (void) setTodaysUserFileName
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"MM_dd_yyyy"];
    NSString *todaysDate = [timeFormatter stringFromDate:[[NSDate alloc]init] ];
    
    todaysUserFileName = [NSString stringWithFormat:@"%@.txt",todaysDate];
    
}
//set todays (current) temporary file name
- (void) getUserName
{
    _username = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
    
}

-(void) startActivityIndicator {
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.alpha = 1.0;
    spinner.transform = CGAffineTransformMakeScale(2.0, 2.0);
    spinner.color = [UIColor blueColor];
    spinner.center = CGPointMake(160, 260);
    [self.scrollView addSubview:spinner];
    [spinner startAnimating];
}

- (void) createDatabaseConnection
{
    [self getUserName];
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
    if ([fileManager fileExistsAtPath:self.databasePath]) {
        
        const char *dbPath = [self.databasePath UTF8String];
        if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
            
            
        } else {
            NSLog(@"Error Creating Database");
        }
    }
}

- (void) readUserFiles {
    
    [self getUserName];
    
    _userFiles =[[NSMutableArray alloc]init];
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString  *filePath = [paths objectAtIndex:0];
    filePath = [filePath stringByAppendingString:[NSString stringWithFormat:@"/%@/",_username]];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:filePath
                                                      error:nil];
    //NSError *err;
    for(NSString *filename in files)
    {
        if([filename isEqualToString:@"data.db"]){
            _databasePath = [NSString stringWithFormat:@"%@%@",filePath,filename];
            
            const char *dbPath = [_databasePath UTF8String];
//            if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
//                NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT name FROM data.sqlite_master WHERE type=\'table\'"];
                NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT name FROM sqlite_master WHERE type=\'table\'"];
                sqlite3_stmt* statement;
                int retVal = sqlite3_prepare_v2(_myDataBase,
                                                [sql_statement UTF8String],
                                                -1,
                                                &statement,
                                                NULL);
                
                if ( retVal == SQLITE_OK )
                {
                    NSString *tableName;
                    while(sqlite3_step(statement) == SQLITE_ROW )
                    {
                        tableName = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0)
                                                             encoding:NSUTF8StringEncoding];
                        
                        if(![tableName isEqualToString:@"sqlite_sequence"] && ![[tableName substringWithRange:NSMakeRange(0, 1)] isEqualToString:@"t"])
                            [_userFiles addObject:tableName];
                    }
                }   
                
                sqlite3_clear_bindings(statement);
                sqlite3_finalize(statement);
//                sqlite3_close(_myDataBase);
//                [_userFiles addObject:filename];
//            }
            
        }
    }
}

-(void) loadFile {
    [self getUserName];
    int row = [_segmentedControl selectedSegmentIndex];
    
    NSString* filename = [_userFiles objectAtIndex:row];
    //    NSString* filename = [_segmentedControl titleForSegmentAtIndex:[_segmentedControl selectedSegmentIndex]];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/data.db",_username]];
//    
//    
////    _databasePath = [NSString stringWithFormat:@"%@%@",filePath,filename];
//    _databasePath = filePath;
//    
//    const char *dbPath = [_databasePath UTF8String];
//    if (sqlite3_open(dbPath, &_myDataBase) == SQLITE_OK) {
        //                NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT name FROM data.sqlite_master WHERE type=\'table\'"];
//        
//        int numberOfRows = 0;
//        NSString *count_statement=[[NSString alloc]initWithFormat:@"SELECT COUNT(1) FROM %@",filename];
        NSString *count_statement=[[NSString alloc]initWithFormat:@"SELECT ID FROM %@ ORDER BY ID DESC LIMIT 1",filename];
        sqlite3_stmt* countStatement;
        
        if( sqlite3_prepare_v2(_myDataBase,[count_statement UTF8String],-1,&countStatement,NULL) == SQLITE_OK )
        {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(countStatement) == SQLITE_ROW )
            {
                maxSize = sqlite3_column_int(countStatement, 0);
            }
        }
        else
        {
            NSLog( @"Failed from sqlite3_prepare_v2. Error is:  %s", sqlite3_errmsg(_myDataBase) );
        }
        sqlite3_clear_bindings(countStatement);
        sqlite3_finalize(countStatement);
//        sqlite3_close(_myDataBase);
        
//    }
    [self loadGraph];
}

- (void) loadGraph {
//    int endValue;
//    if(finalValue > maxSize)
//        endValue = maxSize;
//    else
//        endValue = finalValue;
    if(maxSize>0){
        _tempCurrentTime = [[NSMutableArray alloc]init];
        _tempAccRootMean = [[NSMutableArray alloc]init];
//        _tempGyroscopeX = [[NSMutableArray alloc]init];
//        _tempGyroscopeY = [[NSMutableArray alloc]init];
//        _tempGyroscopeZ = [[NSMutableArray alloc]init];
        
        int row = [_segmentedControl selectedSegmentIndex];
        
        _currentTime =[[NSMutableArray alloc]init];
        _accRootMean = [[NSMutableArray alloc]init];
        
        //    _accelerometerX = [[NSMutableArray alloc]init];
        //    _accelerometerY = [[NSMutableArray alloc]init];
        //    _accelerometerZ = [[NSMutableArray alloc]init];
//        _gyroscopeX = [[NSMutableArray alloc]init];
//        _gyroscopeY = [[NSMutableArray alloc]init];
//        _gyroscopeZ = [[NSMutableArray alloc]init];
        
        
        NSString* filename = [_userFiles objectAtIndex:row];
        NSString *sql_statement;
        if(maxSize>12000){
            sql_statement=[[NSString alloc]initWithFormat:@"SELECT RMS,Timestamp FROM (SELECT ID,RMS,Timestamp FROM %@ ORDER BY ID DESC LIMIT 12000) ORDER BY ID",filename];
        } else {
            sql_statement=[[NSString alloc]initWithFormat:@"SELECT RMS,Timestamp FROM %@",filename];
        }
//        NSString *sql_statement=[[NSString alloc]initWithFormat:@"SELECT RMS,Timestamp,GyroX,GyroY,GyroZ FROM %@",filename];
        sqlite3_stmt* statement;
        int retVal = sqlite3_prepare_v2(_myDataBase,
                                        [sql_statement UTF8String],
                                        -1,
                                        &statement,
                                        NULL);
        int averageCount = 0;
        double accRMSVal=0.0;
        //double gyroXVal=0.0,gyroYVal=0.0,gyroZVal=0.0;
//        bool firstValue=true;
        int calcAverageLimit = 0;
        if(maxSize>12000){
            calcAverageLimit = 2;
        } else {
            calcAverageLimit = maxSize/6000;
        }
        int count = 0;
        if ( retVal == SQLITE_OK )
        {
            
            NSString *accRMS;
            int timeStamp;
//            NSString *gyroX;
//            NSString *gyroY;
//            NSString *gyroZ;
            NSDateFormatter *timeFormatterVal = [[NSDateFormatter alloc] init];
            [timeFormatterVal setDateFormat:@"HH:mm:ss"];
            NSDate *date;
            NSString *time;
            double maxRMS = 0.0f;
            while(sqlite3_step(statement) == SQLITE_ROW )
            {
                count ++;
//                if((count>= startValue) && (count <endValue)){
                    accRMS = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 0)
                                                          encoding:NSUTF8StringEncoding];
                
                    
                    timeStamp = [[NSString stringWithCString:(const char *)sqlite3_column_text(statement, 1)
                                                             encoding:NSUTF8StringEncoding] integerValue];
                    date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
                    time = [timeFormatterVal stringFromDate:date];
                
                    
//                    gyroX = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 2)
//                                                         encoding:NSUTF8StringEncoding];
//                
//                    
//                    gyroY = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 3)
//                                                         encoding:NSUTF8StringEncoding];
//                
//                    
//                    gyroZ = [NSString stringWithCString:(const char *)sqlite3_column_text(statement, 4)
//                                                         encoding:NSUTF8StringEncoding];
                
                averageCount += 1;

                if(averageCount<10){
                    if(maxRMS < [accRMS doubleValue]){
                        accRMSVal= [accRMS doubleValue];
                        maxRMS = accRMSVal;
                        
                    }
                    
//                    gyroXVal += [gyroX doubleValue];
//                    gyroYVal += [gyroY doubleValue];
//                    gyroZVal += [gyroZ doubleValue];
                }else if(averageCount==10){
                    
                    if(maxRMS < [accRMS doubleValue]){
                        
                        accRMSVal= [accRMS doubleValue];
                        maxRMS = accRMSVal;
                        
                    }
                    [_accRootMean addObject:[NSString stringWithFormat:@"%f",maxRMS]];
                    [_currentTime addObject:time];
//                    accRMSVal+= [accRMS doubleValue];
//                    gyroXVal += [gyroX doubleValue];
//                    gyroYVal += [gyroY doubleValue];
//                    gyroZVal += [gyroZ doubleValue];
//                    accRMSVal = accRMSVal/600;
//                    gyroXVal = gyroXVal/600;
//                    gyroYVal = gyroYVal/600;
//                    gyroZVal = gyroZVal/600;
                    
//                    [_accRootMean addObject:[NSString stringWithFormat:@"%f",accRMSVal]];
//                    [_currentTime addObject:time];
//                    [_gyroscopeX addObject:[NSString stringWithFormat:@"%f",gyroXVal]];
//                    [_gyroscopeY addObject:[NSString stringWithFormat:@"%f",gyroYVal]];
//                    [_gyroscopeZ addObject:[NSString stringWithFormat:@"%f",gyroZVal]];
                    averageCount=0;
                    maxRMS = 0.0f;
                }
//                else{
//                    [_accRootMean addObject:accRMS];
//                    [_currentTime addObject:time];
//                    [_gyroscopeX addObject:gyroX];
//                    [_gyroscopeY addObject:gyroY];
//                    [_gyroscopeZ addObject:gyroZ];
//                }
                
                
//                }
            }
        }
        
        sqlite3_clear_bindings(statement);
        sqlite3_finalize(statement);
        
        
        // then break down even further
//        for (int i=startValue; i<(endValue); i++) {
//            // choose whatever input identity you have decided. in this case
//            NSDateFormatter *timeFormatterVal = [[NSDateFormatter alloc] init];
//            [timeFormatterVal setDateFormat:@"HH:mm:ss"];
//            int timestamp = [[_currentTime objectAtIndex:i] integerValue];
//            NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
//            NSString *time = [timeFormatterVal stringFromDate:date];
////            [_currentTime addObject:time];
//            [_tempCurrentTime addObject:time];
//            
//            [_tempAccRootMean addObject:[_accRootMean objectAtIndex:i]];
//            [_tempGyroscopeX addObject:[_gyroscopeX objectAtIndex:i]];
//            [_tempGyroscopeY addObject:[_gyroscopeY objectAtIndex:i]];
//            [_tempGyroscopeZ addObject:[_gyroscopeZ objectAtIndex:i]];
//            
//        }
//        [self showButton];
        [self.scrollView addSubview:[self chart1]];
        [self.scrollView addSubview:[self accMeanLabel]];
//        [self.scrollView addSubview:[self chart3]];
//        [self.scrollView addSubview:[self gyroscopeLabel]];
//        [self.scrollView addSubview:[self gyroscopeAxisLabel]];
    }
    if(maxSize==0){
        [self.scrollView addSubview:[self noDataLabel]];
//        [self showButton];
        
    }
    
}




#pragma mark - Creating the charts
-(FSLineChart*)chart1 {
    __unsafe_unretained typeof(self) weakSelf = self;
    if(_tempAccRootMean){
        // Creating the line chart
        _accMeanlineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(15, 170, [UIScreen mainScreen].bounds.size.width - 47, 166)];
    
        _accMeanlineChart.gridStep = 2;
        _accMeanlineChart.color = [UIColor fsLightBlue];

        _accMeanlineChart.labelForIndex = ^(NSUInteger item) {
            return weakSelf.currentTime[item];
        };
        _accMeanlineChart.labelForValue = ^(CGFloat value) {
            return [NSString stringWithFormat:@"%.f", value];
        };
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];

        [mutableArray addObject:_accRootMean];
        [_accMeanlineChart setChartData:mutableArray];
        [mutableArray removeAllObjects];
        [_accRootMean removeAllObjects];
        //[_currentTime removeAllObjects];
        
        
        //add line
//        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 330, self.view.bounds.size.width, 1)];
//        lineView.backgroundColor = [UIColor blackColor];
//        [self.scrollView addSubview:lineView];
//
        
        return _accMeanlineChart;
    }
    return [[FSLineChart alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}

-(FSLineChart*)chart2 {
    if(_accelerometerX && _accelerometerY && _accelerometerZ){
        // Creating the line chart
        FSLineChart* lineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(10, 250, [UIScreen mainScreen].bounds.size.width - 45, 166)];
    
        //lineChart.gridStep = 3;
        lineChart.color = [UIColor fsOrange];
    
        lineChart.labelForIndex = ^(NSUInteger item) {
            return [NSString stringWithFormat:@"%lu",(unsigned long)item];
        };
    
        lineChart.labelForValue = ^(CGFloat value) {
            return [NSString stringWithFormat:@"%.f", value];
        };
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
        [mutableArray addObject:_accelerometerX];
        [mutableArray addObject:_accelerometerY];
        [mutableArray addObject:_accelerometerZ];
    
        [lineChart setChartData:mutableArray];
        //[lineChart setChartData:chartData];
    
        return lineChart;
    }
    return [[FSLineChart alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}

#pragma mark - Creating the charts
-(FSLineChart*)chart3 {
    __unsafe_unretained typeof(self) weakSelf = self;
    if(_tempGyroscopeX && _tempGyroscopeY && _tempGyroscopeZ){
        // Creating the line chart
        _gyrolineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(15, 360, [UIScreen mainScreen].bounds.size.width - 47, 166)];
    
//        _gyrolineChart.gridStep = 12;
        //_gyrolineChart.color = [UIColor fsYellow];
        _gyrolineChart.labelForIndex = ^(NSUInteger item) {
            return weakSelf.currentTime[item];
        };
    
        _gyrolineChart.labelForValue = ^(CGFloat value) {
            return [NSString stringWithFormat:@"%.f", value];
        };
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
//        [_gyrolineChart setLabelForIndex:_currentTime];
        [mutableArray addObject:_gyroscopeX];
        [mutableArray addObject:_gyroscopeY];
        [mutableArray addObject:_gyroscopeZ];
    
        [_gyrolineChart setChartData:mutableArray];
        //[lineChart setChartData:chartData];
        [mutableArray removeAllObjects];
        [_currentTime removeAllObjects];
        [_gyroscopeX removeAllObjects];
        [_gyroscopeY removeAllObjects];
        [_gyroscopeZ removeAllObjects];
        return _gyrolineChart;
    }
    return [[FSLineChart alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}

#pragma mark - Creating the charts
-(FSLineChart*)chart4 {
    
    if(_accRootMean){
        // Creating the line chart
        FSLineChart* lineChart = [[FSLineChart alloc] initWithFrame:CGRectMake(10, 710, [UIScreen mainScreen].bounds.size.width - 40, 166)];
    
        //lineChart.gridStep = 3;
        lineChart.color = [UIColor fsRed];
        lineChart.labelForIndex = ^(NSUInteger item) {
            return [NSString stringWithFormat:@"%lu",(unsigned long)item];
        };
    
        lineChart.labelForValue = ^(CGFloat value) {
            return [NSString stringWithFormat:@"%.f", value];
        };
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
        [mutableArray addObject:_magX];
        [mutableArray addObject:_magY];
        [mutableArray addObject:_magZ];
    
        [lineChart setChartData:mutableArray];
        //[lineChart setChartData:chartData];
    
        return lineChart;
    }
    return [[FSLineChart alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}


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
                            
                            NSLog(@"%d",[components day]);
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
                sqlite3_close(_myDataBase);
                //                [_userFiles addObject:filename];
            }
            
        }
    }
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end



