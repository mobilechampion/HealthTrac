//
//  HTAddFoodSearchResultsViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddFoodSearchResultsViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL doneDeletingFavorite;
@property (nonatomic, assign) BOOL doneSubmittingSearchRequest;
@property (nonatomic, assign) BOOL allowSelections;

@property (nonatomic, strong) NSMutableArray *addFoodID;
@property (nonatomic, strong) NSMutableArray *addFoodName;
@property (nonatomic, strong) NSMutableArray *addFoodCalories;
@property (nonatomic, strong) NSMutableArray *addFoodServings;
@property (nonatomic, strong) NSMutableArray *quantityPickerValues;
@property (nonatomic, strong) NSMutableArray *quantityPickerValueFractions;

@property (nonatomic, strong) NSString *addFoodCategory;
@property (nonatomic, strong) NSString *addFoodSearchFieldString;
@property (nonatomic, strong) NSString *addFoodSearchString;
@property (nonatomic, strong) NSString *inTemplateString;
@property (nonatomic, strong) NSString *generalFoodSearchString;
@property (nonatomic, strong) NSString *caloriesOrOtherString;

@property (nonatomic, assign) NSInteger selectedFoodID;
@property (nonatomic, assign) NSInteger relaunchItemID;
@property (nonatomic, assign) NSInteger exchangeNumber;
@property (nonatomic, assign) NSInteger generalFoodSearchPhase;

//@property (strong, nonatomic) IBOutlet UIPickerView *quantityPickerView;

@property (nonatomic, assign) BOOL prepCheckboxRTEChecked;
@property (nonatomic, assign) BOOL prepCheckboxLowChecked;
@property (nonatomic, assign) BOOL prepCheckboxMediumChecked;
@property (nonatomic, assign) BOOL prepCheckboxHighChecked;

@property (nonatomic, assign) BOOL isExchangeItem;

@property (nonatomic, assign) float exchangeItemsAllowed;
@property (nonatomic, assign) float exchangeItemsSelected;

@property (nonatomic, strong) NSMutableString *exchangeItemsString;

@property (nonatomic, strong) UILabel *exchangeMessageLabel;

@property (nonatomic, strong) NSArray *exchangeItemArray;
@property (nonatomic, strong) NSArray *exchangeItemQuantitiesArray;

@property (nonatomic, assign) NSInteger numberOfResults;

@property (nonatomic, strong) UIView *prepEffortContainer;
@property (nonatomic, strong) UIButton *searchFieldContainer;
@property (nonatomic, strong) UIButton *generalFoodSearchContainer;
@property (nonatomic, strong) UIButton *exchangeMessageContainer;
@property (nonatomic, strong) UIButton *numberOfResultsContainer;

@property (strong, nonatomic) IBOutlet UIScrollView *addFoodSearchResultsScrollView;

@property (strong, nonatomic) UITextField *searchField;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)checkButton;

- (void)backButtonPressed;
- (void)checkButtonPressed;

- (void)generalFoodSearchPhaseII;
- (void)generalFoodSearchSubmitRequest;

- (void)selectFoodItem:(id)sender;

- (void)chooseExchangeItems; //:(id)sender

- (void)doneWithPicker:(id)sender;

- (IBAction)checkBoxChecked:(id)sender;

- (void)getSearchResults:(NSString *) url withState:(BOOL) urlState;

- (void)submitSearchRequest:(NSString *) url withState:(BOOL) urlState;

- (void)deleteFavorite:(NSString *) url withState:(BOOL) urlState;

- (void)showSearchResults;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
