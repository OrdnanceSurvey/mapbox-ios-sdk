//
//  NSURLRequest+RMUserAgent.m
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import "NSURLRequest+RMUserAgent.h"
#import "RMConfiguration.h"

@implementation NSMutableURLRequest (RMUserAgent)

- (void)appendHeaderAgentValue
{
    [self setValue:[[RMConfiguration sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];
}

@end

@implementation NSURLRequest (RMUserAgent)

+ (instancetype)requestWithHeaderForURL:(NSURL *)url
{
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url];
    [mRequest appendHeaderAgentValue];

    return [mRequest copy];
}

+ (instancetype)requestWithHeaderForURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:timeoutInterval];
    [mRequest appendHeaderAgentValue];

    return [mRequest copy];
}

@end
