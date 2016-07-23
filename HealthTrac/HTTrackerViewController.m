//
//  HTTrackerViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/20/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTTrackerViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"

@interface HTTrackerViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTTrackerViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    UIImageView *buttonImageView;
    
    int screenOffset = (self.view.frame.size.width - 320);
    int buttonImageOffset = (screenOffset / 4) + 63;
    
    [self.buttonColorMyDay.layer setCornerRadius:4.5f];
    [self.buttonColorMyDay.layer setBorderWidth:0.5];
    [self.buttonColorMyDay.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                green:(200/255.0)
                                                                 blue:(204/255.0)
                                                                alpha:1.0].CGColor];
    
    [self.buttonColorMyDay setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)]; //63
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-tracker-color-my-day"]];
    
    [self.buttonColorMyDay addSubview:buttonImageView];
    
    [self.buttonActivityTracker.layer setCornerRadius:2.5f];
    [self.buttonActivityTracker.layer setBorderWidth:0.7];
    [self.buttonActivityTracker.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                     green:(200/255.0)
                                                                      blue:(204/255.0)
                                                                     alpha:1.0].CGColor];
    
    [self.buttonActivityTracker setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-tracker-activity-tracker"]];
    
    [self.buttonActivityTracker addSubview:buttonImageView];
    
    [self.buttonMyJournal.layer setCornerRadius:2.5f];
    [self.buttonMyJournal.layer setBorderWidth:0.7];
    [self.buttonMyJournal.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                               green:(200/255.0)
                                                                blue:(204/255.0)
                                                               alpha:1.0].CGColor];
    
    [self.buttonMyJournal setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-tracker-my-journal"]];
    
    [self.buttonMyJournal addSubview:buttonImageView];
    
    [self.buttonSetAGoal.layer setCornerRadius:2.5f];
    [self.buttonSetAGoal.layer setBorderWidth:0.7];
    [self.buttonSetAGoal.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                              green:(200/255.0)
                                                               blue:(204/255.0)
                                                              alpha:1.0].CGColor];
    
    [self.buttonSetAGoal setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-tracker-set-a-goal"]];
    
    [self.buttonSetAGoal addSubview:buttonImageView];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:YES];
    
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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"MMMM yyyy"];
   
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    
    [self.leftDateArrow setUserInteractionEnabled:NO];
    [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-gray"] forState:UIControlStateNormal];
    
    [self.rightDateArrow setUserInteractionEnabled:NO];
    [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    
    [self getCalendar:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getCalendar:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.numberOfNewMessages = 0;
    self.numberOfEatingPlans = 0;
    self.numberOfLearningModules = 0;
    
    self.previousCalendarColors = [[NSMutableArray alloc] init];
    self.currentCalendarColors = [[NSMutableArray alloc] init];
    self.nextCalendarColors = [[NSMutableArray alloc] init];
    
    self.previousCalendarLogins = [[NSMutableArray alloc] init];
    self.currentCalendarLogins = [[NSMutableArray alloc] init];
    self.nextCalendarLogins = [[NSMutableArray alloc] init];
    
    self.previousCalendarActivity = [[NSMutableArray alloc] init];
    self.currentCalendarActivity = [[NSMutableArray alloc] init];
    self.nextCalendarActivity = [[NSMutableArray alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"MMMM yyyy"];
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.leftDateArrow setUserInteractionEnabled:YES];
    [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
    
    // if it's past today, make it today
    if (appDelegate.passYear == appDelegate.currentYear && appDelegate.passMonth == appDelegate.currentMonth && appDelegate.passDay > appDelegate.currentDay) {
        
        appDelegate.passDay = appDelegate.currentDay;
        
        NSString *dateString;
        
        dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                      (long)appDelegate.passDay,
                      (long)appDelegate.passMonth,
                      (long)appDelegate.passYear];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
        
        NSDate *dateFromString;
        
        dateFromString = [[NSDate alloc] init];
        dateFromString = [dateFormatter dateFromString:dateString];
        
        appDelegate.passDate = dateFromString;
    }
    
    if (appDelegate.passMonth == appDelegate.currentMonth && appDelegate.passYear == appDelegate.currentYear) {
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
        
    } else {
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    
    self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    
    myRequestString = [NSString stringWithFormat:@"action=get_calendar&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showCalendar {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSArray *viewsToRemove = [self.calendarView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }

    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    int calendarBlockCounter = 0;
    
    float calendarContainerWidth = screenWidth - 36;
    float calendarBlockWidth = (calendarContainerWidth / 7);
    float calendarBlockHeight = calendarBlockWidth; // for now
    
    if (screenHeight < 440) {
        calendarBlockHeight = calendarBlockHeight - 12;
    }
    
    NSInteger vPos = 0;
    NSInteger hPos = 0;
    
    NSInteger currentDay;
    NSInteger currentMonth;
    NSInteger currentYear;
    
    UIFont *weekdayFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:10.0];
    UIFont *calendarDayFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:0.53];
    UIColor *calendarDayGrayFontColor = [UIColor colorWithRed:(128/255.0) green:(128/255.0) blue:(128/255.0) alpha:1.0];
    
    UIView *graySeparator;
    
    UIButton *calendarBlock;
    
    UIImageView *buttonImageView;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(-18, 0, screenWidth, 1)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.calendarView addSubview:graySeparator];
    
    vPos += 1;
    
    // populate the weekday headers
    for (int i=1; i<=7; i++) {
        
        calendarBlock = [[UIButton alloc] initWithFrame:CGRectMake(hPos, vPos, calendarBlockWidth, calendarBlockHeight - 6)];
       
        calendarBlock.enabled = NO;
        calendarBlock.userInteractionEnabled = NO;
        calendarBlock.titleLabel.font = weekdayFont;
        
        [calendarBlock setTitleColor:grayFontColor forState:UIControlStateNormal];
        
        switch (i) {
                
            case 1:
                [calendarBlock setTitle:@"SUN" forState:UIControlStateNormal];
                break;
                
            case 2:
                [calendarBlock setTitle:@"MON" forState:UIControlStateNormal];
                break;
                
            case 3:
                [calendarBlock setTitle:@"TUE" forState:UIControlStateNormal];
                break;
                
            case 4:
                [calendarBlock setTitle:@"WED" forState:UIControlStateNormal];
                break;
                
            case 5:
                [calendarBlock setTitle:@"THU" forState:UIControlStateNormal];
                break;
                
            case 6:
                [calendarBlock setTitle:@"FRI" forState:UIControlStateNormal];
                break;
                
            case 7:
                [calendarBlock setTitle:@"SAT" forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
        
        [self.calendarView addSubview:calendarBlock];
        
        hPos += calendarBlockWidth;
    }
    
    vPos += calendarBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(-8, vPos - 7, screenWidth - 20, 1)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.calendarView addSubview:graySeparator];
    
    if (screenHeight < 440) {
        
        vPos -= 6;
        
    } else {
        
        vPos += 1;
    }
    
    hPos = 0;
    
    NSString *dateString;
    
    dateString = [NSString stringWithFormat:@"1-%ld-%ld", (long)appDelegate.passMonth, (long)appDelegate.passYear];// @"01-02-2010";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    // this is imporant - we set our input date format to match our input string
    // if format doesn't match you'll get nil from your string, so be careful
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSDate *dateFromString;
    NSDate *currentAppDate;
    NSDate *lastDateOfCurrentMonth;
    
    dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:dateString];
    
    NSDateComponents *dateComponents;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    dateComponents = [calendar components:NSWeekdayCalendarUnit fromDate:dateFromString];
    NSInteger weekday = [dateComponents weekday];
    
    // populate the previous month's days
    
    if (weekday > 1) {
        
        NSDate *currentDate = [appDelegate addNumberOfDays:(-(weekday - 1)) toDate:dateFromString];
        
        dateComponents = [calendar components:
                          (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:currentDate];
        
        currentDay = [dateComponents day];
        currentMonth = [dateComponents month];
        currentYear = [dateComponents year];
        
        while (currentDay <= 31) {
            
            dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                          (long)currentDay,
                          (long)currentMonth,
                          (long)currentYear];
            
            [dateFormatter setDateFormat:@"dd-MM-yyyy"];
            
            dateFromString = [[NSDate alloc] init];
            
            dateFromString = [dateFormatter dateFromString:dateString];
            
            if (dateFromString) { // this is a valid previous date
                
                calendarBlockCounter++;
                
                calendarBlock = [[UIButton alloc] initWithFrame:CGRectMake(hPos, vPos, calendarBlockWidth, calendarBlockHeight)];
                
                calendarBlock.enabled = YES;
                calendarBlock.userInteractionEnabled = YES;
                
                // clickable!
                
                [calendarBlock setTag:currentDay];
                
                [calendarBlock addTarget:self action:@selector(clickedPreviousMonthDay:) forControlEvents:UIControlEventTouchUpInside];
                
                if (screenHeight < 440) {
                    
                    int imageOffset = ((calendarBlockWidth - 25) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 25, 25)];
                } else {
                    
                    int imageOffset = ((calendarBlockWidth - 27) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 27, 27)];
                }
                
                if ([[self.previousCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"GREEN"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-green"];
                    
                } else if ([[self.previousCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"YELLOW"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-yellow"];
                    
                } else if ([[self.previousCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"RED"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-red"];
                    
                } else {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-gray"];
                }
                
                [calendarBlock addSubview:buttonImageView];
                
                calendarBlock.titleLabel.font = calendarDayFont;
                
                [calendarBlock setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                if (screenHeight < 440) {
                    
                    [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(12.5f, 0.4f, 0.0f, 0.0f)];
                    
                } else {
                    
                    [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(0.7f, 0.4f, 0.0f, 0.0f)];
                }
                
                [calendarBlock setTitle:[NSString stringWithFormat:@"%ld", (long)currentDay] forState:UIControlStateNormal];
                
                [self.calendarView addSubview:calendarBlock];
                
                hPos += calendarBlockWidth;
                
            }
            
            currentDay++;
        }
    }
    
    // populate the current month's days
    
    currentDay = 1;
    
    while (currentDay <= 31) {
        
        dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                      (long)currentDay,
                      (long)appDelegate.passMonth,
                      (long)appDelegate.passYear];
        
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
        
        dateFromString = [[NSDate alloc] init];
        currentAppDate = [[NSDate alloc] init];
        
        dateFromString = [dateFormatter dateFromString:dateString];
        
        currentAppDate = [dateFormatter dateFromString:[NSString stringWithFormat:@"%ld-%ld-%ld",
                                                        (long)appDelegate.currentDay,
                                                        (long)appDelegate.currentMonth,
                                                        (long)appDelegate.currentYear]];
        
        if (dateFromString) { // this is a valid current date
            
            lastDateOfCurrentMonth = dateFromString;
            
            dateComponents = [calendar components:NSWeekdayCalendarUnit fromDate:dateFromString];
            weekday = [dateComponents weekday];
            
            calendarBlockCounter++;
            
            if (calendarBlockCounter > 7) {
                calendarBlockCounter = 1;
                vPos += calendarBlockHeight + 2;
                hPos = 0;
            }
            
            calendarBlock = [[UIButton alloc] initWithFrame:CGRectMake(hPos, vPos, calendarBlockWidth, calendarBlockHeight)];
            
            if (screenHeight < 440) {
                
                if (appDelegate.passDay == currentDay) {
                
                    int imageOffset = ((calendarBlockWidth - 30) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 30, 30)];
                } else {
                    
                    int imageOffset = ((calendarBlockWidth - 25) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 25, 25)];
                }
                
            } else {
                
                if (appDelegate.passDay == currentDay) {
                    
                    int imageOffset = ((calendarBlockWidth - 36) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 36, 36)];
                } else {
                    
                    int imageOffset = ((calendarBlockWidth - 27) / 2);
                    
                    buttonImageView = [[UIImageView alloc]
                                       initWithFrame:CGRectMake(imageOffset, imageOffset, 27, 27)];
                }
            }
            
            // currentDate
            if ([dateFromString isEqualToDate:currentAppDate]) {
                
                [calendarBlock setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                calendarBlock.enabled = YES;
                calendarBlock.userInteractionEnabled = YES;
                
            } else if ([[dateFromString earlierDate:currentAppDate] isEqualToDate:currentAppDate]) {
                
                [calendarBlock setTitleColor:calendarDayGrayFontColor forState:UIControlStateNormal];
                
                calendarBlock.enabled = NO;
                calendarBlock.userInteractionEnabled = NO;
                
            } else {
                
                [calendarBlock setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                calendarBlock.enabled = YES;
                calendarBlock.userInteractionEnabled = YES;
            }
            
            // these things are only on active calendarBlocks
            if (calendarBlock.userInteractionEnabled == YES) {
                
                // clickable!
                
                [calendarBlock setTag:currentDay];
                
                [calendarBlock addTarget:self action:@selector(clickedCurrentMonthDay:) forControlEvents:UIControlEventTouchUpInside];
                
                if ([[self.currentCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"GREEN"]) {
                    
                    if (appDelegate.passDay == currentDay) {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-green-selected"];
                        
                    } else {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-green"];
                    }
                    
                } else if ([[self.currentCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"YELLOW"]) {
                    
                    if (appDelegate.passDay == currentDay) {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-yellow-selected"];
                        
                    } else {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-yellow"];
                    }
                    
                } else if ([[self.currentCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"RED"]) {
                    
                    if (appDelegate.passDay == currentDay) {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-red-selected"];
                        
                    } else {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-red"];
                    }
                    
                } else {
                    
                    if (![dateFromString isEqualToDate:currentAppDate]) {
                        
                        if (appDelegate.passDay == currentDay) {
                            
                            buttonImageView.image = [UIImage imageNamed:@"ht-calendar-gray-selected"];
                            
                        } else {
                            
                            buttonImageView.image = [UIImage imageNamed:@"ht-calendar-gray"];
                        }
                        
                    } else {
                        
                        [calendarBlock setTitleColor:calendarDayGrayFontColor forState:UIControlStateNormal];
                    }
                }
            }
            
            [calendarBlock addSubview:buttonImageView];
            
            // add the additional "today" indicator circle
            
            if ([dateFromString isEqualToDate:currentAppDate]) {
                
                if (screenHeight < 440) {
                    
                    if (appDelegate.passDay == currentDay) {
                        
                        int imageOffset = ((calendarBlockWidth - 30) / 2);
                        
                        buttonImageView = [[UIImageView alloc]
                                           initWithFrame:CGRectMake(imageOffset, imageOffset, 30, 30)];
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-today-selected"];
                        
                    } else {
                        
                        int imageOffset = ((calendarBlockWidth - 25) / 2);
                        
                        buttonImageView = [[UIImageView alloc]
                                           initWithFrame:CGRectMake(imageOffset, imageOffset, 25, 25)];
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-today"];
                    }
                    
                } else {
                    
                    if (appDelegate.passDay == currentDay) {
                        
                        int imageOffset = ((calendarBlockWidth - 36) / 2);
                        
                        buttonImageView = [[UIImageView alloc]
                                           initWithFrame:CGRectMake(imageOffset, imageOffset, 36, 36)];
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-today-selected"];
                    } else {
                        
                        int imageOffset = ((calendarBlockWidth - 27) / 2);
                        
                        buttonImageView = [[UIImageView alloc]
                                           initWithFrame:CGRectMake(imageOffset, imageOffset, 27, 27)];
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-today"];
                    }
                }
                
                [calendarBlock addSubview:buttonImageView];
            }
            
            calendarBlock.titleLabel.font = calendarDayFont;
            
            if (screenHeight < 440) {
                
                [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(12.5f, 0.4f, 0.0f, 0.0f)];
                
            } else {
                
                [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(0.7f, 0.4f, 0.0f, 0.0f)];
            }
            
            [calendarBlock setTitle:[NSString stringWithFormat:@"%ld", (long)currentDay] forState:UIControlStateNormal];
            
            [self.calendarView addSubview:calendarBlock];
            
            hPos += calendarBlockWidth;
        }
        
        currentDay++;
    }
    
    // populate the next month's days
    
    if (weekday < 7) {
        
        NSDate *currentDate = lastDateOfCurrentMonth;
        
        while (weekday < 7) {
            
            currentDate = [appDelegate addNumberOfDays:1 toDate:currentDate];
            
            dateComponents = [calendar components:
                              (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:currentDate];
            
            currentDay = [dateComponents day];
            
            calendarBlockCounter++;
            
            calendarBlock = [[UIButton alloc] initWithFrame:CGRectMake(hPos, vPos, calendarBlockWidth, calendarBlockHeight)];
            
            if (screenHeight < 440) {
                
                int imageOffset = ((calendarBlockWidth - 25) / 2);
                
                buttonImageView = [[UIImageView alloc]
                                   initWithFrame:CGRectMake(imageOffset, imageOffset, 25, 25)];
            } else {
                
                int imageOffset = ((calendarBlockWidth - 27) / 2);
                
                buttonImageView = [[UIImageView alloc]
                                   initWithFrame:CGRectMake(imageOffset, imageOffset, 27, 27)];
            }
            
            if ([dateFromString isEqualToDate:currentAppDate]) {
                
                [calendarBlock setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                calendarBlock.enabled = YES;
                calendarBlock.userInteractionEnabled = YES;
                
            } else if ([[currentDate earlierDate:currentAppDate] isEqualToDate:currentAppDate]) {
                
                calendarBlock.enabled = NO;
                calendarBlock.userInteractionEnabled = NO;
                
                [calendarBlock setTitleColor:calendarDayGrayFontColor forState:UIControlStateNormal];
                
            } else {
                
                [calendarBlock setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                
                calendarBlock.enabled = YES;
                calendarBlock.userInteractionEnabled = YES;
            }
            
            // there are only colors on active calendarBlocks
            if (calendarBlock.userInteractionEnabled == YES) {
                
                // clickable!
                
                [calendarBlock setTag:currentDay];
                
                [calendarBlock addTarget:self action:@selector(clickedNextMonthDay:) forControlEvents:UIControlEventTouchUpInside];
                
                if ([[self.nextCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"GREEN"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-green"];
                    
                } else if ([[self.nextCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"YELLOW"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-yellow"];
                    
                } else if ([[self.nextCalendarColors objectAtIndex:currentDay - 1] isEqualToString:@"RED"]) {
                    
                    buttonImageView.image = [UIImage imageNamed:@"ht-calendar-red"];
                    
                } else {
                    
                    if (![dateFromString isEqualToDate:currentAppDate]) {
                        
                        buttonImageView.image = [UIImage imageNamed:@"ht-calendar-gray"];
                        
                    } else {
                        
                        [calendarBlock setTitleColor:calendarDayGrayFontColor forState:UIControlStateNormal];
                    }
                }
            }
            
            [calendarBlock addSubview:buttonImageView];
            
            calendarBlock.titleLabel.font = calendarDayFont;
            
            if (screenHeight < 440) {
                
                [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(12.5f, 0.4f, 0.0f, 0.0f)];
                
            } else {
                
                [calendarBlock setTitleEdgeInsets:UIEdgeInsetsMake(0.7f, 0.4f, 0.0f, 0.0f)];
            }
            
            [calendarBlock setTitle:[NSString stringWithFormat:@"%ld", (long)currentDay] forState:UIControlStateNormal];
            
            [self.calendarView addSubview:calendarBlock];
            
            hPos += calendarBlockWidth;
            
            weekday++;
        }
    }
}

- (void)clickedCurrentMonthDay:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.passDay = [sender tag];
    
    NSString *dateString;
    
    dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                  (long)appDelegate.passDay,
                  (long)appDelegate.passMonth,
                  (long)appDelegate.passYear];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSDate *dateFromString;
    
    dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:dateString];
    
    appDelegate.passDate = dateFromString;
    
    [self showCalendar];
}

- (void)clickedPreviousMonthDay:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.passMonth = appDelegate.passMonth - 1;
    
    if (appDelegate.passMonth == 0) {
        
        appDelegate.passMonth = 12;
        appDelegate.passYear = appDelegate.passYear - 1;
    }
    
    appDelegate.passDay = [sender tag];
    
    NSString *dateString;
    
    dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                  (long)appDelegate.passDay,
                  (long)appDelegate.passMonth,
                  (long)appDelegate.passYear];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSDate *dateFromString;
    
    dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:dateString];
    
    appDelegate.passDate = dateFromString;
    
    [self getCalendar:HTWebSvcURL withState:0];
}

- (void)clickedNextMonthDay:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.passMonth = appDelegate.passMonth + 1;
    
    if (appDelegate.passMonth == 13) {
        
        appDelegate.passMonth = 12;
        appDelegate.passYear = appDelegate.passYear + 1;
    }
    
    appDelegate.passDay = [sender tag];
    
    NSString *dateString;
    
    dateString = [NSString stringWithFormat:@"%ld-%ld-%ld",
                  (long)appDelegate.passDay,
                  (long)appDelegate.passMonth,
                  (long)appDelegate.passYear];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSDate *dateFromString;
    
    dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:dateString];
    
    appDelegate.passDate = dateFromString;
    
    [self getCalendar:HTWebSvcURL withState:0];
}

- (IBAction)clickedColorMyDay:(id)sender {
    
    [self performSegueWithIdentifier:@"showColorMyDayFromTracker" sender:self];
}

- (IBAction)clickedActivityTracker:(id)sender {
    
    [self performSegueWithIdentifier:@"showActivityFromTracker" sender:self];
}

- (IBAction)clickedMyJournal:(id)sender {
    
    [self performSegueWithIdentifier:@"showJournalFromTracker" sender:self];
}

- (IBAction)clickedSetAGoal:(id)sender {
 
    [self performSegueWithIdentifier:@"showGoalFromTracker" sender:self];
}

- (IBAction)leftDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfMonths:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getCalendar:HTWebSvcURL withState:0];
}

- (IBAction)rightDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfMonths:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getCalendar:HTWebSvcURL withState:0];
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([self.xmlData length]) {
        
        self.xmlParser = [[NSXMLParser alloc] initWithData:self.xmlData];
        
        [self.xmlParser setDelegate:self];
        [self.xmlParser setShouldProcessNamespaces:NO];
        [self.xmlParser setShouldReportNamespacePrefixes:NO];
        [self.xmlParser setShouldResolveExternalEntities:NO];
        [self.xmlParser parse];
    }
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
    
    [self.previousCalendarColors removeAllObjects];
    [self.currentCalendarColors removeAllObjects];
    [self.nextCalendarColors removeAllObjects];
    
    [self.previousCalendarLogins removeAllObjects];
    [self.currentCalendarLogins removeAllObjects];
    [self.nextCalendarLogins removeAllObjects];
    
    [self.previousCalendarActivity removeAllObjects];
    [self.currentCalendarActivity removeAllObjects];
    [self.nextCalendarActivity removeAllObjects];
    
    [self.previousCalendarColors insertObject:@"" atIndex:0];
    [self.currentCalendarColors insertObject:@"" atIndex:0];
    [self.nextCalendarColors insertObject:@"" atIndex:0];
    
    [self.previousCalendarLogins insertObject:@"" atIndex:0];
    [self.currentCalendarLogins insertObject:@"" atIndex:0];
    [self.nextCalendarLogins insertObject:@"" atIndex:0];
    
    [self.previousCalendarActivity insertObject:@"" atIndex:0];
    [self.currentCalendarActivity insertObject:@"" atIndex:0];
    [self.nextCalendarActivity insertObject:@"" atIndex:0];
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
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName hasPrefix:@"prev_color_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:11] integerValue];
        myDay -= 1;
        
        //rich...
        if (myDay > [self.previousCalendarColors count]) {
            
            for (NSUInteger i=[self.previousCalendarColors count]; i<=myDay-1; i++) {
                
                [self.previousCalendarColors insertObject:@"" atIndex:i];
            }
        }
        
        [self.previousCalendarColors insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"current_color_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:14] integerValue];
        myDay -= 1;
        
        if (myDay > [self.currentCalendarColors count]) {
            
            for (NSUInteger i=[self.currentCalendarColors count]; i<=myDay-1; i++) {
                
                [self.currentCalendarColors insertObject:@"" atIndex:i];
            }
        }
        
        [self.currentCalendarColors insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"next_color_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:11] integerValue];
        myDay -= 1;
        
        if (myDay > [self.nextCalendarColors count]) {
            
            for (NSUInteger i=[self.nextCalendarColors count]; i<=myDay-1; i++) {
                
                [self.nextCalendarColors insertObject:@"" atIndex:i];
            }
        }
        
        [self.nextCalendarColors insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"prev_login_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:11] integerValue];
        myDay -= 1;
        
        if (myDay > [self.previousCalendarLogins count]) {
            
            for (NSUInteger i=[self.previousCalendarLogins count]; i<=myDay-1; i++) {
                
                [self.previousCalendarLogins insertObject:@"" atIndex:i];
            }
        }
        
        [self.previousCalendarLogins insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"current_login_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:14] integerValue];
        myDay -= 1;
        
        if (myDay > [self.currentCalendarLogins count]) {
            
            for (NSUInteger i=[self.currentCalendarLogins count]; i<=myDay-1; i++) {
                
                [self.currentCalendarLogins insertObject:@"" atIndex:i];
            }
        }
        
        [self.currentCalendarLogins insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"next_login_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:11] integerValue];
        myDay -= 1;
        
        if (myDay > [self.nextCalendarLogins count]) {
            
            for (NSUInteger i=[self.nextCalendarLogins count]; i<=myDay-1; i++) {
                
                [self.nextCalendarLogins insertObject:@"" atIndex:i];
            }
        }
        
        [self.nextCalendarLogins insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"prev_activity_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:14] integerValue];
        myDay -= 1;
        
        if (myDay > [self.previousCalendarActivity count]) {
            
            for (NSUInteger i=[self.previousCalendarActivity count]; i<=myDay-1; i++) {
                
                [self.previousCalendarActivity insertObject:@"" atIndex:i];
            }
        }
        
        [self.previousCalendarActivity insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"current_activity_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:17] integerValue];
        myDay -= 1;
        
        if (myDay > [self.currentCalendarActivity count]) {
            
            for (NSUInteger i=[self.currentCalendarActivity count]; i<=myDay-1; i++) {
                
                [self.currentCalendarActivity insertObject:@"" atIndex:i];
            }
        }
        
        [self.currentCalendarActivity insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName hasPrefix:@"next_activity_"]) {
        
        NSUInteger myDay = [[elementName substringFromIndex:14] integerValue];
        myDay -= 1;
        
        if (myDay > [self.nextCalendarActivity count]) {
            
            for (NSUInteger i=[self.nextCalendarActivity count]; i<=myDay-1; i++) {
                
                [self.nextCalendarActivity insertObject:@"" atIndex:i];
            }
        }
        
        [self.nextCalendarActivity insertObject:self.currentValue atIndex:myDay];
        
    } else if ([elementName isEqualToString:@"new_messages"]) {
        
        self.numberOfNewMessages = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"new_eating_plan"]) {
        
        self.numberOfEatingPlans = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"new_learning_modules"]) {
        
        self.numberOfLearningModules = [self.currentValue integerValue];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        NSInteger appIconBadgeCount = 0;
        appIconBadgeCount = self.numberOfNewMessages + self.numberOfLearningModules;
        if (appDelegate.hidePlanner == NO){
            appIconBadgeCount = appIconBadgeCount + self.numberOfEatingPlans;
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:appIconBadgeCount];
        
        UITabBarItem *itemDashboard;
        UITabBarItem *itemPlanner;
        UITabBarItem *itemLearn;
        UITabBarItem *itemMore;
        
        if (appDelegate.hidePlanner == YES) {
            
            itemDashboard = [self.tabBarController.tabBar.items objectAtIndex:0];
            itemLearn = [self.tabBarController.tabBar.items objectAtIndex:2];
            itemMore = [self.tabBarController.tabBar.items objectAtIndex:3];
            
        } else {
            
            itemDashboard = [self.tabBarController.tabBar.items objectAtIndex:0];
            itemPlanner = [self.tabBarController.tabBar.items objectAtIndex:2];
            itemLearn = [self.tabBarController.tabBar.items objectAtIndex:3];
            itemMore = [self.tabBarController.tabBar.items objectAtIndex:4];
            
            itemPlanner.badgeValue = nil;
        }
        
        itemDashboard.badgeValue = nil;
        itemLearn.badgeValue = nil;
        itemMore.badgeValue = nil;
        
        if (self.numberOfNewMessages > 0) {
            
            itemMore.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            
            NSMutableDictionary *dashboardUserPrefs = [[NSMutableDictionary alloc] init];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            NSString *userPrefsString;
            
            userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
            
            if([prefs objectForKey:userPrefsString] != nil) { // exists
                
                dashboardUserPrefs = [NSMutableDictionary dictionaryWithDictionary:[prefs objectForKey:userPrefsString]];
                
                if (![[dashboardUserPrefs objectForKey:@"Inbox"] isEqualToString:@"0"]) {
                    
                    itemDashboard.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
                }
                
            } else { // no prefs, but messages, so show it
                
                itemDashboard.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            }
        }
        
        if (self.numberOfEatingPlans > 0 && appDelegate.hidePlanner == NO) {
            
            itemPlanner.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfEatingPlans];
        }
        
        if (self.numberOfLearningModules > 0) {
            
            itemLearn.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfLearningModules];
        }
        
        [self showCalendar];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    UIViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
}


#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
