//
//  HTAppDelegate.h
//  HealthTrac
//
//  Created by Rob O'Neill on 9/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface HTAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, assign) BOOL shouldAllowPortrait;
@property (nonatomic, assign) BOOL hidePlanner;

@property (nonatomic, strong) NSString *passLogin;
@property (nonatomic, strong) NSString *passPw;

@property (nonatomic, strong) NSDate *passDate;
@property (nonatomic, strong) NSDate *currentDate;

@property (nonatomic, assign) NSInteger passDay;
@property (nonatomic, assign) NSInteger passMonth;
@property (nonatomic, assign) NSInteger passYear;
@property (nonatomic, assign) NSInteger currentDay;
@property (nonatomic, assign) NSInteger currentMonth;
@property (nonatomic, assign) NSInteger currentYear;

@property (nonatomic, strong) NSMutableArray *dashboardEditItems;

- (NSDate *)addNumberOfDays:(NSInteger)days toDate:(NSDate *)date;

- (NSDate *)addNumberOfMonths:(NSInteger)months toDate:(NSDate *)date;

- (NSString *)cleanStringBeforeSending:(NSString *)string;

- (NSString *)cleanStringAfterReceiving:(NSString *)string;

- (void)checkAppDatesWithPlanner:(BOOL)inPlanner;

@end