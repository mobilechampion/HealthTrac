//
//  HTInboxMessageViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/17/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTInboxMessageViewController : UIViewController <NSXMLParserDelegate, NSLayoutManagerDelegate, UIAlertViewDelegate, UITextViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL returnToInbox;

@property (nonatomic, assign) NSInteger messageID;

@property (nonatomic, strong) NSString *messageAcked;
@property (nonatomic, strong) NSString *messageSubject;
@property (nonatomic, strong) NSString *messageNote;
@property (nonatomic, strong) NSString *messageDate;

@property (nonatomic, assign) NSString *selectedURLPath;

@property (strong, nonatomic) IBOutlet UILabel *subjectLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *messageScrollView;

@property (strong, nonatomic) IBOutlet UITextView *messageTextView;

- (void)getMessages:(NSString *) url withState:(BOOL) urlState;

- (void)deleteMessage:(NSString *) url withState:(BOOL) urlState;

- (void)showMessage;

- (UIBarButtonItem *)backButton;

- (UIBarButtonItem *)deleteButton;

- (void)backButtonPressed;

- (void)deleteButtonPressed;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
