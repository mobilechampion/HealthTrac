//
//  HTAddActivityExerciseSearchViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddActivitySearchViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTAddActivitySelectItemViewController.h"

@interface HTAddActivitySearchViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddActivitySearchViewController

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
    
    self.addActivitySearchFieldString = @"";
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
    
    if ([self.addActivityCategory isEqualToString:@"exercise"]) {
        
        self.title = @"Exercise";
        
    } else if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
        self.title = @"My Favorites";
        
    } else {
        
        self.title = @"Add Activity";
    }
    
//    NSArray *viewsToRemove = [self.addActivitySearchResultsScrollView subviews];
//    
//    for (UIView *v in viewsToRemove) {
//        
//        [v removeFromSuperview];
//    }
    
    if ([self.addActivityCategory isEqualToString:@"exercise"]) {
        
        self.navigationItem.rightBarButtonItem = [self newExerciseButton];
     
    } else {
        
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    if ([self.addActivitySearchFieldString isEqualToString:@""]
        && ![self.addActivityCategory isEqualToString:@"favorites"]) {
        
        self.addActivityID = [[NSMutableArray alloc] init];
        
        [self.addActivityID insertObject:@"" atIndex:0];
        
        [self showSearchResults];
        
    } else {
        
        [self getSearchResults:HTWebSvcURL withState:0];
    }
}

#pragma mark - Methods

