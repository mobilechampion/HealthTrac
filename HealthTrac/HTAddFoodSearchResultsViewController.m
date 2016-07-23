//
//  HTAddFoodSearchResultsViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddFoodSearchResultsViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTAddFoodSelectItemViewController.h"
#import "HTCreateFavoritesViewController.h"

@interface HTAddFoodSearchResultsViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddFoodSearchResultsViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
    
    self.generalFoodSearchPhase = 1;
    
    self.addFoodSearchFieldString = @"";
    self.generalFoodSearchString = @"";
    
    self.prepCheckboxRTEChecked = NO;
    self.prepCheckboxLowChecked = NO;
    self.prepCheckboxMediumChecked = NO;
    self.prepCheckboxHighChecked = NO;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.passLogin isEqualToString:@""] ||
        [appDelegate.passPw isEqualToString:@""] ||
        appDelegate.passLogin == nil ||
        appDelegate.passPw == nil) {
        
        UINavigationController *navigationController = (UINavigationController *)self.navigationController;
        
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
        
        HTLoginViewController *viewController = (HTLoginViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"loginView"];
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        [navigationController pushViewController:viewController animated:NO];
    }
    
    // make sure all app dates are set correctly
    [appDelegate checkAppDatesWithPlanner:YES];
    
    [super viewWillAppear:animated];
    
    self.allowSelections = NO;
    
    self.inTemplateString = @"false";
    
    if ([self.addFoodCategory isEqualToString:@"favorites"]) {
        
        self.title = @"My Favorites";
        
    } else if ([self.addFoodCategory isEqualToString:@"recommended"]) {
        
        self.title = @"Recommended";
        
    } else if ([self.addFoodCategory isEqualToString:@"general"]) {
        
        self.title = @"General Food Item";
        
    } else if ([self.addFoodCategory isEqualToString:@"template"]) {
        
        self.title = @"Recommended";
        self.inTemplateString = @"true";
    }
    
//    NSArray *viewsToRemove = [self.addFoodSearchResultsScrollView subviews];
//    
//    for (UIView *v in viewsToRemove) {
//        
//        [v removeFromSuperview];
//    }
    
    self.quantityPickerValues = [[NSMutableArray alloc] init];
    self.quantityPickerValueFractions = [[NSMutableArray alloc] init];
    
    [self.quantityPickerValues removeAllObjects];
    [self.quantityPickerValueFractions removeAllObjects];
    
    for (int i=0; i<=16; i++) {
        
        [self.quantityPickerValues insertObject:[NSString stringWithFormat:@"%d", i] atIndex:i];
    }
    
    [self.quantityPickerValueFractions insertObject:@".00" atIndex:0];
    [self.quantityPickerValueFractions insertObject:@".25" atIndex:1];
    [self.quantityPickerValueFractions insertObject:@".50" atIndex:2];
    [self.quantityPickerValueFractions insertObject:@".75" atIndex:3];
    
    self.exchangeItemsString = [NSMutableString stringWithString:@""];
    
    //if ([self.addFoodCategory isEqualToString:@"general"]) {
    
    if (([self.addFoodCategory isEqualToString:@"general"]
         || [self.addFoodCategory isEqualToString:@"template"])
        && self.isExchangeItem == NO) {
    
        self.navigationItem.rightBarButtonItem = [self checkButton];
        
    } else {
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.caloriesOrOtherString = @"calories";
    
    if ([self.addFoodCategory isEqualToString:@"general"]
        && [self.addFoodSearchFieldString isEqualToString:@""]) {
        
        self.addFoodID = [[NSMutableArray alloc] init];
        
        [self.addFoodID insertObject:@"" atIndex:0];
        
        [self showSearchResults];
        
    } else {
    
        [self getSearchResults:HTWebSvcURL withState:0];
    }
}

#pragma mark - Methods

