//
//  HTPlannerViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/29/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTPlannerViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTAddFoodSelectItemViewController.h"
#import "HTAddFoodSearchResultsViewController.h"
#import "HTAddActivitySelectItemViewController.h"

@interface HTPlannerViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTPlannerViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    UIImageView *buttonImageView;
    
    int screenOffset = (self.view.frame.size.width - 320);
    int buttonImageOffset = (screenOffset / 4) + 63;
    
    [self.buttonAddFood.layer setCornerRadius:4.5f];
    [self.buttonAddFood.layer setBorderWidth:0.5];
    [self.buttonAddFood.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                green:(200/255.0)
                                                                 blue:(204/255.0)
                                                                alpha:1.0].CGColor];
    
    [self.buttonAddFood setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)]; //63
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-food"]];
    
    [self.buttonAddFood addSubview:buttonImageView];
    
    [self.buttonAddActivity.layer setCornerRadius:2.5f];
    [self.buttonAddActivity.layer setBorderWidth:0.7];
    [self.buttonAddActivity.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                     green:(200/255.0)
                                                                      blue:(204/255.0)
                                                                     alpha:1.0].CGColor];
    
    [self.buttonAddActivity setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-activity"]];
    
    [self.buttonAddActivity addSubview:buttonImageView];
    
    [self.buttonCreateFavorites.layer setCornerRadius:2.5f];
    [self.buttonCreateFavorites.layer setBorderWidth:0.7];
    [self.buttonCreateFavorites.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                               green:(200/255.0)
                                                                blue:(204/255.0)
                                                               alpha:1.0].CGColor];
    
    [self.buttonCreateFavorites setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-create-favorites"]];
    
    [self.buttonCreateFavorites addSubview:buttonImageView];
    
    [self.buttonCreatePlan.layer setCornerRadius:2.5f];
    [self.buttonCreatePlan.layer setBorderWidth:0.7];
    [self.buttonCreatePlan.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                              green:(200/255.0)
                                                               blue:(204/255.0)
                                                              alpha:1.0].CGColor];
    
    [self.buttonCreatePlan setTitleEdgeInsets:UIEdgeInsetsMake(29.0f, 0.0f, 0.0f, 0.0f)];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(buttonImageOffset, 12, 18, 18)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-create-plan"]];
    
    [self.buttonCreatePlan addSubview:buttonImageView];
    
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
    
    self.selectedFoodCategory = @"";
    self.exchangeItemsString = @"";
    self.saveToMyPlansName = @"";
    self.caloriesOrOtherString = @"calories";
    
    self.hasSavedMyPlans = NO;
    self.doneDeletingFood = NO;
    
    [super viewWillAppear:animated];
    
    [self getPlanner:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getPlanner:(NSString *) url withState:(BOOL) urlState {
    
    NSArray *viewsToRemove = [self.plannerScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFood = NO;
    self.hasSavedMyPlans = NO;
    
    self.plannerItemCount = 0;
    self.selectedFoodID = 0;
    
    self.numberOfNewMessages = 0;
    self.numberOfEatingPlans = 0;
    self.numberOfLearningModules = 0;
    
    self.planName = [[NSString alloc] init];
    self.templateName = [[NSString alloc] init];
    self.planCalories = [[NSString alloc] init];
    
    self.plannerItemID = [[NSMutableArray alloc] init];
    self.plannerItemHour = [[NSMutableArray alloc] init];
    self.plannerItemEat = [[NSMutableArray alloc] init];
    self.plannerItemMove = [[NSMutableArray alloc] init];
    self.plannerItemBalance = [[NSMutableArray alloc] init];
    self.plannerItemReminder = [[NSMutableArray alloc] init];
    self.plannerItemCalories = [[NSMutableArray alloc] init];
    self.plannerItemMealID = [[NSMutableArray alloc] init];
    self.plannerItemExchangeItems = [[NSMutableArray alloc] init];
    self.plannerItemPlaceholder = [[NSMutableArray alloc] init];
    self.plannerItemNotes = [[NSMutableArray alloc] init];
    self.plannerItemSubNotes = [[NSMutableArray alloc] init];
    self.plannerItemImage = [[NSMutableArray alloc] init];
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    [self.leftDateArrow setUserInteractionEnabled:YES];
    [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
    
    [self.rightDateArrow setUserInteractionEnabled:YES];
    [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
    }
    else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    }

    [dateFormatter setDateFormat:@"MMMM yyyy"];
    
    self.title = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    
    NSArray *items = self.tabBarController.tabBar.items;
    
    UITabBarItem *item = [items objectAtIndex:2];
    
    item.title = @"PLAN";
    
    myRequestString = [NSString stringWithFormat:@"action=get_planner&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)deleteFoodItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFood = YES; // after the item is deleted
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_delete_item&WhichID=%ld&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", (long)self.selectedFoodID, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)saveToMyPlans:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFood = YES; // after the item is deleted
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.saveToMyPlansName = [appDelegate cleanStringBeforeSending:self.saveToMyPlansName];
    
    myRequestString = [NSString stringWithFormat:@"action=save_planner_to_my_plans&plan_name=%@&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", self.saveToMyPlansName, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showPlanner {
    
    NSArray *viewsToRemove = [self.plannerScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    if (self.hasSavedMyPlans == YES) {
        
        self.navigationItem.rightBarButtonItem = [self myPlansButton];
        
    } else {
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 8;
    NSInteger vPosOffset = 58;
    NSInteger plannerBlockHeight = 59;
    NSInteger plannerBlockOffset1 = 15;
    NSInteger plannerBlockOffset2 = 10;
    
    if (screenWidth == 320) {
        
        plannerBlockHeight = 45;
        plannerBlockOffset1 = 8;
        plannerBlockOffset2 = 8;
        
        vPosOffset = 43;
    }
    
    UIButton *plannerBlock;
    UIButton *reminderButton;
    
    UIView *graySeparator;
    UIView *plannerBlockBottomBorder;
    
    NSString *currentPlannerHour = @"";
    NSString *currentPlannerItemType = @"";
    NSString *currentPlannerSubNotes = @"";
    
    NSMutableAttributedString *plannerHourString;
    
    UIFont *planNameFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    UIFont *plannerHourFont = [UIFont fontWithName:@"Avenir-Medium" size:13.0];
    UIFont *plannerNotesFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    UIFont *plannerSubNotesFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:10.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UILabel *timeSlotLabel;
    UILabel *notesLabel;
    UILabel *subNotesLabel;
    
    UIImageView *plannerItemIconView;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 104, screenWidth, 1)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(217/255.0) green:(227/255.0) blue:(231/255.0) alpha:1.0];
    
    [self.view addSubview:graySeparator];
    
    UILabel *planNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(63, vPos, screenWidth - 126, 28)];
    
    [planNameLabel setFont:planNameFont];
    [planNameLabel setTextColor:grayFontColor];
    [planNameLabel setTextAlignment:NSTextAlignmentCenter];
    
    if ([self.planName isEqualToString:@""]) {
        
        planNameLabel.text = self.templateName;
        
    } else {
        
        planNameLabel.text = self.planName;
    }
    
    [self.plannerScrollView addSubview:planNameLabel];
    
    if ([self.plannerItemID count] > 1) {
        
        self.navigationItem.leftBarButtonItem = [self saveAsButton];
        
    } else { // no planner items
        
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    // planner nutrition totals
    
    UIButton *plannerImageButton = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth - 38, vPos, 28, 28)];
    
    [plannerImageButton setImage:[UIImage imageNamed:@"ht-planner-nutrition"]
                        forState:UIControlStateNormal];
    
    [plannerImageButton addTarget:self action:@selector(showPlannerNutrition) forControlEvents:UIControlEventTouchUpInside];
    
    [self.plannerScrollView addSubview:plannerImageButton];
    
    vPos += 30;
    
    UILongPressGestureRecognizer *longPress;
    
    BOOL showReminderIcon;
    
    // planner items!
    for (int i=1; i<[self.plannerItemID count]; i++) {
        
        showReminderIcon = NO;
        
        // new time slot?
        if (![[self.plannerItemHour objectAtIndex:i] isEqualToString:currentPlannerHour]) {
            
            currentPlannerHour = [self.plannerItemHour objectAtIndex:i];
            
            timeSlotLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, vPos, 48, 11)];
            
            [timeSlotLabel setFont:plannerHourFont];
            [timeSlotLabel setTextColor:grayFontColor];
            [timeSlotLabel setTextAlignment:NSTextAlignmentRight];
            
            plannerHourString = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@",
                                            currentPlannerHour]];
            
            [plannerHourString addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"Avenir-Medium" size:9]
                                 range:NSMakeRange([plannerHourString length] - 2, 2)];

            timeSlotLabel.attributedText = plannerHourString;
            
            [self.plannerScrollView addSubview:timeSlotLabel];
            
            // 12px
            
            vPos += 7;
            
            graySeparator = [[UIView alloc] initWithFrame:CGRectMake(64, vPos, (screenWidth - 64), 1)];
            graySeparator.backgroundColor = [UIColor colorWithRed:(178/255.0) green:(178/255.0) blue:(178/255.0) alpha:1.0];
            
            [self.plannerScrollView addSubview:graySeparator];
        }
        
        vPos += 7;
        
        // reminder?
        
        if (![[self.plannerItemReminder objectAtIndex:i] isEqualToString:@""]) {
            
            showReminderIcon = YES; // showing this later, to attach to the same selector as the planner item itself
        }
        
        // currentPlannerItemType
        
        if (![[self.plannerItemEat objectAtIndex:i] isEqualToString:@""]) { // eat item
            
            if ([[self.plannerItemEat objectAtIndex:i] isEqualToString:@"TEMP_LABEL"]) {
                
                currentPlannerItemType = @"NOTE";
                
            } else if ([[self.plannerItemPlaceholder objectAtIndex:i] isEqualToString:@"1"] &&
                       ([[self.plannerItemCalories objectAtIndex:i] isEqualToString:@""]
                        ||[[self.plannerItemCalories objectAtIndex:i] isEqualToString:@"0"]) &&
                       ([[self.self.plannerItemMealID objectAtIndex:i] isEqualToString:@""]
                        ||[[self.self.plannerItemMealID objectAtIndex:i] isEqualToString:@"0"])) {
                        // template w/ no selection
                           
                currentPlannerItemType = @"TEMPLATE";
                
            } else {
                
                currentPlannerItemType = @"EAT";
            }
        } else if (![[self.plannerItemMove objectAtIndex:i] isEqualToString:@""]) { // move item
            
            currentPlannerItemType = @"MOVE";
            
        } else if (![[self.plannerItemBalance objectAtIndex:i] isEqualToString:@""]) { // balance item
            
            currentPlannerItemType = @"BALANCE";
            
        } else { // note
            
            currentPlannerItemType = @"NOTE";
        }
        
        plannerBlock = [[UIButton alloc] initWithFrame:CGRectMake(71, vPos, (screenWidth - 80), plannerBlockHeight)];
        
        [plannerBlock setTag:i];
        
        if ([currentPlannerItemType isEqualToString:@"TEMPLATE"]) { // empty template item
            
            [plannerBlock addTarget:self action:@selector(relaunchPlannerTemplateItem:) forControlEvents:UIControlEventTouchUpInside];
            
            if (showReminderIcon == YES) {
            
                reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(38, (vPos + ((plannerBlockHeight / 2) - 8)), 16, 16)];
                
                [reminderButton setTag:i];
                [reminderButton setImage:[UIImage imageNamed:@"ht-reminder-on"] forState:UIControlStateNormal];
                [reminderButton addTarget:self action:@selector(relaunchPlannerTemplateItem:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.plannerScrollView addSubview:reminderButton];
            }
            
        } else if (![[self.plannerItemEat objectAtIndex:i] isEqualToString:@""] &&
                   ![[self.plannerItemEat objectAtIndex:i] isEqualToString:@"TEMP_LABEL"]) { // eat item
            
            [plannerBlock addTarget:self action:@selector(relaunchPlannerItem:) forControlEvents:UIControlEventTouchUpInside];
            
            if (showReminderIcon == YES) {
                
                reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(38, (vPos + ((plannerBlockHeight / 2) - 8)), 16, 16)];
                
                [reminderButton setTag:i];
                [reminderButton setImage:[UIImage imageNamed:@"ht-reminder-on"] forState:UIControlStateNormal];
                [reminderButton addTarget:self action:@selector(relaunchPlannerItem:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.plannerScrollView addSubview:reminderButton];
            }
            
        } else { // activity item - exercise, balance, note
            
            [plannerBlock addTarget:self action:@selector(relaunchActivityItem:) forControlEvents:UIControlEventTouchUpInside];
            
            if (showReminderIcon == YES) {
                
                reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(38, (vPos + ((plannerBlockHeight / 2) - 8)), 16, 16)];
                
                [reminderButton setTag:i];
                [reminderButton setImage:[UIImage imageNamed:@"ht-reminder-on"] forState:UIControlStateNormal];
                [reminderButton addTarget:self action:@selector(relaunchActivityItem:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.plannerScrollView addSubview:reminderButton];
            }
        }
        
        longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(deletePlannerItem:)];
        [plannerBlock addGestureRecognizer:longPress];
        
        [plannerBlock setBackgroundColor:[UIColor whiteColor]];
        
        [plannerBlock.layer setBorderWidth:0.5];
        [plannerBlock.layer setBorderColor:[UIColor colorWithRed:(197/255.0)
                                                           green:(197/255.0)
                                                            blue:(197/255.0)
                                                           alpha:1.0].CGColor];
        
        plannerItemIconView = [[UIImageView alloc] initWithFrame:CGRectMake(plannerBlockOffset2, plannerBlockOffset1, 28, 28)];
        
        plannerBlockBottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, (plannerBlockHeight - 2), (screenWidth - 80), 2)];
        
        if ([currentPlannerItemType isEqualToString:@"EAT"]) {
            
            plannerItemIconView.image = [UIImage imageNamed:@"ht-planner-meal"];
            
            [plannerBlockBottomBorder setBackgroundColor:[UIColor colorWithRed:(187/255.0)
                                                                        green:(227/255.0)
                                                                         blue:(69/255.0)
                                                                         alpha:1.0]];
            
        } else if ([currentPlannerItemType isEqualToString:@"TEMPLATE"]) {
            
            plannerItemIconView.image = [UIImage imageNamed:@"ht-planner-meal-empty"];
            
            [plannerBlockBottomBorder setBackgroundColor:[UIColor colorWithRed:(136/255.0)
                                                                         green:(136/255.0)
                                                                          blue:(136/255.0)
                                                                         alpha:1.0]];
            
        } else if ([currentPlannerItemType isEqualToString:@"MOVE"]) {
            
            plannerItemIconView.image = [UIImage imageNamed:@"ht-planner-activity"];
            
            [plannerBlockBottomBorder setBackgroundColor:[UIColor colorWithRed:(104/255.0)
                                                                         green:(193/255.0)
                                                                          blue:(193/255.0)
                                                                         alpha:1.0]];
            
        } else if ([currentPlannerItemType isEqualToString:@"BALANCE"]) {
            
            plannerItemIconView.image = [UIImage imageNamed:@"ht-planner-balance"];
            
            [plannerBlockBottomBorder setBackgroundColor:[UIColor colorWithRed:(163/255.0)
                                                                         green:(119/255.0)
                                                                          blue:(201/255.0)
                                                                         alpha:1.0]];
            
        } else { // NOTE
            
            plannerItemIconView.image = [UIImage imageNamed:@"ht-planner-note"];
            
            [plannerBlockBottomBorder setBackgroundColor:[UIColor colorWithRed:(238/255.0)
                                                                         green:(107/255.0)
                                                                          blue:(138/255.0)
                                                                         alpha:1.0]];
        }
        
        [plannerBlock addSubview:plannerItemIconView];
        [plannerBlock addSubview:plannerBlockBottomBorder];
        
        // sub_notes?
        
        currentPlannerSubNotes = [self.plannerItemSubNotes objectAtIndex:i];
        
        if ((![currentPlannerSubNotes isEqualToString:@""] ||
            ([currentPlannerItemType isEqualToString:@"EAT"] &&
            ![[self.plannerItemCalories objectAtIndex:i] isEqualToString:@""]))
            && ! [currentPlannerSubNotes isEqualToString:[self.plannerItemNotes objectAtIndex:i]]) {
                
                notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, ((plannerBlockHeight / 2) - 16), (screenWidth - 133), 20)];
                
                [notesLabel setFont:plannerNotesFont];
                [notesLabel setTextColor:grayFontColor];
                [notesLabel setTextAlignment:NSTextAlignmentLeft];
                
                if (![currentPlannerSubNotes isEqualToString:@""]) { // there are sub notes, add caloriesOrOtherString to the notes
                    
                    [notesLabel setText:[NSString stringWithFormat:@"%@ - %@ %@",
                                         [self.plannerItemNotes objectAtIndex:i],
                                         [self.plannerItemCalories objectAtIndex:i],
                                         self.caloriesOrOtherString]];
                    
                } else {
                    
                    [notesLabel setText:[self.plannerItemNotes objectAtIndex:i]];
                }
                
                [plannerBlock addSubview:notesLabel];
                
                subNotesLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, ((plannerBlockHeight / 2) + 2), (screenWidth - 133), 14)];
                
                [subNotesLabel setFont:plannerSubNotesFont];
                [subNotesLabel setTextColor:grayFontColor];
                [subNotesLabel setTextAlignment:NSTextAlignmentLeft];
                
                if (![currentPlannerSubNotes isEqualToString:@""]) { // sub_notes
                    
                    [subNotesLabel setText:currentPlannerSubNotes];
                    
                } else { // create the sub_notes
                    
                    [subNotesLabel setText:[NSString stringWithFormat:@"%@ %@",
                                            [self.plannerItemCalories objectAtIndex:i],
                                            @"calories"]];
                }
                
                [plannerBlock addSubview:subNotesLabel];
            
        } else { // no sub_notes
            
            notesLabel = [[UILabel alloc] initWithFrame:CGRectMake(48, ((plannerBlockHeight / 2) - 9), (screenWidth - 133), 20)];
            
            [notesLabel setFont:plannerNotesFont];
            [notesLabel setTextColor:grayFontColor];
            [notesLabel setTextAlignment:NSTextAlignmentLeft];
            [notesLabel setText:[self.plannerItemNotes objectAtIndex:i]];
            
            [plannerBlock addSubview:notesLabel];
        }
        
        [self.plannerScrollView addSubview:plannerBlock];
        
        vPos += vPosOffset;
    }
    
    [self.plannerScrollView setContentSize:CGSizeMake(screenWidth, vPos + 10)];
    
    [self.plannerScrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (UIBarButtonItem *)myPlansButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"My Plans"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(myPlansButtonPressed)];
    return item;
}

