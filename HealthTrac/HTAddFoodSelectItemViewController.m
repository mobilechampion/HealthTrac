//
//  HTAddFoodSelectItemViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/7/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddFoodSelectItemViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTAddFoodSearchResultsViewController.h"
#import "HTAddFoodSelectItemDetailsViewController.h"

@interface HTAddFoodSelectItemViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddFoodSelectItemViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.rightBarButtonItem = [self checkButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Add Food";
    
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
    
    self.quantityPickerValues = [[NSMutableArray alloc] init];
    self.quantityPickerValueFractions = [[NSMutableArray alloc] init];
    
    self.addFoodTimePickerValues = [[NSMutableArray alloc] init];
    self.addFoodTimePickerValueFractions = [[NSMutableArray alloc] init];
    self.addFoodTimePickerValueAmPm = [[NSMutableArray alloc] init];
    
    self.addFoodReminderPickerValues = [[NSMutableArray alloc] init];
    self.addFoodReminderPickerValueFractions = [[NSMutableArray alloc] init];
    self.addFoodReminderPickerValueAmPm = [[NSMutableArray alloc] init];
    
    self.selectedFoodQuantity = [[NSString alloc] init];
    self.selectedFoodQuantityFraction = [[NSString alloc] init];
    
    self.selectedFoodTime = [[NSString alloc] init];
    self.selectedFoodTimeFraction = [[NSString alloc] init];
    
    self.selectedFoodReminder = [[NSString alloc] init];
    self.selectedFoodReminderFraction = [[NSString alloc] init];
    self.selectedFoodReminderYN = [[NSString alloc] init];
    
    self.selectedFoodAddToFavorites = [[NSString alloc] init];
    self.selectedFoodRelaunchItem = [[NSString alloc] init];
    //self.selectedFoodRelaunchItemID = [[NSString alloc] init];
    self.selectedFoodExchangeNumber = [[NSString alloc] init];
    self.selectedFoodTemplate = [[NSString alloc] init];
    
    [self.quantityPickerValues removeAllObjects];
    [self.quantityPickerValueFractions removeAllObjects];
    
    [self.addFoodTimePickerValues removeAllObjects];
    [self.addFoodTimePickerValueFractions removeAllObjects];
    [self.addFoodTimePickerValueAmPm removeAllObjects];
    
    [self.addFoodReminderPickerValues removeAllObjects];
    [self.addFoodReminderPickerValueFractions removeAllObjects];
    [self.addFoodReminderPickerValueAmPm removeAllObjects];
    
    for (int i=0; i<=16; i++) {
        
        [self.quantityPickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i];
    }
    
    [self.quantityPickerValueFractions insertObject:@".00" atIndex:0];
    [self.quantityPickerValueFractions insertObject:@".25" atIndex:1];
    [self.quantityPickerValueFractions insertObject:@".50" atIndex:2];
    [self.quantityPickerValueFractions insertObject:@".75" atIndex:3];
    
    [self.addFoodReminderPickerValues insertObject:[NSString stringWithFormat:@"none"] atIndex:0];
    
    for (int i=1; i<=12; i++) {
        
        [self.addFoodTimePickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i - 1];
        [self.addFoodReminderPickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i];
    }
    
    [self.addFoodTimePickerValueFractions insertObject:@":00" atIndex:0];
    [self.addFoodTimePickerValueFractions insertObject:@":30" atIndex:1];
    [self.addFoodTimePickerValueAmPm insertObject:@"am" atIndex:0];
    [self.addFoodTimePickerValueAmPm insertObject:@"pm" atIndex:1];
    
    [self.addFoodReminderPickerValueFractions insertObject:@"--" atIndex:0];
    [self.addFoodReminderPickerValueAmPm insertObject:@"--" atIndex:0];
    
    // template item
    if (self.relaunchPlannerItem == YES &&
        ([self.addFoodCategory isEqualToString:@"template"] ||
         [self.addFoodCategory isEqualToString:@"exchange"])) {
        
        self.navigationItem.leftBarButtonItem = [self changeItemButton];
        
    } else {
        
        self.navigationItem.leftBarButtonItem = [self backButton];
    }
    
    [self getFoodItem:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getFoodItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.selectedFoodName = @"";
    self.selectedFoodDetailsID = @"";
    self.selectedFoodCalories = @"";
    self.selectedFoodProtein = @"";
    self.selectedFoodCarbs = @"";
    self.selectedFoodFiber = @"";
    self.selectedFoodSugar = @"";
    self.selectedFoodSodium = @"";
    self.selectedFoodFat = @"";
    self.selectedFoodSatFat = @"";
    self.selectedFoodServings = @"";
    
    self.addFoodToFavorites = NO;
    self.doneAddingFood = NO;
    
    if (self.relaunchPlannerItem == YES) {
        
        if (self.relaunchItemID == 0) {
            
            self.relaunchItemID = self.selectedFoodID;
        }
        
        if (![self.addFoodCategory isEqualToString:@"exchange"]) {
            
            self.addFoodCategory = @""; // this gets populated on the web svc side for a relaunch
        }
    }
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (![self.exchangeItemsString isEqualToString:@""] && self.exchangeItemsString != nil) { // exchanges!
        
        myRequestString = [NSString stringWithFormat:@"action=get_add_food_select_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%@&relaunch_id=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addFoodCategory, self.exchangeItemsString, (long)self.relaunchItemID];
        
    } else {
        
        myRequestString = [NSString stringWithFormat:@"action=get_add_food_select_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%ld&relaunch_id=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addFoodCategory, (long)self.selectedFoodID, (long)self.relaunchItemID];
    }
    
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

- (void)addFoodItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([self.selectedFoodTimeAmPm isEqualToString:@"pm"]
        && [self.selectedFoodTime integerValue] < 12) {
        
        self.selectedFoodTime = [NSString stringWithFormat:@"%ld",
                                 (long)[self.selectedFoodTime integerValue] + 12];
        
    } else if ([self.selectedFoodTimeAmPm isEqualToString:@"am"]
               && [self.selectedFoodTime integerValue] == 12) {
        
        self.selectedFoodTime = @"0";
    }
    
    self.selectedFoodTimeFraction = [self.selectedFoodTimeFraction
                                     stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    if ([self.selectedFoodReminderAmPm isEqualToString:@"pm"] &&
        [self.selectedFoodReminder integerValue] < 12) {
        
        self.selectedFoodReminder = [NSString stringWithFormat:@"%ld",
                                 (long)[self.selectedFoodReminder integerValue] + 12];
        
    } else if ([self.selectedFoodReminderAmPm isEqualToString:@"am"]
               && [self.selectedFoodReminder integerValue] == 12) {
        
        self.selectedFoodReminder = @"0";
    }
    
    self.selectedFoodReminderFraction = [self.selectedFoodReminderFraction
                                     stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    if (![self.selectedFoodReminder isEqualToString:@""]) {
        
        self.selectedFoodReminderYN = @"Y";
    }
    
    if (self.addFoodToFavorites == YES) {
        
        self.selectedFoodAddToFavorites = @"Y";
    }
    
    self.selectedFoodName = [appDelegate cleanStringBeforeSending:self.selectedFoodName];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        self.selectedFoodQuantity = @"1";
        
        self.selectedFoodCalories = [NSString stringWithFormat:@"%ld",
                                     (long)[self.selectedFoodCalories integerValue]];
        
    } else {
        
        self.selectedFoodQuantity = [NSString stringWithFormat:@"%.2f",
                                     [self.selectedFoodQuantity integerValue] +
                                     [self.selectedFoodQuantityFraction floatValue]];
        
        self.selectedFoodCalories = [NSString stringWithFormat:@"%.0f",
                                     [self.selectedFoodQuantity floatValue] *
                                     [self.selectedFoodCalories integerValue]];
    }
    
    if (self.relaunchPlannerItem == YES) {
        
        self.selectedFoodRelaunchItem = @"true";
        self.selectedFoodRelaunchItemID = [NSString stringWithFormat:@"%ld", (long)self.relaunchItemID];
        
        if (![self.selectedFoodDetailsID isEqualToString:@""]) {
            
            self.selectedFoodID = [self.selectedFoodDetailsID integerValue];
        }
    
    } else {
        
        self.selectedFoodRelaunchItem = @"false";
        self.selectedFoodRelaunchItemID = @"";
    }
    
    self.selectedFoodExchangeNumber = @"";
    self.selectedFoodTemplate = self.inTemplateString;
    
    if (![self.exchangeItemsString isEqualToString:@""] && self.exchangeItemsString != nil) {
        
        myRequestString = [NSString stringWithFormat:@"action=get_add_food_add_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%@&hour=%@&hour_half=%@&name=%@&reminder=%@&reminder_half=%@&reminder_yn=%@&add_to_favs=%@&quantity=%@&relaunch=%@&relaunch_id=%@&plan_calories=%@&exchange_number=%@&template=%@&calories=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addFoodCategory, self.exchangeItemsString, self.selectedFoodTime, self.selectedFoodTimeFraction, self.selectedFoodName, self.selectedFoodReminder, self.selectedFoodReminderFraction, self.selectedFoodReminderYN, self.selectedFoodAddToFavorites, self.selectedFoodQuantity, self.selectedFoodRelaunchItem, self.selectedFoodRelaunchItemID, @"", self.selectedFoodExchangeNumber, self.selectedFoodTemplate, self.selectedFoodCalories];
        
    } else {
        
        myRequestString = [NSString stringWithFormat:@"action=get_add_food_add_item&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichCategory=%@&WhichID=%ld&hour=%@&hour_half=%@&name=%@&reminder=%@&reminder_half=%@&reminder_yn=%@&add_to_favs=%@&quantity=%@&relaunch=%@&relaunch_id=%@&plan_calories=%@&exchange_number=%@&template=%@&calories=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addFoodCategory, (long)self.selectedFoodID, self.selectedFoodTime, self.selectedFoodTimeFraction, self.selectedFoodName, self.selectedFoodReminder, self.selectedFoodReminderFraction, self.selectedFoodReminderYN, self.selectedFoodAddToFavorites, self.selectedFoodQuantity, self.selectedFoodRelaunchItem, self.selectedFoodRelaunchItemID, @"", self.selectedFoodExchangeNumber, self.selectedFoodTemplate, self.selectedFoodCalories];
    }
    
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

- (void)showFoodItem {
    
    NSArray *viewsToRemove = [self.addFoodSelectItemScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = -59;
    NSInteger hPos = 0;
    NSInteger nutritionLabelPos = 0;
    
    UIView *selectedItemView;
    UIView *selectedItemViewTwo;
    UIView *selectedItemViewThree;
    UIView *graySeparator;
    
    UILabel *selectedItemLabel;
    
    UIButton *checkBox;
    
    UIFont *foodTitleFont = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    UIFont *foodSectionFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    UIFont *nutritionLabelFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:11.0];
    UIFont *nutritionSubLabelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:11.0];
    UIFont *nutritionValueFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos - 5, screenWidth, 54)];
    
    [selectedItemView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    // details panel icon
    
    if (![self.addFoodCategory isEqualToString:@"general"] &&
        ![self.addFoodCategory isEqualToString:@"exchange"]) {
        
        UIButton *foodItemDetailsButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 44, 13, 28, 28)];
        
        [foodItemDetailsButton setImage:[UIImage imageNamed:@"ht-planner-nutrition"]
                            forState:UIControlStateNormal];
        
        [foodItemDetailsButton addTarget:self action:@selector(showFoodItemDetails) forControlEvents:UIControlEventTouchUpInside];
        
        [selectedItemView addSubview:foodItemDetailsButton];
        
        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 64), 54)];
    
    } else {
        
        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 32), 54)];
    }
    
    selectedItemLabel.adjustsFontSizeToFitWidth = YES;
    selectedItemLabel.minimumScaleFactor = 0.8f;
    
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setNumberOfLines:2];
    [selectedItemLabel setFont:foodTitleFont];
    [selectedItemLabel setText:self.selectedFoodName];

    [selectedItemView addSubview:selectedItemLabel];
    
    [self.addFoodSelectItemScrollView addSubview:selectedItemView];
     
    vPos += 52;
    
    UIToolbar *toolBar;
    
    UIBarButtonItem *barButtonDone;
    UIBarButtonItem *flex;
    
    if (![self.addFoodCategory isEqualToString:@"exchange"] &&
        ![self.addFoodCategory isEqualToString:@"template"]) {
        
        selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
        
        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 130), 46)];
        
        [selectedItemLabel setFont:foodSectionFont];
        [selectedItemLabel setTextColor:grayFontColor];
        [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
        
        if ([self.addFoodCategory isEqualToString:@"general"] && ![self.selectedFoodServings isEqualToString:@""]) {
            
            [selectedItemLabel setNumberOfLines:2];
            [selectedItemLabel setText:[NSString stringWithFormat:@"Quantity (%@)",
                                        [[self.selectedFoodServings stringByReplacingOccurrencesOfString:@"(" withString:@""]
                                         stringByReplacingOccurrencesOfString:@")" withString:@""]]];
        
        } else {
            
            [selectedItemLabel setText:@"Quantity"];
        }
        
        [selectedItemView addSubview:selectedItemLabel];
        
        self.quantityPickerView = [[UIPickerView alloc] init];
        
        self.quantityPickerView.tag = 1;
        self.quantityPickerView.delegate = self;
        self.quantityPickerView.showsSelectionIndicator = YES;
        
        self.quantityTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 7, 90, 31)];
        
        [self.quantityTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [self.quantityTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                             green:(124/255.0)
                                                              blue:(128/255.0)
                                                             alpha:1.0]];
        
        [self.quantityTextField setTextAlignment:NSTextAlignmentRight];
        
        if ([self.selectedFoodQuantity isEqualToString:@""]) {
            
            self.selectedFoodQuantity = @"1";
            self.selectedFoodQuantityFraction = @".00";
        }

        [self.quantityPickerView selectRow:[self.quantityPickerValues indexOfObject:self.selectedFoodQuantity] inComponent:0 animated:YES];
        
        [self.quantityPickerView selectRow:[self.quantityPickerValueFractions indexOfObject:self.selectedFoodQuantityFraction] inComponent:1 animated:YES];
        
        self.quantityTextField.text = [NSString stringWithFormat:@"%@%@", self.selectedFoodQuantity,
                                       self.selectedFoodQuantityFraction];
        self.quantityTextField.delegate = self;
        self.quantityTextField.inputView = self.quantityPickerView;
        
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
        
        self.quantityTextField.inputAccessoryView = toolBar;
        
        [selectedItemView addSubview:self.quantityTextField];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 47, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [selectedItemView addSubview:graySeparator];
        
        [self.addFoodSelectItemScrollView addSubview:selectedItemView];
        
        vPos += 53;
        
    } else { // exchange item
        
        // nothing
    }
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 45)];
    
    [selectedItemLabel setFont:foodSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Add to Planner"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.addFoodTimePickerView = [[UIPickerView alloc] init];
    
    self.addFoodTimePickerView.tag = 2;
    self.addFoodTimePickerView.delegate = self;
    self.addFoodTimePickerView.showsSelectionIndicator = YES;
    
    self.addFoodTimeTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 7, 90, 31)];
    
    [self.addFoodTimeTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.addFoodTimeTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                            green:(124/255.0)
                                                             blue:(128/255.0)
                                                            alpha:1.0]];
    
    [self.addFoodTimeTextField setTextAlignment:NSTextAlignmentRight];
    
    if ([self.selectedFoodTime isEqualToString:@""]) {
        
        self.selectedFoodTime = @"12";
        self.selectedFoodTimeFraction = @":00";
        self.selectedFoodTimeAmPm = @"pm";
    }
    
    if ([self.selectedFoodTime isEqualToString:@"0"]) {
        
        self.selectedFoodTime = @"12";
        self.selectedFoodTimeFraction = @":00";
        self.selectedFoodTimeAmPm = @"am";
    }
    
    [self.addFoodTimePickerView selectRow:[self.addFoodTimePickerValues indexOfObject:self.selectedFoodTime] inComponent:0 animated:YES];
    
    [self.addFoodTimePickerView selectRow:[self.addFoodTimePickerValueFractions indexOfObject:self.selectedFoodTimeFraction] inComponent:1 animated:YES];
    
    [self.addFoodTimePickerView selectRow:[self.addFoodTimePickerValueAmPm indexOfObject:self.selectedFoodTimeAmPm] inComponent:2 animated:YES];
    
    self.addFoodTimeTextField.text = [NSString stringWithFormat:@"%@%@%@",
                                      self.selectedFoodTime,
                                      self.selectedFoodTimeFraction,
                                      self.selectedFoodTimeAmPm];
    
    self.addFoodTimeTextField.delegate = self;
    self.addFoodTimeTextField.inputView = self.addFoodTimePickerView;
    
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
    
    self.addFoodTimeTextField.inputAccessoryView = toolBar;
    
    [selectedItemView addSubview:self.addFoodTimeTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 47, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFoodSelectItemScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 45)];
    
    [selectedItemLabel setFont:foodSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Text Reminder"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.addFoodReminderPickerView = [[UIPickerView alloc] init];
    
    self.addFoodReminderPickerView.tag = 3;
    self.addFoodReminderPickerView.delegate = self;
    self.addFoodReminderPickerView.showsSelectionIndicator = YES;
    
    self.addFoodReminderTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth - 106), 7, 90, 31)];
    
    [self.addFoodReminderTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
    [self.addFoodReminderTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                            green:(124/255.0)
                                                             blue:(128/255.0)
                                                            alpha:1.0]];
    
    [self.addFoodReminderTextField setTextAlignment:NSTextAlignmentRight];
    
    // do we have a reminder?
    
    if (![self.selectedFoodReminder isEqualToString:@""]) {
        
        [self.addFoodReminderPickerValueFractions removeAllObjects];
        [self.addFoodReminderPickerValueAmPm removeAllObjects];
        
        [self.addFoodReminderPickerValueFractions insertObject:@":00" atIndex:0];
        [self.addFoodReminderPickerValueFractions insertObject:@":15" atIndex:1];
        [self.addFoodReminderPickerValueFractions insertObject:@":30" atIndex:2];
        [self.addFoodReminderPickerValueFractions insertObject:@":45" atIndex:3];
        
        [self.addFoodReminderPickerValueAmPm insertObject:@"am" atIndex:0];
        [self.addFoodReminderPickerValueAmPm insertObject:@"pm" atIndex:1];
        
        [self.addFoodReminderPickerView reloadAllComponents];
        
        [self.addFoodReminderPickerView selectRow:[self.addFoodReminderPickerValues indexOfObject:self.selectedFoodReminder] inComponent:0 animated:YES];
        
        [self.addFoodReminderPickerView selectRow:[self.addFoodReminderPickerValueFractions indexOfObject:self.selectedFoodReminderFraction] inComponent:1 animated:YES];
        
        [self.addFoodReminderPickerView selectRow:[self.addFoodReminderPickerValueAmPm indexOfObject:self.selectedFoodReminderAmPm] inComponent:2 animated:YES];
        
        self.addFoodReminderTextField.text = [NSString stringWithFormat:@"%@%@%@",
                                          self.selectedFoodReminder,
                                          self.selectedFoodReminderFraction,
                                          self.selectedFoodReminderAmPm];
    }
    
    self.addFoodReminderTextField.delegate = self;
    self.addFoodReminderTextField.inputView = self.addFoodReminderPickerView;
    
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
    
    self.addFoodReminderTextField.inputAccessoryView = toolBar;
    
    [selectedItemView addSubview:self.addFoodReminderTextField];
    
    [self.addFoodSelectItemScrollView addSubview:selectedItemView];
    
    vPos += 47;
    
    // add to favorites
    
    if (![self.addFoodCategory isEqualToString:@"favorites"]
        && ![self.addFoodCategory isEqualToString:@"exchange"]) {
        
        vPos += 6;
        
        selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, -4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
        [selectedItemView addSubview:graySeparator];

        selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 4, ((screenWidth - 32) / 2), 45)];
        
        [selectedItemLabel setFont:foodSectionFont];
        [selectedItemLabel setTextColor:grayFontColor];
        [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
        [selectedItemLabel setText:@"Add to Favorites"];
        
        [selectedItemView addSubview:selectedItemLabel];
        
        hPos += (screenWidth - 47);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 11, 31, 31)];
        
        if (self.addFoodToFavorites == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }

        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:201];
        
        [selectedItemView addSubview:checkBox];
        
        [self.addFoodSelectItemScrollView addSubview:selectedItemView];
        
        vPos += 53;
        
    }
    
    // nutritional info - calories
    
    float nutritionalCalc;
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 268)];
    
    [selectedItemView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 18, ((screenWidth - 32) / 2), 16)];
    
    [selectedItemLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:12.0]];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"NUTRITIONAL INFO"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    selectedItemViewTwo = [[UIView alloc] initWithFrame:CGRectMake(16, 38, (screenWidth - 32), 3)];
    
    [selectedItemViewTwo setBackgroundColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
    
    [selectedItemView addSubview:selectedItemViewTwo];
    
    selectedItemViewThree = [[UIView alloc] initWithFrame:CGRectMake(16, 41, (screenWidth - 32), 211)];
    
    [selectedItemViewThree setBackgroundColor:[UIColor whiteColor]];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, ((screenWidth - 64) / 2), 20)];
    
    [selectedItemLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Calories"];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodCaloriesLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2), 10, (((screenWidth - 64) / 2) - 16), 20)];
    
    [self.addFoodCaloriesLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:21.0]];
    [self.addFoodCaloriesLabel setTextColor:grayFontColor];
    [self.addFoodCaloriesLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodCalories floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodCalories floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    [self.addFoodCaloriesLabel setText:[NSString stringWithFormat:@"%.0f", nutritionalCalc]];
    
    [selectedItemViewThree addSubview:self.addFoodCaloriesLabel];
    
    NSMutableAttributedString *nutritionValueStr;
    
    // carbs
    
    nutritionLabelPos = 41;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [selectedItemLabel setFont:nutritionLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Carbs", @"   "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodCarbsLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodCarbsLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.addFoodCarbsLabel setFont:nutritionValueFont];
    [self.addFoodCarbsLabel setTextColor:grayFontColor];
    [self.addFoodCarbsLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodCarbs floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodCarbs floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodCarbsLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodCarbsLabel];
    
    // fiber
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor whiteColor]];
    
    [selectedItemLabel setFont:nutritionSubLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Fiber", @"      "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodFiberLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodFiberLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.addFoodFiberLabel setFont:nutritionValueFont];
    [self.addFoodFiberLabel setTextColor:grayFontColor];
    [self.addFoodFiberLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodFiber floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodFiber floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodFiberLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodFiberLabel];
    
    // sugars
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [selectedItemLabel setFont:nutritionSubLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Sugars", @"      "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodSugarLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodSugarLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];

    [self.addFoodSugarLabel setFont:nutritionValueFont];
    [self.addFoodSugarLabel setTextColor:grayFontColor];
    [self.addFoodSugarLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodSugar floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodSugar floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodSugarLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodSugarLabel];
    
    // protein
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor whiteColor]];
    
    [selectedItemLabel setFont:nutritionLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Protein", @"   "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodProteinLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodProteinLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.addFoodProteinLabel setFont:nutritionValueFont];
    [self.addFoodProteinLabel setTextColor:grayFontColor];
    [self.addFoodProteinLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodProtein floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodProtein floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodProteinLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodProteinLabel];
    
    // total fat
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [selectedItemLabel setFont:nutritionLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Total Fat", @"   "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodFatLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodFatLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.addFoodFatLabel setFont:nutritionValueFont];
    [self.addFoodFatLabel setTextColor:grayFontColor];
    [self.addFoodFatLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodFat floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodFat floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodFatLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodFatLabel];
    
    // sat fat
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor whiteColor]];
    
    [selectedItemLabel setFont:nutritionSubLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Sat. Fat", @"      "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodSatFatLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodSatFatLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.addFoodSatFatLabel setFont:nutritionValueFont];
    [self.addFoodSatFatLabel setTextColor:grayFontColor];
    [self.addFoodSatFatLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodSatFat floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodSatFat floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodSatFatLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodSatFatLabel];
    
    // sodium
    
    nutritionLabelPos += 22;
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [selectedItemLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [selectedItemLabel setFont:nutritionLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:[NSString stringWithFormat:@"%@Sodium", @"   "]];
    
    [selectedItemViewThree addSubview:selectedItemLabel];
    
    self.addFoodSodiumLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.addFoodSodiumLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.addFoodSodiumLabel setFont:nutritionValueFont];
    [self.addFoodSodiumLabel setTextColor:grayFontColor];
    [self.addFoodSodiumLabel setTextAlignment:NSTextAlignmentRight];
    
    if ([self.addFoodCategory isEqualToString:@"exchange"]) {
        
        nutritionalCalc = [self.selectedFoodSodium floatValue];
        
    } else {
        
        nutritionalCalc = ([self.selectedFoodSodium floatValue] *
                           ([self.selectedFoodQuantity integerValue] + [self.selectedFoodQuantityFraction floatValue]));
    }
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%.0fmg%@", nutritionalCalc, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.addFoodSodiumLabel setAttributedText:nutritionValueStr];
    
    [selectedItemViewThree addSubview:self.addFoodSodiumLabel];
    
    [selectedItemView addSubview:selectedItemViewThree];
    
    [self.addFoodSelectItemScrollView addSubview:selectedItemView];
    
    vPos += 268;
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, (screenHeight - vPos))];
    
    [selectedItemView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    [self.addFoodSelectItemScrollView addSubview:selectedItemView];
    
    [self.addFoodSelectItemScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
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

- (UIBarButtonItem *) changeItemButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Change Item" style:UIBarButtonItemStylePlain target:self action:@selector(changeItemButtonPressed)];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)changeItemButtonPressed {
    
    [self performSegueWithIdentifier:@"changeTemplateItem" sender:self];
}

- (void)checkButtonPressed {
    
    self.doneAddingFood = YES;
    
    [self addFoodItem:HTWebSvcURL withState:0];
}

- (IBAction)checkBoxChecked:(id)sender {
    
    UIButton *button = sender;
    
    if (button.tag == 201) { // add to favorites
        
        if (self.addFoodToFavorites == NO) {
            
            [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
            self.addFoodToFavorites = YES;
            
        } else {
            
            [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
            
            self.addFoodToFavorites = NO;
        }
    }
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;
    
    if (barButtonItem.tag == 101) { // quantity
        
        [self.quantityTextField resignFirstResponder];
    
    } else if (barButtonItem.tag == 102) { // add food time
        
        [self.addFoodTimeTextField resignFirstResponder];
        
    } else if (barButtonItem.tag == 103) { // add food reminder
        
        [self.addFoodReminderTextField resignFirstResponder];
    }
}

- (void)showFoodItemDetails {
    
    [self performSegueWithIdentifier:@"showFoodItemDetails" sender:self];
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    return NO;
}

#pragma  mark - UIPickerView delegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // quantity
        
        NSString *theQuantity;
        NSString *theFraction;
        float newValue;
        
        NSMutableAttributedString *nutritionValueStr;
        
        theQuantity = [self.quantityPickerValues objectAtIndex:[pickerView selectedRowInComponent:0]];
        theFraction = [self.quantityPickerValueFractions objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        if ([theQuantity isEqualToString:@"0"]) {
            
            if ([theFraction isEqualToString:@".00"]) {
                
                theFraction = @".25";
            }
            
            [self.quantityPickerValueFractions removeAllObjects];
            
            [self.quantityPickerValueFractions insertObject:@".25" atIndex:0];
            [self.quantityPickerValueFractions insertObject:@".50" atIndex:1];
            [self.quantityPickerValueFractions insertObject:@".75" atIndex:2];
            
            [self.quantityPickerView reloadAllComponents];
            
            if ([theFraction isEqualToString:@".25"]) {
                
                [self.quantityPickerView selectRow:0 inComponent:1 animated:YES];
                
            } else if ([theFraction isEqualToString:@".50"]) {
                
                [self.quantityPickerView selectRow:1 inComponent:1 animated:YES];
                
            } else if ([theFraction isEqualToString:@".75"]) {
                
                [self.quantityPickerView selectRow:2 inComponent:1 animated:YES];
            }
            
        } else {
            
            [self.quantityPickerValueFractions removeAllObjects];
            
            [self.quantityPickerValueFractions insertObject:@".00" atIndex:0];
            [self.quantityPickerValueFractions insertObject:@".25" atIndex:1];
            [self.quantityPickerValueFractions insertObject:@".50" atIndex:2];
            [self.quantityPickerValueFractions insertObject:@".75" atIndex:3];
            
            [self.quantityPickerView reloadAllComponents];
            
            if ([theFraction isEqualToString:@".25"]) {
                
                [self.quantityPickerView selectRow:1 inComponent:1 animated:YES];
                
            } else if ([theFraction isEqualToString:@".50"]) {
                
                [self.quantityPickerView selectRow:2 inComponent:1 animated:YES];
                
            } else if ([theFraction isEqualToString:@".75"]) {
                
                [self.quantityPickerView selectRow:3 inComponent:1 animated:YES];
            }
        }
        
        self.selectedFoodQuantity = theQuantity;
        self.selectedFoodQuantityFraction = theFraction;
        
        self.quantityTextField.text = [NSString stringWithFormat:@"%@%@", theQuantity, theFraction];
        
        // calories
        
        newValue = [self.selectedFoodCalories floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        self.addFoodCaloriesLabel.text = [NSString stringWithFormat:@"%.0f", newValue];
        
        // carbs
        
        newValue = [self.selectedFoodCarbs floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodCarbsLabel setAttributedText:nutritionValueStr];
        
        // fiber
        
        newValue = [self.selectedFoodFiber floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor whiteColor]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodFiberLabel setAttributedText:nutritionValueStr];

        // sugar
        
        newValue = [self.selectedFoodSugar floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodSugarLabel setAttributedText:nutritionValueStr];
        
        // protein
        
        newValue = [self.selectedFoodProtein floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor whiteColor]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodProteinLabel setAttributedText:nutritionValueStr];
        
        // total fat
        
        newValue = [self.selectedFoodFat floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodFatLabel setAttributedText:nutritionValueStr];
        
        // sat fat
        
        newValue = [self.selectedFoodSatFat floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor whiteColor]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodSatFatLabel setAttributedText:nutritionValueStr];
        
        // sodium
        
        newValue = [self.selectedFoodSodium floatValue] * ([theQuantity integerValue] + [theFraction floatValue]);
        
        nutritionValueStr = [[NSMutableAttributedString alloc]
                             initWithString:[NSString stringWithFormat:@"%.0fmg%@", newValue, @"..."]];
        
        [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                                  range:NSMakeRange([nutritionValueStr length] - 3, 3)];
        
        [self.addFoodSodiumLabel setAttributedText:nutritionValueStr];
        
    } else if (pickerView.tag == 2) { // add to planner time
        
        NSString *theTime;
        NSString *theFraction;
        NSString *theAmPm;
        
        theTime = [self.addFoodTimePickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theFraction = [self.addFoodTimePickerValueFractions
                       objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        theAmPm = [self.addFoodTimePickerValueAmPm
                   objectAtIndex:[pickerView selectedRowInComponent:2]];
        
        self.selectedFoodTime = theTime;
        self.selectedFoodTimeFraction = theFraction;
        self.selectedFoodTimeAmPm = theAmPm;
        
        NSInteger thisInteger = [theTime integerValue];
        
        self.addFoodTimeTextField.text = [NSString stringWithFormat:@"%ld%@%@", (long)thisInteger, theFraction, theAmPm];
        
    } else if (pickerView.tag == 3) { // add food reminder time
        
        NSString *theTime;
        NSString *theFraction;
        NSString *theAmPm;
        
        theTime = [self.addFoodReminderPickerValues
                   objectAtIndex:[pickerView selectedRowInComponent:0]];
        
        theFraction = [self.addFoodReminderPickerValueFractions
                       objectAtIndex:[pickerView selectedRowInComponent:1]];
        
        theAmPm = [self.addFoodReminderPickerValueAmPm
                   objectAtIndex:[pickerView selectedRowInComponent:2]];
        
        self.selectedFoodReminder = theTime;
        self.selectedFoodReminderFraction = theFraction;
        self.selectedFoodReminderAmPm = theAmPm;
        
        if ([theTime isEqualToString:@"none"]) {
            
            self.selectedFoodReminder = @"";
            self.selectedFoodReminderFraction = @"";
            self.selectedFoodReminderAmPm = @"";
            
            self.addFoodReminderTextField.text = @"";
            
            [self.addFoodReminderPickerValueFractions removeAllObjects];
            [self.addFoodReminderPickerValueAmPm removeAllObjects];
            
            [self.addFoodReminderPickerValueFractions insertObject:@"--" atIndex:0];
            [self.addFoodReminderPickerValueAmPm insertObject:@"--" atIndex:0];
            
            [self.addFoodReminderPickerView reloadAllComponents];
            
            [self.addFoodReminderPickerView selectRow:0 inComponent:1 animated:YES];
            [self.addFoodReminderPickerView selectRow:0 inComponent:2 animated:YES];
            
        } else {
            
            [self.addFoodReminderPickerValueFractions removeAllObjects];
            [self.addFoodReminderPickerValueAmPm removeAllObjects];
            
            [self.addFoodReminderPickerValueFractions insertObject:@":00" atIndex:0];
            [self.addFoodReminderPickerValueFractions insertObject:@":15" atIndex:1];
            [self.addFoodReminderPickerValueFractions insertObject:@":30" atIndex:2];
            [self.addFoodReminderPickerValueFractions insertObject:@":45" atIndex:3];
            
            [self.addFoodReminderPickerValueAmPm insertObject:@"am" atIndex:0];
            [self.addFoodReminderPickerValueAmPm insertObject:@"pm" atIndex:1];
            
            [self.addFoodReminderPickerView reloadAllComponents];
            
            NSInteger thisInteger = [theTime integerValue];
            
            theFraction = [self.addFoodReminderPickerValueFractions
                           objectAtIndex:[pickerView selectedRowInComponent:1]];
            
            theAmPm = [self.addFoodReminderPickerValueAmPm
                       objectAtIndex:[pickerView selectedRowInComponent:2]];
            
            self.selectedFoodReminder = theTime;
            self.selectedFoodReminderFraction = theFraction;
            self.selectedFoodReminderAmPm = theAmPm;
            
            self.addFoodReminderTextField.text = [NSString stringWithFormat:@"%ld%@%@", (long)thisInteger, theFraction, theAmPm];
        }
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView.tag == 1) { // quantity
        
        if (component == 0) {  // numbers
            
            return 17;
            
        } else { // fractions
            
            return [self.quantityPickerValueFractions count]; // 3 or 4;
        }
        
    } else if (pickerView.tag == 2) { // add food time
        
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
            
            return [self.addFoodReminderPickerValueFractions count]; // 1 or 4
            
        } else { // am, pm
            
            return [self.addFoodReminderPickerValueAmPm count]; // 1 or 2
        }
        
    } else {
        
        return 1;
    }
}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    if (pickerView.tag == 1) { // quantity
        
        return 2;
        
    } else if (pickerView.tag == 2 || pickerView.tag == 3) { // add food time, reminder
        
        return 3;
        
    } else {
    
        return 1;
    }
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    
    if (pickerView.tag == 1) { // quantity
        
        if (component == 0) { // numbers
            
            title = [self.quantityPickerValues objectAtIndex:row];
            
        } else { // fractions
            
            title = [self.quantityPickerValueFractions objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 2) { // add food time
        
        if (component == 0) { // numbers
            
            title = [self.addFoodTimePickerValues objectAtIndex:row];
            
            NSInteger thisInteger = [title integerValue];
            
            title = [NSString stringWithFormat:@"%d", (int)thisInteger];
            
        } else if (component == 1) { // fractions
            
            title = [self.addFoodTimePickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            title = [self.addFoodTimePickerValueAmPm objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 3) { // add food reminder
        
        if (component == 0) { // numbers
            
            title = [self.addFoodReminderPickerValues objectAtIndex:row];
            
            if (![title isEqualToString:@"none"]) {
            
                NSInteger thisInteger = [title integerValue];

                title = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else if (component == 1) { // fractions
            
            title = [self.addFoodReminderPickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            title = [self.addFoodReminderPickerValueAmPm objectAtIndex:row];
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
    
    if (pickerView.tag == 1) { // quantity
        
        if (component == 0) {
            
            pickerLabel.text = [self.quantityPickerValues objectAtIndex:row];
            
        } else {
            
            pickerLabel.text = [self.quantityPickerValueFractions objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 2) { // add food time
        
        if (component == 0) {
            
            NSInteger thisInteger = [[self.addFoodTimePickerValues objectAtIndex:row] integerValue];
            
            pickerLabel.text = [NSString stringWithFormat:@"%d", (int)thisInteger];
            
        } else if (component == 1) { // fractions
            
            pickerLabel.text = [self.addFoodTimePickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            pickerLabel.text = [self.addFoodTimePickerValueAmPm objectAtIndex:row];
        }
        
    } else if (pickerView.tag == 3) { // add food reminder
        
        if (component == 0) {
            
            if ([[self.addFoodReminderPickerValues objectAtIndex:row] isEqualToString:@"none"]) {
                
                pickerLabel.text = @"none";
                
            } else {
                
                NSInteger thisInteger = [[self.addFoodReminderPickerValues objectAtIndex:row] integerValue];
                
                pickerLabel.text = [NSString stringWithFormat:@"%d", (int)thisInteger];
            }
            
        } else if (component == 1) { // fractions
            
            pickerLabel.text = [self.addFoodReminderPickerValueFractions objectAtIndex:row];
            
        } else { // am, pm
            
            pickerLabel.text = [self.addFoodReminderPickerValueAmPm objectAtIndex:row];
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
    
    self.selectedFoodName = @"";
    self.selectedFoodDetailsID = @"";
    self.selectedFoodCalories = @"";
    self.selectedFoodProtein = @"";
    self.selectedFoodCarbs = @"";
    self.selectedFoodFiber = @"";
    self.selectedFoodSugar = @"";
    self.selectedFoodSodium = @"";
    self.selectedFoodFat = @"";
    self.selectedFoodSatFat = @"";
    self.selectedFoodServings = @"";
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
        
    } else if ([elementName isEqualToString:@"food_item_name"]) {
        
        self.selectedFoodName = [cleanString capitalizedString];
        
    } else if ([elementName isEqualToString:@"food_item_id"]) {
        
        self.selectedFoodDetailsID = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_calories"]) {
        
        self.selectedFoodCalories = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_protein"]) {
        
        self.selectedFoodProtein = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_carbs"]) {
        
        self.selectedFoodCarbs = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_fiber"]) {
        
        self.selectedFoodFiber = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_sugar"]) {
        
        self.selectedFoodSugar = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_sodium"]) {
        
        self.selectedFoodSodium = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_fat"]) {
        
        self.selectedFoodFat = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_sat_fat"]) {
        
        self.selectedFoodSatFat = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_servings"]) {
        
        self.selectedFoodServings = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_quantity"]) {
        
        if (![cleanString isEqualToString:@""]) { // we've got a quantity
            
            // this does not work in iOS 7
            
            //if ([cleanString containsString:@"."]) { // contains a fraction
            
            if ([cleanString rangeOfString:@"."].location != NSNotFound) {
                
                self.selectedFoodQuantity = [cleanString substringToIndex:[cleanString rangeOfString:@"."].location];
                
                self.selectedFoodQuantityFraction = [cleanString substringFromIndex:[cleanString rangeOfString:@"."].location];
            
            } else { // whole number
                
                self.selectedFoodQuantity = cleanString;
                self.selectedFoodQuantityFraction = @".00";
            }
        }
        
    } else if ([elementName isEqualToString:@"food_item_category"]
               && ![cleanString isEqualToString:@""]) {
        
        self.addFoodCategory = cleanString;
        
    } else if ([elementName isEqualToString:@"food_item_time"]
               && ![cleanString isEqualToString:@""]) {
        
        self.selectedFoodTime = cleanString;
        
        if ([self.selectedFoodTime integerValue] > 12
            && [self.selectedFoodTime integerValue] != 24) {
            
            self.selectedFoodTime = [NSString stringWithFormat:@"%ld", (long)[self.selectedFoodTime integerValue] - 12];
            
            self.selectedFoodTimeAmPm = @"pm";
            
        } else if ([self.selectedFoodTime integerValue] == 24 ||
                   [self.selectedFoodTime integerValue] == 0) {
            
            self.selectedFoodTime = @"12";
            self.selectedFoodTimeAmPm = @"am";
            
        }  else if ([self.selectedFoodTime integerValue] == 12) {
            
            self.selectedFoodTime = @"12";
            self.selectedFoodTimeAmPm = @"pm";
            
        } else {
            
            self.selectedFoodTimeAmPm = @"am";
        }
        
    } else if ([elementName isEqualToString:@"food_item_time_fraction"]) {
        
        if ([cleanString isEqualToString:@""]) {
            
            self.selectedFoodTimeFraction = @":00";
            
        } else {
            
            self.selectedFoodTimeFraction = cleanString;
        }
        
    } else if ([elementName isEqualToString:@"food_item_reminder_time"]
               && ![cleanString isEqualToString:@""]) {
        
        self.selectedFoodReminder = cleanString;
        
        if ([self.selectedFoodReminder integerValue] > 12
            && [self.selectedFoodReminder integerValue] != 24) {
            
            self.selectedFoodReminder = [NSString stringWithFormat:@"%ld", (long)[self.selectedFoodReminder integerValue] - 12];
            
            self.selectedFoodReminderAmPm = @"pm";
            
        } else if ([self.selectedFoodReminder integerValue] == 24 ||
                   [self.selectedFoodReminder integerValue] == 0) {
            
            self.selectedFoodReminder = @"12";
            self.selectedFoodReminderAmPm = @"am";
            
        }  else if ([self.selectedFoodReminder integerValue] == 12) {
            
            self.selectedFoodReminder = @"12";
            self.selectedFoodReminderAmPm = @"pm";
            
        } else {
            
            self.selectedFoodReminderAmPm = @"am";
        }
        
    } else if ([elementName isEqualToString:@"food_item_reminder_time_fraction"]) {
        
        if ([cleanString isEqualToString:@""]) {
            
            self.selectedFoodReminderFraction = @":00";
            
        } else {
            
            self.selectedFoodReminderFraction = cleanString;
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
        
        if (self.doneAddingFood == YES) {
            
            [[self navigationController] popToRootViewControllerAnimated:YES];
        
        } else {
            
            [self showFoodItem];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if ([segue.identifier isEqualToString:@"showFoodItemDetails"]) {
        
        HTAddFoodSelectItemDetailsViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        viewController.mealItemID = [self.selectedFoodDetailsID integerValue];
        
    } else {
        
        HTAddFoodSearchResultsViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        viewController.addFoodCategory = self.addFoodCategory;
        viewController.relaunchItemID = self.relaunchItemID;
        
        viewController.addFoodSearchString = [NSString
                                              stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld",
                                              self.addFoodCategory,
                                              @"",
                                              @"true",
                                              (long)self.relaunchItemID];
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
