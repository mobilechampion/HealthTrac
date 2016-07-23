//
//  HTPlannerMyPlansViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/10/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTPlannerMyPlansViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL doneSelectingPlan;
@property (nonatomic, assign) BOOL doneDeletingPlan;

@property (nonatomic, strong) NSString *fromDate;
@property (nonatomic, strong) NSString *toDate;

@property (nonatomic, strong) NSString *selectedEatingPlanID;

@property (nonatomic, strong) NSMutableArray *myPlanID;
@property (nonatomic, strong) NSMutableArray *myPlanName;

@property (strong, nonatomic) IBOutlet UIDatePicker *fromPickerView;
@property (strong, nonatomic) IBOutlet UIDatePicker *toPickerView;

@property (nonatomic, strong) UITextField *fromTextField;
@property (nonatomic, strong) UITextField *toTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *myPlansScrollView;

- (UIBarButtonItem *) backButton;

- (void)backButtonPressed;
- (void)loadPlanButtonPressed;
- (void)eatingPlanPressed:(id)sender;
- (void)deletePlan:(id)sender;

- (void)datePickerValueChanged:(id)sender;
- (void)doneWithPicker:(id)sender;

- (void)getMyPlans:(NSString *) url withState:(BOOL) urlState;

- (void)selectEatingPlan:(NSString *) url withState:(BOOL) urlState;

- (void)deleteMyPlan:(NSString *) url withState:(BOOL) urlState;

- (void)showMyPlans;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
