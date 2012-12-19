//
//  OTPSBroadcastShowViewController.m
//  OpenTokParseSample
//
//  Created by Ankur Oberoi on 12/5/12.
//  Copyright (c) 2012 Ankur Oberoi. All rights reserved.
//

#import "BroadcastViewController.h"
#import "Constants.h"

@interface BroadcastViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) OTSession *session;
@property (strong, nonatomic) NSMutableSet *disconnectListeners;
+ (NSString *)textForStatus:(OTSessionConnectionStatus)status;
- (void)configureView;
- (void)didEnterBackground;
- (void)willEnterForeground;
- (void)addVideoViewConstraints:(UIView *)videoView;
- (void)connectToBroadcast;
- (BOOL)isBroadcastOwner;
- (void)ensureSessionDisconnectedBeforeBlock:(void (^)(void))resumeBlock;
@end

@implementation BroadcastViewController

#pragma mark - View Management

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    [self configureView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Do any additional cleanup after the view will go away
    [self.session disconnect];
    
    [super viewWillDisappear:animated];
}

- (void)configureView
{
    if (self.broadcast) {
        self.navigationItem.title = self.broadcast[@"title"];
    }
    
    if (self.session) {
        self.statusLabel.text = [BroadcastViewController textForStatus:self.session.sessionConnectionStatus];
    } else {
        self.statusLabel.text = @"";
    }
}

// TODO: Localization
+ (NSString *)textForStatus:(OTSessionConnectionStatus)status {
    NSString *text;
    switch (status) {
        case OTSessionConnectionStatusConnected:
            text = @"Connected";
            break;
        case OTSessionConnectionStatusConnecting:
            text = @"Connecting";
            break;
        case OTSessionConnectionStatusDisconnected:
            text = @"Disconnected";
            break;
        case OTSessionConnectionStatusFailed:
            text = @"Failed";
            break;
            
        default:
            text = @"";
            break;
    }
    return text;
}

#pragma mark - Broadcast

- (void)setBroadcast:(PFObject *)broadcast
{
    if (![broadcast isEqual:self.broadcast]){
        
        [self ensureSessionDisconnectedBeforeBlock:^ {
            _broadcast = broadcast;
            
            [self connectToBroadcast];
            [self configureView];
        }];
        
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
    
}

- (void)connectToBroadcast
{
    
    // Create a new session when either there is no Session or the Session is old
    if ( !self.session || ![self.broadcast[@"sessionId"] isEqual:self.session.sessionId]) {
        
        self.session = [[OTSession alloc] initWithSessionId:self.broadcast[@"sessionId"]
                                                   delegate:self];
    }
    
    // Connect to the Session as long as its not already connecting or connected
    if ( !( self.session.sessionConnectionStatus == OTSessionConnectionStatusConnected ||
           self.session.sessionConnectionStatus == OTSessionConnectionStatusConnecting   ) ) {
        
        // Get a token by calling Parse Cloud Code function
        [PFCloud callFunctionInBackground:@"getBroadcastToken"
                           withParameters:@{ @"broadcast" : self.broadcast.objectId }
                                    block:^(NSString *token, NSError *error) {
                                        if (!error) {
                                            [self.session connectWithApiKey:kOpentokApiKey token:token];
                                            [self configureView];
                                        }
                                    }];
        
    }
}

- (BOOL)isBroadcastOwner {
    return [[(PFUser *)self.broadcast[@"owner"] objectId] isEqual:[[PFUser currentUser] objectId]];
}

#pragma mark - Split View Delegate

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"Broadcasts";
    self.navigationItem.leftBarButtonItem = barButtonItem;
    self.masterPopoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)button
{
    self.navigationItem.leftBarButtonItem = nil;
    self.masterPopoverController = nil;
}

#pragma mark - OpenTok Session Delegate

- (void)sessionDidConnect:(OTSession *)session
{
    // Publish if this user owns this broadcast
    if ([self isBroadcastOwner]) {
        OTPublisher *publisher = [[OTPublisher alloc] initWithDelegate:self];
        [self.session publish:publisher];
    }
    [self configureView];
}

- (void)sessionDidDisconnect:(OTSession *)session
{
    for (void (^handler)(void) in self.disconnectListeners) {
        handler();
        [self.disconnectListeners removeObject:handler];
    }
    [self configureView];
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error
{
    NSLog(@"Session failed to connect: %@", error.userInfo);
    [self configureView];
}

- (void)session:(OTSession *)session didReceiveStream:(OTStream *)stream
{
    if (![self isBroadcastOwner]) {
        __unused OTSubscriber *subscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
    }
}

- (void)session:(OTSession *)session didDropStream:(OTStream *)stream
{
    // Note: Removing subscriber view done automatically
}

#pragma mark - OpenTok Session Helpers

- (void)ensureSessionDisconnectedBeforeBlock:(void (^)(void))resumeBlock {
    
    // If the session exists, and it is connected or connecting, then save this block as a listener and start disconnecting
    if (self.session && (self.session.sessionConnectionStatus == OTSessionConnectionStatusConnected ||
                         self.session.sessionConnectionStatus == OTSessionConnectionStatusConnecting)) {
        
        [self.disconnectListeners addObject:resumeBlock];
        [self.session disconnect];
        
        // Otherwise, we can execute the block right now
    } else {
        resumeBlock();
    }
}

#pragma mark - OpenTok Publisher Delegate

- (void)publisher:(OTPublisher*)publisher didFailWithError:(OTError*) error
{
    NSLog(@"Publisher failed to initialize");
}

-(void)publisherDidStartStreaming:(OTPublisher*)publisher
{
    [self.view addSubview:publisher.view];
    [self addVideoViewConstraints:publisher.view];
}

-(void)publisherDidStopStreaming:(OTPublisher*)publisher
{
    // Note: Removing publisher view done automatically
}

#pragma mark - OpenTok Subscriber Delegate

- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    [self.view addSubview:subscriber.view];
    [self addVideoViewConstraints:subscriber.view];
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"Subscriber failed to connect to stream");
}

# pragma mark - Object Lifecycle

- (void) awakeFromNib
{
    // Initialize data structures
    self.disconnectListeners = [[NSMutableSet alloc] init];
    
    // Register for app backgrounding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // Unsubscribe from notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - Backgrounding

- (void)didEnterBackground
{
    if (self.broadcast) {
        [self.disconnectListeners removeAllObjects];
    }
    
}

- (void)willEnterForeground
{
    if (self.broadcast) {
        [self connectToBroadcast];
    }
}

#pragma mark - Auto Layout

- (void)addVideoViewConstraints:(UIView *)videoView
{
    NSDictionary *views = NSDictionaryOfVariableBindings(self.view, videoView);
    
    // video view constraints to itself
    videoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:videoView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:videoView
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:0.75
                                                           constant:0]];
    
    // video view constaints in relation to super view
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=20)-[videoView]-(>=20)-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:videoView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:videoView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0
                                                           constant:0]];
    // optional constraints
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[videoView]-|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:views];
    for (NSLayoutConstraint *constraint in horizontalConstraints) {
        constraint.priority = UILayoutPriorityRequired - 10;
    }
    [self.view addConstraints:horizontalConstraints];
}

@end
