//
//  HTTextField.m
//  HealthTrac
//
//  Created by Rob O'Neill on 10/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTTextField.h"


@implementation HTTextField

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 6, 0);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 6, 0);
}

- (HTTextField *)initHTDefaultWithFrame:(CGRect)frame {
    
    UIFont *valuesFont = [UIFont fontWithName:@"OpenSans-Light" size:18.0];
    
    UIColor *grayFontColor = [UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0];

    HTTextField *textField = [[HTTextField alloc] initWithFrame:frame];
    
    [textField textRectForBounds:textField.bounds];
    [textField editingRectForBounds:textField.bounds];
    [textField setEnabled:YES];
    [textField setUserInteractionEnabled:YES];
    [textField setTextAlignment:NSTextAlignmentRight];
    [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [textField setTextColor:grayFontColor];
    [textField setFont:valuesFont];
    [textField setClearButtonMode:UITextFieldViewModeNever];
    [textField setKeyboardType:UIKeyboardTypeDecimalPad];
    [textField.layer setCornerRadius:2.5f];
    [textField.layer setBorderWidth:0.7];
    [textField.layer setBorderColor:[UIColor colorWithRed:(218/255.0)
                                                           green:(227/255.0)
                                                            blue:(230/255.0)
                                                           alpha:1.0].CGColor];
    
    [textField setBackgroundColor:[UIColor colorWithRed:(247/255.0)
                                                         green:(249/255.0)
                                                          blue:(250/255.0)
                                                         alpha:1.0]];
    return textField;
}

@end
