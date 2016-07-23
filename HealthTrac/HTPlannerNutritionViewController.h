//
//  HTPlannerNutritionViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTPlannerNutritionViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *addFoodCategory;

@property (nonatomic, assign) NSInteger selectedFoodID;

@property (nonatomic, strong) NSString *plannerName;
@property (nonatomic, strong) NSString *plannerCalories;
@property (nonatomic, strong) NSString *plannerProtein;
@property (nonatomic, strong) NSString *plannerCarbs;
@property (nonatomic, strong) NSString *plannerFiber;
@property (nonatomic, strong) NSString *plannerSugar;
@property (nonatomic, strong) NSString *plannerSodium;
@property (nonatomic, strong) NSString *plannerFat;
@property (nonatomic, strong) NSString *plannerSatFat;
@property (nonatomic, strong) NSString *plannerCaloriesBurned;
@property (nonatomic, strong) NSString *plannerTargetCalories;

@property (nonatomic, strong) UIButton *targetCaloriesButton;

@property (nonatomic, strong) UIAlertView *targetCaloriesAlertView;

@property (nonatomic, strong) UITextField *alertViewCaloriesTextField;

@property (nonatomic, assign) BOOL doneUpdatingTargetCalories;

@property (nonatomic, strong) UILabel *plannerNameLabel;
@property (nonatomic, strong) UILabel *plannerCaloriesLabel;
@property (nonatomic, strong) UILabel *plannerProteinLabel;
@property (nonatomic, strong) UILabel *plannerCarbsLabel;
@property (nonatomic, strong) UILabel *plannerFiberLabel;
@property (nonatomic, strong) UILabel *plannerSugarLabel;
@property (nonatomic, strong) UILabel *plannerSodiumLabel;
@property (nonatomic, strong) UILabel *plannerFatLabel;
@property (nonatomic, strong) UILabel *plannerSatFatLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *plannerNutritionScrollView;

- (UIBarButtonItem *) backButton;

- (void)backButtonPressed;

- (void)targetCaloriesButtonPressed;

- (void)getNutrition:(NSString *) url withState:(BOOL) urlState;

- (void)updatePlannerTargetCalories:(NSString *) url withState:(BOOL) urlState;

- (void)showNutrition;

// Error handling
- (void)handleURLError:(NSError *)error;

@end