//
//  ACAccountStore+GCD.h
//  LetMeAuth-STTwitter
//
//  Created by Alexey Aleshkov on 10/12/14.
//  Copyright (c) 2014 Webparadox, LLC. All rights reserved.
//


#import <Accounts/Accounts.h>


typedef void (^ACAccountStoreRequestAccountsCompletionHandler)(BOOL granted, NSArray *accounts, NSError *error);


@interface ACAccountStore (GCD)

- (void)gcd_requestAccessToAccountsWithType:(ACAccountType *)accountType
                                    options:(NSDictionary *)options
                                      queue:(dispatch_queue_t)queue
                                 completion:(ACAccountStoreRequestAccessCompletionHandler)completion;

- (void)gcd_requestAccountsWithType:(ACAccountType *)accountType
                            options:(NSDictionary *)options
                              queue:(dispatch_queue_t)queue
                         completion:(ACAccountStoreRequestAccountsCompletionHandler)completion;

@end
