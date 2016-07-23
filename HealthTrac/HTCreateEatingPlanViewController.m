//
//  HTCreateEatingPlanViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTCreateEatingPlanViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTCreateEatingPlanSelectViewController.h"

@interface HTCreateEatingPlanViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTCreateEatingPlanViewController

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
    
    self.title = @"Create Eating Plan";
    
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
    
    self.selectedHeightFeetPickerValues = [[NSMutableArray alloc] init];
    self.selectedHeightInchesPickerValues = [[NSMutableArray alloc] init];
    self.selectedSexPickerValues = [[NSMutableArray alloc] init];
    self.selectedActivityLevelPickerValues = [[NSMutableArray alloc] init];

    self.selectedHeight = [[NSString alloc] init];
    self.selectedHeightFeet = [[NSString alloc] init];
    self.selectedHeightInches = [[NSString alloc] init];
    self.selectedSex = [[NSString alloc] init];
    self.selectedWeight = [[NSString alloc] init];
    self.selectedAge = [[NSString alloc] init];
    self.selectedActivityLevel = [[NSString alloc] init];
    
    self.caloriesToMaintain = [[NSString alloc] init];
    self.caloriesToLoseOneLb = [[NSString alloc] init];
    self.caloriesToLoseTwoLbs = [[NSString alloc] init];
    
    [self.selectedHeightFeetPickerValues removeAllObjects];
    [self.selectedHeightInchesPickerValues removeAllObjects];
    [self.selectedSexPickerValues removeAllObjects];
    [self.selectedActivityLevelPickerValues removeAllObjects];

    for (int i=4; i<=6; i++) {
        
        [self.selectedHeightFeetPickerValues
         insertObject:[NSString stringWithFormat:@"%d ft", i] atIndex:i - 4];
    }
    
    for (int i=0; i<=11; i++) {
        
        [self.selectedHeightInchesPickerValues
         insertObject:[NSString stringWithFormat:@"%d inches", i] atIndex:i];
    }

    [self.selectedSexPickerValues insertObject:@"MALE" atIndex:0];
    [self.selectedSexPickerValues insertObject:@"FEMALE" atIndex:1];
    
    [self.selectedActivityLevelPickerValues insertObject:@"1.2" atIndex:0];
    [self.selectedActivityLevelPickerValues insertObject:@"1.375" atIndex:1];
    [self.selectedActivityLevelPickerValues insertObject:@"1.55" atIndex:2];
    [self.selectedActivityLevelPickerValues insertObject:@"1.725" atIndex:3];
    [self.selectedActivityLevelPickerValues insertObject:@"1.9" atIndex:4];
    
    self.doneUpdatingValues = NO;
    
    [self getCreateEatingPlanValues:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getCreateEatingPlanValues:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.selectedHeight = @"";
    self.selectedHeightFeet = @"";
    self.selectedHeightInches = @"";
    self.selectedSex = @"";
    self.selectedWeight = @"";
    self.selectedAge = @"";
    self.selectedActivityLevel = @"";
    
    self.caloriesToMaintain = @"";
    self.caloriesToLoseOneLb = @"";
    self.caloriesToLoseTwoLbs = @"";
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_create_eating_plan_values&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)updateCreateEatingPlanValues:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.doneUpdatingValues = YES;
    
    self.caloriesToMaintain = @"";
    self.caloriesToLoseOneLb = @"";
    self.caloriesToLoseTwoLbs = @"";
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.selectedHeight = [[NSString stringWithFormat:@"%@ %@",
                            self.selectedHeightFeet,
                            self.selectedHeightInches] stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    
    self.selectedSex = [self.selectedSexPickerValues objectAtIndex:[self.selectedSexPickerView selectedRowInComponent:0]];
    
    self.selectedWeight = [self.selectedWeightTextField.text stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceCharacterSet]];
    
    self.selectedAge = [self.selectedAgeTextField.text stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceCharacterSet]];
    
    self.selectedActivityLevel = [self.selectedActivityLevelPickerValues objectAtIndex:[self.selectedActivityLevelPickerView selectedRowInComponent:0]];
    
    myRequestString = [NSString stringWithFormat:@"action=update_create_eating_plan_values&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&client_height=%@&client_sex=%@&client_weight=%@&client_age=%@&client_activity_multiplier=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.selectedHeight, self.selectedSex, self.selectedWeight, self.selectedAge, self.selectedActivityLevel];
    
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

- (void)showCreateEatingPlan {
    
    NSArray *viewsToRemove = [self.createEatingPlanScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = 0;
    
    UIView *createEatingPlanView;
    UIView *graySeparator;
    
    UILabel *createEatingPlanLabel;
    
    UIFont *createEatingPlanSectionFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UIToolbar *toolBar;
    
    UIBarButtonItem *barButtonDone;
    UIBarButtonItem *flex;
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 4;
    
    // height
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [createEatingPlanLabel setFont:createEatingPlanSectionFont];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Height"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    self.selectedHeightPickerView = [[UIPickerView alloc] init];
    
    self.selectedHeightPickerView.tag = 1;
    self.selectedHeightPickerView.delegate = self;
    self.selectedHeightPickerView.showsSelectionIndicator = YES;
    
    self.selectedHeightTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(((screenWidth / 2) - 20), 9, (((screenWidth - 32) / 2) + 20), 31)];
    
    self.selectedHeightTextField.tag = 1;
    
    [self.selectedHeightTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.selectedHeightTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                                green:(124/255.0)
                                                                 blue:(128/255.0)
                                                                alpha:1.0]];
    
    [self.selectedHeightTextField setTextAlignment:NSTextAlignmentRight];
    
    if (![self.selectedHeight isEqualToString:@""]) {
        
        [self.selectedHeightPickerView selectRow:[self.selectedHeightFeetPickerValues indexOfObject:self.selectedHeightFeet] inComponent:0 animated:YES];
        
        [self.selectedHeightPickerView selectRow:[self.selectedHeightInchesPickerValues indexOfObject:self.selectedHeightInches] inComponent:1 animated:YES];
        
        self.selectedHeightTextField.text = [NSString stringWithFormat:@"%@ %@",
                                             self.selectedHeightFeet,
                                             [self.selectedHeightInches stringByReplacingOccurrencesOfString:@"ches" withString:@""]];
    }
    
    self.selectedHeightTextField.delegate = self;
    self.selectedHeightTextField.inputView = self.selectedHeightPickerView;
    
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
    
    self.selectedHeightTextField.inputAccessoryView = toolBar;
    
    [createEatingPlanView addSubview:self.selectedHeightTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 53;
    
    // weight
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [createEatingPlanLabel setFont:createEatingPlanSectionFont];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Weight"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    self.selectedWeightTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(((screenWidth / 2) - 20), 9, (((screenWidth - 32) / 2) + 20), 31)];
    
    [self.selectedWeightTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.selectedWeightTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                               green:(124/255.0)
                                                                blue:(128/255.0)
                                                               alpha:1.0]];
    
    [self.selectedWeightTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedWeightTextField.text = self.selectedWeight;
    
    [createEatingPlanView addSubview:self.selectedWeightTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.selectedWeightTextField setTag:2];
    [self.selectedWeightTextField setDelegate:self];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 53;
    
    // age
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [createEatingPlanLabel setFont:createEatingPlanSectionFont];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Age"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    self.selectedAgeTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(((screenWidth / 2) - 20), 9, (((screenWidth - 32) / 2) + 20), 31)];
    
    [self.selectedAgeTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.selectedAgeTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                               green:(124/255.0)
                                                                blue:(128/255.0)
                                                               alpha:1.0]];
    
    [self.selectedAgeTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedAgeTextField.text = self.selectedAge;
    
    [createEatingPlanView addSubview:self.selectedAgeTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.selectedAgeTextField setTag:3];
    [self.selectedAgeTextField setDelegate:self];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 53;
    
    // sex
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [createEatingPlanLabel setFont:createEatingPlanSectionFont];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Sex"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    self.selectedSexPickerView = [[UIPickerView alloc] init];
    
    self.selectedSexPickerView.tag = 2;
    self.selectedSexPickerView.delegate = self;
    self.selectedSexPickerView.showsSelectionIndicator = YES;
    
    self.selectedSexTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(((screenWidth / 2) - 20), 9, (((screenWidth - 32) / 2) + 20), 31)];
    
    self.selectedSexTextField.tag = 4;
    
    [self.selectedSexTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.selectedSexTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                            green:(124/255.0)
                                                             blue:(128/255.0)
                                                            alpha:1.0]];
    
    [self.selectedSexTextField setTextAlignment:NSTextAlignmentRight];
    
    if (![self.selectedSex isEqualToString:@""]) {
        
        [self.selectedSexPickerView selectRow:[self.selectedSexPickerValues indexOfObject:self.selectedSex] inComponent:0 animated:YES];
        
        if ([self.selectedSex isEqualToString:@"MALE"]) {
            
            self.selectedSexTextField.text = @"Male";
            
        } else if ([self.selectedSex isEqualToString:@"FEMALE"]) {
            
            self.selectedSexTextField.text = @"Female";
        }
    }
    
    self.selectedSexTextField.delegate = self;
    self.selectedSexTextField.inputView = self.selectedSexPickerView;
    
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
    
    self.selectedSexTextField.inputAccessoryView = toolBar;
    
    [createEatingPlanView addSubview:self.selectedSexTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 53;
    
    // activity level
    
    createEatingPlanView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [createEatingPlanLabel setFont:createEatingPlanSectionFont];
    [createEatingPlanLabel setTextColor:grayFontColor];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentLeft];
    [createEatingPlanLabel setText:@"Activity Level"];
    
    [createEatingPlanView addSubview:createEatingPlanLabel];
    
    self.selectedActivityLevelPickerView = [[UIPickerView alloc] init];
    
    self.selectedActivityLevelPickerView.tag = 3;
    self.selectedActivityLevelPickerView.delegate = self;
    self.selectedActivityLevelPickerView.showsSelectionIndicator = YES;
    
    self.selectedActivityLevelTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(((screenWidth / 2) - 20), 9, (((screenWidth - 32) / 2) + 20), 31)];
    
    self.selectedActivityLevelTextField.tag = 5;
    
    [self.selectedActivityLevelTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.selectedActivityLevelTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                            green:(124/255.0)
                                                             blue:(128/255.0)
                                                            alpha:1.0]];
    
    [self.selectedActivityLevelTextField setTextAlignment:NSTextAlignmentRight];
    
    if (![self.selectedActivityLevel isEqualToString:@""]) {
        
        [self.selectedActivityLevelPickerView selectRow:[self.selectedActivityLevelPickerValues indexOfObject:self.selectedActivityLevel] inComponent:0 animated:YES];
        
        if ([self.selectedActivityLevel isEqualToString:@"1.2"]) {
            
            self.selectedActivityLevelTextField.text = @"Sedentary";
            
        } else if ([self.selectedActivityLevel isEqualToString:@"1.375"]) {
            
            self.selectedActivityLevelTextField.text = @"Lightly Active";
            
        } else if ([self.selectedActivityLevel isEqualToString:@"1.55"]) {
            
            self.selectedActivityLevelTextField.text = @"Moderately Active";
            
        } else if ([self.selectedActivityLevel isEqualToString:@"1.725"]) {
            
            self.selectedActivityLevelTextField.text = @"Very Active";
            
        } else if ([self.selectedActivityLevel isEqualToString:@"1.9"]) {
            
            self.selectedActivityLevelTextField.text = @"Extra Active";
        }
    }
    
    self.selectedActivityLevelTextField.delegate = self;
    self.selectedActivityLevelTextField.inputView = self.selectedActivityLevelPickerView;
    
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
    
    self.selectedActivityLevelTextField.inputAccessoryView = toolBar;
    
    [createEatingPlanView addSubview:self.selectedActivityLevelTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [createEatingPlanView addSubview:graySeparator];
    
    [self.createEatingPlanScrollView addSubview:createEatingPlanView];
    
    vPos += 53;
    
    vPos = screenHeight - 124;
    
    UIButton *calculateButton;
    
    calculateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 60)];
    
    [calculateButton setBackgroundColor:[UIColor colorWithRed:(113/255.0) green:(202/255.0) blue:(94/255.0) alpha:1.0]];
    
    [calculateButton addTarget:self action:@selector(calculateButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    createEatingPlanLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, (screenWidth - 32), 50)];
    
    [createEatingPlanLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:14.0]];
    [createEatingPlanLabel setTextColor:[UIColor whiteColor]];
    [createEatingPlanLabel setTextAlignment:NSTextAlignmentCenter];
    [createEatingPlanLabel setText:@"CALCULATE"];
    
    [calculateButton addSubview:createEatingPlanLabel];
    
    [self.createEatingPlanScrollView addSubview:calculateButton];
    
    vPos += 60;
    
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

