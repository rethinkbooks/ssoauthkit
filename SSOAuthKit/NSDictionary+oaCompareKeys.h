//
//  NSDictionary+oaCompareKeys.h
//  SSOAuthKit
//
//  Created by Sam Soffes on 7/16/10.
//  Copyright 2010 Sam Soffes, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (oaCompareKeys)

- (NSComparisonResult)oaCompareKeys:(NSDictionary *)other;

@end
