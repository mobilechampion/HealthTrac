//
//  HTInboxViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTInboxViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTInboxMessageViewController.h"
#import "HTTextField.h"

@interface HTInboxViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTInboxViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    int screenWidth = self.view.frame.size.width;
    int screenOffset = (self.view.frame.size.width - 320);
    
    UIView *graySeparator;
    
    self.title = @"Inbox";
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    self.messageID = [[NSMutableArray alloc] init];
    self.messageAcked = [[NSMutableArray alloc] init];
    self.messageSubject = [[NSMutableArray alloc] init];
    self.messageNote = [[NSMutableArray alloc] init];
    self.messageDate = [[NSMutableArray alloc] init];
    
    self.searchField = [[HTTextField alloc] initHTDefaultWithFrame:CGRectMake(12, 7, 296 + screenOffset, 28)];
    
    [self.searchField setTextAlignment:NSTextAlignmentCenter];
    [self.searchField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [self.searchField setKeyboardType:UIKeyboardTypeASCIICapable];
    
    [self.searchField addTarget:self
                         action:@selector(textFieldDidChange:)
               forControlEvents:UIControlEventEditingChanged];
    
    self.searchField.font = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *color = [UIColor colorWithRed:(117/255.0)
                                     green:(124/255.0)
                                      blue:(128/255.0)
                                     alpha:0.6];
    
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search" attributes:@{NSForegroundColorAttributeName: color}];
    
    [self.searchContainerView addSubview:self.searchField];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 41, screenWidth, 2)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.searchContainerView addSubview:graySeparator];
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
    
    [self getMessages:HTWebSvcURL withState:0];
}

#pragma mark - Methods

- (void)getMessages:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *searchString = [[NSString alloc] init];
    
    searchString = [self.searchField.text stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    myRequestString = [NSString stringWithFormat:@"action=get_messages&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&search=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, searchString];
    
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

- (void)showMessages {
    
    NSArray *viewsToRemove = [self.scrollView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    NSInteger vPos = 0;
    
    UIView *graySeparator;
    UIView *messageBlock;
    
    int screenWidth = self.view.frame.size.width;
    int screenOffset = (self.view.frame.size.width - 320);
 
    UIFont *subjectFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0];
    UIFont *noteFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    UIFont *dateFont = [UIFont fontWithName:@"OpenSans" size:12.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    UIColor *blueFontColor = [UIColor colorWithRed:(116/255.0) green:(204/255.0) blue:(240/255.0) alpha:1.0];
    
    UITapGestureRecognizer *tapGestureRecognizer;
    
    for (int i=1; i<=[self.messageID count] - 1; i++) {
        
        messageBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 82)];
        
        messageBlock.backgroundColor = [UIColor whiteColor];
        
        self.subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, 223 + screenOffset, 18)];
        
        if (![[self.messageAcked objectAtIndex:i] isEqualToString:@"Y"]) {
            
            [self.subjectLabel setTextColor:blueFontColor];
            
        } else {
            
            [self.subjectLabel setTextColor:grayFontColor];
        }
        
        [self.subjectLabel setTextAlignment:NSTextAlignmentLeft];
        [self.subjectLabel setFont:subjectFont];
        [self.subjectLabel setText:[self.messageSubject objectAtIndex:i]];
        
        [messageBlock addSubview:self.subjectLabel];
        
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(241 + screenOffset, 8, 79, 18)];
        
        if (![[self.messageAcked objectAtIndex:i] isEqualToString:@"Y"]) {
            
            [self.dateLabel setTextColor:blueFontColor];
            
        } else {
            
            [self.dateLabel setTextColor:grayFontColor];
        }
        
        [self.dateLabel setTextAlignment:NSTextAlignmentLeft];
        [self.dateLabel setFont:dateFont];
        [self.dateLabel setText:[self.messageDate objectAtIndex:i]];
        
        [messageBlock addSubview:self.dateLabel];
        
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 32, 223 + screenOffset, 44)];
        self.messageLabel.numberOfLines = 2;
        [self.messageLabel setTextAlignment:NSTextAlignmentLeft];
        [self.messageLabel setFont:noteFont];
        [self.messageLabel setTextColor:grayFontColor];
        [self.messageLabel setText:[self.messageNote objectAtIndex:i]];
        
        [messageBlock addSubview:self.messageLabel];
        
        graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 81, screenWidth, 5)];
        graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
        
        [messageBlock addSubview:graySeparator];
        
        messageBlock.userInteractionEnabled = YES;
        messageBlock.tag = i;
        
        tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                initWithTarget:self
                                action:@selector(selectMessage:)];
        
        [tapGestureRecognizer setNumberOfTouchesRequired:1];
        
        [messageBlock addGestureRecognizer:tapGestureRecognizer];
        
        [self.scrollView addSubview:messageBlock];
        
        messageBlock = nil;

        vPos += 87;
    }
    
    [self.scrollView setContentSize:CGSizeMake(screenWidth, vPos + 0)]; // starts at 640
}

