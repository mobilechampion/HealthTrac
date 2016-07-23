//
//  HTColorMyDayViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/22/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTColorMyDayViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"
#import "UIView+Toast.h"
#import "HTTrackerReminderViewController.h"

@interface HTColorMyDayViewController ()

@end

static NSString *const HTWebSvcURL = @"https://www.setpointhealth.com/ws_setpointhealth/mobile/sph_app_v2.0.asp";
static NSString *connError = @"There was a problem connecting.\n            Please try again later.";

@implementation HTColorMyDayViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    self.overallColor = [[NSString alloc] init];
    self.eatColor = [[NSString alloc] init];
    self.moveColor = [[NSString alloc] init];
    self.sleepColor = [[NSString alloc] init];
    self.stressColor = [[NSString alloc] init];
    
    self.title = @"Color My Day";
    
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
    
    [super viewWillAppear:animated];
    
    self.doneEditingColorMyDay = NO;
    self.colorMyDayReminder = NO;
    self.doBackgroundUpdate = NO;
    self.dateArrowClicked = NO;
    
    [self getColorMyDay:HTWebSvcURL withState:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    if (self.doBackgroundUpdate == YES) {
        
        [self updateColorMyDay:HTWebSvcURL withState:0];
    }
    
    [super viewWillDisappear:animated];
}

#pragma mark - Methods

