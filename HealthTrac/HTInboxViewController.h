//
//  HTInboxViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTInboxViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSMutableArray *messageID;
@property (nonatomic, strong) NSMutableArray *messageAcked;
@property (nonatomic, strong) NSMutableArray *messageSubject;
@property (nonatomic, strong) NSMutableArray *messageNote;
@property (nonatomic, strong) NSMutableArray *messageDate;

@property (nonatomic, assign) NSInteger selectedMessageID;

@property (nonatomic, strong) UILabel *subjectLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@property (strong, nonatomic) UITextField *searchField;

@property (strong, nonatomic) IBOutlet UIView *searchContainerView;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;

- (void)getMessages:(NSString *) url withState:(BOOL) urlState;

- (void)showMessages;

- (void)selectMessage:(id)sender;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
