//
//  HTMoreViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 9/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTMoreViewController : UITableViewController  <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;
@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL showInbox;

@property (nonatomic, assign) NSInteger numberOfNewMessages;
@property (nonatomic, assign) NSInteger numberOfEatingPlans;
@property (nonatomic, assign) NSInteger numberOfLearningModules;

@property (nonatomic, strong) NSMutableArray *moreItems;

- (void)getMorePanelItems:(NSString *) url withState:(BOOL) urlState;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
