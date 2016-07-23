//
//  HTJournalEditViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/24/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTJournalEditViewController : UIViewController <NSXMLParserDelegate, NSLayoutManagerDelegate, UIAlertViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL doneEditingJournal;
@property (nonatomic, assign) BOOL leftDateArrowClicked;
@property (nonatomic, assign) BOOL rightDateArrowClicked;
@property (nonatomic, assign) BOOL hasNing;
@property (nonatomic, assign) BOOL shareToNing;

@property (nonatomic, strong) NSString *journal;
@property (nonatomic, strong) NSString *ningAlertTitle;
@property (nonatomic, strong) NSString *ningAlertText;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet UITextView *journalTextView;

- (UIBarButtonItem *)cancelButton;
- (UIBarButtonItem *)doneButton;

- (void)cancelButtonPressed;
- (void)doneButtonPressed;

- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;

- (void)getJournal:(NSString *) url withState:(BOOL) urlState;

- (void)updateJournal:(NSString *) url withState:(BOOL) urlState;

- (void)showJournal;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
