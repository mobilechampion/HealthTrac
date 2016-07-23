//
//  HTCreateEatingPlanSelectViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/8/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTCreateEatingPlanSelectViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"

@interface HTCreateEatingPlanSelectViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTCreateEatingPlanSelectViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Select Eating Plan";
    
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
    
    self.practicePlanID = [[NSMutableArray alloc] init];
    self.practicePlanName = [[NSMutableArray alloc] init];
    self.practicePlanCalories = [[NSMutableArray alloc] init];
    
    [self.practicePlanID removeAllObjects];
    [self.practicePlanName removeAllObjects];
    [self.practicePlanCalories removeAllObjects];
    
    self.fromDate = @"";
    self.toDate = @"";
    self.selectedCalories = @"";
    self.selectedEatingPlanID = @"";
    
    self.doneSelectingPlan = NO;
    
    [self getPracticePlans:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getPracticePlans:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_create_eating_plan_practice_plans&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)selectEatingPlan:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneSelectingPlan = YES;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    
    NSDate *fromDate = [dateFormatter dateFromString:self.fromDate];
    NSDate *toDate = [dateFormatter dateFromString:self.toDate];
    
    NSString *fromDateString = [dateFormatter stringFromDate:fromDate];
    NSString *toDateString = [dateFormatter stringFromDate:toDate];

    myRequestString = [NSString stringWithFormat:@"action=create_eating_plan_choose_plan&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&start_date=%@&end_date=%@&selected_template_id=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, fromDateString, toDateString, self.selectedEatingPlanID];

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

- (void)updatePlannerTargetCalories:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneSelectingPlan = YES;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=update_planner_target_calories&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&plan_calories=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.selectedCalories];
    
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

