//
//  OTPSBroadcastCell.h
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 12/4/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface BroadcastCell : PFTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *ownerLabel;

@end
