//
//  HTWebContentViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/12/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTWebContentViewController.h"
#import "HTAppDelegate.h"

@interface HTWebContentViewController ()

@end

@implementation HTWebContentViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.webUIView setBackgroundColor:[UIColor whiteColor]];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.navigationController.navigationBar.translucent = YES;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.shouldAllowPortrait = YES;
    
    [super viewWillAppear:animated];
    
    self.title = self.selectedAssetTitle;
    
    [self showWebContent];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.shouldAllowPortrait = NO;
    
    [super viewWillDisappear:animated];
}

#pragma mark - Methods

- (void)showWebContent {
    
    [self.webView setBackgroundColor:[UIColor whiteColor]];
    
    self.webView.scalesPageToFit = YES;
    
    NSURL *myUrl = [NSURL URLWithString:self.selectedAssetPath];
    
    NSURLRequest *myRequest = [NSURLRequest requestWithURL:myUrl];
    
    [self.webView loadRequest:myRequest];
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

#pragma mark - UINavigationController delegate methods

- (BOOL)shouldAutorotate {
    
    return YES;
}

// CHECKIT - UIInterfaceOrientationMask

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
