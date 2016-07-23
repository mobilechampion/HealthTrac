//
//  HTAddFoodViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/4/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddFoodViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTAddFoodSearchViewController.h"

@interface HTAddFoodViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTAddFoodViewController

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
    
    self.title = @"Add Food";
    
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
    
    [super viewWillAppear:animated];
    
    self.showAddFoodFavorites = NO;
    self.showAddFoodRecommended = NO;
    self.showAddFoodGeneral = NO;
    
    self.numberOfaddFoodButtons = 0;
    
    [self getAddFoodCategories:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getAddFoodCategories:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_add_food&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showAddFoodCategories {

    NSArray *viewsToRemove = [self.addFoodView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = 0;
    
    NSInteger addFoodButtonHeight;
    
    UIView *graySeparator;
    
    UIButton *addFoodButton;
    
    UIImageView *buttonImageView;
    
    UIFont *addFoodFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];

    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    if (self.numberOfaddFoodButtons == 0) {
        
        self.numberOfaddFoodButtons = 1;
    }
    
    addFoodButtonHeight = ((screenHeight - 71) / self.numberOfaddFoodButtons);
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];

    [self.addFoodView addSubview:graySeparator];
    
    vPos += 8;
    
    if (self.showAddFoodFavorites == YES) {
        
        addFoodButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addFoodButtonHeight)];
        
        [addFoodButton setTitleEdgeInsets:UIEdgeInsetsMake(((addFoodButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
        
        addFoodButton.titleLabel.font = addFoodFont;
        
        [addFoodButton setTitleColor:grayFontColor forState:UIControlStateNormal];
        [addFoodButton setTitle:@"My Favorites" forState:UIControlStateNormal];
        
        buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addFoodButtonHeight / 5), 48, 48)];
        
        [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-food-select"]];
        
        [addFoodButton addSubview:buttonImageView];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addFoodButtonHeight - 8), screenWidth, 8)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [addFoodButton addSubview:graySeparator];
        
        [addFoodButton setTag:1];
        
        [addFoodButton addTarget:self action:@selector(addFoodSelectCategory:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.addFoodView addSubview:addFoodButton];
        
        vPos += addFoodButtonHeight;
    }
    
    if (self.showAddFoodRecommended == YES) {
        
        addFoodButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addFoodButtonHeight)];
        
        [addFoodButton setTitleEdgeInsets:UIEdgeInsetsMake(((addFoodButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
        
        addFoodButton.titleLabel.font = addFoodFont;
        
        [addFoodButton setTitleColor:grayFontColor forState:UIControlStateNormal];
        [addFoodButton setTitle:@"Recommended" forState:UIControlStateNormal];
        
        buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addFoodButtonHeight / 5), 48, 48)];
        
        [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-food-select"]];
        
        [addFoodButton addSubview:buttonImageView];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addFoodButtonHeight - 8), screenWidth, 8)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [addFoodButton addSubview:graySeparator];
        
        [addFoodButton setTag:2];
        
        [addFoodButton addTarget:self action:@selector(addFoodSelectCategory:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.addFoodView addSubview:addFoodButton];
        
        vPos += addFoodButtonHeight;
    }
    
    if (self.showAddFoodGeneral == YES) {
        
        addFoodButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addFoodButtonHeight)];
        
        [addFoodButton setTitleEdgeInsets:UIEdgeInsetsMake(((addFoodButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
        
        addFoodButton.titleLabel.font = addFoodFont;
        
        [addFoodButton setTitleColor:grayFontColor forState:UIControlStateNormal];
        [addFoodButton setTitle:@"General Food Item" forState:UIControlStateNormal];
        
        buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addFoodButtonHeight / 5), 48, 48)];
        
        [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-food-select"]];
        
        [addFoodButton addSubview:buttonImageView];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addFoodButtonHeight - 8), screenWidth, 8)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [addFoodButton addSubview:graySeparator];
        
        [addFoodButton setTag:3];
        
        [addFoodButton addTarget:self action:@selector(addFoodSelectCategory:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.addFoodView addSubview:addFoodButton];
        
        vPos += addFoodButtonHeight;
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

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)addFoodSelectCategory:(id)sender {
    
    UIButton *button = sender;
    
    if (button.tag == 1) {
        
        self.addFoodCategory = @"favorites";
        
    } else if (button.tag == 2) {
        
        self.addFoodCategory = @"recommended";
        
    } else if (button.tag == 3) {
        
        self.addFoodCategory = @"general";
    }
    
    if (button.tag == 3) {
        
        [self performSegueWithIdentifier:@"showGeneralSearchResults" sender:self];
        
    } else {
        
        [self performSegueWithIdentifier:@"showFoodSearchFromAddFood" sender:self];
    }
    
    
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
    
    self.showAddFoodFavorites = NO;
    self.showAddFoodRecommended = NO;
    self.showAddFoodGeneral = NO;
    
    self.numberOfaddFoodButtons = 0;
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
        
    } else if ([elementName isEqualToString:@"add_food_favorites"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.showAddFoodFavorites = YES;
            
            self.numberOfaddFoodButtons += 1;
        }
        
    } else if ([elementName isEqualToString:@"add_food_recommended"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.showAddFoodRecommended = YES;
            
            self.numberOfaddFoodButtons += 1;
        }
        
    } else if ([elementName isEqualToString:@"add_food_general"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.showAddFoodGeneral = YES;
            
            self.numberOfaddFoodButtons += 1;
        }
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
        
        [self showAddFoodCategories];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTAddFoodSearchViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    
    viewController.addFoodCategory = self.addFoodCategory;
}


#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end