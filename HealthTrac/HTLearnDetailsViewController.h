//
//  HTLearnDetailsViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/11/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface HTLearnDetailsViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, assign) BOOL showConnError;
@property (nonatomic, assign) BOOL learningModuleHasWorksheet;
@property (nonatomic, assign) BOOL doneUpdatingLearningModule;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, assign) NSInteger learningModuleID;

@property (nonatomic, assign) NSString *selectedAssetPath;

@property (nonatomic, strong) NSString *learningModuleTitle;
@property (nonatomic, strong) NSString *learningModuleDescription;
@property (nonatomic, assign) NSString *learningModuleStatus;

@property (nonatomic, strong) NSString *learningModuleIntroVideoTitle;
@property (nonatomic, strong) NSString *learningModuleIntroVideoPath;

@property (nonatomic, strong) NSMutableArray *learningModuleVideoTitles;
@property (nonatomic, strong) NSMutableArray *learningModuleVideoPaths;

@property (nonatomic, strong) NSMutableArray *learningModuleDocumentTitles;
@property (nonatomic, strong) NSMutableArray *learningModuleDocumentPaths;

@property (nonatomic, strong) MPMoviePlayerViewController *moviePlayerViewController;

@property (nonatomic, strong) NSURL *movieURL;

@property (strong, nonatomic) IBOutlet UIScrollView *learnScrollView;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;
- (void)markAsCompleteButtonPressed;

- (void)getLearningModule:(NSString *) url withState:(BOOL) urlState;

- (void)showLearningModule;
- (void)playIntroMovie;
- (void)showWorksheet;
- (void)playMovie:(id)sender;
- (void)showDocument:(id)sender;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