- (void)getSearchResults:(NSString *) url withState:(BOOL) urlState {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneDeletingFavorite = NO;
    
    self.addActivityID = [[NSMutableArray alloc] init];
    self.addActivityName = [[NSMutableArray alloc] init];
    self.addActivityType = [[NSMutableArray alloc] init];
    
    self.selectedActivityID = 0;
    
    self.addActivitySearchFieldString = self.searchField.text;
    
    if (self.addActivitySearchFieldString == nil) {
        
        self.addActivitySearchFieldString = @"";
    }
    
    NSMutableString *favoritesTypeString = [[NSMutableString alloc] initWithString:@""];
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
        if (self.favoritesTypeExerciseChecked == YES) {
            
            [favoritesTypeString appendString:@"M,"];
        }
        
        if (self.favoritesTypeBalanceChecked == YES) {
            
            [favoritesTypeString appendString:@"BAL,"];
        }
        
        if (self.favoritesTypeNoteChecked == YES) {
            
            [favoritesTypeString appendString:@"NOTE,"];
        }
        
        if ([favoritesTypeString length] != 0) {
            
            NSRange favoritesTypeStringRange = NSMakeRange(0, [favoritesTypeString length] - 1);
            
            favoritesTypeString = [NSMutableString stringWithString:[favoritesTypeString substringWithRange:favoritesTypeStringRange]];
        }
    }

    self.addActivitySearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&relaunch=%ld&type=%@",
                                    self.addActivityCategory,
                                    [appDelegate cleanStringBeforeSending:self.addActivitySearchFieldString],
                                    (long)self.relaunchItemID,
                                    favoritesTypeString];
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_activity_search_results&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.addActivitySearchString];
    
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
    self.doneDeletingFavorite = YES; // after the item is deleted
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_activity_delete_favorite&WhichID=%ld&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", (long)self.selectedActivityID, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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
    
    NSArray *viewsToRemove = [self.addActivitySearchResultsScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    [self.numberOfResultsContainer removeFromSuperview];
    [self.favoritesTypeContainer removeFromSuperview];
    [self.searchFieldContainer removeFromSuperview];
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 0;
    NSInteger hPos = 0;
    NSInteger searchResultsContainerHeight = 62;
    
    UIButton *searchResultsContainer;
    
    UIView *graySeparator;
    
    UILabel *activityTitle;
    UILabel *activitySubTitle;
    
    UIImageView *activityImage;
    
    UIFont *activityTitleFont = [UIFont fontWithName:@"Avenir-Light" size:16.0];
    UIFont *activitySubTitleFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:12.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    UIColor *activitySubTitleFontColor = [UIColor colorWithRed:(166/255.0) green:(179/255.0) blue:(186/255.0) alpha:1.0];
    
    // favorites type
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
        hPos = 16;
        
        UILabel *searchLabel;
        
        UIButton *checkBox;
        
        UIFont *searchCriteriaFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
        UIFont *checkBoxLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
        
        self.favoritesTypeContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, 70)];
        
        [self.favoritesTypeContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.favoritesTypeContainer addSubview:graySeparator];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
        
        [searchLabel setFont:searchCriteriaFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Type"];
        
        [self.favoritesTypeContainer addSubview:searchLabel];
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.favoritesTypeExerciseChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:1];
        
        [self.favoritesTypeContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Exercise"];
        [searchLabel sizeToFit];
        
        [self.favoritesTypeContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 3) - 10);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.favoritesTypeBalanceChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:2];
        
        [self.favoritesTypeContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Stress Management"];
        [searchLabel sizeToFit];
        
        [self.favoritesTypeContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 3) + 50);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if (self.favoritesTypeNoteChecked == YES) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:3];
        
        [self.favoritesTypeContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Note"];
        [searchLabel sizeToFit];
        
        [self.favoritesTypeContainer addSubview:searchLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.favoritesTypeContainer addSubview:graySeparator];
        
        [self.view addSubview:self.favoritesTypeContainer];
    }
    
    // search
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
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
    
    [self.searchField addTarget:self
                         action:@selector(textFieldDidChange:)
               forControlEvents:UIControlEventEditingChanged];
    
    self.searchField.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *color = [UIColor colorWithRed:(117/255.0)
                                     green:(124/255.0)
                                      blue:(128/255.0)
                                     alpha:0.6];
    
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: color}];
    
    self.searchField.text = self.addActivitySearchFieldString;
    
    [self.searchFieldContainer addSubview:self.searchField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + (searchResultsContainerHeight - 4), screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.searchFieldContainer addSubview:graySeparator];
    
    [self.view addSubview:self.searchFieldContainer];
    
    vPos += searchResultsContainerHeight;
    
    // number of search results
    
    if ([self.addActivityCategory isEqualToString:@"exercise"] && ![self.searchField.text isEqualToString:@""]) {
        
        self.numberOfResultsContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, 122, screenWidth, searchResultsContainerHeight)];
        
        [self.numberOfResultsContainer setBackgroundColor:[UIColor whiteColor]];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.numberOfResultsContainer addSubview:graySeparator];
        
        if (self.numberOfResults == 200) {
            
            activityTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, (screenWidth - 32), 30)];
            
        } else {
            
            activityTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 17, (screenWidth - 32), 30)];
        }
        
        [activityTitle setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0]];
        [activityTitle setTextColor:[UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0]];
        [activityTitle setTextAlignment:NSTextAlignmentCenter];
        
        if (self.numberOfResults == 200) {
            
            [activityTitle setText:[NSString stringWithFormat:@"Top %ld results", (long)self.numberOfResults]];
            
        } else {
            
            [activityTitle setText:[NSString stringWithFormat:@"%ld results", (long)self.numberOfResults]];
        }
        
        [self.numberOfResultsContainer addSubview:activityTitle];
        
        if (self.numberOfResults == 200) {
            
            activitySubTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, (screenWidth - 32), 20)];
            
            [activitySubTitle setFont:activitySubTitleFont];
            [activitySubTitle setTextColor:activitySubTitleFontColor];
            [activitySubTitle setTextAlignment:NSTextAlignmentCenter];
            [activitySubTitle setText:@"Refine search to narrow results"];
            
            [self.numberOfResultsContainer addSubview:activitySubTitle];
        }
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.numberOfResultsContainer addSubview:graySeparator];
        
        [self.view addSubview:self.numberOfResultsContainer];
    }
    
    // search results
    
    UILongPressGestureRecognizer *longPress;
    
    for (int i=1; i<=[self.addActivityID count] - 1; i++) {
        
        hPos = 16;
        
        searchResultsContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, searchResultsContainerHeight)];
        
        [searchResultsContainer addTarget:self action:@selector(selectActivity:) forControlEvents:UIControlEventTouchUpInside];
        
        [searchResultsContainer setTag:i];
        
        if ([self.addActivityCategory isEqualToString:@"favorites"]
            && ![[self.addActivityType objectAtIndex:i] isEqualToString:@""]) {
            
            activityImage = [[UIImageView alloc] initWithFrame:CGRectMake(hPos, (searchResultsContainerHeight / 2) - 12, 20, 20)];
            
            if ([[self.addActivityType objectAtIndex:i] isEqualToString:@"exercise"]) {
                
                [activityImage setImage:[UIImage imageNamed:@"ht-planner-activity"]];
                
            } else if ([[self.addActivityType objectAtIndex:i] isEqualToString:@"stress"]) {
                
                [activityImage setImage:[UIImage imageNamed:@"ht-planner-balance"]];
                
            } else if ([[self.addActivityType objectAtIndex:i] isEqualToString:@"note"]) {
                
                [activityImage setImage:[UIImage imageNamed:@"ht-planner-note"]];
                
            }
            
            [searchResultsContainer addSubview:activityImage];
            
            hPos += 30;
            
        }

        activityTitle = [[UILabel alloc] initWithFrame:CGRectMake(hPos, 15, (screenWidth - (hPos + 16)), 30)];
        
        [activityTitle setFont:activityTitleFont];
        [activityTitle setTextColor:grayFontColor];
        [activityTitle setTextAlignment:NSTextAlignmentLeft];
        [activityTitle setText:[self.addActivityName objectAtIndex:i]];
        
        [searchResultsContainer addSubview:activityTitle];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, searchResultsContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [searchResultsContainer addSubview:graySeparator];
        
        if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
            longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(deleteFavoriteItem:)];
            [searchResultsContainer addGestureRecognizer:longPress];
        }
        
        [self.addActivitySearchResultsScrollView addSubview:searchResultsContainer];
        
        vPos += searchResultsContainerHeight;
    }
    
    [self.addActivitySearchResultsScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
    
    self.allowSelections = YES;
    
    if (self.searchField && ![self.addActivityCategory isEqualToString:@"favorites"]) {
        
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

- (UIBarButtonItem *) newExerciseButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"New" style:UIBarButtonItemStylePlain target:self action:@selector(newExerciseButtonPressed)];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)newExerciseButtonPressed {
    
    self.addActivityCategory = @"exercise";
    
    [self performSegueWithIdentifier:@"showAddActivitySelectItem" sender:self];
}

