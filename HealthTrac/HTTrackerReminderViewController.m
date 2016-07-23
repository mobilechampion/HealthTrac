//
//  HTTrackerReminderViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTTrackerReminderViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"

@interface HTTrackerReminderViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTTrackerReminderViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.navigationItem.rightBarButtonItem = [self checkButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Set a Reminder";
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:NO];
    
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
    
    self.reminderPickerValues = [[NSMutableArray alloc] init];
    self.reminderPickerValueAmPm = [[NSMutableArray alloc] init];
    
    [self.reminderPickerValues removeAllObjects];
    [self.reminderPickerValueAmPm removeAllObjects];
    
    self.reminderYN = [[NSString alloc] init];
    self.reminderDays = [[NSString alloc] init];
    self.reminderColorDay = [[NSString alloc] init];
    self.reminderTime = [[NSString alloc] init];
    self.reminderTimeAmPm = [[NSString alloc] init];
    
    self.doneSettingReminder = NO;
    
    self.radioButtonYesterdayChecked = NO;
    self.radioButtonTodayChecked = NO;
    
    self.reminderDailyChecked = NO;
    self.reminderMondayChecked = NO;
    self.reminderTuesdayChecked = NO;
    self.reminderWednesdayChecked = NO;
    self.reminderThursdayChecked = NO;
    self.reminderFridayChecked = NO;
    self.reminderSaturdayChecked = NO;
    self.reminderSundayChecked = NO;
    
    [self.reminderPickerValues insertObject:@"none" atIndex:0];
    
    for (int i=1; i<=12; i++) {
        
        [self.reminderPickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i];
    }
    
    [self.reminderPickerValueAmPm insertObject:@"am" atIndex:0];
    [self.reminderPickerValueAmPm insertObject:@"pm" atIndex:1];
    
    [self getReminder:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getReminder:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.reminderYN = @"";
    self.reminderDays = @"";
    self.reminderColorDay = @"";
    self.reminderTime = @"";
    self.reminderTimeAmPm = @"";
    
    self.doneSettingReminder = NO;
    
    if ([self.reminderType isEqualToString:@"metric"]) {
        
        self.reminderType = [NSString stringWithFormat:@"%ld", (long)self.reminderMetricID];
    }
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_tracker_reminder&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&metric=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.reminderType];
    
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

