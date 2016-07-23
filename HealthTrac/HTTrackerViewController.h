//
//  HTTrackerViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/20/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTTrackerViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, retain) NSMutableArray *previousCalendarColors;
@property (nonatomic, retain) NSMutableArray *currentCalendarColors;
@property (nonatomic, retain) NSMutableArray *nextCalendarColors;

@property (nonatomic, retain) NSMutableArray *previousCalendarLogins;
@property (nonatomic, retain) NSMutableArray *currentCalendarLogins;
@property (nonatomic, retain) NSMutableArray *nextCalendarLogins;

@property (nonatomic, retain) NSMutableArray *previousCalendarActivity;
@property (nonatomic, retain) NSMutableArray *currentCalendarActivity;
@property (nonatomic, retain) NSMutableArray *nextCalendarActivity;

@property (nonatomic, assign) NSInteger numberOfNewMessages;
@property (nonatomic, assign) NSInteger numberOfEatingPlans;
@property (nonatomic, assign) NSInteger numberOfLearningModules;

@property (strong, nonatomic) IBOutlet UIView *calendarView;
@property (strong, nonatomic) IBOutlet UIView *appletsView;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UIButton *buttonColorMyDay;
@property (strong, nonatomic) IBOutlet UIButton *buttonActivityTracker;
@property (strong, nonatomic) IBOutlet UIButton *buttonMyJournal;
@property (strong, nonatomic) IBOutlet UIButton *buttonSetAGoal;

- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;
- (IBAction)clickedColorMyDay:(id)sender;
- (IBAction)clickedActivityTracker:(id)sender;
- (IBAction)clickedMyJournal:(id)sender;
- (IBAction)clickedSetAGoal:(id)sender;

- (void)clickedCurrentMonthDay:(id)sender;
- (void)clickedPreviousMonthDay:(id)sender;
- (void)clickedNextMonthDay:(id)sender;

- (void)getCalendar:(NSString *) url withState:(BOOL) urlState;

- (void)showCalendar;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
