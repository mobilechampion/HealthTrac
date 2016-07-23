//
//  HTAddFoodSelectItemDetailsViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/10/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddFoodSelectItemDetailsViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTTextView.h"

@interface HTAddFoodSelectItemDetailsViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddFoodSelectItemDetailsViewController

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
    
    self.title = @"Food Item Details";
    
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
    
    self.selectedMealName = @"";
    self.selectedMealType = @"";
    self.selectedMealPrep = @"";
    
    self.selectedMealCalories = @"";
    self.selectedMealProtein = @"";
    self.selectedMealCarbs = @"";
    self.selectedMealFat = @"";
    self.selectedMealSatFat = @"";
    self.selectedMealSugars = @"";
    self.selectedMealFiber = @"";
    self.selectedMealSodium = @"";
    
    self.selectedMealDescription = @"";
    self.selectedMealServings = @"";
    self.selectedMealIngredients = @"";
    self.selectedMealDirections = @"";
    self.selectedMealRecommended = @"";
    self.selectedMealComments = @"";
    
    if (self.mealItemID != 0) {
        
        [self getMealItem:HTWebSvcURL withState:0];
        
    } else { // should never happen
        
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

#pragma mark - Methods

- (void)getMealItem:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_food_item_details&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&WhichID=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.mealItemID];
    
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

