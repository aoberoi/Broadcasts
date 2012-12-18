//
//  OTPSBroadcastShowViewController.h
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 12/5/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <Opentok/Opentok.h>

@interface BroadcastViewController : UIViewController <UISplitViewControllerDelegate,
                                                               OTSessionDelegate,
                                                               OTPublisherDelegate,
                                                               OTSubscriberDelegate>

@property (nonatomic, strong) PFObject *broadcast;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end