- (UIBarButtonItem *)saveAsButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Save As" style:UIBarButtonItemStylePlain target:self action:@selector(saveAsButtonPressed)];
    
    return item;
}

- (void)myPlansButtonPressed {
    
    [self performSegueWithIdentifier:@"showMyPlansFromPlanner" sender:self];
}

- (void)saveAsButtonPressed {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Save to My Plans?" message:@"Enter a name to save this plan to My Plans for future use" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 2;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    
    if ([self.planName isEqualToString:@""]) {
        
        textField.text = self.templateName;
        
    } else {
        
        textField.text = self.planName;
    }
    
    [alertView show];
}

- (IBAction) clickedAddFood:(id)sender {
    
    [self performSegueWithIdentifier:@"showAddFoodFromPlanner" sender:self];
}

- (IBAction) clickedAddActivity:(id)sender {
    
    [self performSegueWithIdentifier:@"showAddActivityFromPlanner" sender:self];
}

- (IBAction) clickedCreateFavorites:(id)sender {
    
    [self performSegueWithIdentifier:@"showCreateFavoritesFromPlanner" sender:self];
}

- (IBAction) clickedCreatePlan:(id)sender {
    
    [self performSegueWithIdentifier:@"showCreateEatingPlanFromPlanner" sender:self];
}

