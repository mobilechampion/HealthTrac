//
//  HTWebContentViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 12/12/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTWebContentViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *webUIView;
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSString *selectedAssetTitle;
@property (strong, nonatomic) NSString *selectedAssetPath;

- (UIBarButtonItem *)backButton;

- (void)backButtonPressed;

- (void)showWebContent;

@end
