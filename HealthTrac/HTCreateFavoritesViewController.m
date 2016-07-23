//
//  HTCreateFavoritesViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/3/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTCreateFavoritesViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTTextView.h"

@interface HTCreateFavoritesViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTCreateFavoritesViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.navigationItem.rightBarButtonItem = [self checkButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
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
    
    self.selectedFavoriteName = @"";
    self.selectedFavoriteType = @"";
    self.selectedFavoritePrep = @"";
    
    self.selectedFavoriteCalories = @"";
    self.selectedFavoriteProtein = @"";
    self.selectedFavoriteCarbs = @"";
    self.selectedFavoriteFat = @"";
    self.selectedFavoriteSatFat = @"";
    self.selectedFavoriteSugars = @"";
    self.selectedFavoriteFiber = @"";
    self.selectedFavoriteSodium = @"";
    
    self.selectedFavoriteDescription = @"";
    self.selectedFavoriteServings = @"";
    self.selectedFavoriteIngredients = @"";
    self.selectedFavoriteDirections = @"";
    self.selectedFavoriteRecommended = @"";
    self.selectedFavoriteComments = @"";
    
    self.showAdditionalFields = NO;
    self.doneAddingFavorite = NO;
    
    self.typeRadioButtonSnackChecked = NO;
    self.typeRadioButtonAMChecked = NO;
    self.typeRadioButtonPMChecked = NO;
    self.typeRadioButtonOtherChecked = NO;
    
    self.prepRadioButtonRTEChecked = NO;
    self.prepRadioButtonLowChecked = NO;
    self.prepRadioButtonMediumChecked = NO;
    self.prepRadioButtonHighChecked = NO;
    
    if (![self.selectedFavoriteRelaunchItem isEqualToString:@""]
        && self.selectedFavoriteRelaunchItem != nil
        && self.relaunchItemID != 0) {
        
        self.title = @"Edit Favorite";
        
        [self getFavoriteItem:HTWebSvcURL withState:0];
        
    } else { // create new favorite
        
        self.title = @"Create Favorite";
        
        [self showFavoriteItem];
    }
}

#pragma mark - Methods

- (void)getFavoriteItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_get_favorite&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichID=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.relaunchItemID];
    
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