- (IBAction) leftDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getPlanner:HTWebSvcURL withState:0];
}

- (IBAction) rightDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getPlanner:HTWebSvcURL withState:0];
}

- (IBAction) relaunchPlannerItem:(id)sender {
    
    UIButton *button = sender;
    
    self.selectedFoodID = button.tag;
    
    // template item
    if ([[self.plannerItemPlaceholder objectAtIndex:button.tag] isEqualToString:@"1"]) {
        
        self.selectedFoodCategory = @"template";
    }
    
    if (![[self.plannerItemExchangeItems objectAtIndex:button.tag] isEqualToString:@""]) {
        
        self.selectedFoodCategory = @"exchange";
        self.exchangeItemsString = [self.plannerItemExchangeItems objectAtIndex:button.tag];
    }
    
    [self performSegueWithIdentifier:@"relaunchPlannerItem" sender:self];
}

- (IBAction) relaunchActivityItem:(id)sender {
    
    UIButton *button = sender;
    
    self.selectedFoodID = button.tag;
    
    [self performSegueWithIdentifier:@"relaunchActivityItem" sender:self];
}

- (IBAction) relaunchPlannerTemplateItem:(id)sender {
    
    UIButton *button = sender;
    
    self.selectedFoodID = button.tag;
    
    [self performSegueWithIdentifier:@"relaunchPlannerTemplateItem" sender:self];
}

