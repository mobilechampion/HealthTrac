//
//  HTLearnViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 11/3/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTLearnViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTLearnDetailsViewController.h"

@interface HTLearnViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTLearnViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.title = @"Learning Modules";
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
    
    NSArray *items = self.tabBarController.tabBar.items;
    
    NSInteger tabBarItemIndex = 3;
    
    if (appDelegate.hidePlanner == YES) {
        
        tabBarItemIndex = 2;
    }
    
    UITabBarItem *item = [items objectAtIndex:tabBarItemIndex];
    
    item.title = @"LEARN";
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
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
    [appDelegate checkAppDatesWithPlanner:NO];
    
    [super viewWillAppear:animated];
    
    self.allowSelections = NO;
    
    [self getLearningModules:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getLearningModules:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    self.learningModuleCount = 0;
    
    self.numberOfNewMessages = 0;
    self.numberOfEatingPlans = 0;
    self.numberOfLearningModules = 0;
    
    self.learningModuleID = [[NSMutableArray alloc] init];
    self.learningModuleSessionID = [[NSMutableArray alloc] init];
    self.learningModuleStatus = [[NSMutableArray alloc] init];
    self.learningModuleTitle = [[NSMutableArray alloc] init];
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_learning_modules&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showLearningModules {
    
    NSArray *viewsToRemove = [self.learnScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    BOOL hasCurrentModules = NO;
    BOOL hasFutureModules = NO;
    BOOL hasArchivedModules = NO;
    
    BOOL headerOneShown = NO;
    BOOL headerTwoShown = NO;
    BOOL headerThreeShown = NO;
    
    NSInteger vPos = -54;
    NSInteger LabelOffset;
    
    UIView *graySeparator;
    UIView *learnBlock;
    
    UIButton *learnBlockButton;
    
    UILabel *learnLabel;
    
    UIImageView *learnImage;
    
    int screenWidth = self.view.frame.size.width;
    int learnBlockHeight;
    
    LabelOffset = 14;
    
    UIFont *learnHeaderFont = [UIFont fontWithName:@"AvenirNext-Medium" size:12.0];
    UIFont *learnTitleFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    for (int i=1; i<=self.learningModuleCount; i++) {
        
        if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UNLOCKED"] ||
            [[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"VIEWED"] ||
            [[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UPDATED"]) {
            
            hasCurrentModules = YES;
            
        } else if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"LOCKED"]) {
            
            hasFutureModules = YES;
            
        } else if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"DONE"]) {
            
            hasArchivedModules = YES;
        }
    }
    
    // learning modules
    
    if (self.learningModuleCount == 0) {
        
        learnBlockHeight = 86;
        
        learnBlock = [[UIView alloc] initWithFrame:CGRectMake(10, vPos, screenWidth - 20, learnBlockHeight)];
        
        [learnBlock setBackgroundColor:[UIColor whiteColor]];
        
        [learnBlock.layer setCornerRadius:2.5f];
        [learnBlock.layer setBorderWidth:0.7];
        [learnBlock.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                         green:(200/255.0)
                                                          blue:(204/255.0)
                                                         alpha:1.0].CGColor];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, LabelOffset, screenWidth - 60, 10)];
        [learnLabel setTextAlignment:NSTextAlignmentCenter];
        [learnLabel setFont:learnHeaderFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:@"YOUR NEXT MODULE"];
        
        [learnBlock addSubview:learnLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(15, LabelOffset + 20, screenWidth - 50, 1)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [learnBlock addSubview:graySeparator];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, LabelOffset + 36, screenWidth - 30, 20)];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setFont:learnTitleFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:@"There are no modules in this section"];
        
        [learnBlock addSubview:learnLabel];
        
        [self.learnScrollView addSubview:learnBlock];
        
        vPos += learnBlockHeight;
    }
    
    for (int i=1; i<=self.learningModuleCount; i++) {
        
        if (hasCurrentModules == NO && headerOneShown == NO) { // show the empty container for this section
            
            learnBlockHeight = 86;
            
            learnBlock = [[UIView alloc] initWithFrame:CGRectMake(10, vPos, screenWidth - 20, learnBlockHeight)];
            
            [learnBlock setBackgroundColor:[UIColor whiteColor]];
            
            [learnBlock.layer setCornerRadius:2.5f];
            [learnBlock.layer setBorderWidth:0.7];
            [learnBlock.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                             green:(200/255.0)
                                                              blue:(204/255.0)
                                                             alpha:1.0].CGColor];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, LabelOffset, screenWidth - 60, 10)];
            [learnLabel setTextAlignment:NSTextAlignmentCenter];
            [learnLabel setFont:learnHeaderFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"YOUR NEXT MODULE"];
            
            [learnBlock addSubview:learnLabel];
            
            graySeparator = [[UIView alloc] initWithFrame:CGRectMake(15, LabelOffset + 20, screenWidth - 50, 1)];
            graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
            
            [learnBlock addSubview:graySeparator];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, LabelOffset + 36, screenWidth - 30, 20)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnTitleFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"There are no modules in this section"];
            
            [learnBlock addSubview:learnLabel];
            
            [self.learnScrollView addSubview:learnBlock];
            
            vPos += learnBlockHeight;
            
            headerOneShown = YES;
        }
        
        if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UNLOCKED"] ||
            [[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"VIEWED"] ||
            [[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UPDATED"]) {
            
            if (headerOneShown == NO) {
                
                learnBlockHeight = 86;
                
                learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(10, vPos, screenWidth - 20, learnBlockHeight)];
                
                [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
                
                [learnBlockButton.layer setCornerRadius:2.5f];
                [learnBlockButton.layer setBorderWidth:0.7];
                [learnBlockButton.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                 green:(200/255.0)
                                                                  blue:(204/255.0)
                                                                 alpha:1.0].CGColor];
                
                learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, LabelOffset, screenWidth - 60, 10)];
                [learnLabel setTextAlignment:NSTextAlignmentCenter];
                [learnLabel setFont:learnHeaderFont];
                [learnLabel setTextColor:grayFontColor];
                [learnLabel setText:@"YOUR NEXT MODULE"];
                
                [learnBlockButton addSubview:learnLabel];
                
                graySeparator = [[UIView alloc] initWithFrame:CGRectMake(15, LabelOffset + 20, screenWidth - 50, 1)];
                graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
                
                [learnBlockButton addSubview:graySeparator];
                
                learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, LabelOffset + 30, 32, 32)];
                
                [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-blue"]];
                
                [learnBlockButton addSubview:learnImage];
                
                learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, LabelOffset + 36, screenWidth - 97, 20)];
                [learnLabel setTextAlignment:NSTextAlignmentLeft];
                [learnLabel setFont:learnTitleFont];
                [learnLabel setTextColor:grayFontColor];
                [learnLabel setText:[self.learningModuleTitle objectAtIndex:i]];
                
                [learnBlockButton addSubview:learnLabel];
                
                [learnBlockButton setTag:i];
                
                [learnBlockButton addTarget:self
                                     action:@selector(selectLearningModule:)
                           forControlEvents:UIControlEventTouchUpInside];
                
                [self.learnScrollView addSubview:learnBlockButton];
                
                vPos += learnBlockHeight;
                
                headerOneShown = YES;
                
            } else { // additional "current" modules
                
                vPos += 4;
                
                learnBlockHeight = 51;
                
                learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(10, vPos, screenWidth - 20, learnBlockHeight)];
                
                [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
                
                [learnBlockButton.layer setCornerRadius:2.5f];
                [learnBlockButton.layer setBorderWidth:0.7];
                [learnBlockButton.layer setBorderColor:[UIColor colorWithRed:(194/255.0)
                                                                 green:(200/255.0)
                                                                  blue:(204/255.0)
                                                                 alpha:1.0].CGColor];
                
                learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 32, 32)];
                
                [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-blue"]];
                
                [learnBlockButton addSubview:learnImage];
                
                learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 16, screenWidth - 97, 20)];
                [learnLabel setTextAlignment:NSTextAlignmentLeft];
                [learnLabel setFont:learnTitleFont];
                [learnLabel setTextColor:grayFontColor];
                [learnLabel setText:[self.learningModuleTitle objectAtIndex:i]];
                
                [learnBlockButton addSubview:learnLabel];
                
                [learnBlockButton setTag:i];
                
                [learnBlockButton addTarget:self
                                     action:@selector(selectLearningModule:)
                           forControlEvents:UIControlEventTouchUpInside];
                
                [self.learnScrollView addSubview:learnBlockButton];
                
                vPos += learnBlockHeight;
            }
        }
        
        if (hasFutureModules == NO && headerTwoShown == NO && (i == self.learningModuleCount ||
            (![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UNLOCKED"] &&
            ![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"VIEWED"] &&
            ![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UPDATED"]))) { // show the empty container for this section
            
            vPos += 22;
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, vPos, screenWidth - 20, 10)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnHeaderFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"FUTURE MODULES"];
            
            [self.learnScrollView addSubview:learnLabel];
            
            vPos += 22;
            
            learnBlockHeight = 51;
            
            learnBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
            
            [learnBlock setBackgroundColor:[UIColor whiteColor]];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, screenWidth - 30, 20)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnTitleFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"There are no modules in this section"];
            
            [learnBlock addSubview:learnLabel];
            
            [self.learnScrollView addSubview:learnBlock];
            
            vPos += learnBlockHeight;
            
            headerTwoShown = YES;
        }
        
        if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"LOCKED"]) {
            
            if (headerTwoShown == NO) { // just show the header
                
                vPos += 22;
                
                learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, vPos, screenWidth - 20, 10)];
                [learnLabel setTextAlignment:NSTextAlignmentLeft];
                [learnLabel setFont:learnHeaderFont];
                [learnLabel setTextColor:grayFontColor];
                [learnLabel setText:@"FUTURE MODULES"];
                
                [self.learnScrollView addSubview:learnLabel];
                
                headerTwoShown = YES;
                
                vPos += 18;
            }
            
            vPos += 4;
            
            learnBlockHeight = 51;
            
            learnBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
            
            [learnBlock setBackgroundColor:[UIColor whiteColor]];
            
            learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 32, 32)];
            
            [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-blue"]];
            
            [learnBlock addSubview:learnImage];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 16, screenWidth - 77, 20)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnTitleFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:[self.learningModuleTitle objectAtIndex:i]];
            
            [learnBlock addSubview:learnLabel];
            
            [self.learnScrollView addSubview:learnBlock];
            
            vPos += learnBlockHeight;
        }
        
        if (hasArchivedModules == NO && headerThreeShown == NO && (i == self.learningModuleCount ||
            (![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UNLOCKED"] &&
            ![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"VIEWED"] &&
            ![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"UPDATED"] &&
            ![[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"LOCKED"]))) { // show the empty container for this section
            
            vPos += 22;
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, vPos, screenWidth - 20, 10)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnHeaderFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"ARCHIVED MODULES"];
            
            [self.learnScrollView addSubview:learnLabel];
            
            vPos += 22;
            
            learnBlockHeight = 51;
            
            learnBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
            
            [learnBlock setBackgroundColor:[UIColor whiteColor]];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 16, screenWidth - 30, 20)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnTitleFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:@"There are no modules in this section"];
            
            [learnBlock addSubview:learnLabel];
            
            [self.learnScrollView addSubview:learnBlock];
            
            vPos += learnBlockHeight;
            
            headerThreeShown = YES;
        }
        
        if ([[self.learningModuleStatus objectAtIndex:i] isEqualToString:@"DONE"]) {
            
            if (headerThreeShown == NO) { // just show the header
                
                vPos += 22;
                
                learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, vPos, screenWidth - 20, 10)];
                [learnLabel setTextAlignment:NSTextAlignmentLeft];
                [learnLabel setFont:learnHeaderFont];
                [learnLabel setTextColor:grayFontColor];
                [learnLabel setText:@"ARCHIVED MODULES"];
                
                [self.learnScrollView addSubview:learnLabel];
                
                headerThreeShown = YES;
                
                vPos += 18;
            }
            
            vPos += 4;
            
            learnBlockHeight = 51;
            
            learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
            
            [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
            
            learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 10, 32, 32)];
            
            [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-gray"]];
            
            [learnBlockButton addSubview:learnImage];
            
            learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(62, 16, screenWidth - 77, 20)];
            [learnLabel setTextAlignment:NSTextAlignmentLeft];
            [learnLabel setFont:learnTitleFont];
            [learnLabel setTextColor:grayFontColor];
            [learnLabel setText:[self.learningModuleTitle objectAtIndex:i]];
            
            [learnBlockButton addSubview:learnLabel];
            
            [learnBlockButton setTag:i];
            
            [learnBlockButton addTarget:self
                                 action:@selector(selectLearningModule:)
                       forControlEvents:UIControlEventTouchUpInside];
            
            [self.learnScrollView addSubview:learnBlockButton];
            
            vPos += learnBlockHeight;
        }
    }
    
    [self.learnScrollView setContentSize:CGSizeMake(screenWidth, vPos + 4)];
    
    [self.learnScrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    self.allowSelections = YES;
}

