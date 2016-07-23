//
//  HTJournalViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/24/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTJournalViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"

@interface HTJournalViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTJournalViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.journal = [[NSString alloc] init];
    
    self.journalDate = [[NSMutableArray alloc] init];
    self.journalColor = [[NSMutableArray alloc] init];
    self.journalText = [[NSMutableArray alloc] init];
    
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
    
    //int screenWidth = self.view.frame.size.width;
    //int screenHeight = self.view.frame.size.height;
    
    /*
    self.journalTextView = [[UITextView alloc] initWithFrame:CGRectMake(22, 5, (screenWidth - 44), (screenHeight - 130))];
    
    [self.scrollView addSubview:self.journalTextView];
    
    self.journalTextView.editable = YES;
    
    self.journalTextView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    self.journalTextView.textColor = [UIColor colorWithRed:(117/255.0)
                                                     green:(124/255.0)
                                                      blue:(128/255.0)
                                                     alpha:1.0];
    self.journalTextView.editable = NO;
    
    self.journalTextView.layoutManager.delegate = self;
    */
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
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.navigationItem.rightBarButtonItem = [self editButton];
    
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

- (void)showJournal {
    
    NSArray *viewsToRemove = [self.scrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    int screenWidth = self.view.frame.size.width;
    
    NSInteger vPos = 4;
    NSInteger hPos = 0;
    NSInteger offsetPos = -1; // init as -1, do nothing later (no scrolling) if this remains unchanged
    NSInteger journalHeaderContainerHeight = 62;
    
    NSString *dateString;
    NSString *colorString;
    
    UIButton *journalHeaderContainer;
    
    UIView *graySeparator;
    
    UILabel *dateLabel;
    UILabel *journalTextLabel;
    
    UIFont *dateFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
    UIFont *journalTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    UIColor *graySeparatorColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    UIColor *journalHeaderBGColor = [UIColor colorWithRed:(245/255.0) green:(248/255.0) blue:(250/255.0) alpha:1.0];

    UIImageView *colorImage;
    
    UIButton *editPencilButton;

    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 104, screenWidth, 5)];
    graySeparator.backgroundColor = graySeparatorColor;
    
    [self.view addSubview:graySeparator];
    
    // loop through journal entries
    
    for (int i=1; i<=[self.journalDate count] - 1; i++) {
        
        hPos = 16;
        
        journalHeaderContainer = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, journalHeaderContainerHeight)];
        
        journalHeaderContainer.backgroundColor = journalHeaderBGColor;
        
        // color?
        
        colorString = [self.journalColor objectAtIndex:i];
        
        if ([colorString isEqualToString:@"GREEN"] ||
            [colorString isEqualToString:@"YELLOW"] ||
            [colorString isEqualToString:@"RED"]) {
            
            colorImage = [[UIImageView alloc] initWithFrame:CGRectMake(hPos, 14, 30, 30)];
            
            hPos += 46;
            
            if ([colorString isEqualToString:@"GREEN"]) {
                
                colorImage.image = [UIImage imageNamed:@"ht-calendar-green"];
                
            } else if ([colorString isEqualToString:@"YELLOW"]) {
                
                colorImage.image = [UIImage imageNamed:@"ht-calendar-yellow"];
            
            } else { // red
                
                colorImage.image = [UIImage imageNamed:@"ht-calendar-red"];
            }
            
            [journalHeaderContainer addSubview:colorImage];
        }
        
        // date
        
        dateString = [self.journalDate objectAtIndex:i];
        
        dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(hPos, 15, (screenWidth - (hPos + 58)), 30)];

        [dateLabel setFont:dateFont];
        [dateLabel setTextColor:grayFontColor];
        [dateLabel setTextAlignment:NSTextAlignmentLeft];
        [dateLabel setText:dateString];
        
        [journalHeaderContainer addSubview:dateLabel];
        
        // journalOffset
        
        NSString *tempDateString;
        NSString *newDateString;
        
        NSString *monthString;
        NSString *dayString;
        NSString *yearString;
        
        tempDateString = [self.journalDate objectAtIndex:i];
        
        monthString = [tempDateString substringToIndex:[tempDateString rangeOfString:@"/"].location];
        
        tempDateString = [tempDateString substringFromIndex:[tempDateString rangeOfString:@"/"].location + 1];
        
        dayString = [tempDateString substringToIndex:[tempDateString rangeOfString:@"/"].location];
        
        tempDateString = [tempDateString substringFromIndex:[tempDateString rangeOfString:@"/"].location + 1];
        
        yearString = tempDateString;
        
        newDateString = [NSString stringWithFormat:@"%@-%@-%@",
                         dayString,
                         monthString,
                         yearString];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
        
        NSDate *dateFromString;
        
        dateFromString = [[NSDate alloc] init];
        dateFromString = [dateFormatter dateFromString:newDateString];
        
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterLongStyle];
        
        if ([[dateFormatter stringFromDate:dateFromString]
              isEqualToString:[dateFormatter stringFromDate:appDelegate.passDate]]) {
            
            offsetPos = vPos - 4;
        }
        
        // edit pencil - only allowed for entries within the past year
        
        NSDate *oneYearAgo = [appDelegate addNumberOfMonths:-12 toDate:appDelegate.currentDate];
        
        // dateFromString = journalDate in date format
        
        if ([[dateFromString laterDate:oneYearAgo] isEqualToDate:dateFromString] ) {

            editPencilButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth - 58), 0, 58, 58)];
            
            [editPencilButton setImage:[UIImage imageNamed:@"ht-journal-pencil"] forState:UIControlStateNormal];
            
            [editPencilButton setTag:i];
            
            [editPencilButton addTarget:self action:@selector(editPencilPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            [journalHeaderContainer addSubview:editPencilButton];
        }
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, journalHeaderContainerHeight - 4, screenWidth, 4)];
        graySeparator.backgroundColor = graySeparatorColor;
        
        [journalHeaderContainer addSubview:graySeparator];
        
        [self.scrollView addSubview:journalHeaderContainer];
        
        vPos += journalHeaderContainerHeight + 16;
        
        // journal text
        
        journalTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, vPos, (screenWidth - 32), 30)];
        
        journalTextLabel.numberOfLines = 0;
        
        [journalTextLabel setFont:journalTextFont];
        [journalTextLabel setTextColor:grayFontColor];
        [journalTextLabel setTextAlignment:NSTextAlignmentLeft];
        [journalTextLabel setText:[self.journalText objectAtIndex:i]];
        
        [journalTextLabel sizeToFit];
        
        [self.scrollView addSubview:journalTextLabel];
        
        vPos += journalTextLabel.frame.size.height + 16;
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 4)];
        graySeparator.backgroundColor = graySeparatorColor;
        
        [self.scrollView addSubview:graySeparator];
        
        vPos += 4;
    }
    
    [self.scrollView setContentSize:CGSizeMake(screenWidth, vPos)];
    
    if (offsetPos != -1) {
        
        if (vPos - offsetPos < self.scrollView.frame.size.height) {
            
            // this is so the scroll view still fills the screen area and doesn't scroll too far
            offsetPos = vPos - self.scrollView.frame.size.height;
        }
        
        CGPoint journalOffset = CGPointMake(0, offsetPos);
        [self.scrollView setContentOffset:journalOffset animated: YES];
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

- (UIBarButtonItem *)editButton {
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(editButtonPressed)];
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)editButtonPressed {
    
    [self performSegueWithIdentifier:@"showJournalEdit" sender:self];
}

