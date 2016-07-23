//
//  HTPlannerViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/29/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTPlannerViewController : UIViewController <NSXMLParserDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL doneDeletingFood;
@property (nonatomic, assign) BOOL hasSavedMyPlans;

@property (nonatomic, assign) NSInteger plannerItemCount;
@property (nonatomic, assign) NSInteger selectedFoodID;

@property (nonatomic, strong) NSString *selectedFoodCategory;

@property (nonatomic, strong) NSString *planName;
@property (nonatomic, strong) NSString *templateName;
@property (nonatomic, strong) NSString *planCalories;

@property (nonatomic, strong) NSString *saveToMyPlansName;

@property (nonatomic, strong) NSMutableArray *plannerItemID;
@property (nonatomic, strong) NSMutableArray *plannerItemHour;
@property (nonatomic, strong) NSMutableArray *plannerItemEat;
@property (nonatomic, strong) NSMutableArray *plannerItemMove;
@property (nonatomic, strong) NSMutableArray *plannerItemBalance;
@property (nonatomic, strong) NSMutableArray *plannerItemReminder;
@property (nonatomic, strong) NSMutableArray *plannerItemCalories;
@property (nonatomic, strong) NSMutableArray *plannerItemMealID;
@property (nonatomic, strong) NSMutableArray *plannerItemExchangeItems;
@property (nonatomic, strong) NSMutableArray *plannerItemPlaceholder;
@property (nonatomic, strong) NSMutableArray *plannerItemNotes;
@property (nonatomic, strong) NSMutableArray *plannerItemSubNotes;
@property (nonatomic, strong) NSMutableArray *plannerItemImage;

@property (nonatomic, assign) NSInteger numberOfNewMessages;
@property (nonatomic, assign) NSInteger numberOfEatingPlans;
@property (nonatomic, assign) NSInteger numberOfLearningModules;

@property (nonatomic, strong) NSString *exchangeItemsString;
@property (nonatomic, strong) NSString *caloriesOrOtherString;

@property (strong, nonatomic) IBOutlet UIScrollView *plannerScrollView;

@property (strong, nonatomic) IBOutlet UIView *appletsView;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UIButton *buttonAddFood;
@property (strong, nonatomic) IBOutlet UIButton *buttonAddActivity;
@property (strong, nonatomic) IBOutlet UIButton *buttonCreateFavorites;
@property (strong, nonatomic) IBOutlet UIButton *buttonCreatePlan;

- (UIBarButtonItem *) myPlansButton;
- (UIBarButtonItem *) saveAsButton;

- (void) myPlansButtonPressed;
- (void) saveAsButtonPressed;

- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;
- (IBAction)clickedAddFood:(id)sender;
- (IBAction)clickedAddActivity:(id)sender;
- (IBAction)clickedCreateFavorites:(id)sender;
- (IBAction)clickedCreatePlan:(id)sender;
- (IBAction)relaunchPlannerItem:(id)sender;
- (IBAction)relaunchPlannerTemplateItem:(id)sender;
- (IBAction)relaunchActivityItem:(id)sender;
- (IBAction)deletePlannerItem:(id)sender;

- (void)getPlanner:(NSString *) url withState:(BOOL) urlState;

- (void)deleteFoodItem:(NSString *) url withState:(BOOL) urlState;

- (void)saveToMyPlans:(NSString *) url withState:(BOOL) urlState;

- (void)showPlanner;

- (void)showPlannerNutrition;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