- (void)selectLearningModule:(id)sender {
    
    if (self.allowSelections == YES) {
        
        UIButton *selectedButton = sender;
        
        self.selectedLearningModuleID = [[self.learningModuleSessionID
                                          objectAtIndex:selectedButton.tag] integerValue];
        
        [self performSegueWithIdentifier:@"showLearningModuleDetails" sender:self];
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
    
    self.learningModuleCount = 0;
    
    [self.learningModuleID removeAllObjects];
    [self.learningModuleSessionID removeAllObjects];
    [self.learningModuleStatus removeAllObjects];
    [self.learningModuleTitle removeAllObjects];
    
    [self.learningModuleID insertObject:@"" atIndex:0];
    [self.learningModuleSessionID insertObject:@"" atIndex:0];
    [self.learningModuleStatus insertObject:@"" atIndex:0];
    [self.learningModuleTitle insertObject:@"" atIndex:0];
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
    
    NSString *cleanStr = [[NSString alloc] init];
    
    cleanStr = [appDelegate cleanStringAfterReceiving:self.currentValue];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName hasPrefix:@"learning_module_item_"]) { // learning modules! set learningModuleCount
        
        self.learningModuleCount = [[elementName stringByReplacingOccurrencesOfString:@"learning_module_item_" withString:@""] integerValue];
        
    } else if ([elementName hasPrefix:@"learning_module_id_"]) {
        
        [self.learningModuleID insertObject:self.currentValue
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"learning_module_id_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_session_id_"]) {
        
        [self.learningModuleSessionID insertObject:self.currentValue
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"learning_module_session_id_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_session_status_"]) {
        
        [self.learningModuleStatus insertObject:self.currentValue
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"learning_module_session_status_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_title_"]) {
        
        [self.learningModuleTitle insertObject:cleanStr
                                   atIndex:[[elementName
                                             stringByReplacingOccurrencesOfString:@"learning_module_title_" withString:@""]
                                            integerValue]];
        
    } else if ([elementName isEqualToString:@"new_messages"]) {
        
        self.numberOfNewMessages = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"new_eating_plan"]) {
        
        self.numberOfEatingPlans = [self.currentValue integerValue];
        
    } else if ([elementName isEqualToString:@"new_learning_modules"]) {
        
        self.numberOfLearningModules = [self.currentValue integerValue];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        NSInteger appIconBadgeCount = 0;
        appIconBadgeCount = self.numberOfNewMessages + self.numberOfLearningModules;
        if (appDelegate.hidePlanner == NO){
            appIconBadgeCount = appIconBadgeCount + self.numberOfEatingPlans;
        }
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:appIconBadgeCount];
        
        UITabBarItem *itemDashboard;
        UITabBarItem *itemPlanner;
        UITabBarItem *itemLearn;
        UITabBarItem *itemMore;
        
        if (appDelegate.hidePlanner == YES) {
            
            itemDashboard = [self.tabBarController.tabBar.items objectAtIndex:0];
            itemLearn = [self.tabBarController.tabBar.items objectAtIndex:2];
            itemMore = [self.tabBarController.tabBar.items objectAtIndex:3];
        
        } else {
            
            itemDashboard = [self.tabBarController.tabBar.items objectAtIndex:0];
            itemPlanner = [self.tabBarController.tabBar.items objectAtIndex:2];
            itemLearn = [self.tabBarController.tabBar.items objectAtIndex:3];
            itemMore = [self.tabBarController.tabBar.items objectAtIndex:4];
            
            itemPlanner.badgeValue = nil;
        }
        
        itemDashboard.badgeValue = nil;
        itemLearn.badgeValue = nil;
        itemMore.badgeValue = nil;
        
        if (self.numberOfNewMessages > 0) {
            
            itemMore.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            
            NSMutableDictionary *dashboardUserPrefs = [[NSMutableDictionary alloc] init];
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            
            NSString *userPrefsString;
            
            userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
            
            if([prefs objectForKey:userPrefsString] != nil) { // exists
                
                dashboardUserPrefs = [NSMutableDictionary dictionaryWithDictionary:[prefs objectForKey:userPrefsString]];
                
                if (![[dashboardUserPrefs objectForKey:@"Inbox"] isEqualToString:@"0"]) {
                    
                    itemDashboard.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
                }
                
            } else { // no prefs, but messages, so show it
                
                itemDashboard.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
            }
        }
        
        if (self.numberOfEatingPlans > 0 && appDelegate.hidePlanner == NO) {
            
            itemPlanner.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfEatingPlans];
        }
        
        if (self.numberOfLearningModules > 0) {
            
            itemLearn.badgeValue = [NSString stringWithFormat:@"%ld", (long)self.numberOfLearningModules];
        }
        
        [self showLearningModules];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTLearnDetailsViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.learningModuleID = self.selectedLearningModuleID;
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
