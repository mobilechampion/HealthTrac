//
//  HTLoginViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTLoginViewController.h"
#import "HTAppDelegate.h"
#import "UIView+Toast.h"
#import <sys/utsname.h>

@interface HTLoginViewController ()

@end

@implementation HTLoginViewController

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSString *myLogin;
    NSString *myPassword;
    NSString *myPractice;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    myLogin = [prefs objectForKey:@"login"];
    myPassword = [prefs objectForKey:@"password"];
    myPractice = [prefs objectForKey:@"practice"];
    
    if (![myLogin isEqualToString:@""] && myLogin != NULL) {
        
        self.loginField.text = myLogin;
    }

    if (![myPassword isEqualToString:@""] && myPassword != NULL) {
        
        self.pwField.text = myPassword;
    }
    
    if ([myPractice isEqualToString:@""] || myPractice == NULL) {

        myPractice = @"";
    }
    
    if ([myPractice isEqualToString:@""]) {
        
        [self.labelWelcome setText:@"Welcome to HealthTrac"];
        
    } else {
        
        [self.labelWelcome setText:[NSString stringWithFormat:@"%@", myPractice]];
        
        self.labelWelcome.adjustsFontSizeToFitWidth = YES;
    }
    
    if ([self.loginField.text isEqualToString:@""]) {
        
        self.rememberMeIsChecked = NO;
        
    } else {
        
        self.rememberMeIsChecked = YES;
        
        [self.rememberMeCheckBox setImage:[UIImage imageNamed:@"ht-check-on.png"] forState:UIControlStateNormal];
    }
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    // pop all viewcontrollers from tab bar, etc.
    
    for (UIViewController *viewController in self.tabBarController.viewControllers) {
        
        if([viewController isKindOfClass:[UINavigationController class]]) {
            
            if (![viewController isViewLoaded]) {
                [(UINavigationController *)viewController popToRootViewControllerAnimated:NO];
            }
        }
    }
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.currentDay = 0;
    appDelegate.currentMonth = 0;
    appDelegate.currentYear = 0;
    
    NSDate *date = [NSDate date];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
    
    appDelegate.passDate = date;
    appDelegate.currentDate = date;
    
    appDelegate.currentDay = [dateComponents day];
    appDelegate.currentMonth = [dateComponents month];
    appDelegate.currentYear = [dateComponents year];
    
    appDelegate.passDay = appDelegate.currentDay;
    appDelegate.passMonth = appDelegate.currentMonth;
    appDelegate.passYear = appDelegate.currentYear;
    
    UIColor *color = [UIColor colorWithWhite:1.0 alpha:0.4];
    
    self.loginField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: color}];
    
    self.pwField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: color}];
    
    NSString *myPractice;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    myPractice = [prefs objectForKey:@"practice"];
    
    if ([myPractice isEqualToString:@""] || myPractice == NULL) {
        
        myPractice = @"";
    }
    
    if ([myPractice isEqualToString:@""]) {
        
        [self.labelWelcome setText:@"Welcome to HealthTrac"];
        
    } else {
        
        [self.labelWelcome setText:[NSString stringWithFormat:@"%@", myPractice]];
        
        self.labelWelcome.adjustsFontSizeToFitWidth = YES;
    }
    
    self.shouldHidePlanner = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}

#pragma mark - Methods

- (IBAction)rememberMeChecked:(id)sender {
    
    if (self.rememberMeIsChecked == NO) {
        
        self.rememberMeIsChecked = YES;
        
        [self.rememberMeCheckBox setImage:[UIImage imageNamed:@"ht-check-on"] forState:UIControlStateNormal];
        
    } else {
        
        self.rememberMeIsChecked = NO;
        
        [self.rememberMeCheckBox setImage:[UIImage imageNamed:@"ht-check-off"] forState:UIControlStateNormal];
    }
}

- (IBAction)loginButtonPressed:(id)sender {
    
    if (self.sphConnection) {
        
        [self.sphConnection cancel];
    }
    
    // perform the login
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self doLogin:HTWebSvcURL withState:0];
}

- (void)doLogin:(NSString *) url withState:(BOOL) urlState {
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    myRequestString = [NSString stringWithFormat:@"action=login&userid=%@&pw=%@&version=iPhone+%@&swVersion=%@&device=%@&iostoken=%@",
                       self.loginField.text,
                       self.pwField.text,
                       [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"],
                       [[UIDevice currentDevice] systemVersion],
                       self.deviceName, [[NSUserDefaults standardUserDefaults] valueForKey:@"push_token"]];
    
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

- (void)setFontFamily:(NSString*)fontFamily forView:(UIView*)view andSubViews:(BOOL)isSubViews {
    
    if ([view isKindOfClass:[UILabel class]]) {
        
        UILabel *lbl = (UILabel *)view;
        
        [lbl setFont:[UIFont fontWithName:fontFamily size:[[lbl font] pointSize]]];
    }
    
    if (isSubViews) {
        
        for (UIView *sview in view.subviews) {
            
            [self setFontFamily:fontFamily forView:sview andSubViews:YES];
        }
    }
}

- (NSString*)deviceName {
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
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
    
    // handle the error generically
    [self handleURLError:error];
    
    self.sphConnection = nil;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    self.login = nil;
    self.pw = nil;
    self.firstName = nil;
    self.lastName = nil;
    self.practice = nil;
    
    self.shouldHidePlanner = NO;
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
    
    if ([elementName isEqualToString:@"login"]) {
        
        self.login = self.currentValue;
        
    } else if ([elementName isEqualToString:@"pw"]) {
        
        self.pw = self.currentValue;
        
    } else if ([elementName isEqualToString:@"first_name"]) {
        
        self.firstName = self.currentValue;
        
    } else if ([elementName isEqualToString:@"last_name"]) {
        
        self.lastName = self.currentValue;
        
    } else if ([elementName isEqualToString:@"practice"]) {
        
        self.practice = self.currentValue;
        
    } else if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    } else if ([elementName isEqualToString:@"hide_planner"]) {
        
        if ([self.currentValue isEqualToString:@"1"]) {
            
            self.shouldHidePlanner = YES;
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
        
        HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        
        appDelegate.passLogin = self.login;
        appDelegate.passPw = self.pw;
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        
        if (self.rememberMeIsChecked == YES) {
            
            [prefs setObject:self.login forKey:@"login"];
            [prefs setObject:self.pw forKey:@"password"];
            [prefs setObject:self.practice forKey:@"practice"];
            [prefs synchronize];
            
        } else {
            
            [prefs setObject:@"" forKey:@"login"];
            [prefs setObject:@"" forKey:@"password"];
            [prefs setObject:self.practice forKey:@"practice"];
            [prefs synchronize];
        }
        
        if (self.rememberMeIsChecked == NO) {
            
            self.loginField.text = @"";
            self.pwField.text = @"";
        }
        
        if (self.shouldHidePlanner == YES) {
            
            appDelegate.hidePlanner = YES;
        
        } else {
            
            appDelegate.hidePlanner = NO;
        }
 
        [self performSegueWithIdentifier:@"showDashboardFromLogin" sender:self];
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Error handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