- (void)selectMessage:(id)sender {
    
    UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
    
    [tapGestureRecognizer.view setBackgroundColor:[UIColor colorWithRed:(217/255.0)
                                                                  green:(217/255.0)
                                                                   blue:(217/255.0)
                                                                  alpha:1.0]];
    
    self.selectedMessageID = [[self.messageID objectAtIndex:[tapGestureRecognizer.view tag]] integerValue];
    
    [self performSegueWithIdentifier:@"showMessageViewFromInbox" sender:self];
    
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
    
    [self.messageID removeAllObjects];
    [self.messageAcked removeAllObjects];
    [self.messageSubject removeAllObjects];
    [self.messageNote removeAllObjects];
    [self.messageDate removeAllObjects];
    
    [self.messageID insertObject:@"" atIndex:0];
    [self.messageAcked insertObject:@"" atIndex:0];
    [self.messageSubject insertObject:@"" atIndex:0];
    [self.messageNote insertObject:@"" atIndex:0];
    [self.messageDate insertObject:@"" atIndex:0];
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
    }
    
    // messages
    else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_id"]) {
        
        [self.messageID insertObject:self.currentValue
                             atIndex:[[[elementName
                                        stringByReplacingOccurrencesOfString:@"message_" withString:@""] stringByReplacingOccurrencesOfString:@"_id" withString:@""] integerValue]];
        
    } else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_acked"]) {
        
        [self.messageAcked insertObject:self.currentValue
                             atIndex:[[[elementName
                                        stringByReplacingOccurrencesOfString:@"message_" withString:@""] stringByReplacingOccurrencesOfString:@"_acked" withString:@""] integerValue]];
        
    }  else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_subject"]) {
        
        cleanStr = [[[[[[[self.currentValue stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                        stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                        stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                        stringByReplacingOccurrencesOfString:@"<br>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br />" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br/>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        
        [self.messageSubject insertObject:cleanStr
                             atIndex:[[[elementName
                                        stringByReplacingOccurrencesOfString:@"message_" withString:@""] stringByReplacingOccurrencesOfString:@"_subject" withString:@""] integerValue]];
        
    }  else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_note"]) {
        
        cleanStr = [[[[[[[self.currentValue stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                        stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                        stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                        stringByReplacingOccurrencesOfString:@"<br>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br />" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br/>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        
        [self.messageNote insertObject:cleanStr
                             atIndex:[[[elementName
                                        stringByReplacingOccurrencesOfString:@"message_" withString:@""] stringByReplacingOccurrencesOfString:@"_note" withString:@""] integerValue]];
        
    }  else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_created"]) {
        
        [self.messageDate insertObject:self.currentValue
                             atIndex:[[[elementName
                                        stringByReplacingOccurrencesOfString:@"message_" withString:@""] stringByReplacingOccurrencesOfString:@"_created" withString:@""] integerValue]];
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
        
        [self showMessages];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - UITextView delegate methods

- (void)textFieldDidChange:(id)sender {
    
    [self getMessages:HTWebSvcURL withState:0];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"showMessageViewFromInbox"]) {
        
        HTInboxMessageViewController *viewController = [segue destinationViewController];
        
        viewController.messageID = self.selectedMessageID;
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
