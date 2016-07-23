//
//  HTDashboardViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 9/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTDashboardViewController : UIViewController <NSXMLParserDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, strong) NSString *calories;
@property (nonatomic, strong) NSString *caloriesGoal;
@property (nonatomic, strong) NSString *caloriesBurned;
@property (nonatomic, strong) NSString *weight;
@property (nonatomic, strong) NSString *weightStarting;
@property (nonatomic, strong) NSString *weightGoal;
@property (nonatomic, strong) NSString *weightOfficial;
@property (nonatomic, strong) NSString *walkingSteps;
@property (nonatomic, strong) NSString *walkingStepsGoal;
@property (nonatomic, strong) NSString *walkingStepsOfficial;
@property (nonatomic, strong) NSString *exerciseMinutes;
@property (nonatomic, strong) NSString *exerciseMinutesGoal;
@property (nonatomic, strong) NSString *exerciseMinutesOfficial;
@property (nonatomic, strong) NSString *sleepHours;
@property (nonatomic, strong) NSString *sleepHoursGoal;
@property (nonatomic, strong) NSString *sleepHoursOfficial;
@property (nonatomic, strong) NSString *numberOfMessages;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showMessages;
@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) NSInteger newLearningModules;
@property (nonatomic, assign) NSInteger newEatingPlans;

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSMutableArray *customMetrics;
@property (nonatomic, strong) NSMutableArray *customMetricsTypes;
@property (nonatomic, strong) NSMutableArray *customMetricsLabels;
@property (nonatomic, strong) NSMutableArray *customMetricsGoals;
@property (nonatomic, strong) NSMutableArray *customMetricsOfficial;

@property (nonatomic, strong) NSMutableArray *dashboardItems;
@property (nonatomic, strong) NSMutableArray *dashboardItemValues;
@property (nonatomic, strong) NSMutableArray *dashboardUserSort;

@property (nonatomic, strong) NSObject *dashboardObject;

@property (nonatomic, strong) NSMutableDictionary *dashboardUserPrefs;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;

@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

- (IBAction)leftDateArrowClick:(id)sender;

- (IBAction)rightDateArrowClick:(id)sender;

- (void)getDashboard:(NSString *) url withState:(BOOL) urlState;

- (NSNumber *)getNumberFromString:(NSString *) string;

- (NSString *)getFormattedStringFromFloat:(float) number;

// error handling
- (void)handleURLError:(NSError *)error;

@end







