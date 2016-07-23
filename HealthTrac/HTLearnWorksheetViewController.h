//
//  HTLearnWorksheetViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/13/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTLearnWorksheetViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL doneWithWorksheet;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) NSInteger learningModuleID;

@property (nonatomic, strong) NSString *learningModuleTitle;

@property (nonatomic, strong) NSMutableArray *learningModuleWorksheetTextViews;
@property (nonatomic, strong) NSMutableArray *learningModuleWorksheetIDs;
@property (nonatomic, strong) NSMutableArray *learningModuleWorksheetQuestions;
@property (nonatomic, strong) NSMutableArray *learningModuleWorksheetAnswers;

@property (strong, nonatomic) IBOutlet UIScrollView *learnScrollView;

- (UIBarButtonItem *)backButton;
- (UIBarButtonItem *)doneButton;

- (void)backButtonPressed;
- (void)doneButtonPressed;

- (void)getLearningModuleWorksheet:(NSString *) url withState:(BOOL) urlState;
- (void)updateLearningModuleWorksheet:(NSString *) url withState:(BOOL) urlState;

- (void)showLearningModuleWorksheet;

// Error handling
- (void)handleURLError:(NSError *)error;

@end