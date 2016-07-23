//
//  HTGoalEditViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/28/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTGoalEditViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"

@interface HTGoalEditViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTGoalEditViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.goal = [[NSString alloc] init];
    self.goalTime = [[NSString alloc] init];
    self.goalPlace = [[NSString alloc] init];
    self.goalSupport = [[NSString alloc] init];
    self.goalMotivation = [[NSString alloc] init];
    self.goalComment = [[NSString alloc] init];
    
    self.title = @"Set a Goal";
    
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
    
    // this panel must always be TODAY
    
    appDelegate.passDay = appDelegate.currentDay;
    appDelegate.passMonth = appDelegate.currentMonth;
    appDelegate.passYear = appDelegate.currentYear;
    appDelegate.passDate = appDelegate.currentDate;
    
    [self.leftDateArrow setUserInteractionEnabled:NO];
    [self.rightDateArrow setUserInteractionEnabled:NO];
    
    [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-gray"] forState:UIControlStateNormal];
    [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    
    self.doneEditingGoal = NO;
    
    self.navigationItem.leftBarButtonItem = [self cancelButton];
    self.navigationItem.rightBarButtonItem = [self doneButton];
    
    [self getGoal:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getGoal:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
    } else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
    } else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
    }
    
    myRequestString = [NSString stringWithFormat:@"action=get_goal&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)updateGoal:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.goal = [appDelegate cleanStringBeforeSending:self.goalField.text];
    self.goalTime = [appDelegate cleanStringBeforeSending:self.goalTimeField.text];
    self.goalPlace = [appDelegate cleanStringBeforeSending:self.goalPlaceField.text];
    self.goalSupport = [appDelegate cleanStringBeforeSending:self.goalSupportField.text];
    self.goalMotivation = [appDelegate cleanStringBeforeSending:self.goalMotivationField.text];
    self.goalComment = [appDelegate cleanStringBeforeSending:self.goalCommentField.text];
    
    myRequestString = [NSString stringWithFormat:@"action=update_goal&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&goal=%@&goal_time=%@&goal_place=%@&goal_support=%@&goal_motivation=%@&goal_comment=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.goal, self.goalTime, self.goalPlace, self.goalSupport, self.goalMotivation, self.goalComment];
    
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

- (void)showGoal {
    
    NSArray *viewsToRemove = [self.goalScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    NSInteger vPos = 0;
    NSInteger LabelOffset;
    
    UIView *graySeparator;
    
    UILabel *goalLabel;
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    int screenOffset = (self.view.frame.size.width - 320);
    int goalBlockHeight;
    
    if (screenHeight < 568) {
        
        goalBlockHeight = 62;;
        LabelOffset = 19;
        
    } else {
        
        goalBlockHeight = 76;
        LabelOffset = 25;
    }
    
    UIFont *goalLabelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    UIFont *goalFieldFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 104, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.view addSubview:graySeparator];
    
    self.goalField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(20, vPos + LabelOffset, (screenWidth - 40), 31)];
    
    [self.goalField setFont:goalFieldFont];
    [self.goalField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    UIColor *color = [UIColor colorWithRed:(117/255.0)
                                     green:(124/255.0)
                                      blue:(128/255.0)
                                     alpha:0.6];
    
    self.goalField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"My Goal" attributes:@{NSForegroundColorAttributeName: color}];
    
    [self.goalField setText:self.goal];
    
    [self.goalScrollView addSubview:self.goalField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Location"];
    
    [self.goalScrollView addSubview:goalLabel];
    
    self.goalPlaceField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalPlaceField setFont:goalFieldFont];
    [self.goalPlaceField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.goalPlaceField setText:self.goalPlace];
    
    [self.goalScrollView addSubview:self.goalPlaceField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Time / Frequency"];
    
    [self.goalScrollView addSubview:goalLabel];
    
    self.goalTimeField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalTimeField setFont:goalFieldFont];
    [self.goalTimeField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.goalTimeField setText:self.goalTime];
    
    [self.goalScrollView addSubview:self.goalTimeField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Preparation"];
    
    [self.goalScrollView addSubview:goalLabel];
    
    self.goalSupportField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalSupportField setFont:goalFieldFont];
    [self.goalSupportField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.goalSupportField setText:self.goalSupport];
    
    [self.goalScrollView addSubview:self.goalSupportField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"My Motivation"];
    
    [self.goalScrollView addSubview:goalLabel];
    
    self.goalMotivationField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalMotivationField setFont:goalFieldFont];
    [self.goalMotivationField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.goalMotivationField setText:self.goalMotivation];
    
    [self.goalScrollView addSubview:self.goalMotivationField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Goal Feedback"];
    
    [self.goalScrollView addSubview:goalLabel];
    
    self.goalCommentField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalCommentField setFont:goalFieldFont];
    [self.goalCommentField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.goalCommentField setText:self.goalComment];
    
    [self.goalScrollView addSubview:self.goalCommentField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalScrollView addSubview:graySeparator];
    
    [self.goalScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
    
    [self.goalField becomeFirstResponder];
}

- (UIBarButtonItem *)cancelButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(cancelButtonPressed)];
    return item;
}

- (UIBarButtonItem *)doneButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(doneButtonPressed)];
    return item;
}

- (void)cancelButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)doneButtonPressed {
    
    self.doneEditingGoal = YES;
    
    [self updateGoal:HTWebSvcURL withState:0];
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
    
    self.goal = nil;
    self.goalTime = nil;
    self.goalPlace = nil;
    self.goalSupport = nil;
    self.goalMotivation = nil;
    self.goalComment = nil;
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
        
    } else if ([elementName isEqualToString:@"goal"]) {
        
        self.goal = cleanString;
        
    } else if ([elementName isEqualToString:@"goal_time"]) {
        
        self.goalTime = self.currentValue;
        
    } else if ([elementName isEqualToString:@"goal_place"]) {
        
        self.goalPlace = cleanString;
        
    } else if ([elementName isEqualToString:@"goal_support"]) {
        
        self.goalSupport = cleanString;
        
    } else if ([elementName isEqualToString:@"goal_motivation"]) {
        
        self.goalMotivation = cleanString;
        
    } else if ([elementName isEqualToString:@"goal_comment"]) {
        
        self.goalComment = cleanString;
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
        
        if (self.doneEditingGoal == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else {
            
            [self showGoal];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (IBAction)leftDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getGoal:HTWebSvcURL withState:0];
}

- (IBAction)rightDateArrowClick:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getGoal:HTWebSvcURL withState:0];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
