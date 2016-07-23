//
//  HTAddActivityViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddActivityViewController : UIViewController {
    
}

@property (nonatomic, strong) NSString *addActivityCategory;
@property (nonatomic, strong) NSString *addActivityType;

@property (nonatomic, assign) NSInteger numberOfaddACtivityButtons;

@property (strong, nonatomic) IBOutlet UIView *addActivityView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;

- (void)showAddActivityCategories;

- (void)addActivitySelectCategory:(id)sender;

@end