- (void)selectActivity:(id)sender {
    
    if (self.allowSelections == YES) {
        
        UIButton *button = sender;
        
        self.selectedActivityID = button.tag;
        
        [self performSegueWithIdentifier:@"showAddActivitySelectItem" sender:self];
    }
}

- (IBAction) checkBoxChecked:(id)sender {
    
    UIButton *button = sender;
    
    switch (button.tag) {
        case 1:
            
            if (self.favoritesTypeExerciseChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeExerciseChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeExerciseChecked = NO;
            }
            
            break;
            
        case 2:
            
            if (self.favoritesTypeBalanceChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeBalanceChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeBalanceChecked = NO;
            }
            
            break;
            
        case 3:
            
            if (self.favoritesTypeNoteChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeNoteChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.favoritesTypeNoteChecked = NO;
            }
            
            break;
            
        default:
            break;
    }
    
    [self getSearchResults:HTWebSvcURL withState:0];
}

- (void)deleteFavoriteItem:(id)sender {
    
    UILongPressGestureRecognizer *recognizer = sender;
    
    self.selectedActivityID = [[self.addActivityID objectAtIndex:recognizer.view.tag] integerValue];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Favorite?" message:@"Are you sure you want to delete this item from My Favorites?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        
        [alertView show];
    }
}

#pragma mark - UITextView delegate methods

