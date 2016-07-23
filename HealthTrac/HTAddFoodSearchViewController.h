//
//  HTAddFoodSearchViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/4/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NMRangeSlider;

@interface HTAddFoodSearchViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *addFoodCategory;

@property (strong, nonatomic) IBOutlet UIScrollView *addFoodSearchScrollView;

@property (strong, nonatomic) IBOutlet NMRangeSlider *caloriesSlider;
@property (strong, nonatomic) IBOutlet NMRangeSlider *proteinSlider;
@property (strong, nonatomic) IBOutlet NMRangeSlider *carbsSlider;
@property (strong, nonatomic) IBOutlet NMRangeSlider *netCarbsSlider;
@property (strong, nonatomic) IBOutlet NMRangeSlider *fatSlider;
@property (strong, nonatomic) IBOutlet NMRangeSlider *satFatSlider;

@property (nonatomic, assign) BOOL showProteinSlider;
@property (nonatomic, assign) BOOL showCarbsSlider;
@property (nonatomic, assign) BOOL showNetCarbsSlider;
@property (nonatomic, assign) BOOL showFatSlider;
@property (nonatomic, assign) BOOL showSatFatSlider;
@property (nonatomic, assign) BOOL showSearchProducts;

@property (nonatomic, assign) BOOL typeCheckboxSnackChecked;
@property (nonatomic, assign) BOOL typeCheckboxAMChecked;
@property (nonatomic, assign) BOOL typeCheckboxPMChecked;
@property (nonatomic, assign) BOOL typeCheckboxOtherChecked;
@property (nonatomic, assign) BOOL prepCheckboxRTEChecked;
@property (nonatomic, assign) BOOL prepCheckboxLowChecked;
@property (nonatomic, assign) BOOL prepCheckboxMediumChecked;
@property (nonatomic, assign) BOOL prepCheckboxHighChecked;

@property (nonatomic, strong) NSString *productsSearchSelection;
@property (nonatomic, strong) NSString *addFoodSearchFieldString;
@property (nonatomic, strong) NSString *addFoodSearchString;

@property (strong, nonatomic) UITextField *searchField;

@property (nonatomic, assign) BOOL showAdditionalFields;

@property (nonatomic, strong) UIImageView *additionalFieldsImageView;

- (IBAction)labelSliderChanged:(NMRangeSlider*)sender;

- (IBAction)checkBoxChecked:(id)sender;

- (void)updateSliderLabels:(NMRangeSlider*)sender;

- (UIBarButtonItem *)backButton;

- (UIBarButtonItem *)checkButton;

- (void)backButtonPressed;

- (void)checkButtonPressed;

- (void)getSearchFields:(NSString *) url withState:(BOOL) urlState;

- (void)showSearchFields;

- (NMRangeSlider *)createNMRangeSliderWithFrame:(CGRect)frame
                                         andType:(NSString *)type
                                     andMinValue:(float)minValue
                                     andMaxValue:(float)maxValue
                                    andStepValue:(float)stepValue;

- (void)toggleAdditionalFields;

// Error handling
- (void)handleURLError:(NSError *)error;

@end