//
//  HTAddActivityViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/1/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTAddActivityViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTAddActivitySearchViewController.h"

@interface HTAddActivityViewController ()

@end

@implementation HTAddActivityViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.navigationItem.leftBarButtonItem = [self backButton];
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName:
                                  [UIColor colorWithRed:(117/255.0)
                                                  green:(124/255.0)
                                                   blue:(128/255.0)
                                                  alpha:1.0],
                              NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-Regular" size:20.0]}];
    
    self.title = @"Add Activity";
    
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.navigationController setNavigationBarHidden:NO];
    
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
    [appDelegate checkAppDatesWithPlanner:YES];
    
    [super viewWillAppear:animated];
    
    self.numberOfaddACtivityButtons = 4;
    
    [self showAddActivityCategories];
}

#pragma mark - Methods

- (void)showAddActivityCategories {
    
    NSArray *viewsToRemove = [self.addActivityView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    
    NSInteger vPos = 0;
    
    NSInteger addActivityButtonHeight;
    
    UIView *graySeparator;
    
    UIButton *addActivityButton;
    
    UIImageView *buttonImageView;
    
    UIFont *addActivityFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];
    
    addActivityButtonHeight = ((screenHeight - 71) / self.numberOfaddACtivityButtons);

    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [self.addActivityView addSubview:graySeparator];
    
    vPos += 8;
    
    addActivityButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addActivityButtonHeight)];
    
    [addActivityButton setTitleEdgeInsets:UIEdgeInsetsMake(((addActivityButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
    
    addActivityButton.titleLabel.font = addActivityFont;
    
    [addActivityButton setTitleColor:grayFontColor forState:UIControlStateNormal];
    [addActivityButton setTitle:@"My Favorites" forState:UIControlStateNormal];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addActivityButtonHeight / 5), 48, 48)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-activity-favorites"]];
    
    [addActivityButton addSubview:buttonImageView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addActivityButtonHeight - 8), screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [addActivityButton addSubview:graySeparator];
    
    [addActivityButton setTag:1];
    
    [addActivityButton addTarget:self action:@selector(addActivitySelectCategory:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.addActivityView addSubview:addActivityButton];
    
    vPos += addActivityButtonHeight;

    addActivityButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addActivityButtonHeight)];
    
    [addActivityButton setTitleEdgeInsets:UIEdgeInsetsMake(((addActivityButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
    
    addActivityButton.titleLabel.font = addActivityFont;
    
    [addActivityButton setTitleColor:grayFontColor forState:UIControlStateNormal];
    [addActivityButton setTitle:@"Exercise" forState:UIControlStateNormal];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addActivityButtonHeight / 5), 48, 48)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-activity-exercise"]];
    
    [addActivityButton addSubview:buttonImageView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addActivityButtonHeight - 8), screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [addActivityButton addSubview:graySeparator];
    
    [addActivityButton setTag:2];
    
    [addActivityButton addTarget:self action:@selector(addActivitySelectCategory:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.addActivityView addSubview:addActivityButton];
    
    vPos += addActivityButtonHeight;
    
    addActivityButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addActivityButtonHeight)];
    
    [addActivityButton setTitleEdgeInsets:UIEdgeInsetsMake(((addActivityButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
    
    addActivityButton.titleLabel.font = addActivityFont;
    
    [addActivityButton setTitleColor:grayFontColor forState:UIControlStateNormal];
    [addActivityButton setTitle:@"Stress Management" forState:UIControlStateNormal];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addActivityButtonHeight / 5), 48, 48)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-activity-balance"]];
    
    [addActivityButton addSubview:buttonImageView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addActivityButtonHeight - 8), screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [addActivityButton addSubview:graySeparator];
    
    [addActivityButton setTag:3];
    
    [addActivityButton addTarget:self action:@selector(addActivitySelectCategory:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.addActivityView addSubview:addActivityButton];
    
    vPos += addActivityButtonHeight;
    
    addActivityButton = [[UIButton alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, addActivityButtonHeight)];
    
    [addActivityButton setTitleEdgeInsets:UIEdgeInsetsMake(((addActivityButtonHeight / 5) * 2), 0.0f, 0.0f, 0.0f)];
    
    addActivityButton.titleLabel.font = addActivityFont;
    
    [addActivityButton setTitleColor:grayFontColor forState:UIControlStateNormal];
    [addActivityButton setTitle:@"Note" forState:UIControlStateNormal];
    
    buttonImageView = [[UIImageView alloc] initWithFrame:CGRectMake((screenWidth / 2) - 24, (addActivityButtonHeight / 5), 48, 48)];
    
    [buttonImageView setImage:[UIImage imageNamed:@"ht-planner-add-activity-note"]];
    
    [addActivityButton addSubview:buttonImageView];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, (addActivityButtonHeight - 8), screenWidth, 8)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [addActivityButton addSubview:graySeparator];
    
    [addActivityButton setTag:4];
    
    [addActivityButton addTarget:self action:@selector(addActivitySelectCategory:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.addActivityView addSubview:addActivityButton];
    
    vPos += addActivityButtonHeight;
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

- (void)addActivitySelectCategory:(id)sender {
    
    UIButton *button = sender;
    
    self.addActivityType = @"";
    
    if (button.tag == 1) {
        
        self.addActivityCategory = @"favorites";
        
        [self performSegueWithIdentifier:@"showActivitySearch" sender:self];
        
    } else if (button.tag == 2) {
        
        self.addActivityCategory = @"exercise";
        
        [self performSegueWithIdentifier:@"showActivitySearch" sender:self];
        
    } else if (button.tag == 3) {
        
        self.addActivityCategory = @"stress";
        
        [self performSegueWithIdentifier:@"showNewActivity" sender:self];
        
    } else if (button.tag == 4) {
        
        self.addActivityCategory = @"note";
        
        [self performSegueWithIdentifier:@"showNewActivity" sender:self];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTAddActivitySearchViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    
    viewController.addActivityCategory = self.addActivityCategory;
}

@end