- (void)calculateButtonPressed {
    
    NSString *alertString;
    
    if ([[self.selectedHeightTextField.text stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        alertString = @"Please select your height";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedHeightTextField becomeFirstResponder];
        
    } else if ([[self.selectedWeightTextField.text stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        alertString = @"Please enter your weight";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedWeightTextField becomeFirstResponder];
        
    } else if ([[self.selectedAgeTextField.text stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        alertString = @"Please enter your age";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedAgeTextField becomeFirstResponder];
        
    } else if ([[self.selectedSexTextField.text stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        alertString = @"Please select your sex";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedSexTextField becomeFirstResponder];
        
    } else if ([[self.selectedActivityLevelTextField.text stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        alertString = @"Please select your activity level";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedActivityLevelTextField becomeFirstResponder];
        
    } else {
        
        [self updateCreateEatingPlanValues:HTWebSvcURL withState:0];
    }
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;
    
    if (barButtonItem.tag == 101) { // height
        
        NSString *theFeet;
        NSString *theInches;
        
        theFeet = [self.selectedHeightFeetPickerValues
                   objectAtIndex:[self.selectedHeightPickerView selectedRowInComponent:0]];
        
        theInches = [self.selectedHeightInchesPickerValues
                     objectAtIndex:[self.selectedHeightPickerView selectedRowInComponent:1]];
        
        self.selectedHeightFeet = theFeet;
        self.selectedHeightInches = theInches;
        
        theInches = [theInches stringByReplacingOccurrencesOfString:@"ches" withString:@""];
        
        self.selectedHeightTextField.text = [NSString stringWithFormat:@"%@ %@", theFeet, theInches];
        
        [self.selectedHeightTextField resignFirstResponder];
        
    } else if (barButtonItem.tag == 102) { // sex
        
        NSString *theSex;
        
        theSex = [self.selectedSexPickerValues
                  objectAtIndex:[self.selectedSexPickerView selectedRowInComponent:0]];
        
        self.selectedSex = theSex;
        
        if ([theSex isEqualToString:@"MALE"]) {
            
            self.selectedSexTextField.text = @"Male";
            
        } else {
            
            self.selectedSexTextField.text = @"Female";
        }
        
        [self.selectedSexTextField resignFirstResponder];
        
    } else if (barButtonItem.tag == 103) { // activity level
        
        NSString *theActivityLevel;
        
        theActivityLevel = [self.selectedActivityLevelPickerValues
                  objectAtIndex:[self.selectedActivityLevelPickerView selectedRowInComponent:0]];
        
        self.selectedActivityLevel = theActivityLevel;
        
        if ([theActivityLevel isEqualToString:@"1.2"]) {
            
            self.selectedActivityLevelTextField.text = @"Sedentary";
            
        } else if ([theActivityLevel isEqualToString:@"1.375"]) {
            
            self.selectedActivityLevelTextField.text = @"Lightly Active";
            
        } else if ([theActivityLevel isEqualToString:@"1.55"]) {
            
            self.selectedActivityLevelTextField.text = @"Moderately Active";
            
        } else if ([theActivityLevel isEqualToString:@"1.725"]) {
            
            self.selectedActivityLevelTextField.text = @"Very Active";
            
        } else { // 1.9
            
            self.selectedActivityLevelTextField.text = @"Extra Active";
            
        }
        
        [self.selectedActivityLevelTextField resignFirstResponder];
    }
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField.tag == 1 || textField.tag == 4 || textField.tag == 5) {
        
        return NO;
        
    } else {
        
        return YES;
    }
}

#pragma  mark - UIPickerView delegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // height
        
        NSString *theFeet;
        NSString *theInches;
        
        theFeet = [self.selectedHeightFeetPickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theInches = [self.selectedHeightInchesPickerValues
                     objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        self.selectedHeightFeet = theFeet;
        self.selectedHeightInches = theInches;
        
        theInches = [theInches stringByReplacingOccurrencesOfString:@"ches" withString:@""];
        
        self.selectedHeightTextField.text = [NSString stringWithFormat:@"%@ %@", theFeet, theInches];
        
    } else if (pickerView.tag == 2) { // sex
        
        NSString *theSex;
        
        theSex = [self.selectedSexPickerValues
                  objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        self.selectedSex = theSex;
        
        if ([theSex isEqualToString:@"MALE"]) {
            
            self.selectedSexTextField.text = @"Male";
            
        } else {
            
            self.selectedSexTextField.text = @"Female";
        }
        
    } else if (pickerView.tag == 3) { // activity level
        
        NSString *theActivityLevel;
        
        theActivityLevel = [self.selectedActivityLevelPickerValues
                  objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        self.selectedActivityLevel = theActivityLevel;
        
        if ([theActivityLevel isEqualToString:@"1.2"]) {
            
            self.selectedActivityLevelTextField.text = @"Sedentary";
            
        } else if ([theActivityLevel isEqualToString:@"1.375"]) {
            
            self.selectedActivityLevelTextField.text = @"Lightly Active";
            
        } else if ([theActivityLevel isEqualToString:@"1.55"]) {
            
            self.selectedActivityLevelTextField.text = @"Moderately Active";
            
        } else if ([theActivityLevel isEqualToString:@"1.725"]) {
            
            self.selectedActivityLevelTextField.text = @"Very Active";
            
        } else { // 1.9
            
            self.selectedActivityLevelTextField.text = @"Extra Active";
            
        }
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // height
        
        if (component == 0) {  // feet
            
            return 3;
            
        } else { // inches
            
            return 12;
        }
        
    } else if (pickerView.tag == 2) { // sex
        
        return 2;
        
    } else { // actvity level
        
        return 5;
    }
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    if (pickerView.tag == 1) { // height
        
        return 2;
        
    } else {
        
        return 1;
    }
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    
    if (pickerView.tag == 1) { // height
        
        if (component == 0) { // feet
            
            title = [self.selectedHeightFeetPickerValues objectAtIndex:row];
            
        } else { // inches
            
            title = [[self.selectedHeightInchesPickerValues objectAtIndex:row] stringByReplacingOccurrencesOfString:@"ches" withString:@""];
        }
        
    } else if (pickerView.tag == 2) { // sex
        
        switch (row) {
                
            case 0:
                title = @"Male";
                break;
                
            case 1:
                title = @"Female";
                break;
                
            default:
                break;
        }
        
    } else if (pickerView.tag == 3) { // activity level
        
        switch (row) {
                
            case 0:
                title = @"Sedentary (1.2)";
                break;
                
            case 1:
                title = @"Lightly Active (1.3)";
                break;
                
            case 2:
                title = @"Moderately Active (1.5)";
                break;
                
            case 3:
                title = @"Very Active (1.7)";
                break;
                
            case 4:
                title = @"Extra Active (1.9)";
                break;
                
            default:
                break;
        }
    }
    
    return title;
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    int sectionWidth;
    
    if (pickerView.tag == 2) { // sex
        
        sectionWidth = 80;
        
    } else if (pickerView.tag == 3) { // activity level
        
        sectionWidth = 200;
        
    } else {
        
        sectionWidth = 42;
    }
    
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
    
    if (pickerView.tag == 1) { // height
        
        if (component == 0) { // feet
            
            pickerLabel.text = [self.selectedHeightFeetPickerValues objectAtIndex:row];
            
        } else { // inches
            
            pickerLabel.text = [[self.selectedHeightInchesPickerValues objectAtIndex:row] stringByReplacingOccurrencesOfString:@"ches" withString:@""];
        }
        
    }  else if (pickerView.tag == 2) { // sex
        
        switch (row) {
                
            case 0:
                pickerLabel.text = @"Male";
                break;
                
            case 1:
                pickerLabel.text = @"Female";
                break;
                
            default:
                break;
        }
        
    } else if (pickerView.tag == 3) { // activity level
        
        switch (row) {
                
            case 0:
                pickerLabel.text = @"Sedentary (1.2)";
                break;
                
            case 1:
                pickerLabel.text = @"Lightly Active (1.3)";
                break;
                
            case 2:
                pickerLabel.text = @"Moderately Active (1.5)";
                break;
                
            case 3:
                pickerLabel.text = @"Very Active (1.7)";
                break;
                
            case 4:
                pickerLabel.text = @"Extra Active (1.9)";
                break;
                
            default:
                break;
        }
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
        
    } else if ([elementName isEqualToString:@"client_height"]) {
        
        self.selectedHeight = cleanString;
        
        if (![self.selectedHeight isEqualToString:@""]) {
            
            self.selectedHeightFeet = [self.selectedHeight substringToIndex:[self.selectedHeight rangeOfString:@"ft "].location + 2];
            
            self.selectedHeightInches = [self.selectedHeight substringFromIndex:[self.selectedHeight rangeOfString:@"ft "].location + 3];
        }
        
    } else if ([elementName isEqualToString:@"client_weight"]) {
        
        self.selectedWeight = cleanString;
        
    } else if ([elementName isEqualToString:@"client_age"]) {
        
        self.selectedAge = cleanString;
        
    } else if ([elementName isEqualToString:@"client_sex"]) {
        
        self.selectedSex = cleanString;
        
    } else if ([elementName isEqualToString:@"client_activity_multiplier"]) {
        
        self.selectedActivityLevel = cleanString;
        
    } else if ([elementName isEqualToString:@"calories_to_maintain"]) {
        
        self.caloriesToMaintain = cleanString;
        
    } else if ([elementName isEqualToString:@"calories_to_lose_1_lb"]) {
        
        self.caloriesToLoseOneLb = cleanString;
        
    } else if ([elementName isEqualToString:@"calories_to_lose_2_lbs"]) {
        
        self.caloriesToLoseTwoLbs = cleanString;
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
        
        if (self.doneUpdatingValues == YES) {
            
            // show plans segue
            
            [self performSegueWithIdentifier:@"showChooseEatingPlan" sender:self];
            
        } else {
            
            [self showCreateEatingPlan];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTCreateEatingPlanSelectViewController *viewController = segue.destinationViewController;

    viewController.hidesBottomBarWhenPushed = YES;
    
    viewController.caloriesToMaintain = self.caloriesToMaintain;
    viewController.caloriesToLoseOneLb = self.caloriesToLoseOneLb;
    viewController.caloriesToLoseTwoLbs = self.caloriesToLoseTwoLbs;
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
