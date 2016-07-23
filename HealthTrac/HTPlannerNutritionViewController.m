//
//  HTPlannerNutritionViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTPlannerNutritionViewController.h"
#import "HTAppDelegate.h"
#import "HTTextField.h"
#import "UIView+Toast.h"
#import "HTLoginViewController.h"

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTPlannerNutritionViewController

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
    
    self.doneUpdatingTargetCalories = NO;
    
    [self getNutrition:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getNutrition:(NSString *) url withState:(BOOL) urlState {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneUpdatingTargetCalories = NO;
    
    self.plannerName = @"";
    self.plannerCalories = @"";
    self.plannerProtein = @"";
    self.plannerCarbs = @"";
    self.plannerFiber = @"";
    self.plannerSugar = @"";
    self.plannerSodium = @"";
    self.plannerFat = @"";
    self.plannerSatFat = @"";
    self.plannerCaloriesBurned = @"";
    self.plannerTargetCalories = @"";
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.title = @"Today";
        
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.title = @"Yesterday";
        
    }
    else {
        
        self.title = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    }
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=get_planner_nutrition&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneUpdatingTargetCalories = YES;
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=update_planner_target_calories&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&plan_calories=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.plannerTargetCalories];
    
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

- (void)showNutrition {
    
    NSArray *viewsToRemove = [self.plannerNutritionScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;

    NSInteger vPos = -64;
    NSInteger nutritionLabelPos = 0;

    UIView *plannerNutritionView;
    UIView *plannerNutritionViewTwo;
    UIView *plannerNutritionViewThree;
    UIView *graySeparator;

    UILabel *plannerNutritionLabel;

    UIFont *planNameFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    UIFont *nutritionLabelFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:11.0];
    UIFont *nutritionSubLabelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:11.0];
    UIFont *nutritionValueFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];

    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    [self.plannerNutritionScrollView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];

    // nutritional info - calories
    
    if (![self.plannerName isEqualToString:@""]) {
        
        plannerNutritionView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 60)];
        
        [plannerNutritionView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
        
        UILabel *planNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, screenWidth - 32, 60)];
        
        [planNameLabel setFont:planNameFont];
        [planNameLabel setTextColor:grayFontColor];
        [planNameLabel setTextAlignment:NSTextAlignmentCenter];
        
        planNameLabel.text = self.plannerName;
            
        [plannerNutritionView addSubview:planNameLabel];
        
        [self.plannerNutritionScrollView addSubview:plannerNutritionView];
        
        vPos += 60;
        
    } else {
        
        vPos += 20;
    }
    
    // all calorie totals
    
    UIView *calorieTotalsView;
    
    float calorieTotalsViewWidth;
    
    calorieTotalsViewWidth = ((screenWidth - 32) / 4.0);
    
    plannerNutritionView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 60)];
    
    [plannerNutritionView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    // calories goal
    
    calorieTotalsView = [[UIView alloc] initWithFrame:CGRectMake(16, 0, calorieTotalsViewWidth, 60)];
    
    [calorieTotalsView setBackgroundColor:[UIColor whiteColor]];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, calorieTotalsViewWidth, 20)];
    
    [plannerNutritionLabel setFont:nutritionValueFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = @"Goal";
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    self.targetCaloriesButton = [[UIButton alloc] initWithFrame:CGRectMake(4, 26, (calorieTotalsViewWidth - 9), 26)];
    
    [self.targetCaloriesButton.layer setCornerRadius:2.5f];
    [self.targetCaloriesButton.layer setBorderWidth:0.7];
    [self.targetCaloriesButton.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                 green:(200/255.0)
                                                                  blue:(204/255.0)
                                                                 alpha:1.0].CGColor];
    
    [self.targetCaloriesButton setTitleEdgeInsets:UIEdgeInsetsMake(0.5f, 0.0f, 0.0f, 0.0f)];
    
    self.targetCaloriesButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:21.0];
    
    [self.targetCaloriesButton setTitleColor:grayFontColor forState:UIControlStateNormal];
    [self.targetCaloriesButton setTitle:self.plannerTargetCalories forState:UIControlStateNormal];
    [self.targetCaloriesButton addTarget:self action:@selector(targetCaloriesButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [calorieTotalsView addSubview:self.targetCaloriesButton];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake((calorieTotalsViewWidth - 1), 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    [plannerNutritionView addSubview:calorieTotalsView];
    
    // calories consumed
    
    calorieTotalsView = [[UIView alloc] initWithFrame:CGRectMake((16 + calorieTotalsViewWidth), 0, calorieTotalsViewWidth, 60)];
    
    [calorieTotalsView setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, calorieTotalsViewWidth, 20)];
    
    [plannerNutritionLabel setFont:nutritionValueFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = @"Consumed";
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, calorieTotalsViewWidth, 26)];
    
    [plannerNutritionLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:21.0]];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = self.plannerCalories;
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake((calorieTotalsViewWidth - 1), 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    [plannerNutritionView addSubview:calorieTotalsView];
    
    // calories burned
    
    calorieTotalsView = [[UIView alloc] initWithFrame:CGRectMake((16 + (calorieTotalsViewWidth * 2.0)), 0, calorieTotalsViewWidth, 60)];
    
    [calorieTotalsView setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, calorieTotalsViewWidth, 20)];
    
    [plannerNutritionLabel setFont:nutritionValueFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = @"Burned";
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, calorieTotalsViewWidth, 26)];
    
    [plannerNutritionLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:21.0]];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = self.plannerCaloriesBurned;
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake((calorieTotalsViewWidth - 1), 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    [plannerNutritionView addSubview:calorieTotalsView];
    
    // calories remaining
    
    calorieTotalsView = [[UIView alloc] initWithFrame:CGRectMake((16 + (calorieTotalsViewWidth * 3.0)), 0, calorieTotalsViewWidth, 60)];
    
    [calorieTotalsView setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 11, 1, 38)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0];
    
    [calorieTotalsView addSubview:graySeparator];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 6, calorieTotalsViewWidth, 20)];
    
    [plannerNutritionLabel setFont:nutritionValueFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    plannerNutritionLabel.text = @"Remaining";
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, calorieTotalsViewWidth, 26)];
    
    [plannerNutritionLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:21.0]];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentCenter];
    
    NSInteger caloriesRemaining = ([self.plannerTargetCalories integerValue]
                                   - ([self.plannerCalories integerValue] - [self.plannerCaloriesBurned integerValue]));
    
    plannerNutritionLabel.text = [NSString stringWithFormat:@"%ld", (long)caloriesRemaining];
    
    [calorieTotalsView addSubview:plannerNutritionLabel];
    
    [plannerNutritionView addSubview:calorieTotalsView];
    
    [self.plannerNutritionScrollView addSubview:plannerNutritionView];
    
    vPos += 60;
    
    plannerNutritionView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 268)];
    
    [plannerNutritionView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 18, ((screenWidth - 32) / 2), 16)];
    
    [plannerNutritionLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:12.0]];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:@"DAILY NUTRITION SUMMARY"];
    
    [plannerNutritionView addSubview:plannerNutritionLabel];
    
    plannerNutritionViewTwo = [[UIView alloc] initWithFrame:CGRectMake(16, 38, (screenWidth - 32), 3)];
    
    [plannerNutritionViewTwo setBackgroundColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
    
    [plannerNutritionView addSubview:plannerNutritionViewTwo];
    
    plannerNutritionViewThree = [[UIView alloc] initWithFrame:CGRectMake(16, 41, (screenWidth - 32), 211)];
    
    [plannerNutritionViewThree setBackgroundColor:[UIColor whiteColor]];
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, ((screenWidth - 64) / 2), 20)];
    
    [plannerNutritionLabel setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:@"Calories"];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerCaloriesLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2), 10, (((screenWidth - 64) / 2) - 16), 20)];
    
    [self.plannerCaloriesLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:21.0]];
    [self.plannerCaloriesLabel setTextColor:grayFontColor];
    [self.plannerCaloriesLabel setTextAlignment:NSTextAlignmentRight];
    
    [self.plannerCaloriesLabel setText:self.plannerCalories];
    
    [plannerNutritionViewThree addSubview:self.plannerCaloriesLabel];
    
    NSMutableAttributedString *nutritionValueStr;
    
    // carbs
    
    nutritionLabelPos = 41;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [plannerNutritionLabel setFont:nutritionLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Carbs", @"   "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerCarbsLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerCarbsLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.plannerCarbsLabel setFont:nutritionValueFont];
    [self.plannerCarbsLabel setTextColor:grayFontColor];
    [self.plannerCarbsLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerCarbs, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerCarbsLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerCarbsLabel];
    
    // fiber
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor whiteColor]];
    
    [plannerNutritionLabel setFont:nutritionSubLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Fiber", @"      "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerFiberLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerFiberLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.plannerFiberLabel setFont:nutritionValueFont];
    [self.plannerFiberLabel setTextColor:grayFontColor];
    [self.plannerFiberLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerFiber, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerFiberLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerFiberLabel];
    
    // sugars
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [plannerNutritionLabel setFont:nutritionSubLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Sugars", @"      "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerSugarLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerSugarLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.plannerSugarLabel setFont:nutritionValueFont];
    [self.plannerSugarLabel setTextColor:grayFontColor];
    [self.plannerSugarLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerSugar, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerSugarLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerSugarLabel];
    
    // protein
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor whiteColor]];
    
    [plannerNutritionLabel setFont:nutritionLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Protein", @"   "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerProteinLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerProteinLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.plannerProteinLabel setFont:nutritionValueFont];
    [self.plannerProteinLabel setTextColor:grayFontColor];
    [self.plannerProteinLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerProtein, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerProteinLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerProteinLabel];
    
    // total fat
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [plannerNutritionLabel setFont:nutritionLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Total Fat", @"   "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerFatLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerFatLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.plannerFatLabel setFont:nutritionValueFont];
    [self.plannerFatLabel setTextColor:grayFontColor];
    [self.plannerFatLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerFat, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerFatLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerFatLabel];
    
    // sat fat
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor whiteColor]];
    
    [plannerNutritionLabel setFont:nutritionSubLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Sat. Fat", @"      "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerSatFatLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerSatFatLabel setBackgroundColor:[UIColor whiteColor]];
    
    [self.plannerSatFatLabel setFont:nutritionValueFont];
    [self.plannerSatFatLabel setTextColor:grayFontColor];
    [self.plannerSatFatLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@g%@", self.plannerSatFat, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor whiteColor]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerSatFatLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerSatFatLabel];
    
    // sodium
    
    nutritionLabelPos += 22;
    
    plannerNutritionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [plannerNutritionLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [plannerNutritionLabel setFont:nutritionLabelFont];
    [plannerNutritionLabel setTextColor:grayFontColor];
    [plannerNutritionLabel setTextAlignment:NSTextAlignmentLeft];
    [plannerNutritionLabel setText:[NSString stringWithFormat:@"%@Sodium", @"   "]];
    
    [plannerNutritionViewThree addSubview:plannerNutritionLabel];
    
    self.plannerSodiumLabel = [[UILabel alloc] initWithFrame:CGRectMake(((screenWidth / 2) - 16), nutritionLabelPos, ((screenWidth - 64) / 2), 22)];
    
    [self.plannerSodiumLabel setBackgroundColor:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]];
    
    [self.plannerSodiumLabel setFont:nutritionValueFont];
    [self.plannerSodiumLabel setTextColor:grayFontColor];
    [self.plannerSodiumLabel setTextAlignment:NSTextAlignmentRight];
    
    nutritionValueStr = [[NSMutableAttributedString alloc]
                         initWithString:[NSString stringWithFormat:@"%@mg%@", self.plannerSodium, @"..."]];
    
    [nutritionValueStr addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithRed:(242/255.0) green:(246/255.0) blue:(247/255.0) alpha:1.0]
                              range:NSMakeRange([nutritionValueStr length] - 3, 3)];
    
    [self.plannerSodiumLabel setAttributedText:nutritionValueStr];
    
    [plannerNutritionViewThree addSubview:self.plannerSodiumLabel];
    
    [plannerNutritionView addSubview:plannerNutritionViewThree];
    
    [self.plannerNutritionScrollView addSubview:plannerNutritionView];
    
    vPos += 268;
    
    [self.plannerNutritionScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
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

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)targetCaloriesButtonPressed {
    
    self.targetCaloriesAlertView = [[UIAlertView alloc] initWithTitle:@"Update calories goal?" message:@"Enter a new calories goal" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    
    self.targetCaloriesAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    self.targetCaloriesAlertView.tag = 1;
    
    self.alertViewCaloriesTextField = [self.targetCaloriesAlertView textFieldAtIndex:0];
    
    [self.alertViewCaloriesTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    
    self.alertViewCaloriesTextField.delegate = self;
    self.alertViewCaloriesTextField.tag = 2;
    self.alertViewCaloriesTextField.text = self.plannerTargetCalories;
    
    [self.targetCaloriesAlertView show];
}

#pragma mark - UITextField delegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField.text.length >= 4 && range.length == 0) { //  4 character max

        return NO;
        
    } else {

        return YES;
    }
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == 1 && buttonIndex == 1) {
        
        self.plannerTargetCalories = [[[alertView textFieldAtIndex:0] text]
                                  stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceCharacterSet]];
        
        [self updatePlannerTargetCalories:HTWebSvcURL withState:0];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    
    if ([[[[alertView textFieldAtIndex:0] text]
          stringByTrimmingCharactersInSet:
          [NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        
        return NO;
        
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
    
    self.plannerName = @"";
    self.plannerCalories = @"";
    self.plannerProtein = @"";
    self.plannerCarbs = @"";
    self.plannerFiber = @"";
    self.plannerSugar = @"";
    self.plannerSodium = @"";
    self.plannerFat = @"";
    self.plannerSatFat = @"";
    self.plannerCaloriesBurned = @"";
    self.plannerTargetCalories = @"";
//    self.plannerServings = @"";
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
        
    } else if ([elementName isEqualToString:@"planner_name"]) {
        
        self.plannerName = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_calories"]) {
        
        self.plannerCalories = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_protein"]) {
        
        self.plannerProtein = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_carbs"]) {
        
        self.plannerCarbs = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_fiber"]) {
        
        self.plannerFiber = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_sugar"]) {
        
        self.plannerSugar = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_sodium"]) {
        
        self.plannerSodium = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_fat"]) {
        
        self.plannerFat = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_sat_fat"]) {
        
        self.plannerSatFat = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_target_calories"]) {
        
        self.plannerTargetCalories = cleanString;
        
    } else if ([elementName isEqualToString:@"planner_calories_burned"]) {
        
        self.plannerCaloriesBurned = cleanString;
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
        
        if (self.doneUpdatingTargetCalories == YES) {
            
            [self getNutrition:HTWebSvcURL withState:0];
            
        } else {
            
            [self showNutrition];
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
