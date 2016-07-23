//
//  HTNavigationController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 12/13/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTNavigationController.h"

@interface HTNavigationController ()

@end

@implementation HTNavigationController

- (BOOL)shouldAutorotate {
    
    return [self.visibleViewController shouldAutorotate];
}

// CHECKIT - UIInterfaceOrientationMask

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return [self.visibleViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}

@end
