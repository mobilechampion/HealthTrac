//
//  HTLoginViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/6/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTLoginViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate>

@property (nonatomic, retain) NSURLConnection *sphConnection;
@property (nonatomic, retain) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, retain) NSString *login;
@property (nonatomic, retain) NSString *pw;
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *practice;
@property (nonatomic, retain) NSString *webSvcError;

@property (nonatomic, assign) BOOL rememberMeIsChecked;
@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL shouldHidePlanner;

@property (strong, nonatomic) IBOutlet UITextField *loginField;
@property (strong, nonatomic) IBOutlet UITextField *pwField;

@property (strong, nonatomic) IBOutlet UILabel *labelWelcome;

@property (strong, nonatomic) IBOutlet UIButton *rememberMeCheckBox;

- (NSString*)deviceName;

- (IBAction)rememberMeChecked:(id)sender;

- (IBAction)loginButtonPressed:(id)sender;

- (void)doLogin:(NSString *) url withState:(BOOL) urlState;

- (void)setFontFamily:(NSString*)fontFamily forView:(UIView*)view andSubViews:(BOOL)isSubViews;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