- (void)showCreateEatingPlanOptions {
    
    NSArray *viewsToRemove = [self.createEatingPlanScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = 0;
    
    UIButton *createEatingPlanView;
    
    UILabel *createEatingPlanLabel;
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UIToolbar *toolBar;
    
    UIBarButtonItem *barButtonDone;
    UIBarButtonItem *flex;
    
    [self.view setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    [self.createEatingPlanScrollView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 40)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 18, ((screenWidth - 32) / 2), 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:12.0]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"IN ORDER TO"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2), 18, ((screenWidth - 32) / 2), 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:12.0]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentRight];
    [createEatingPlanLabel setText:@"DAILY CALORIES"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 40;
    
    // calories to maintain
    
    createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
    
    [createEatingPlanView setTag:1];
    
    if (![self.caloriesToMaintain isEqualToString:@"N/A"]) {
        
        [createEatingPlanView addTarget:self action:@selector(selectTargetCalories:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Maintain current weight"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - 76), 15, 50, 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:17]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentRight];
    [createEatingPlanLabel setText:self.caloriesToMaintain];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 49;
    
    // calories to lose 1 lb
    
    createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
    
    [createEatingPlanView setTag:2];
    
    if (![self.caloriesToLoseOneLb isEqualToString:@"N/A"]) {
        
        [createEatingPlanView addTarget:self action:@selector(selectTargetCalories:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Lose approx 1 pound per week"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - 76), 15, 50, 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:17]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentRight];
    [createEatingPlanLabel setText:self.caloriesToLoseOneLb];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 49;
    
    // calories to lose 2 lbs
    
    createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
    
    [createEatingPlanView setTag:3];
    
    if (![self.caloriesToLoseTwoLbs isEqualToString:@"N/A"]) {
        
        [createEatingPlanView addTarget:self action:@selector(selectTargetCalories:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Lose approx 2 pounds per week"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - 76), 15, 50, 16)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:17]];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentRight];
    [createEatingPlanLabel setText:self.caloriesToLoseTwoLbs];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 49;
    
    // practice plans
    
    if ([self.practicePlanID count] > 1) {
    
        createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 40)];
        
        createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 18, (screenWidth - 32), 16)];
        
        [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:12.0]];
        [createEatingPlanLabel setTextColor:grayFontColor];
        [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
        [createEatingPlanLabel setText:@"OR CHOOSE AN EATING PLAN TEMPLATE"];
        
        [createEatingPlanView addSubview:createEatingPlanLabel];
        
        [self.createEatingPlanScrollView addSubview:createEatingPlanView];
        
        vPos += 40;
        
        UIView *customBorderView;
        
        for (int i=1; i<=[self.practicePlanID count] - 1; i++) {
        
            // practice plan
            
            createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
            
            [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
            
            if ([self.selectedEatingPlanID isEqualToString:[self.practicePlanID objectAtIndex:i]]) {
                
                customBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, (screenWidth - 12), 2)];
                
                [customBorderView setBackgroundColor:[UIColor colorWithRed:(116/255.0)
                                                                     green:(204/255.0)
                                                                      blue:(240/255.0)
                                                                     alpha:1.0]];
                
                [createEatingPlanView addSubview:customBorderView];
                
                customBorderView = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - 14), 0, 2, 45)];
                
                [customBorderView setBackgroundColor:[UIColor colorWithRed:(116/255.0)
                                                                     green:(204/255.0)
                                                                      blue:(240/255.0)
                                                                     alpha:1.0]];
                
                [createEatingPlanView addSubview:customBorderView];

                customBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, 43, (screenWidth - 12), 2)];
                
                [customBorderView setBackgroundColor:[UIColor colorWithRed:(116/255.0)
                                                                     green:(204/255.0)
                                                                      blue:(240/255.0)
                                                                     alpha:1.0]];
                
                [createEatingPlanView addSubview:customBorderView];

                customBorderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 43)];
                
                [customBorderView setBackgroundColor:[UIColor colorWithRed:(116/255.0)
                                                                     green:(204/255.0)
                                                                      blue:(240/255.0)
                                                                     alpha:1.0]];
                
                [createEatingPlanView addSubview:customBorderView];
            }
            
            [createEatingPlanView setTag:i + 3];
            
            [createEatingPlanView addTarget:self action:@selector(eatingPlanPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
            
            [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
            [createEatingPlanLabel setTextColor:grayFontColor];
            [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
            [createEatingPlanLabel setText:[self.practicePlanName objectAtIndex:i]];
            
            [createEatingPlanView addSubview:createEatingPlanLabel];
            
            createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - 76), 15, 50, 16)];
            
            [createEatingPlanLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:17]];
            [createEatingPlanLabel setTextColor:grayFontColor];
            [createEatingPlanLabel setTextAlignment:NSTextAlignmentRight];
            [createEatingPlanLabel setText:[self.practicePlanCalories objectAtIndex:i]];
            
            [createEatingPlanView addSubview:createEatingPlanLabel];
            
            [self.createEatingPlanScrollView addSubview:createEatingPlanView];
            
            vPos += 49;
        }
        
        createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 20)];
        
        [self.createEatingPlanScrollView addSubview:createEatingPlanView];
        
        vPos += 20;
        
        // from date
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
        
        [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
        
        createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
        
        [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
        [createEatingPlanLabel setTextColor:grayFontColor];
        [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
        [createEatingPlanLabel setText:@"From"];
        
        [createEatingPlanView addSubview:createEatingPlanLabel];
        
        self.fromPickerView = [[UIDatePicker alloc] init];
        
        self.fromPickerView.tag = 1;
        
        [self.fromPickerView setMinimumDate:appDelegate.currentDate];
        [self.fromPickerView setMaximumDate:[appDelegate addNumberOfMonths:2 toDate:appDelegate.currentDate]];
        [self.fromPickerView setDatePickerMode:UIDatePickerModeDate];
        
        [self.fromPickerView addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        if ([self.fromDate isEqual:@""]) {
            
            self.fromDate = [dateFormatter stringFromDate:appDelegate.currentDate];
        }
        
        [self.fromPickerView setDate:[dateFormatter dateFromString:self.fromDate]];
        
        self.fromTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 7, ((screenWidth - 32) / 2), 31)];
        
        self.fromTextField.tag = 1;
        self.fromTextField.delegate = self;
        
        [self.fromTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [self.fromTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                         green:(124/255.0)
                                                          blue:(128/255.0)
                                                         alpha:1.0]];
        
        [self.fromTextField setTextAlignment:NSTextAlignmentRight];
        
        self.fromTextField.delegate = self;
        self.fromTextField.inputView = self.fromPickerView;
        
        self.fromTextField.text = self.fromDate;
        
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
        
        self.fromTextField.inputAccessoryView = toolBar;
        
        [createEatingPlanView addSubview:self.fromTextField];
        
        [self.createEatingPlanScrollView addSubview:createEatingPlanView];
        
        vPos += 49;
        
        // to date
        
        createEatingPlanView = [[UIButton alloc] initWithFrame:CGRectMake(6, vPos, (screenWidth - 12), 45)];
        
        [createEatingPlanView setBackgroundColor:[UIColor whiteColor]];
        
        createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 15, (screenWidth - 90), 16)];
        
        [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
        [createEatingPlanLabel setTextColor:grayFontColor];
        [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
        [createEatingPlanLabel setText:@"To"];
        
        [createEatingPlanView addSubview:createEatingPlanLabel];
        
        self.toPickerView = [[UIDatePicker alloc] init];
        
        self.toPickerView.tag = 2;
        
        [self.toPickerView setMinimumDate:appDelegate.currentDate];
        [self.toPickerView setMaximumDate:[appDelegate addNumberOfMonths:2 toDate:appDelegate.currentDate]];
        [self.toPickerView setDatePickerMode:UIDatePickerModeDate];
        
        [self.toPickerView addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        if ([self.toDate isEqual:@""]) {
            
            self.toDate = [dateFormatter stringFromDate:appDelegate.currentDate];
        }
        
        [self.toPickerView setDate:[dateFormatter dateFromString:self.toDate]];
        
        self.toTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 7, ((screenWidth - 32) / 2), 31)];
        
        self.toTextField.tag = 2;
        self.toTextField.delegate = self;
        
        [self.toTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [self.toTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                       green:(124/255.0)
                                                        blue:(128/255.0)
                                                       alpha:1.0]];
        
        [self.toTextField setTextAlignment:NSTextAlignmentRight];
        
        self.toTextField.delegate = self;
        self.toTextField.inputView = self.toPickerView;
        
        self.toTextField.text = self.toDate;
        
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
        
        self.toTextField.inputAccessoryView = toolBar;
        
        [createEatingPlanView addSubview:self.toTextField];
        
        [self.createEatingPlanScrollView addSubview:createEatingPlanView];
        
        vPos += 49;
        
        UIButton *loadPlanButton;
        
        loadPlanButton = [[UIButton alloc] initWithFrame:CGRectMake(0, screenHeight - 60, screenWidth, 60)];
        
        [loadPlanButton setBackgroundColor:[UIColor colorWithRed:(113/255.0) green:(202/255.0) blue:(94/255.0) alpha:1.0]];
        
        [loadPlanButton addTarget:self action:@selector(loadPlanButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, (screenWidth - 32), 50)];
        
        [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:14.0]];
        [createEatingPlanLabel setTextColor:[UIColor whiteColor]];
        [createEatingPlanLabel setTextAlignment:NSTextAlignmentCenter];
        [createEatingPlanLabel setText:@"LOAD PLAN"];
        
        [loadPlanButton addSubview:createEatingPlanLabel];
        
        [self.view addSubview:loadPlanButton];
    }
    
    [self.createEatingPlanScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
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

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)selectTargetCalories:(id)sender {
    
    UIButton *selectedButton = sender;
    
    switch (selectedButton.tag) {
        case 1:
            self.selectedCalories = self.caloriesToMaintain;
            break;
            
        case 2:
            self.selectedCalories = self.caloriesToLoseOneLb;
            break;
            
        case 3:
            self.selectedCalories = self.caloriesToLoseTwoLbs;
            break;
            
        default:
            self.selectedCalories = @"";
            break;
    }
    
    if (![self.selectedCalories isEqualToString:@""]) {
        
        [self updatePlannerTargetCalories:HTWebSvcURL withState:0];
    }
}