- (void)getSearchResults:(NSString *) url withState:(BOOL) urlState {
    //
    //    NSArray *viewsToRemove = [self.addFoodSearchResultsScrollView subviews];
    //
    //    for (UIView *v in viewsToRemove) {
    //
    //        [v removeFromSuperview];
    //    }
    //
    //    [self.searchFieldContainer removeFromSuperview];
    //    [self.exchangeMessageContainer removeFromSuperview];
    //    [self.numberOfResultsContainer removeFromSuperview];
    //    [self.prepEffortContainer removeFromSuperview];
    //    [self.generalFoodSearchContainer removeFromSuperview];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFavorite = NO;
    self.doneSubmittingSearchRequest = NO;
    
    self.addFoodID = [[NSMutableArray alloc] init];
    self.addFoodName = [[NSMutableArray alloc] init];
    self.addFoodCalories = [[NSMutableArray alloc] init];
    self.addFoodServings = [[NSMutableArray alloc] init];
    
    self.exchangeItemArray = [[NSArray alloc] init];
    self.exchangeItemQuantitiesArray = [[NSArray alloc] init];
    
    self.selectedFoodID = 0;
    
    // prep effort
    
    NSMutableString *prepString = [[NSMutableString alloc] initWithString:@""];
    
    if ([self.addFoodCategory isEqualToString:@"template"]) {
        
        if (self.prepCheckboxRTEChecked == YES) {
            
            [prepString appendString:@"R,"];
        }
        
        if (self.prepCheckboxLowChecked == YES) {
            
            [prepString appendString:@"L,"];
        }
        
        if (self.prepCheckboxMediumChecked == YES) {
            
            [prepString appendString:@"M,"];
        }
        
        if (self.prepCheckboxHighChecked == YES) {
            
            [prepString appendString:@"H,"];
        }
        
        if ([prepString length] != 0) {
            
            NSRange prepStringRange = NSMakeRange(0, [prepString length] - 1);
            
            prepString = [NSMutableString stringWithString:[prepString substringWithRange:prepStringRange]];
        }
    }
    
    if ([self.addFoodCategory isEqualToString:@"template"]
        && self.relaunchItemID > 0
        && ([self.searchField.text isEqualToString:@""] || self.searchField.text == nil)) {
        
        self.addFoodSearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld&prep=%@",
                                    self.addFoodCategory,
                                    @"",
                                    self.inTemplateString,
                                    (long)self.relaunchItemID,
                                    prepString];
        
    } else if ([self.addFoodCategory isEqualToString:@"template"]
               && self.relaunchItemID > 0
               && ![self.searchField.text isEqualToString:@""] && self.searchField.text != nil) {
        
        self.addFoodSearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld&prep=%@",
                                    self.addFoodCategory,
                                    [appDelegate cleanStringBeforeSending:self.searchField.text],
                                    self.inTemplateString,
                                    (long)self.relaunchItemID,
                                    prepString];
    }
    
    // new generalFoodSearch stuff
    
    if ([self.addFoodCategory isEqualToString:@"general"]) {
        
        // re-searching the same terms
        if ([self.addFoodSearchFieldString isEqualToString:@""] ||
            ![self.addFoodSearchFieldString isEqualToString:self.generalFoodSearchString]) {
            
            self.generalFoodSearchPhase = 1;
            
        }
        
        self.generalFoodSearchString = self.addFoodSearchFieldString;
    }
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_search_results&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&generalFoodSearchPhase=%ld&%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.generalFoodSearchPhase,
                       self.addFoodSearchString];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)submitSearchRequest:(NSString *) url withState:(BOOL) urlState {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFavorite = NO;
    self.doneSubmittingSearchRequest = YES;
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=submit_search_request&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&search=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, [appDelegate cleanStringBeforeSending:self.searchField.text]];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)deleteFavorite:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneSubmittingSearchRequest = NO;
    self.doneDeletingFavorite = YES; // after the item is deleted
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_delete_favorite&WhichID=%ld&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", (long)self.selectedFoodID, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)showSearchResults {
    
    NSArray *viewsToRemove = [self.addFoodSearchResultsScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    [self.searchFieldContainer removeFromSuperview];
    [self.exchangeMessageContainer removeFromSuperview];
    [self.numberOfResultsContainer removeFromSuperview];
    [self.prepEffortContainer removeFromSuperview];
    [self.generalFoodSearchContainer removeFromSuperview];
    
    int screenWidth = self.view.frame.size.width;
  
    NSInteger vPos = 0;
    NSInteger hPos = 0;
    NSInteger searchResultsContainerHeight = 62;

    UIButton *searchResultsContainer;
    
    UIView *graySeparator;

    UILabel *foodTitle;
    UILabel *foodSubTitle;
    
    UIFont *foodTitleFont = [UIFont fontWithName:@"Avenir-Light" size:16.0];
    UIFont *foodSubTitleFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:12.0];

    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    UIColor *foodSubTitleFontColor = [UIColor colorWithRed:(166/255.0) green:(179/255.0) blue:(186/255.0) alpha:1.0];
    
    // prep effort
    
    if ([self.addFoodCategory isEqualToString:@"template"] && self.isExchangeItem == NO) {
        
        hPos = 16;
        
        UILabel *searchLabel;
        
        UIButton *checkBox;
        
        UIFont *searchCriteriaFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
        UIFont *checkBoxLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
        
        self.prepEffortContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, 70)];
        
        [self.prepEffortContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.prepEffortContainer addSubview:graySeparator];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
        
        [searchLabel setFont:searchCriteriaFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Preparation Effort"];
        
        [self.prepEffortContainer addSubview:searchLabel];
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.prepCheckboxRTEChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:5];
        
        [self.prepEffortContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Ready to Eat"];
        [searchLabel sizeToFit];
        
        [self.prepEffortContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 4) + 28);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.prepCheckboxLowChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:6];
        
        [self.prepEffortContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Low"];
        [searchLabel sizeToFit];
        
        [self.prepEffortContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 4) - 15);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.prepCheckboxMediumChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:7];
        
        [self.prepEffortContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Medium"];
        [searchLabel sizeToFit];
        
        [self.prepEffortContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 4) + 6);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.prepCheckboxHighChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:8];
        
        [self.prepEffortContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"High"];
        [searchLabel sizeToFit];
        
        [self.prepEffortContainer addSubview:searchLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.prepEffortContainer addSubview:graySeparator];
        
        [self.view addSubview:self.prepEffortContainer];
    }
    
    // search
    
    if (([self.addFoodCategory isEqualToString:@"general"]
        || [self.addFoodCategory isEqualToString:@"template"])
        && self.isExchangeItem == NO) {
        
        if ([self.addFoodCategory isEqualToString:@"template"] && self.isExchangeItem == NO) {
            
            self.searchFieldContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 128, screenWidth, searchResultsContainerHeight)];
            
        } else {
            
            self.searchFieldContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, screenWidth, searchResultsContainerHeight)];
        }
        
        [self.searchFieldContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.searchFieldContainer addSubview:graySeparator];
        
        self.searchField = [[HTTextField alloc]
                            initHTDefaultWithFrame:CGRectMake(16, 19, (screenWidth - 32), 24)];
        
        [self.searchField setTextAlignment:NSTextAlignmentLeft];
        [self.searchField setClearButtonMode:UITextFieldViewModeWhileEditing];
        [self.searchField setKeyboardType:UIKeyboardTypeASCIICapable];
        
        /*
        if (![self.addFoodCategory isEqualToString:@"general"]) {
            
            [self.searchField addTarget:self
                                 action:@selector(textFieldDidChange:)
                       forControlEvents:UIControlEventEditingChanged];
        }
        */
        
        self.searchField.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
        
        UIColor *color = [UIColor colorWithRed:(117/255.0)
                                         green:(124/255.0)
                                          blue:(128/255.0)
                                         alpha:0.6];
        
        self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: color}];
        
        self.searchField.text = self.addFoodSearchFieldString;
        
        [self.searchFieldContainer addSubview:self.searchField];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + (searchResultsContainerHeight - 4), screenWidth, 4)];
        
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.searchFieldContainer addSubview:graySeparator];
        
        [self.view addSubview:self.searchFieldContainer];
        
        vPos += searchResultsContainerHeight;
    }
    
    // exchange item!
    
    if (self.isExchangeItem == YES) {
        
        self.exchangeMessageContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, screenWidth, searchResultsContainerHeight)];
        
        [self.exchangeMessageContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.exchangeMessageContainer addSubview:graySeparator];
        
        self.exchangeMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 17, (screenWidth - 32), 30)];
        
        [self.exchangeMessageLabel setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0]];
        [self.exchangeMessageLabel setTextColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
        [self.exchangeMessageLabel setTextAlignment:NSTextAlignmentCenter];
        
        if (self.exchangeItemsAllowed == 0) { // limitless exchange icon
            
            if (self.exchangeItemsSelected == 1) {
                
                [self.exchangeMessageLabel setText:@"1 item selected"];
                
            } else {
                
                [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f items selected",
                                    (float)self.exchangeItemsSelected]];
            }
            
        } else { // traditional exchange item
            
            if (self.exchangeItemsAllowed == 1) {
                
                [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f of 1 item selected",
                                    (float)self.exchangeItemsSelected]];
                
            } else {
                
                [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f of %ld items selected",
                                    (float)self.exchangeItemsSelected,
                                    (long)self.exchangeItemsAllowed]];
            }
        }
        
        [self.exchangeMessageContainer addSubview:self.exchangeMessageLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.exchangeMessageContainer addSubview:graySeparator];
        
        [self.view addSubview:self.exchangeMessageContainer];
    }
    
    // number of search results
    
    if (!([self.addFoodCategory isEqualToString:@"general"]
          && [self.addFoodSearchFieldString isEqualToString:@""])
        && ![self.addFoodCategory isEqualToString:@"template"]
        && ![self.addFoodCategory isEqualToString:@"exchange"]) {
        
        if ([self.addFoodCategory isEqualToString:@"general"]) {
            
            self.numberOfResultsContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 122, screenWidth, searchResultsContainerHeight)];
            
        } else {
            
            self.numberOfResultsContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 64, screenWidth, searchResultsContainerHeight)];
        }
        
        [self.numberOfResultsContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.numberOfResultsContainer addSubview:graySeparator];
        
        if (self.numberOfResults == 200 && ![self.addFoodCategory isEqualToString:@"general"]) {
            
            [self.numberOfResultsContainer addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            
            foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, (screenWidth - 32), 30)];
            
        } else if (self.numberOfResults == 50 && [self.addFoodCategory isEqualToString:@"general"] &&
                   self.generalFoodSearchPhase == 1) {
            
            foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, (screenWidth - 32), 30)];
            
        } else {
            
            foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 17, (screenWidth - 32), 30)];
        }
        
        [foodTitle setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0]];
        [foodTitle setTextColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
        [foodTitle setTextAlignment:NSTextAlignmentCenter];
        
        if ((self.numberOfResults == 200 && ![self.addFoodCategory isEqualToString:@"general"]) ||
            (self.numberOfResults == 50 && [self.addFoodCategory isEqualToString:@"general"] &&
             self.generalFoodSearchPhase == 1)) {
                
                [foodTitle setText:[NSString stringWithFormat:@"Top %ld results", (long)self.numberOfResults]];
                
            } else {
                
                [foodTitle setText:[NSString stringWithFormat:@"%ld results", (long)self.numberOfResults]];
            }
        
        [self.numberOfResultsContainer addSubview:foodTitle];
        
        if ((self.numberOfResults == 200 && ![self.addFoodCategory isEqualToString:@"general"]) ||
            (self.numberOfResults == 50 && [self.addFoodCategory isEqualToString:@"general"] &&
             self.generalFoodSearchPhase == 1)) {
                
                foodSubTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, (screenWidth - 32), 20)];
                
                [foodSubTitle setFont:foodSubTitleFont];
                [foodSubTitle setTextColor:foodSubTitleFontColor];
                [foodSubTitle setTextAlignment:NSTextAlignmentCenter];
                [foodSubTitle setText:@"Refine search to narrow results"];
                
                [self.numberOfResultsContainer addSubview:foodSubTitle];
            }
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.numberOfResultsContainer addSubview:graySeparator];
        
        [self.view addSubview:self.numberOfResultsContainer];
    }
    
    // general food search phase II
    
    if ([self.addFoodCategory isEqualToString:@"general"] && ![self.addFoodSearchFieldString isEqualToString:@""]
        && self.generalFoodSearchPhase == 1) {
        
        self.generalFoodSearchContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 184, screenWidth, searchResultsContainerHeight)];
        
        [self.generalFoodSearchContainer setBackgroundColor:[UIColor whiteColor]];
        
        [self.generalFoodSearchContainer addTarget:self action:@selector(generalFoodSearchPhaseII) forControlEvents:UIControlEventTouchUpInside];
        
        foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 15, (screenWidth - 32), 30)];
        
        [foodTitle setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0]];
        [foodTitle setTextColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
        [foodTitle setTextAlignment:NSTextAlignmentCenter];
        
        [foodTitle setText:[NSString stringWithFormat:@"Or tap here to expand this search"]];
        
        [self.generalFoodSearchContainer addSubview:foodTitle];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.generalFoodSearchContainer addSubview:graySeparator];
        
        [self.view addSubview:self.generalFoodSearchContainer];
        
        vPos += searchResultsContainerHeight - 4;
        
    } else if ([self.addFoodCategory isEqualToString:@"general"]
               && ![self.addFoodSearchFieldString isEqualToString:@""]
               && (self.generalFoodSearchPhase == 2 || self.generalFoodSearchPhase == 3)) {
        
        self.generalFoodSearchContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 184, screenWidth, searchResultsContainerHeight)];
        
        [self.generalFoodSearchContainer setBackgroundColor:[UIColor whiteColor]];
        
        [self.generalFoodSearchContainer addTarget:self action:@selector(generalFoodSearchSubmitRequest) forControlEvents:UIControlEventTouchUpInside];
        
        foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 5, (screenWidth - 32), 30)];
        
        [foodTitle setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0]];
        [foodTitle setTextColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
        [foodTitle setTextAlignment:NSTextAlignmentCenter];
        
        [foodTitle setText:[NSString stringWithFormat:@"Not finding what you're looking for?"]];
        
        [self.generalFoodSearchContainer addSubview:foodTitle];
        
        foodSubTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 29, (screenWidth - 32), 20)];
        
        [foodSubTitle setFont:foodSubTitleFont];
        [foodSubTitle setTextColor:foodSubTitleFontColor];
        [foodSubTitle setTextAlignment:NSTextAlignmentCenter];
        [foodSubTitle setText:@"Tap to submit search to our research department"];
        
        [self.generalFoodSearchContainer addSubview:foodSubTitle];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.generalFoodSearchContainer addSubview:graySeparator];
        
        [self.view addSubview:self.generalFoodSearchContainer];
        
        vPos += searchResultsContainerHeight - 4;
    }
    
    // search results
    
    NSString *thisExchangeItemQuantity;
    NSString *thisExchangeItemNumber;
    NSString *thisExchangeItemNumberFraction;
    
    UILongPressGestureRecognizer *longPress;
    
    for (int i=1; i<=[self.addFoodID count] - 1; i++) {
        
        hPos = 16;

        searchResultsContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, searchResultsContainerHeight)];
        
        if (self.isExchangeItem == YES) {
            
            // nothing
            
        } else {
            
            [searchResultsContainer addTarget:self action:@selector(selectFoodItem:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [searchResultsContainer setTag:i];
        
        if (self.isExchangeItem == YES) {
        
            UIPickerView *quantityPickerView = [[UIPickerView alloc] init];
            
            quantityPickerView = [[UIPickerView alloc] init];
            
            quantityPickerView.tag = i + 1000;
            quantityPickerView.delegate = self;
            quantityPickerView.showsSelectionIndicator = YES;
            
            HTTextField *quantityTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(hPos, 13, 60, 32)];
            
            quantityTextField.tag = i + 2000;
            
            [quantityTextField setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
            [quantityTextField setTextColor:[UIColor colorWithRed:(117/255.0)
                                                                 green:(124/255.0)
                                                                  blue:(128/255.0)
                                                                 alpha:1.0]];
            
            [quantityTextField setTextAlignment:NSTextAlignmentRight];

            if ([self.exchangeItemArray containsObject:[self.addFoodID objectAtIndex:i]]) {
                
                thisExchangeItemQuantity = [self.exchangeItemQuantitiesArray
                                          objectAtIndex:[self.exchangeItemArray indexOfObject:[self.addFoodID objectAtIndex:i]]];
                
                thisExchangeItemNumber = [thisExchangeItemQuantity
                                                   substringToIndex:[thisExchangeItemQuantity rangeOfString:@"."].location];
                
                thisExchangeItemNumberFraction = [thisExchangeItemQuantity
                                                   substringFromIndex:[thisExchangeItemQuantity rangeOfString:@"."].location];
                
                [quantityPickerView selectRow:[self.quantityPickerValues indexOfObject:thisExchangeItemNumber] inComponent:0 animated:YES];
        
                [quantityPickerView selectRow:[self.quantityPickerValueFractions indexOfObject:thisExchangeItemNumberFraction] inComponent:1 animated:YES];
        
                quantityTextField.text = [NSString stringWithFormat:@"%@%@", thisExchangeItemNumber,
                                               thisExchangeItemNumberFraction];
                
            } else {
                
                [quantityPickerView selectRow:0 inComponent:0 animated:YES];
                
                [quantityPickerView selectRow:0 inComponent:1 animated:YES];
                
                quantityTextField.text = @"0.00";
            }
            
            quantityTextField.delegate = self;
            quantityTextField.inputView = quantityPickerView;
            
            UIToolbar *toolBar;
            
            UIBarButtonItem *barButtonDone;
            UIBarButtonItem *flex;
            
            toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            [toolBar setBarTintColor:[UIColor whiteColor]];
            
            barButtonDone = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                             style:UIBarButtonItemStylePlain target:self action:@selector(doneWithPicker:)];
            barButtonDone.tag = i + 3000;
            
            flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
            
            [barButtonDone setTitleTextAttributes:@{NSFontAttributeName:
                                                        [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0],
                                                    NSForegroundColorAttributeName: [UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]} forState:UIControlStateNormal];
            
            toolBar.items = [[NSArray alloc] initWithObjects:flex, barButtonDone, nil];
            
            quantityTextField.inputAccessoryView = toolBar;
            
            [searchResultsContainer addSubview:quantityTextField];
            
            hPos += 70;
        }
        
        if (![[self.addFoodCalories objectAtIndex:i] isEqualToString:@""]) {
            
            foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(hPos, 6, (screenWidth - (hPos + 16)), 30)];
            
        } else {
        
            foodTitle = [[UILabel alloc] initWithFrame:CGRectMake(hPos, 15, (screenWidth - (hPos + 16)), 30)];
        }
    
        [foodTitle setFont:foodTitleFont];
        [foodTitle setTextColor:grayFontColor];
        [foodTitle setTextAlignment:NSTextAlignmentLeft];
        [foodTitle setText:[[self.addFoodName objectAtIndex:i] capitalizedString]];
        
        [searchResultsContainer addSubview:foodTitle];
    
        if (![[self.addFoodCalories objectAtIndex:i] isEqualToString:@""]) {
            
            foodSubTitle = [[UILabel alloc] initWithFrame:CGRectMake(hPos, 30, (screenWidth - (hPos + 16)), 20)];
            
            [foodSubTitle setFont:foodSubTitleFont];
            [foodSubTitle setTextColor:foodSubTitleFontColor];
            [foodSubTitle setTextAlignment:NSTextAlignmentLeft];
            
            if ([self.addFoodCategory isEqualToString:@"general"] &&
                ![[self.addFoodServings objectAtIndex:i] isEqualToString:@""]) {
               
                [foodSubTitle setText:[NSString stringWithFormat:@"%@ %@ - %@",
                                       [self.addFoodCalories objectAtIndex:i],
                                       self.caloriesOrOtherString,
                                       [self.addFoodServings objectAtIndex:i]]];
            
            } else {
                
                [foodSubTitle setText:[NSString stringWithFormat:@"%@ %@", [self.addFoodCalories objectAtIndex:i], self.caloriesOrOtherString]];
            }
            
            [searchResultsContainer addSubview:foodSubTitle];
        }
            
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [searchResultsContainer addSubview:graySeparator];
        
        if ([self.addFoodCategory isEqualToString:@"favorites"]) {
            
            longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(deleteFavoriteItem:)];
            [searchResultsContainer addGestureRecognizer:longPress];
        }
        
        [self.addFoodSearchResultsScrollView addSubview:searchResultsContainer];
        
        vPos += searchResultsContainerHeight;
    }
    
    [self.addFoodSearchResultsScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
    
    self.allowSelections = YES;
    
    if (self.searchField && [self.addFoodCategory isEqualToString:@"general"] &&
        [self.searchField.text stringByTrimmingCharactersInSet:
         [NSCharacterSet whitespaceCharacterSet]].length == 0) {
        
        [self.searchField becomeFirstResponder];
    }
}

