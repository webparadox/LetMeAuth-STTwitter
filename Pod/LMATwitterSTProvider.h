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
 LMAOAuth1Token => NSString. String token for use in request parameters
 LMAOAuth1TokenSecret => String token secret for use in request parameters
 LMAUserId => NSString. Current user id for this token
 @"screen_name" => NSString. User screen name (twitter.com/<screen_name>)
 */
@interface LMATwitterSTProvider : NSObject <LMAProvider>

@end
