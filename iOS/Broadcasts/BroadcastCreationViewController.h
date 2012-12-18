//
//  OTPSCreateConversationViewController.h
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 11/30/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class BroadcastCreationViewController;

@protocol OTPSCreateBroadcastDelegate <NSObject>

- (void)createBroadcastController:(BroadcastCreationViewController *)createBroadcastViewController didAddBroadcast:(PFObject *)broadcast;

@end

@interface BroadcastCreationViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet id <OTPSCreateBroadcastDelegate> delegate;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end
