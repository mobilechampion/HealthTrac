//
//  HTCreateEatingPlanViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTCreateEatingPlanViewController : UIViewController <NSXMLParserDelegate, UIPickerViewDelegate, UITextFieldDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) BOOL doneUpdatingValues;

@property (nonatomic, strong) NSString *selectedHeight;
@property (nonatomic, strong) NSString *selectedHeightFeet;
@property (nonatomic, strong) NSString *selectedHeightInches;
@property (nonatomic, strong) NSString *selectedSex;
@property (nonatomic, strong) NSString *selectedWeight;
@property (nonatomic, strong) NSString *selectedAge;
@property (nonatomic, strong) NSString *selectedActivityLevel;

@property (nonatomic, strong) NSString *caloriesToMaintain;
@property (nonatomic, strong) NSString *caloriesToLoseOneLb;
@property (nonatomic, strong) NSString *caloriesToLoseTwoLbs;

@property (nonatomic, strong) NSMutableArray *selectedHeightFeetPickerValues;
@property (nonatomic, strong) NSMutableArray *selectedHeightInchesPickerValues;
@property (nonatomic, strong) NSMutableArray *selectedSexPickerValues;
@property (nonatomic, strong) NSMutableArray *selectedActivityLevelPickerValues;

@property (nonatomic, strong) UITextField *selectedHeightTextField;
@property (nonatomic, strong) UITextField *selectedSexTextField;
@property (nonatomic, strong) UITextField *selectedWeightTextField;
@property (nonatomic, strong) UITextField *selectedAgeTextField;
@property (nonatomic, strong) UITextField *selectedActivityLevelTextField;

@property (strong, nonatomic) IBOutlet UIScrollView *createEatingPlanScrollView;

@property (strong, nonatomic) IBOutlet UIPickerView *selectedHeightPickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *selectedSexPickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *selectedActivityLevelPickerView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;
- (void)calculateButtonPressed;

- (void)doneWithPicker:(id)sender;

- (void)getCreateEatingPlanValues:(NSString *) url withState:(BOOL) urlState;

- (void)updateCreateEatingPlanValues:(NSString *) url withState:(BOOL) urlState;

- (void)showCreateEatingPlan;

// Error handling
- (void)handleURLError:(NSError *)error;

@end