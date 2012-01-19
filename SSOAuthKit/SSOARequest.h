//
//  SSOARequest.h
//  SSOAuthKit
//
//  Created by Sam Soffes on 1/25/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "ASIHTTPRequest.h"

@class SSOAToken;

@interface SSOARequest : ASIHTTPRequest;

@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
@property (nonatomic, retain) NSURL *callbackURL;
@property (copy) SSOAToken *token;

@end
