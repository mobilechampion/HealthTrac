//
//  HTCreateFavoritesViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/3/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTCreateFavoritesViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *selectedFavoriteRelaunchItem;
@property (nonatomic, assign) NSInteger relaunchItemID;

@property (nonatomic, strong) NSString *selectedFavoriteName;
@property (nonatomic, strong) NSString *selectedFavoriteType;
@property (nonatomic, strong) NSString *selectedFavoritePrep;

@property (nonatomic, strong) NSString *selectedFavoriteCalories;
@property (nonatomic, strong) NSString *selectedFavoriteProtein;
@property (nonatomic, strong) NSString *selectedFavoriteCarbs;
@property (nonatomic, strong) NSString *selectedFavoriteFat;
@property (nonatomic, strong) NSString *selectedFavoriteSatFat;
@property (nonatomic, strong) NSString *selectedFavoriteSugars;
@property (nonatomic, strong) NSString *selectedFavoriteFiber;
@property (nonatomic, strong) NSString *selectedFavoriteSodium;

@property (nonatomic, strong) NSString *selectedFavoriteDescription;
@property (nonatomic, strong) NSString *selectedFavoriteServings;
@property (nonatomic, strong) NSString *selectedFavoriteIngredients;
@property (nonatomic, strong) NSString *selectedFavoriteDirections;
@property (nonatomic, strong) NSString *selectedFavoriteRecommended;
@property (nonatomic, strong) NSString *selectedFavoriteComments;

@property (nonatomic, assign) BOOL doneAddingFavorite;

@property (nonatomic, strong) UITextField *selectedFavoriteNameTextField;

@property (nonatomic, strong) UITextField *selectedFavoriteCaloriesTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteProteinTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteCarbsTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteFatTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteSatFatTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteSugarsTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteFiberTextField;
@property (nonatomic, strong) UITextField *selectedFavoriteSodiumTextField;

@property (nonatomic, strong) UITextField *selectedFavoriteServingsTextField;

@property (nonatomic, strong) UITextView *selectedFavoriteDescriptionTextView;
@property (nonatomic, strong) UITextView *selectedFavoriteIngredientsTextView;
@property (nonatomic, strong) UITextView *selectedFavoriteDirectionsTextView;
@property (nonatomic, strong) UITextView *selectedFavoriteRecommendedTextView;
@property (nonatomic, strong) UITextView *selectedFavoriteCommentsTextView;

@property (nonatomic, assign) BOOL typeRadioButtonSnackChecked;
@property (nonatomic, assign) BOOL typeRadioButtonAMChecked;
@property (nonatomic, assign) BOOL typeRadioButtonPMChecked;
@property (nonatomic, assign) BOOL typeRadioButtonOtherChecked;
@property (nonatomic, assign) BOOL prepRadioButtonRTEChecked;
@property (nonatomic, assign) BOOL prepRadioButtonLowChecked;
@property (nonatomic, assign) BOOL prepRadioButtonMediumChecked;
@property (nonatomic, assign) BOOL prepRadioButtonHighChecked;

@property (nonatomic, assign) BOOL showAdditionalFields;

@property (strong, nonatomic) IBOutlet UIScrollView *addFavoriteScrollView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)checkButton;

- (void)backButtonPressed;
- (void)checkButtonPressed;
- (void)toggleAdditionalFields;

- (IBAction)radioButtonChecked:(id)sender;

- (void)getFavoriteItem:(NSString *) url withState:(BOOL) urlState;

- (void)addFavoriteItem:(NSString *) url withState:(BOOL) urlState;

- (void)showFavoriteItem;

// Error handling
- (void)handleURLError:(NSError *)error;

@end