- (void)getColorMyDay:(NSString *) url withState:(BOOL) urlState {
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    self.colorMyDayReminder = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        self.dateLabel.text = @"Today";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    else if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:
              [dateFormatter stringFromDate:[appDelegate addNumberOfDays:-1 toDate:appDelegate.currentDate]]]) {
        
        self.dateLabel.text = @"Yesterday";
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    else {
        
        self.dateLabel.text = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:appDelegate.passDate]];
        
        [self.leftDateArrow setUserInteractionEnabled:YES];
        [self.leftDateArrow setImage:[UIImage imageNamed:@"ht-arrow-left-blue"] forState:UIControlStateNormal];
        
        [self.rightDateArrow setUserInteractionEnabled:YES];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-blue"] forState:UIControlStateNormal];
    }
    
    myRequestString = [NSString stringWithFormat:@"action=get_color_my_day&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear];
    
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

- (void)updateColorMyDay:(NSString *) url withState:(BOOL) urlState {

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [self.view makeToastActivity];
    
    [self.sphConnection cancel]; // stop any previous call to the web service
    
    self.showConnError = NO;
    
    NSString *myRequestString;
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    myRequestString = [NSString stringWithFormat:@"action=update_color_my_day&userid=%@&pw=%@&day=%ld&month=%ld&year=%ld&overall=%@&eat=%@&move=%@&sleep=%@&stress=%@", appDelegate.passLogin, appDelegate.passPw, (long)appDelegate.passDay, (long)appDelegate.passMonth, (long)appDelegate.passYear, self.overallColor, self.eatColor, self.moveColor, self.sleepColor, self.stressColor];
    
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

- (void)showColorMyDay {
    
    NSArray *viewsToRemove = [self.colorMyDayView subviews];
    
    for (UIView *v in viewsToRemove) {
        
        [v removeFromSuperview];
    }
    
    NSInteger vPos = 0;
    
    UIView *graySeparator;
    UIView *colorBlock;
    
    UIButton *colorButton;
    
    UILabel *colorLabel;
    
    NSMutableAttributedString *subjectString;
    NSString *colorString;
    
    int screenWidth = self.view.frame.size.width;
    int screenHeight = self.view.frame.size.height;
    int colorBlockHeight = ((screenHeight - 108) / 5);
    int buttonDimensions;
    
    if (screenHeight < 568) {
        
        buttonDimensions = 32;
        
    } else {
        
        buttonDimensions = 48;
    }
    
    UIFont *subjectFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    UIFont *colorFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:14.0];
    UIFont *currentFont;
    
    UIColor *grayFontColor = [UIColor colorWithRed:(98/255.0) green:(98/255.0) blue:(98/255.0) alpha:1.0];
    UIColor *lightGrayFontColor = [UIColor colorWithRed:(178/255.0) green:(178/255.0) blue:(178/255.0) alpha:1.0];
    UIColor *greenFontColor = [UIColor colorWithRed:(112/255.0) green:(195/255.0) blue:(106/255.0) alpha:1.0];
    UIColor *yellowFontColor = [UIColor colorWithRed:(239/255.0) green:(198/255.0) blue:(120/255.0) alpha:1.0];
    UIColor *redFontColor = [UIColor colorWithRed:(221/255.0) green:(105/255.0) blue:(105/255.0) alpha:1.0];
    UIColor *currentFontColor;
    
    UIButton *reminderButton;
    
    UIImageView *reminderButtonImage;
    
    BOOL reminderIconOn = NO;
    
    if (self.colorMyDayReminder == YES) {
        
        reminderIconOn = YES;
    }
    
    // overall
    colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, colorBlockHeight)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [colorBlock addSubview:graySeparator];
    
    reminderButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    
    [reminderButton addTarget:self action:@selector(setReminder) forControlEvents:UIControlEventTouchUpInside];
    
    reminderButtonImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 12, 16, 16)];
    
    if (reminderIconOn == YES) {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder-on"]];
        
    } else {
        
        [reminderButtonImage setImage:[UIImage imageNamed:@"ht-reminder"]];
    }
    
    [reminderButton addSubview:reminderButtonImage];
    
    [colorBlock addSubview:reminderButton];
    
    colorLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 10, screenWidth - 46, 20)];
    
    [colorLabel setFont:subjectFont];
    [colorLabel setTextColor:grayFontColor];
    
    if ([self.overallColor isEqualToString:@"GREEN"]) {
        
        colorString = @"Well!";
        
        currentFont = colorFont;
        
        currentFontColor = greenFontColor;
        
    } else if ([self.overallColor isEqualToString:@"YELLOW"]) {
        
        colorString = @"Fairly well";
        
        currentFont = colorFont;
        
        currentFontColor = yellowFontColor;
        
    } else if ([self.overallColor isEqualToString:@"RED"]) {
        
        colorString = @"Not so well";
        
        currentFont = colorFont;
        
        currentFontColor = redFontColor;
        
    } else {
        
        colorString = @"(Select to fill)";
        
        currentFont = subjectFont;
        
        currentFontColor = lightGrayFontColor;
    }
    
    subjectString = [[NSMutableAttributedString alloc]
                    initWithString:[NSString stringWithFormat:@"%@ %@",
                                    @"I followed my program",
                                    colorString]];
    
    [subjectString  addAttribute:NSFontAttributeName
                            value:currentFont
                            range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];

    [subjectString  addAttribute:NSForegroundColorAttributeName
                            value:currentFontColor
                            range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    colorLabel.attributedText = subjectString;
    
    [colorBlock addSubview:colorLabel];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 6) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:1];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.overallColor isEqualToString:@"GREEN"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 2) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:2];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.overallColor isEqualToString:@"YELLOW"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake(((screenWidth / 6) * 5) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:3];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.overallColor isEqualToString:@"RED"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    [self.colorMyDayView addSubview:colorBlock];
    
    vPos += colorBlockHeight;
    
    // eat
    colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, colorBlockHeight)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [colorBlock addSubview:graySeparator];
    
    colorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
    
    [colorLabel setFont:subjectFont];
    [colorLabel setTextColor:grayFontColor];
    
    if ([self.eatColor isEqualToString:@"ONTRACK"]) {
        
        colorString = @"Good!";
        
        currentFont = colorFont;
        
        currentFontColor = greenFontColor;
        
    } else if ([self.eatColor isEqualToString:@"OK"]) {
        
        colorString = @"Fair";
        
        currentFont = colorFont;
        
        currentFontColor = yellowFontColor;
        
    } else if ([self.eatColor isEqualToString:@"OFF"]) {
        
        colorString = @"Poor";
        
        currentFont = colorFont;
        
        currentFontColor = redFontColor;
        
    } else {
        
        colorString = @"(Select to fill)";
        
        currentFont = subjectFont;
        
        currentFontColor = lightGrayFontColor;
    }
    
    subjectString = [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@ %@",
                                     @"My eating was",
                                     colorString]];
    
    [subjectString  addAttribute:NSFontAttributeName
                           value:currentFont
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    [subjectString  addAttribute:NSForegroundColorAttributeName
                           value:currentFontColor
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    colorLabel.attributedText = subjectString;
    
    [colorBlock addSubview:colorLabel];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 6) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:4];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.eatColor isEqualToString:@"ONTRACK"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 2) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:5];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.eatColor isEqualToString:@"OK"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake(((screenWidth / 6) * 5) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:6];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.eatColor isEqualToString:@"OFF"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    [self.colorMyDayView addSubview:colorBlock];
    
    vPos += colorBlockHeight;
    
    // move
    colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, colorBlockHeight)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [colorBlock addSubview:graySeparator];
    
    colorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
    
    [colorLabel setFont:subjectFont];
    [colorLabel setTextColor:grayFontColor];
    
    if ([self.moveColor isEqualToString:@"ONTRACK"]) {
        
        colorString = @"Good!";
        
        currentFont = colorFont;
        
        currentFontColor = greenFontColor;
        
    } else if ([self.moveColor isEqualToString:@"OK"]) {
        
        colorString = @"Fair";
        
        currentFont = colorFont;
        
        currentFontColor = yellowFontColor;
        
    } else if ([self.moveColor isEqualToString:@"OFF"]) {
        
        colorString = @"Poor";
        
        currentFont = colorFont;
        
        currentFontColor = redFontColor;
        
    } else {
        
        colorString = @"(Select to fill)";
        
        currentFont = subjectFont;
        
        currentFontColor = lightGrayFontColor;
    }
    
    subjectString = [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@ %@",
                                     @"My activity levels were",
                                     colorString]];
    
    [subjectString  addAttribute:NSFontAttributeName
                           value:currentFont
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    [subjectString  addAttribute:NSForegroundColorAttributeName
                           value:currentFontColor
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    colorLabel.attributedText = subjectString;
    
    [colorBlock addSubview:colorLabel];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 6) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:7];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.moveColor isEqualToString:@"ONTRACK"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 2) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:8];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.moveColor isEqualToString:@"OK"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake(((screenWidth / 6) * 5) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:9];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.moveColor isEqualToString:@"OFF"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    [self.colorMyDayView addSubview:colorBlock];
    
    vPos += colorBlockHeight;
    
    // sleep
    colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, colorBlockHeight)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [colorBlock addSubview:graySeparator];
    
    colorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
    
    [colorLabel setFont:subjectFont];
    [colorLabel setTextColor:grayFontColor];
    
    if ([self.sleepColor isEqualToString:@"GOOD"]) {
        
        colorString = @"Good!";
        
        currentFont = colorFont;
        
        currentFontColor = greenFontColor;
        
    } else if ([self.sleepColor isEqualToString:@"FAIR"]) {
        
        colorString = @"Fair";
        
        currentFont = colorFont;
        
        currentFontColor = yellowFontColor;
        
    } else if ([self.sleepColor isEqualToString:@"POOR"]) {
        
        colorString = @"Poor";
        
        currentFont = colorFont;
        
        currentFontColor = redFontColor;
        
    } else {
        
        colorString = @"(Select to fill)";
        
        currentFont = subjectFont;
        
        currentFontColor = lightGrayFontColor;
    }
    
    subjectString = [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@ %@",
                                     @"My sleep was",
                                     colorString]];
    
    [subjectString  addAttribute:NSFontAttributeName
                           value:currentFont
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    [subjectString  addAttribute:NSForegroundColorAttributeName
                           value:currentFontColor
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    colorLabel.attributedText = subjectString;
    
    [colorBlock addSubview:colorLabel];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 6) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:10];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.sleepColor isEqualToString:@"GOOD"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 2) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:11];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.sleepColor isEqualToString:@"FAIR"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake(((screenWidth / 6) * 5) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:12];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.sleepColor isEqualToString:@"POOR"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    [self.colorMyDayView addSubview:colorBlock];
    
    vPos += colorBlockHeight;
    
    // stress
    colorBlock = [[UIView alloc] initWithFrame:CGRectMake(0, vPos, screenWidth, colorBlockHeight)];
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [colorBlock addSubview:graySeparator];
    
    colorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, screenWidth - 20, 20)];
    
    [colorLabel setFont:subjectFont];
    [colorLabel setTextColor:grayFontColor];
    
    if ([self.stressColor isEqualToString:@"LOW"]) {
        
        colorString = @"Low!";
        
        currentFont = colorFont;
        
        currentFontColor = greenFontColor;
        
    } else if ([self.stressColor isEqualToString:@"MEDIUM"]) {
        
        colorString = @"Medium";
        
        currentFont = colorFont;
        
        currentFontColor = yellowFontColor;
        
    } else if ([self.stressColor isEqualToString:@"HIGH"]) {
        
        colorString = @"High";
        
        currentFont = colorFont;
        
        currentFontColor = redFontColor;
        
    } else {
        
        colorString = @"(Select to fill)";
        
        currentFont = subjectFont;
        
        currentFontColor = lightGrayFontColor;
    }
    
    subjectString = [[NSMutableAttributedString alloc]
                     initWithString:[NSString stringWithFormat:@"%@ %@",
                                     @"My stress levels were",
                                     colorString]];
    
    [subjectString  addAttribute:NSFontAttributeName
                           value:currentFont
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    [subjectString  addAttribute:NSForegroundColorAttributeName
                           value:currentFontColor
                           range:NSMakeRange([subjectString length] - [colorString length], [colorString length])];
    
    colorLabel.attributedText = subjectString;
    
    [colorBlock addSubview:colorLabel];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 6) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:13];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.stressColor isEqualToString:@"LOW"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-green-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake((screenWidth / 2) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:14];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.stressColor isEqualToString:@"MEDIUM"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-yellow-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    colorButton = [[UIButton alloc] initWithFrame:CGRectMake(((screenWidth / 6) * 5) - (buttonDimensions / 2), 34, buttonDimensions, buttonDimensions)];
    
    colorButton.enabled = YES;
    colorButton.userInteractionEnabled = YES;
    
    [colorButton setTag:15];
    
    [colorButton addTarget:self action:@selector(clickedColorButton:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([self.stressColor isEqualToString:@"HIGH"]) {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-on"] forState:UIControlStateNormal];
        
    } else {
        
        [colorButton setImage:[UIImage imageNamed:@"ht-color-button-red-off"] forState:UIControlStateNormal];
    }
    
    [colorBlock addSubview:colorButton];
    
    [self.colorMyDayView addSubview:colorBlock];
}

- (IBAction)clickedColorButton:(id)sender {
    
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    switch (buttonTag) {
            
        case 1:
            if ([self.overallColor isEqualToString:@"GREEN"]) {
                
                self.overallColor = @"";
                
            } else {
                
                self.overallColor = @"GREEN";
            }
            break;
            
        case 2:
            if ([self.overallColor isEqualToString:@"YELLOW"]) {
                
                self.overallColor = @"";
                
            } else {
                
                self.overallColor = @"YELLOW";
            }
            break;
            
        case 3:
            if ([self.overallColor isEqualToString:@"RED"]) {
                
                self.overallColor = @"";
                
            } else {
                
                self.overallColor = @"RED";
            }
            break;
            
        case 4:
            if ([self.eatColor isEqualToString:@"ONTRACK"]) {
                
                self.eatColor = @"";
                
            } else {
                
                self.eatColor = @"ONTRACK";
            }
            break;
            
        case 5:
            if ([self.eatColor isEqualToString:@"OK"]) {
                
                self.eatColor = @"";
                
            } else {
                
                self.eatColor = @"OK";
            }
            break;
            
        case 6:
            if ([self.eatColor isEqualToString:@"OFF"]) {
                
                self.eatColor = @"";
                
            } else {
                
                self.eatColor = @"OFF";
            }
            break;
            
        case 7:
            if ([self.moveColor isEqualToString:@"ONTRACK"]) {
                
                self.moveColor = @"";
                
            } else {
                
                self.moveColor = @"ONTRACK";
            }
            break;
            
        case 8:
            if ([self.moveColor isEqualToString:@"OK"]) {
                
                self.moveColor = @"";
                
            } else {
                
                self.moveColor = @"OK";
            }
            break;
            
        case 9:
            if ([self.moveColor isEqualToString:@"OFF"]) {
                
                self.moveColor = @"";
                
            } else {
                
                self.moveColor = @"OFF";
            }
            break;
            
        case 10:
            if ([self.sleepColor isEqualToString:@"GOOD"]) {
                
                self.sleepColor = @"";
                
            } else {
                
                self.sleepColor = @"GOOD";
            }
            break;
            
        case 11:
            if ([self.sleepColor isEqualToString:@"FAIR"]) {
                
                self.sleepColor = @"";
                
            } else {
                
                self.sleepColor = @"FAIR";
            }
            break;
            
        case 12:
            if ([self.sleepColor isEqualToString:@"POOR"]) {
                
                self.sleepColor = @"";
                
            } else {
                
                self.sleepColor = @"POOR";
            }
            break;
            
        case 13:
            if ([self.stressColor isEqualToString:@"LOW"]) {
                
                self.stressColor = @"";
                
            } else {
                
                self.stressColor = @"LOW";
            }
            break;
            
        case 14:
            if ([self.stressColor isEqualToString:@"MEDIUM"]) {
                
                self.stressColor = @"";
                
            } else {
                
                self.stressColor = @"MEDIUM";
            }
            break;
            
        case 15:
            if ([self.stressColor isEqualToString:@"HIGH"]) {
                
                self.stressColor = @"";
                
            } else {
                
                self.stressColor = @"HIGH";
            }
            break;
            
        default:
            break;
    }
    
    [self showColorMyDay];
}

- (IBAction)setReminder {
    
    [self performSegueWithIdentifier:@"showRemindersFromColorMyDay" sender:self];
}

#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    // reset the data object
    if ([self.xmlData length]) [self.xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    self.xmlParser = [[NSXMLParser alloc] initWithData:data];
    
    [self.xmlParser setDelegate:self];
    [self.xmlParser setShouldProcessNamespaces:NO];
    [self.xmlParser setShouldReportNamespacePrefixes:NO];
    [self.xmlParser setShouldResolveExternalEntities:NO];
    [self.xmlParser parse];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    self.sphConnection = nil;
    
    [self.view hideToastActivity];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
    
    self.overallColor = nil;
    self.eatColor = nil;
    self.moveColor = nil;
    self.sleepColor = nil;
    self.stressColor = nil;
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
    
    if ([elementName isEqualToString:@"error_message"]) {
        
        self.webSvcError = self.currentValue;
        
    }
    
    self.currentValue = [NSMutableString stringWithString:[self.currentValue uppercaseString]];
    
    if ([elementName isEqualToString:@"overall"]) {
        
        self.overallColor = self.currentValue;
        
    } else if ([elementName isEqualToString:@"eat"]) {
        
        self.eatColor = self.currentValue;
        
    } else if ([elementName isEqualToString:@"move"]) {
        
        self.moveColor = self.currentValue;
        
    } else if ([elementName isEqualToString:@"sleep"]) {
        
        self.sleepColor = self.currentValue;
        
    } else if ([elementName isEqualToString:@"stress"]) {
        
        self.stressColor = self.currentValue;
        
    } else if ([elementName isEqualToString:@"color_my_day_reminder"]) {
        
        if ([self.currentValue isEqualToString:@"Y"]) {
            
            self.colorMyDayReminder = YES;
            
        } else {
            
            self.colorMyDayReminder = NO;
        }
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
        
        if (self.doneEditingColorMyDay == YES) {
            
            self.doBackgroundUpdate = NO;
            
            [[self navigationController] popViewControllerAnimated:YES];
            
        } else if (self.dateArrowClicked == YES) {
            
            self.dateArrowClicked = NO;
            
            [self getColorMyDay:HTWebSvcURL withState:0];
            
        } else {
            
            self.doBackgroundUpdate = YES;
            
            [self showColorMyDay];
        }
        
    } else {
        
        [self.view makeToast:self.webSvcError duration:3.0 position:@"center"];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.navigationController setNavigationBarHidden:NO];
    
    HTTrackerReminderViewController *viewController = segue.destinationViewController;
    
    viewController.hidesBottomBarWhenPushed = YES;
    viewController.reminderType = @"color";
}

- (IBAction)leftDateArrowClick:(id)sender {
    
    self.dateArrowClicked = YES;
    
    [self updateColorMyDay:HTWebSvcURL withState:0];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:-1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    //[self getColorMyDay:HTWebSvcURL withState:0];
}

- (IBAction)rightDateArrowClick:(id)sender {
    
    self.dateArrowClicked = YES;
    
    [self updateColorMyDay:HTWebSvcURL withState:0];
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSCalendar *theCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDate *newDate = [appDelegate addNumberOfDays:1 toDate:appDelegate.passDate];
    
    NSDateComponents *dateComponents = [theCalendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:newDate];
    
    appDelegate.passDate = newDate;
    appDelegate.passDay = [dateComponents day];
    appDelegate.passMonth = [dateComponents month];
    appDelegate.passYear = [dateComponents year];
    
    // KRISTINA!!!  Bratty bug...  :)
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    if ([[dateFormatter stringFromDate:appDelegate.passDate] isEqualToString:[dateFormatter stringFromDate:appDelegate.currentDate]]) {
        
        [self.rightDateArrow setUserInteractionEnabled:NO];
        [self.rightDateArrow setImage:[UIImage imageNamed:@"ht-arrow-right-gray"] forState:UIControlStateNormal];
    }
    
    //[self getColorMyDay:HTWebSvcURL withState:0];
}

- (IBAction)cancelColorMyDay:(id)sender {
    
    self.doBackgroundUpdate = NO;
    
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)doneColorMyDay:(id)sender {
    
    self.doneEditingColorMyDay = YES;
    
    [self updateColorMyDay:HTWebSvcURL withState:0];
}

#pragma mark - Error Handling

- (void)handleURLError:(NSError *)error {
    
    self.showConnError = YES;
}

@end
