//
//  LMATwitterSTConstants.m
//  LetMeAuth-STTwitter
//
//  Created by Alexey Aleshkov on 18/12/14.
//  Copyright (c) 2014 Webparadox, LLC. All rights reserved.
//


//#import "LMATwitterSTConstants.h"
#import <LetMeAuth/LetMeAuth.h>


NSString *LMATwitterSTConsumerKey = @"oauth_consumer_key";
NSString *LMATwitterSTConsumerSecret = @"oauth_consumer_secret";
NSString *LMATwitterSTCallbackURL = @"oauth_callback";


__attribute__((constructor))
static void initializeConstants()
{
    LMATwitterSTConsumerKey = LMAOAuth1ConsumerKey;
    LMATwitterSTConsumerSecret = LMAOAuth1ConsumerSecret;
    LMATwitterSTCallbackURL = LMAOAuth1Callback;
}
