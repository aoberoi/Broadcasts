//
//  OTPSCreateConversationViewController.m
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 11/30/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import "BroadcastCreationViewController.h"

@interface BroadcastCreationViewController ()

@end

@implementation BroadcastCreationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)done:(id)sender {
    if (self.titleField.text.length > 0 && self.titleField.text.length < 25) {
        
        // Create the new Broadcast object
        PFObject *newBroadcast = [PFObject objectWithClassName:@"Broadcast"];
        newBroadcast[@"title"] = self.titleField.text;
        newBroadcast[@"owner"] = [PFUser currentUser];
        
        // Set the access control for the new Broadcast
        PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
        [acl setPublicReadAccess:YES];
        newBroadcast.ACL = acl;
        
        // Save the new Broadcast
        [newBroadcast saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [self.delegate createBroadcastController:self didAddBroadcast:newBroadcast];
                [self dismiss];
            } else {
                NSLog(@"Error saving Broadcast object: %@", error.description);
            }
        }];
        
        // Show loading interface
        self.titleField.enabled = NO;
        self.doneButton.enabled = NO;
        self.cancelButton.enabled = NO;
        
    } else {
        // Show validation error
        NSLog(@"Invalid title for new Broadcast object: %@", self.titleField.text);
    }
}

- (IBAction)cancel:(id)sender {
    [self dismiss];
}

// TODO: use segue unwinding
- (void)dismiss {
    // Dismiss view controller
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        // Clear value in text field
        self.titleField.text = [NSString string];
    }];
}
@end
