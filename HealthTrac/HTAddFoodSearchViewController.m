//
//  HTAddFoodSearchViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/4/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddFoodSearchViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "NMRangeSlider.h"
#import "HTTextField.h"
#import "HTAddFoodSearchResultsViewController.h"

@interface HTAddFoodSearchViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddFoodSearchViewController

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
    
    int screenWidth = self.view.frame.size.width;
    
    self.caloriesSlider = [self createNMRangeSliderWithFrame:CGRectMake(8, 80, (screenWidth - 16), 34)
                                                     andType:@"calories"
                                                 andMinValue:0
                                                 andMaxValue:600
                                                andStepValue:10];
    
    self.caloriesSlider.tag = 101;
    
    self.proteinSlider = [self createNMRangeSliderWithFrame:
                          CGRectMake(8, 46, (screenWidth - 16), 34)
                                                    andType:@"protein"
                                                andMinValue:0
                                                andMaxValue:100
                                               andStepValue:1];
    
    self.proteinSlider.tag = 102;
    
    self.carbsSlider = [self createNMRangeSliderWithFrame:
                        CGRectMake(8, 46, (screenWidth - 16), 34)
                                                  andType:@"carbs"
                                              andMinValue:0
                                              andMaxValue:100
                                             andStepValue:1];
    
    self.carbsSlider.tag = 103;
    
    self.netCarbsSlider = [self createNMRangeSliderWithFrame:
                           CGRectMake(8, 46, (screenWidth - 16), 34)
                                                     andType:@"net carbs"
                                                 andMinValue:0
                                                 andMaxValue:100
                                                andStepValue:1];
    
    self.netCarbsSlider.tag = 104;
    
    self.fatSlider = [self createNMRangeSliderWithFrame:
                      CGRectMake(8, 46, (screenWidth - 16), 34)
                                                andType:@"fat"
                                            andMinValue:0
                                            andMaxValue:50
                                           andStepValue:1];
    
    self.fatSlider.tag = 105;
    
    self.satFatSlider = [self createNMRangeSliderWithFrame:
                         CGRectMake(8, 46, (screenWidth - 16), 34)
                                                   andType:@"sat fat"
                                               andMinValue:0
                                               andMaxValue:20
                                              andStepValue:1];
    
    self.satFatSlider.tag = 106;
    
    self.typeCheckboxSnackChecked = NO;
    self.typeCheckboxAMChecked = NO;
    self.typeCheckboxPMChecked = NO;
    self.typeCheckboxOtherChecked = NO;
    self.prepCheckboxRTEChecked = NO;
    self.prepCheckboxLowChecked = NO;
    self.prepCheckboxMediumChecked = NO;
    self.prepCheckboxHighChecked = NO;
    
    self.productsSearchSelection = @"";
    self.addFoodSearchFieldString = @"";
    self.addFoodSearchString = @"";
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
    
    if ([self.addFoodCategory isEqualToString:@"favorites"]) {

        self.title = @"My Favorites";

    } else if ([self.addFoodCategory isEqualToString:@"recommended"]) {

        self.title = @"Recommended";

    } else if ([self.addFoodCategory isEqualToString:@"general"]) {

        self.title = @"General Food Item";
        
    }
    
    [self getSearchFields:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getSearchFields:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.showProteinSlider = NO;
    self.showCarbsSlider = NO;
    self.showNetCarbsSlider = NO;
    self.showFatSlider = NO;
    self.showSatFatSlider = NO;
    self.showSearchProducts = NO;
    
    self.showAdditionalFields = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food_search_fields&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showSearchFields {
    
    NSArray *viewsToRemove = [self.addFoodSearchScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;

    NSInteger vPos = -64;
    NSInteger hPos;
    
    UIView *graySeparator;
    
    UIButton *addFoodSearchButton;
    UIButton *checkBox;
    
    UILabel *searchLabel;
    
    NSMutableAttributedString *labelString;
    
    UIFont *searchLabelFont = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    UIFont *subSearchLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    UIFont *checkBoxLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
    UIFont *searchHeaderFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17.0];
    UIFont *searchCriteriaFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UIView *searchContainer;
    UIView *caloriesSliderContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 170)];
    
    [caloriesSliderContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 14, screenWidth, 30)];
    
    [searchLabel setFont:searchLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentCenter];
    [searchLabel setText:@"Calories"];
    
    [caloriesSliderContainer addSubview:searchLabel];
    
    [caloriesSliderContainer addSubview:self.caloriesSlider];
    
    [self.addFoodSearchScrollView addSubview:caloriesSliderContainer];
    
    [self updateSliderLabels:self.caloriesSlider];
    
    vPos += 170;
    
    if (self.showProteinSlider == YES ||
        self.showCarbsSlider == YES ||
        self.showNetCarbsSlider == YES ||
        self.showFatSlider == YES ||
        self.showSatFatSlider == YES) { // we have additional fields
        
        addFoodSearchButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 50)];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, screenWidth, 50)];
        [searchLabel setFont:searchHeaderFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Additional Fields"];
        
        [addFoodSearchButton addSubview:searchLabel];
        
        self.additionalFieldsImageView = [[UIImageView alloc]
                                          initWithFrame:CGRectMake((screenWidth - 43), 12, 27, 27)];
        
        if (self.showAdditionalFields == YES) {
            
            [self.additionalFieldsImageView setImage:[UIImage imageNamed:@"ht-expand-content-minus"]];
            
        } else {
            
            [self.additionalFieldsImageView setImage:[UIImage imageNamed:@"ht-expand-content-plus"]];
        }
        
        [addFoodSearchButton addSubview:self.additionalFieldsImageView];
        
        [addFoodSearchButton addTarget:self
                                action:@selector(toggleAdditionalFields)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [self.addFoodSearchScrollView addSubview:addFoodSearchButton];
        
        vPos += 50;
        
        if (self.showProteinSlider == YES) {
            
            searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 124)];
            
            [searchContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
            
            labelString = [[NSMutableAttributedString alloc]
                           initWithString:[NSString stringWithFormat:@"%@",
                                           @"Protein (g)"]];
            
            [labelString addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"AvenirNext-Medium" size:10]
                                range:NSMakeRange([labelString length] - 3, 3)];
            
            searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, screenWidth, 15)];
            
            [searchLabel setFont:subSearchLabelFont];
            [searchLabel setTextColor:grayFontColor];
            [searchLabel setTextAlignment:NSTextAlignmentLeft];
            [searchLabel setAttributedText:labelString];
            
            [searchContainer addSubview:searchLabel];
            
            [self updateSliderLabels:self.proteinSlider];
            
            [searchContainer addSubview:self.proteinSlider];
            
            if (self.showAdditionalFields == YES) {
            
                [self.addFoodSearchScrollView addSubview:searchContainer];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 120, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.addFoodSearchScrollView addSubview:graySeparator];
                
                vPos += 124;
            }
        }
        
        if (self.showCarbsSlider == YES) {
            
            searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 124)];
            
            [searchContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
            
            labelString = [[NSMutableAttributedString alloc]
                           initWithString:[NSString stringWithFormat:@"%@",
                                           @"Carbs (g)"]];
            
            [labelString addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"AvenirNext-Medium" size:10]
                                range:NSMakeRange([labelString length] - 3, 3)];
            
            searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, screenWidth, 15)];
            
            [searchLabel setFont:subSearchLabelFont];
            [searchLabel setTextColor:grayFontColor];
            [searchLabel setTextAlignment:NSTextAlignmentLeft];
            [searchLabel setAttributedText:labelString];
            
            [searchContainer addSubview:searchLabel];
            
            [self updateSliderLabels:self.carbsSlider];
            
            [searchContainer addSubview:self.carbsSlider];
            
            if (self.showAdditionalFields == YES) {
                
                [self.addFoodSearchScrollView addSubview:searchContainer];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 120, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.addFoodSearchScrollView addSubview:graySeparator];
                
                vPos += 124;
            }
        }
        
        if (self.showNetCarbsSlider == YES) {
            
            searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 124)];
            
            [searchContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
            
            labelString = [[NSMutableAttributedString alloc]
                           initWithString:[NSString stringWithFormat:@"%@",
                                           @"Net Carbs (g)"]];
            
            [labelString addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"AvenirNext-Medium" size:10]
                                range:NSMakeRange([labelString length] - 3, 3)];
            
            searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, screenWidth, 15)];
            
            [searchLabel setFont:subSearchLabelFont];
            [searchLabel setTextColor:grayFontColor];
            [searchLabel setTextAlignment:NSTextAlignmentLeft];
            [searchLabel setAttributedText:labelString];
            
            [searchContainer addSubview:searchLabel];
            
            [self updateSliderLabels:self.netCarbsSlider];
            
            [searchContainer addSubview:self.netCarbsSlider];
            
            if (self.showAdditionalFields == YES) {
                
                [self.addFoodSearchScrollView addSubview:searchContainer];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 120, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.addFoodSearchScrollView addSubview:graySeparator];
                
                vPos += 124;
            }
        }
        
        if (self.showFatSlider == YES) {
            
            searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 124)];
            
            [searchContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
            
            labelString = [[NSMutableAttributedString alloc]
                           initWithString:[NSString stringWithFormat:@"%@",
                                           @"Fat (g)"]];
            
            [labelString addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"AvenirNext-Medium" size:10]
                                range:NSMakeRange([labelString length] - 3, 3)];
            
            searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, screenWidth, 15)];
            
            [searchLabel setFont:subSearchLabelFont];
            [searchLabel setTextColor:grayFontColor];
            [searchLabel setTextAlignment:NSTextAlignmentLeft];
            [searchLabel setAttributedText:labelString];
            
            [searchContainer addSubview:searchLabel];
            
            [self updateSliderLabels:self.fatSlider];
            
            [searchContainer addSubview:self.fatSlider];
            
            if (self.showAdditionalFields == YES) {
                
                [self.addFoodSearchScrollView addSubview:searchContainer];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 120, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.addFoodSearchScrollView addSubview:graySeparator];
                
                vPos += 124;
            }
        }
        
        if (self.showSatFatSlider == YES) {
            
            searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 124)];
            
            [searchContainer setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
            
            labelString = [[NSMutableAttributedString alloc]
                           initWithString:[NSString stringWithFormat:@"%@",
                                           @"Sat Fat (g)"]];
            
            [labelString addAttribute:NSFontAttributeName
                                value:[UIFont fontWithName:@"AvenirNext-Medium" size:10]
                                range:NSMakeRange([labelString length] - 3, 3)];
            
            searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, screenWidth, 15)];
            
            [searchLabel setFont:subSearchLabelFont];
            [searchLabel setTextColor:grayFontColor];
            [searchLabel setTextAlignment:NSTextAlignmentLeft];
            [searchLabel setAttributedText:labelString];
            
            [searchContainer addSubview:searchLabel];
            
            [self updateSliderLabels:self.satFatSlider];
            
            [searchContainer addSubview:self.satFatSlider];
            
            if (self.showAdditionalFields == YES) {
                
                [self.addFoodSearchScrollView addSubview:searchContainer];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 120, screenWidth, 4)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [self.addFoodSearchScrollView addSubview:graySeparator];
                
                vPos += 124;
            }
        }
        
        if (self.showAdditionalFields == NO) {
            
            graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
            graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
            
            [self.addFoodSearchScrollView addSubview:graySeparator];
            
            vPos += 4;
        }
    }
    
    hPos = 16;
    
    // type
    
    searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
    
    [searchLabel setFont:searchCriteriaFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Type"];
    
    [searchContainer addSubview:searchLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeCheckboxSnackChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
     
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:1];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Snack"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) - 5);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeCheckboxAMChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:2];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"AM Meal"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) + 10);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeCheckboxPMChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:3];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"PM Meal"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) + 9);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.typeCheckboxOtherChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:4];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Other"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    [self.addFoodSearchScrollView addSubview:searchContainer];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.addFoodSearchScrollView addSubview:graySeparator];
    
    vPos += 70;
    
    hPos = 16;
    
    // prep effort
    
    searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
    
    [searchLabel setFont:searchCriteriaFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Preparation Effort"];
    
    [searchContainer addSubview:searchLabel];
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepCheckboxRTEChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:5];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Ready to Eat"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) + 28);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepCheckboxLowChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:6];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Low"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) - 15);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepCheckboxMediumChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:7];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Medium"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    hPos += (((screenWidth - 32) / 4) + 6);
    
    checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
    
    if (self.prepCheckboxHighChecked == YES) {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
        
    } else {
        
        [checkBox setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
    }
    
    [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
    [checkBox setTag:8];
    
    [searchContainer addSubview:checkBox];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
    
    [searchLabel setFont:checkBoxLabelFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"High"];
    [searchLabel sizeToFit];
    
    [searchContainer addSubview:searchLabel];
    
    [self.addFoodSearchScrollView addSubview:searchContainer];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.addFoodSearchScrollView addSubview:graySeparator];
    
    vPos += 70;
    
    hPos = 16;
    
    if ([self.addFoodCategory isEqualToString:@"favorites"] ||
        [self.addFoodCategory isEqualToString:@"general"]) {
        
        self.showSearchProducts = NO;
    }
    
    if (self.showSearchProducts == YES) {
        
        // products
        
        searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
        
        [searchLabel setFont:searchCriteriaFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Products"];
        
        [searchContainer addSubview:searchLabel];
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if ([self.productsSearchSelection isEqualToString:@"Y"]) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:9];
        
        [searchContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Include"];
        [searchLabel sizeToFit];
        
        [searchContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 3) - 14);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if ([self.productsSearchSelection isEqualToString:@"O"]) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:10];
        
        [searchContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"Only Products"];
        [searchLabel sizeToFit];
        
        [searchContainer addSubview:searchLabel];
        
        hPos += (((screenWidth - 32) / 3) + 18);
        
        checkBox = [[UIButton alloc] initWithFrame:CGRectMake(hPos, 33, 24, 24)];
        
        if ([self.productsSearchSelection isEqualToString:@"N"]) {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
            
        } else {
            
            [checkBox setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
        }
        
        [checkBox addTarget:self action:@selector(checkBoxChecked:) forControlEvents:UIControlEventTouchUpInside];
        [checkBox setTag:11];
        
        [searchContainer addSubview:checkBox];
        
        searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos + 30, 40, 1, 15)];
        
        [searchLabel setFont:checkBoxLabelFont];
        [searchLabel setTextColor:grayFontColor];
        [searchLabel setTextAlignment:NSTextAlignmentLeft];
        [searchLabel setText:@"No Products"];
        [searchLabel sizeToFit];
        
        [searchContainer addSubview:searchLabel];
        
        [self.addFoodSearchScrollView addSubview:searchContainer];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [self.addFoodSearchScrollView addSubview:graySeparator];
        
        vPos += 70;
        
        hPos = 16;
    }
    
    // search
    
    searchContainer = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 70)];
    
    searchLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 9, screenWidth, 15)];
    
    [searchLabel setFont:searchCriteriaFont];
    [searchLabel setTextColor:grayFontColor];
    [searchLabel setTextAlignment:NSTextAlignmentLeft];
    [searchLabel setText:@"Keywords"];
    
    [searchContainer addSubview:searchLabel];
    
    self.searchField = [[HTTextField alloc]
                                initHTDefaultWithFrame:CGRectMake(hPos, 33, (screenWidth - 32), 24)];
    
    [self.searchField setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0]];
    [self.searchField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.searchField setTextAlignment:NSTextAlignmentLeft];
    [self.searchField setText:self.addFoodSearchFieldString];
    
    [searchContainer addSubview:self.searchField];
    
    [self.addFoodSearchScrollView addSubview:searchContainer];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos + 66, screenWidth, 4)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.addFoodSearchScrollView addSubview:graySeparator];
    
    vPos += 70;
    
    [self.addFoodSearchScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
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

- (UIBarButtonItem *)checkButton {
    
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
    
    NSMutableString *typeString = [[NSMutableString alloc] init];
    NSMutableString *prepString = [[NSMutableString alloc] init];
    
    // type
    
    if (self.typeCheckboxSnackChecked == YES) {
        
        [typeString appendString:@"SN,"];
    }
    
    if (self.typeCheckboxAMChecked == YES) {
        
        [typeString appendString:@"AM,"];
    }
    
    if (self.typeCheckboxPMChecked == YES) {
        
        [typeString appendString:@"PM,"];
    }
    
    if (self.typeCheckboxOtherChecked == YES) {
        
        [typeString appendString:@"Other,"];
    }
    
    if ([typeString length] != 0) {
        
        NSRange typeStringRange = NSMakeRange(0, [typeString length] - 1);
        
        typeString = [NSMutableString stringWithString:[typeString substringWithRange:typeStringRange]];
    }
    
    // prep
    
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
    
    self.addFoodSearchString = [NSString stringWithFormat:@"WhichCategory=%@&calories=%d;%d&protein=%d;%d&carbs=%d;%d&net_carbs=%d;%d&fat=%d;%d&sat_fat=%d;%d&type=%@&prep=%@&products=%@&search=%@&template=false",
                                self.addFoodCategory,
                                (int)roundf(self.caloriesSlider.lowerValue),
                                (int)roundf(self.caloriesSlider.upperValue),
                                (int)roundf(self.proteinSlider.lowerValue),
                                (int)roundf(self.proteinSlider.upperValue),
                                (int)roundf(self.carbsSlider.lowerValue),
                                (int)roundf(self.carbsSlider.upperValue),
                                (int)roundf(self.netCarbsSlider.lowerValue),
                                (int)roundf(self.netCarbsSlider.upperValue),
                                (int)roundf(self.fatSlider.lowerValue),
                                (int)roundf(self.fatSlider.upperValue),
                                (int)roundf(self.satFatSlider.lowerValue),
                                (int)roundf(self.satFatSlider.upperValue),
                                typeString,
                                prepString,
                                self.productsSearchSelection,
                                [appDelegate cleanStringBeforeSending:self.searchField.text]];
    
    self.addFoodSearchFieldString = self.searchField.text;
    
    [self performSegueWithIdentifier:@"showAddFoodSearchResults" sender:self];
}

- (void)toggleAdditionalFields {
    
    if (self.showAdditionalFields == NO) {
        
        self.showAdditionalFields = YES;
        
    } else {
        
        self.showAdditionalFields = NO;
    }
    
    [self showSearchFields];
}

- (IBAction) checkBoxChecked:(id)sender {
    
    UIButton *button = sender;

    switch (button.tag) {
        case 1:
            
            if (self.typeCheckboxSnackChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxSnackChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxSnackChecked = NO;
            }
            
            break;
            
        case 2:
            
            if (self.typeCheckboxAMChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxAMChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxAMChecked = NO;
            }
            
            break;
            
        case 3:
            
            if (self.typeCheckboxPMChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxPMChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxPMChecked = NO;
            }
            
            break;
            
        case 4:
            
            if (self.typeCheckboxOtherChecked == NO) {
                
                [button setImage:[UIImage imageNamed:@"ht-check-on-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxOtherChecked = YES;
                
            } else {
                
                [button setImage:[UIImage imageNamed:@"ht-check-off-green"] forState:UIControlStateNormal];
                
                self.typeCheckboxOtherChecked = NO;
            }
            
            break;
            
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
            
        case 9:
            
            if (![self.productsSearchSelection isEqualToString:@"Y"]) {
                
                [button setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
                
                self.productsSearchSelection = @"Y";
                
                UIButton *otherButton;
                
                otherButton = (UIButton *)[self.view viewWithTag:10];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
                
                otherButton = (UIButton *)[self.view viewWithTag:11];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
            }
            
            break;
            
        case 10:
            
            if (![self.productsSearchSelection isEqualToString:@"O"]) {
                
                [button setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
                
                self.productsSearchSelection = @"O";
                
                UIButton *otherButton;
                
                otherButton = (UIButton *)[self.view viewWithTag:9];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
                
                otherButton = (UIButton *)[self.view viewWithTag:11];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
            }
            
            break;
            
        case 11:
            
            if (![self.productsSearchSelection isEqualToString:@"N"]) {
                
                [button setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
                
                self.productsSearchSelection = @"N";
                
                UIButton *otherButton;
                
                otherButton = (UIButton *)[self.view viewWithTag:9];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
                
                otherButton = (UIButton *)[self.view viewWithTag:10];
                
                [otherButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
            }
            
            break;
            
        default:
            break;
    }
}

#pragma mark - NMRangeSlider methods

- (NMRangeSlider *)createNMRangeSliderWithFrame:(CGRect)frame
                                         andType:(NSString *)type
                                     andMinValue:(float)minValue
                                     andMaxValue:(float)maxValue
                                    andStepValue:(float)stepValue {
    
    NMRangeSlider *rangeSlider = [[NMRangeSlider alloc] initWithFrame:frame];
    
    rangeSlider.minimumValue = minValue;
    rangeSlider.maximumValue = maxValue;
    
    rangeSlider.lowerValue = minValue;
    rangeSlider.upperValue = maxValue;
    
    rangeSlider.stepValue = stepValue;
    
    [rangeSlider addTarget:self action:@selector(labelSliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    NSInteger fontSize;
    
    float vOffset;
    
    if ([type isEqualToString:@"calories"]) {
        
        fontSize = 18.0;
        
        vOffset = -29.5;
        
    } else {
        
        fontSize = 14.0;
        
        vOffset = -24.0;
    }
    
    UILabel *lowerLabel = [[UILabel alloc] initWithFrame:CGRectMake(-22.5f, vOffset, 88, 21)];
    
    [lowerLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:fontSize]];
    
    [lowerLabel setBackgroundColor:[UIColor clearColor]];
    [lowerLabel setTextAlignment:NSTextAlignmentCenter];
    
    [lowerLabel setTextColor:[UIColor colorWithRed:(114/255.0)
                                             green:(126/255.0)
                                              blue:(133/255.0)
                                             alpha:1.0]];
    
    [rangeSlider addSubview:lowerLabel];
    
    int screenWidth = self.view.frame.size.width;
    float scaleHashSpacing;
    
    UILabel *upperLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth - 81.5f), vOffset, 88, 21)];
    
    [upperLabel setBackgroundColor:[UIColor clearColor]];
    [upperLabel setTextAlignment:NSTextAlignmentCenter];
    [upperLabel setFont:[UIFont fontWithName:@"OpenSans-Light" size:fontSize]];
    [upperLabel setTextColor:[UIColor colorWithRed:(114/255.0)
                                             green:(126/255.0)
                                              blue:(133/255.0)
                                             alpha:1.0]];
    
    [rangeSlider addSubview:upperLabel];
    
    NSInteger sliderScaleOffset;
    
    if ([type isEqualToString:@"calories"]) {
        
        sliderScaleOffset = 42;
        
    } else {
        
        sliderScaleOffset = 40;
    }
    
    UIView *sliderScale = [[UIView alloc] initWithFrame:CGRectMake(20, sliderScaleOffset, (screenWidth - 58), 30)];
    
    scaleHashSpacing = ((screenWidth - 58) / 20.0f);
    
    UIView *scaleHash;
    
    UILabel *scaleHashLabel;
    
    NSMutableArray *scaleHashValues = [[NSMutableArray alloc] init];
    
    NSInteger scaleHashCount = 0;
    NSInteger scaleLabelCount = 0;
    NSInteger scaleHashHeight;
    
    [scaleHashValues insertObject:@"" atIndex:0];
    [scaleHashValues insertObject:@"0" atIndex:1];
    
    float hashSteps = ((maxValue - minValue) / 4);
    
    for (int i=1; i<=4; i++) {
        
        [scaleHashValues insertObject:[NSString stringWithFormat:@"%d", (int)roundf(hashSteps * i)] atIndex:i+1];
    }
    
    for (float i=0; i<=((screenWidth - 58) + 1); i+=scaleHashSpacing) {
        
        if (scaleHashCount == 0) {
            
            scaleHashHeight = 8;
            
        } else {
            
            scaleHashHeight = 4;
        }
        
        scaleHash = [[UIView alloc] initWithFrame:CGRectMake(i, 0, 1, scaleHashHeight)];
        
        [scaleHash setBackgroundColor:[UIColor colorWithRed:(163/255.0)
                                                        green:(169/255.0)
                                                         blue:(172/255.0)
                                                        alpha:1.0]];
        
        [sliderScale addSubview:scaleHash];
        
        if (scaleHashCount == 0) {
            
            scaleLabelCount += 1;
            
            if (scaleLabelCount == 1) {
                
                scaleHashLabel = [[UILabel alloc] initWithFrame:CGRectMake(i-1, 16, 20, 12)];
                
                [scaleHashLabel setTextAlignment:NSTextAlignmentLeft];
                
            } else if (scaleLabelCount == 5) {
                
                scaleHashLabel = [[UILabel alloc] initWithFrame:CGRectMake(i-18, 16, 20, 12)];
                
                [scaleHashLabel setTextAlignment:NSTextAlignmentRight];
                
            } else {
                
                scaleHashLabel = [[UILabel alloc] initWithFrame:CGRectMake(i-9.5f, 16, 20, 12)];
                
                [scaleHashLabel setTextAlignment:NSTextAlignmentCenter];
            }
            
            scaleHashLabel.text = [scaleHashValues objectAtIndex:scaleLabelCount];
            
            [scaleHashLabel setFont:[UIFont fontWithName:@"OpenSans" size:10.0]];
            [scaleHashLabel setTextColor:[UIColor colorWithRed:(163/255.0)
                                                     green:(169/255.0)
                                                      blue:(172/255.0)
                                                     alpha:1.0]];
            
            [sliderScale addSubview:scaleHashLabel];
        }
        
        scaleHashCount += 1;
        
        if (scaleHashCount == 5) {
            
            scaleHashCount = 0;
        }
    }
    
    [rangeSlider addSubview:sliderScale];
    
    return rangeSlider;
}


- (void)updateSliderLabels:(NMRangeSlider*)sender {
    
    UILabel *lowerLabel = [[sender subviews] objectAtIndex:0];
    UILabel *upperLabel = [[sender subviews] objectAtIndex:1];
    
    CGPoint lowerCenter;
    lowerCenter.x = (sender.lowerCenter.x + sender.frame.origin.x) - 8;
    
    if (sender.tag == 101) { // calories slider
        
        lowerCenter.y = (sender.center.y - 116.0f);
        
    } else {
        
        lowerCenter.y = (sender.center.y - 76.5f);
    }
    
    if (lowerCenter.x != 0) { // initially
        
        lowerLabel.center = lowerCenter;
    }
    
    lowerLabel.text = [NSString stringWithFormat:@"%d", (int)sender.lowerValue];
    
    CGPoint upperCenter;
    upperCenter.x = (sender.upperCenter.x + sender.frame.origin.x) - 8;
    
    if (sender.tag == 101) { // calories slider
        
        upperCenter.y = (sender.center.y - 116.0f);
        
    } else {
        
        upperCenter.y = (sender.center.y - 76.5f);
    }
    
    if (upperCenter.x != 0) { // initially
        
        upperLabel.center = upperCenter;
    }
    
    [lowerLabel setTextAlignment:NSTextAlignmentCenter];
    
    if (((int)sender.upperValue == (int)sender.maximumValue)) {
        
        upperLabel.text = [NSString stringWithFormat:@"%d+", (int)sender.upperValue];
        
    } else {
        
        upperLabel.text = [NSString stringWithFormat:@"%d", (int)sender.upperValue];
    }
    
    if (((int)sender.upperValue == (int)sender.lowerValue)) {
        
        if (((int)sender.upperValue == (int)sender.maximumValue)) {
            
            lowerLabel.text = [NSString stringWithFormat:@"%d+",
                               (int)sender.lowerValue];
            
        } else {
            
            lowerLabel.text = [NSString stringWithFormat:@"%d",
                               (int)sender.lowerValue];
        }
        
        upperLabel.text = @"";
        
    } else if (((int)sender.upperValue - (int)sender.lowerValue) <
               (((int)sender.maximumValue - (int)sender.minimumValue) / 7.0f)) {
        
        if (((int)sender.upperValue == (int)sender.maximumValue)) {
            
            if (sender.tag == 101) { // calories slider
                
                [lowerLabel setTextAlignment:NSTextAlignmentLeft];
            }
            
            lowerLabel.text = [NSString stringWithFormat:@"%d - %d+",
                               (int)sender.lowerValue,
                               (int)sender.upperValue];
            
        } else {
            
            lowerLabel.text = [NSString stringWithFormat:@"%d - %d",
                               (int)sender.lowerValue,
                               (int)sender.upperValue];
        }
        
        upperLabel.text = @"";
    }
}

- (IBAction)labelSliderChanged:(NMRangeSlider*)sender {
    
    [self updateSliderLabels:sender];
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    self.xmlParser = [[NSXMLParser alloc] initWithData:data];

    [self.xmlParser setDelegate:self];
    [self.xmlParser setShouldProcessNamespaces:NO];
    [self.xmlParser setShouldReportNamespacePrefixes:NO];
    [self.xmlParser setShouldResolveExternalEntities:NO];
    [self.xmlParser parse];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"search_protein"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showProteinSlider = YES;
        
    } else if ([elementName isEqualToString:@"search_carbs"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showCarbsSlider = YES;
        
    } else if ([elementName isEqualToString:@"search_net_carbs"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showNetCarbsSlider = YES;
        
    } else if ([elementName isEqualToString:@"search_fat"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showFatSlider = YES;
        
    } else if ([elementName isEqualToString:@"search_sat_fat"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showSatFatSlider = YES;
        
    } else if ([elementName isEqualToString:@"search_products"] && [self.currentValue isEqualToString:@"1"]) {
        
        self.showSearchProducts = YES;
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
        
        [self showSearchFields];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTAddFoodSearchResultsViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    
    viewController.addFoodCategory = self.addFoodCategory;
    viewController.addFoodSearchString = self.addFoodSearchString;
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end