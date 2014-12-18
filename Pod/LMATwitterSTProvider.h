//
//  LMATwitterSTProvider.h
//  LetMeAuth-STTwitter
//
//  Created by Evgeniy Yurtaev on 21.11.14.
//  Copyright (c) 2014 Webparadox, LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <LetMeAuth/LetMeAuth.h>
#import "LMATwitterSTConstants.h"


/*
 @"oauth_token" => NSString. String token for use in request parameters
 @"oauth_token_secret" => String token secret for use in request parameters
 @"user_id" => NSString. Current user id for this token
 @"screen_name" => NSString. User screen name (twitter.com/<screen_name>)
 */
@interface LMATwitterSTProvider : NSObject <LMAProvider>

@end