- (void)addFavoriteItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneAddingFavorite = YES;
    
    NSString *myRequestString;

    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.selectedFavoriteName = self.selectedFavoriteNameTextField.text;
    
    if (self.typeRadioButtonSnackChecked == YES) {
        
        self.selectedFavoriteType = @"SN";
        
    } else if (self.typeRadioButtonAMChecked == YES) {
        
        self.selectedFavoriteType = @"AM";
        
    } else if (self.typeRadioButtonPMChecked == YES) {
        
        self.selectedFavoriteType = @"PM";
        
    } else if (self.typeRadioButtonOtherChecked == YES) {
        
        self.selectedFavoriteType = @"Other";
    }
    
    if (self.prepRadioButtonRTEChecked == YES) {
        
        self.selectedFavoritePrep = @"R";
        
    } else if (self.prepRadioButtonLowChecked == YES) {
        
        self.selectedFavoritePrep = @"L";
        
    } else if (self.prepRadioButtonMediumChecked == YES) {
        
        self.selectedFavoritePrep = @"M";
        
    } else if (self.prepRadioButtonHighChecked == YES) {
        
        self.selectedFavoritePrep = @"H";
    }
    
    self.selectedFavoriteCalories = self.selectedFavoriteCaloriesTextField.text;
    self.selectedFavoriteProtein = self.selectedFavoriteProteinTextField.text;
    self.selectedFavoriteCarbs = self.selectedFavoriteCarbsTextField.text;
    self.selectedFavoriteFat = self.selectedFavoriteFatTextField.text;
    self.selectedFavoriteSatFat = self.selectedFavoriteSatFatTextField.text;
    self.selectedFavoriteSugars = self.selectedFavoriteSugarsTextField.text;
    self.selectedFavoriteFiber = self.selectedFavoriteFiberTextField.text;
    self.selectedFavoriteSodium = self.selectedFavoriteSodiumTextField.text;
    
    self.selectedFavoriteServings = self.selectedFavoriteServingsTextField.text;
    
    self.selectedFavoriteDescription = self.selectedFavoriteDescriptionTextView.text;
    self.selectedFavoriteIngredients = self.selectedFavoriteIngredientsTextView.text;
    self.selectedFavoriteDirections = self.selectedFavoriteDirectionsTextView.text;
    self.selectedFavoriteRecommended = self.selectedFavoriteRecommendedTextView.text;
    self.selectedFavoriteComments = self.selectedFavoriteCommentsTextView.text;
    
    self.selectedFavoriteName = [appDelegate cleanStringBeforeSending:self.selectedFavoriteName];
    
    self.selectedFavoriteDescription =
        [appDelegate cleanStringBeforeSending:self.selectedFavoriteDescription];
    
    self.selectedFavoriteIngredients =
        [appDelegate cleanStringBeforeSending:self.selectedFavoriteIngredients];
    
    self.selectedFavoriteDirections =
        [appDelegate cleanStringBeforeSending:self.selectedFavoriteDirections];
    
    self.selectedFavoriteRecommended =
        [appDelegate cleanStringBeforeSending:self.selectedFavoriteRecommended];
    
    self.selectedFavoriteComments = [appDelegate cleanStringBeforeSending:self.selectedFavoriteComments];
    
    if (![self.selectedFavoriteRelaunchItem isEqualToString:@""]
        && self.selectedFavoriteRelaunchItem != nil
        && self.relaunchItemID != 0) {
        
        self.selectedFavoriteRelaunchItem =
        [NSString stringWithFormat:@"%ld", (long)self.relaunchItemID];
        
    } else {
        
        self.selectedFavoriteRelaunchItem = @"";
    }
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_add_favorite&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&name=%@&WhichID=%@&type=%@&prep=%@&description=%@&servings=%@&ingredients=%@&directions=%@&recommended_with=%@&comments=%@&calories=%@&protein=%@&carbs=%@&fat=%@&sat_fat=%@&sugars=%@&fiber=%@&sodium=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.selectedFavoriteName, self.selectedFavoriteRelaunchItem, self.selectedFavoriteType, self.selectedFavoritePrep, self.selectedFavoriteDescription, self.selectedFavoriteServings, self.selectedFavoriteIngredients, self.selectedFavoriteDirections, self.selectedFavoriteRecommended, self.selectedFavoriteComments, self.selectedFavoriteCalories, self.selectedFavoriteProtein, self.selectedFavoriteCarbs, self.selectedFavoriteFat, self.selectedFavoriteSatFat, self.selectedFavoriteSugars, self.selectedFavoriteFiber, self.selectedFavoriteSodium];
    
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

