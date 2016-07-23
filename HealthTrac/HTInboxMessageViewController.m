//
//  HTInboxMessageViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/17/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTInboxMessageViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTWebContentViewController.h"

@interface HTInboxMessageViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTInboxMessageViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.title = @"";
    
    self.navigationController.navigationBar.translucent = YES;
    self.navigationItem.leftBarButtonItem = [self backButton];
    self.navigationItem.rightBarButtonItem = [self deleteButton];
    
    self.messageAcked = [[NSString alloc] init];
    self.messageSubject = [[NSString alloc] init];
    self.messageNote = [[NSString alloc] init];
    self.messageDate = [[NSString alloc] init];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.subjectLabel.font = [UIFont fontWithName:@"Avenir-Light" size:23.0];
    self.subjectLabel.textColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    self.messageTextView = [[UITextView alloc] initWithFrame:CGRectMake(8, 8, (screenWidth - 32), (screenHeight - 130))];
    
    [self.messageScrollView addSubview:self.messageTextView];
    
    self.messageTextView.editable = YES;
    
    self.messageTextView.font = [UIFont fontWithName:@"Avenir-Roman" size:14.0];
    self.messageTextView.textColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    self.messageTextView.editable = NO;
    self.messageTextView.userInteractionEnabled = YES;
    self.messageTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    
    self.messageTextView.layoutManager.delegate = self;
    self.messageTextView.delegate = self;
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
    
    self.selectedURLPath = @"";
    
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
    
    myRequestString = [NSString stringWithFormat:@"action=get_messages&messageid=%ld&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", (long)self.messageID, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)showMessage {
    
    if ([self.messageNote isEqualToString:@""]) {
        
        [self backButtonPressed]; //pop back to inbox
    }
    
    self.subjectLabel.numberOfLines = 2;
    
    [self.subjectLabel sizeToFit];
    
    self.subjectLabel.text = self.messageSubject;
    self.messageTextView.text = self.messageNote;
}

- (void)openLinkInWebView {
    
    [self performSegueWithIdentifier:@"showWebContentFromMessage" sender:self];
}

- (void)deleteMessage:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.returnToInbox = YES; // after the message is deleted
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=delete_message&messageid=%ld&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", (long)self.messageID, appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (UIBarButtonItem *)backButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-back-arrow"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (UIBarButtonItem *)deleteButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-delete"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(deleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)deleteButtonPressed {
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Message?" message:@"Are you sure you want to delete this message?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [alertView show];
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
    
    self.messageAcked = nil;
    self.messageSubject = nil;
    self.messageNote = nil;
    self.messageDate = nil;
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
    
    // message
    else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_acked"]) {
        
        self.messageAcked =  self.currentValue;
        
    } else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_subject"]) {
        
        cleanStr = [[[[[[[self.currentValue stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                        stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                        stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                        stringByReplacingOccurrencesOfString:@"<br>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br />" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"<br/>" withString:@" "]
                        stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        
        self.messageSubject = cleanStr;
        
    } else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_note"]) {
        
        cleanStr = [[[[[[[self.currentValue stringByReplacingOccurrencesOfString:@"|*|lt|*|" withString:@"<"]
                         stringByReplacingOccurrencesOfString:@"|*|gt|*|" withString:@">"]
                        stringByReplacingOccurrencesOfString:@"|*|and|*|" withString:@"&"]
                       stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"]
                      stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"]
                     stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"]
                    stringByReplacingOccurrencesOfString:@"&#39;" withString:@"'"];
        
        self.messageNote = cleanStr;
        
    } else if ([elementName hasPrefix:@"message_"] && [elementName hasSuffix:@"_created"]) {
        
        self.messageDate = self.currentValue;
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
        
        if (self.returnToInbox == YES) {
            
            self.returnToInbox = NO;
            
            [self backButtonPressed]; // pop back to inbox
            
        } else {
            
            [self showMessage];
        }
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - UITextView delegate methods

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    
    self.selectedURLPath = [NSString stringWithFormat:@"%@", URL];
    
    if ([self.selectedURLPath containsString:@"@"]
        && ![self.selectedURLPath containsString:@"http"]
        && ![self.selectedURLPath containsString:@"www"]) {
        
        self.selectedURLPath = @"";
        
    } else {
        
        [self openLinkInWebView];
    }
    
    return NO;
}

#pragma mark - NSLayoutManagerDelegate methods

- (CGFloat)layoutManager:(NSLayoutManager *)layoutManager lineSpacingAfterGlyphAtIndex:(NSUInteger)glyphIndex withProposedLineFragmentRect:(CGRect)rect {
    
    return 9;
}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 1) {

        [self deleteMessage:HTWebSvcURL withState:0];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTWebContentViewController *viewController = segue.destinationViewController;
    
    viewController.selectedAssetTitle = @"";
    viewController.selectedAssetPath = self.selectedURLPath;
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