- (void)showPlannerNutrition {
    
    [self performSegueWithIdentifier:@"showNutritionFromPlanner" sender:self];
}

- (void)deletePlannerItem:(id)sender {
    
    UILongPressGestureRecognizer *recognizer = sender;
    
    self.selectedFoodID = [[self.plannerItemID objectAtIndex:recognizer.view.tag] integerValue];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Item?" message:@"Are you sure you want to delete this item from your Plan?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        
        alertView.tag = 1;
        
        [alertView show];
    }
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1 && buttonIndex == 1) { // delete food item
        
        [self deleteFoodItem:HTWebSvcURL withState:0];
    
    } else if (alertView.tag == 2 && buttonIndex == 1) {
        
        self.saveToMyPlansName = [[[alertView textFieldAtIndex:0] text]
                                  stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];

        [self saveToMyPlans:HTWebSvcURL withState:0];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if (alertView.tag == 2) {
        
        self.saveToMyPlansName = [[[alertView textFieldAtIndex:0] text]
                                  stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        
        if ([self.saveToMyPlansName isEqualToString:@""]) {
            
            return NO;
            
        } else {
            
            return YES;
        }
        
    } else {
        
        return YES;
    }
    
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
    
    //HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    self.plannerItemCount = 0;
    
    self.planName = @"";
    self.templateName = @"";
    self.planCalories = @"";
    self.caloriesOrOtherString = @"calories";

    [self.plannerItemID removeAllObjects];
    [self.plannerItemHour removeAllObjects];
    [self.plannerItemEat removeAllObjects];
    [self.plannerItemMove removeAllObjects];
    [self.plannerItemBalance removeAllObjects];
    [self.plannerItemReminder removeAllObjects];
    [self.plannerItemCalories removeAllObjects];
    [self.plannerItemMealID removeAllObjects];
    [self.plannerItemExchangeItems removeAllObjects];
    [self.plannerItemPlaceholder removeAllObjects];
    [self.plannerItemNotes removeAllObjects];
    [self.plannerItemSubNotes removeAllObjects];
    [self.plannerItemImage removeAllObjects];
    
    [self.plannerItemID insertObject:@"" atIndex:0];
    [self.plannerItemHour insertObject:@"" atIndex:0];
    [self.plannerItemEat insertObject:@"" atIndex:0];
    [self.plannerItemMove insertObject:@"" atIndex:0];
    [self.plannerItemBalance insertObject:@"" atIndex:0];
    [self.plannerItemReminder insertObject:@"" atIndex:0];
    [self.plannerItemCalories insertObject:@"" atIndex:0];
    [self.plannerItemMealID insertObject:@"" atIndex:0];
    [self.plannerItemExchangeItems insertObject:@"" atIndex:0];
    [self.plannerItemPlaceholder insertObject:@"" atIndex:0];
    [self.plannerItemNotes insertObject:@"" atIndex:0];
    [self.plannerItemSubNotes insertObject:@"" atIndex:0];
    [self.plannerItemImage insertObject:@"" atIndex:0];
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
        
    } else if ([elementName isEqualToString:@"calories_or_other_string"]) {
        
        self.caloriesOrOtherString = self.currentValue;
        
    } else if ([elementName isEqualToString:@"has_saved_my_plans"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.hasSavedMyPlans = YES;
            
        } else {
            
            self.hasSavedMyPlans = NO;
        }
        
    } else if ([elementName isEqualToString:@"plan_name"] && ![self.currentValue isEqualToString:@""]) {
        
        self.planName = self.currentValue;
        
    } else if ([elementName isEqualToString:@"template_name"] && ![self.currentValue isEqualToString:@""]) {
        
        self.templateName = self.currentValue;
        
    } else if ([elementName isEqualToString:@"plan_calories"]) {
        
        self.planCalories = self.currentValue;
        
    } else if ([elementName hasPrefix:@"planner_item_"]) { // planner items! set plannerItemCount
        
        self.plannerItemCount = [[elementName stringByReplacingOccurrencesOfString:@"planner_item_" withString:@""]
                                 integerValue];
        
    } else if ([elementName hasPrefix:@"id_"]) {
        
        [self.plannerItemID insertObject:self.currentValue
                                 atIndex:[[elementName
                                           stringByReplacingOccurrencesOfString:@"id_" withString:@""]
                                          integerValue]];
        
    } else if ([elementName hasPrefix:@"plan_hour_"]) {
        
        [self.plannerItemHour insertObject:self.currentValue
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"plan_hour_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName hasPrefix:@"eat_"]) {
        
        [self.plannerItemEat insertObject:self.currentValue
                                  atIndex:[[elementName
                                            stringByReplacingOccurrencesOfString:@"eat_" withString:@""]
                                           integerValue]];
        
    } else if ([elementName hasPrefix:@"move_"]) {
        
        [self.plannerItemMove insertObject:self.currentValue
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"move_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName hasPrefix:@"balance_"]) {
        
        [self.plannerItemBalance insertObject:self.currentValue
                                      atIndex:[[elementName
                                                stringByReplacingOccurrencesOfString:@"balance_" withString:@""]
                                               integerValue]];
        
    } else if ([elementName hasPrefix:@"reminder_"]) {
        
        [self.plannerItemReminder insertObject:self.currentValue
                                       atIndex:[[elementName
                                                 stringByReplacingOccurrencesOfString:@"reminder_" withString:@""]
                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"calories_"]) {
        
        [self.plannerItemCalories insertObject:self.currentValue
                                       atIndex:[[elementName
                                                 stringByReplacingOccurrencesOfString:@"calories_" withString:@""]
                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"meal_id_"]) {
        
        [self.plannerItemMealID insertObject:self.currentValue
                                     atIndex:[[elementName
                                               stringByReplacingOccurrencesOfString:@"meal_id_" withString:@""]
                                              integerValue]];
        
    } else if ([elementName hasPrefix:@"exchange_items_"]) {
        
        [self.plannerItemExchangeItems insertObject:self.currentValue
                                            atIndex:[[elementName
                                                      stringByReplacingOccurrencesOfString:@"exchange_items_" withString:@""]
                                                     integerValue]];
        
    } else if ([elementName hasPrefix:@"placeholder_"]) {
        
        [self.plannerItemPlaceholder insertObject:self.currentValue
                                          atIndex:[[elementName
                                                    stringByReplacingOccurrencesOfString:@"placeholder_" withString:@""]
                                                   integerValue]];
        
    } else if ([elementName hasPrefix:@"notes_"]) {
        
        [self.plannerItemNotes insertObject:self.currentValue
                                    atIndex:[[elementName
                                              stringByReplacingOccurrencesOfString:@"notes_" withString:@""]
                                             integerValue]];
        
    } else if ([elementName hasPrefix:@"sub_notes_"]) {
        
        [self.plannerItemSubNotes insertObject:self.currentValue
                                       atIndex:[[elementName
                                                 stringByReplacingOccurrencesOfString:@"sub_notes_" withString:@""]
                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"image_"]) {
        
        [self.plannerItemImage insertObject:self.currentValue
                                    atIndex:[[elementName
                                              stringByReplacingOccurrencesOfString:@"image_" withString:@""]
                                             integerValue]];
        
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
        
        UITabBarItem *item0 = [self.tabBarController.tabBar.items objectAtIndex:0];
        UITabBarItem *item2 = [self.tabBarController.tabBar.items objectAtIndex:2];
        UITabBarItem *item3 = [self.tabBarController.tabBar.items objectAtIndex:3];
        UITabBarItem *item4 = [self.tabBarController.tabBar.items objectAtIndex:4];
        
        item0.badgeValue = nil;
        item2.badgeValue = nil;
        item3.badgeValue = nil;
        item4.badgeValue = nil;
        
        if (self.numberOfNewMessages > 0) {
            
            item4.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            
            NSMutableDictionary *dashboardUserPrefs = [[NSMutableDictionary alloc] init];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            NSString *userPrefsString;
            
            userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
            
            if([prefs objectForKey:userPrefsString] != nil) { // exists
                
                dashboardUserPrefs = [NSMutableDictionary dictionaryWithDictionary:[prefs objectForKey:userPrefsString]];
                
                if (![[dashboardUserPrefs objectForKey:@"Inbox"] isEqualToString:@"0"]) {
                    
                    item0.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
                }
                
            } else { // no prefs, but messages, so show it
                
                item0.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            }
        }
        
        if (self.numberOfEatingPlans > 0) {
            
            item2.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfEatingPlans];
        }
        
        if (self.numberOfLearningModules > 0) {
            
            item3.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfLearningModules];
        }
        
        if (self.doneDeletingFood == YES) {
            
            [self getPlanner:HTWebSvcURL withState:0];
            
        } else {
            
            [self showPlanner];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if ([segue.identifier isEqualToString:@"relaunchPlannerItem"]) {
        
        HTAddFoodSelectItemViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        if ([self.selectedFoodCategory isEqualToString:@"template"]) {
            
            viewController.addFoodCategory = @"template";
            
            viewController.selectedFoodID = [[self.plannerItemMealID objectAtIndex:self.selectedFoodID] integerValue];
            
            viewController.relaunchItemID = [[self.plannerItemID objectAtIndex:self.selectedFoodID] integerValue];
            
        } else if ([self.selectedFoodCategory isEqualToString:@"exchange"]) {
            
            viewController.addFoodCategory = @"exchange";
            viewController.exchangeItemsString = [self.exchangeItemsString stringByReplacingOccurrencesOfString:@"***" withString:@"||"];
            
            viewController.selectedFoodID = [[self.plannerItemID objectAtIndex:self.selectedFoodID] integerValue];
        
        } else {
            
            viewController.selectedFoodID = [[self.plannerItemID objectAtIndex:self.selectedFoodID] integerValue];
        }
        
        viewController.relaunchPlannerItem = YES;
        
        if ([self.selectedFoodCategory isEqualToString:@"template"]
            || [self.selectedFoodCategory isEqualToString:@"exchange"]) {
            
            viewController.inTemplateString = @"true";
        }
        
    } else if ([segue.identifier isEqualToString:@"relaunchPlannerTemplateItem"]) {
        
        HTAddFoodSearchResultsViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        viewController.relaunchItemID = [[self.plannerItemID objectAtIndex:self.selectedFoodID] integerValue];
        viewController.addFoodCategory = @"template";
        
    } else if ([segue.identifier isEqualToString:@"relaunchActivityItem"]) {
        
        HTAddActivitySelectItemViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        viewController.selectedActivityID = [[self.plannerItemID objectAtIndex:self.selectedFoodID] integerValue];
        viewController.relaunchPlannerItem = YES;
        
        if (![[self.plannerItemMove objectAtIndex:self.selectedFoodID] isEqualToString:@""]) {
            
            viewController.addActivityCategory = @"exercise";
            
        } else if (![[self.plannerItemBalance objectAtIndex:self.selectedFoodID] isEqualToString:@""]) {
            
            viewController.addActivityCategory = @"stress";
            
        } else {
            
            viewController.addActivityCategory = @"note";
        }
        
    } else {
        
        UIViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end