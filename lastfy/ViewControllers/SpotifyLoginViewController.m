//
//  SpotifyLoginViewController.m
//  lastfy
//
//  Created by Ezequiel Santos on 5/5/15.
//  Copyright (c) 2015 Ezequiel França. All rights reserved.
//

#import "SpotifyLoginViewController.h"
#import <Spotify/Spotify.h>
//#import "Config.h"

@interface SpotifyLoginViewController () <SPTAuthViewDelegate>

@property (atomic, readwrite) SPTAuthViewController *authViewController;

@end

@implementation SpotifyLoginViewController


- (void)viewDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdatedNotification:) name:@"sessionUpdated" object:nil];
    self.statusLabel.text = @"";
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)sessionUpdatedNotification:(NSNotification *)notification {
    self.statusLabel.text = @"";
    if(self.navigationController.topViewController == self) {
        SPTAuth *auth = [SPTAuth defaultInstance];
        if (auth.session && [auth.session isValid]) {
            [self performSegueWithIdentifier:@"ShowPlayer" sender:nil];
        }
    }
}

-(void)showPlayer {
    self.statusLabel.text = @"Logged in.";
    [self performSegueWithIdentifier:@"ShowPlayer" sender:nil];
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didFailToLogin:(NSError *)error {
    self.statusLabel.text = @"Login failed.";
    NSLog(@"*** Failed to log in: %@", error);
}

- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didLoginWithSession:(SPTSession *)session {
    self.statusLabel.text = @"";
    [self showPlayer];
}

- (void)authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController {
    self.statusLabel.text = @"Login cancelled.";
}

- (void)openLoginPage {
    self.statusLabel.text = @"Logging in...";
    
    self.authViewController = [SPTAuthViewController authenticationViewController];
    self.authViewController.delegate = self;
    self.authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.definesPresentationContext = YES;
    
    [self presentViewController:self.authViewController animated:NO completion:nil];
}


- (void)renewTokenAndShowPlayer {
    self.statusLabel.text = @"Refreshing token...";
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        auth.session = session;
        
        if (error) {
            self.statusLabel.text = @"Refreshing token failed.";
            NSLog(@"*** Error renewing session: %@", error);
            return;
        }
        
        [self showPlayer];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    // Check if we have a token at all
    if (auth.session == nil) {
        self.statusLabel.text = @"";
        return;
    }
    
    // Check if it's still valid
    if ([auth.session isValid]) {
        // It's still valid, show the player.
        [self performSegueWithIdentifier:@"ShowPlayer" sender:nil];
        return;
    }
    
    // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
    self.statusLabel.text = @"Token expired.";
    if (auth.hasTokenRefreshService) {
        [self renewTokenAndShowPlayer];
        return;
    }
    
    // Else, just show login dialog
}

- (IBAction)loginClicked:(id)sender {
    [self openLoginPage];
}

- (IBAction)clearCookiesClicked:(id)sender {
    self.authViewController = [SPTAuthViewController authenticationViewController];
    [self.authViewController clearCookies:nil];
    self.statusLabel.text = @"Cookies cleared.";
}
@end