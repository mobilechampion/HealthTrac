//
//  HTTableViewCellController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 9/19/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTTableViewCellController.h"

@implementation HTTableViewCellController

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    int screenWidth = self.window.frame.size.width;
    
    CGRect newFrame = self.textLabel.frame;
    newFrame.origin.y = 52;
    
    if (screenWidth > 320) {
        
        newFrame.size.width = ((screenWidth - 320) + 200);
        
    } else {
        
        newFrame.size.width = 212;
    }
    
    newFrame.size.height = 4;
    
    [self.detailTextLabel setFrame:newFrame];
    
    self.detailTextLabel.backgroundColor = [UIColor colorWithRed:(222/255.0)
                                                           green:(228/255.0)
                                                            blue:(231/255.0)
                                                           alpha:1.0];

    self.detailTextLabel.font = [UIFont systemFontOfSize:12.0];
}

- (void)setDetailBGColor:(UIColor *) color {
    
    self.detailTextLabel.backgroundColor = color;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
