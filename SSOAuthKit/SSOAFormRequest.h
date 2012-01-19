//
//  SSOAFormRequest.h
//  SSOAuthKit
//
//  Created by Sam Soffes on 4/7/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "ASIFormDataRequest.h"

@class SSOAToken;

@interface SSOAFormRequest : ASIFormDataRequest

@property (nonatomic, retain) NSString *consumerKey;
@property (nonatomic, retain) NSString *consumerSecret;
@property (nonatomic, retain) NSURL *callbackURL;
@property (copy) SSOAToken *token;

@end
