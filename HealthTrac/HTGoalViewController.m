//
//  HTGoalViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/27/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTGoalViewController.h"
#import "HTGoalEditViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTextField.h"
#import "HTTrackerReminderViewController.h"

@interface HTGoalViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTGoalViewController

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
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
        self.navigationItem.leftBarButtonItem = [self backButton];
        self.navigationItem.rightBarButtonItem = [self editButton];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
        self.navigationItem.leftBarButtonItem = [self backButton];
        self.navigationItem.rightBarButtonItem = [self editButton];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
        
        self.navigationItem.leftBarButtonItem = [self backButton];
        self.navigationItem.rightBarButtonItem = [self editButton];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    
    self.goalReminder = NO;
    
    [self getGoal:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getGoal:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.goalReminder = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
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

- (void)showGoal {
    
    NSArray *viewsToRemove = [self.goalView subviews];
    
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
        
        goalBlockHeight = 62;
        LabelOffset = 19;
        
    } else {
        
        goalBlockHeight = 76;
        LabelOffset = 25;
    }
    
    UIFont *goalLabelFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    UIFont *goalFieldFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    UIButton *reminderButton;
    
    UIImageView *reminderButtonImage;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 104, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.view addSubview:graySeparator];
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos + LabelOffset, 50, 31)];
    
    [reminderButton setTag:1];
    
    [reminderButton addTarget:self action:@selector(setReminder) forControlEvents:UIControlEventTouchUpInside];
    
    reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(20, 7, 16, 16)];
    
    if (self.goalReminder == YES) {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
        
    } else {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
    }
    
    [reminderButton addSubview:reminderButtonImage];
    
    [self.goalView addSubview:reminderButton];
    
    self.goalField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(50, vPos + LabelOffset, (screenWidth - 70), 31)];
    
    [self.goalField setEnabled:NO];
    [self.goalField setUserInteractionEnabled:NO];
    [self.goalField setFont:goalFieldFont];
    [self.goalField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalField setBackgroundColor:[UIColor whiteColor]];
    [self.goalField.layer setCornerRadius:0.0f];
    [self.goalField.layer setBorderWidth:0.0f];
    [self.goalField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    if ([self.goal isEqualToString:@""]) {
        
        [self.goalField setTextColor:[UIColor colorWithRed:(178/255.0)
                                                           green:(178/255.0)
                                                            blue:(178/255.0) alpha:1.0]];
        
        [self.goalField setFont:[UIFont fontWithName:@"OpenSans-Light" size:16.0]];
        
        [self.goalField setText:@"(Click Edit to add)"];
        
        [self.goalField setEnabled:YES];
        [self.goalField setUserInteractionEnabled:YES];
        
        [self.goalField addTarget:self action:@selector(editButtonPressed)
                 forControlEvents:UIControlEventTouchDown];
        
    } else {
        
        [self.goalField setText:self.goal];
    }
    
    [self.goalView addSubview:self.goalField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Location"];
    
    [self.goalView addSubview:goalLabel];
    
    self.goalPlaceField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalPlaceField setEnabled:NO];
    [self.goalPlaceField setUserInteractionEnabled:NO];
    [self.goalPlaceField setFont:goalFieldFont];
    [self.goalPlaceField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalPlaceField setBackgroundColor:[UIColor whiteColor]];
    [self.goalPlaceField.layer setCornerRadius:0.0f];
    [self.goalPlaceField.layer setBorderWidth:0.0f];
    [self.goalPlaceField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.goalPlaceField setText:self.goalPlace];
    
    [self.goalView addSubview:self.goalPlaceField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Time / Frequency"];
    
    [self.goalView addSubview:goalLabel];
    
    self.goalTimeField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalTimeField setEnabled:NO];
    [self.goalTimeField setUserInteractionEnabled:NO];
    [self.goalTimeField setFont:goalFieldFont];
    [self.goalTimeField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalTimeField setBackgroundColor:[UIColor whiteColor]];
    [self.goalTimeField.layer setCornerRadius:0.0f];
    [self.goalTimeField.layer setBorderWidth:0.0f];
    [self.goalTimeField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.goalTimeField setText:self.goalTime];
    
    [self.goalView addSubview:self.goalTimeField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Preparation"];
    
    [self.goalView addSubview:goalLabel];
    
    self.goalSupportField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalSupportField setEnabled:NO];
    [self.goalSupportField setUserInteractionEnabled:NO];
    [self.goalSupportField setFont:goalFieldFont];
    [self.goalSupportField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalSupportField setBackgroundColor:[UIColor whiteColor]];
    [self.goalSupportField.layer setCornerRadius:0.0f];
    [self.goalSupportField.layer setBorderWidth:0.0f];
    [self.goalSupportField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.goalSupportField setText:self.goalSupport];
    
    [self.goalView addSubview:self.goalSupportField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"My Motivation"];
    
    [self.goalView addSubview:goalLabel];
    
    self.goalMotivationField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalMotivationField setEnabled:NO];
    [self.goalMotivationField setUserInteractionEnabled:NO];
    [self.goalMotivationField setFont:goalFieldFont];
    [self.goalMotivationField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalMotivationField setBackgroundColor:[UIColor whiteColor]];
    [self.goalMotivationField.layer setCornerRadius:0.0f];
    [self.goalMotivationField.layer setBorderWidth:0.0f];
    [self.goalMotivationField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.goalMotivationField setText:self.goalMotivation];
    
    [self.goalView addSubview:self.goalMotivationField];
    
    vPos += goalBlockHeight;

    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
    
    goalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    [goalLabel setTextAlignment:NSTextAlignmentLeft];
    [goalLabel setFont:goalLabelFont];
    [goalLabel setTextColor:grayFontColor];
    [goalLabel setText:@"Goal Feedback"];
    
    [self.goalView addSubview:goalLabel];
    
    self.goalCommentField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(160 + (screenOffset / 2), vPos + LabelOffset, 140 + (screenOffset / 2), 31)];
    
    [self.goalCommentField setEnabled:NO];
    [self.goalCommentField setUserInteractionEnabled:NO];
    [self.goalCommentField setFont:goalFieldFont];
    [self.goalCommentField setKeyboardType:UIKeyboardTypeASCIICapable];
    [self.goalCommentField setBackgroundColor:[UIColor whiteColor]];
    [self.goalCommentField.layer setCornerRadius:0.0f];
    [self.goalCommentField.layer setBorderWidth:0.0f];
    [self.goalCommentField.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    [self.goalCommentField setText:self.goalComment];
    
    [self.goalView addSubview:self.goalCommentField];
    
    vPos += goalBlockHeight;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.goalView addSubview:graySeparator];
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

