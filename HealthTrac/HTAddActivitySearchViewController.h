//
//  HTAddActivitySearchViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTAddActivitySearchViewController : UIViewController <NSXMLParserDelegate,
    UITextFieldDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSMutableArray *addActivityID;
@property (nonatomic, strong) NSMutableArray *addActivityName;
@property (nonatomic, strong) NSMutableArray *addActivityType;

@property (nonatomic, strong) NSString *addActivityCategory;
@property (nonatomic, strong) NSString *addActivitySearchFieldString;
@property (nonatomic, strong) NSString *addActivitySearchString;

@property (nonatomic, assign) NSInteger selectedActivityID;
@property (nonatomic, assign) NSInteger relaunchItemID;

@property (nonatomic, assign) BOOL favoritesTypeExerciseChecked;
@property (nonatomic, assign) BOOL favoritesTypeBalanceChecked;
@property (nonatomic, assign) BOOL favoritesTypeNoteChecked;
@property (nonatomic, assign) BOOL doneDeletingFavorite;
@property (nonatomic, assign) BOOL allowSelections;

@property (nonatomic, assign) NSInteger numberOfResults;

@property (nonatomic, strong) UIView *favoritesTypeContainer;

@property (nonatomic, strong) UIButton *searchFieldContainer;
@property (nonatomic, strong) UIButton *numberOfResultsContainer;

@property (strong, nonatomic) IBOutlet UIScrollView *addActivitySearchResultsScrollView;

@property (strong, nonatomic) UITextField *searchField;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)newExerciseButton;

- (void)backButtonPressed;
- (void)newExerciseButtonPressed;

- (void)selectActivity:(id)sender;

- (void)deleteFavoriteItem:(id)sender;

- (void)getSearchResults:(NSString *) url withState:(BOOL) urlState;

- (void)deleteFavorite:(NSString *) url withState:(BOOL) urlState;

- (void)showSearchResults;

// Error handling
- (void)handleURLError:(NSError *)error;

@end