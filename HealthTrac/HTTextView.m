//
//  HTTextView.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/4/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTTextView.h"

@implementation HTTextView

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 6, 0);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 6, 0);
}

- (HTTextView *)initHTDefaultWithFrame:(CGRect)frame {

UIFont *valuesFont = [UIFont fontWithName:@"OpenSans-Light" size:14.0];

UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];

HTTextView *textView = [[HTTextView alloc] initWithFrame:frame];

    [textView textRectForBounds:textView.bounds];
    [textView editingRectForBounds:textView.bounds];
    [textView setUserInteractionEnabled:YES];
    [textView setTextAlignment:NSTextAlignmentLeft];
    [textView setTextColor:grayFontColor];
    [textView setFont:valuesFont];
    [textView setKeyboardType:UIKeyboardTypeASCIICapable];
    [textView.layer setCornerRadius:2.5f];
    [textView.layer setBorderWidth:0.7];
    [textView.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                    green:(227/255.0)
                                                     blue:(230/255.0)
                                                    alpha:1.0].CGColor];
    
    [textView setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                  green:(249/255.0)
                                                   blue:(250/255.0)
                                                  alpha:1.0]];
    return textView;
}

@end
