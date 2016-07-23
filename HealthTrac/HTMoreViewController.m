//
//  HTMoreViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 9/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTMoreViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "JSBadgeView.h"
#import "UIView+Toast.h"

@interface HTMoreViewController ()

@end

@implementation HTMoreViewController

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    int screenWidth = self.view.frame.size.width;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2) - 50, 0, 100, 40)];
    
    [titleLabel setFont:[UIFont fontWithName:@"Omnes-Light" size:23.0]];
    [titleLabel setTextColor:[UIColor colorWithRed:(59/255.0)
                                             green:(183/255.0)
                                              blue:(234/255.0)
                                             alpha:1.0]];
    
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    NSMutableAttributedString *titleLabelString;
    
    titleLabelString = [[NSMutableAttributedString alloc]
                        initWithString:@"HealthTrac"];
    
    [titleLabelString addAttribute:NSFontAttributeName
                             value:[UIFont fontWithName:@"Omnes-Medium" size:23.0]
                             range:NSMakeRange([titleLabelString length] -4, 4)];
    
    titleLabel.attributedText = titleLabelString;
    
    self.navigationItem.titleView = titleLabel;
    
    NSArray *items = self.tabBarController.tabBar.items;
    
    NSInteger tabBarItemIndex = 4;
    
    if (appDelegate.hidePlanner == YES) {
        
        tabBarItemIndex = 3;
    }
    
    UITabBarItem *item = [items objectAtIndex:tabBarItemIndex];
    
    item.title = @"MORE";
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.tableView.separatorColor = [UIColor clearColor];
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
    
    [self getMorePanelItems:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getMorePanelItems:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.showInbox = NO;
    
    self.numberOfNewMessages = 0;
    self.numberOfEatingPlans = 0;
    self.numberOfLearningModules = 0;
    
    self.moreItems = [[NSMutableArray alloc] init];
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=app_more_panel_get_vals&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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
    
    [self.moreItems removeAllObjects];
    
    [self.tableView reloadData];
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
        
    } else if ([elementName isEqualToString:@"show_messages"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.showInbox = YES;
        }
        
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
        
        if (self.showInbox == YES) {
            
            [self.moreItems addObject:@"Inbox"];
            
        }
        
        [self.moreItems addObject:@"Sign Out"];
        
        [self.tableView reloadData];
        
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
        
        if (self.numberOfNewMessages > 0 && self.showInbox == YES) {
            
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
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.moreItems.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 82;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSArray *viewsToRemove = [cell subviews];
    
    for (UIView *v in viewsToRemove) {
        
        if ([v isKindOfClass:[UIImageView class]] || [v isKindOfClass:[UILabel class]]) {
            
            [v removeFromSuperview];
        }
    }
    
    int screenWidth = self.view.frame.size.width;
    int separatorOffset = cell.frame.size.height;
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    imgView.frame = CGRectMake((cell.frame.size.width/2)-(imgView.frame.size.width/2),
                            16, 32, 32);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 57, screenWidth, 19)];
    
    [label setTextColor:[UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0]];
    [label setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:12.0]];
    
    label.textAlignment = NSTextAlignmentCenter;
    
    UIView *graySeparator;
    
    if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Inbox"]) {
        
        [label setTag:1];
        
        imgView.image = [UIImage imageNamed:@"ht-more-inbox"];
        
        if (self.numberOfNewMessages > 0) {
            
            JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:imgView
                                                                   alignment:JSBadgeViewAlignmentTopRight];
            badgeView.badgeText = [NSString stringWithFormat:@"%ld", (long)self.numberOfNewMessages];
        }
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Devices & Apps"]) {
        
        imgView.image = [UIImage imageNamed:@"ht-more-devices"];
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Settings"]) {
        
        imgView.image = [UIImage imageNamed:@"ht-more-settings"];
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Store"]) {
        
        imgView.image = [UIImage imageNamed:@"ht-more-store"];
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Orders"]) {
        
        imgView.image = [UIImage imageNamed:@"ht-more-orders"];
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Sign Out"]) {
        
        [label setTag:6];
        
        imgView.image = [UIImage imageNamed:@"ht-more-sign-out"];
    }
    
    if (indexPath.row == 0) {
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [cell addSubview:graySeparator];
    }
    
    [cell addSubview:imgView];
    
    label.text = [[self.moreItems objectAtIndex:indexPath.row] uppercaseString];
    
    [cell addSubview:label];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, separatorOffset, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [cell addSubview:graySeparator];
    
    // these keep the separator bar from slightly disappearing when a call is selected, then de-selected
    cell.clipsToBounds = NO;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Inbox"]) {
        
        [self performSegueWithIdentifier:@"ShowInboxFromMore" sender:self];
        
    } else if ([[self.moreItems objectAtIndex:indexPath.row] isEqualToString:@"Sign Out"]) {
    
        appDelegate.passLogin = nil;
        appDelegate.passPw = nil;
        
        UINavigationController *navigationController = (UINavigationController *)self.navigationController;
        
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
        
        HTLoginViewController *viewController = (HTLoginViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"loginView"];
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        
        [navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    UIViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
