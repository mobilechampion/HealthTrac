//
//  HTActivityViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTActivityViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTTrackerReminderViewController.h"

@interface HTActivityViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTActivityViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.metricReminders = [[NSMutableArray alloc] init];
    
    self.customMetrics = [[NSMutableArray alloc] init];
    self.customMetricsTypes = [[NSMutableArray alloc] init];
    self.customMetricsLabels = [[NSMutableArray alloc] init];
    self.customMetricsGoals = [[NSMutableArray alloc] init];
    self.customMetricsOfficial = [[NSMutableArray alloc] init];
    
    self.title = @"Activity Tracker";
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.passLogin isEqualToString:@""] ||
        [appDelegate.passPw isEqualToString:@""] ||
        appDelegate.passLogin == nil ||
        appDelegate.passPw == nil) {
        
        UINavigationController *navigationController = (UINavigationController *)self.navigationController;
        
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
        
        HTLoginViewController *viewController = (HTLoginViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"loginView"];
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        [navigationController pushViewController:viewController animated:NO];
    }
    
    // make sure all app dates are set correctly
    [appDelegate checkAppDatesWithPlanner:NO];
    
    [super viewWillAppear:animated];
    
    self.doneEditingActivity = NO;
    
    [self getActivity:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getActivity:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }

    myRequestString = [NSString stringWithFormat:@"action=get_activity&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)showActivity {
    
    NSArray *viewsToRemove = [self.scrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    NSInteger vPos = 11;
    
    UILabel *weightLabel;
    UILabel *walkingStepsLabel;
    UILabel *exerciseMinutesLabel;
    UILabel *sleepHoursLabel;
    UILabel *customMetricsLabel;
    
    NSInteger currentYear = 0;
    NSInteger currentMonth = 0;
    NSInteger currentDay = 0;
    
    NSDate *date = [NSDate date];
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [calendar components:(NSWeekdayCalendarUnit) fromDate:date];
    
    dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    
    currentYear = [dateComponents year];
    currentMonth = [dateComponents month];
    currentDay = [dateComponents day];
    
    UIView *graySeparator;
    
    int screenWidth = self.view.frame.size.width;
    int screenOffset = (self.view.frame.size.width - 320);
    
    UIFont *labelsFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UIButton *reminderButton;
    UIImageView *reminderButtonImage;
    
    BOOL reminderIconOn;
    
    if ([[self.metricReminders objectAtIndex:11] isEqualToString:@"Y"]) {
        
        reminderIconOn = YES;
        
    } else {
        
        reminderIconOn = NO;
    }
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, 142 + screenOffset, 31)];
    
    [reminderButton setTag:11];

    [reminderButton addTarget:self action:@selector(setReminder:) forControlEvents:UIControlEventTouchUpInside];

    reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 16, 16)];
    
    if (reminderIconOn == YES) {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
        
    } else {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
    }
    
    [reminderButton addSubview:reminderButtonImage];
    
    weightLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 108 + screenOffset, 31)];
    [weightLabel setTextAlignment:NSTextAlignmentLeft];
    [weightLabel setFont:labelsFont];
    [weightLabel setTextColor:grayFontColor];
    [weightLabel setText:@"Weight"];
    
    [reminderButton addSubview:weightLabel];
    
    [self.scrollView addSubview:reminderButton];
    
    self.weightField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(151 + screenOffset, vPos, 70, 31)];
    [self.weightField setTag:1];
    
    [self.scrollView addSubview:self.weightField];
    
    self.weightGoalField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(230 + screenOffset, vPos, 70, 31)];
    [self.weightGoalField setTag:2];
    
    [self.scrollView addSubview:self.weightGoalField];
    
    vPos += 40;
    
    if (self.showWalkingSteps == YES) {
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.scrollView addSubview:graySeparator];
        
        vPos += 13;
        
        if ([[self.metricReminders objectAtIndex:12] isEqualToString:@"Y"]) {
            
            reminderIconOn = YES;
            
        } else {
            
            reminderIconOn = NO;
        }
        
        reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, 142 + screenOffset, 31)];
        
        [reminderButton setTag:12];
        
        [reminderButton addTarget:self action:@selector(setReminder:) forControlEvents:UIControlEventTouchUpInside];
        
        reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 16, 16)];
        
        if (reminderIconOn == YES) {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
            
        } else {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
        }
        
        [reminderButton addSubview:reminderButtonImage];

        walkingStepsLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 108 + screenOffset, 31)];
        [walkingStepsLabel setTextAlignment:NSTextAlignmentLeft];
        [walkingStepsLabel setFont:labelsFont];
        [walkingStepsLabel setTextColor:grayFontColor];
        [walkingStepsLabel setText:@"Walking Steps"];
        
        [reminderButton addSubview:walkingStepsLabel];
        
        [self.scrollView addSubview:reminderButton];
        
        self.walkingStepsField = [[HTTextField alloc]
                                  initHTDefaultWithFrame:CGRectMake(151 + screenOffset, vPos, 70, 31)];
        [self.walkingStepsField setTag:3];
        
        [self.scrollView addSubview:self.walkingStepsField];
        
        self.walkingStepsGoalField = [[HTTextField alloc]
                                      initHTDefaultWithFrame:CGRectMake(230 + screenOffset, vPos, 70, 31)];
        [self.walkingStepsGoalField setTag:4];
        
        [self.scrollView addSubview:self.walkingStepsGoalField];
        
        vPos += 40;
    }
    
    if (self.showExerciseMinutes == YES) {
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.scrollView addSubview:graySeparator];
        
        vPos += 13;
        
        if ([[self.metricReminders objectAtIndex:13] isEqualToString:@"Y"]) {
            
            reminderIconOn = YES;
            
        } else {
            
            reminderIconOn = NO;
        }
        
        reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, 142 + screenOffset, 31)];
        
        [reminderButton setTag:13];
        
        [reminderButton addTarget:self action:@selector(setReminder:) forControlEvents:UIControlEventTouchUpInside];
        
        reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 16, 16)];
        
        if (reminderIconOn == YES) {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
            
        } else {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
        }
        
        [reminderButton addSubview:reminderButtonImage];
        
        exerciseMinutesLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 108 + screenOffset, 31)];
        [exerciseMinutesLabel setTextAlignment:NSTextAlignmentLeft];
        [exerciseMinutesLabel setFont:labelsFont];
        [exerciseMinutesLabel setTextColor:grayFontColor];
        [exerciseMinutesLabel setText:@"Exercise Minutes"];
        
        [reminderButton addSubview:exerciseMinutesLabel];
        
        [self.scrollView addSubview:reminderButton];
        
        self.exerciseMinutesField = [[HTTextField alloc]
                                      initHTDefaultWithFrame:CGRectMake(151 + screenOffset, vPos, 70, 31)];
        [self.exerciseMinutesField setTag:5];
        
        [self.scrollView addSubview:self.exerciseMinutesField];
        
        self.exerciseMinutesGoalField = [[HTTextField alloc]
                                     initHTDefaultWithFrame:CGRectMake(230 + screenOffset, vPos, 70, 31)];
        [self.exerciseMinutesGoalField setTag:6];
        
        [self.scrollView addSubview:self.exerciseMinutesGoalField];
        
        vPos += 40;
    }
    
    if (self.showSleepHours == YES) {
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.scrollView addSubview:graySeparator];
        
        vPos += 13;
        
        if ([[self.metricReminders objectAtIndex:14] isEqualToString:@"Y"]) {
            
            reminderIconOn = YES;
            
        } else {
            
            reminderIconOn = NO;
        }
        
        reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, 142 + screenOffset, 31)];
        
        [reminderButton setTag:14];
        
        [reminderButton addTarget:self action:@selector(setReminder:) forControlEvents:UIControlEventTouchUpInside];
        
        reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 16, 16)];
        
        if (reminderIconOn == YES) {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
            
        } else {
            
            [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
        }
        
        [reminderButton addSubview:reminderButtonImage];
        
        sleepHoursLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 108 + screenOffset, 31)];
        [sleepHoursLabel setTextAlignment:NSTextAlignmentLeft];
        [sleepHoursLabel setFont:labelsFont];
        [sleepHoursLabel setTextColor:grayFontColor];
        [sleepHoursLabel setText:@"Sleep Hours"];
        
        [reminderButton addSubview:sleepHoursLabel];
        
        [self.scrollView addSubview:reminderButton];
        
        self.sleepHoursField = [[HTTextField alloc]
                                         initHTDefaultWithFrame:CGRectMake(151 + screenOffset, vPos, 70, 31)];
        [self.sleepHoursField setTag:7];
        
        [self.scrollView addSubview:self.sleepHoursField];
        
        self.sleepHoursGoalField = [[HTTextField alloc]
                                initHTDefaultWithFrame:CGRectMake(230 + screenOffset, vPos, 70, 31)];
        [self.sleepHoursGoalField setTag:8];
        
        [self.scrollView addSubview:self.sleepHoursGoalField];
        
        vPos += 40;
    }
    
    // custom metrics
    if ([self.customMetrics count] > 1) {
        
        for (int i=1; i<=[self.customMetrics count] - 1; i++) {
            
            if ([[self.customMetricsLabels objectAtIndex:i] isEqualToString:@""]) {
                
                // do nothing - ignore this type of metric
                
            } else {
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.scrollView addSubview:graySeparator];
                
                vPos += 13;
                
                if ([[self.metricReminders objectAtIndex:i] isEqualToString:@"Y"]) {
                    
                    reminderIconOn = YES;
                    
                } else {
                    
                    reminderIconOn = NO;
                }
                
                reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, 142 + screenOffset, 31)];
                
                [reminderButton setTag:i];
                
                [reminderButton addTarget:self action:@selector(setReminder:) forControlEvents:UIControlEventTouchUpInside];
                
                reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 7, 16, 16)];
                
                if (reminderIconOn == YES) {
                    
                    [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
                    
                } else {
                    
                    [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
                }
                
                [reminderButton addSubview:reminderButtonImage];
                
                customMetricsLabel = [[UILabel alloc] initWithFrame:CGRectMake(34, 0, 108 + screenOffset, 31)];
                customMetricsLabel.adjustsFontSizeToFitWidth = YES;
                customMetricsLabel.minimumScaleFactor = 0.8f;
                [customMetricsLabel setTextAlignment:NSTextAlignmentLeft];
                [customMetricsLabel setFont:labelsFont];
                [customMetricsLabel setTextColor:grayFontColor];
                [customMetricsLabel setText:[NSString stringWithFormat:@"%@", [self.customMetricsLabels objectAtIndex:i]]];
                
                [reminderButton addSubview:customMetricsLabel];
                
                [self.scrollView addSubview:reminderButton];
                
                // regular custom metric (not check box)
                if ([[self.customMetricsTypes objectAtIndex:i] isEqualToString:@"1"]) {
                    
                    customMetricsField[i] = [[HTTextField alloc]
                                                initHTDefaultWithFrame:CGRectMake(151 + screenOffset, vPos, 70, 31)];
                    
                    customMetricsField[i].tag = (20 + i); // tags 21 -> 30
                    
                    if ([[self.customMetrics objectAtIndex:i] doubleValue] == 0) {
                        
                        [customMetricsField[i] setPlaceholder:@"0"];
                        
                    } else {
                        
                        [customMetricsField[i] setText:[self
                                                        getFormattedStringFromFloat:
                                                        [[self.customMetrics objectAtIndex:i] doubleValue]]];
                    }
                    
                    [self.scrollView addSubview:customMetricsField[i]];
                    
                    customMetricsGoalField[i] = [[HTTextField alloc]
                                             initHTDefaultWithFrame:CGRectMake(230 + screenOffset, vPos, 70, 31)];
                    
                    customMetricsGoalField[i].tag = (50 + i); // tags 51 -> 60
                    
                    if ([[self.customMetricsGoals objectAtIndex:i] doubleValue] == 0) {
                        
                        [customMetricsGoalField[i] setPlaceholder:@"0"];
                        
                    } else {
                        
                        [customMetricsGoalField[i] setText:[self
                                                        getFormattedStringFromFloat:
                                                        [[self.customMetricsGoals objectAtIndex:i] doubleValue]]];
                    }
                    
                    if (appDelegate.currentYear == appDelegate.passYear && appDelegate.currentMonth == appDelegate.passMonth && appDelegate.currentDay == appDelegate.passDay) {
                        
                        [customMetricsGoalField[i] setEnabled:YES];
                        [customMetricsGoalField[i] setUserInteractionEnabled:YES];
                        
                        [customMetricsGoalField[i].layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                                        green:(227/255.0)
                                                                         blue:(230/255.0)
                                                                        alpha:1.0].CGColor];
                        
                        [customMetricsGoalField[i] setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                                      green:(249/255.0)
                                                                       blue:(250/255.0)
                                                                      alpha:1.0]];
                    }
                    else {
                        
                        [customMetricsGoalField[i] setEnabled:NO];
                        [customMetricsGoalField[i] setUserInteractionEnabled:NO];
                        [customMetricsGoalField[i].layer setBorderColor:[UIColor whiteColor].CGColor];
                        [customMetricsGoalField[i] setBackgroundColor:[UIColor whiteColor]];
                    }
                    
                    [self.scrollView addSubview:customMetricsGoalField[i]];
                }
                
                else { // [customMetricsTypes objectAtIndex:i] == @"2" -> check box metric
                    
                    metricCheckBox[i] = [UIButton buttonWithType:UIButtonTypeCustom];
                    metricCheckBox[i].frame = CGRectMake(266 + screenOffset, vPos - 1, 33, 33);
                    metricCheckBox[i].tag = (20 + i);
                    [metricCheckBox[i] setEnabled:YES];
                    [metricCheckBox[i] setUserInteractionEnabled:YES];
                    [metricCheckBox[i] addTarget:self action:@selector(metricChecked:) forControlEvents:UIControlEventTouchUpInside];
                    
                    if ([[self.customMetrics objectAtIndex:i] isEqualToString:@"1" ]) {
                        
                        [metricCheckBox[i] setImage:[UIImage imageNamed:@"ht-check-on-green"]
                                           forState:UIControlStateNormal];
                        
                    } else { // @"0"
                        
                        [metricCheckBox[i] setImage:[UIImage imageNamed:@"ht-check-off-green"]
                                           forState:UIControlStateNormal];
                    }
                    
                    [self.scrollView addSubview:metricCheckBox[i]];
                }
                
                vPos += 40;
            }
        }
    }
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.scrollView addSubview:graySeparator];
    
    vPos += 4;
    
    if (appDelegate.currentYear == appDelegate.passYear && appDelegate.currentMonth == appDelegate.passMonth && appDelegate.currentDay == appDelegate.passDay) {
        
        [self.weightGoalField setEnabled:YES];
        [self.weightGoalField setUserInteractionEnabled:YES];
        
        [self.weightGoalField.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                                        green:(227/255.0)
                                                                         blue:(230/255.0)
                                                                        alpha:1.0].CGColor];
        
        [self.weightGoalField setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                                      green:(249/255.0)
                                                                       blue:(250/255.0)
                                                                      alpha:1.0]];
        if (self.showWalkingSteps == YES) {
            
            [self.walkingStepsGoalField setEnabled:YES];
            [self.walkingStepsGoalField setUserInteractionEnabled:YES];
            
            [self.walkingStepsGoalField.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                                       green:(227/255.0)
                                                                        blue:(230/255.0)
                                                                       alpha:1.0].CGColor];
            
            [self.walkingStepsGoalField setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                                     green:(249/255.0)
                                                                      blue:(250/255.0)
                                                                     alpha:1.0]];
        }
        
        if (self.showExerciseMinutes == YES) {
            
            [self.exerciseMinutesGoalField setEnabled:YES];
            [self.exerciseMinutesGoalField setUserInteractionEnabled:YES];
            
            [self.exerciseMinutesGoalField.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                                             green:(227/255.0)
                                                                              blue:(230/255.0)
                                                                             alpha:1.0].CGColor];
            
            [self.exerciseMinutesGoalField setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                                           green:(249/255.0)
                                                                            blue:(250/255.0)
                                                                           alpha:1.0]];
        }
        
        if (self.showSleepHours == YES) {
            
            [self.sleepHoursGoalField setEnabled:YES];
            [self.sleepHoursGoalField setUserInteractionEnabled:YES];
            
            [self.sleepHoursGoalField.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                                                green:(227/255.0)
                                                                                 blue:(230/255.0)
                                                                                alpha:1.0].CGColor];
            
            [self.sleepHoursGoalField setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                                              green:(249/255.0)
                                                                               blue:(250/255.0)
                                                                              alpha:1.0]];
        }
        
    } else { // read-only on goals if not current date
        
        [self.weightGoalField setEnabled:NO];
        [self.weightGoalField setUserInteractionEnabled:NO];
        
        [self.weightGoalField.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.weightGoalField setBackgroundColor:[UIColor whiteColor]];
        
        if (self.showWalkingSteps == YES) {
            
            [self.walkingStepsGoalField setEnabled:NO];
            [self.walkingStepsGoalField setUserInteractionEnabled:NO];
            
            [self.walkingStepsGoalField.layer setBorderColor:[UIColor whiteColor].CGColor];
            [self.walkingStepsGoalField setBackgroundColor:[UIColor whiteColor]];
        }
        
        if (self.showExerciseMinutes == YES) {
            
            [self.exerciseMinutesGoalField setEnabled:NO];
            [self.exerciseMinutesGoalField setUserInteractionEnabled:NO];
            
            [self.exerciseMinutesGoalField.layer setBorderColor:[UIColor whiteColor].CGColor];
            [self.exerciseMinutesGoalField setBackgroundColor:[UIColor whiteColor]];
        }
        
        if (self.showSleepHours == YES) {
            
            [self.sleepHoursGoalField setEnabled:NO];
            [self.sleepHoursGoalField setUserInteractionEnabled:NO];
            
            [self.sleepHoursGoalField.layer setBorderColor:[UIColor whiteColor].CGColor];
            [self.sleepHoursGoalField setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
    // weight
    
    if ([self.weight doubleValue] == 0) {
        
        [self.weightField setPlaceholder:@"0"];
        
    } else {
        
        [self.weightField setText:[self getFormattedStringFromFloat:[self.weight doubleValue]]];
    }
    
    if ([self.weightGoal doubleValue] == 0) {
        
        [self.weightGoalField setPlaceholder:@"0"];
        
    } else {
        
        [self.weightGoalField setText:[self getFormattedStringFromFloat:[self.weightGoal doubleValue]]];
    }
    
    // walking steps
    
    if (self.showWalkingSteps == YES) {
        
        if ([self.walkingSteps doubleValue] == 0) {
            
            [self.walkingStepsField setPlaceholder:@"0"];
            
        } else {
            
            [self.walkingStepsField setText:[self getFormattedStringFromFloat:[self.walkingSteps doubleValue]]];
        }
        
        if ([self.walkingStepsGoal doubleValue] == 0) {
            
            [self.walkingStepsGoalField setPlaceholder:@"0"];
            
        } else {
            
            [self.walkingStepsGoalField setText:[self getFormattedStringFromFloat:[self.walkingStepsGoal doubleValue]]];
        }
    }
    
    // exercise minutes
    
    if (self.showExerciseMinutes == YES) {
        
        if ([self.exerciseMinutes doubleValue] == 0) {
            
            [self.exerciseMinutesField setPlaceholder:@"0"];
            
        } else {
            
            [self.exerciseMinutesField setText:[self getFormattedStringFromFloat:[self.exerciseMinutes doubleValue]]];
        }
        
        if ([self.exerciseMinutesGoal doubleValue] == 0) {
            
            [self.exerciseMinutesGoalField setPlaceholder:@"0"];
            
        } else {
            
            [self.exerciseMinutesGoalField setText:[self getFormattedStringFromFloat:[self.exerciseMinutesGoal doubleValue]]];
        }
    }
    
    // sleep hours
    
    if (self.showSleepHours == YES) {
        
        if ([self.sleepHours doubleValue] == 0) {
            
            [self.sleepHoursField setPlaceholder:@"0"];
            
        } else {
            
            [self.sleepHoursField setText:[self getFormattedStringFromFloat:[self.sleepHours doubleValue]]];
        }
        
        if ([self.sleepHoursGoal doubleValue] == 0) {
            
            [self.sleepHoursGoalField setPlaceholder:@"0"];
            
        } else {
            
            [self.sleepHoursGoalField setText:[self getFormattedStringFromFloat:[self.sleepHoursGoal doubleValue]]];
        }
    }
    
    [self.scrollView setContentSize:CGSizeMake(screenWidth, vPos)];
}

- (void)updateActivity:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *myRequestString;
    NSString *weightStr = @"";
    NSString *walkingStepsStr = @"";
    NSString *exerciseMinutesStr = @"";
    NSString *sleepHoursStr = @"";
    NSString *weightGoalStr = @"";
    NSString *walkingStepsGoalStr = @"";
    NSString *exerciseMinutesGoalStr = @"";
    NSString *sleepHoursGoalStr = @"";
    NSString *customMetricStr = @"";
    NSString *customMetricGoalStr = @"";
    
    weightStr = [self.weightField text];
    weightGoalStr = [self.weightGoalField text];
    walkingStepsStr = [self.walkingStepsField text];
    walkingStepsGoalStr = [self.walkingStepsGoalField text];
    exerciseMinutesStr = [self.exerciseMinutesField text];
    exerciseMinutesGoalStr = [self.exerciseMinutesGoalField text];
    sleepHoursStr = [self.sleepHoursField text];
    sleepHoursGoalStr = [self.sleepHoursGoalField text];
    
    myRequestString = [NSString stringWithFormat:@"action=update_activity&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&weight=%@&weight_goal=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, weightStr, weightGoalStr];
    
    if (self.showWalkingSteps == YES) {
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&walking_steps=%@", walkingStepsStr]];
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&walking_steps_goal=%@", walkingStepsGoalStr]];
    }
    
    if (self.showExerciseMinutes == YES) {
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&exercise_minutes=%@", exerciseMinutesStr]];
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&exercise_minutes_goal=%@", exerciseMinutesGoalStr]];
    }
    
    if (self.showSleepHours == YES) {
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&sleep_hours=%@", sleepHoursStr]];
        
        myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&sleep_hours_goal=%@", sleepHoursGoalStr]];
    }
    
    // custom metrics
    if ([self.customMetrics count] > 1) {
        
        for (int i=1; i<=[self.customMetrics count] - 1; i++) {
            
            if ([[self.customMetricsLabels objectAtIndex:i] isEqualToString:@""]) {
                
                // do nothing - ignore this type of metric
                
            } else {
                
                
                if ([[self.customMetricsTypes objectAtIndex:i] isEqualToString:@"1"]) {
                    
                    customMetricStr = @"";
                    customMetricGoalStr = @"";
                    
                    customMetricStr = [NSString stringWithFormat:@"%@", [customMetricsField[i] text]];
                    customMetricGoalStr = [NSString stringWithFormat:@"%@", [customMetricsGoalField[i] text]];
                    
                    myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&metric%i=%@", i, customMetricStr]];
                    
                    myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&metric%i_goal=%@", i, customMetricGoalStr]];
                    
                } else { // [[customMetricsTypes objectAtIndex:i] isEqualToString:@"2"] -> checkbox
                    
                    if ([self.customMetrics[i] isEqualToString:@"1"]) {
                        
                        customMetricStr = @"1";
                        
                    } else {
                        
                        customMetricStr = @"0";
                    }
                    
                    myRequestString = [myRequestString stringByAppendingString:[NSString stringWithFormat:@"&metric%i=%@", i, customMetricStr]];
                }
            }
        }
    }
    
    myRequestString = [myRequestString stringByReplacingOccurrencesOfString:@"," withString:@""];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (IBAction)metricChecked:(id)sender {
    
    if ([self.customMetrics[[sender tag] - 20] isEqualToString:@"1"]) {
        
        self.customMetrics[[sender tag] - 20] = @"0";
        
        [sender setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        
    } else {
        
        self.customMetrics[[sender tag] - 20] = @"1";
        
        [sender setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
    }
}

- (IBAction)setReminder:(id)sender {
    
    UIButton *reminderButton = sender;
    
    self.reminderMetricID = reminderButton.tag;
    
    [self performSegueWithIdentifier:@"showRemindersFromActivity" sender:self];
}

- (NSString *)getFormattedStringFromFloat:(float) number {
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    
    NSString *groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
    
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    [formatter setGroupingSeparator:groupingSeparator];
    [formatter setGroupingSize:3];
    [formatter setAlwaysShowsDecimalSeparator:NO];
    [formatter setUsesGroupingSeparator:YES];
    
    NSString *formattedString = [formatter stringFromNumber:[NSNumber numberWithFloat:number]];
    
    return formattedString;
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    self.xmlParser = [[NSXMLParser alloc] initWithData:data];
    
    [self.xmlParser setDelegate:self];
    [self.xmlParser setShouldProcessNamespaces:NO];
    [self.xmlParser setShouldReportNamespacePrefixes:NO];
    [self.xmlParser setShouldResolveExternalEntities:NO];
    [self.xmlParser parse];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self handleURLError:error];

    self.sphConnection = nil;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    self.weight = nil;
    self.weightGoal = nil;
    self.walkingSteps = nil;
    self.walkingStepsGoal = nil;
    self.exerciseMinutes = nil;
    self.exerciseMinutesGoal = nil;
    self.sleepHours = nil;
    self.sleepHoursGoal = nil;
    self.weightUpdateSuccess = @"";
    
    [self.metricReminders removeAllObjects];
    
    [self.customMetrics removeAllObjects];
    [self.customMetricsTypes removeAllObjects];
    [self.customMetricsLabels removeAllObjects];
    [self.customMetricsGoals removeAllObjects];
    [self.customMetricsOfficial removeAllObjects];
    
    [self.metricReminders insertObject:@"" atIndex:0];
    
    [self.customMetrics insertObject:@"" atIndex:0];
    [self.customMetricsTypes insertObject:@"" atIndex:0];
    [self.customMetricsLabels insertObject:@"" atIndex:0];
    [self.customMetricsGoals insertObject:@"" atIndex:0];
    [self.customMetricsOfficial insertObject:@"" atIndex:0];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    self.showConnError = YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    
    self.currentElement = elementName;
    self.currentValue = [[NSMutableString alloc] init];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    
    if ([elementName isEqualToString:@"weight"]) {
        
        self.weight = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"weight_goal"]) {
        
        self.weightGoal = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"walking_steps"]) {
        
        self.showWalkingSteps = YES;
        self.walkingSteps = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"walking_steps_goal"]) {
        
        self.walkingStepsGoal = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"exercise_minutes"]) {
        
        self.showExerciseMinutes = YES;
        self.exerciseMinutes = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"exercise_minutes_goal"]) {
        
        self.exerciseMinutesGoal = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"sleep_hours"]) {
        
        self.showSleepHours = YES;
        self.sleepHours = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"sleep_hours_goal"]) {
        
        self.sleepHoursGoal = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"success"]) {
        
        self.weightUpdateSuccess = self.currentValue;
    }
    
    else if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
    }
    
    // custom metrics labels
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_label"]) {
        
        [self.customMetricsLabels insertObject:self.currentValue
                                       atIndex:[[[elementName
                                                  stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_label" withString:@""] integerValue]];
    }
    
    // custom metrics goals
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_goal"]) {
        
        [self.customMetricsGoals insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_goal" withString:@""] integerValue]];
    }
    
    // custom metrics types
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_type"]) {
        
        [self.customMetricsTypes insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_type" withString:@""] integerValue]];
    }
    
    // custom metrics official
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_official"]) {
        
        [self.customMetricsOfficial insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_official" withString:@""] integerValue]];
    }
    
    // all metrics reminders
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_reminder"]) {
        
        [self.metricReminders insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_reminder" withString:@""] integerValue]];
    }
    
    // custom metrics
    else if ([elementName hasPrefix:@"metric"]) {
        
        [self.customMetrics insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] integerValue]];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        if (self.doneEditingActivity == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else {
            
            [self showActivity];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTTrackerReminderViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.reminderType = @"metric";
    viewController.reminderMetricID = self.reminderMetricID;
}

- (IBAction)leftDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getActivity:HTWebSvcURL withState:0];
}

- (IBAction)rightDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    // KRISTINA!!!  Bratty bug...  :)
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    
    [self getActivity:HTWebSvcURL withState:0];
}

- (IBAction)cancelActivity:(id)sender {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)doneActivity:(id)sender {
    
    self.doneEditingActivity = YES;
    
    [self updateActivity:HTWebSvcURL withState:0];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
