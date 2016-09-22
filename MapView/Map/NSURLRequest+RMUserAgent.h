//
//  NSURLRequest+RMUserAgent.h
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (RMUserAgent)

/**
 Creates and returns an initialized URL request with specified values. Appends information about user agent to the header.

 @param url The URL for the new request.

 @return The newly created URL request.
 */
+ (instancetype)rm_requestWithHeaderForURL:(NSURL *)url;

/**
 Creates and returns an initialized URL request with specified values. Appends information about user agent to the header.

 @param url             The URL for the new request.
 @param cachePolicy     The cache policy for the new request.
 @param timeoutInterval The timeout interval for the new request, in seconds.

 @return The newly created URL request.
 */
+ (instancetype)rm_requestWithHeaderForURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval;

@end