- (UIBarButtonItem *)backButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-back-arrow"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (UIBarButtonItem *) checkButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-check"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(checkButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)checkButtonPressed {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([self.addFoodCategory isEqualToString:@"general"]) {
        
        self.addFoodSearchFieldString = self.searchField.text;
        
        self.addFoodSearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld&prep=%@",
                                    self.addFoodCategory,
                                    [appDelegate cleanStringBeforeSending:self.searchField.text],
                                    self.inTemplateString,
                                    (long)self.relaunchItemID,
                                    @""];
        
        [self getSearchResults:HTWebSvcURL withState:0];
        
    } else if ([self.addFoodCategory isEqualToString:@"template"] && self.isExchangeItem == NO) {
        
        self.addFoodSearchFieldString = self.searchField.text;
        
        NSMutableString *prepString = [[NSMutableString alloc] initWithString:@""];
        
        if (self.prepCheckboxRTEChecked == YES) {
            
            [prepString appendString:@"R,"];
        }
        
        if (self.prepCheckboxLowChecked == YES) {
            
            [prepString appendString:@"L,"];
        }
        
        if (self.prepCheckboxMediumChecked == YES) {
            
            [prepString appendString:@"M,"];
        }
        
        if (self.prepCheckboxHighChecked == YES) {
            
            [prepString appendString:@"H,"];
        }
        
        if ([prepString length] != 0) {
            
            NSRange prepStringRange = NSMakeRange(0, [prepString length] - 1);
            
            prepString = [NSMutableString stringWithString:[prepString substringWithRange:prepStringRange]];
        }
        
        self.addFoodSearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld&prep=%@",
                                    self.addFoodCategory,
                                    [appDelegate cleanStringBeforeSending:self.searchField.text],
                                    self.inTemplateString,
                                    (long)self.relaunchItemID,
                                    prepString];
        
        [self getSearchResults:HTWebSvcURL withState:0];
        
    } else {
        
        [self chooseExchangeItems];
    }
}

