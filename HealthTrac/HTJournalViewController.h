//
//  HTJournalViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/24/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTJournalViewController : UIViewController <NSXMLParserDelegate, NSLayoutManagerDelegate, UITextViewDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, strong) NSString *journal;

@property (nonatomic, strong) NSMutableArray *journalDate;
@property (nonatomic, strong) NSMutableArray *journalColor;
@property (nonatomic, strong) NSMutableArray *journalText;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@property (strong, nonatomic) IBOutlet UITextView *journalTextView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)editButton;

- (void)backButtonPressed;
- (void)editButtonPressed;

- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;

- (void)getJournal:(NSString *) url withState:(BOOL) urlState;

- (void)editPencilPressed:(id)sender;

- (void)showJournal;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
