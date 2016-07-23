//
//  HTDashboardEditViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 9/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTDashboardEditViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *dashboardUserSort;
@property (nonatomic, strong) NSMutableArray *dashboardObjects;

@property (nonatomic, strong) NSMutableDictionary *dashboardUserPrefs;

@property (nonatomic, strong) NSObject *dashboardObject;

- (IBAction)doneEditing:(id)sender;
- (IBAction)cancelEditing:(id)sender;

@end