- (void)generalFoodSearchPhaseII {
    
    self.generalFoodSearchPhase = 2;
    
    [self getSearchResults:HTWebSvcURL withState:0];
}

- (void)generalFoodSearchSubmitRequest {
    
    NSString *alertString = [NSString stringWithFormat:@"We're sorry you couldn't find what you were searching for.\n\nYour request for '%@' has been submitted to our research department.\n\nYou should receive an email from us within one business day.", self.searchField.text];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Search Request Submitted"
                                                        message:alertString
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    
    self.generalFoodSearchPhase = 1;
    
    [self submitSearchRequest:HTWebSvcURL withState:0];
}

- (void)selectFoodItem:(id)sender {
    
    if (self.allowSelections == YES) {
        
        UIButton *button = sender;
        
        self.selectedFoodID = button.tag;
        
        if (self.generalFoodSearchPhase == 2) {
            
            self.generalFoodSearchPhase = 3; // so we do not force the web scrape again - be done with it, submit a request if necessary
        }
        
        [self performSegueWithIdentifier:@"showFoodSearchSelectItem" sender:self];
    }
}

- (void)chooseExchangeItems {
    
    if (self.exchangeItemsSelected > self.exchangeItemsAllowed && self.exchangeItemsAllowed != 0) {
        
        NSString *alertString;
        
        if (self.exchangeItemsAllowed == 1) {
            
            alertString = @"Please choose 1 item or less";
            
        } else {
            
            alertString = [NSString stringWithFormat:@"Please choose %ld items or less", (long)self.exchangeItemsAllowed];
        }
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
    } else {
        
        UITextField *quantityTextField;
        
        for (int i=1; i<=self.numberOfResults; i++) {
            
            quantityTextField = (UITextField*)[self.view viewWithTag:(i + 2000)];
            
            if ([quantityTextField.text floatValue] != 0.00) {
                
                [self.exchangeItemsString appendString:[NSString stringWithFormat:@"%@||%.2f}",
                                                        [self.addFoodID objectAtIndex:(i)],
                                                        [quantityTextField.text floatValue]]];
            }
        }
        
        [self performSegueWithIdentifier:@"showFoodSearchSelectItem" sender:self];
    }
}