- (void)showFavoriteItem {
    
    NSArray *viewsToRemove = [self.addFavoriteScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 0;
    NSInteger hPos = 0;
    
    UIView *selectedItemView;
    UIView *graySeparator;
    
    UILabel *selectedItemLabel;
    
    UIButton *radioButton;
    
    UIFont *favoriteSectionFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    UIFont *textFieldFont = [UIFont fontWithName:@"OpenSans-Light" size:18];
    UIFont *radioButtonLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    // favorite name
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, 64, screenWidth, 57)];
    
    [selectedItemView setBackgroundColor:[UIColor whiteColor]];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    self.selectedFavoriteNameTextField = [[HTTextField alloc]
                                          initHTDefaultWithFrame:CGRectMake(16, 17, (screenWidth - 32), 24)];
    
    [self.selectedFavoriteNameTextField setTextAlignment:NSTextAlignmentLeft];
    [self.selectedFavoriteNameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.selectedFavoriteNameTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    self.selectedFavoriteNameTextField.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *color = [UIColor colorWithRed:(117/255.0)
                                     green:(124/255.0)
                                      blue:(128/255.0)
                                     alpha:0.6];
    
    self.selectedFavoriteNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Food description" attributes:@{NSForegroundColorAttributeName: color}];
    
    self.selectedFavoriteNameTextField.text = self.selectedFavoriteName;
    
    [selectedItemView addSubview:self.selectedFavoriteNameTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 53, screenWidth, 4)];
    
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.view addSubview:selectedItemView];
    
    vPos -= 7;
    
    // type
    
    hPos = 16;
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Type"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeRadioButtonSnackChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton setTag:1];
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Snack"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) - 5);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeRadioButtonAMChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:2];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"AM Meal"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) + 10);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeRadioButtonPMChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:3];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"PM Meal"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) + 9);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeRadioButtonOtherChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:4];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Other"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 66, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 70;
    
    hPos = 16;
    
    // prep effort
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Preparation Effort"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepRadioButtonRTEChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:5];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Ready to Eat"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) + 28);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepRadioButtonLowChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:6];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Low"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) - 15);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepRadioButtonMediumChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:7];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Medium"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    hPos += (((screenWidth - 32) / 4) + 6);
    
    radioButton = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepRadioButtonHighChecked == YES) {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [radioButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    radioButton.enabled = YES;
    radioButton.userInteractionEnabled = YES;
    
    [radioButton addTarget:self action:@selector(radioButtonChecked:) forControlEvents:UIControlEventTouchUpInside];
    
    [radioButton setTag:8];
    
    [selectedItemView addSubview:radioButton];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [selectedItemLabel setFont:radioButtonLabelFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"High"];
    [selectedItemLabel sizeToFit];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 66, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 70;
    
    hPos = 16;
    
    // additional fields
    
    UIButton *additionalFieldsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, screenWidth, 49)];
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Additional Fields"];
    
    [additionalFieldsButton addSubview:selectedItemLabel];
    
    UIImageView *additionalFieldsImageView = [[UIImageView alloc]
                                      initWithFrame:CGRectMake((screenWidth - 43), 11, 27, 27)];
    
    if (self.showAdditionalFields == YES) {
        
        [additionalFieldsImageView setImage:[UIImage imageNamed:@"ht-expand-content-minus"]];
        
    } else {
        
        [additionalFieldsImageView setImage:[UIImage imageNamed:@"ht-expand-content-plus"]];
    }
    
    [additionalFieldsButton addSubview:additionalFieldsImageView];
    
    [additionalFieldsButton addTarget:self
                            action:@selector(toggleAdditionalFields)
                  forControlEvents:UIControlEventTouchUpInside];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [additionalFieldsButton addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:additionalFieldsButton];
    
    vPos += 53;
    
    // servings
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Servings"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteServingsTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteServingsTextField setFont:textFieldFont];
    [self.selectedFavoriteServingsTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteServingsTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteServingsTextField.text = self.selectedFavoriteServings;
    
    [selectedItemView addSubview:self.selectedFavoriteServingsTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
    
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 53;
    }
    
    // description
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 110)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, ((screenWidth - 32) / 2), 16)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Description"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteDescriptionTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16, 34, (screenWidth - 32), 63)];
    
    [self.selectedFavoriteDescriptionTextView setTextColor:grayFontColor];
    
    self.selectedFavoriteDescriptionTextView.text = self.selectedFavoriteDescription;
    
    [selectedItemView addSubview:self.selectedFavoriteDescriptionTextView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 106, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
        
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 110;
    }
    
    // ingredients
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 110)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, (screenWidth - 32), 16)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Ingredients (1 per line)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteIngredientsTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16, 34, (screenWidth - 32), 63)];
    
    [self.selectedFavoriteIngredientsTextView setTextColor:grayFontColor];
    
    self.selectedFavoriteIngredientsTextView.text = self.selectedFavoriteIngredients;
    
    [selectedItemView addSubview:self.selectedFavoriteIngredientsTextView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 106, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
        
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 110;
    }
    
    // directions
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 110)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, ((screenWidth - 32) / 2), 16)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Directions"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteDirectionsTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16, 34, (screenWidth - 32), 63)];
    
    [self.selectedFavoriteDirectionsTextView setTextColor:grayFontColor];
    
    self.selectedFavoriteDirectionsTextView.text = self.selectedFavoriteDirections;
    
    [selectedItemView addSubview:self.selectedFavoriteDirectionsTextView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 106, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
        
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 110;
    }
    
    // recommended with
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 110)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, ((screenWidth - 32) / 2), 16)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Recommended With"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteRecommendedTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16, 34, (screenWidth - 32), 63)];
    
    [self.selectedFavoriteRecommendedTextView setTextColor:grayFontColor];
    
    self.selectedFavoriteRecommendedTextView.text = self.selectedFavoriteRecommended;
    
    [selectedItemView addSubview:self.selectedFavoriteRecommendedTextView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 106, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
        
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 110;
    }
    
    // comments
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 110)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, ((screenWidth - 32) / 2), 16)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Comments"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteCommentsTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16, 34, (screenWidth - 32), 63)];
    
    [self.selectedFavoriteCommentsTextView setTextColor:grayFontColor];
    
    self.selectedFavoriteCommentsTextView.text = self.selectedFavoriteComments;
    
    [selectedItemView addSubview:self.selectedFavoriteCommentsTextView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 106, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    if (self.showAdditionalFields == YES) {
        
        [self.addFavoriteScrollView addSubview:selectedItemView];
        
        vPos += 110;
    }
    
    // calories
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Calories"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteCaloriesTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteCaloriesTextField setFont:textFieldFont];
    [self.selectedFavoriteCaloriesTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteCaloriesTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteCaloriesTextField.text = self.selectedFavoriteCalories;
    
    [selectedItemView addSubview:self.selectedFavoriteCaloriesTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // protein
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Protein (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteProteinTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteProteinTextField setFont:textFieldFont];
    [self.selectedFavoriteProteinTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteProteinTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteProteinTextField.text = self.selectedFavoriteProtein;
    
    [selectedItemView addSubview:self.selectedFavoriteProteinTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // carbs
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Carbohydrates (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteCarbsTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteCarbsTextField setFont:textFieldFont];
    [self.selectedFavoriteCarbsTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteCarbsTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteCarbsTextField.text = self.selectedFavoriteCarbs;
    
    [selectedItemView addSubview:self.selectedFavoriteCarbsTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // fat
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Fat (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteFatTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteFatTextField setFont:textFieldFont];
    [self.selectedFavoriteFatTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteFatTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteFatTextField.text = self.selectedFavoriteFat;
    
    [selectedItemView addSubview:self.selectedFavoriteFatTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // sat fat
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Saturated Fat (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteSatFatTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteSatFatTextField setFont:textFieldFont];
    [self.selectedFavoriteSatFatTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteSatFatTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteSatFatTextField.text = self.selectedFavoriteSatFat;
    
    [selectedItemView addSubview:self.selectedFavoriteSatFatTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // sugars
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Sugars (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteSugarsTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteSugarsTextField setFont:textFieldFont];
    [self.selectedFavoriteSugarsTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteSugarsTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteSugarsTextField.text = self.selectedFavoriteSugars;
    
    [selectedItemView addSubview:self.selectedFavoriteSugarsTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // fiber
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Fiber (g)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteFiberTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteFiberTextField setFont:textFieldFont];
    [self.selectedFavoriteFiberTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteFiberTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteFiberTextField.text = self.selectedFavoriteFiber;
    
    [selectedItemView addSubview:self.selectedFavoriteFiberTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;
    
    // sodium
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 53)];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, ((screenWidth - 32) / 2), 49)];
    
    [selectedItemLabel setFont:favoriteSectionFont];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:@"Sodium (mg)"];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    self.selectedFavoriteSodiumTextField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake((screenWidth / 2), 9, ((screenWidth - 32) / 2), 31)];
    
    [self.selectedFavoriteSodiumTextField setFont:textFieldFont];
    [self.selectedFavoriteSodiumTextField setTextColor:grayFontColor];
    
    [self.selectedFavoriteSodiumTextField setTextAlignment:NSTextAlignmentRight];
    
    self.selectedFavoriteSodiumTextField.text = self.selectedFavoriteSodium;
    
    [selectedItemView addSubview:self.selectedFavoriteSodiumTextField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 49, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [selectedItemView addSubview:graySeparator];
    
    [self.addFavoriteScrollView addSubview:selectedItemView];
    
    vPos += 53;

    
    [self.addFavoriteScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
}

- (UIBarButtonItem *) backButton {
    
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
    
    NSString *alertString;
    
    NSString *checkStringName = [self.selectedFavoriteNameTextField.text stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
    
    NSString *checkStringCalories = [self.selectedFavoriteCaloriesTextField.text stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]];
    
    if ([checkStringName isEqualToString:@""]) {
        
        alertString = @"Please enter a name for this Favorite item";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedFavoriteNameTextField becomeFirstResponder];
        
    // type
        
    } else if (self.typeRadioButtonSnackChecked == NO &&
               self.typeRadioButtonAMChecked == NO &&
               self.typeRadioButtonPMChecked == NO &&
               self.typeRadioButtonOtherChecked == NO) {
        
        alertString = @"Please choose a type for this Favorite item";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
    // prep
        
    } else if (self.prepRadioButtonRTEChecked == NO &&
               self.prepRadioButtonLowChecked == NO &&
               self.prepRadioButtonMediumChecked == NO &&
               self.prepRadioButtonHighChecked == NO) {
        
        alertString = @"Please choose the preparation effort for this Favorite item";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
    // calories
        
    } else if ([checkStringCalories isEqualToString:@""]) {
        
        alertString = @"Please enter the calories for this Favorite item";
        
        [self.view makeToast:alertString duration:5.0 position:@"center"];
        
        [self.selectedFavoriteCaloriesTextField becomeFirstResponder];
        
    } else {
        
        [self addFavoriteItem:HTWebSvcURL withState:0];
    }
}

- (IBAction) radioButtonChecked:(id)sender {
    
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    switch (buttonTag) {
            
        case 1:
            if (self.typeRadioButtonSnackChecked == YES) {
                
                self.typeRadioButtonSnackChecked = NO;
                
            } else {
                
                self.typeRadioButtonSnackChecked = YES;
                
                self.typeRadioButtonAMChecked = NO;
                self.typeRadioButtonPMChecked = NO;
                self.typeRadioButtonOtherChecked = NO;
            }
            break;
            
        case 2:
            if (self.typeRadioButtonAMChecked == YES) {
                
                self.typeRadioButtonAMChecked = NO;
                
            } else {
                
                self.typeRadioButtonAMChecked = YES;
                
                self.typeRadioButtonSnackChecked = NO;
                self.typeRadioButtonPMChecked = NO;
                self.typeRadioButtonOtherChecked = NO;
            }
            break;
            
        case 3:
            if (self.typeRadioButtonPMChecked == YES) {
                
                self.typeRadioButtonPMChecked = NO;
                
            } else {
                
                self.typeRadioButtonPMChecked = YES;
                
                self.typeRadioButtonSnackChecked = NO;
                self.typeRadioButtonAMChecked = NO;
                self.typeRadioButtonOtherChecked = NO;
            }
            break;
            
        case 4:
            if (self.typeRadioButtonOtherChecked == YES) {
                
                self.typeRadioButtonOtherChecked = NO;
                
            } else {
                
                self.typeRadioButtonOtherChecked = YES;
                
                self.typeRadioButtonSnackChecked = NO;
                self.typeRadioButtonAMChecked = NO;
                self.typeRadioButtonPMChecked = NO;
            }
            break;
            
        case 5:
            if (self.prepRadioButtonRTEChecked == YES) {
                
                self.prepRadioButtonRTEChecked = NO;
                
            } else {
                
                self.prepRadioButtonRTEChecked = YES;
                
                self.prepRadioButtonLowChecked = NO;
                self.prepRadioButtonMediumChecked = NO;
                self.prepRadioButtonHighChecked = NO;
            }
            break;
            
        case 6:
            if (self.prepRadioButtonLowChecked == YES) {
                
                self.prepRadioButtonLowChecked = NO;
                
            } else {
                
                self.prepRadioButtonLowChecked = YES;
                
                self.prepRadioButtonRTEChecked = NO;
                self.prepRadioButtonMediumChecked = NO;
                self.prepRadioButtonHighChecked = NO;
            }
            break;
            
        case 7:
            if (self.prepRadioButtonMediumChecked == YES) {
                
                self.prepRadioButtonMediumChecked = NO;
                
            } else {
                
                self.prepRadioButtonMediumChecked = YES;
                
                self.prepRadioButtonRTEChecked = NO;
                self.prepRadioButtonLowChecked = NO;
                self.prepRadioButtonHighChecked = NO;
            }
            break;
            
        case 8:
            if (self.prepRadioButtonHighChecked == YES) {
                
                self.prepRadioButtonHighChecked = NO;
                
            } else {
                
                self.prepRadioButtonHighChecked = YES;
                
                self.prepRadioButtonRTEChecked = NO;
                self.prepRadioButtonLowChecked = NO;
                self.prepRadioButtonMediumChecked = NO;
            }
            break;
            
        default:
            break;
    }
    
    self.selectedFavoriteName = self.selectedFavoriteNameTextField.text;
    
    self.selectedFavoriteCalories = self.selectedFavoriteCaloriesTextField.text;
    self.selectedFavoriteProtein = self.selectedFavoriteProteinTextField.text;
    self.selectedFavoriteCarbs = self.selectedFavoriteCarbsTextField.text;
    self.selectedFavoriteFat = self.selectedFavoriteFatTextField.text;
    self.selectedFavoriteSatFat = self.selectedFavoriteSatFatTextField.text;
    self.selectedFavoriteSugars = self.selectedFavoriteSugarsTextField.text;
    self.selectedFavoriteFiber = self.selectedFavoriteFiberTextField.text;
    self.selectedFavoriteSodium = self.selectedFavoriteSodiumTextField.text;
    
    self.selectedFavoriteServings = self.selectedFavoriteServingsTextField.text;
    
    self.selectedFavoriteDescription = self.selectedFavoriteDescriptionTextView.text;
    self.selectedFavoriteIngredients = self.selectedFavoriteIngredientsTextView.text;
    self.selectedFavoriteDirections = self.selectedFavoriteDirectionsTextView.text;
    self.selectedFavoriteRecommended = self.selectedFavoriteRecommendedTextView.text;
    self.selectedFavoriteComments = self.selectedFavoriteCommentsTextView.text;
    
    [self showFavoriteItem];
}

- (void)toggleAdditionalFields {
    
    if (self.showAdditionalFields == NO) {
        
        self.showAdditionalFields = YES;
        
    } else {
        
        self.showAdditionalFields = NO;
    }
    
    self.selectedFavoriteName = self.selectedFavoriteNameTextField.text;
    
    self.selectedFavoriteCalories = self.selectedFavoriteCaloriesTextField.text;
    self.selectedFavoriteProtein = self.selectedFavoriteProteinTextField.text;
    self.selectedFavoriteCarbs = self.selectedFavoriteCarbsTextField.text;
    self.selectedFavoriteFat = self.selectedFavoriteFatTextField.text;
    self.selectedFavoriteSatFat = self.selectedFavoriteSatFatTextField.text;
    self.selectedFavoriteSugars = self.selectedFavoriteSugarsTextField.text;
    self.selectedFavoriteFiber = self.selectedFavoriteFiberTextField.text;
    self.selectedFavoriteSodium = self.selectedFavoriteSodiumTextField.text;
    
    self.selectedFavoriteServings = self.selectedFavoriteServingsTextField.text;
    
    self.selectedFavoriteDescription = self.selectedFavoriteDescriptionTextView.text;
    self.selectedFavoriteIngredients = self.selectedFavoriteIngredientsTextView.text;
    self.selectedFavoriteDirections = self.selectedFavoriteDirectionsTextView.text;
    self.selectedFavoriteRecommended = self.selectedFavoriteRecommendedTextView.text;
    self.selectedFavoriteComments = self.selectedFavoriteCommentsTextView.text;
    
    [self showFavoriteItem];
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
    
    self.selectedFavoriteName = @"";
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
        
    } else if ([elementName isEqualToString:@"favorite_meal_name"]) {
        
        self.selectedFavoriteName = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_type"]) {
        
        if ([cleanString isEqualToString:@"SN"]) {
            
            self.typeRadioButtonSnackChecked = YES;
            
        } else if ([cleanString isEqualToString:@"AM"]) {
            
            self.typeRadioButtonAMChecked = YES;
            
        } else if ([cleanString isEqualToString:@"PM"]) {
            
            self.typeRadioButtonPMChecked = YES;
            
        } else if ([cleanString isEqualToString:@"Other"]) {
            
            self.typeRadioButtonOtherChecked = YES;
        }
        
    } else if ([elementName isEqualToString:@"favorite_meal_prep"]) {
        
        if ([cleanString isEqualToString:@"R"]) {
            
            self.prepRadioButtonRTEChecked = YES;
            
        } else if ([cleanString isEqualToString:@"L"]) {
            
            self.prepRadioButtonLowChecked = YES;
            
        } else if ([cleanString isEqualToString:@"M"]) {
            
            self.prepRadioButtonMediumChecked = YES;
            
        } else if ([cleanString isEqualToString:@"H"]) {
            
            self.prepRadioButtonHighChecked = YES;
        }
        
    } else if ([elementName isEqualToString:@"favorite_meal_calories"]) {
        
        self.selectedFavoriteCalories = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_protein"]) {
        
        self.selectedFavoriteProtein = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_carbs"]) {
        
        self.selectedFavoriteCarbs = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_fat"]) {
        
        self.selectedFavoriteFat = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_sat_fat"]) {
        
        self.selectedFavoriteSatFat = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_sugar"]) {
        
        self.selectedFavoriteSugars = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_fiber"]) {
        
        self.selectedFavoriteFiber = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_sodium"]) {
        
        self.selectedFavoriteSodium = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_description"]) {
        
        self.selectedFavoriteDescription = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_servings"]) {
        
        self.selectedFavoriteServings = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_menu"]) {
        
        self.selectedFavoriteIngredients = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_directions"]) {
        
        self.selectedFavoriteDirections = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_servewith"]) {
        
        self.selectedFavoriteRecommended = cleanString;
        
    } else if ([elementName isEqualToString:@"favorite_meal_nutrition"]) {
        
        self.selectedFavoriteComments = cleanString;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        if (self.doneAddingFavorite == YES) {
            
            if (self.relaunchItemID != 0) { // update
                
                [[self navigationController] popViewControllerAnimated:YES];
                
            } else { // new item
                
                [[self navigationController] popToRootViewControllerAnimated:YES];
            }
            
        } else {
            
            [self showFavoriteItem];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
