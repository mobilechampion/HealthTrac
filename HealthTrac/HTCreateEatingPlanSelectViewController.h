//
//  HTCreateEatingPlanSelectViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/8/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTCreateEatingPlanSelectViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL doneSelectingPlan;

@property (nonatomic, strong) NSString *caloriesToMaintain;
@property (nonatomic, strong) NSString *caloriesToLoseOneLb;
@property (nonatomic, strong) NSString *caloriesToLoseTwoLbs;
@property (nonatomic, strong) NSString *fromDate;
@property (nonatomic, strong) NSString *toDate;

@property (nonatomic, strong) NSString *selectedCalories;
@property (nonatomic, strong) NSString *selectedEatingPlanID;

@property (nonatomic, strong) NSMutableArray *practicePlanID;
@property (nonatomic, strong) NSMutableArray *practicePlanName;
@property (nonatomic, strong) NSMutableArray *practicePlanCalories;

@property (strong, nonatomic) IBOutlet UIDatePicker *fromPickerView;
@property (strong, nonatomic) IBOutlet UIDatePicker *toPickerView;

@property (nonatomic, strong) UITextField *fromTextField;
@property (nonatomic, strong) UITextField *toTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *createEatingPlanScrollView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;
- (void)loadPlanButtonPressed;
- (void)selectTargetCalories:(id)sender;
- (void)eatingPlanPressed:(id)sender;

- (void)datePickerValueChanged:(id)sender;
- (void)doneWithPicker:(id)sender;

- (void)getPracticePlans:(NSString *) url withState:(BOOL) urlState;

- (void)selectEatingPlan:(NSString *) url withState:(BOOL) urlState;

- (void)updatePlannerTargetCalories:(NSString *) url withState:(BOOL) urlState;

- (void)showCreateEatingPlanOptions;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
