//
//  HTLearnDetailsViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/11/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTLearnDetailsViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTWebContentViewController.h"
#import "HTLearnWorksheetViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HTLearnDetailsViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTLearnDetailsViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.view autoresizesSubviews];
    
    self.navigationController.navigationBar.hidden = NO;
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Learning Modules";
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.learningModuleHasWorksheet = NO;
    
    self.learningModuleTitle = @"";
    self.learningModuleDescription = @"";
    self.learningModuleStatus = @"";
    self.learningModuleIntroVideoTitle = @"";
    self.learningModuleIntroVideoPath = @"";
    
    self.learningModuleVideoTitles = [[NSMutableArray alloc] init];
    self.learningModuleVideoPaths = [[NSMutableArray alloc] init];
    self.learningModuleDocumentTitles = [[NSMutableArray alloc] init];
    self.learningModuleDocumentPaths = [[NSMutableArray alloc] init];
    
    self.selectedAssetPath = @"";

    [self getLearningModule:HTWebSvcURL withState:0];
}

- (void)viewWillAppear:(BOOL)animated {
    
    if (!UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
        
        [[UIDevice currentDevice] setValue:
         [NSNumber numberWithInteger: UIInterfaceOrientationPortrait]
                                    forKey:@"orientation"];
    }
    
    self.moviePlayerViewController = nil;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if ([appDelegate.passLogin isEqualToString:@""] ||
        [appDelegate.passPw isEqualToString:@""] ||
        appDelegate.passLogin == nil ||
        appDelegate.passPw == nil) {
        
        UINavigationController *navigationController = (UINavigationController *)self.navigationController;
        
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle: nil];
        
        HTLoginViewController *viewController = (HTLoginViewController*)[mainStoryboard instantiateViewControllerWithIdentifier: @"loginView"];
        
        viewController.hidesBottomBarWhenPushed = YES;
        
        [navigationController pushViewController:viewController animated:NO];
    }
    
    // make sure all app dates are set correctly
    [appDelegate checkAppDatesWithPlanner:NO];
    
    self.doneUpdatingLearningModule = NO;
    
    [super viewWillAppear:animated];
}

#pragma mark - Methods

- (void)getLearningModule:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.learningModuleHasWorksheet = NO;
    self.doneUpdatingLearningModule = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=get_learning_module_details&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&session_id=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.learningModuleID];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)updateLearningModuleStatus:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.learningModuleHasWorksheet = NO;
    self.doneUpdatingLearningModule = YES;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=update_learning_module_status&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&session_id=%ld&status=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, (long)self.learningModuleID, self.learningModuleStatus];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:url]];
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: myRequestData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    
    self.xmlData = [NSMutableData dataWithCapacity:0];
    self.xmlData = [[NSMutableData alloc] init];
    
    @try {
        
        self.sphConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        
    } @catch (NSException *ex) {
        
        self.showConnError = YES;
    }
}

