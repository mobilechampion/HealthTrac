//
//  HTAddActivitySelectItemViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddActivitySelectItemViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"

@interface HTAddActivitySelectItemViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddActivitySelectItemViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.addActivitySelectItemScrollView setBackgroundColor:[UIColor whiteColor]];
    
    self.navigationItem.rightBarButtonItem = [self checkButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Add Activity";
    
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
    [appDelegate checkAppDatesWithPlanner:YES];
    
    [super viewWillAppear:animated];

    self.addActivityTimePickerValues = [[NSMutableArray alloc] init];
    self.addActivityTimePickerValueFractions = [[NSMutableArray alloc] init];
    self.addActivityTimePickerValueAmPm = [[NSMutableArray alloc] init];
    
    self.addActivityReminderPickerValues = [[NSMutableArray alloc] init];
    self.addActivityReminderPickerValueFractions = [[NSMutableArray alloc] init];
    self.addActivityReminderPickerValueAmPm = [[NSMutableArray alloc] init];
    
    self.selectedActivityTime = [[NSString alloc] init];
    self.selectedActivityTimeFraction = [[NSString alloc] init];
    
    self.selectedActivityReminder = [[NSString alloc] init];
    self.selectedActivityReminderFraction = [[NSString alloc] init];
    self.selectedActivityReminderYN = [[NSString alloc] init];
    
    self.selectedActivityAddToFavorites = [[NSString alloc] init];
    self.selectedActivityRelaunchItem = [[NSString alloc] init];

    [self.addActivityTimePickerValues removeAllObjects];
    [self.addActivityTimePickerValueFractions removeAllObjects];
    [self.addActivityTimePickerValueAmPm removeAllObjects];
    
    [self.addActivityReminderPickerValues removeAllObjects];
    [self.addActivityReminderPickerValueFractions removeAllObjects];
    [self.addActivityReminderPickerValueAmPm removeAllObjects];
    
    [self.addActivityReminderPickerValues insertObject:[NSString stringWithFormat:@"none"] atIndex:0];
    
    for (int i=1; i<=12; i++) {
        
        [self.addActivityTimePickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i - 1];
        [self.addActivityReminderPickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i];
    }
    
    [self.addActivityTimePickerValueFractions insertObject:@":00" atIndex:0];
    [self.addActivityTimePickerValueFractions insertObject:@":30" atIndex:1];
    [self.addActivityTimePickerValueAmPm insertObject:@"am" atIndex:0];
    [self.addActivityTimePickerValueAmPm insertObject:@"pm" atIndex:1];
    
    [self.addActivityReminderPickerValueFractions insertObject:@"--" atIndex:0];
    [self.addActivityReminderPickerValueAmPm insertObject:@"--" atIndex:0];
    
    self.navigationItem.leftBarButtonItem = [self backButton];

    self.caloriesBurnedRecalc = YES;
    
    [self getActivityItem:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getActivityItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.selectedActivityName = @"";
    
    self.addActivityToFavorites = NO;
    self.doneAddingActivity = NO;
    
    if (self.relaunchPlannerItem == YES) {
        
        if (self.relaunchItemID == 0) {
            
            self.relaunchItemID = self.selectedActivityID;
        }
    }
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    myRequestString = [NSString stringWithFormat:@"action=get_add_activity_select_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%ld&relaunch_id=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addActivityCategory, (long)self.selectedActivityID, (long)self.relaunchItemID];

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

- (void)addActivityItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([self.selectedActivityTimeAmPm isEqualToString:@"pm"]
        && [self.selectedActivityTime integerValue] < 12) {
        
        self.selectedActivityTime = [NSString stringWithFormat:@"%ld",
                                 (long)[self.selectedActivityTime integerValue] + 12];
        
    } else if ([self.selectedActivityTimeAmPm isEqualToString:@"am"]
               && [self.selectedActivityTime integerValue] == 12) {
        
        self.selectedActivityTime = @"0";
    }
    
    self.selectedActivityTimeFraction = [self.selectedActivityTimeFraction
                                     stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    if ([self.selectedActivityReminderAmPm isEqualToString:@"pm"] &&
        [self.selectedActivityReminder integerValue] < 12) {
        
        self.selectedActivityReminder = [NSString stringWithFormat:@"%ld",
                                     (long)[self.selectedActivityReminder integerValue] + 12];
        
    } else if ([self.selectedActivityReminderAmPm isEqualToString:@"am"]
               && [self.selectedActivityReminder integerValue] == 12) {
        
        self.selectedActivityReminder = @"0";
    }
    
    self.selectedActivityReminderFraction = [self.selectedActivityReminderFraction
                                         stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    if (![self.selectedActivityReminder isEqualToString:@""]) {
        
        self.selectedActivityReminderYN = @"Y";
    }
    
    if (self.addActivityToFavorites == YES) {
        
        self.selectedActivityAddToFavorites = @"Y";
    }
    
    self.selectedActivityName = self.selectedActivityNameTextField.text;
    
    self.selectedActivityName = [appDelegate cleanStringBeforeSending:self.selectedActivityName];
    
    if (self.relaunchPlannerItem == YES) {
        
        self.selectedActivityRelaunchItem = @"true";
        self.selectedActivityRelaunchItemID = [NSString stringWithFormat:@"%ld", (long)self.relaunchItemID];
        
    } else {
        
        self.selectedActivityRelaunchItem = @"false";
        self.selectedActivityRelaunchItemID = @"";
    }
    
    self.selectedActivityDuration = self.durationTextField.text;
    self.selectedActivityCaloriesBurned = self.caloriesBurnedTextField.text;
    
    if ([self.selectedActivityDuration isEqualToString:@""]
        || self.selectedActivityDuration == nil) {
        
        self.selectedActivityDuration = @"0";
    }
    
    if ([self.selectedActivityCaloriesBurned isEqualToString:@""]
        || self.selectedActivityCaloriesBurned == nil) {
        
        self.selectedActivityCaloriesBurned = @"0";
    }
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]
        && ![self.selectedActivityType isEqualToString:@""] && self.selectedActivityType != nil) {
        
        self.addActivityCategory = self.selectedActivityType;
    }
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_activity_add_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%ld&hour=%@&hour_half=%@&name=%@&reminder=%@&reminder_half=%@&reminder_yn=%@&add_to_favs=%@&relaunch=%@&relaunch_id=%@&plan_calories=%@&duration=%@&calories_burned=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addActivityCategory, (long)self.selectedActivityID, self.selectedActivityTime, self.selectedActivityTimeFraction, self.selectedActivityName, self.selectedActivityReminder, self.selectedActivityReminderFraction, self.selectedActivityReminderYN, self.selectedActivityAddToFavorites, self.selectedActivityRelaunchItem, self.selectedActivityRelaunchItemID, @"", self.selectedActivityDuration, self.selectedActivityCaloriesBurned];
    
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

- (void)showActivityItem {
    
    NSArray *viewsToRemove = [self.addActivitySelectItemScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 0;
    NSInteger hPos = 0;
    
    UIView *selectedItemView;
    UIView *graySeparator;
    
    UILabel *selectedItemLabel;
    
    UIButton *checkBox;
    
    UIFont *foodSectionFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    // activity name

    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, 57)];
    
    [selectedItemView setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    self.selectedActivityNameTextField = [[HTTextField alloc]
                        initHTDefaultWithFrame:CGRectMake(16, 17, (screenWidth - 32), 24)];
    
    [self.selectedActivityNameTextField setTextAlignment:NSTextAlignmentLeft];
    [self.selectedActivityNameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.selectedActivityNameTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    self.selectedActivityNameTextField.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *color = [UIColor colorWithRed:(117/255.0)
                                     green:(124/255.0)
                                      blue:(128/255.0)
                                     alpha:0.6];
    
    self.selectedActivityNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Activity description" attributes:@{NSForegroundColorAttributeName: color}];
    
    self.selectedActivityNameTextField.text = self.selectedActivityName;
    
    [selectedItemView addSubview:self.selectedActivityNameTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 53, screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.view addSubview:selectedItemView];
    
    vPos -= 7;
    
    // add to planner
    
    UIToolbar *toolBar;
    
    UIBarButtonItem *barButtonDone;
    UIBarButtonItem *flex;
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:foodSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Add to Planner"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.addActivityTimePickerView = [[UIPickerView alloc] init];
    
    self.addActivityTimePickerView.tag = 2;
    self.addActivityTimePickerView.delegate = self;
    self.addActivityTimePickerView.showsSelectionIndicator = YES;
    
    self.addActivityTimeTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 9, 90, 31)];
    
    [self.addActivityTimeTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.addActivityTimeTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                            green:(124/255.0)
                                                             blue:(128/255.0)
                                                            alpha:1.0]];
    
    [self.addActivityTimeTextField setTextAlignment:NSTextAlignmentRight];
    
    if ([self.selectedActivityTime isEqualToString:@""]) {
        
        self.selectedActivityTime = @"12";
        self.selectedActivityTimeFraction = @":00";
        self.selectedActivityTimeAmPm = @"pm";
    }
    
    [self.addActivityTimePickerView selectRow:[self.addActivityTimePickerValues indexOfObject:self.selectedActivityTime] inComponent:0 animated:YES];
    
    [self.addActivityTimePickerView selectRow:[self.addActivityTimePickerValueFractions indexOfObject:self.selectedActivityTimeFraction] inComponent:1 animated:YES];
    
    [self.addActivityTimePickerView selectRow:[self.addActivityTimePickerValueAmPm indexOfObject:self.selectedActivityTimeAmPm] inComponent:2 animated:YES];
    
    self.addActivityTimeTextField.text = [NSString stringWithFormat:@"%@%@%@",
                                      self.selectedActivityTime,
                                      self.selectedActivityTimeFraction,
                                      self.selectedActivityTimeAmPm];
    
    self.addActivityTimeTextField.delegate = self;
    self.addActivityTimeTextField.inputView = self.addActivityTimePickerView;
    
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    
    [toolBar setBarTintColor:[UIColor whiteColor]];
    
    barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(doneWithPicker:)];
    barButtonDone.tag = 102;
    
    flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [barButtonDone setTitleTextAttributes:@{NSFontAttributeName:
                                                [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0],
                                            NSForegroundColorAttributeName: [UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]} forState:UIControlStateNormal];
    
    toolBar.items = [[NSArray alloc] initWithObjects:flex, barButtonDone, nil];
    
    self.addActivityTimeTextField.inputAccessoryView = toolBar;
    
    [selectedItemView addSubview:self.addActivityTimeTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addActivitySelectItemScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // text reminder
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:foodSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Text Reminder"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.addActivityReminderPickerView = [[UIPickerView alloc] init];
    
    self.addActivityReminderPickerView.tag = 3;
    self.addActivityReminderPickerView.delegate = self;
    self.addActivityReminderPickerView.showsSelectionIndicator = YES;
    
    self.addActivityReminderTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 9, 90, 31)];
    
    [self.addActivityReminderTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.addActivityReminderTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                                    green:(124/255.0)
                                                                     blue:(128/255.0)
                                                                    alpha:1.0]];
    
    [self.addActivityReminderTextField setTextAlignment:NSTextAlignmentRight];
    
    // do we have a reminder?
    
    if (![self.selectedActivityReminder isEqualToString:@""]) {
        
        [self.addActivityReminderPickerValueFractions removeAllObjects];
        [self.addActivityReminderPickerValueAmPm removeAllObjects];
        
        [self.addActivityReminderPickerValueFractions insertObject:@":00" atIndex:0];
        [self.addActivityReminderPickerValueFractions insertObject:@":15" atIndex:1];
        [self.addActivityReminderPickerValueFractions insertObject:@":30" atIndex:2];
        [self.addActivityReminderPickerValueFractions insertObject:@":45" atIndex:3];
        
        [self.addActivityReminderPickerValueAmPm insertObject:@"am" atIndex:0];
        [self.addActivityReminderPickerValueAmPm insertObject:@"pm" atIndex:1];
        
        [self.addActivityReminderPickerView reloadAllComponents];
        
        [self.addActivityReminderPickerView selectRow:[self.addActivityReminderPickerValues indexOfObject:self.selectedActivityReminder] inComponent:0 animated:YES];
        
        [self.addActivityReminderPickerView selectRow:[self.addActivityReminderPickerValueFractions indexOfObject:self.selectedActivityReminderFraction] inComponent:1 animated:YES];
        
        [self.addActivityReminderPickerView selectRow:[self.addActivityReminderPickerValueAmPm indexOfObject:self.selectedActivityReminderAmPm] inComponent:2 animated:YES];
        
        self.addActivityReminderTextField.text = [NSString stringWithFormat:@"%@%@%@",
                                                  self.selectedActivityReminder,
                                                  self.selectedActivityReminderFraction,
                                                  self.selectedActivityReminderAmPm];
    }
    
    self.addActivityReminderTextField.delegate = self;
    self.addActivityReminderTextField.inputView = self.addActivityReminderPickerView;
    
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
    
    [toolBar setBarTintColor:[UIColor whiteColor]];
    
    barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(doneWithPicker:)];
    barButtonDone.tag = 103;
    
    flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    [barButtonDone setTitleTextAttributes:@{NSFontAttributeName:
                                                [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0],
                                            NSForegroundColorAttributeName: [UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]} forState:UIControlStateNormal];
    
    toolBar.items = [[NSArray alloc] initWithObjects:flex, barButtonDone, nil];
    
    self.addActivityReminderTextField.inputAccessoryView = toolBar;
    
    [selectedItemView addSubview:self.addActivityReminderTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addActivitySelectItemScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // duration
    
    if ([self.addActivityCategory isEqualToString:@"exercise"]
        || ([self.addActivityCategory isEqualToString:@"favorites"]
            && [self.selectedActivityType isEqualToString:@"exercise"])) {
    
        selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
        
        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
        
        [selectedItemLabel setFont:foodSectionFont];
        [selectedItemLabel setTextColor:grayFontColor];
        [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
        [selectedItemLabel setText:@"Duration (minutes)"];
        
        [selectedItemView addSubview:selectedItemLabel];
        
        self.durationTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 9, 90, 31)];
        
        [self.durationTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [self.durationTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                             green:(124/255.0)
                                                              blue:(128/255.0)
                                                             alpha:1.0]];
        
        [self.durationTextField setTextAlignment:NSTextAlignmentRight];
        
        self.durationTextField.text = [NSString stringWithFormat:@"%@",
                                       self.selectedActivityDuration];
        
        [self.durationTextField setTag:1];
        [self.durationTextField setDelegate:self];
        [self.durationTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        [selectedItemView addSubview:self.durationTextField];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [selectedItemView addSubview:graySeparator];
        
        [self.addActivitySelectItemScrollView addSubview:selectedItemView];
        
        vPos += 53;
    }
    
    // calories burned
    
    if ([self.addActivityCategory isEqualToString:@"exercise"]
        || ([self.addActivityCategory isEqualToString:@"favorites"]
            && [self.selectedActivityType isEqualToString:@"exercise"])) {
        
        selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
        
        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
        
        [selectedItemLabel setFont:foodSectionFont];
        [selectedItemLabel setTextColor:grayFontColor];
        [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
        [selectedItemLabel setText:@"Calories Burned"];
        
        [selectedItemView addSubview:selectedItemLabel];
        
        self.caloriesBurnedTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 9, 90, 31)];
        
        [self.caloriesBurnedTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [self.caloriesBurnedTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                             green:(124/255.0)
                                                              blue:(128/255.0)
                                                             alpha:1.0]];
        
        [self.caloriesBurnedTextField setTextAlignment:NSTextAlignmentRight];
        
        self.caloriesBurnedTextField.text = [NSString stringWithFormat:@"%@",
                                       self.selectedActivityCaloriesBurned];
        
        [selectedItemView addSubview:self.caloriesBurnedTextField];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [selectedItemView addSubview:graySeparator];
        
        [self.caloriesBurnedTextField setTag:2];
        [self.caloriesBurnedTextField setDelegate:self];
        [self.caloriesBurnedTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
        [self.addActivitySelectItemScrollView addSubview:selectedItemView];
        
        vPos += 53;
    }
    
    // add to favorites
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];

    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:foodSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Add to Favorites"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (screenWidth - 47);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 9, 31, 31)];
    
    if (self.addActivityToFavorites == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:201];
    
    [selectedItemView addSubview:checkBox];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];

    [selectedItemView addSubview:graySeparator];

    [self.addActivitySelectItemScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    [self.addActivitySelectItemScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
    
    if ([self.selectedActivityNameTextField.text isEqualToString:@""]) {
        
        [self.selectedActivityNameTextField becomeFirstResponder];
    }
}

- (UIBarButtonItem *) backButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-back-arrow"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (UIBarButtonItem *) checkButton {
    
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
    
    NSString *checkString = [self.selectedActivityNameTextField.text stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceCharacterSet]];
    
    if ([checkString isEqualToString:@""]) {
        
        NSString *alertString;
        
        alertString = @"Please enter your\nActivity Description";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedActivityNameTextField becomeFirstResponder];
        
    } else {
        
        self.doneAddingActivity = YES;
        
        [self addActivityItem:HTWebSvcURL withState:0];
    }
}

