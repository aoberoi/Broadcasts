//
//  OTPSViewController.h
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 11/28/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "BroadcastCreationViewController.h"
#import "BroadcastViewController.h"

@interface BroadcastTableViewController : PFQueryTableViewController <OTPSCreateBroadcastDelegate>

@property (nonatomic, strong) BroadcastViewController *showBroadcastViewController;

@end
