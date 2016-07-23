//
//  HTAddFoodViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/4/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddFoodViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) BOOL showAddFoodFavorites;
@property (nonatomic, assign) BOOL showAddFoodRecommended;
@property (nonatomic, assign) BOOL showAddFoodGeneral;

@property (nonatomic, strong) NSString *addFoodCategory;

@property (nonatomic, assign) NSInteger numberOfaddFoodButtons;

@property (strong, nonatomic) IBOutlet UIView *addFoodView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;

- (void)getAddFoodCategories:(NSString *) url withState:(BOOL) urlState;

- (void)showAddFoodCategories;

- (void)addFoodSelectCategory:(id)sender;

// Error handling
- (void)handleURLError:(NSError *)error;

@end