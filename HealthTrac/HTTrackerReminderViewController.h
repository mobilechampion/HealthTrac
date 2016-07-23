//
//  HTTrackerReminderViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/15/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTTrackerReminderViewController : UIViewController <NSXMLParserDelegate, UIPickerViewDelegate, UITextFieldDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) BOOL radioButtonYesterdayChecked;
@property (nonatomic, assign) BOOL radioButtonTodayChecked;

@property (nonatomic, assign) BOOL reminderDailyChecked;
@property (nonatomic, assign) BOOL reminderMondayChecked;
@property (nonatomic, assign) BOOL reminderTuesdayChecked;
@property (nonatomic, assign) BOOL reminderWednesdayChecked;
@property (nonatomic, assign) BOOL reminderThursdayChecked;
@property (nonatomic, assign) BOOL reminderFridayChecked;
@property (nonatomic, assign) BOOL reminderSaturdayChecked;
@property (nonatomic, assign) BOOL reminderSundayChecked;

@property (nonatomic, assign) NSInteger reminderMetricID;

@property (nonatomic, strong) NSString *reminderType;

@property (nonatomic, strong) NSString *reminderYN;
@property (nonatomic, strong) NSString *reminderTime;
@property (nonatomic, strong) NSString *reminderTimeAmPm;
@property (nonatomic, strong) NSString *reminderDays;
@property (nonatomic, strong) NSString *reminderColorDay;

@property (nonatomic, assign) BOOL doneSettingReminder;

@property (nonatomic, strong) NSMutableArray *reminderPickerValues;
@property (nonatomic, strong) NSMutableArray *reminderPickerValueAmPm;

@property (nonatomic, strong) UITextField *reminderTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *reminderScrollView;

@property (strong, nonatomic) IBOutlet UIPickerView *reminderPickerView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)checkButton;

- (void)backButtonPressed;
- (void)checkButtonPressed;

- (IBAction)checkBoxChecked:(id)sender;
- (IBAction)radioButtonChecked:(id)sender;

- (void)doneWithPicker:(id)sender;

- (void)getReminder:(NSString *) url withState:(BOOL) urlState;

- (void)updateReminder:(NSString *) url withState:(BOOL) urlState;

- (void)showReminder;

// Error handling
- (void)handleURLError:(NSError *)error;

@end