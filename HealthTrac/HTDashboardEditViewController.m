//
//  HTDashboardEditViewController.m
//  HealthTrac
//
//  Created by Rob O'Neill on 9/16/14.
//  Copyright (c) 2014 SetPoint Health. All rights reserved.
//

#import "HTDashboardEditViewController.h"
#import "HTAppDelegate.h"
#import "HTLoginViewController.h"

@interface HTDashboardEditViewController ()

@end

@implementation HTDashboardEditViewController

#pragma mark - View lifecycle

- (void)loadView {
    
    [super loadView];
    
    int screenWidth = self.view.frame.size.width;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake((screenWidth / 2) - 50, 0, 100, 40)];
    
    [titleLabel setFont:[UIFont fontWithName:@"Omnes-Light" size:23.0]];
    [titleLabel setTextColor:[UIColor colorWithRed:(59/255.0)
                                             green:(183/255.0)
                                              blue:(234/255.0)
                                             alpha:1.0]];
    
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    NSMutableAttributedString *titleLabelString;
    
    titleLabelString = [[NSMutableAttributedString alloc]
                        initWithString:@"HealthTrac"];
    
    [titleLabelString addAttribute:NSFontAttributeName
                             value:[UIFont fontWithName:@"Omnes-Medium" size:23.0]
                             range:NSMakeRange([titleLabelString length] -4, 4)];
    
    titleLabel.attributedText = titleLabelString;
    
    self.navigationItem.titleView = titleLabel;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setEditing:YES animated:NO];
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    self.tableView.separatorColor = [UIColor clearColor];
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
    
    self.dashboardUserSort = [[NSMutableArray alloc] init];
    self.dashboardObjects = [[NSMutableArray alloc] init];
    
    self.dashboardUserPrefs = [[NSMutableDictionary alloc] init];
    
    self.dashboardObject = [[NSObject alloc] init];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *userPrefsString;
    
    userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
    
    if([prefs objectForKey:userPrefsString] == nil) { // does not yet exist
        
        // create the default dashboardUserPrefs and dashboardUserSort
        for (id object in appDelegate.dashboardEditItems) {
            [self.dashboardUserSort addObject:object]; // add this item
            [self.dashboardUserPrefs setObject:@"1" forKey:object]; // turn this item "on" by default
        }
        
        [prefs setObject:self.dashboardUserPrefs forKey:userPrefsString];
        
        userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserSort"];
        
        [prefs setObject:self.dashboardUserSort forKey:userPrefsString];
        
        [prefs synchronize];
        
    } else {
        
        self.dashboardUserPrefs = [NSMutableDictionary
                                   dictionaryWithDictionary:[prefs objectForKey:userPrefsString]];
        
        userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserSort"];
        
        self.dashboardUserSort = [NSMutableArray
                                  arrayWithArray:[prefs objectForKey:userPrefsString]];
        
        // if it's in your prefs, but not a valid dashboard item, store it and then remove it
        for (id object in self.dashboardUserSort) {
            if (![appDelegate.dashboardEditItems containsObject:object]) {
                [self.dashboardObjects addObject:object];
                [self.dashboardUserPrefs removeObjectForKey:object];
            }
        }
        
        // remove from above
        for (id object in self.dashboardObjects) {
            [self.dashboardUserSort removeObject:object];
        }
        
        // if it's a valid dashboard item, but not in your prefs, add it
        for (id object in appDelegate.dashboardEditItems) {
            if (![self.dashboardUserSort containsObject:object]) {
                [self.dashboardUserSort addObject:object];
                [self.dashboardUserPrefs setObject:@"1" forKey:object];
            }
        }
        
        userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
        
        [prefs setObject:self.dashboardUserPrefs forKey:userPrefsString];
        
        userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserSort"];
        
        [prefs setObject:self.dashboardUserSort forKey:userPrefsString];
        
        [prefs synchronize];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dashboardUserSort count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIView *graySeparator;
    
    UIFont *cellFont = [UIFont fontWithName:@"AvenirNext-Medium" size:16.0];
    
    cell.textLabel.font = cellFont;
    
    [cell.textLabel setTextColor:[UIColor colorWithRed:(117/255.0) green:(124/255.0) blue:(128/255.0) alpha:1.0]];
    
    cell.showsReorderControl = YES;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if ([[self.dashboardUserPrefs objectForKey:[self.dashboardUserSort objectAtIndex:indexPath.row]] isEqualToString:@"1"]) {
        
        cell.imageView.image = [UIImage imageNamed:@"ht-dash-edit-check"];
        
    } else {
        
        cell.imageView.image = [UIImage imageNamed:@"ht-dash-edit-check-off"];
    }
    
    if ([[self.dashboardUserSort objectAtIndex:indexPath.row] isEqualToString:@"calories"]) {
        
        cell.textLabel.text = @"Calories";
        
    } else if ([[self.dashboardUserSort objectAtIndex:indexPath.row] isEqualToString:@"weight"]) {
        
        cell.textLabel.text = @"Weight";
        
    } else {
        
        cell.textLabel.text = [self.dashboardUserSort objectAtIndex:indexPath.row];
    }
    
    [self tableView:self.tableView canMoveRowAtIndexPath:indexPath];
    
    int screenWidth = self.view.frame.size.width;
    int separatorOffset = cell.frame.size.height - 2;
    
    graySeparator = [[UIView alloc] initWithFrame:CGRectMake(0, separatorOffset, screenWidth, 5)];
    graySeparator.backgroundColor = [UIColor colorWithRed:(235/255.0) green:(240/255.0) blue:(242/255.0) alpha:1.0];
    
    [cell addSubview:graySeparator];
    
    // these keep the separator bar from slightly disappearing when a call is selected, then de-selected
    cell.clipsToBounds = NO;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([[self.dashboardUserPrefs objectForKey:[self.dashboardUserSort objectAtIndex:indexPath.row]] isEqualToString:@"1"]) {
        
        [self.tableView cellForRowAtIndexPath:indexPath].imageView.image = [UIImage imageNamed:@"ht-dash-edit-check-off"];
        
        [self.dashboardUserPrefs setObject:@"0" forKey:[self.dashboardUserSort objectAtIndex:indexPath.row]];
        
    } else {
        
        [self.tableView cellForRowAtIndexPath:indexPath].imageView.image = [UIImage imageNamed:@"ht-dash-edit-check"];
        
        [self.dashboardUserPrefs setObject:@"1" forKey:[self.dashboardUserSort objectAtIndex:indexPath.row]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 75;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    self.dashboardObject = [self.dashboardUserSort objectAtIndex:fromIndexPath.row];
    
    [self.dashboardUserSort removeObject:self.dashboardObject];
    [self.dashboardUserSort insertObject:self.dashboardObject atIndex:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (IBAction)doneEditing:(id)sender {
    
    HTAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSString *userPrefsString;
    
    [self.dashboardObjects removeAllObjects];
    
    for (id object in self.dashboardUserSort) {
        if ([[self.dashboardUserPrefs objectForKey:object] isEqualToString:@"0"]) { // find disabled items in this array
            [self.dashboardObjects addObject:object]; // add it to this temp array
        }
    }
    
    for (id object in self.dashboardObjects) { // now remove and re-add these items to the bottom of original array
        [self.dashboardUserSort removeObject:object];
        [self.dashboardUserSort addObject:object];
    }
    
    userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserPrefs"];
    
    [prefs setObject:self.dashboardUserPrefs forKey:userPrefsString];
    
    userPrefsString = [NSString stringWithFormat:@"%@-%@", appDelegate.passLogin, @"dashboardUserSort"];
    
    [prefs setObject:self.dashboardUserSort forKey:userPrefsString];
    
    [prefs synchronize];
    
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (IBAction)cancelEditing:(id)sender {
    
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

@end
