//
//  HTLearnViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 11/3/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTLearnViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL allowSelections;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) NSInteger learningModuleCount;
@property (nonatomic, assign) NSInteger selectedLearningModuleID;

@property (nonatomic, assign) NSInteger numberOfNewMessages;
@property (nonatomic, assign) NSInteger numberOfEatingPlans;
@property (nonatomic, assign) NSInteger numberOfLearningModules;

@property (nonatomic, strong) NSMutableArray *learningModuleID;
@property (nonatomic, strong) NSMutableArray *learningModuleSessionID;
@property (nonatomic, strong) NSMutableArray *learningModuleStatus;
@property (nonatomic, strong) NSMutableArray *learningModuleTitle;

@property (strong, nonatomic) IBOutlet UIScrollView *learnScrollView;

- (void)getLearningModules:(NSString *) url withState:(BOOL) urlState;

- (void)showLearningModules;

- (void)selectLearningModule:(id)sender;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