- (void)updateReminder:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneSettingReminder = YES;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([self.reminderTimeAmPm isEqualToString:@"pm"] &&
        [self.reminderTime integerValue] < 12) {
        
        self.reminderTime = [NSString stringWithFormat:@"%ld",
                                     (long)[self.reminderTime integerValue] + 12];
        
    } else if ([self.reminderTimeAmPm isEqualToString:@"am"]
               && [self.reminderTime integerValue] == 12) {
        
        self.reminderTime = @"0";
    }

    if (![self.reminderTime isEqualToString:@""]) {
        
        self.reminderYN = @"Y";
    }
    
    NSMutableString *reminderDays = [[NSMutableString alloc] initWithString:@""];
    
    if (self.reminderDailyChecked == YES) {
        
        [reminderDays appendString:@"DLY,"];
        
    }
    
    if (self.reminderMondayChecked == YES) {
        
        [reminderDays appendString:@"MON,"];
        
    }
    
    if (self.reminderTuesdayChecked == YES) {
        
        [reminderDays appendString:@"TUE,"];
        
    }
    
    if (self.reminderWednesdayChecked == YES) {
        
        [reminderDays appendString:@"WED,"];
        
    }
    
    if (self.reminderThursdayChecked == YES) {
        
        [reminderDays appendString:@"THU,"];
        
    }
    
    if (self.reminderFridayChecked == YES) {
        
        [reminderDays appendString:@"FRI,"];
        
    }
    
    if (self.reminderSaturdayChecked == YES) {
        
        [reminderDays appendString:@"SAT,"];
        
    }
    
    if (self.reminderSundayChecked == YES) {
        
        [reminderDays appendString:@"SUN,"];
    }
    
    if (![reminderDays isEqualToString:@""]) { // trim off the last comma
        
        [reminderDays setString:[reminderDays substringToIndex:[reminderDays length] - 1]];
    }
    
    if ([self.reminderType isEqualToString:@"color"]) {
        
        if (self.radioButtonYesterdayChecked == YES) {
            
            self.reminderColorDay = @"yesterday";
            
        } else if (self.radioButtonTodayChecked == YES) {
            
            self.reminderColorDay = @"today";
        }
    }
    
    myRequestString = [NSString stringWithFormat:@"action=update_tracker_reminder&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&metric=%@&reminder_days=%@&reminder_hour=%@&reminder_color_day=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.reminderType, reminderDays, self.reminderTime, self.reminderColorDay];
    
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

- (void)showReminder {
    
    NSArray *viewsToRemove = [self.reminderScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = -64;
    
    float reminderButtonHeight = ((screenHeight - 68) / 9);
    
    if ([self.reminderType isEqualToString:@"color"]) {
        
        reminderButtonHeight = ((screenHeight - 68) / 10);
    }

    UIButton *reminderButton;
    
    UIView *graySeparator;

    UILabel *reminderLabel;

    UIButton *checkBox;
    UIButton *radioButton;
    
    UIFont *reminderLabelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];

    UIToolbar *toolBar;

    UIBarButtonItem *barButtonDone;
    UIBarButtonItem *flex;
    
    reminderButtonHeight += 4;
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, screenWidth, reminderButtonHeight)];
    
    [reminderButton setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    reminderLabel = [[UILabel alloc]
                     initWithFrame:CGRectMake(16, 4, ((screenWidth - 32) / 2), (reminderButtonHeight - 8))];

    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Text Reminder"];

    [reminderButton addSubview:reminderLabel];

    self.reminderPickerView = [[UIPickerView alloc] init];

    self.reminderPickerView.tag = 1;
    self.reminderPickerView.delegate = self;
    self.reminderPickerView.showsSelectionIndicator = YES;
    
    self.reminderTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), ((reminderButtonHeight - 31) / 2.0), 90, 31)];

    [self.reminderTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.reminderTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                                green:(124/255.0)
                                                                 blue:(128/255.0)
                                                                alpha:1.0]];

    [self.reminderTextField setTextAlignment:NSTextAlignmentRight];

    // do we have a reminder?

    if (![self.reminderTime isEqualToString:@""]) {

        [self.reminderPickerValueAmPm removeAllObjects];

        [self.reminderPickerValueAmPm insertObject:@"am" atIndex:0];
        [self.reminderPickerValueAmPm insertObject:@"pm" atIndex:1];

        [self.reminderPickerView reloadAllComponents];

        [self.reminderPickerView selectRow:[self.reminderPickerValues indexOfObject:self.reminderTime] inComponent:0 animated:YES];

        [self.reminderPickerView selectRow:[self.reminderPickerValueAmPm indexOfObject:self.reminderTimeAmPm] inComponent:1 animated:YES];

        self.reminderTextField.text = [NSString stringWithFormat:@"%@:00%@",
                                              self.reminderTime,
                                              self.reminderTimeAmPm];
    }

    self.reminderTextField.delegate = self;
    self.reminderTextField.inputView = self.reminderPickerView;

    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];

    [toolBar setBarTintColor:[UIColor whiteColor]];

    barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(doneWithPicker:)];
    barButtonDone.tag = 101;

    flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    [barButtonDone setTitleTextAttributes:@{NSFontAttributeName:
                                                [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0],
                                            NSForegroundColorAttributeName: [UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]} forState:UIControlStateNormal];

    toolBar.items = [[NSArray alloc] initWithObjects:flex, barButtonDone, nil];

    self.reminderTextField.inputAccessoryView = toolBar;

    [reminderButton addSubview:self.reminderTextField];

    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];

    [reminderButton addSubview:graySeparator];
    
    [self.view addSubview:reminderButton];

    vPos += reminderButtonHeight;
    
    reminderButtonHeight -= 4;
    
    // color my day?
    
    if ([self.reminderType isEqualToString:@"color"]) {
        
        reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
        
        reminderLabel = [[UILabel alloc]
                         initWithFrame:CGRectMake(16, 0, 110, (reminderButtonHeight - 4))];
        
        [reminderLabel setFont:reminderLabelFont];
        [reminderLabel setTextColor:grayFontColor];
        [reminderLabel setTextAlignment:NSTextAlignmentLeft];
        [reminderLabel setText:@"To color my day:"];
        
        [reminderButton addSubview:reminderLabel];
        
        radioButton = [[UIButton alloc] initWithFrame:CGRectMake(130, ((reminderButtonHeight / 2) - 14), 24, 24)];
        
        if (self.radioButtonYesterdayChecked == YES) {

            [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];

        } else {

            [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
        }
        
        radioButton.enabled = YES;
        radioButton.userInteractionEnabled = YES;
        
        [radioButton setTag:1];
        
        [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
        
        [reminderButton addSubview:radioButton];
        
        reminderLabel = [[UILabel alloc]
                         initWithFrame:CGRectMake(162, 0, 70, (reminderButtonHeight - 4))];
        
        [reminderLabel setFont:reminderLabelFont];
        [reminderLabel setTextColor:grayFontColor];
        [reminderLabel setTextAlignment:NSTextAlignmentLeft];
        [reminderLabel setText:@"Yesterday"];
        
        [reminderButton addSubview:reminderLabel];
        
        radioButton = [[UIButton alloc] initWithFrame:CGRectMake(234, ((reminderButtonHeight / 2) - 14), 24, 24)];
        
        if (self.radioButtonTodayChecked == YES) {
            
            [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
            
        } else {
            
            [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
        }
        
        radioButton.enabled = YES;
        radioButton.userInteractionEnabled = YES;
        
        [radioButton setTag:2];
        
        [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
        
        [reminderButton addSubview:radioButton];
        
        reminderLabel = [[UILabel alloc]
                         initWithFrame:CGRectMake(266, 0, 48, (reminderButtonHeight - 4))];
        
        [reminderLabel setFont:reminderLabelFont];
        [reminderLabel setTextColor:grayFontColor];
        [reminderLabel setTextAlignment:NSTextAlignmentLeft];
        [reminderLabel setText:@"Today"];
        
        [reminderButton addSubview:reminderLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [reminderButton addSubview:graySeparator];
        
        [self.reminderScrollView addSubview:reminderButton];
        
        vPos += reminderButtonHeight;
    }

    // daily checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Daily"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderDailyChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:201];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:201];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // monday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Monday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderMondayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:202];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:202];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // tuesday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Tuesday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderTuesdayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:203];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:203];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // wednesday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Wednesday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderWednesdayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:204];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:204];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // thursday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Thursday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderThursdayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:205];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:205];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // friday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Friday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderFridayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:206];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:206];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // saturday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Saturday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderSaturdayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:207];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:207];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    // sunday checkbox
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, reminderButtonHeight)];
    
    reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), (reminderButtonHeight - 4))];
    
    [reminderLabel setFont:reminderLabelFont];
    [reminderLabel setTextColor:grayFontColor];
    [reminderLabel setTextAlignment:NSTextAlignmentLeft];
    [reminderLabel setText:@"Sunday"];
    
    [reminderButton addSubview:reminderLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 47), ((reminderButtonHeight - 34) / 2.0), 30, 30)];
    
    if (self.reminderSundayChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:208];
    
    [reminderButton addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (reminderButtonHeight - 4), screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [reminderButton addSubview:graySeparator];
    
    [reminderButton addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [reminderButton setTag:208];
    
    [self.reminderScrollView addSubview:reminderButton];
    
    vPos += reminderButtonHeight;
    
    [self.reminderScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
}

- (UIBarButtonItem *)backButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-back-arrow"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (UIBarButtonItem *)checkButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-check"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)checkButtonPressed {
    
    if ([self.reminderType isEqualToString:@"color"]) {
        
        if (self.radioButtonYesterdayChecked == YES) {
            
            self.reminderColorDay = @"yesterday";
            
        } else if (self.radioButtonTodayChecked == YES) {
            
            self.reminderColorDay = @"today";
            
        } else {
            
            self.reminderColorDay = @"";
        }
    }
    
    if ([self.reminderType isEqualToString:@"color"] &&
        [self.reminderColorDay isEqualToString:@""] &&
        ![self.reminderTime isEqualToString:@""] &&
        ![self.reminderDays isEqualToString:@""]) {
        
        [self.view makeToast:@"Please select Yesterday or Today for your Color My Day reminder"
                    duration:5.0 position:@"center"];
    
    } else {
        
        [self updateReminder:HTWebSvcURL withState:0];
    }
}

- (IBAction)checkBoxChecked:(id)sender {
    
    UIButton *button = sender;
    
    if (button.tag == 201) { // daily
        
        if (self.reminderDailyChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderDailyChecked = YES;
            self.reminderMondayChecked = YES;
            self.reminderTuesdayChecked = YES;
            self.reminderWednesdayChecked = YES;
            self.reminderThursdayChecked = YES;
            self.reminderFridayChecked = YES;
            self.reminderSaturdayChecked = YES;
            self.reminderSundayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderDailyChecked = NO;
            self.reminderMondayChecked = NO;
            self.reminderTuesdayChecked = NO;
            self.reminderWednesdayChecked = NO;
            self.reminderThursdayChecked = NO;
            self.reminderFridayChecked = NO;
            self.reminderSaturdayChecked = NO;
            self.reminderSundayChecked = NO;
        }
        
    } else if (button.tag == 202) { // monday
        
        if (self.reminderMondayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderMondayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderMondayChecked = NO;
        }
        
    } else if (button.tag == 203) { // tuesday
        
        if (self.reminderTuesdayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderTuesdayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderTuesdayChecked = NO;
        }
        
    } else if (button.tag == 204) { // wednesday
        
        if (self.reminderWednesdayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderWednesdayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderWednesdayChecked = NO;
        }
        
    } else if (button.tag == 205) { // thursday
        
        if (self.reminderThursdayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderThursdayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderThursdayChecked = NO;
        }
        
    } else if (button.tag == 206) { // friday
        
        if (self.reminderFridayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderFridayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderFridayChecked = NO;
        }
        
    } else if (button.tag == 207) { // saturday
        
        if (self.reminderSaturdayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderSaturdayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderSaturdayChecked = NO;
        }
        
    } else if (button.tag == 208) { // sunday
        
        if (self.reminderSundayChecked == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.reminderSundayChecked = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.reminderSundayChecked = NO;
        }
    }
    
    if (self.reminderMondayChecked == YES &&
        self.reminderTuesdayChecked == YES &&
        self.reminderWednesdayChecked == YES &&
        self.reminderThursdayChecked == YES &&
        self.reminderFridayChecked == YES &&
        self.reminderSaturdayChecked == YES &&
        self.reminderSundayChecked == YES) {
        
        self.reminderDailyChecked = YES;
    
    } else {
        
        self.reminderDailyChecked = NO;
    }
    
    NSMutableString *reminderDays = [[NSMutableString alloc] initWithString:@""];
    
    if (self.reminderDailyChecked == YES) {
        
        [reminderDays appendString:@"DLY,"];
        
    }
    
    if (self.reminderMondayChecked == YES) {
        
        [reminderDays appendString:@"MON,"];
        
    }
    
    if (self.reminderTuesdayChecked == YES) {
        
        [reminderDays appendString:@"TUE,"];
        
    }
    
    if (self.reminderWednesdayChecked == YES) {
        
        [reminderDays appendString:@"WED,"];
        
    }
    
    if (self.reminderThursdayChecked == YES) {
        
        [reminderDays appendString:@"THU,"];
        
    }
    
    if (self.reminderFridayChecked == YES) {
        
        [reminderDays appendString:@"FRI,"];
        
    }
    
    if (self.reminderSaturdayChecked == YES) {
        
        [reminderDays appendString:@"SAT,"];
        
    }
    
    if (self.reminderSundayChecked == YES) {
        
        [reminderDays appendString:@"SUN,"];
    }
    
    if (![reminderDays isEqualToString:@""]) { // trim off the last comma
        
        [reminderDays setString:[reminderDays substringToIndex:[reminderDays length] - 1]];
    }
    
    self.reminderDays = reminderDays;
    
    [self.reminderTextField resignFirstResponder];
    
    [self showReminder];
}

- (IBAction)radioButtonChecked:(id)sender {
    
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    switch (buttonTag) {
            
        case 1: // yesterday
            
            if (self.radioButtonYesterdayChecked == YES) {
                
                self.radioButtonYesterdayChecked = NO;
                
            } else {
                
                self.radioButtonYesterdayChecked = YES;
                self.radioButtonTodayChecked = NO;
            }
            break;
            
        case 2: // today
            
            if (self.radioButtonTodayChecked == YES) {
                
                self.radioButtonTodayChecked = NO;
                
            } else {
                
                self.radioButtonTodayChecked = YES;
                self.radioButtonYesterdayChecked = NO;
            }
            break;
            
        default:
            break;
    }
    
    if (self.radioButtonYesterdayChecked == YES) {
        
        self.reminderColorDay = @"yesterday";
        
    } else if (self.radioButtonTodayChecked == YES) {
        
        self.reminderColorDay = @"today";
        
    } else {
        
        self.reminderColorDay = @"";
    }
    
    [self.reminderTextField resignFirstResponder];
    
    [self showReminder];
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;
    
    if (barButtonItem.tag == 101) { // reminder
        
        [self.reminderTextField resignFirstResponder];
        
        [self showReminder];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    return NO;
}

#pragma  mark - UIPickerView delegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // reminder time
        
        NSString *theTime;
        NSString *theAmPm;
        
        theTime = [self.reminderPickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theAmPm = [self.reminderPickerValueAmPm
                   objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        self.reminderTime = theTime;
        self.reminderTimeAmPm = theAmPm;
        
        if ([theTime isEqualToString:@"none"]) {
            
            self.reminderTime = @"";
            self.reminderTimeAmPm = @"";
            
            self.reminderTextField.text = @"";
            
            [self.reminderPickerValueAmPm removeAllObjects];
            
            [self.reminderPickerValueAmPm insertObject:@"--" atIndex:0];
            
            [self.reminderPickerView reloadAllComponents];
            
            [self.reminderPickerView selectRow:0 inComponent:0 animated:YES];
            [self.reminderPickerView selectRow:0 inComponent:1 animated:YES];
            
            self.reminderDailyChecked = NO;
            self.reminderMondayChecked = NO;
            self.reminderTuesdayChecked = NO;
            self.reminderWednesdayChecked = NO;
            self.reminderThursdayChecked = NO;
            self.reminderFridayChecked = NO;
            self.reminderSaturdayChecked = NO;
            self.reminderSundayChecked = NO;
            
        } else {
            
            [self.reminderPickerValueAmPm removeAllObjects];
            
            [self.reminderPickerValueAmPm insertObject:@"am" atIndex:0];
            [self.reminderPickerValueAmPm insertObject:@"pm" atIndex:1];
            
            [self.reminderPickerView reloadAllComponents];
            
            NSInteger thisInteger = [theTime integerValue];
            
            theAmPm = [self.reminderPickerValueAmPm
                       objectAtIndex:[pickerView selectedRowInComponent:1]];
            
            self.reminderTime = theTime;
            self.reminderTimeAmPm = theAmPm;
            
            self.reminderTextField.text = [NSString stringWithFormat:@"%ld:00%@", (long)thisInteger, theAmPm];
        }
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // reminder
        
        if (component == 0) {  // numbers
            
            return 13;
            
        } else { // am, pm
            
            return [self.reminderPickerValueAmPm count]; // 1 or 2
        }
        
    } else {
        
        return 1;
    }
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    if (pickerView.tag == 1) { // reminder
        
        return 2;
        
    } else {
        
        return 1;
    }
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    
    if (pickerView.tag == 1) { // reminder
        
        if (component == 0) { // numbers
            
            title = [self.reminderPickerValues objectAtIndex:row];
            
            if (![title isEqualToString:@"none"]) {
                
                NSInteger thisInteger = [title integerValue];
                
                title = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else { // am, pm
            
            title = [self.reminderPickerValueAmPm objectAtIndex:row];
        }
        
    } else {
        
        title = [@"" stringByAppendingFormat:@"%ld",(long)row];
    }
    
    return title;
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    int sectionWidth;
    
    sectionWidth = 42;
    
    return sectionWidth;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *pickerLabel = (UILabel*)view;
    
    if (!pickerLabel) {
        
        pickerLabel = [[UILabel alloc] init];
        
        [pickerLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [pickerLabel setTextColor:[UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0]];
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
    }
    
    if (pickerView.tag == 1) { // reminder
        
        if (component == 0) {
            
            if ([[self.reminderPickerValues objectAtIndex:row] isEqualToString:@"none"]) {
                
                pickerLabel.text = @"none";
                
            } else {
                
                NSInteger thisInteger = [[self.reminderPickerValues objectAtIndex:row] integerValue];
                
                pickerLabel.text = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else { // am, pm
            
            pickerLabel.text = [self.reminderPickerValueAmPm objectAtIndex:row];
        }
        
    } else {
        
        pickerLabel.text = @"";
    }
    
    return pickerLabel;
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
    
    self.reminderYN = @"";
    self.reminderDays = @"";
    self.reminderColorDay = @"";
    self.reminderTime = @"";
    self.reminderTimeAmPm = @"";
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
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *cleanString = [[NSString alloc] init];
    
    cleanString = [appDelegate cleanStringAfterReceiving:self.currentValue];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"reminder_time"]
               && ![cleanString isEqualToString:@""]) {
        
        self.reminderTime = cleanString;
        
        if ([self.reminderTime integerValue] > 12
            && [self.reminderTime integerValue] != 24) {
            
            self.reminderTime = [NSString stringWithFormat:@"%ld", (long)[self.reminderTime integerValue] - 12];
            
            self.reminderTimeAmPm = @"pm";
            
        } else if ([self.reminderTime integerValue] == 24 ||
                   [self.reminderTime integerValue] == 0) {
            
            self.reminderTime = @"12";
            self.reminderTimeAmPm = @"am";
            
        } else if ([self.reminderTime integerValue] == 12) {
            
            self.reminderTime = @"12";
            self.reminderTimeAmPm = @"pm";
            
        } else {
            
            self.reminderTimeAmPm = @"am";
        }
        
    } else if ([elementName isEqualToString:@"reminder_days"]
               && ![cleanString isEqualToString:@""]) {
        
        self.reminderDays = cleanString;
        
    } else if ([elementName isEqualToString:@"reminder_color_day"]
               && ![cleanString isEqualToString:@""]) {
        
        self.reminderColorDay = cleanString;
        
        if ([self.reminderColorDay isEqualToString:@"yesterday"]) {
            
            self.radioButtonYesterdayChecked = YES;
            self.radioButtonTodayChecked = NO;
            
        } else if ([self.reminderColorDay isEqualToString:@"today"]) {
            
            self.radioButtonTodayChecked = YES;
            self.radioButtonYesterdayChecked = NO;
        }
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
        
        if (self.doneSettingReminder == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else {
            
            // this doesn't work in iOS 7
            
//            if ([self.reminderDays containsString:@"DLY"]) {
//                
//                self.reminderDailyChecked = YES;
//                
//            }
            
            if ([self.reminderDays rangeOfString:@"DLY" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderDailyChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"MON" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderMondayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"TUE" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderTuesdayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"WED" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderWednesdayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"THU" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderThursdayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"FRI" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderFridayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"SAT" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderSaturdayChecked = YES;
                
            }
            
            if ([self.reminderDays rangeOfString:@"SUN" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                self.reminderSundayChecked = YES;
                
            }
            
            if (self.reminderDailyChecked == YES) {
                
                self.reminderMondayChecked = YES;
                self.reminderTuesdayChecked = YES;
                self.reminderWednesdayChecked = YES;
                self.reminderThursdayChecked = YES;
                self.reminderFridayChecked = YES;
                self.reminderSaturdayChecked = YES;
                self.reminderSundayChecked = YES;
            }
            
            if (self.reminderMondayChecked == YES &&
                self.reminderTuesdayChecked == YES &&
                self.reminderWednesdayChecked == YES &&
                self.reminderThursdayChecked == YES &&
                self.reminderFridayChecked == YES &&
                self.reminderSaturdayChecked == YES &&
                self.reminderSundayChecked == YES) {
                
                self.reminderDailyChecked = YES;
                
            } else {
                
                self.reminderDailyChecked = NO;
            }
            
            [self showReminder];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