- (void)textFieldDidChange:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.addActivitySearchFieldString = self.searchField.text;
    
    NSMutableString *favoritesTypeString = [[NSMutableString alloc] initWithString:@""];
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]) {
        
        if (self.favoritesTypeExerciseChecked == YES) {
            
            [favoritesTypeString appendString:@"M,"];
        }
        
        if (self.favoritesTypeBalanceChecked == YES) {
            
            [favoritesTypeString appendString:@"BAL,"];
        }
        
        if (self.favoritesTypeNoteChecked == YES) {
            
            [favoritesTypeString appendString:@"NOTE,"];
        }
        
        if ([favoritesTypeString length] != 0) {
            
            NSRange favoritesTypeStringRange = NSMakeRange(0, [favoritesTypeString length] - 1);
            
            favoritesTypeString = [NSMutableString stringWithString:[favoritesTypeString substringWithRange:favoritesTypeStringRange]];
        }
    }
    
    self.addActivitySearchFieldString = self.searchField.text;
    
    if (self.addActivitySearchFieldString == nil) {
        
        self.addActivitySearchFieldString = @"";
    }
    
    self.addActivitySearchString = [NSString
                                    stringWithFormat:@"WhichCategory=%@&search=%@&relaunch=%ld&type=%@",
                                    self.addActivityCategory,
                                    [appDelegate cleanStringBeforeSending:self.addActivitySearchFieldString],
                                    (long)self.relaunchItemID,
                                    favoritesTypeString];
    
    if ([self.searchField.text length] >= 1) {
        
        [self getSearchResults:HTWebSvcURL withState:0];
        
    } else {
        
        [self.sphConnection cancel]; // stop any previous call to the web service
        
        [self.view hideToastActivity];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        [self.addActivityID removeAllObjects];
        [self.addActivityName removeAllObjects];
        [self.addActivityType removeAllObjects];
        
        [self.addActivityID insertObject:@"" atIndex:0];
        [self.addActivityName insertObject:@"" atIndex:0];
        [self.addActivityType insertObject:@"" atIndex:0];
        
        self.selectedActivityID = 0;
        self.numberOfResults = 0;
        
        [self showSearchResults];
    }
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {
        
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
    
    [self.addActivityID removeAllObjects];
    [self.addActivityName removeAllObjects];
    [self.addActivityType removeAllObjects];
    
    [self.addActivityID insertObject:@"" atIndex:0];
    [self.addActivityName insertObject:@"" atIndex:0];
    [self.addActivityType insertObject:@"" atIndex:0];
    
    self.selectedActivityID = 0;
    self.numberOfResults = 0;
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
        
    } else if ([elementName hasPrefix:@"activity_id_"]) {
        
        [self.addActivityID insertObject:self.currentValue atIndex:[[elementName stringByReplacingOccurrencesOfString:@"activity_id_" withString:@""]
                                                                integerValue]];
        
        self.numberOfResults = [[elementName stringByReplacingOccurrencesOfString:@"activity_id_" withString:@""]
                                integerValue];
        
    } else if ([elementName hasPrefix:@"activity_notes_"]) {
        
        [self.addActivityName insertObject:cleanString atIndex:[[elementName stringByReplacingOccurrencesOfString:@"activity_notes_" withString:@""]
                                                                integerValue]];
        
    } else if ([elementName hasPrefix:@"activity_type_"]) {
        
        [self.addActivityType insertObject:cleanString atIndex:[[elementName stringByReplacingOccurrencesOfString:@"activity_type_" withString:@""]
                                                                integerValue]];
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
        
        if (self.doneDeletingFavorite == YES) {
            
            [self getSearchResults:HTWebSvcURL withState:0];
            
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
    
    HTAddActivitySelectItemViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    
    viewController.addActivityCategory = self.addActivityCategory;
    
    if ([self.addActivityCategory isEqualToString:@"favorites"]
        && ![[self.addActivityType objectAtIndex:self.selectedActivityID] isEqualToString:@""]) {
        
        if ([[self.addActivityType objectAtIndex:self.selectedActivityID] isEqualToString:@"exercise"]) {
            
            viewController.selectedActivityType = @"exercise";
            
        } else if ([[self.addActivityType objectAtIndex:self.selectedActivityID] isEqualToString:@"stress"]) {
            
            viewController.selectedActivityType = @"stress";
            
        } else if ([[self.addActivityType objectAtIndex:self.selectedActivityID]
                    isEqualToString:@"note"]) {
            
            viewController.selectedActivityType = @"note";
        }
    }
    
    viewController.selectedActivityID = [[self.addActivityID objectAtIndex:self.selectedActivityID] integerValue];

    if (self.relaunchItemID > 0) {
        
        viewController.relaunchPlannerItem = YES;
        viewController.relaunchItemID = self.relaunchItemID;
        
    } else {
        
        viewController.relaunchPlannerItem = NO;
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