- (UIBarButtonItem *)editButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(editButtonPressed)];
    return item;
}

- (UIBarButtonItem *)newButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"New"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(newButtonPressed)];
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)editButtonPressed {
    
    [self performSegueWithIdentifier:@"showGoalEdit" sender:self];
}

- (void)newButtonPressed {
    
    [self performSegueWithIdentifier:@"showGoalEdit" sender:self];
}

- (IBAction)setReminder {
    
    [self performSegueWithIdentifier:@"showRemindersFromGoal" sender:self];
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
    
    NSString *cleanStr = [[NSString alloc] init];
    
    cleanStr = [appDelegate cleanStringAfterReceiving:self.currentValue];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"goal"]) {
        
        self.goal = cleanStr;
        
    } else if ([elementName isEqualToString:@"goal_time"]) {
        
        self.goalTime = self.currentValue;
        
    } else if ([elementName isEqualToString:@"goal_place"]) {
        
        self.goalPlace = cleanStr;
        
    } else if ([elementName isEqualToString:@"goal_support"]) {
        
        self.goalSupport = cleanStr;
        
    } else if ([elementName isEqualToString:@"goal_motivation"]) {
        
        self.goalMotivation = cleanStr;
        
    } else if ([elementName isEqualToString:@"goal_comment"]) {
        
        self.goalComment = cleanStr;
        
    } else if ([elementName isEqualToString:@"goal_reminder"]) {
        
        if ([cleanStr isEqualToString:@"Y"]) {
            
            self.goalReminder = YES;
            
        } else {
            
            self.goalReminder = NO;
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
        
        [self showGoal];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     
     if ([segue.identifier isEqualToString:@"showRemindersFromGoal"]) {
     
         HTTrackerReminderViewController *viewController = segue.destinationViewController;
         
         viewController.hidesBottomBarWhenPushed = YES;
         viewController.reminderType = @"goal";
         
     } else {
         
         UIViewController *viewController = segue.destinationViewController;
         
         viewController.hidesBottomBarWhenPushed = YES;
     }
 }
 
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