- (void)showLearningModule {
    
    NSInteger vPos = -64;
    
    UIButton *learnBlockButton;
    
    UILabel *learnLabel;
    
    UIImageView *learnImage;
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    int learnBlockHeight;
    
    UIFont *learnTitleFont = [UIFont fontWithName:@"Avenir-Light" size:20.0];
    UIFont *learnAssetTitleFont = [UIFont fontWithName:@"AvenirNext-Medium" size:14.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 128)];
    
    learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, (screenWidth - 32), 64)];
    
    learnLabel.numberOfLines = 2;
    
    [learnLabel setTextAlignment:NSTextAlignmentLeft];
    [learnLabel setFont:learnTitleFont];
    [learnLabel setTextColor:grayFontColor];
    [learnLabel setText:self.learningModuleTitle];
    
    [learnBlockButton addSubview:learnLabel];
    
    learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 64, (screenWidth - 32), 64)];
    
    learnLabel.numberOfLines = 0;

    [learnLabel setTextAlignment:NSTextAlignmentLeft];
    [learnLabel setFont:[UIFont fontWithName:@"AvenirNext-regular" size:14.0]];
    [learnLabel setTextColor:grayFontColor];
    [learnLabel setText:self.learningModuleDescription];
    [learnLabel sizeToFit];
    
    [learnBlockButton addSubview:learnLabel];
    
    [self.learnScrollView addSubview:learnBlockButton];
    
    vPos += (learnLabel.frame.size.height + 78);
    
    // intro video
    
    if (![self.learningModuleIntroVideoTitle isEqualToString:@""] &&
        ![self.learningModuleIntroVideoPath isEqualToString:@""]) {
        
        learnBlockHeight = 51;
        
        learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
        
        [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
        
        learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 13, 26, 26)];
        
        [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-video"]];
        
        [learnBlockButton addSubview:learnImage];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, screenWidth - 77, 20)];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setFont:learnAssetTitleFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:self.learningModuleIntroVideoTitle];
        
        [learnBlockButton addSubview:learnLabel];
        
        [learnBlockButton addTarget:self action:@selector(playIntroMovie) forControlEvents:UIControlEventTouchUpInside];
        
        [self.learnScrollView addSubview:learnBlockButton];
        
        vPos += 55;
    }
    
    // videos
    
    for (int i=1; i<[self.learningModuleVideoTitles count]; i++) {
        
        learnBlockHeight = 51;
        
        learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
        
        [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
        
        learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 13, 26, 26)];
        
        [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-video"]];
        
        [learnBlockButton addSubview:learnImage];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, screenWidth - 77, 20)];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setFont:learnAssetTitleFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:[self.learningModuleVideoTitles objectAtIndex:i]];
        
        [learnBlockButton addSubview:learnLabel];
        
        [learnBlockButton setTag:i];
        
        [learnBlockButton addTarget:self action:@selector(playMovie:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.learnScrollView addSubview:learnBlockButton];
        
        vPos += 55;
    }
    
    // documents
    
    for (int i=1; i<[self.learningModuleDocumentTitles count]; i++) {
        
        learnBlockHeight = 51;
        
        learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
        
        [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
        
        learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 13, 26, 26)];
        
        [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-document"]];
        
        [learnBlockButton addSubview:learnImage];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, screenWidth - 77, 20)];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setFont:learnAssetTitleFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:[self.learningModuleDocumentTitles objectAtIndex:i]];
        
        [learnBlockButton addSubview:learnLabel];
        
        [learnBlockButton setTag:i];
        
        [learnBlockButton addTarget:self action:@selector(showDocument:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.learnScrollView addSubview:learnBlockButton];
        
        vPos += 55;
    }
    
    // worksheet
    
    if (self.learningModuleHasWorksheet == YES) {
        
        learnBlockHeight = 51;
        
        learnBlockButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, learnBlockHeight)];
        
        [learnBlockButton setBackgroundColor:[UIColor whiteColor]];
        
        learnImage = [[UIImageView alloc] initWithFrame:CGRectMake(15, 13, 26, 26)];
        
        [learnImage setImage:[UIImage imageNamed:@"ht-learning-module-worksheet"]];
        
        [learnBlockButton addSubview:learnImage];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(56, 16, screenWidth - 77, 20)];
        [learnLabel setTextAlignment:NSTextAlignmentLeft];
        [learnLabel setFont:learnAssetTitleFont];
        [learnLabel setTextColor:grayFontColor];
        [learnLabel setText:@"Worksheet Questions"];
        
        [learnBlockButton addSubview:learnLabel];
        
        [learnBlockButton addTarget:self action:@selector(showWorksheet) forControlEvents:UIControlEventTouchUpInside];
        
        [self.learnScrollView addSubview:learnBlockButton];
        
        vPos += 55;
    }
    
    if (![self.learningModuleStatus isEqualToString:@"DONE"]) {
    
        UIButton *markAsCompleteButton;
        
        markAsCompleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, screenHeight - 60, screenWidth, 60)];
        
        [markAsCompleteButton setBackgroundColor:[UIColor colorWithRed:(113/255.0) green:(202/255.0) blue:(94/255.0) alpha:1.0]];
        
        [markAsCompleteButton addTarget:self action:@selector(markAsCompleteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        learnLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 6, (screenWidth - 32), 50)];
        
        [learnLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:14.0]];
        [learnLabel setTextColor:[UIColor whiteColor]];
        [learnLabel setTextAlignment:NSTextAlignmentCenter];
        [learnLabel setText:@"MARK AS COMPLETE"];
        
        [markAsCompleteButton addSubview:learnLabel];
        
        [self.view addSubview:markAsCompleteButton];
        
        vPos += 60;
    }

    [self.learnScrollView setContentSize:CGSizeMake(screenWidth, vPos)];
}

