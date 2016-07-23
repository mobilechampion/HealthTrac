//
//  HTAppDelegate.m
//  HealthTrac
//
//  Created by Rob O'Neill on 9/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAppDelegate.h"
#import "HTWebContentViewController.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@implementation HTAppDelegate

#pragma mark - Delegate Methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self registerPushSetting];
    
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:(116/255.0)
                                                           green:(204/255.0)
                                                            blue:(240/255.0)
                                                           alpha:1.0]];
    
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithRed:(1.0)
                                                      green:(1.0)
                                                       blue:(1.0)
                                                      alpha:0.6],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:9.0]}
                                           forState:UIControlStateNormal];
    
    [UITabBarItem.appearance setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithRed:(1.0)
                                                      green:(1.0)
                                                       blue:(1.0)
                                                      alpha:1.0],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:9.0]}
                                           forState:UIControlStateSelected];
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
     setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor colorWithRed:(116/255.0)
                                                      green:(204/255.0)
                                                       blue:(240/255.0)
                                                      alpha:1.0],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0]}
     forState:UIControlStateNormal];
    
    self.currentDay = 0;
    self.currentMonth = 0;
    self.currentYear = 0;
    
    NSDate *date = [NSDate date];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    
    self.passDate = date;
    self.currentDate = date;
    
    self.currentDay = [dateComponents day];
    self.currentMonth = [dateComponents month];
    self.currentYear = [dateComponents year];
    
    self.passDay = self.currentDay;
    self.passMonth = self.currentMonth;
    self.passYear = self.currentYear;

    self.dashboardEditItems = [NSMutableArray array];
    
    self.shouldAllowPortrait = NO;
    self.hidePlanner = NO;
    
    return YES;
}

- (void) registerPushSetting
{
    UIApplication *application = [UIApplication sharedApplication];
    
    //For Push Notification
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)] && IS_OS_8_OR_LATER)
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge
                                                                                             |UIUserNotificationTypeSound
                                                                                             |UIUserNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *devicePushToken=[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] ;
    devicePushToken = [devicePushToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    [[NSUserDefaults standardUserDefaults] setValue:devicePushToken forKey:@"push_token"];
    
    NSLog(@"Token = %@", devicePushToken);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Received RemoteNotification, %@", userInfo);
    NSInteger appIconBadgeCount = [[userInfo valueForKey:@"badgeicon"] integerValue];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:appIconBadgeCount];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"onReceivePush" object:nil];
    
    NSLog(@"didReceiveRemoteNotification fetchCompletionHandler called");
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Global Methods

- (NSDate *)addNumberOfDays:(NSInteger)days toDate:(NSDate *)date {
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    
    dayComponent.day = days;
    
    NSDate *newDate = [theCalendar dateByAddingComponents:dayComponent toDate:date options:0];
    
    return newDate;
}

- (NSDate *)addNumberOfMonths:(NSInteger)months toDate:(NSDate *)date {
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *monthComponent = [[NSDateComponents alloc] init];
    
    monthComponent.month = months;
    
    NSDate *newDate = [theCalendar dateByAddingComponents:monthComponent toDate:date options:0];
    
    return newDate;
}

- (NSString *)cleanStringBeforeSending:(NSString *)string {
    
    NSString *cleanString = [[[[[string stringByReplacingOccurrencesOfString:@"<" withString:@"|*|lt|*|"]
                                stringByReplacingOccurrencesOfString:@">" withString:@"|*|gt|*|"]
                               stringByReplacingOccurrencesOfString:@"&" withString:@"|*|and|*|"]
                              stringByReplacingOccurrencesOfString:@" " withString:@"+"]
                             stringByReplacingOccurrencesOfString:@"\n" withString:@"%0D%0A"];
    return cleanString;
}

- (NSString *)cleanStringAfterReceiving:(NSString *)string {
    
    NSString *cleanString = [[[[string stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                               stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                              stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                             stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
    return cleanString;
}

- (void)checkAppDatesWithPlanner:(BOOL)inPlanner {
    
    // make sure we have currentDate set correctly
    
    NSDate *date = [NSDate date];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if (![[dateFormatter stringFromDate:self.currentDate]
          isEqualToString:[dateFormatter stringFromDate:date]]) {
        
        self.currentDate = date;
        
        self.currentDay = [dateComponents day];
        self.currentMonth = [dateComponents month];
        self.currentYear = [dateComponents year];
    }
    
    // make sure passDate is not in the future if we're not in the planner
    
    if (inPlanner == NO) {
        
        if ([[self.passDate earlierDate:date] isEqualToDate:date]) {
         
            self.passDate = date;
            
            self.passDay = [dateComponents day];
            self.passMonth = [dateComponents month];
            self.passYear = [dateComponents year];
        }
    }
}

// CHECKIT - UIInterfaceOrientationMask

- (UIInterfaceOrientationMask) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    
    if (([[self.window.rootViewController presentedViewController]
         isKindOfClass:[MPMoviePlayerViewController class]] || self.shouldAllowPortrait == YES) &&
        (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))) {
        
        return UIInterfaceOrientationMaskAllButUpsideDown;
        
    }
    else {
        
        return UIInterfaceOrientationMaskPortrait;
    }
}

@end



