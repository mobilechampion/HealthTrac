//
//  HTLearnWorksheetViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/13/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTLearnWorksheetViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "HTTextView.h"
#import "UIView+Toast.h"

@interface HTLearnWorksheetViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTLearnWorksheetViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.view autoresizesSubviews];
    
    self.navigationController.navigationBar.hidden = NO;
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.navigationItem.rightBarButtonItem = [self doneButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Learning Modules";
    
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
    
    self.doneWithWorksheet = NO;
    
    self.learningModuleTitle = @"";
    
    self.learningModuleWorksheetTextViews = [[NSMutableArray alloc] init];
    self.learningModuleWorksheetIDs = [[NSMutableArray alloc] init];
    self.learningModuleWorksheetQuestions = [[NSMutableArray alloc] init];
    self.learningModuleWorksheetAnswers = [[NSMutableArray alloc] init];
    
    [self getLearningModuleWorksheet:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getLearningModuleWorksheet:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.doneWithWorksheet = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_learning_module_details&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&session_id=%ld&worksheet=true", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.learningModuleID];
    
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

- (void)updateLearningModuleWorksheet:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    self.showConnError = NO;
    self.doneWithWorksheet = YES;
    
    NSString *myRequestString;
    NSString *cleanString = @"";
    NSMutableString *worksheetAnswers = [[NSMutableString alloc] initWithString:@""];
    
    for (UIView *view in [self.learnScrollView subviews]) {
        
        if ([view isKindOfClass:[UIView class]]) {
            
            for (UIView *subview in [view subviews]) {
                
                if ([subview isKindOfClass:[UITextView class]]) {
                    
                    [self.learningModuleWorksheetTextViews addObject:subview];
                }
            }
        }
    }
    
    for (int i=1; i<[self.learningModuleWorksheetTextViews count]; i++) {
        
        cleanString = [((UITextView*)[self.learningModuleWorksheetTextViews objectAtIndex:i]).text
                       stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceCharacterSet]];
        
        cleanString = [appDelegate cleanStringBeforeSending:cleanString];

        if ([cleanString isEqualToString:@""]) {
            
            cleanString = @"|*|delete|*|";
        }
        
        [worksheetAnswers
         appendString:[NSString stringWithFormat:@"&ws_answer_%d=%@", i,
                       cleanString]];
    }
    
    myRequestString = [NSString stringWithFormat:@"action=update_learning_module_worksheet&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&session_id=%ld&worksheet=true%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.learningModuleID, worksheetAnswers];
    
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

- (void)showLearningModuleWorksheet {
    
    NSArray *viewsToRemove = [self.learnScrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    NSInteger vPos = -64;

    UIView *learnBlock;
    UIView *whiteSeparator;
    
    UITextView *learnTextView;

    UILabel *learnLabel;
    
    int screenWidth = self.view.frame.size.width;
    int learnBlockHeight;

    UIFont *learnTitleFont = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    UIFont *learnLabelFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    learnBlockHeight = 64;
    
    learnBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
    
    learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 32), learnBlockHeight)];
    
    learnLabel.numberOfLines = 2;
    
    [learnLabel setTextAlignment:NSTextAlignmentLeft];
    [learnLabel setFont:learnTitleFont];
    [learnLabel setTextColor:grayFontColor];
    [learnLabel setText:self.learningModuleTitle];
    
    [learnBlock addSubview:learnLabel];
    
    [self.learnScrollView addSubview:learnBlock];
    
    vPos += learnBlockHeight;
    
    whiteSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
    whiteSeparator.backgroundColor = [UIColor whiteColor];
    
    [self.learnScrollView addSubview:whiteSeparator];
    
    vPos += 4;
    
    learnBlockHeight = 150;
    
    for (int i=1; i<[self.learningModuleWorksheetIDs count]; i++) {
        
        learnBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, (screenWidth - 32), 40)];
        
        learnLabel.numberOfLines = 0;
        
        [learnLabel setFont:learnLabelFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setText:[self.learningModuleWorksheetQuestions objectAtIndex:i]];
        [learnLabel sizeToFit];
        
        [learnBlock addSubview:learnLabel];
        
        learnTextView = [[HTTextView alloc] initHTDefaultWithFrame:CGRectMake(16,
                                                                              (learnLabel.frame.size.height + 18), (screenWidth - 32), 74)];
        
        [learnTextView setTextColor:grayFontColor];
        
        learnTextView.text = [self.learningModuleWorksheetAnswers objectAtIndex:i];
        
        [learnBlock addSubview:learnTextView];
        
        whiteSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (learnLabel.frame.size.height + 108),
                                                                  screenWidth, 4)];
        whiteSeparator.backgroundColor = [UIColor whiteColor];
        
        [learnBlock addSubview:whiteSeparator];
        
        [self.learnScrollView addSubview:learnBlock];
        
        vPos += (learnLabel.frame.size.height + 112);
    }
    
    [self.learnScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
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

- (UIBarButtonItem *)doneButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed)];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)doneButtonPressed {
    
    [self updateLearningModuleWorksheet:HTWebSvcURL withState:0];
}

#pragma mark - UINavigationController delegate methods

// CHECKIT - UIInterfaceOrientationMask

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
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
    
    self.learningModuleTitle = @"";
    
    [self.learningModuleWorksheetTextViews removeAllObjects];
    [self.learningModuleWorksheetIDs removeAllObjects];
    [self.learningModuleWorksheetQuestions removeAllObjects];
    [self.learningModuleWorksheetAnswers removeAllObjects];
    
    [self.learningModuleWorksheetTextViews insertObject:@"" atIndex:0];
    [self.learningModuleWorksheetIDs insertObject:@"" atIndex:0];
    [self.learningModuleWorksheetQuestions insertObject:@"" atIndex:0];
    [self.learningModuleWorksheetAnswers insertObject:@"" atIndex:0];
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
        
        self.webSvcError = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_title"]) {
        
        self.learningModuleTitle = cleanStr;
        
    } else if ([elementName hasPrefix:@"learning_module_worksheet_id_"]) {
        
        [self.learningModuleWorksheetIDs insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_worksheet_id_" withString:@""]
                                                                        integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_worksheet_question_"]) {
        
        [self.learningModuleWorksheetQuestions insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_worksheet_question_" withString:@""]
                                                                        integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_worksheet_response_"]) {
        
        [self.learningModuleWorksheetAnswers insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_worksheet_response_" withString:@""]
                                                                        integerValue]];
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
        
        if (self.doneWithWorksheet == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
        
        } else {
            
            [self showLearningModuleWorksheet];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
