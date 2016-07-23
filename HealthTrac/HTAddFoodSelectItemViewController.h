//
//  HTAddFoodSelectItemViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/7/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddFoodSelectItemViewController : UIViewController <NSXMLParserDelegate, UIPickerViewDelegate, UITextFieldDelegate> {
    
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
@property (nonatomic, assign) NSInteger relaunchItemID;

@property (nonatomic, assign) BOOL relaunchPlannerItem;
@property (nonatomic, strong) NSString *inTemplateString;

@property (nonatomic, strong) NSString *selectedFoodName;
@property (nonatomic, strong) NSString *selectedFoodDetailsID;
@property (nonatomic, strong) NSString *selectedFoodCalories;
@property (nonatomic, strong) NSString *selectedFoodProtein;
@property (nonatomic, strong) NSString *selectedFoodCarbs;
@property (nonatomic, strong) NSString *selectedFoodFiber;
@property (nonatomic, strong) NSString *selectedFoodSugar;
@property (nonatomic, strong) NSString *selectedFoodSodium;
@property (nonatomic, strong) NSString *selectedFoodFat;
@property (nonatomic, strong) NSString *selectedFoodSatFat;
@property (nonatomic, strong) NSString *selectedFoodServings;

@property (nonatomic, strong) NSString *selectedFoodQuantity;
@property (nonatomic, strong) NSString *selectedFoodQuantityFraction;
@property (nonatomic, strong) NSString *selectedFoodTime;
@property (nonatomic, strong) NSString *selectedFoodTimeFraction;
@property (nonatomic, strong) NSString *selectedFoodTimeAmPm;
@property (nonatomic, strong) NSString *selectedFoodReminder;
@property (nonatomic, strong) NSString *selectedFoodReminderFraction;
@property (nonatomic, strong) NSString *selectedFoodReminderAmPm;
@property (nonatomic, strong) NSString *selectedFoodReminderYN;
@property (nonatomic, strong) NSString *selectedFoodAddToFavorites;
@property (nonatomic, strong) NSString *selectedFoodRelaunchItem;
@property (nonatomic, strong) NSString *selectedFoodRelaunchItemID;
@property (nonatomic, strong) NSString *selectedFoodExchangeNumber;
@property (nonatomic, strong) NSString *selectedFoodTemplate;

@property (nonatomic, assign) BOOL addFoodToFavorites;
@property (nonatomic, assign) BOOL doneAddingFood;

@property (nonatomic, strong) NSMutableArray *quantityPickerValues;
@property (nonatomic, strong) NSMutableArray *quantityPickerValueFractions;
@property (nonatomic, strong) NSMutableArray *addFoodTimePickerValues;
@property (nonatomic, strong) NSMutableArray *addFoodTimePickerValueFractions;
@property (nonatomic, strong) NSMutableArray *addFoodTimePickerValueAmPm;
@property (nonatomic, strong) NSMutableArray *addFoodReminderPickerValues;
@property (nonatomic, strong) NSMutableArray *addFoodReminderPickerValueFractions;
@property (nonatomic, strong) NSMutableArray *addFoodReminderPickerValueAmPm;

@property (nonatomic, strong) UITextField *quantityTextField;
@property (nonatomic, strong) UITextField *addFoodTimeTextField;
@property (nonatomic, strong) UITextField *addFoodReminderTextField;

@property (nonatomic, strong) UILabel *addFoodCaloriesLabel;
@property (nonatomic, strong) UILabel *addFoodProteinLabel;
@property (nonatomic, strong) UILabel *addFoodCarbsLabel;
@property (nonatomic, strong) UILabel *addFoodFiberLabel;
@property (nonatomic, strong) UILabel *addFoodSugarLabel;
@property (nonatomic, strong) UILabel *addFoodSodiumLabel;
@property (nonatomic, strong) UILabel *addFoodFatLabel;
@property (nonatomic, strong) UILabel *addFoodSatFatLabel;

@property (nonatomic, strong) NSString *exchangeItemsString;

@property (strong, nonatomic) IBOutlet UIScrollView *addFoodSelectItemScrollView;

@property (strong, nonatomic) IBOutlet UIPickerView *quantityPickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *addFoodTimePickerView;
@property (strong, nonatomic) IBOutlet UIPickerView *addFoodReminderPickerView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)checkButton;
- (UIBarButtonItem *)changeItemButton;

- (void)backButtonPressed;
- (void)checkButtonPressed;
- (void)changeItemButtonPressed;

- (IBAction)checkBoxChecked:(id)sender;

- (void)doneWithPicker:(id)sender;

- (void)getFoodItem:(NSString *) url withState:(BOOL) urlState;

- (void)addFoodItem:(NSString *) url withState:(BOOL) urlState;

- (void)showFoodItem;

// Error handling
- (void)handleURLError:(NSError *)error;

@end