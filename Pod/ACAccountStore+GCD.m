//
//  ACAccountStore+GCD.m
//  LetMeAuth-STTwitter
//
//  Created by Alexey Aleshkov on 10/12/14.
//  Copyright (c) 2014 Webparadox, LLC. All rights reserved.
//


#import "ACAccountStore+GCD.h"


@implementation ACAccountStore (GCD)

- (void)gcd_requestAccessToAccountsWithType:(ACAccountType *)accountType
                                    options:(NSDictionary *)options
                                      queue:(dispatch_queue_t)queue
                                 completion:(ACAccountStoreRequestAccessCompletionHandler)completion
{
    ACAccountStoreRequestAccessCompletionHandler completionHandler;
    if (!queue) {
        completionHandler = completion;
    } else {
        completionHandler = ^(BOOL granted, NSError *error) {
            dispatch_async(queue, ^{
                completion(granted, error);
            });
        };
    }

    [self requestAccessToAccountsWithType:accountType options:options completion:completionHandler];
}

- (void)gcd_requestAccountsWithType:(ACAccountType *)accountType
                            options:(NSDictionary *)options
                              queue:(dispatch_queue_t)queue
                         completion:(ACAccountStoreRequestAccountsCompletionHandler)completion
{
    __weak typeof(self)weakSelf = self;

    [self gcd_requestAccessToAccountsWithType:accountType options:options queue:queue completion:^(BOOL granted, NSError *error) {
        __strong typeof(weakSelf)self = weakSelf;

        NSArray *accounts = nil;
        if (granted) {
            accounts = [self accountsWithAccountType:accountType];
        }
        completion(granted, accounts, error);
    }];
}

@end