- (void)editPencilPressed:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSString *tempDateString;
    
    NSString *monthString;
    NSString *dayString;
    NSString *yearString;
    
    tempDateString = [self.journalDate objectAtIndex:[sender tag]];
    
    monthString = [tempDateString substringToIndex:[tempDateString rangeOfString:@"/"].location];
    
    tempDateString = [tempDateString substringFromIndex:[tempDateString rangeOfString:@"/"].location + 1];
    
    dayString = [tempDateString substringToIndex:[tempDateString rangeOfString:@"/"].location];
    
    tempDateString = [tempDateString substringFromIndex:[tempDateString rangeOfString:@"/"].location + 1];
    
    yearString = tempDateString;
    
    NSString *newDateString;
    
    newDateString = [NSString stringWithFormat:@"%@-%@-%@",
                  dayString,
                  monthString,
                  yearString];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    
    NSDate *dateFromString;
    
    dateFromString = [[NSDate alloc] init];
    dateFromString = [dateFormatter dateFromString:newDateString];
    
    appDelegate.passDate = dateFromString;
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:dateFromString];
    
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passDay = [dateComponents day];
    appDelegate.passYear = [dateComponents year];
    
    [self performSegueWithIdentifier:@"showJournalEdit" sender:self];
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
    
    [self.journalDate removeAllObjects];
    [self.journalColor removeAllObjects];
    [self.journalText removeAllObjects];
    
    [self.journalDate insertObject:@"" atIndex:0];
    [self.journalColor insertObject:@"" atIndex:0];
    [self.journalText insertObject:@"" atIndex:0];
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
    
    cleanStr = [[[[[[[self.currentValue
                        stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                        stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                        stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                        stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]
                        stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"]
                        stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"]
                        stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];

    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"journal"]) {
        
        self.journal = cleanStr;
        
    } else if ([elementName hasPrefix:@"journal_date_"]) {
        
        [self.journalDate insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"journal_date_" withString:@""]
                                                                  integerValue]];
        
    } else if ([elementName hasPrefix:@"journal_color_"]) {
        
        [self.journalColor insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"journal_color_" withString:@""]
                                                                  integerValue]];
        
    } else if ([elementName hasPrefix:@"journal_text_"]) {
        
        [self.journalText insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"journal_text_" withString:@""]
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

        [self showJournal];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - NSLayoutManagerDelegate methods

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    
    return 5.5;
}

#pragma mark - UITextView delegate methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    [self editButtonPressed];
    
    return NO;
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
    
    [self getJournal:HTWebSvcURL withState:0];
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
    
    [self getJournal:HTWebSvcURL withState:0];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