- (IBAction) checkBoxChecked:(id)sender {
    
    UIButton *button = sender;
    
    switch (button.tag) {
        case 5:
            
            if (self.prepCheckboxRTEChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxRTEChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxRTEChecked = NO;
            }
            
            break;
            
        case 6:
            
            if (self.prepCheckboxLowChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxLowChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxLowChecked = NO;
            }
            
            break;
            
        case 7:
            
            if (self.prepCheckboxMediumChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxMediumChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxMediumChecked = NO;
            }
            
            break;
            
        case 8:
            
            if (self.prepCheckboxHighChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxHighChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.prepCheckboxHighChecked = NO;
            }
            
            break;
            
        default:
            break;
    }
    
    [self getSearchResults:HTWebSvcURL withState:0];
}

- (void)doneWithPicker:(id)sender {
    
    UIBarButtonItem *barButtonItem = sender;

    UITextField *quantityTextField = (UITextField*)[self.view viewWithTag:(barButtonItem.tag - 1000)];
    
    [quantityTextField resignFirstResponder];
}

- (void)deleteFavoriteItem:(id)sender {
    
    UILongPressGestureRecognizer *recognizer = sender;
    
    self.selectedFoodID = [[self.addFoodID objectAtIndex:recognizer.view.tag] integerValue];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Edit or Delete Favorite?" message:@"Would you like to edit or delete this My Favorites item?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Edit", @"Delete", nil];
        
        [alertView show];
    }
}

