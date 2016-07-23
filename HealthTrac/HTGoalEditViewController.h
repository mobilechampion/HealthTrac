//
//  HTGoalEditViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/28/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTGoalEditViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL doneEditingGoal;

@property (nonatomic, strong) NSString *goal;
@property (nonatomic, strong) NSString *goalTime;
@property (nonatomic, strong) NSString *goalPlace;
@property (nonatomic, strong) NSString *goalSupport;
@property (nonatomic, strong) NSString *goalMotivation;
@property (nonatomic, strong) NSString *goalComment;

@property (nonatomic, retain) UITextField *goalField;
@property (nonatomic, retain) UITextField *goalTimeField;
@property (nonatomic, retain) UITextField *goalPlaceField;
@property (nonatomic, retain) UITextField *goalSupportField;
@property (nonatomic, retain) UITextField *goalMotivationField;
@property (nonatomic, retain) UITextField *goalCommentField;

@property (strong, nonatomic) IBOutlet UIScrollView *goalScrollView;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

- (UIBarButtonItem *)cancelButton;
- (UIBarButtonItem *)doneButton;

- (void)cancelButtonPressed;
- (void)doneButtonPressed;

- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;

- (void)getGoal:(NSString *) url withState:(BOOL) urlState;

- (void)updateGoal:(NSString *) url withState:(BOOL) urlState;

- (void)showGoal;

// Error handling
- (void)handleURLError:(NSError *)error;

@end