//
//  HTAddFoodSelectItemDetailsViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/10/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddFoodSelectItemDetailsViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) NSInteger mealItemID;

@property (nonatomic, strong) NSString *selectedMealName;
@property (nonatomic, strong) NSString *selectedMealType;
@property (nonatomic, strong) NSString *selectedMealPrep;

@property (nonatomic, strong) NSString *selectedMealCalories;
@property (nonatomic, strong) NSString *selectedMealProtein;
@property (nonatomic, strong) NSString *selectedMealCarbs;
@property (nonatomic, strong) NSString *selectedMealFat;
@property (nonatomic, strong) NSString *selectedMealSatFat;
@property (nonatomic, strong) NSString *selectedMealSugars;
@property (nonatomic, strong) NSString *selectedMealFiber;
@property (nonatomic, strong) NSString *selectedMealSodium;

@property (nonatomic, strong) NSString *selectedMealDescription;
@property (nonatomic, strong) NSString *selectedMealServings;
@property (nonatomic, strong) NSString *selectedMealIngredients;
@property (nonatomic, strong) NSString *selectedMealDirections;
@property (nonatomic, strong) NSString *selectedMealRecommended;
@property (nonatomic, strong) NSString *selectedMealComments;

@property (nonatomic, strong) NSMutableAttributedString *completeDetailsString;

@property (nonatomic, strong) UITextField *selectedMealNameTextField;

@property (nonatomic, strong) UITextField *selectedMealCaloriesTextField;

@property (nonatomic, strong) UITextField *selectedMealTypeTextField;
@property (nonatomic, strong) UITextField *selectedMealPrepTextField;

@property (nonatomic, strong) UITextField *selectedMealProteinTextField;
@property (nonatomic, strong) UITextField *selectedMealCarbsTextField;
@property (nonatomic, strong) UITextField *selectedMealFatTextField;
@property (nonatomic, strong) UITextField *selectedMealSatFatTextField;
@property (nonatomic, strong) UITextField *selectedMealSugarsTextField;
@property (nonatomic, strong) UITextField *selectedMealFiberTextField;
@property (nonatomic, strong) UITextField *selectedMealSodiumTextField;

@property (nonatomic, strong) UITextField *selectedMealServingsTextField;

@property (nonatomic, strong) UITextView *selectedMealDescriptionTextView;
@property (nonatomic, strong) UITextView *selectedMealIngredientsTextView;
@property (nonatomic, strong) UITextView *selectedMealDirectionsTextView;
@property (nonatomic, strong) UITextView *selectedMealRecommendedTextView;
@property (nonatomic, strong) UITextView *selectedMealCommentsTextView;

@property (strong, nonatomic) IBOutlet UITextView *completeDetailsTextView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;;

- (void)getMealItem:(NSString *) url withState:(BOOL) urlState;

- (void)showMealItem;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