#pragma mark - UITextView delegate methods

- (void)textFieldDidChange:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        
    self.addFoodSearchFieldString = self.searchField.text;
    
    NSMutableString *prepString = [[NSMutableString alloc] initWithString:@""];
    
    if ([self.addFoodCategory isEqualToString:@"template"]) {
        
        if (self.prepCheckboxRTEChecked == YES) {
            
            [prepString appendString:@"R,"];
        }
        
        if (self.prepCheckboxLowChecked == YES) {
            
            [prepString appendString:@"L,"];
        }
        
        if (self.prepCheckboxMediumChecked == YES) {
            
            [prepString appendString:@"M,"];
        }
        
        if (self.prepCheckboxHighChecked == YES) {
            
            [prepString appendString:@"H,"];
        }
        
        if ([prepString length] != 0) {
            
            NSRange prepStringRange = NSMakeRange(0, [prepString length] - 1);
            
            prepString = [NSMutableString stringWithString:[prepString substringWithRange:prepStringRange]];
        }
    }
    
    self.addFoodSearchString = [NSString
                                stringWithFormat:@"WhichCategory=%@&search=%@&template=%@&relaunch=%ld&prep=%@",
                                self.addFoodCategory,
                                [appDelegate cleanStringBeforeSending:self.searchField.text],
                                self.inTemplateString,
                                (long)self.relaunchItemID,
                                prepString];
    
    [self getSearchResults:HTWebSvcURL withState:0];
}

