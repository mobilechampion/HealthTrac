//
//  HTColorMyDayViewController.h
//  HealthTrac
//
//  Created by Rob O'Neill on 10/22/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTColorMyDayViewController : UIViewController <NSXMLParserDelegate> {
    
}

@property (nonatomic, strong) NSURLConnection *sphConnection;
@property (nonatomic, strong) NSMutableData *xmlData;

@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableString *currentValue;
@property (nonatomic, strong) NSString *currentElement;

@property (nonatomic, strong) NSString *webSvcError;

@property (nonatomic, strong) NSString *overallColor;
@property (nonatomic, strong) NSString *eatColor;
@property (nonatomic, strong) NSString *moveColor;
@property (nonatomic, strong) NSString *sleepColor;
@property (nonatomic, strong) NSString *stressColor;

@property (nonatomic, assign) BOOL showConnError;

@property (nonatomic, assign) BOOL doneEditingColorMyDay;
@property (nonatomic, assign) BOOL colorMyDayReminder;
@property (nonatomic, assign) BOOL doBackgroundUpdate;
@property (nonatomic, assign) BOOL dateArrowClicked;

@property (strong, nonatomic) IBOutlet UIView *colorMyDayView;

@property (strong, nonatomic) IBOutlet UIButton *leftDateArrow;
@property (strong, nonatomic) IBOutlet UIButton *rightDateArrow;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

- (IBAction)cancelColorMyDay:(id)sender;
- (IBAction)doneColorMyDay:(id)sender;
- (IBAction)leftDateArrowClick:(id)sender;
- (IBAction)rightDateArrowClick:(id)sender;
- (IBAction)clickedColorButton:(id)sender;

- (void)getColorMyDay:(NSString *) url withState:(BOOL) urlState;

- (void)updateColorMyDay:(NSString *) url withState:(BOOL) urlState;

- (void)showColorMyDay;

// Error handling
- (void)handleURLError:(NSError *)error;

@end