- (UIBarButtonItem *)backButton {
    
    UIImage *image = [UIImage imageNamed:@"ht-nav-bar-button-back-arrow"];
    
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    
    [button addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    
    UIBarButtonItem *item= [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (void)backButtonPressed {
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)markAsCompleteButtonPressed {
    
    self.learningModuleStatus = @"DONE";
    
    [self updateLearningModuleStatus:HTWebSvcURL withState:0];
}

- (void)playIntroMovie {
    
    self.movieURL = [NSURL URLWithString:self.learningModuleIntroVideoPath];

    self.moviePlayerViewController = [[MPMoviePlayerViewController alloc]
                                                initWithContentURL:self.movieURL];
    
    self.moviePlayerViewController.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.moviePlayerViewController.moviePlayer.fullscreen = YES;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self presentMoviePlayerViewControllerAnimated:self.moviePlayerViewController];
}

- (void)playMovie:(id)sender {
    
    UIButton *movieButton = sender;

    self.selectedAssetPath = [self.learningModuleVideoPaths objectAtIndex:movieButton.tag];
    
    self.movieURL = [NSURL URLWithString:self.selectedAssetPath];

    self.moviePlayerViewController = [[MPMoviePlayerViewController alloc]
                                      initWithContentURL:self.movieURL];
    
    self.moviePlayerViewController.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    self.moviePlayerViewController.moviePlayer.fullscreen = YES;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];

    [self presentMoviePlayerViewControllerAnimated:self.moviePlayerViewController];
}

- (void)showDocument:(id)sender {
    
    UIButton *documentButton = sender;
    
    self.selectedAssetPath = [self.learningModuleDocumentPaths objectAtIndex:documentButton.tag];
    
    [self performSegueWithIdentifier:@"showWebContentFromLearningModule" sender:self];
}

- (void)showWorksheet {
    
    [self performSegueWithIdentifier:@"showWorksheetFromLearningModule" sender:self];
}

#pragma mark - UINavigationController delegate methods

// CHECKIT - UIInterfaceOrientationMask

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([self.xmlData length]) {
        
        self.xmlParser = [[NSXMLParser alloc] initWithData:self.xmlData];
        
        [self.xmlParser setDelegate:self];
        [self.xmlParser setShouldProcessNamespaces:NO];
        [self.xmlParser setShouldReportNamespacePrefixes:NO];
        [self.xmlParser setShouldResolveExternalEntities:NO];
        [self.xmlParser parse];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [self handleURLError:error];
    
    self.sphConnection = nil;
}

#pragma mark - NSXMLParserDelegate methods

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
    self.currentElement = nil;
    self.currentValue = nil;
    self.webSvcError = nil;
    
    self.learningModuleTitle = @"";
    self.learningModuleDescription = @"";
    self.learningModuleStatus = @"";
    self.learningModuleIntroVideoTitle = @"";
    self.learningModuleIntroVideoPath = @"";
    
    [self.learningModuleVideoTitles removeAllObjects];
    [self.learningModuleVideoPaths removeAllObjects];
    [self.learningModuleDocumentTitles removeAllObjects];
    [self.learningModuleDocumentPaths removeAllObjects];

    
    [self.learningModuleVideoTitles insertObject:@"" atIndex:0];
    [self.learningModuleVideoPaths insertObject:@"" atIndex:0];
    [self.learningModuleDocumentTitles insertObject:@"" atIndex:0];
    [self.learningModuleDocumentPaths insertObject:@"" atIndex:0];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    self.showConnError = YES;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    
    self.currentElement = elementName;
    self.currentValue = [[NSMutableString alloc] init];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSString *cleanStr = [[NSString alloc] init];
    
    cleanStr = [appDelegate cleanStringAfterReceiving:self.currentValue];
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_title"]) {
        
        self.learningModuleTitle = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_status"]) {
        
        self.learningModuleStatus = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_description"]) {
        
        self.learningModuleDescription = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_has_worksheet"]) {
        
        if ([cleanStr isEqualToString:@"1"]) {
            
            self.learningModuleHasWorksheet = YES;
            
        } else {
            
            self.learningModuleHasWorksheet = NO;
        }
        
    } else if ([elementName isEqualToString:@"learning_module_intro_video_title"]) {
        
        self.learningModuleIntroVideoTitle = cleanStr;
        
    } else if ([elementName isEqualToString:@"learning_module_intro_video_path"]) {
        
        self.learningModuleIntroVideoPath = cleanStr;
        
    } else if ([elementName hasPrefix:@"learning_module_video_title_"]) {
        
        [self.learningModuleVideoTitles insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_video_title_" withString:@""]
                                                                       integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_video_path_"]) {
        
        [self.learningModuleVideoPaths insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_video_path_" withString:@""]
                                                                      integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_document_title_"]) {
        
        [self.learningModuleDocumentTitles insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_document_title_" withString:@""]
                                                                       integerValue]];
        
    } else if ([elementName hasPrefix:@"learning_module_document_path_"]) {
        
        [self.learningModuleDocumentPaths insertObject:cleanStr atIndex:[[elementName stringByReplacingOccurrencesOfString:@"learning_module_document_path_" withString:@""]
                                                                      integerValue]];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    [self.currentValue appendString:string];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (self.showConnError == YES) {
        
        [self.view makeToast:connError duration:3.0 position:@"center"];
        
        self.showConnError = NO;
        
    } else if ([self.webSvcError isEqualToString:@""]) {
        
        if (self.doneUpdatingLearningModule == YES) {
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else {
            
            [self showLearningModule];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showWebContentFromLearningModule"]) {
    
        [self.navigationController setNavigationBarHidden:NO];
        
        HTWebContentViewController *viewController = segue.destinationViewController;
        
        viewController.selectedAssetTitle = @"Learning Modules";
        viewController.selectedAssetPath = self.selectedAssetPath;
    
    } else if ([segue.identifier isEqualToString:@"showWorksheetFromLearningModule"]) {
        
        [self.navigationController setNavigationBarHidden:NO];
        
        HTLearnWorksheetViewController *viewController = segue.destinationViewController;
        
        viewController.learningModuleID = self.learningModuleID;
    }
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