- (void)showMealItem {
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 64;
    
    UIView *selectedItemView;
    
    UILabel *selectedItemLabel;
    
    UIFont *favoriteSectionFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    UIFont *favoriteSectionBoldFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    // food item name
    
    selectedItemView = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 54)];
    
    [selectedItemView setBackgroundColor:[UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0]];
    
    selectedItemLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 32), 54)];
    
    [selectedItemLabel setNumberOfLines:2];
    [selectedItemLabel setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0]];
    [selectedItemLabel setTextColor:grayFontColor];
    [selectedItemLabel setTextAlignment:NSTextAlignmentLeft];
    [selectedItemLabel setText:self.selectedMealName];
    
    [selectedItemView addSubview:selectedItemLabel];
    
    [self.view addSubview:selectedItemView];
    
    [self.completeDetailsTextView setFont:favoriteSectionFont];
    [self.completeDetailsTextView setTextColor:grayFontColor];
    
    self.completeDetailsString = [[NSMutableAttributedString alloc]
                                  initWithString:@""];
    
    NSMutableAttributedString *detailsAttributedString;
    
    // description
    
    if (![self.selectedMealDescription isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"%@\n\n",
                                                   self.selectedMealDescription]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(0, self.selectedMealDescription.length)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // type
    
    if (![self.selectedMealType isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Type - %@\n\n",
                                                   self.selectedMealType]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 4)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(4, self.selectedMealType.length)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // prep effort
    
    if (![self.selectedMealPrep isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString
                                                   stringWithFormat:@"Preparation Effort - %@\n\n",
                                                   self.selectedMealPrep]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 18)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(18, self.selectedMealPrep.length)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // servings
    
    if (![self.selectedMealServings isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Servings - %@\n\n",
                                                   self.selectedMealServings]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 8)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(8, self.selectedMealServings.length)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // ingredients
    
    if (![self.selectedMealIngredients isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Ingredients\n%@\n\n",
                                                   self.selectedMealIngredients]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 11)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(11, self.selectedMealIngredients.length + 1)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // directions
    
    if (![self.selectedMealDirections isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Directions\n%@\n\n",
                                                   self.selectedMealDirections]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 10)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(10, self.selectedMealDirections.length + 1)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // recommended with
    
    if (![self.selectedMealRecommended isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Recommended With\n%@\n\n",
                                                   self.selectedMealRecommended]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 16)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(16, self.selectedMealRecommended.length + 1)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // comments
    
    if (![self.selectedMealComments isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Comments\n%@\n\n",
                                                   self.selectedMealComments]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 8)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(8, self.selectedMealComments.length + 1)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // calories
    
    if (![self.selectedMealCalories isEqualToString:@""]) {
        
        detailsAttributedString = [[NSMutableAttributedString alloc]
                                   initWithString:[NSString stringWithFormat:@"Calories - %@\n\n",
                                                   self.selectedMealCalories]];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionBoldFont
                                        range:NSMakeRange(0, 8)];
        
        [detailsAttributedString addAttribute:NSFontAttributeName
                                        value:favoriteSectionFont
                                        range:NSMakeRange(8, self.selectedMealCalories.length + 3)];
        
        [self.completeDetailsString appendAttributedString:detailsAttributedString];
    }
    
    // protein
    
    if ([self.selectedMealProtein isEqualToString:@""]) {
        
        self.selectedMealProtein = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString stringWithFormat:@"Protein - %@g\n\n",
                                               self.selectedMealProtein]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 7)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(7, self.selectedMealProtein.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];

    
    // carbs
    
    if ([self.selectedMealCarbs isEqualToString:@""]) {
        
        self.selectedMealCarbs = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Carbohydrates - %@g\n\n",
                                               self.selectedMealCarbs]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 13)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(13, self.selectedMealCarbs.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];

    
    // fat
    
    if ([self.selectedMealFat isEqualToString:@""]) {
        
        self.selectedMealFat = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Fat - %@g\n\n",
                                               self.selectedMealFat]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 3)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(3, self.selectedMealFat.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];
    

    // sat fat
    
    if ([self.selectedMealSatFat isEqualToString:@""]) {
        
        self.selectedMealSatFat = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Sat Fat - %@g\n\n",
                                               self.selectedMealSatFat]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 7)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(7, self.selectedMealSatFat.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];
    

    // sugars
    
    if ([self.selectedMealSugars isEqualToString:@""]) {
        
        self.selectedMealSugars = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Sugars - %@g\n\n",
                                               self.selectedMealSugars]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 6)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(6, self.selectedMealSugars.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];
    

    // fiber
    
    if ([self.selectedMealFiber isEqualToString:@""]) {
        
        self.selectedMealFiber = @"0";
    }
    
    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Fiber - %@g\n\n",
                                               self.selectedMealFiber]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 5)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(5, self.selectedMealFiber.length + 4)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];
    

    // sodium
    
    if ([self.selectedMealSodium isEqualToString:@""]) {
        
        self.selectedMealSodium = @"0";
    }

    detailsAttributedString = [[NSMutableAttributedString alloc]
                               initWithString:[NSString
                                               stringWithFormat:@"Sodium - %@mg\n\n",
                                               self.selectedMealSodium]];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionBoldFont
                                    range:NSMakeRange(0, 6)];
    
    [detailsAttributedString addAttribute:NSFontAttributeName
                                    value:favoriteSectionFont
                                    range:NSMakeRange(6, self.selectedMealSodium.length + 5)];
    
    [self.completeDetailsString appendAttributedString:detailsAttributedString];
    
    // make it all grayFontColor
    
    [self.completeDetailsString addAttribute:NSForegroundColorAttributeName
                                    value:grayFontColor
                                    range:NSMakeRange(0, self.completeDetailsString.length)];
    
    [self.completeDetailsTextView setAttributedText:self.completeDetailsString];
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

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
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
    
    self.selectedMealName = @"";
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
        
    } else if ([elementName isEqualToString:@"meal_item_name"]) {
        
        self.selectedMealName = [cleanString capitalizedString];
        
    } else if ([elementName isEqualToString:@"meal_item_type"]) {
        
        if ([cleanString isEqualToString:@"SN"]) {
            
            self.selectedMealType = @"Snack";
            
        } else if ([cleanString isEqualToString:@"AM"]) {
            
            self.selectedMealType = @"AM Meal";
            
        } else if ([cleanString isEqualToString:@"PM"]) {
            
            self.selectedMealType = @"PM Meal";
            
        } else if ([cleanString isEqualToString:@"Other"]) {
            
            self.selectedMealType = @"Other";
        }
        
    } else if ([elementName isEqualToString:@"meal_item_prep"]) {
        
        if ([cleanString isEqualToString:@"R"]) {
            
            self.selectedMealPrep = @"Ready to Eat";
            
        } else if ([cleanString isEqualToString:@"L"]) {
            
            self.selectedMealPrep = @"Low";
            
        } else if ([cleanString isEqualToString:@"M"]) {
            
            self.selectedMealPrep = @"Medium";
            
        } else if ([cleanString isEqualToString:@"H"]) {
            
            self.selectedMealPrep = @"High";
        }
        
    } else if ([elementName isEqualToString:@"meal_item_calories"]) {
        
        self.selectedMealCalories = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_protein"]) {
        
        self.selectedMealProtein = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_carbs"]) {
        
        self.selectedMealCarbs = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_fat"]) {
        
        self.selectedMealFat = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_sat_fat"]) {
        
        self.selectedMealSatFat = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_sugar"]) {
        
        self.selectedMealSugars = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_fiber"]) {
        
        self.selectedMealFiber = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_sodium"]) {
        
        self.selectedMealSodium = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_description"]) {
        
        self.selectedMealDescription = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_servings"]) {
        
        self.selectedMealServings = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_menu"]) {
        
        self.selectedMealIngredients = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_directions"]) {
        
        self.selectedMealDirections = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_servewith"]) {
        
        self.selectedMealRecommended = cleanString;
        
    } else if ([elementName isEqualToString:@"meal_item_nutrition"]) {
        
        self.selectedMealComments = cleanString;
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
        
        [self showMealItem];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