- (IBAction) checkBoxChecked:(id)sender {
    
    UIButton *button = sender;
    
    if (button.tag == 201) { // add to favorites
        
        if (self.addActivityToFavorites == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.addActivityToFavorites = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.addActivityToFavorites = NO;
        }
    }
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;
    
    if (barButtonItem.tag == 102) { // add food time
        
        [self.addActivityTimeTextField resignFirstResponder];
        
    } else if (barButtonItem.tag == 103) { // add food reminder
        
        [self.addActivityReminderTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField.tag == 1 || textField.tag == 2) {
        
        return YES;
        
    } else {
        
        return NO;
    }
}

- (void)textFieldDidChange:(id)sender {
    
    UITextField *textField = sender;
    
    if (textField.tag == 1 && self.caloriesBurnedRecalc == YES) { // duration
        
        float calcValue = [textField.text floatValue] * self.globalCaloriesBurned;
        
        [self.caloriesBurnedTextField setText:[NSString stringWithFormat:@"%.0f", calcValue]];
    
    } else if (textField.tag == 2) { // caloriesBurnedRecalc
        
        self.caloriesBurnedRecalc = NO;
    }
}

#pragma  mark - UIPickerView delegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView.tag == 2) { // add to planner time
        
        NSString *theTime;
        NSString *theFraction;
        NSString *theAmPm;
        
        theTime = [self.addActivityTimePickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theFraction = [self.addActivityTimePickerValueFractions
                       objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        theAmPm = [self.addActivityTimePickerValueAmPm
                   objectAtIndex:[pickerView selectedRowInComponent:2]];
        
        self.selectedActivityTime = theTime;
        self.selectedActivityTimeFraction = theFraction;
        self.selectedActivityTimeAmPm = theAmPm;
        
        NSInteger thisInteger = [theTime integerValue];
        
        self.addActivityTimeTextField.text = [NSString stringWithFormat:@"%ld%@%@", (long)thisInteger, theFraction, theAmPm];
        
    } else if (pickerView.tag == 3) { // add food reminder time
        
        NSString *theTime;
        NSString *theFraction;
        NSString *theAmPm;
        
        theTime = [self.addActivityReminderPickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theFraction = [self.addActivityReminderPickerValueFractions
                       objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        theAmPm = [self.addActivityReminderPickerValueAmPm
                   objectAtIndex:[pickerView selectedRowInComponent:2]];
        
        self.selectedActivityReminder = theTime;
        self.selectedActivityReminderFraction = theFraction;
        self.selectedActivityReminderAmPm = theAmPm;
        
        if ([theTime isEqualToString:@"none"]) {
            
            self.selectedActivityReminder = @"";
            self.selectedActivityReminderFraction = @"";
            self.selectedActivityReminderAmPm = @"";
            
            self.addActivityReminderTextField.text = @"";
            
            [self.addActivityReminderPickerValueFractions removeAllObjects];
            [self.addActivityReminderPickerValueAmPm removeAllObjects];
            
            [self.addActivityReminderPickerValueFractions insertObject:@"--" atIndex:0];
            [self.addActivityReminderPickerValueAmPm insertObject:@"--" atIndex:0];
            
            [self.addActivityReminderPickerView reloadAllComponents];
            
            [self.addActivityReminderPickerView selectRow:0 inComponent:1 animated:YES];
            [self.addActivityReminderPickerView selectRow:0 inComponent:2 animated:YES];
            
        } else {
            
            [self.addActivityReminderPickerValueFractions removeAllObjects];
            [self.addActivityReminderPickerValueAmPm removeAllObjects];
            
            [self.addActivityReminderPickerValueFractions insertObject:@":00" atIndex:0];
            [self.addActivityReminderPickerValueFractions insertObject:@":15" atIndex:1];
            [self.addActivityReminderPickerValueFractions insertObject:@":30" atIndex:2];
            [self.addActivityReminderPickerValueFractions insertObject:@":45" atIndex:3];
            
            [self.addActivityReminderPickerValueAmPm insertObject:@"am" atIndex:0];
            [self.addActivityReminderPickerValueAmPm insertObject:@"pm" atIndex:1];
            
            [self.addActivityReminderPickerView reloadAllComponents];
            
            NSInteger thisInteger = [theTime integerValue];
            
            theFraction = [self.addActivityReminderPickerValueFractions
                           objectAtIndex:[pickerView selectedRowInComponent:1]];
            
            theAmPm = [self.addActivityReminderPickerValueAmPm
                       objectAtIndex:[pickerView selectedRowInComponent:2]];
            
            self.selectedActivityReminder = theTime;
            self.selectedActivityReminderFraction = theFraction;
            self.selectedActivityReminderAmPm = theAmPm;
            
            self.addActivityReminderTextField.text = [NSString stringWithFormat:@"%ld%@%@", (long)thisInteger, theFraction, theAmPm];
        }
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView.tag == 2) { // add food time
        
        if (component == 0) {  // numbers
            
            return 12;
            
        } else if (component == 1) { // fractions
            
            return 2;
            
        } else { // am, pm
            
            return 2;
        }
        
    } else if (pickerView.tag == 3) { // add food reminder
        
        if (component == 0) {  // numbers
            
            return 13;
            
        } else if (component == 1) { // fractions
            
            return [self.addActivityReminderPickerValueFractions count]; // 1 or 4
            
        } else { // am, pm
            
            return [self.addActivityReminderPickerValueAmPm count]; // 1 or 2
        }
        
    } else {
        
        return 1;
    }
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    if (pickerView.tag == 2 || pickerView.tag == 3) { // add food time, reminder
        
        return 3;
        
    } else {
        
        return 1;
    }
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    
    if (pickerView.tag == 2) { // add food time
        
        if (component == 0) { // numbers
            
            title = [self.addActivityTimePickerValues objectAtIndex:row];
            
            NSInteger thisInteger = [title integerValue];
            
            title = [NSString stringWithFormat:@"%d", (int)thisInteger];
            
        } else if (component == 1) { // fractions
            
            title = [self.addActivityTimePickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            title = [self.addActivityTimePickerValueAmPm objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 3) { // add food reminder
        
        if (component == 0) { // numbers
            
            title = [self.addActivityReminderPickerValues objectAtIndex:row];
            
            if (![title isEqualToString:@"none"]) {
                
                NSInteger thisInteger = [title integerValue];
                
                title = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else if (component == 1) { // fractions
            
            title = [self.addActivityReminderPickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            title = [self.addActivityReminderPickerValueAmPm objectAtIndex:row];
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
    
    if (pickerView.tag == 2) { // add food time
        
        if (component == 0) {
            
            NSInteger thisInteger = [[self.addActivityTimePickerValues objectAtIndex:row] integerValue];

            pickerLabel.text = [NSString stringWithFormat:@"%d", (int)thisInteger];
            
        } else if (component == 1) { // fractions
            
            pickerLabel.text = [self.addActivityTimePickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            pickerLabel.text = [self.addActivityTimePickerValueAmPm objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 3) { // add food reminder
        
        if (component == 0) {
            
            if ([[self.addActivityReminderPickerValues objectAtIndex:row] isEqualToString:@"none"]) {
                
                pickerLabel.text = @"none";
                
            } else {
                
                NSInteger thisInteger = [[self.addActivityReminderPickerValues objectAtIndex:row] integerValue];
                
                pickerLabel.text = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else if (component == 1) { // fractions
            
            pickerLabel.text = [self.addActivityReminderPickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            pickerLabel.text = [self.addActivityReminderPickerValueAmPm objectAtIndex:row];
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
    
    self.selectedActivityName = @"";
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
        
    } else if ([elementName isEqualToString:@"activity_id"]) {
        
        self.selectedActivityID = [cleanString integerValue];
        
    } else if ([elementName isEqualToString:@"activity_type"]) {
        
        self.selectedActivityType = cleanString;
        
    } else if ([elementName isEqualToString:@"activity_notes"]) {
        
        self.selectedActivityName = cleanString;
        
    } else if ([elementName isEqualToString:@"activity_calories_burned"]) {
        
        self.selectedActivityCaloriesBurned = cleanString;
        
    } else if ([elementName isEqualToString:@"activity_duration_minutes"]) {
        
        self.selectedActivityDuration = cleanString;
        
    } else if ([elementName isEqualToString:@"activity_item_time"]
               && ![cleanString isEqualToString:@""]) {
        
        self.selectedActivityTime = cleanString;
        
        if ([self.selectedActivityTime integerValue] > 12
            && [self.selectedActivityTime integerValue] != 24) {
            
            self.selectedActivityTime = [NSString stringWithFormat:@"%ld", (long)[self.selectedActivityTime integerValue] - 12];
            
            self.selectedActivityTimeAmPm = @"pm";
            
        } else if ([self.selectedActivityTime integerValue] == 24 ||
                   [self.selectedActivityTime integerValue] == 0) {
            
            self.selectedActivityTime = @"12";
            self.selectedActivityTimeAmPm = @"am";
            
        }  else if ([self.selectedActivityTime integerValue] == 12) {
            
            self.selectedActivityTime = @"12";
            self.selectedActivityTimeAmPm = @"pm";
            
        } else {
            
            self.selectedActivityTimeAmPm = @"am";
        }
        
    } else if ([elementName isEqualToString:@"activity_item_time_fraction"]) {
        
        if ([cleanString isEqualToString:@""]) {
            
            self.selectedActivityTimeFraction = @":00";
            
        } else {
            
            self.selectedActivityTimeFraction = cleanString;
        }
        
    } else if ([elementName isEqualToString:@"activity_item_reminder_time"]
               && ![cleanString isEqualToString:@""]) {
        
        self.selectedActivityReminder = cleanString;
        
        if ([self.selectedActivityReminder integerValue] > 12
            && [self.selectedActivityReminder integerValue] != 24) {
            
            self.selectedActivityReminder = [NSString stringWithFormat:@"%ld", (long)[self.selectedActivityReminder integerValue] - 12];
            
            self.selectedActivityReminderAmPm = @"pm";
            
        } else if ([self.selectedActivityReminder integerValue] == 24 ||
                   [self.selectedActivityReminder integerValue] == 0) {
            
            self.selectedActivityReminder = @"12";
            self.selectedActivityReminderAmPm = @"am";
            
        }  else if ([self.selectedActivityReminder integerValue] == 12) {
            
            self.selectedActivityReminder = @"12";
            self.selectedActivityReminderAmPm = @"pm";
            
        } else {
            
            self.selectedActivityReminderAmPm = @"am";
        }
        
    } else if ([elementName isEqualToString:@"activity_item_reminder_time_fraction"]) {
        
        if ([cleanString isEqualToString:@""]) {
            
            self.selectedActivityReminderFraction = @":00";
            
        } else {
            
            self.selectedActivityReminderFraction = cleanString;
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
        
        if (self.doneAddingActivity == YES) {
            
            [[self navigationController] popToRootViewControllerAnimated:YES];
            
        } else {
            
            if ([self.selectedActivityDuration isEqualToString:@""]
                || [self.selectedActivityDuration isEqualToString:@"0"]
                || self.selectedActivityDuration == nil) {
                
                self.selectedActivityDuration = @"1";
                
            }
            
            if ([self.selectedActivityCaloriesBurned isEqualToString:@""]
                || self.selectedActivityCaloriesBurned == nil) {
                
                self.selectedActivityCaloriesBurned = @"0";
                
            }
            
            self.globalCaloriesBurned = ([self.selectedActivityCaloriesBurned floatValue] /
            [self.selectedActivityDuration floatValue]);
            
            [self showActivityItem];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end