- (void)eatingPlanPressed:(id)sender {

    UIButton *selectedPlan = sender;
    
    if ([self.selectedEatingPlanID isEqualToString:[self.practicePlanID objectAtIndex:selectedPlan.tag - 3]]) {
        
        self.selectedEatingPlanID = @"";
        
    } else {
        
        self.selectedEatingPlanID = [self.practicePlanID objectAtIndex:selectedPlan.tag - 3];
    }
    
    [self showCreateEatingPlanOptions];
}

- (void)loadPlanButtonPressed {
    
    NSString *alertString;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    NSDate *fromDate = [dateFormatter dateFromString:self.fromDate];
    NSDate *toDate = [dateFormatter dateFromString:self.toDate];
    
    if ([self.selectedEatingPlanID isEqualToString:@""]) {
        
        alertString = @"Please choose an eating plan template";
        
        [self.view makeToast:alertString duration:3.0 position:@"center"];
        
    } else if ([[fromDate earlierDate:toDate] isEqualToDate:toDate] &&
               ![fromDate isEqualToDate:toDate]) { // fromDate != toDate
        
        alertString = @"From date cannot be after To date";
        
        [self.view makeToast:alertString duration:3.0 position:@"center"];
    
    } else {
        
        [self selectEatingPlan:HTWebSvcURL withState:0];
    }
}

- (void)datePickerValueChanged:(id)sender {
    
    UIDatePicker *datePicker = sender;
    
    NSString *newDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    newDate = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:datePicker.date]];
    
    if (datePicker.tag == 1) {
        
        self.fromDate = newDate;
        self.fromTextField.text = newDate;
        
    } else {
        
        self.toDate = newDate;
        self.toTextField.text = newDate;
    }
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;
    
    if (barButtonItem.tag == 101) { // from
        
        [self.fromTextField resignFirstResponder];
        
    } else { // to
        
        [self.toTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    return NO;
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
    
    [self.practicePlanID removeAllObjects];
    [self.practicePlanName removeAllObjects];
    [self.practicePlanCalories removeAllObjects];
    
    [self.practicePlanID insertObject:@"" atIndex:0];
    [self.practicePlanName insertObject:@"" atIndex:0];
    [self.practicePlanCalories insertObject:@"" atIndex:0];
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
        
    } else if ([elementName hasPrefix:@"plan_id_"]) {
        
        [self.practicePlanID insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"plan_id_" withString:@""]
                                                                     integerValue]];
        
    } else if ([elementName hasPrefix:@"plan_name_"]) {
        
        [self.practicePlanName insertObject:cleanString atIndex:[[elementName stringByReplacingOccurrencesOfString:@"plan_name_" withString:@""]
                                                                     integerValue]];
        
    } else if ([elementName hasPrefix:@"plan_calories_"]) {
        
        [self.practicePlanCalories insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"plan_calories_" withString:@""]
                                                                     integerValue]];
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
        
        if (self.doneSelectingPlan == YES) {
            
            [[self navigationController] popToRootViewControllerAnimated:YES];
            
        } else {
            
            [self showCreateEatingPlanOptions];
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
