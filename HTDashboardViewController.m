//
//  HTDashboardViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 9/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTDashboardViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "HTTableViewCellController.h"
#import "UIView+Toast.h"
#import "JSBadgeView.h"

@interface HTDashboardViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTDashboardViewController

#pragma mark - View lifecycle

- (void)loadView {
    
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
    
    [super loadView];
    
    self.customMetrics = [[NSMutableArray alloc] init];
    self.customMetricsTypes = [[NSMutableArray alloc] init];
    self.customMetricsLabels = [[NSMutableArray alloc] init];
    self.customMetricsGoals = [[NSMutableArray alloc] init];
    self.customMetricsOfficial = [[NSMutableArray alloc] init];
    
    int screenWidth = self.view.frame.size.width;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2) - 50, 0, 100, 40)];
    
    [titleLabel setFont:[UIFont fontWithName:@"Omnes-Light" size:23.0]];
    [titleLabel setTextColor:[UIColor colorWithRed:(59/255.0)
                                             green:(183/255.0)
                                              blue:(234/255.0)
                                             alpha:1.0]];
    
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    NSMutableAttributedString *titleLabelString;
    
    titleLabelString = [[NSMutableAttributedString alloc]
                    initWithString:@"HealthTrac"];

    [titleLabelString addAttribute:NSFontAttributeName
                      value:[UIFont fontWithName:@"Omnes-Medium" size:23.0]
                      range:NSMakeRange([titleLabelString length] -4, 4)];

     titleLabel.attributedText = titleLabelString;
    
    self.navigationItem.titleView = titleLabel;
    
    self.newLearningModules = 0;
    self.newEatingPlans = 0;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];

    self.dashboardItems = [NSMutableArray array];
    self.dashboardItemValues = [NSMutableArray array];
    self.dashboardUserSort = [NSMutableArray array];
    
    self.dashboardObject = [[NSObject alloc] init];
    
    self.dashboardUserPrefs = [[NSMutableDictionary alloc] init];
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
    
    // set up custom tab bar icons and titles
    
    NSArray *items;
    
    UITabBarItem *itemDashboard;
    UITabBarItem *itemTracker;
    UITabBarItem *itemPlanner;
    UITabBarItem *itemLearn;
    UITabBarItem *itemMore;
    
    // hidePlanner?
    
    if (appDelegate.hidePlanner == YES) {
        
        NSMutableArray *tabBarViewControllers = [NSMutableArray arrayWithArray:
                                                 [self.tabBarController viewControllers]];
        
        if ([tabBarViewControllers count] == 5) {
            
            [tabBarViewControllers removeObjectAtIndex:2];
            
            [self.tabBarController setViewControllers:tabBarViewControllers];
        }
    }
    
    items = self.tabBarController.tabBar.items;
    
    if (appDelegate.hidePlanner == YES) {
        
        itemDashboard = [items objectAtIndex:0];
        itemTracker = [items objectAtIndex:1];
        itemLearn = [items objectAtIndex:2];
        itemMore = [items objectAtIndex:3];
        
    } else {
        
        itemDashboard = [items objectAtIndex:0];
        itemTracker = [items objectAtIndex:1];
        itemPlanner = [items objectAtIndex:2];
        itemLearn = [items objectAtIndex:3];
        itemMore = [items objectAtIndex:4];
    }
    
    itemDashboard.image = [[UIImage imageNamed:@"ht-tabbar-dashboard-default"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemDashboard.selectedImage = [[UIImage imageNamed:@"ht-tabbar-dashboard-selected"]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemDashboard.title = @"DASHBOARD";
    
    itemTracker.image = [[UIImage imageNamed:@"ht-tabbar-track-default"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemTracker.selectedImage = [[UIImage imageNamed:@"ht-tabbar-track-selected"]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemTracker.title = @"TRACK";
    
    if (appDelegate.hidePlanner == NO) {
    
        itemPlanner.image = [[UIImage imageNamed:@"ht-tabbar-plan-default"]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        itemPlanner.selectedImage = [[UIImage imageNamed:@"ht-tabbar-plan-selected"]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        itemPlanner.title = @"PLAN";
    }
    
    itemLearn.image = [[UIImage imageNamed:@"ht-tabbar-learn-default"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemLearn.selectedImage = [[UIImage imageNamed:@"ht-tabbar-learn-selected"]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemLearn.title = @"LEARN";
    
    itemMore.image = [[UIImage imageNamed:@"ht-tabbar-more-default"]
                   imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemMore.selectedImage = [[UIImage imageNamed:@"ht-tabbar-more-selected"]
                           imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    itemMore.title = @"MORE";
    
    [super viewWillAppear:animated];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *userPrefsString;

    userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserSort"];
    
    self.dashboardUserSort = [NSMutableArray
                              arrayWithArray:[prefs objectForKey:userPrefsString]];
    
    userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
    
    self.dashboardUserPrefs = [NSMutableDictionary
                               dictionaryWithDictionary:[prefs objectForKey:userPrefsString]];
    
    [self getDashboard:HTWebSvcURL withState:0];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.dashboardItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    HTTableViewCellController *cell;
    
    NSNumber *calcNumberOne;
    NSNumber *calcNumberTwo;
    NSNumber *calcNumberThree;
    NSNumber *calcNumberFour = [[NSNumber alloc] initWithInt:500];
   
    NSString *calcNumberFive;
    
    NSMutableAttributedString *textLabelStr;
        
    cell = [[HTTableViewCellController alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    NSString *cellTextLabel = (NSString *)[self.dashboardItems objectAtIndex:(indexPath.row)];
    
    UIView *graySeparator;
    
    cell.textLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:26.0];
    cell.textLabel.textColor = [UIColor colorWithRed:(114/255.0)
                                               green:(126/255.0)
                                                blue:(133/255.0)
                                               alpha:1.0];
    
    if ([cellTextLabel isEqualToString:@"calories"]) { // these are handled a little differently than the rest
        
        calcNumberOne = [self getNumberFromString:self.calories];
        calcNumberTwo = [self getNumberFromString:self.caloriesGoal];
        calcNumberThree = [self getNumberFromString:self.caloriesBurned];
        calcNumberThree =  @([calcNumberOne floatValue] / ([calcNumberTwo floatValue] + [calcNumberThree floatValue]));
        calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
        
        cell.imageView.image = [UIImage imageNamed:@"ht-dash-calories-consumed"];
        
        textLabelStr = [[NSMutableAttributedString alloc]
                        initWithString:[NSString stringWithFormat:@"%@ %@",
                                        [self getFormattedStringFromFloat:[self.calories doubleValue]],
                                        @"calories consumed"]];
                        
        [textLabelStr addAttribute:NSFontAttributeName
                             value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                             range:NSMakeRange([textLabelStr length] - 17, 17)];
        
        cell.textLabel.attributedText = textLabelStr;
        
        if (![self.caloriesGoal isEqualToString:@""]) {
            
            [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
            
            if ([calcNumberThree floatValue] > 500) {
                
                // red progress bar
                cell.detailTextLabel.textColor = [UIColor colorWithRed:(241/255.0) green:(106/255.0) blue:(114/255.0) alpha:1.0];

            } else {
                // green progress bar
                cell.detailTextLabel.textColor = [UIColor colorWithRed:(182/255.0) green:(223/255.0) blue:(59/255.0) alpha:1.0];
            }
        }
        
    } else { // NOT calories, everything else
        
        // green progress bar
        
        cell.detailTextLabel.textColor = [UIColor colorWithRed:(182/255.0) green:(223/255.0) blue:(59/255.0) alpha:1.0];
        
        if ([cellTextLabel isEqualToString:@"calories_goal"] && ![self.caloriesGoal isEqualToString:@""]) {
            
            calcNumberOne = [self getNumberFromString:self.calories];
            calcNumberTwo = [self getNumberFromString:self.caloriesGoal];
            calcNumberThree = [self getNumberFromString:self.caloriesBurned];
            calcNumberFive = [self getFormattedStringFromFloat:(([calcNumberThree doubleValue] + [calcNumberTwo doubleValue]) - [calcNumberOne doubleValue])];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-calories-remaining"];
            
            textLabelStr = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@ %@",
                                            calcNumberFive,
                                            @"calories remaining"]];
            
            [textLabelStr addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                 range:NSMakeRange([textLabelStr length] - 18, 18)];
            
            cell.textLabel.attributedText = textLabelStr;
            cell.detailTextLabel.text = @"";
            
        } else if ([cellTextLabel isEqualToString:@"weight"]) {
            
            calcNumberOne = [self getNumberFromString:self.weight];
            calcNumberTwo = [self getNumberFromString:self.weightGoal];
            calcNumberThree = [self getNumberFromString:self.weightStarting];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-weight"];
            
            // if current weight > starting weight
            if (([calcNumberOne doubleValue] > [calcNumberThree doubleValue])) {
                
                calcNumberFive = [self getFormattedStringFromFloat:([calcNumberOne doubleValue] - [calcNumberThree doubleValue])];

                textLabelStr = [[NSMutableAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%@ %@",
                                                calcNumberFive,
                                                @"lbs gained"]];
                
                [textLabelStr addAttribute:NSFontAttributeName
                                     value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                     range:NSMakeRange([textLabelStr length] - 10, 10)];
                
                cell.textLabel.attributedText = textLabelStr;
                cell.detailTextLabel.text = @" ";
                
            } else { // you've lost weight - good job.  :)
                
                calcNumberFive = [self getFormattedStringFromFloat:([calcNumberThree doubleValue] - [calcNumberOne doubleValue])];
                
                textLabelStr = [[NSMutableAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%@ %@",
                                                calcNumberFive,
                                                @"lbs lost"]];
                
                [textLabelStr addAttribute:NSFontAttributeName
                                     value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                     range:NSMakeRange([textLabelStr length] - 8, 8)];
                
                cell.textLabel.attributedText = textLabelStr;

                if (![self.weightGoal isEqualToString:@""]) {
                    
                    calcNumberThree =  @((([calcNumberThree floatValue] - [calcNumberOne floatValue]) / ([calcNumberThree floatValue] - [calcNumberTwo floatValue])));
                    calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
                    
                    [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
                }
            }
            
        } else if ([cellTextLabel isEqualToString:@"weight_goal"] && ![self.weightGoal isEqualToString:@""]) {
            
            calcNumberOne = [self getNumberFromString:self.weight];
            calcNumberTwo = [self getNumberFromString:self.weightGoal];
            calcNumberFive = [self getFormattedStringFromFloat:([calcNumberOne doubleValue] - [calcNumberTwo doubleValue])];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-weight-remaining"];
            
            textLabelStr = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@ %@",
                                            calcNumberFive,
                                            @"lbs to go"]];
            
            [textLabelStr addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                 range:NSMakeRange([textLabelStr length] - 9, 9)];
            
            cell.textLabel.attributedText = textLabelStr;
            cell.detailTextLabel.text = @"";
            
        } else if ([cellTextLabel isEqualToString:@"Walking Steps"]) {
            
            calcNumberOne = [self getNumberFromString:self.walkingSteps];
            calcNumberTwo = [self getNumberFromString:self.walkingStepsGoal];
            calcNumberThree =  @([calcNumberOne floatValue] / [calcNumberTwo floatValue]);
            calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
            calcNumberFive = [self getFormattedStringFromFloat:[calcNumberOne floatValue]];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-steps"];
            
            textLabelStr = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@ %@",
                                            calcNumberFive,
                                            [self.dashboardItems objectAtIndex:(indexPath.row)]]];
            
            [textLabelStr addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                 range:NSMakeRange([textLabelStr length] -
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length],
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length])];
            
            cell.textLabel.attributedText = textLabelStr;
            
            if (![self.walkingStepsGoal isEqualToString:@""]) {
                
                if ([self.walkingSteps isEqualToString:@"0"]) {
                    
                    cell.detailTextLabel.text = @" ";
                    
                } else {
                    
                    [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
                }
                
            } else {
                
                cell.detailTextLabel.text = @"";
            }
            
        } else if ([cellTextLabel isEqualToString:@"Exercise Minutes"]) {

            calcNumberOne = [self getNumberFromString:self.exerciseMinutes];
            calcNumberTwo = [self getNumberFromString:self.exerciseMinutesGoal];
            calcNumberThree =  @([calcNumberOne floatValue] / [calcNumberTwo floatValue]);
            calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
            calcNumberFive = [self getFormattedStringFromFloat:[calcNumberOne floatValue]];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-minutes"];
            
            textLabelStr = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@ %@",
                                            calcNumberFive,
                                            [self.dashboardItems objectAtIndex:(indexPath.row)]]];
            
            [textLabelStr addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                 range:NSMakeRange([textLabelStr length] -
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length],
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length])];
            
            cell.textLabel.attributedText = textLabelStr;
            
            if (![self.exerciseMinutesGoal isEqualToString:@""]) {
                
                if ([self.exerciseMinutes isEqualToString:@"0"]) {
                    
                    cell.detailTextLabel.text = @" ";
                    
                } else {
                    
                    [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
                }
                
            } else {
                
                cell.detailTextLabel.text = @"";
            }
            
        } else if ([cellTextLabel isEqualToString:@"Sleep Hours"]) {
            
            calcNumberOne = [self getNumberFromString:self.sleepHours];
            calcNumberTwo = [self getNumberFromString:self.sleepHoursGoal];
            calcNumberThree =  @([calcNumberOne floatValue] / [calcNumberTwo floatValue]);
            calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
            calcNumberFive = [self getFormattedStringFromFloat:[calcNumberOne floatValue]];
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-sleep"];
            
            textLabelStr = [[NSMutableAttributedString alloc]
                            initWithString:[NSString stringWithFormat:@"%@ %@",
                                            calcNumberFive,
                                            [self.dashboardItems objectAtIndex:(indexPath.row)]]];
            
            [textLabelStr addAttribute:NSFontAttributeName
                                 value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                 range:NSMakeRange([textLabelStr length] -
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length],
                                                   [[self.dashboardItems objectAtIndex:(indexPath.row)] length])];
            
            cell.textLabel.attributedText = textLabelStr;
            
            if (![self.sleepHoursGoal isEqualToString:@""]) {
                
                if ([self.sleepHours isEqualToString:@"0"]) {
                    
                    cell.detailTextLabel.text = @" ";
                    
                } else {
                    
                    [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
                }
                
            } else {
                
                cell.detailTextLabel.text = @"";
            }
            
        } else if ([cellTextLabel isEqualToString:@"Inbox"]) {
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-inbox"];
            
            if ([self.numberOfMessages isEqualToString:@"0"]) { // no new messages
                
                textLabelStr = [[NSMutableAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%@", @"Inbox"]];
                
                [textLabelStr addAttribute:NSFontAttributeName
                                     value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                     range:NSMakeRange(0, 5)];
                
                cell.textLabel.attributedText = textLabelStr;
                
                cell.detailTextLabel.text = @"";
                
            } else {
                
                if ([self.numberOfMessages isEqualToString:@"1"]) {
                    
                    textLabelStr = [[NSMutableAttributedString alloc]
                                    initWithString:[NSString stringWithFormat:@"%@ %@",
                                                    self.numberOfMessages,
                                                    @"new message"]];
                    
                    [textLabelStr addAttribute:NSFontAttributeName
                                         value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                         range:NSMakeRange([textLabelStr length] - 11, 11)];
                    
                    cell.textLabel.attributedText = textLabelStr;
                    
                } else {
                    
                    textLabelStr = [[NSMutableAttributedString alloc]
                                    initWithString:[NSString stringWithFormat:@"%@ %@",
                                                    self.numberOfMessages,
                                                    @"new messages"]];
                    
                    [textLabelStr addAttribute:NSFontAttributeName
                                         value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                         range:NSMakeRange([textLabelStr length] - 12, 12)];
                    
                    cell.textLabel.attributedText = textLabelStr;
                }
                
                cell.detailTextLabel.text = @"";
                
                JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:cell.imageView
                                                                       alignment:JSBadgeViewAlignmentTopRight];
                badgeView.badgeText = self.numberOfMessages;
            }
        }
        
        // custom metrics
        else {
            
            cell.imageView.image = [UIImage imageNamed:@"ht-dash-metrics"];
            
            if ([[self.dashboardItemValues objectAtIndex:(indexPath.row)] isEqualToString:@""]) { // checkboxes
                
                textLabelStr = [[NSMutableAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%@",
                                                [self.dashboardItems objectAtIndex:(indexPath.row)]]];
                
                [textLabelStr addAttribute:NSFontAttributeName
                                     value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                     range:NSMakeRange(0, [textLabelStr length])];
                
                cell.textLabel.attributedText = textLabelStr;
                
                // loop through custom metrics to see if this checkbox was checked
                for (int i = 1; i <= 10; i++) {
                    
                    if ([[self.customMetricsLabels objectAtIndex:i] length] != 0) {
                        
                        if ([[self.customMetricsLabels objectAtIndex:i] isEqualToString:[self.dashboardItems objectAtIndex:(indexPath.row)]]) {
                            
                            if ([[self.customMetrics objectAtIndex:i] isEqualToString:@"1"]) {
                                
                                [cell.detailTextLabel setAttributedText:[self getProgressBar:500]];
                                
                            } else {
                                
                                cell.detailTextLabel.text = @"";
                            }
                        }
                    }
                }
                
            } else {
                
                calcNumberOne = [self.dashboardItemValues objectAtIndex:(indexPath.row)];
                calcNumberFive = [self getFormattedStringFromFloat:[calcNumberOne floatValue]];
                
                textLabelStr = [[NSMutableAttributedString alloc]
                                initWithString:[NSString stringWithFormat:@"%@ %@",
                                                calcNumberFive,
                                                [self.dashboardItems objectAtIndex:(indexPath.row)]]];
                
                [textLabelStr addAttribute:NSFontAttributeName
                                     value:[UIFont fontWithName:@"AvenirNext-Regular" size:15]
                                     range:NSMakeRange([textLabelStr length] -
                                                       [[self.dashboardItems objectAtIndex:(indexPath.row)] length],
                                                       [[self.dashboardItems objectAtIndex:(indexPath.row)] length])];
                
                cell.textLabel.attributedText = textLabelStr;
                
                // loop through custom metrics to see if there is a goal  for this metric
                for (int i = 1; i <= 10; i++) {
                    
                    if ([[self.customMetricsLabels objectAtIndex:i] length] != 0) {
                        
                        if ([[self.customMetricsLabels objectAtIndex:i] isEqualToString:[self.dashboardItems objectAtIndex:(indexPath.row)]]) {
                            
                            if (![[self.customMetricsGoals objectAtIndex:i] isEqualToString:@""]) {
                                
                                calcNumberOne = [self getNumberFromString:[self.customMetrics objectAtIndex:i]];
                                calcNumberTwo = [self getNumberFromString:[self.customMetricsGoals objectAtIndex:i]];
                                calcNumberThree =  @([calcNumberOne floatValue] / [calcNumberTwo floatValue]);
                                calcNumberThree =  @([calcNumberThree floatValue] * [calcNumberFour floatValue]);
                                
                                [cell.detailTextLabel setAttributedText:[self getProgressBar:[calcNumberThree floatValue]]];
                                
                            } else {
                                
                                cell.detailTextLabel.text = @"";
                            }
                        }
                    }
                }
            }
        }
    }
    
    int screenWidth = self.view.frame.size.width;
    int separatorOffset = cell.frame.size.height + 28;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, separatorOffset, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [cell addSubview:graySeparator];
    
    // these keep the separator bar from slightly disappearing when a call is selected, then de-selected
    cell.clipsToBounds = NO;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([[self.dashboardItems objectAtIndex:indexPath.row] isEqualToString:@"Inbox"]) {
        
        [self performSegueWithIdentifier:@"showInboxFromDashboard" sender:self];
        
    } else if ([[self.dashboardItems objectAtIndex:indexPath.row] isEqualToString:@"calories"] ||
               [[self.dashboardItems objectAtIndex:indexPath.row] isEqualToString:@"calories_goal"]) {
        
        self.tabBarController.selectedIndex = 2;
        
    } else {
    
        [self performSegueWithIdentifier:@"showActivityFromDashboard" sender:self];
    }
}

#pragma mark - Methods

- (void)getDashboard:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.newLearningModules = 0;
    self.newEatingPlans = 0;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_dashboard&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    
    } else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    
    } else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
}

- (NSNumber *) getNumberFromString:(NSString *) string {
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSNumber *currentCalcValue = [numberFormatter numberFromString:string];
    
    return currentCalcValue;
}

- (NSString *) getFormattedStringFromFloat:(float) number {
    
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

-(NSMutableAttributedString *)getProgressBar:(float)number {
    
    NSMutableAttributedString *progressBlock;
    NSMutableAttributedString *progressString;
    
    const UniChar asciiCode = 0x2022;
    float spacing = -4.0f;
    
    progressBlock = [[NSMutableAttributedString alloc] initWithString:[NSMutableString stringWithFormat:@"%C", asciiCode]];
    progressString = [[NSMutableAttributedString alloc] initWithString:[NSMutableString stringWithFormat:@"%C", asciiCode]];
    
    if (number > 500) {
        
        number = 500;
    }
    
    for (int i = 1; i < number; i++) {
        
        [progressString appendAttributedString:progressBlock];
        
    }
    
    [progressString addAttribute:NSKernAttributeName value:@(spacing) range:NSMakeRange(0, [progressString length])];
    
    return progressString;
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
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    self.calories = nil;
    self.caloriesGoal = nil;
    self.caloriesBurned = nil;
    self.weight = nil;
    self.weightStarting = nil;
    self.weightGoal = nil;
    self.weightOfficial = nil;
    self.walkingSteps = nil;
    self.walkingStepsGoal = nil;
    self.walkingStepsOfficial = nil;
    self.exerciseMinutes = nil;
    self.exerciseMinutesGoal = nil;
    self.exerciseMinutesOfficial = nil;
    self.sleepHours = nil;
    self.sleepHoursGoal = nil;
    self.sleepHoursOfficial = nil;
    self.numberOfMessages = nil;
    
    self.showMessages = NO;
    
    [self.customMetrics removeAllObjects];
    [self.customMetricsTypes removeAllObjects];
    [self.customMetricsLabels removeAllObjects];
    [self.customMetricsGoals removeAllObjects];
    [self.customMetricsOfficial removeAllObjects];
    
    [self.customMetrics insertObject:@"" atIndex:0];
    [self.customMetricsTypes insertObject:@"" atIndex:0];
    [self.customMetricsLabels insertObject:@"" atIndex:0];
    [self.customMetricsGoals insertObject:@"" atIndex:0];
    [self.customMetricsOfficial insertObject:@"" atIndex:0];
    
    [self.dashboardItems removeAllObjects];
    [self.dashboardItemValues removeAllObjects];
    
    [appDelegate.dashboardEditItems removeAllObjects];
    
    self.dashboardObject = nil;
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
   
    if ([elementName isEqualToString:@"calories"]) {
        
        [appDelegate.dashboardEditItems addObject:@"calories"];
        
        if (![[self.dashboardUserPrefs objectForKey:@"calories"] isEqualToString:@"0"]) {
            
            self.calories = self.currentValue;
            
            if ([self.calories isEqualToString:@""]) {
                self.calories = @"0";
            }
            
            [self.dashboardItems addObject:@"calories"];
            [self.dashboardItemValues addObject:self.calories];
        }
        
    } else if ([elementName isEqualToString:@"calories_goal"] &&
               ![[self.dashboardUserPrefs objectForKey:@"calories"] isEqualToString:@"0"]) {
        
        self.caloriesGoal = self.currentValue;
        
        [self.dashboardItems addObject:@"calories_goal"];
        [self.dashboardItemValues addObject:self.caloriesGoal];
        
    } else if ([elementName isEqualToString:@"calories_burned"] &&
               ![[self.dashboardUserPrefs objectForKey:@"calories"] isEqualToString:@"0"]) {
        
        self.caloriesBurned = self.currentValue;
        
    } else if ([elementName isEqualToString:@"weight"]) {
        
        [appDelegate.dashboardEditItems addObject:@"weight"];
        
        if (![[self.dashboardUserPrefs objectForKey:@"weight"] isEqualToString:@"0"]) {
            
            self.weight = self.currentValue;
            
            [self.dashboardItems addObject:@"weight"];
            [self.dashboardItemValues addObject:self.weight];
        }
        
    } else if ([elementName isEqualToString:@"weight_starting"] &&
               ![[self.dashboardUserPrefs objectForKey:@"weight"] isEqualToString:@"0"]) {
        
        self.weightStarting = self.currentValue;
        
    } else if ([elementName isEqualToString:@"weight_goal"] &&
               ![[self.dashboardUserPrefs objectForKey:@"weight"] isEqualToString:@"0"]) {
        
        self.weightGoal = self.currentValue;
        
        [self.dashboardItems addObject:@"weight_goal"];
        [self.dashboardItemValues addObject:self.weightGoal];
        
    } else if ([elementName isEqualToString:@"weight_official"] &&
               ![[self.dashboardUserPrefs objectForKey:@"weight"] isEqualToString:@"0"]) {
        
        self.weightOfficial = self.currentValue;
        
    } else if ([elementName isEqualToString:@"walking_steps"]) {
        
        [appDelegate.dashboardEditItems addObject:@"Walking Steps"];
        
        if (![[self.dashboardUserPrefs objectForKey:@"Walking Steps"] isEqualToString:@"0"]) {
            
            self.walkingSteps = self.currentValue;
            
            if ([self.walkingSteps isEqualToString:@""]) {
                self.walkingSteps = @"0";
            }
            
            [self.dashboardItems addObject:@"Walking Steps"];
            [self.dashboardItemValues addObject:self.walkingSteps];
        }
        
    } else if ([elementName isEqualToString:@"walking_steps_goal"] && ![[self.dashboardUserPrefs objectForKey:@"Walking Steps"] isEqualToString:@"0"]) {
        
        self.walkingStepsGoal = self.currentValue;
        
    } else if ([elementName isEqualToString:@"walking_steps_official"] && ![[self.dashboardUserPrefs objectForKey:@"Walking Steps"] isEqualToString:@"0"]) {
        
        self.walkingStepsOfficial = self.currentValue;
        
    } else if ([elementName isEqualToString:@"exercise_minutes"]) {
        
        [appDelegate.dashboardEditItems addObject:@"Exercise Minutes"];
        
        if (![[self.dashboardUserPrefs objectForKey:@"Exercise Minutes"] isEqualToString:@"0"]) {
        
            self.exerciseMinutes = self.currentValue;
            
            if ([self.exerciseMinutes isEqualToString:@""]) {
                self.exerciseMinutes = @"0";
            }
            
            [self.dashboardItems addObject:@"Exercise Minutes"];
            [self.dashboardItemValues addObject:self.exerciseMinutes];
        }
        
    } else if ([elementName isEqualToString:@"exercise_minutes_goal"] && ![[self.dashboardUserPrefs objectForKey:@"Exercise Minutes"] isEqualToString:@"0"]) {
        
        self.exerciseMinutesGoal = self.currentValue;
        
    } else if ([elementName isEqualToString:@"exercise_minutes_official"] && ![[self.dashboardUserPrefs objectForKey:@"Exercise Minutes"] isEqualToString:@"0"]) {
        
        self.exerciseMinutesOfficial = self.currentValue;
        
    } else if ([elementName isEqualToString:@"sleep_hours"]) {
        
        [appDelegate.dashboardEditItems addObject:@"Sleep Hours"];
        
        if (![[self.dashboardUserPrefs objectForKey:@"Sleep Hours"] isEqualToString:@"0"]) {
        
            self.sleepHours = self.currentValue;
            
            if ([self.sleepHours isEqualToString:@""]) {
                self.sleepHours = @"0";
            }
            
            [self.dashboardItems addObject:@"Sleep Hours"];
            [self.dashboardItemValues addObject:self.sleepHours];
        }
        
    } else if ([elementName isEqualToString:@"sleep_hours_goal"] &&
               ![[self.dashboardUserPrefs objectForKey:@"Sleep Hours"] isEqualToString:@"0"]) {
        
        self.sleepHoursGoal = self.currentValue;
        
    } else if ([elementName isEqualToString:@"sleep_hours_official"] && ![[self.dashboardUserPrefs objectForKey:@"Sleep Hours"] isEqualToString:@"0"]) {
        
        self.sleepHoursOfficial = self.currentValue;
        
    } else if ([elementName isEqualToString:@"show_messages"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            [appDelegate.dashboardEditItems addObject:@"Inbox"];
            
            if (![[self.dashboardUserPrefs objectForKey:@"Inbox"] isEqualToString:@"0"]) {
                self.showMessages = YES;
            }
        }
        
    } else if ([elementName isEqualToString:@"new_messages"]) {
        //  && ![[self.dashboardUserPrefs objectForKey:@"Inbox"] isEqualToString:@"0"]
        
        self.numberOfMessages = self.currentValue;
        
    } else if ([elementName isEqualToString:@"new_learning_modules"]) {
        
        self.newLearningModules = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"new_eating_plan"]) {
        
        self.newEatingPlans = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
    }
    
    // custom metrics official
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_official"]) {
        
        [self.customMetricsOfficial insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_official" withString:@""] integerValue]];
    }
    
    // custom metrics labels
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_label"]) {
        
        [self.customMetricsLabels insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_label" withString:@""] integerValue]];
    }
    
    // custom metrics goals
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_goal"]) {
        
        [self.customMetricsGoals insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_goal" withString:@""] integerValue]];
    }
    
    // custom metrics types
    else if ([elementName hasPrefix:@"metric"] && [elementName hasSuffix:@"_type"]) {
        
        [self.customMetricsTypes insertObject:self.currentValue atIndex:[[[elementName stringByReplacingOccurrencesOfString:@"metric" withString:@""] stringByReplacingOccurrencesOfString:@"_type" withString:@""] integerValue]];
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
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSUInteger indexValue;
    NSUInteger indexValueTwo;
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        NSInteger appIconBadgeCount = 0;
        appIconBadgeCount = [self.numberOfMessages integerValue] + self.newLearningModules;
        if (appDelegate.hidePlanner == NO){
            appIconBadgeCount = appIconBadgeCount + self.newEatingPlans;
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:appIconBadgeCount];
        
        // loop through custom metrics looking for valid metrics to display
        for (int i = 1; i <= 10; i++) {
            
            if ([[self.customMetricsLabels objectAtIndex:i] length] != 0) {
                
                [appDelegate.dashboardEditItems addObject:[self.customMetricsLabels objectAtIndex:i]];
                
                if (![[self.dashboardUserPrefs objectForKey:[self.customMetricsLabels objectAtIndex:i]] isEqualToString:@"0"]) {
                    
                    [self.dashboardItems addObject:[self.customMetricsLabels objectAtIndex:i]];
                    
                    // checkbox metrics - don't show the value in the dashboard
                    if ([[self.customMetricsTypes objectAtIndex:i] isEqualToString:@"2"]) {
                        
                        [self.dashboardItemValues addObject:@""];
                        
                    } else {
                        
                        if ([[self.customMetrics objectAtIndex:i] length] == 0) {
                            
                            [self.dashboardItemValues addObject:@"0"];
                            
                        } else {
                            
                            [self.dashboardItemValues addObject:[self.customMetrics objectAtIndex:i]];
                        }
                    }
                }
            }
        }
        
        // Dashboard and More tab bar items - check for badge
        
        NSInteger tabBarItemIndex = 0;
        
        UITabBarItem *itemDashboard = [self.tabBarController.tabBar.items objectAtIndex:tabBarItemIndex];
        
        if (appDelegate.hidePlanner == YES) {
            
            tabBarItemIndex = 3;
            
        } else {
            
            tabBarItemIndex = 4;
        }
        
        UITabBarItem *itemMore = [self.tabBarController.tabBar.items objectAtIndex:tabBarItemIndex];
        
        itemDashboard.badgeValue = nil;
        itemMore.badgeValue = nil;
        
        if (self.showMessages == YES) {
            
            [self.dashboardItems addObject:@"Inbox"];
            [self.dashboardItemValues addObject:@""];
            
            if ([self.numberOfMessages integerValue] > 0) {
                
                itemDashboard.badgeValue = [NSString stringWithFormat:@"%@", self.numberOfMessages];
                itemMore.badgeValue = [NSString stringWithFormat:@"%@", self.numberOfMessages];
            }
            
        } else if ([self.numberOfMessages integerValue] > 0) { // show on More tab only
            
            itemMore.badgeValue = [NSString stringWithFormat:@"%@", self.numberOfMessages];
        }
        
        // sort the dashboardItems according to self.dashboardUserSort prefs
        if ([self.dashboardUserSort count] > 0) {
            
            for (int i=0; i<[self.dashboardUserSort count]-1; i++) {
                
                if ([self.dashboardItems containsObject:[self.dashboardUserSort objectAtIndex:i]]) { // this sorted item is valid
                    
                    indexValue = [self.dashboardItems indexOfObject:[self.dashboardUserSort objectAtIndex:i]];
                    
                    if (indexValue != i) { // if this item is not already at the correct index
                    
                        self.dashboardObject = [self.dashboardItems objectAtIndex:indexValue];
                        [self.dashboardItems removeObjectAtIndex:indexValue];
                        [self.dashboardItems insertObject:self.dashboardObject atIndex:i];
                        
                        // move the assocaited value as well
                        self.dashboardObject = [self.dashboardItemValues objectAtIndex:indexValue];
                        [self.dashboardItemValues removeObjectAtIndex:indexValue];
                        [self.dashboardItemValues insertObject:self.dashboardObject atIndex:i];
                        
                    }
                }
            }
        }
        
        if ([self.dashboardItems containsObject:@"calories"] && [self.dashboardItems containsObject:@"calories_goal"]) {
            
            indexValue = [self.dashboardItems indexOfObject:@"calories"];
            indexValueTwo = [self.dashboardItems indexOfObject:@"calories_goal"];
            
            [self.dashboardItems removeObject:@"calories_goal"];
            [self.dashboardItems insertObject:@"calories_goal" atIndex:indexValue+1];
            
            // move the assocaited value as well
            self.dashboardObject = [self.dashboardItemValues objectAtIndex:indexValueTwo];
            
            [self.dashboardItemValues removeObjectAtIndex:indexValueTwo];
            [self.dashboardItemValues insertObject:self.dashboardObject atIndex:indexValue+1];
        }
        
        // need to move weight_goal as well
        if ([self.dashboardItems containsObject:@"weight"] && [self.dashboardItems containsObject:@"weight_goal"]) {
            
            indexValue = [self.dashboardItems indexOfObject:@"weight"];
            indexValueTwo = [self.dashboardItems indexOfObject:@"weight_goal"];
            
            [self.dashboardItems removeObject:@"weight_goal"];
            [self.dashboardItems insertObject:@"weight_goal" atIndex:indexValue+1];
            
            // move the assocaited value as well
            self.dashboardObject = [self.dashboardItemValues objectAtIndex:indexValueTwo];
            
            [self.dashboardItemValues removeObjectAtIndex:indexValueTwo];
            [self.dashboardItemValues insertObject:self.dashboardObject atIndex:indexValue+1];
        }
        
        // Learn tab bar item - check for badge
        
        if (appDelegate.hidePlanner == YES) {
            
            tabBarItemIndex = 2;
            
        } else {
            
            tabBarItemIndex = 3;
        }
        
        UITabBarItem *itemLearn = [self.tabBarController.tabBar.items objectAtIndex:tabBarItemIndex];
        
        itemLearn.badgeValue = nil;
        
        if (self.newLearningModules > 0) {
            
            itemLearn.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.newLearningModules];
            
        }
        
        // Plan tab bar item - check for badge
        
        if (appDelegate.hidePlanner == NO) {
        
            UITabBarItem *itemPlanner = [self.tabBarController.tabBar.items objectAtIndex:2];
            
            itemPlanner.badgeValue = nil;
            
            if (self.newEatingPlans > 0) {
                
                itemPlanner.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.newEatingPlans];
            }
        }
        
        [self.tableView reloadData];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    UIViewController *viewController = segue.destinationViewController;

    viewController.hidesBottomBarWhenPushed = YES;
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
    
    [self getDashboard:HTWebSvcURL withState:0];
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
    
    [self getDashboard:HTWebSvcURL withState:0];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
