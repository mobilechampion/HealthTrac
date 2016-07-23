//
//  HTJournalEditViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/24/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTJournalEditViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"

@interface HTJournalEditViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTJournalEditViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.journal = [[NSString alloc] init];
    self.ningAlertTitle = [[NSString alloc] init];
    self.ningAlertText = [[NSString alloc] init];
    
    self.title = @"My Journal";
    
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
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    self.journalTextView = [[UITextView alloc] initWithFrame:CGRectMake(22, 5, (screenWidth - 44), (screenHeight - 130))];
    
    [self.journalTextView setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.scrollView addSubview:self.journalTextView];
    
    self.journalTextView.editable = YES;
    
    self.journalTextView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    self.journalTextView.textColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    self.journalTextView.layoutManager.delegate = self;
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
    
    self.doneEditingJournal = NO;
    self.leftDateArrowClicked = NO;
    self.rightDateArrowClicked = NO;
    self.hasNing = NO;
    self.shareToNing = NO;
    
    self.navigationItem.leftBarButtonItem = [self cancelButton];
    self.navigationItem.rightBarButtonItem = [self doneButton];
    
    [self getJournal:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getJournal:(NSString *) url withState:(BOOL) urlState {
    
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
    
    myRequestString = [NSString stringWithFormat:@"action=get_journal&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)updateJournal:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *cleanStr = [[NSString alloc] init];

    cleanStr = [[[[[self.journalTextView.text
                    stringByReplacingOccurrencesOfString:@"<" withString:@"|*|lt|*|"]
                    stringByReplacingOccurrencesOfString:@">" withString:@"|*|gt|*|"]
                    stringByReplacingOccurrencesOfString:@"&" withString:@"|*|and|*|"]
                    stringByReplacingOccurrencesOfString:@" " withString:@"+"]
                    stringByReplacingOccurrencesOfString:@"\n" withString:@"%0D%0A"];

    self.journal = cleanStr;
    
    myRequestString = [NSString stringWithFormat:@"action=update_journal&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&journal=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.journal];
    
    if (self.shareToNing == YES) {
        
        myRequestString = [myRequestString stringByAppendingString:@"&ning=1"];
    }
    
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

- (void)showJournal {
    
    int screenWidth = self.view.frame.size.width;
    
    UIView *graySeparator;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 104, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.view addSubview:graySeparator];
    
    self.journalTextView.text = self.journal;
    
    [self.journalTextView becomeFirstResponder];
    
    [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
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
    
    self.doneEditingJournal = YES;
    
    if (self.hasNing == YES && ![self.journalTextView.text isEqualToString:@""]) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:self.ningAlertTitle
                                  message:self.ningAlertText
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Yes", @"No", nil];
        
        [alertView show];
        
    } else {
        
        [self updateJournal:HTWebSvcURL withState:0];
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
    
    self.journal = nil;
    self.ningAlertTitle = nil;
    self.ningAlertText = nil;
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
    
    NSString *cleanStr = [[NSString alloc] init];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"journal"]) {
        
        cleanStr = [[[[[[[self.currentValue
                            stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                            stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                            stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                            stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]
                            stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"]
                            stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"]
                            stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        
        self.journal = cleanStr;
        
    } else if ([elementName isEqualToString:@"has_ning"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.hasNing = YES;
        }
        
    } else if ([elementName isEqualToString:@"ning_alert_title"]) {
        
        self.ningAlertTitle = self.currentValue;
        
    } else if ([elementName isEqualToString:@"ning_alert_text"]) {
        
        self.ningAlertText = self.currentValue;
        
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
        
        if (self.doneEditingJournal == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else {
            
            if (self.leftDateArrowClicked == YES) {
                
                NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                
                NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
                
                NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
                
                appDelegate.passDate = newDate;
                appDelegate.passDay = [dateComponents day];
                appDelegate.passMonth = [dateComponents month];
                appDelegate.passYear = [dateComponents year];
                
                self.leftDateArrowClicked = NO;
                
                [self getJournal:HTWebSvcURL withState:0];
                
            } else if (self.rightDateArrowClicked == YES) {
                
                NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                
                NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
                
                NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
                
                appDelegate.passDate = newDate;
                appDelegate.passDay = [dateComponents day];
                appDelegate.passMonth = [dateComponents month];
                appDelegate.passYear = [dateComponents year];
                
                self.rightDateArrowClicked = NO;
                
                [self getJournal:HTWebSvcURL withState:0];
            }
            
            [self showJournal];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    // share with friends on comment wall?
    
    if (buttonIndex == 0) { // yes
        
        self.shareToNing = YES;
        
        [self updateJournal:HTWebSvcURL withState:0];
        
    } else if (buttonIndex == 1) { // no
        
        self.shareToNing = NO;
        
        [self updateJournal:HTWebSvcURL withState:0];
    }
}

#pragma mark - NSLayoutManagerDelegate methods

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    
    return 5.5;
}

- (IBAction)leftDateArrowClick:(id)sender {
    
    self.leftDateArrowClicked = YES;
    
    if (self.hasNing == YES && ![self.journalTextView.text isEqualToString:@""]) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:self.ningAlertTitle
                                  message:self.ningAlertText
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Yes", @"No", nil];
        
        [alertView show];
        
    } else {
        
        [self updateJournal:HTWebSvcURL withState:0];
    }
    
    /*
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getJournal:HTWebSvcURL withState:0];
    */
}

- (IBAction)rightDateArrowClick:(id)sender {
    
    self.rightDateArrowClicked = YES;
    
    if (self.hasNing == YES && ![self.journalTextView.text isEqualToString:@""]) {
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:self.ningAlertTitle
                                  message:self.ningAlertText
                                  delegate:self
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"Yes", @"No", nil];
        
        [alertView show];
        
    } else {
        
        [self updateJournal:HTWebSvcURL withState:0];
    }
    
    /*
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    [self getJournal:HTWebSvcURL withState:0];
    */
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