#pragma  mark - UIPickerView delegate methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow: (NSInteger)row inComponent:(NSInteger)component {
    
    NSString *theQuantity;
    NSString *theFraction;
    
    theQuantity = [self.quantityPickerValues objectAtIndex:[pickerView selectedRowInComponent:0]];
    theFraction = [self.quantityPickerValueFractions objectAtIndex:[pickerView selectedRowInComponent:1]];
    
    UITextField *quantityTextField;
    
    quantityTextField = (UITextField*)[self.view viewWithTag:(pickerView.tag + 1000)];
    
    quantityTextField.text = [NSString stringWithFormat:@"%@%@", theQuantity, theFraction];
    
    self.exchangeItemsSelected = 0.0;
    
    for (int i=1; i<=self.numberOfResults; i++) {
        
        quantityTextField = (UITextField*)[self.view viewWithTag:(i + 2000)];
        
        self.exchangeItemsSelected = self.exchangeItemsSelected + [quantityTextField.text floatValue];
    }
    
    if (self.exchangeItemsAllowed == 0) { // limitless exchange icon
        
        if (self.exchangeItemsSelected == 1) {
            
            [self.exchangeMessageLabel setText:@"1 item selected"];
            
        } else {
            
            [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f items selected",
                                                (float)self.exchangeItemsSelected]];
        }
        
    } else { // traditional exchange item
        
        if (self.exchangeItemsAllowed == 1) {
            
            [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f of 1 item selected",
                                                (float)self.exchangeItemsSelected]];
            
        } else {
            
            [self.exchangeMessageLabel setText:[NSString stringWithFormat:@"%.2f of %ld items selected",
                                                (float)self.exchangeItemsSelected,
                                                (long)self.exchangeItemsAllowed]];
        }
    }
}

// tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (component == 0) {  // numbers
        
        return 17;
        
    } else { // fractions
        
        return 4;
    }

}

// tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 2;
}

// tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    NSString *title;
    
    if (component == 0) { // numbers
        
        title = [self.quantityPickerValues objectAtIndex:row];
        
    } else { // fractions
        
        title = [self.quantityPickerValueFractions objectAtIndex:row];
    }

    return title;
}

// tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    
    return 42;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *pickerLabel = (UILabel*)view;
    
    if (!pickerLabel) {
        
        pickerLabel = [[UILabel alloc] init];
        
        [pickerLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:18]];
        [pickerLabel setTextColor:[UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0]];
        [pickerLabel setTextAlignment:NSTextAlignmentCenter];
    }
    
    if (component == 0) {
        
        pickerLabel.text = [self.quantityPickerValues objectAtIndex:row];
        
    } else {
        
        pickerLabel.text = [self.quantityPickerValueFractions objectAtIndex:row];
    }

    return pickerLabel;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) { // edit
        
        [self performSegueWithIdentifier:@"showEditFavoriteFromAddFood" sender:self];
        
    } else if (buttonIndex == 2) { // delete
        
        [self deleteFavorite:HTWebSvcURL withState:0];
    }
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([self.xmlData length]) {
        
        self.xmlParser = [[NSXMLParser alloc] initWithData:self.xmlData];
        
        [self.xmlParser setDelegate:self];
        [self.xmlParser setShouldProcessNamespaces:NO];
        [self.xmlParser setShouldReportNamespacePrefixes:NO];
        [self.xmlParser setShouldResolveExternalEntities:NO];
        [self.xmlParser parse];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self handleURLError:error];
    
    self.sphConnection = nil;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    [self.addFoodID removeAllObjects];
    [self.addFoodName removeAllObjects];
    [self.addFoodCalories removeAllObjects];
    [self.addFoodServings removeAllObjects];
    
    [self.addFoodID insertObject:@"" atIndex:0];
    [self.addFoodName insertObject:@"" atIndex:0];
    [self.addFoodCalories insertObject:@"" atIndex:0];
    [self.addFoodServings insertObject:@"" atIndex:0];
    
    self.selectedFoodID = 0;
    self.numberOfResults = 0;
    
    self.isExchangeItem = NO;
    
    self.exchangeItemsAllowed = 0;
    self.exchangeItemsSelected = 0;
    
    self.caloriesOrOtherString = @"calories";
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    self.showConnError = YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    
    self.currentElement = elementName;
    self.currentValue = [[NSMutableString alloc] init];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *cleanString = [[NSString alloc] init];
    
    cleanString = [appDelegate cleanStringAfterReceiving:self.currentValue];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName hasPrefix:@"food_id_"]) {
        
        [self.addFoodID insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"food_id_" withString:@""]
                                                                integerValue]];
        
        self.numberOfResults = self.numberOfResults + 1;
        
    } else if ([elementName hasPrefix:@"food_name_"]) {
        
        [self.addFoodName insertObject:cleanString atIndex:[[elementName stringByReplacingOccurrencesOfString:@"food_name_" withString:@""]
                                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"food_calories_"]) {
        
        [self.addFoodCalories insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"food_calories_" withString:@""]
                                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"food_servings_"]) {
        
        [self.addFoodServings insertObject:cleanString atIndex:[[elementName stringByReplacingOccurrencesOfString:@"food_servings_" withString:@""]
                                                                integerValue]];
        
    } else if ([elementName isEqualToString:@"exchange_number"]) {
        
        self.isExchangeItem = YES;
        
        self.exchangeItemsAllowed = [cleanString floatValue];
        
    } else if ([elementName isEqualToString:@"exchange_number_selected"]) {
        
        self.exchangeItemsSelected = [cleanString floatValue];
        
    } else if ([elementName isEqualToString:@"exchange_array"]) {
        
        self.exchangeItemArray = [cleanString componentsSeparatedByString:@","];
        
    } else if ([elementName isEqualToString:@"exchange_array_quantities"]) {
        
        self.exchangeItemQuantitiesArray = [cleanString componentsSeparatedByString:@","];
        
    } else if ([elementName isEqualToString:@"calories_or_other_string"]) {
        
        self.caloriesOrOtherString = cleanString;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.currentValue appendString:[appDelegate cleanStringAfterReceiving:string]];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        if (self.isExchangeItem == YES) {
            
            self.navigationItem.rightBarButtonItem = [self checkButton];
            self.addFoodCategory = @"exchange";
            
        } else if (([self.addFoodCategory isEqualToString:@"general"]
                    || [self.addFoodCategory isEqualToString:@"template"])
                   && self.isExchangeItem == NO) {
            
            self.navigationItem.rightBarButtonItem = [self checkButton];
            
        } else {
            
            self.navigationItem.rightBarButtonItem = nil;
        }
        
        if (self.doneDeletingFavorite == YES) {
            
            [self getSearchResults:HTWebSvcURL withState:0];
            
        } else if (self.doneSubmittingSearchRequest == YES) {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
        } else {
            
            [self showSearchResults];
        }

    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    if ([segue.identifier isEqualToString:@"showEditFavoriteFromAddFood"]) {
    
        HTCreateFavoritesViewController *viewController = segue.destinationViewController;
        
        viewController.hidesBottomBarWhenPushed = YES;
        viewController.selectedFavoriteRelaunchItem = @"true";
        viewController.relaunchItemID = self.selectedFoodID;
        
    } else {
    
        HTAddFoodSelectItemViewController *viewController = segue.destinationViewController;

        viewController.hidesBottomBarWhenPushed = YES;

        viewController.addFoodCategory = self.addFoodCategory;
        viewController.selectedFoodID = [[self.addFoodID objectAtIndex:self.selectedFoodID] integerValue];
        
        if (self.relaunchItemID > 0) {
            
            viewController.relaunchPlannerItem = YES;
            viewController.relaunchItemID = self.relaunchItemID;
            
        } else {
        
            viewController.relaunchPlannerItem = NO;
        }
        
        if ([self.inTemplateString isEqualToString:@"true"]) {
            
            viewController.inTemplateString = @"true";
            
        } else {
            
            viewController.inTemplateString = @"";
        }
        
        if (self.isExchangeItem == YES) {
            
            viewController.inTemplateString = @"true";
            viewController.addFoodCategory = @"exchange";
            viewController.exchangeItemsString = self.exchangeItemsString;
        }
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
