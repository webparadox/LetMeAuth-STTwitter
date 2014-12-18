//
//  LMATwitterSTProvider.m
//  LetMeAuth-STTwitter
//
//  Created by Evgeniy Yurtaev on 21.11.14.
//  Copyright (c) 2014 Webparadox, LLC. All rights reserved.
//


#import "LMATwitterSTProvider.h"
#import <STTwitter/STTwitter.h>
#import <Accounts/Accounts.h>
#import <UIKit/UIKit.h>
#import "ACAccountStore+GCD.h"


typedef NS_ENUM(NSInteger, LMATwitterSTAuthType) {
    LMATwitterSTAuthTypeNone,
    LMATwitterSTAuthTypeSafari,
    LMATwitterSTAuthTypeAccountStore
};


@interface LMATwitterSTProvider ()

@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) STTwitterAPI *twitterAPI;
@property (copy, nonatomic) NSString *consumerKey;
@property (copy, nonatomic) NSString *consumerSecret;
@property (copy, nonatomic) NSString *callbackURL;
@property (assign, nonatomic) LMATwitterSTAuthType type;
@property (copy, nonatomic) void (^errorBlock)(NSError *error);
@property (assign, nonatomic) BOOL cancelled;

- (void)didAuthenticateWithData:(NSDictionary *)data;
- (void)didFailWithError:(NSError *)error;
- (void)didCancel;
- (void)finish;

@end


@implementation LMATwitterSTProvider

@synthesize providerDelegate = _providerDelegate;

- (id)initWithConfiguration:(NSDictionary *)configuration
{
    NSString *consumerKey = configuration[LMATwitterSTConsumerKey];
    NSString *consumerSecret = configuration[LMATwitterSTConsumerSecret];
    NSString *callbackURL = configuration[LMATwitterSTCallbackURL];

    NSParameterAssert(consumerKey != nil && [consumerKey length] > 0);
    NSParameterAssert(consumerSecret != nil && [consumerSecret length] > 0);
    NSParameterAssert(callbackURL != nil && [callbackURL length] > 0);

    self = [super init];
    if (!self) {
        return nil;
    }

    self.consumerKey = consumerKey;
    self.consumerSecret = consumerSecret;
    self.callbackURL = callbackURL;

    self.accountStore = [[ACAccountStore alloc] init];

    __weak typeof(self)weakSelf = self;
    self.errorBlock = ^void (NSError *error) {
        __strong typeof(weakSelf)self = weakSelf;

        [self didFailWithError:error];
    };

    return self;
}

- (void)start
{
    __weak typeof(self)weakSelf = self;

    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore gcd_requestAccountsWithType:accountType options:nil queue:dispatch_get_main_queue() completion:^(BOOL granted, NSArray *accounts, NSError *error) {
        __strong typeof(weakSelf)self = weakSelf;

        if (!granted) {
            error = nil;
        }

        self.twitterAPI = [STTwitterAPI twitterAPIWithOAuthConsumerKey:self.consumerKey consumerSecret:self.consumerSecret];

        if (error || ![accounts count]) {
            [self.twitterAPI postTokenRequest:^(NSURL *url, NSString *oauthToken) {
                __strong typeof(weakSelf)self = weakSelf;

                if (self.cancelled) {
                    [self didCancel];
                    return;
                }

                self.type = LMATwitterSTAuthTypeSafari;
                [[UIApplication sharedApplication] openURL:url];
            } oauthCallback:self.callbackURL errorBlock:self.errorBlock];
        } else {
            ACAccount *account = [accounts objectAtIndex:0];

            self.type = LMATwitterSTAuthTypeAccountStore;

            [self.twitterAPI postReverseOAuthTokenRequest:^(NSString *authenticationHeader) {
                __strong typeof(weakSelf)self = weakSelf;

                if (self.cancelled) {
                    [self didCancel];
                    return;
                }

                STTwitterAPI *twitterAPIOS = [STTwitterAPI twitterAPIOSWithAccount:account];
                [twitterAPIOS verifyCredentialsWithSuccessBlock:^(NSString *username) {
                    __strong typeof(weakSelf)self = weakSelf;

                    if (self.cancelled) {
                        [self didCancel];
                        return;
                    }

                    [twitterAPIOS postReverseAuthAccessTokenWithAuthenticationHeader:authenticationHeader successBlock:^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
                        __strong typeof(weakSelf)self = weakSelf;

                        if (self.cancelled) {
                            [self didCancel];
                            return;
                        }

                        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:4];

                        [dictionary setValue:oAuthToken forKey:LMAOAuth1Token];
                        [dictionary setValue:oAuthTokenSecret forKey:LMAOAuth1TokenSecret];
                        [dictionary setValue:userID forKey:LMAUserId];
                        [dictionary setValue:screenName forKey:@"screen_name"];

                        [self didAuthenticateWithData:dictionary];
                    } errorBlock:self.errorBlock];
                } errorBlock:self.errorBlock];
            } errorBlock:self.errorBlock];
        }
    }];
}

- (void)cancel
{
    self.cancelled = YES;
}

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (self.type != LMATwitterSTAuthTypeSafari) {
        return NO;
    }
    if (self.cancelled) {
        [self didCancel];
        return NO;
    }

    if (!url || ![[url absoluteString] hasPrefix:self.callbackURL]) {
        return NO;
    }

    NSDictionary *d = [self parametersDictionaryFromQueryString:[url query]];
    NSString *verifier = d[@"oauth_verifier"];

    __weak typeof(self)weakSelf = self;
    [self.twitterAPI postAccessTokenRequestWithPIN:verifier successBlock:^(NSString *oAuthToken, NSString *oAuthTokenSecret, NSString *userID, NSString *screenName) {
        __strong typeof(weakSelf)self = weakSelf;

        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:4];

        [dictionary setValue:oAuthToken forKey:LMAOAuth1Token];
        [dictionary setValue:oAuthTokenSecret forKey:LMAOAuth1TokenSecret];
        [dictionary setValue:userID forKey:LMAUserId];
        [dictionary setValue:screenName forKey:@"screen_name"];

        [self didAuthenticateWithData:dictionary];
    } errorBlock:self.errorBlock];

    return YES;
}

- (BOOL)handleDidBecomeActive
{
    if (self.type != LMATwitterSTAuthTypeSafari) {
        return NO;
    }

    [self didCancel];

    return YES;
}

#pragma mark Private methods

- (NSDictionary *)parametersDictionaryFromQueryString:(NSString *)queryString
{
    NSMutableDictionary *md = [[NSMutableDictionary alloc] init];

    NSArray *queryComponents = [queryString componentsSeparatedByString:@"&"];
    for (NSString *s in queryComponents) {
        NSArray *pair = [s componentsSeparatedByString:@"="];

        if ([pair count] != 2) {
            continue;
        }

        NSString *key = pair[0];
        NSString *value = pair[1];

        md[key] = value;
    }

    return md;
}

- (void)didAuthenticateWithData:(NSDictionary *)data
{
    [self.providerDelegate provider:self didAuthenticateWithData:data];
    [self finish];
}

- (void)didFailWithError:(NSError *)error
{
    [self.providerDelegate provider:self didFailWithError:error];
    [self finish];
}

- (void)didCancel
{
    [self.providerDelegate providerDidCancel:self];
    [self finish];
}

- (void)finish
{
    self.twitterAPI = nil;
}

@end
