//
//  HTAddActivitySelectItemViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddActivitySelectItemViewController : UIViewController <NSXMLParserDelegate, UIPickerViewDelegate, UITextFieldDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *addActivityCategory;

@property (nonatomic, assign) NSInteger selectedActivityID;
@property (nonatomic, assign) NSInteger relaunchItemID;

@property (nonatomic, assign) BOOL relaunchPlannerItem;
@property (nonatomic, assign) BOOL caloriesBurnedRecalc;

@property (nonatomic, strong) NSString *selectedActivityType;
@property (nonatomic, strong) NSString *selectedActivityName;
@property (nonatomic, strong) NSString *selectedActivityCaloriesBurned;
@property (nonatomic, strong) NSString *selectedActivityDuration;

@property (nonatomic, assign) float globalCaloriesBurned;

@property (nonatomic, strong) NSString *selectedActivityTime;
@property (nonatomic, strong) NSString *selectedActivityTimeFraction;
@property (nonatomic, strong) NSString *selectedActivityTimeAmPm;
@property (nonatomic, strong) NSString *selectedActivityReminder;
@property (nonatomic, strong) NSString *selectedActivityReminderFraction;
@property (nonatomic, strong) NSString *selectedActivityReminderAmPm;
@property (nonatomic, strong) NSString *selectedActivityReminderYN;
@property (nonatomic, strong) NSString *selectedActivityAddToFavorites;
@property (nonatomic, strong) NSString *selectedActivityRelaunchItem;
@property (nonatomic, strong) NSString *selectedActivityRelaunchItemID;

@property (nonatomic, assign) BOOL addActivityToFavorites;
@property (nonatomic, assign) BOOL doneAddingActivity;

@property (nonatomic, strong) NSMutableArray *addActivityTimePickerValues;
@property (nonatomic, strong) NSMutableArray *addActivityTimePickerValueFractions;
@property (nonatomic, strong) NSMutableArray *addActivityTimePickerValueAmPm;
@property (nonatomic, strong) NSMutableArray *addActivityReminderPickerValues;
@property (nonatomic, strong) NSMutableArray *addActivityReminderPickerValueFractions;
@property (nonatomic, strong) NSMutableArray *addActivityReminderPickerValueAmPm;

@property (nonatomic, strong) UITextField *selectedActivityNameTextField;
@property (nonatomic, strong) UITextField *durationTextField;
@property (nonatomic, strong) UITextField *caloriesBurnedTextField;
@property (nonatomic, strong) UITextField *addActivityTimeTextField;
@property (nonatomic, strong) UITextField *addActivityReminderTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *addActivitySelectItemScrollView;

@property (strong, nonatomic) IBOutlet UIPickerView *addActivityTimePickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *addActivityReminderPickerView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)checkButton;

- (void)backButtonPressed;
- (void)checkButtonPressed;

- (IBAction)checkBoxChecked:(id)sender;

- (void)doneWithPicker:(id)sender;

- (void)getActivityItem:(NSString *) url withState:(BOOL) urlState;

- (void)addActivityItem:(NSString *) url withState:(BOOL) urlState;

- (void)showActivityItem;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
