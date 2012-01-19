//
//  NSURL+OAuthString.h
//  SSOAuthKit
//
//  Created by Sam Soffes on 11/17/09.
//  Copyright 2009 Sam Soffes, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (OAuthString)

- (NSString *)OAuthString;
- (NSDictionary *)queryDictionary;

@end
