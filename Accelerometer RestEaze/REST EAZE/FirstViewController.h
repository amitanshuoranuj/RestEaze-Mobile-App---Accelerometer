//
//  FirstViewController.h
//  REST EAZE
//
//  Created by Amitanshu Jha on 12/30/14.
//  Copyright (c) 2014 Amitanshu Jha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"

@interface FirstViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) IBOutlet UILabel *headerLabel;
@property (strong, nonatomic) NSString* username;

//- (IBAction)downloadFromServer:(id)sender;
//- (IBAction)loadData:(id)sender;

//-(void) writeToTextFile;
//-(void) readFromTextFile;
//- (void) readFileFromServerAndStoreInMemory;
//- (void) deleteStoredFile;
//- (void) uploadFileToServer;

@property (nonatomic) UIButton *prevBtn;
@property (nonatomic) UIButton *nextBtn;

@property (nonatomic) UIButton *refreshBtn;
//database
@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *myDataBase;

@end

