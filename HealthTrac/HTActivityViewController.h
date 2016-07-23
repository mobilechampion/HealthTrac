//
//  HTActivityViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTActivityViewController : UIViewController <NSXMLParserDelegate> {
    
    UITextField *customMetricsField[10];
    UITextField *customMetricsGoalField[10];
    
    UIButton *metricCheckBox[10];
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, strong) NSMutableArray *metricReminders;

@property (nonatomic, strong) NSMutableArray *customMetrics;
@property (nonatomic, strong) NSMutableArray *customMetricsTypes;
@property (nonatomic, strong) NSMutableArray *customMetricsLabels;
@property (nonatomic, strong) NSMutableArray *customMetricsGoals;
@property (nonatomic, strong) NSMutableArray *customMetricsOfficial;

@property (nonatomic, strong) NSString *weight;
@property (nonatomic, strong) NSString *weightGoal;
@property (nonatomic, strong) NSString *walkingSteps;
@property (nonatomic, strong) NSString *walkingStepsGoal;
@property (nonatomic, strong) NSString *exerciseMinutes;
@property (nonatomic, strong) NSString *exerciseMinutesGoal;
@property (nonatomic, strong) NSString *sleepHours;
@property (nonatomic, strong) NSString *sleepHoursGoal;
@property (nonatomic, strong) NSString *weightUpdateSuccess;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, retain) UITextField *weightField;
@property (nonatomic, retain) UITextField *weightGoalField;
@property (nonatomic, retain) UITextField *walkingStepsField;
@property (nonatomic, retain) UITextField *walkingStepsGoalField;
@property (nonatomic, retain) UITextField *exerciseMinutesField;
@property (nonatomic, retain) UITextField *exerciseMinutesGoalField;
@property (nonatomic, retain) UITextField *sleepHoursField;
@property (nonatomic, retain) UITextField *sleepHoursGoalField;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL showWalkingSteps;
@property (nonatomic, assign) BOOL showExerciseMinutes;
@property (nonatomic, assign) BOOL showSleepHours;

@property (nonatomic, assign) BOOL doneEditingActivity;

@property (nonatomic, assign) NSInteger reminderMetricID;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

- (IBAction)cancelActivity:(id)sender;
- (IBAction)doneActivity:(id)sender;
- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;
- (IBAction)metricChecked:(id)sender;
- (IBAction)setReminder:(id)sender;

- (void)getActivity:(NSString *) url withState:(BOOL) urlState;

- (void)updateActivity:(NSString *) url withState:(BOOL) urlState;

- (void)showActivity;

- (NSString *) getFormattedStringFromFloat:(float) number;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
