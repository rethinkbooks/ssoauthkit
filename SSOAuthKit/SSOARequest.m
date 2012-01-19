//
//  SSOARequest.m
//  SSOAuthKit
//
//  Created by Sam Soffes on 1/25/10.
//  Copyright 2010 Sam Soffes. All rights reserved.
//

#import "SSOARequest.h"
#import "SSOAToken.h"
#import "OAHMAC_SHA1SignatureProvider.h"
#import "NSURL+OAuthString.h"
#import <SSToolkit/NSString+SSToolkitAdditions.h>

@implementation SSOARequest

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
	}
	return self;
}


- (NSString *)encodeURL:(NSString *)string {
	NSString *newString = NSMakeCollectable([(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease]);
	if (newString) {
		return newString;
	}
	return @"";
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
	
	if ([token.key isEqualToString:@""] == NO) {
		[parameterPairs addObject:[NSDictionary dictionaryWithObject:token.key forKey:@"oauth_token"]];
	}
	
	// Sort and concatenate
	NSMutableString *normalizedRequestParameters = [[NSMutableString alloc] init];
	NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(compare:)];
	
	NSUInteger i = 0;
	NSUInteger count = [parameterPairs count] - 1;
	for (NSDictionary *pair in sortedPairs) {
        NSString *string = [NSString stringWithFormat:@"%@=%@%@", [self encodeURL:[pair objectForKey:@"key"]], [self encodeURL:[pair objectForKey:@"value"]], (i < count ?  @"&" : @"")]; 
		[normalizedRequestParameters appendString:string];
		i++;
	}
	[parameterPairs release];
	
	// OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
	NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", self.requestMethod,
									 [[self.url OAuthString] URLEncodedString],
									 [normalizedRequestParameters URLEncodedString]];
	[normalizedRequestParameters release];
	
	// Sign
	// Secrets must be urlencoded before concatenated with '&'
	NSString *signature = [signatureProvider signClearText:signatureBaseString withSecret:
						   [NSString stringWithFormat:@"%@&%@", [self.consumerSecret URLEncodedString], 
							[token.secret URLEncodedString]]];
	
	// Set OAuth headers
	NSString *oauthToken = @"";
	if ([token.key isEqualToString:@""] == NO) {
		oauthToken = [NSString stringWithFormat:@"oauth_token=\"%@\", ", [token.key URLEncodedString]];
	}
	
	NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@oauth_signature_method=\"%@\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",
							 [self.consumerKey URLEncodedString],
							 oauthToken,
							 [[signatureProvider name] URLEncodedString],
							 [signature URLEncodedString],
							 timestamp,
							 nonce];
    if (self.callbackURL) {
        oauthHeader = [oauthHeader stringByAppendingFormat:@", oauth_callback=\"%@\"", [[self.callbackURL absoluteString] URLEncodedString]];
    }

	// Clean up
	[signatureProvider release];
	
	// Add the header
	[self addRequestHeader:@"Authorization" value:oauthHeader];
}

@end
