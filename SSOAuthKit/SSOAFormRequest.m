//
//  SSOAFormRequest.m
//  SSOAuthKit
//
//  Created by Sam Soffes on 4/7/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "SSOAFormRequest.h"
#import "SSOAToken.h"
#import "OAHMAC_SHA1SignatureProvider.h"
#import "NSURL+OAuthString.h"
#import "NSDictionary+oaCompareKeys.h"
#import <SSToolkit/NSString+SSToolkitAdditions.h>

@implementation SSOAFormRequest

@synthesize consumerKey;
@synthesize consumerSecret;
@synthesize callbackURL;
@synthesize token;

- (void)dealloc {
    self.token = nil;
    self.callbackURL = nil;
    self.consumerSecret = nil;
    self.consumerKey = nil;
    [super dealloc];
}


- (id)initWithURL:(NSURL *)newURL {
    if ((self = [super initWithURL:newURL])) {
        self.useCookiePersistence = NO;
        self.requestMethod = @"POST";
    }
    return self;
}


- (void)buildRequestHeaders {
    [super buildRequestHeaders];

    if (!self.consumerKey || !self.consumerSecret) {
        return;
    }

    // Signature provider
    id<OASignatureProviding> signatureProvider = [[OAHMAC_SHA1SignatureProvider alloc] init];

    // Timestamp
    NSString *timestamp = [NSString stringWithFormat:@"%d", time(NULL)];

    // Nonce
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *nonce = [(NSString *)string autorelease];

    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // Build a sorted array of both request parameters and OAuth header parameters
    NSMutableArray *parameterPairs = [[NSMutableArray alloc] initWithObjects:
                                      [NSDictionary dictionaryWithObjectsAndKeys:self.consumerKey, @"value", @"oauth_consumer_key", @"key", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:[signatureProvider name], @"value", @"oauth_signature_method", @"key", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:timestamp, @"value", @"oauth_timestamp", @"key", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:nonce, @"value", @"oauth_nonce", @"key", nil],
                                      [NSDictionary dictionaryWithObjectsAndKeys:@"1.0", @"value", @"oauth_version", @"key", nil],
                                      nil];
    if (self.callbackURL) {
        [parameterPairs addObject:[NSDictionary dictionaryWithObjectsAndKeys:[self.callbackURL absoluteString], @"value", @"oauth_callback", @"key", nil]];
    }

    if (token && [token.key isEqualToString:@""] == NO) {
        [parameterPairs addObject:[NSDictionary dictionaryWithObjectsAndKeys:token.key, @"value", @"oauth_token", @"key", nil]];
    }

    // Add existing parameters
    if (postData) {
        [parameterPairs addObjectsFromArray:postData];
    }

    // Sort and concatenate
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(oaCompareKeys:)];
    [parameterPairs release];

    NSMutableArray *pieces = [[NSMutableArray alloc] init];
    for (NSDictionary *pair in sortedPairs) {
        [pieces addObject:[NSString stringWithFormat:@"%@=%@", [[pair objectForKey:@"key"] URLEncodedString], [[pair objectForKey:@"value"] URLEncodedString]]];
    }
    NSString *normalizedRequestParameters = [pieces componentsJoinedByString:@"&"];
    [pieces release];

    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", self.requestMethod,
                                     [[self.url OAuthString] URLEncodedString],
                                     [normalizedRequestParameters URLEncodedString]];

    // Sign
    // Secrets must be urlencoded before concatenated with '&'
    NSString *tokenSecret = token ? [token.secret URLEncodedString] : @"";
    NSString *secret = [NSString stringWithFormat:@"%@&%@", [self.consumerSecret URLEncodedString], tokenSecret];
    NSString *signature = [signatureProvider signClearText:signatureBaseString withSecret:secret];

    // Set OAuth headers
    NSString *oauthToken = @"";
    if (token && [token.key isEqualToString:@""] == NO) {
        oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [token.key URLEncodedString]];
    }

    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_nonce=\"%@\", oauth_signature_method=\"%@\", oauth_timestamp=\"%@\", oauth_consumer_key=\"%@\", %@oauth_signature=\"%@\", oauth_version=\"1.0\"",
                             [nonce URLEncodedString],
                             [[signatureProvider name] URLEncodedString],
                             [timestamp URLEncodedString],
                             [self.consumerKey URLEncodedString],
                             oauthToken,
                             [signature URLEncodedString]];
    if (self.callbackURL) {
        oauthHeader = [oauthHeader stringByAppendingFormat:@", oauth_callback=\"%@\"", [[self.callbackURL absoluteString] URLEncodedString]];
    }

    // Clean up
    [signatureProvider release];

    // Add the header
    [self addRequestHeader:@"Authorization" value:oauthHeader];
}

@end
